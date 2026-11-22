// 花来 - 注入辅助
import Foundation
import Darwin

enum InjectHelper {
    static func locateGameBinary() -> String? {
        guard let pid = GameSession.findProcess(named: BinaryAnalysis.targetProcessName) else { return nil }
        return "/proc/\(pid)"
    }
}