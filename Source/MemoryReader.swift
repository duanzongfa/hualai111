// 花来 - 内存读取器
import Foundation
import Darwin
import simd

final class KernelMemoryReader {
    static let shared = KernelMemoryReader()

    private(set) var targetPid: pid_t = 0
    private var targetTask: task_t = task_t(0)
    private var kreadFn: ((UInt64, UnsafeMutableRawPointer, Int) -> Int32)?

    private typealias KRWRead = @convention(c) (UInt64, UnsafeMutableRawPointer, Int) -> Int32

    var isAttached: Bool { targetPid != 0 }

    @discardableResult
    func attach(pid: pid_t) -> Bool {
        detach()
        var task = task_t(0)
        let kr = task_for_pid(mach_task_self_, pid, &task)
        guard kr == KERN_SUCCESS, task != 0 else { return false }
        targetPid = pid
        targetTask = task
        loadKernelReader()
        return true
    }

    func detach() {
        if targetTask != 0 {
            mach_port_deallocate(mach_task_self_, targetTask)
        }
        targetTask = task_t(0)
        targetPid = 0
    }

    private func loadKernelReader() {
        let candidates = [
            "/usr/lib/libkrw.dylib",
            "/var/jb/usr/lib/libkrw.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/libkrw.dylib",
            "/var/jb/Library/MobileSubstrate/DynamicLibraries/libkrw.dylib"
        ]
        for path in candidates {
            guard let handle = dlopen(path, RTLD_LAZY) else { continue }
            if let sym = dlsym(handle, "kread") ?? dlsym(handle, "_kread") {
                kreadFn = unsafeBitCast(sym, to: KRWRead.self)
                return
            }
        }
    }

    func read(_ address: UInt64, into buffer: UnsafeMutableRawPointer, size: Int) -> Bool {
        guard size > 0 else { return false }

        if let fn = kreadFn, fn(address, buffer, size) == 0 {
            return true
        }

        guard targetTask != 0 else { return false }
        var copied: vm_size_t = 0
        let kr = vm_read_overwrite(targetTask,
                                   vm_address_t(address),
                                   vm_size_t(size),
                                   vm_address_t(UInt(bitPattern: buffer)),
                                   &copied)
        return kr == KERN_SUCCESS && copied == vm_size_t(size)
    }

    func readU32(_ address: UInt64) -> UInt32? {
        var value: UInt32 = 0
        guard read(address, into: &value, size: MemoryLayout<UInt32>.size) else { return nil }
        return value
    }

    func readU64(_ address: UInt64) -> UInt64? {
        var value: UInt64 = 0
        guard read(address, into: &value, size: MemoryLayout<UInt64>.size) else { return nil }
        return value
    }

    func readI32(_ address: UInt64) -> Int32? {
        var value: Int32 = 0
        guard read(address, into: &value, size: MemoryLayout<Int32>.size) else { return nil }
        return value
    }

    func readFloat(_ address: UInt64) -> Float? {
        var value: Float = 0
        guard read(address, into: &value, size: MemoryLayout<Float>.size) else { return nil }
        return value
    }

    func readVec3(_ address: UInt64) -> SIMD3<Float>? {
        var value = SIMD3<Float>.zero
        guard read(address, into: &value, size: MemoryLayout<SIMD3<Float>>.size) else { return nil }
        return value
    }

    func readMatrix4x4(_ address: UInt64) -> matrix_float4x4? {
        var value = matrix_identity_float4x4
        guard read(address, into: &value, size: MemoryLayout<matrix_float4x4>.size) else { return nil }
        return value
    }
}