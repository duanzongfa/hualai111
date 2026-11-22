// 花来 - 入口
import UIKit

final class HuailaiController {
    static let shared = HuailaiController()
    private init() {}

    private(set) var window: UIWindow?
    private var overlayRoot: UIViewController?

    func initialize() {
        print("[Huailai] controller starting")
        GameSession.shared.start()
        DispatchQueue.main.async { [weak self] in
            self?.installOverlay()
        }
    }

    func installOverlay() {
        guard overlayRoot == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.installOverlay() }
            return
        }

        let root = UIViewController()
        root.view.backgroundColor = .clear
        let overlay = ESPOverlayView(frame: scene.coordinateSpace.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.view.addSubview(overlay)

        let window = UIWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1)
        window.rootViewController = root
        window.backgroundColor = .clear
        window.isHidden = false

        self.window = window
        overlayRoot = root
    }

    func teardown() {
        GameSession.shared.stop()
        overlayRoot = nil
        window?.isHidden = true
        window = nil
    }
}