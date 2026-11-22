// 花来 - 核心配置
// 基于 Ghidra 逆向 ESPOnlyPureTrollLive 分析结果

import Foundation

// MARK: - 二进制分析数据
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
    case kernel = "kernel"
    case process = "process"
    case auto = "auto"
}

// MARK: - ESP 配置键名 (来自二进制字符串分析)
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
    case backEnemy = "BackEnemyEnabled"
    case filterAI = "FilterAIEnabled"
    case stats = "StatsEnabled"
    case loot = "LootEnabled"
    case lootShowRarity = "LootShowRarityEnabled"
    case lootValuePanel = "LootValuePanelEnabled"
    case lootMinRarity = "LootMinRarity"
    case lootMinValue = "LootMinValue"
    case lootDistanceMeters = "LootDistanceMeters"
    case deathBox = "DeathBoxEnabled"
    case filterAIDeathBox = "FilterAIDeathBoxEnabled"
    case container = "ContainerEnabled"
    case skeletonThickness = "SkeletonThickness"
    case boxThickness = "BoxThickness"
    case playerTextScale = "PlayerTextScale"
    case lootTextScale = "LootTextScale"
    case lootValuePanelScale = "LootValuePanelScale"
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
    case projTrackPart = "ProjectileTrackPart"
    case projTrackHuman = "ProjectileTrackHumanEnabled"
    case projTrackAI = "ProjectileTrackAIEnabled"
    case projTrackCircle = "ProjectileTrackCircleEnabled"
    case projTrackRadius = "ProjectileTrackRadius"
    case projTrackHitRate = "ProjectileHitRate"
    case screenCaptureProtect = "ScreenCaptureProtectionEnabled"
    case deathSound = "DeathSoundEnabled"
}

// MARK: - IPC 通知名称
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

// MARK: - 运行时配置
struct RuntimeConfig {
    var readMode: ReadMode = .kernel
    var espEnabled: Bool = true
    var aimEnabled: Bool = false
    var fovDegrees: CGFloat = 180.0
    var aimPart: AimPart = .head
    static let headBoneIndex: Int = 9
    static let maxBones: Int = 30
    var targetFPS: Int = 60
    var windowAlpha: CGFloat = 0.9
}

enum AimPart: Int {
    case head = 0
    case neck = 1
    case chest = 2
    case stomach = 3
    case pelvis = 4
}

// MARK: - 内存偏移 (需要运行时通过 XPF/jbinfo 动态解析)
struct MemoryOffsets {
    static var gameBaseAddress: UInt64 = 0x100000000
    static var kernelStaticBase: UInt64 = 0x0
    static var sptmBase: UInt64 = 0x0
    static var txmBase: UInt64 = 0x0
    
    var playerListBase: UInt64? = nil
    var localPlayerOffset: UInt64? = nil
    var entityListOffset: UInt64? = nil
    var viewMatrixOffset: UInt64? = nil
    var projMatrixOffset: UInt64? = nil
    var cameraPosOffset: UInt64? = nil
    
    var playerIDOffset: Int = 0x0
    var teamIDOffset: Int = 0x0
    var healthOffset: Int = 0x0
    var maxHealthOffset: Int = 0x0
    var isAliveOffset: Int = 0x0
    var visibilityOffset: Int = 0x0
    var positionOffset: Int = 0x0
    var bonesOffset: Int = 0x0
    var boneCount: Int = 25
    
    var origDrawIndexedPrimitives: UInt64 = 0x0
    var origDrawPrimitives: UInt64 = 0x0
}

// MARK: - 游戏数据结构
struct BonePoint {
    let index: Int
    let worldPos: SIMD3<Float>
    let screenPos: SIMD2<Float>?
}

struct PlayerEntity {
    let id: Int
    let teamId: Int
    let health: Float
    let maxHealth: Float
    let isAlive: Bool
    let isVisible: Bool
    let position: SIMD3<Float>
    let bones: [BonePoint]
    let distance: Float
    let name: String
}

struct CameraData {
    var position: SIMD3<Float> = .zero
    var matrix: matrix_float4x4 = .identity
}

struct CheatGameState {
    var players: [PlayerEntity] = []
    var localPlayer: PlayerEntity?
    var camera: CameraData = CameraData()
    var deltaSeconds: Float = 0
    var frameCount: Int = 0
    var fps: Float = 0
}
