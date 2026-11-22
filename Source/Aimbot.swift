// 花来 - 自瞄模块 (修复版)
import Foundation

class Aimbot {
    static let shared = Aimbot()
    private var config = RuntimeConfig()
    
    func update() {
        guard config.aimEnabled else { return }
        // TODO: 实现自瞄逻辑
    }
}

extension PlayerEntity {
    var isEnemy: Bool {
        return teamId != CheatGameState.shared.localPlayerTeamId
    }
}
