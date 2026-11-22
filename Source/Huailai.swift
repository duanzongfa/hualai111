// 花来 - 主入口 (修复版)
import Foundation
import UIKit

class CheatGameState {
    static let shared = CheatGameState()
    var players: [PlayerEntity] = []
    var localPlayer: PlayerEntity?
    var camera: CameraData = CameraData()
    var deltaSeconds: Float = 0
    var frameCount: Int = 0
    var fps: Float = 0
}

class HuailaiController {
    static let shared = HuailaiController()
    private var memoryReader = KernelMemoryReader.shared
    private var isInitialized = false
    
    func initialize() {
        print("[Huailai] Starting...")
        IPCManager.shared.observeReady()
        if let pid = findProcess(named: BinaryAnalysis.targetProcessName) {
            if memoryReader.initialize(pid: pid) {
                isInitialized = true
                print("[Huailai] Initialized with PID: \(pid)")
            }
        }
    }
    
    private func findProcess(named name: String) -> pid_t? {
        var pids = [Int32](repeating: 0, count: 4096)
        let count = proc_listallpids(&pids, UInt32(pids.count * MemoryLayout<Int32>.stride))
        guard count > 0 else { return nil }
        for i in 0..<Int(count) {
            if pids[i] != 0 {
                return pids[i]
            }
        }
        return nil
    }
}

@objc class HuailaiInject: NSObject {
    @objc static func main() {
        HuailaiController.shared.initialize()
    }
}
