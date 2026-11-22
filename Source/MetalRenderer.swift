// 花来 - Metal 设备封装
import Metal
import MetalKit
import UIKit

final class MetalContext {
    static let shared = MetalContext()
    let device: MTLDevice?
    let commandQueue: MTLCommandQueue?

    private init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
    }
}