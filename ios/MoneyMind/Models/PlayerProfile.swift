import Foundation
import SwiftData

@Model
class PlayerProfile {
    var level: Int = 1
    var totalXP: Int = 0
    var currentZone: String = "The Awakening"
    var questStreak: Int = 0
    var longestStreak: Int = 0
    var totalQuestsCompleted: Int = 0
    var totalMoneySaved: Double = 0
    var totalMoneyRecovered: Double = 0
    var bossesDefeatedData: Data = Data()
    var unlockedBadgesData: Data = Data()
    var activeTitle: String = "Rookie Saver"
    var avatarStage: Int = 0
    var currentBossZone: String?
    var currentBossDamageDealt: Int = 0
    var lastQuestDate: Date?
    var doubleXPUntil: Date?

    var bossesDefeated: [String] {
        get { (try? JSONDecoder().decode([String].self, from: bossesDefeatedData)) ?? [] }
        set { bossesDefeatedData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var unlockedBadges: [String] {
        get { (try? JSONDecoder().decode([String].self, from: unlockedBadgesData)) ?? [] }
        set { unlockedBadgesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init() {}

    func xpForLevel(_ level: Int) -> Int {
        Int(100 * pow(1.4, Double(level - 1)))
    }

    var xpForCurrentLevel: Int { xpForLevel(level) }

    var xpProgressInCurrentLevel: Int {
        var remaining = totalXP
        for l in 1..<level {
            remaining -= xpForLevel(l)
        }
        return max(0, remaining)
    }

    var xpProgressFraction: Double {
        guard xpForCurrentLevel > 0 else { return 0 }
        return min(1.0, Double(xpProgressInCurrentLevel) / Double(xpForCurrentLevel))
    }

    var currentQuestZone: QuestZone {
        QuestZone.zone(forLevel: level)
    }
}
