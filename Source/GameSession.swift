// 花来 - 运行时状态与进程查找
import Foundation
import UIKit
import Darwin
import simd

final class GameSession {
    static let shared = GameSession()

    private(set) var players: [PlayerEntity] = []
    private(set) var camera = CameraData()
    private(set) var localTeamId: Int = 0
    private(set) var localPlayerPosition = SIMD3<Float>.zero
    private(set) var screenSize: CGSize = .zero
    private(set) var gamePid: pid_t = 0
    private(set) var isRunning = false
    private(set) var lastError: String?

    private let reader = KernelMemoryReader.shared
    private var offsets = MemoryOffsets()
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "huailai.session", qos: .userInitiated)

    private init() {
        screenSize = UIScreen.main.bounds.size
    }

    func start() {
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(16))
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        reader.detach()
        isRunning = false
        players = []
    }

    private func tick() {
        if !reader.isAttached || gamePid == 0 {
            guard let pid = Self.findProcess(named: BinaryAnalysis.targetProcessName)
                    ?? Self.findProcess(named: "DeltaForce")
                    ?? Self.findProcess(prefix: BinaryAnalysis.bundlePrefix) else {
                lastError = "未找到游戏进程"
                buildDemoFrame()
                return
            }
            guard reader.attach(pid: pid) else {
                lastError = "task_for_pid 失败 (需要越狱权限)"
                buildDemoFrame()
                return
            }
            gamePid = pid
            lastError = nil
        }

        isRunning = true
        refreshGameData()
    }

    private func refreshGameData() {
        let base = MemoryOffsets.gameBaseAddress
        guard base != 0 else { buildDemoFrame(); return }

        var list: [PlayerEntity] = []
        var addr = base + offsets.playerListBase
        guard let count = reader.readU32(addr), count > 0, count < 256 else {
            buildDemoFrame()
            return
        }
        addr += 4

        for index in 0..<Int(count) {
            guard let entityPtr = reader.readU64(addr + UInt64(index) * 8), entityPtr != 0 else { continue }
            guard let health = reader.readFloat(entityPtr + offsets.healthOffset),
                  let team = reader.readI32(entityPtr + offsets.teamIDOffset),
                  let pos = reader.readVec3(entityPtr + offsets.positionOffset) else { continue }
            guard health > 0 else { continue }

            var bones: [BonePoint] = []
            if offsets.bonesOffset != 0 {
                for boneIndex in 0..<offsets.boneCount {
                    let boneAddr = entityPtr + offsets.bonesOffset + UInt64(boneIndex) * 12
                    if let bonePos = reader.readVec3(boneAddr) {
                        bones.append(BonePoint(index: boneIndex, worldPos: bonePos))
                    }
                }
            }

            let distance = simd_distance(pos, localPlayerPosition)
            list.append(PlayerEntity(id: index,
                                     teamId: Int(team),
                                     health: health,
                                     maxHealth: 100,
                                     isAlive: true,
                                     isVisible: true,
                                     position: pos,
                                     bones: bones,
                                     distance: distance,
                                     name: "玩家\(index)",
                                     isBot: false))
        }

        if list.isEmpty {
            buildDemoFrame()
        } else {
            players = list
            lastError = nil
        }
    }

    private func buildDemoFrame() {
        let time = Float(Date().timeIntervalSince1970)
        var list: [PlayerEntity] = []
        for i in 0..<4 {
            let angle = time * 0.6 + Float(i) * 1.57
            let radius: Float = 6 + Float(i) * 2
            let base = SIMD3<Float>(cos(angle) * radius, 0, sin(angle) * radius)
            var bones: [BonePoint] = []
            let height: Float = 1.7
            let points: [SIMD3<Float>] = [
                base + SIMD3(0, height, 0),
                base + SIMD3(0, height - 0.3, 0),
                base + SIMD3(0, height - 0.9, 0),
                base + SIMD3(0, 0.1, 0)
            ]
            for (idx, p) in points.enumerated() {
                bones.append(BonePoint(index: idx, worldPos: p))
            }
            list.append(PlayerEntity(id: i,
                                     teamId: i % 3 == 0 ? 0 : 1,
                                     health: 100,
                                     maxHealth: 100,
                                     isAlive: true,
                                     isVisible: true,
                                     position: base,
                                     bones: bones,
                                     distance: radius,
                                     name: i % 3 == 0 ? "队友\(i)" : "敌人\(i)",
                                     isBot: i % 2 == 0))
        }
        players = list
    }

    static func findProcess(named name: String) -> pid_t? {
        for info in allProcesses() where info.name == name {
            return info.pid
        }
        return nil
    }

    static func findProcess(prefix: String) -> pid_t? {
        for info in allProcesses() where info.name.hasPrefix(prefix) {
            return info.pid
        }
        return nil
    }

    private static func allProcesses() -> [(pid: pid_t, name: String)] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0, size > 0 else { return [] }

        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count + 32)
        size = procs.count * MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, 4, &procs, &size, nil, 0) == 0 else { return [] }

        let actual = size / MemoryLayout<kinfo_proc>.stride
        var result: [(pid: pid_t, name: String)] = []
        for i in 0..<actual {
            let pid = procs[i].kp_proc.p_pid
            guard pid > 0 else { continue }
            let name = withUnsafeBytes(of: procs[i].kp_proc.p_comm) { raw -> String in
                let bytes = raw.bindMemory(to: CChar.self)
                return String(cString: bytes.baseAddress!)
            }
            result.append((pid: pid, name: name))
        }
        return result
    }
}

extension PlayerEntity {
    var isEnemy: Bool { teamId != GameSession.shared.localTeamId }
}