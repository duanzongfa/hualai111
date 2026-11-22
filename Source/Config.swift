// 花来 - 核心配置与数据结构
import Foundation
import UIKit
import CoreGraphics
import simd

enum BinaryAnalysis {
    static let drawGameAddr: UInt64 = 0x1001d807c
    static let onEspStatsAddr: UInt64 = 0x100035c60
    static let toggleWindowAddr: UInt64 = 0x1000904b4
    static let openAfterHUDAddr: UInt64 = 0x1000a86a4
    static let renderBootLogoAddr: UInt64 = 0x100011490
    static let injectHookAddr: UInt64 = 0x100013940
    static let initOffsetsAddr: UInt64 = 0x10032d0f0
    static let targetProcessName = "DeltaForce"
    static let bundlePrefix = "com.tencent"
}

enum ReadMode: String {
    case kernel
    case process
    case auto
}

enum AimPart: Int, CaseIterable {
    case head = 0
    case neck = 1
    case chest = 2
    case stomach = 3
    case pelvis = 4

    var title: String {
        switch self {
        case .head: return "头部"
        case .neck: return "颈部"
        case .chest: return "胸部"
        case .stomach: return "腹部"
        case .pelvis: return "骨盆"
        }
    }
}

enum ConfigKey: String {
    case master = "MasterEnabled"
    case skeleton = "SkeletonEnabled"
    case box = "BoxEnabled"
    case ray = "RayEnabled"
    case health = "HealthEnabled"
    case distance = "DistanceEnabled"
    case name = "NameEnabled"
    case heroInfo = "HeroInfoEnabled"
    case headArmor = "HeadArmorEnabled"
    case heldWeapon = "HeldWeaponEnabled"
    case filterAI = "FilterAIEnabled"
    case stats = "StatsEnabled"
    case loot = "LootEnabled"
    case lootMinRarity = "LootMinRarity"
    case lootMinValue = "LootMinValue"
    case lootDistanceMeters = "LootDistanceMeters"
    case deathBox = "DeathBoxEnabled"
    case container = "ContainerEnabled"
    case skeletonThickness = "SkeletonThickness"
    case boxThickness = "BoxThickness"
    case playerTextScale = "PlayerTextScale"
    case humanBoxColor = "HumanBoxColor"
    case aiBoxColor = "AIBoxColor"
    case humanSkeletonColor = "HumanSkeletonColor"
    case aiSkeletonColor = "AISkeletonColor"
    case aim = "AimEnabled"
    case aimPart = "AimPart"
    case aimHuman = "AimHumanEnabled"
    case aimAI = "AimAIEnabled"
    case aimADS = "AimADSEnabled"
    case aimHip = "AimHipEnabled"
    case aimCircle = "AimCircleEnabled"
    case aimFovRange = "AimFovRange"
    case aimStrength = "AimStrength"
    case projTrack = "ProjectileTrackEnabled"
    case projTrackRadius = "ProjectileTrackRadius"
    case projTrackHitRate = "ProjectileHitRate"
    case screenCaptureProtect = "ScreenCaptureProtectionEnabled"
}

enum IPCNotification: String {
    case mainBundle = "com.cb.esponly.puretroll.live"
    case runtimePID = "com.cb.esponly.runtime.pid"
    case runtimeReady = "com.cb.esponly.runtime.ready"
    case runtimeDSReady = "com.cb.esponly.runtime.ds-ready"
    case runtimeRenderReady = "com.cb.esponly.runtime.render-ready"
    case runtimeRWMode = "com.cb.esponly.runtime.rw-mode"
    case runtimeStop = "com.cb.esponly.runtime.stop"
    case sakuraResume = "com.cb.esponly.sakura.resume"
    case sakuraResumeReady = "com.cb.esponly.sakura.resume-ready"
    case espShow = "com.cz.esp.runtime.show"
    case espHide = "com.cz.esp.runtime.hide"
    case espVisibleState = "com.cz.esp.runtime.visible-state"
}

struct MemoryOffsets {
    static var gameBaseAddress: UInt64 = 0x100000000
    static var kernelStaticBase: UInt64 = 0x0
    static var sptmBase: UInt64 = 0x0
    static var txmBase: UInt64 = 0x0

    var playerListBase: UInt64 = 0x0
    var localPlayerOffset: UInt64 = 0x0
    var entityListOffset: UInt64 = 0x0
    var viewMatrixOffset: UInt64 = 0x0
    var cameraPosOffset: UInt64 = 0x0

    var playerIDOffset: UInt64 = 0x0
    var teamIDOffset: UInt64 = 0x0
    var healthOffset: UInt64 = 0x0
    var maxHealthOffset: UInt64 = 0x0
    var isAliveOffset: UInt64 = 0x0
    var visibilityOffset: UInt64 = 0x0
    var positionOffset: UInt64 = 0x0
    var bonesOffset: UInt64 = 0x0
    var boneCount: Int = 25
}

struct BonePoint {
    let index: Int
    let worldPos: SIMD3<Float>
    var screenPos: SIMD2<Float>?
}

struct PlayerEntity {
    let id: Int
    let teamId: Int
    let health: Float
    let maxHealth: Float
    let isAlive: Bool
    let isVisible: Bool
    let position: SIMD3<Float>
    var bones: [BonePoint]
    let distance: Float
    let name: String
    let isBot: Bool
}

struct CameraData {
    var position: SIMD3<Float> = .zero
    var matrix: matrix_float4x4 = matrix_identity_float4x4
}

final class ConfigStore {
    static let shared = ConfigStore()

    var masterEnabled: Bool = true
    var espEnabled: Bool = true
    var showSkeleton: Bool = true
    var showBox: Bool = true
    var showHealth: Bool = true
    var showDistance: Bool = true
    var showName: Bool = true
    var showRay: Bool = false
    var filterAI: Bool = false

    var aimEnabled: Bool = false
    var aimPart: AimPart = .head
    var aimFov: CGFloat = 120
    var aimSmooth: CGFloat = 6
    var aimHumanOnly: Bool = true

    var readMode: ReadMode = .auto
    var maxDistance: Float = 400
    var targetFPS: Int = 60

    var boxColor: UIColor { UIColor(red: 0.20, green: 0.95, blue: 0.45, alpha: 0.95) }
    var aiBoxColor: UIColor { UIColor(red: 1.00, green: 0.42, blue: 0.42, alpha: 0.95) }
    var skeletonColor: UIColor { UIColor(red: 0.30, green: 0.90, blue: 1.00, alpha: 0.95) }

    private init() {}
}