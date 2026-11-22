// 花来 - IPC 通信
import Foundation

final class IPCManager {
    static let shared = IPCManager()
    private init() {}

    func notify(_ name: String, payload: [String: Any]? = nil) {

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            name as CFString,
            nil, nil, true
        )
        NotificationCenter.default.post(name: Notification.Name(name), object: nil, userInfo: payload)
    }

    func sendShow() { notify("com.cz.esp.runtime.show") }
    func sendHide() { notify("com.cz.esp.runtime.hide") }
    func attachObserver(_ name: String, handler: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { _ in handler() }
    }
}