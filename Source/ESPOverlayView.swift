// 花来 - 透明 ESP 悬浮层
import UIKit

final class ESPOverlayView: UIView {
    private let espLayer = CALayer()
    private let panel = UIButton(type: .system)
    private var displayLink: CADisplayLink?
    private var controlPanel: ControlPanel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = .clear
        espLayer.frame = bounds
        layer.addSublayer(espLayer)
        setupFloatingButton()
        startDisplayLink()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        espLayer.frame = bounds
    }

    deinit { displayLink?.invalidate() }

    private func setupFloatingButton() {
        panel.setTitle("花", for: .normal)
        panel.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        panel.setTitleColor(.white, for: .normal)
        panel.backgroundColor = Theme.accent.withAlphaComponent(0.85)
        panel.layer.cornerRadius = 26
        panel.layer.shadowColor = UIColor.black.cgColor
        panel.layer.shadowOpacity = 0.4
        panel.layer.shadowRadius = 10
        panel.layer.shadowOffset = CGSize(width: 0, height: 4)
        panel.frame = CGRect(x: 24, y: 120, width: 52, height: 52)
        panel.addTarget(self, action: #selector(togglePanel), for: .touchUpInside)
        addSubview(panel)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(dragButton(_:)))
        panel.addGestureRecognizer(pan)
    }

    @objc private func togglePanel() {
        if let existing = controlPanel {
            existing.isHidden.toggle()
            return
        }
        let panelView = ControlPanel(overlay: self)
        let width = min(Theme.panelWidth, bounds.width - 40)
        let height = min(520, bounds.height - 160)
        panelView.frame = CGRect(x: max(20, bounds.width - width - 20),
                                 y: 90,
                                 width: width,
                                 height: height)
        panelView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        addSubview(panelView)
        controlPanel = panelView
    }

    @objc private func dragButton(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        panel.center = CGPoint(x: panel.center.x + translation.x, y: panel.center.y + translation.y)
        gesture.setTranslation(.zero, in: self)
    }

    private func startDisplayLink() {
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.preferredFramesPerSecond = 60
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func step() {
        let session = GameSession.shared
        ESPRenderer.shared.render(in: espLayer,
                                  camera: session.camera,
                                  players: session.players,
                                  screen: bounds.size)
    }
}