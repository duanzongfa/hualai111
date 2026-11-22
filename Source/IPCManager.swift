// 花来 - IPC 通信管理器 (修复版)
import Foundation

class IPCManager {
    static let shared = IPCManager()
    private let notificationCenter = NotificationCenter.default
    
    func observeReady() {
        notificationCenter.addObserver(
            forName: Notification.Name(IPCNotification.runtimeReady.rawValue),
            object: nil, queue: .main
        ) { _ in print("[Huailai] Game ready") }
    }
    
    func sendShow() {
        notificationCenter.post(name: Notification.Name(IPCNotification.espShow.rawValue), object: nil)
    }
    
    func sendHide() {
        notificationCenter.post(name: Notification.Name(IPCNotification.espHide.rawValue), object: nil)
    }
}
