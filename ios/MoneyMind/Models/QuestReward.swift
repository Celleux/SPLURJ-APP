import Foundation

struct QuestReward {
    let xp: Int
    let scratchCard: Bool
    let essence: Int
    let didLevelUp: Bool
    let newLevel: Int
    let isLucky: Bool
    let bossDamage: Int
    let tiktokMoment: String?
    let streakBonusCards: Int
    let hasDoubleXP: Bool

    static let empty = QuestReward(
        xp: 0,
        scratchCard: false,
        essence: 0,
        didLevelUp: false,
        newLevel: 1,
        isLucky: false,
        bossDamage: 0,
        tiktokMoment: nil,
        streakBonusCards: 0,
        hasDoubleXP: false
    )
}
