// 花来 - Metal 渲染器 (修复版)
import Metal
import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {
    var mtkView: MTKView?
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    override init() {
        super.init()
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
