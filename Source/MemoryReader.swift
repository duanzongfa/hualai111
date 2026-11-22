// 花来 - 内存读取器 (修复版)
// 基于 libkrw (kread32/kread64) 内核内存读取

import Foundation
import Darwin

class KernelMemoryReader {
    static let shared = KernelMemoryReader()
    private var targetPid: pid_t = 0
    private var targetTask: task_t = MACH_PORT_NULL
    
    typealias KRead32 = @convention(c) (task_t, UInt64, UnsafeMutablePointer<UInt32>) -> kern_return_t
    typealias KRead64 = @convention(c) (task_t, UInt64, UnsafeMutablePointer<UInt64>) -> kern_return_t
    
    private var kread32: KRead32?
    private var kread64: KRead64?
    
    func initialize(pid: pid_t) -> Bool {
        self.targetPid = pid
        guard task_for_pid(mach_task_self_, pid, &targetTask) == KERN_SUCCESS else {
            return false
        }
        
        let paths = [
            "/Library/MobileSubstrate/DynamicLibraries/libkrw.dylib",
            "/var/containers/Bundle/Application/.jbroot/Library/MobileSubstrate/DynamicLibraries/libkrw.dylib"
        ]
        
        for path in paths {
            let handle = dlopen(path, RTLD_LAZY)
            guard handle != nil else { continue }
            kread32 = dlsym(handle, "_kread32").map { ptr in unsafeBitCast(ptr, to: KRead32.self) }
            kread64 = dlsym(handle, "_kread64").map { ptr in unsafeBitCast(ptr, to: KRead64.self) }
            if kread32 != nil { break }
        }
        
        return kread32 != nil
    }
    
    deinit { targetTask = MACH_PORT_NULL }
    
    func read32(_ addr: UInt64) -> UInt32? {
        var v: UInt32 = 0
        guard let fn = kread32, fn(targetTask, addr, &v) == KERN_SUCCESS else { return nil }
        return v
    }
    
    func read64(_ addr: UInt64) -> UInt64? {
        var v: UInt64 = 0
        guard let fn = kread64, fn(targetTask, addr, &v) == KERN_SUCCESS else { return nil }
        return v
    }
    
    func readFloat(_ addr: UInt64) -> Float? {
        guard let v = read32(addr) else { return nil }
        return Float(bitPattern: v)
    }
    
    func readVec3(_ addr: UInt64) -> SIMD3<Float>? {
        guard let x = readFloat(addr), let y = readFloat(addr + 4), let z = readFloat(addr + 8) else { return nil }
        return SIMD3<Float>(x, y, z)
    }
}
