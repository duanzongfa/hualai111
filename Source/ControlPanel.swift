// 花来 - 悬浮控制面板
import UIKit

final class ControlPanel: UIView, UITableViewDataSource, UITableViewDelegate {

    private let titleLabel = UILabel()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let closeButton = UIButton(type: .system)

    private struct Row {
        enum Kind { case toggle, slider, choice }
        let title: String
        let kind: Kind
        let value: () -> String
        let action: (() -> Void)?
    }

    private var sections: [(String, [Row])] = []
    private weak var overlay: UIView?
    private var refreshTimer: Timer?

    init(overlay: UIView) {
        super.init(frame: .zero)
        self.overlay = overlay
        buildUI()
        buildRows()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tableView.reloadData()
            self?.updateStatus()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { refreshTimer?.invalidate() }

    private func buildUI() {
        backgroundColor = Theme.panel
        layer.cornerRadius = Theme.cornerRadius
        layer.borderWidth = 1
        layer.borderColor = Theme.separator.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)

        titleLabel.text = "花来  ·  DELTA FORCE"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = Theme.textPrimary

        statusDot.layer.cornerRadius = 3
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.widthAnchor.constraint(equalToConstant: 6).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 6).isActive = true

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = Theme.textSecondary

        let statusStack = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusStack.axis = .horizontal
        statusStack.spacing = 6
        statusStack.alignment = .center

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), statusStack])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(Theme.textSecondary, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorColor = Theme.separator
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)

        addSubview(headerStack)
        addSubview(closeButton)
        addSubview(tableView)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            closeButton.centerYAnchor.constraint(equalTo: headerStack.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        headerStack.isUserInteractionEnabled = true
        headerStack.addGestureRecognizer(pan)
    }

    private func buildRows() {
        let config = ConfigStore.shared
        sections = [
            ("总控", [
                Row(title: "总开关", kind: .toggle, value: { config.masterEnabled ? "开" : "关" }, action: { config.masterEnabled.toggle() })
            ]),
            ("透视 ESP", [
                Row(title: "透视开关", kind: .toggle, value: { config.espEnabled ? "开" : "关" }, action: { config.espEnabled.toggle() }),
                Row(title: "方框", kind: .toggle, value: { config.showBox ? "开" : "关" }, action: { config.showBox.toggle() }),
                Row(title: "骨骼", kind: .toggle, value: { config.showSkeleton ? "开" : "关" }, action: { config.showSkeleton.toggle() }),
                Row(title: "血量", kind: .toggle, value: { config.showHealth ? "开" : "关" }, action: { config.showHealth.toggle() }),
                Row(title: "距离", kind: .toggle, value: { config.showDistance ? "开" : "关" }, action: { config.showDistance.toggle() }),
                Row(title: "名字", kind: .toggle, value: { config.showName ? "开" : "关" }, action: { config.showName.toggle() }),
                Row(title: "过滤人机", kind: .toggle, value: { config.filterAI ? "开" : "关" }, action: { config.filterAI.toggle() })
            ]),
            ("自瞄", [
                Row(title: "自瞄开关", kind: .toggle, value: { config.aimEnabled ? "开" : "关" }, action: { config.aimEnabled.toggle() }),
                Row(title: "瞄准部位", kind: .choice, value: { config.aimPart.title }, action: { config.aimPart = AimPart(rawValue: (config.aimPart.rawValue + 1) % AimPart.allCases.count) ?? .head }),
                Row(title: "FOV", kind: .slider, value: { String(format: "%.0f", config.aimFov) }, action: nil),
                Row(title: "平滑", kind: .slider, value: { String(format: "%.0f", config.aimSmooth) }, action: nil)
            ]),
            ("渲染", [
                Row(title: "最大距离", kind: .slider, value: { String(format: "%.0fm", config.maxDistance) }, action: nil),
                Row(title: "帧率", kind: .slider, value: { "\(config.targetFPS)" }, action: nil)
            ])
        ]
    }

    private func updateStatus() {
        let session = GameSession.shared
        if session.isRunning {
            statusDot.backgroundColor = Theme.success
            statusLabel.text = session.gamePid != 0 ? "已连接 PID \(session.gamePid)" : "运行中"
        } else {
            statusDot.backgroundColor = Theme.danger
            statusLabel.text = session.lastError ?? "未连接"
        }
    }

    @objc private func handleClose() {
        overlay?.isHidden = true
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview else { return }
        let translation = gesture.translation(in: superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gesture.setTranslation(.zero, in: superview)
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].1.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 46 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let row = sections[indexPath.section].1[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        content.textProperties.color = Theme.textPrimary
        content.textProperties.font = .systemFont(ofSize: 14, weight: .regular)
        content.secondaryText = row.value()
        content.secondaryTextProperties.color = row.kind == .toggle
            ? (row.value() == "开" ? Theme.accent : Theme.textSecondary)
            : Theme.textSecondary
        content.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .semibold)
        cell.contentConfiguration = content
        cell.backgroundColor = Theme.card
        let bg = UIView()
        bg.backgroundColor = Theme.accentSoft
        cell.selectedBackgroundView = bg
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].1[indexPath.row]
        if let action = row.action {
            action()
            tableView.reloadData()
        }
    }
}