// 花来 - 自瞄
import UIKit
import simd

final class Aimbot {
    static let shared = Aimbot()
    private let config = ConfigStore.shared

    func bestTarget(players: [PlayerEntity], screen: CGSize) -> PlayerEntity? {
        guard config.masterEnabled, config.aimEnabled else { return nil }
        let center = CGPoint(x: screen.width / 2, y: screen.height / 2)
        let halfFov = config.aimFov / 2

        var best: PlayerEntity?
        var bestScore = CGFloat.greatestFiniteMagnitude

        for player in players where player.isAlive && player.isEnemy {
            if config.aimHumanOnly && player.isBot { continue }
            guard player.distance <= config.maxDistance else { continue }
            guard let screenPoint = ESPProjector.shared.project(world: player.position,
                                                                camera: GameSession.shared.camera,
                                                                screen: screen) else { continue }
            let dx = CGFloat(screenPoint.x) - center.x
            let dy = CGFloat(screenPoint.y) - center.y
            let distance = sqrt(dx * dx + dy * dy)
            guard distance <= halfFov else { continue }
            if distance < bestScore {
                bestScore = distance
                best = player
            }
        }
        return best
    }

    func aimPoint(for target: PlayerEntity) -> SIMD3<Float> {
        let wanted = SkeletonLayout.aimIndex(for: config.aimPart)
        if let bone = target.bones.first(where: { $0.index == wanted }) {
            return bone.worldPos
        }
        let fallback = SkeletonLayout.headBoneIndex
        if let bone = target.bones.first(where: { $0.index == fallback }) {
            return bone.worldPos
        }
        return target.position + SIMD3<Float>(0, 1.6, 0)
    }

    func aimOffset(for target: PlayerEntity, screen: CGSize) -> CGPoint? {
        guard let point = ESPProjector.shared.project(world: aimPoint(for: target),
                                                      camera: GameSession.shared.camera,
                                                      screen: screen) else { return nil }
        let center = CGPoint(x: screen.width / 2, y: screen.height / 2)
        let smooth = max(config.aimSmooth, 1)
        return CGPoint(x: (CGFloat(point.x) - center.x) / smooth,
                       y: (CGFloat(point.y) - center.y) / smooth)
    }
}