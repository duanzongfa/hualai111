// 花来 - dyld Hook (修复版)
import Foundation
import Darwin

class DYLDHook {
    static let shared = DYLDHook()
    func hook() {
        print("[Huailai] dyld hook installed")
    }
}
