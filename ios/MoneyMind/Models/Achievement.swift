import Foundation
import SwiftData

nonisolated enum AchievementType: String, Codable, Sendable {
    case badge
    case card
}

@Model
class Achievement {
    var typeRaw: String

    @Attribute(.unique) var name: String
    var category: String
    var achievementDescription: String
    var iconName: String
    var dateEarned: Date?
    var isEarned: Bool

    var cardID: String
    var rarity: String
    var setName: String
    var obtainedAt: Date
    var duplicateCount: Int
    var isNew: Bool
    var evolutionLevel: Int

    var achievementType: AchievementType {
        get { AchievementType(rawValue: typeRaw) ?? .badge }
        set { typeRaw = newValue.rawValue }
    }

    var isMaxEvolved: Bool { evolutionLevel >= 2 }

    private init(type: AchievementType) {
        self.typeRaw = type.rawValue
        self.name = UUID().uuidString
        self.category = ""
        self.achievementDescription = ""
        self.iconName = ""
        self.dateEarned = nil
        self.isEarned = false
        self.cardID = ""
        self.rarity = "Common"
        self.setName = ""
        self.obtainedAt = Date()
        self.duplicateCount = 0
        self.isNew = true
        self.evolutionLevel = 0
    }

    static func badge(name: String, category: String, badgeDescription: String, iconName: String) -> Achievement {
        let a = Achievement(type: .badge)
        a.name = name
        a.category = category
        a.achievementDescription = badgeDescription
        a.iconName = iconName
        return a
    }

    static func card(cardID: String, rarity: String, setName: String) -> Achievement {
        let a = Achievement(type: .card)
        a.name = "card_\(cardID)_\(UUID().uuidString.prefix(8))"
        a.cardID = cardID
        a.rarity = rarity
        a.setName = setName
        return a
    }
}

nonisolated enum BadgeCategory: String, CaseIterable, Sendable {
    case money = "Money"
    case streak = "Streak"
    case skill = "Skill"
}

nonisolated struct BadgeInfo: Sendable {
    let name: String
    let category: String
    let description: String
    let icon: String
}

nonisolated enum BadgeDefinition: Sendable {
    static let all: [BadgeInfo] = [
        BadgeInfo(name: "First Save", category: "Money", description: "Logged your first avoided purchase", icon: "star.fill"),
        BadgeInfo(name: "$100 Saved", category: "Money", description: "Saved a total of $100", icon: "dollarsign.circle.fill"),
        BadgeInfo(name: "$500 Saved", category: "Money", description: "Saved a total of $500", icon: "banknote.fill"),
        BadgeInfo(name: "$1,000 Saved", category: "Money", description: "Reached the $1,000 savings milestone", icon: "crown.fill"),
        BadgeInfo(name: "$5,000 Saved", category: "Money", description: "An incredible $5,000 saved", icon: "trophy.fill"),
        BadgeInfo(name: "$10,000 Saved", category: "Money", description: "Five figures of savings — extraordinary", icon: "medal.star.fill"),
        BadgeInfo(name: "$25,000 Saved", category: "Money", description: "A life-changing amount saved", icon: "sparkles"),

        BadgeInfo(name: "3-Day Streak", category: "Streak", description: "Maintained a 3-day streak", icon: "flame.fill"),
        BadgeInfo(name: "7-Day Streak", category: "Streak", description: "A full week of mindful choices", icon: "flame.fill"),
        BadgeInfo(name: "14-Day Streak", category: "Streak", description: "Two weeks of consistency", icon: "flame.circle.fill"),
        BadgeInfo(name: "30-Day Streak", category: "Streak", description: "One month of dedication", icon: "flame.circle.fill"),
        BadgeInfo(name: "60-Day Streak", category: "Streak", description: "Two months of commitment", icon: "star.circle.fill"),
        BadgeInfo(name: "90-Day Streak", category: "Streak", description: "Three months — truly transformative", icon: "medal.fill"),

        BadgeInfo(name: "First Urge Surf", category: "Skill", description: "Completed your first urge surf session", icon: "water.waves"),
        BadgeInfo(name: "First HALT Check", category: "Skill", description: "Completed your first HALT check-in", icon: "heart.text.clipboard.fill"),
        BadgeInfo(name: "Session 1 Complete", category: "Skill", description: "Completed Understanding Your Money Brain", icon: "brain.fill"),
        BadgeInfo(name: "Session 2 Complete", category: "Skill", description: "Completed Catching Irrational Thoughts", icon: "lightbulb.fill"),
        BadgeInfo(name: "Session 3 Complete", category: "Skill", description: "Completed Building Your Coping Toolkit", icon: "wrench.and.screwdriver.fill"),
        BadgeInfo(name: "Session 4 Complete", category: "Skill", description: "Mastered problem-solving high-risk situations", icon: "exclamationmark.shield.fill"),
        BadgeInfo(name: "Session 5 Complete", category: "Skill", description: "Built your support network", icon: "person.3.fill"),
        BadgeInfo(name: "Session 6 Complete", category: "Skill", description: "Completed your financial consequences audit", icon: "chart.line.downtrend.xyaxis"),
        BadgeInfo(name: "Session 7 Complete", category: "Skill", description: "Created your alternative behaviors plan", icon: "arrow.triangle.swap"),
        BadgeInfo(name: "Session 8 Complete", category: "Skill", description: "Built your relapse prevention plan", icon: "shield.checkered"),
        BadgeInfo(name: "Honest Reflection", category: "Skill", description: "Completed your first spending autopsy", icon: "magnifyingglass"),
        BadgeInfo(name: "If-Then Planner", category: "Skill", description: "Created your first implementation intention", icon: "arrow.triangle.branch"),
        BadgeInfo(name: "Program Graduate", category: "Skill", description: "Completed all 8 sessions of the Splurj Program", icon: "graduationcap.fill"),
        BadgeInfo(name: "Connector", category: "Skill", description: "Invited a friend to Splurj", icon: "person.badge.plus"),
        BadgeInfo(name: "Challenge Champion", category: "Skill", description: "Completed a Friend Challenge", icon: "trophy.fill"),
    ]
}
