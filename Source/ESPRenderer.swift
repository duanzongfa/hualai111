// 花来 - ESP 渲染器 (修复版)
import Foundation

class ESPRenderer {
    static let shared = ESPRenderer()
    
    func worldToScreen(_ worldPos: SIMD3<Float>, camera: CameraData, screenSize: CGSize) -> SIMD2<Float>? {
        let clip = camera.matrix * SIMD4<Float>(worldPos.x, worldPos.y, worldPos.z, 1.0)
        guard clip.w > 0.001 else { return nil }
        let ndcX = clip.x / clip.w
        let ndcY = clip.y / clip.w
        let screenX = (ndcX + 1.0) * 0.5 * Float(screenSize.width)
        let screenY = (1.0 - ndcY) * 0.5 * Float(screenSize.height)
        return SIMD2<Float>(screenX, screenY)
    }
    
    func getBoxSize(distance: Float, height: Float = 1.8) -> CGSize {
        let scale = max(30.0, min(200.0, 500.0 / max(distance, 1.0)))
        return CGSize(width: scale, height: scale * height)
    }
}
