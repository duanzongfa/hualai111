// 花来 - ESP 投影与绘制
import UIKit
import simd

final class ESPProjector {
    static let shared = ESPProjector()

    func project(world: SIMD3<Float>, camera: CameraData, screen: CGSize) -> SIMD2<Float>? {
        let clip = camera.matrix * SIMD4<Float>(world.x, world.y, world.z, 1)
        guard clip.w > 0.001 else { return nil }
        let ndc = SIMD2<Float>(clip.x / clip.w, clip.y / clip.w)
        guard abs(ndc.x) <= 1.6, abs(ndc.y) <= 1.6 else { return nil }
        return SIMD2<Float>((ndc.x + 1) * 0.5 * Float(screen.width),
                            (1 - ndc.y) * 0.5 * Float(screen.height))
    }

    func headTop(_ player: PlayerEntity, camera: CameraData, screen: CGSize) -> SIMD2<Float>? {
        guard let first = player.bones.first?.worldPos else {
            return project(world: player.position + SIMD3(0, 1.75, 0), camera: camera, screen: screen)
        }
        return project(world: first, camera: camera, screen: screen)
    }

    func feet(_ player: PlayerEntity, camera: CameraData, screen: CGSize) -> SIMD2<Float>? {
        project(world: player.position, camera: camera, screen: screen)
    }
}

final class ESPRenderer {
    static let shared = ESPRenderer()
    private let config = ConfigStore.shared
    private let projector = ESPProjector.shared

    func render(in layer: CALayer, camera: CameraData, players: [PlayerEntity], screen: CGSize) {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard config.masterEnabled, config.espEnabled, screen.width > 0 else { return }

        for player in players where player.isAlive && player.distance <= config.maxDistance {
            let isEnemy = player.isEnemy
            if config.filterAI && player.isBot { continue }
            drawPlayer(player, in: layer, camera: camera, screen: screen, isEnemy: isEnemy)
        }
    }

    private func drawPlayer(_ player: PlayerEntity, in layer: CALayer, camera: CameraData, screen: CGSize, isEnemy: Bool) {
        let color = isEnemy ? config.boxColor : config.aiBoxColor
        guard let top = projector.headTop(player, camera: camera, screen: screen),
              let bottom = projector.feet(player, camera: camera, screen: screen) else { return }

        let height = abs(bottom.y - top.y)
        guard height > 6 else { return }
        let width = height * 0.45

        if config.showSkeleton {
            drawSkeleton(player, in: layer, camera: camera, screen: screen, color: config.skeletonColor)
        }

        if config.showBox {
            let rect = CGRect(x: CGFloat(top.x) - CGFloat(width) / 2,
                              y: CGFloat(top.y),
                              width: CGFloat(width),
                              height: CGFloat(height))
            let box = CALayer()
            box.frame = rect
            box.borderColor = color.cgColor
            box.borderWidth = 1.5
            box.backgroundColor = UIColor.clear.cgColor
            layer.addSublayer(box)
        }

        if config.showHealth {
            let bar = CALayer()
            let barHeight = CGFloat(height)
            let ratio = CGFloat(max(0, min(1, player.health / max(player.maxHealth, 1))))
            bar.frame = CGRect(x: CGFloat(top.x) - CGFloat(width) / 2 - 5,
                               y: CGFloat(top.y) + (1 - ratio) * barHeight,
                               width: 3,
                               height: ratio * barHeight)
            bar.backgroundColor = ratio > 0.5 ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
            layer.addSublayer(bar)
        }

        var lines: [String] = []
        if config.showName { lines.append(player.name) }
        if config.showDistance { lines.append(String(format: "%.0fm", player.distance)) }
        if !lines.isEmpty { addLabel(lines.joined(separator: "  "), at: CGPoint(x: CGFloat(top.x), y: CGFloat(top.y) - 14), color: color, in: layer) }
    }

    private func drawSkeleton(_ player: PlayerEntity, in layer: CALayer, camera: CameraData, screen: CGSize, color: UIColor) {
        let joints = player.bones.compactMap { $0.worldPos }
        guard joints.count >= 2 else { return }
        var points: [CGPoint] = []
        for joint in joints {
            if let p = projector.project(world: joint, camera: camera, screen: screen) {
                points.append(CGPoint(x: CGFloat(p.x), y: CGFloat(p.y)))
            }
        }
        guard points.count >= 2 else { return }
        for i in 0..<(points.count - 1) {
            addLine(from: points[i], to: points[i + 1], color: color, in: layer)
        }
    }

    private func addLine(from: CGPoint, to: CGPoint, color: UIColor, in layer: CALayer) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.cgColor
        shape.lineWidth = 1.2
        shape.fillColor = UIColor.clear.cgColor
        layer.addSublayer(shape)
    }

    private func addLabel(_ text: String, at point: CGPoint, color: UIColor, in layer: CALayer) {
        let label = CATextLayer()
        label.string = text
        label.fontSize = 11
        label.alignmentMode = .center
        label.foregroundColor = color.cgColor
        label.contentsScale = UIScreen.main.scale
        label.frame = CGRect(x: point.x - 60, y: point.y, width: 120, height: 15)
        layer.addSublayer(label)
    }
}