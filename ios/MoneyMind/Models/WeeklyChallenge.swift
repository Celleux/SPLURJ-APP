import Foundation
import SwiftData

@Model
class WeeklyChallenge {
    var id: String = ""
    var title: String = ""
    var challengeDescription: String = ""
    var target: Int = 0
    var current: Int = 0
    var rewardType: String = "epicCard"
    var startsAt: Date = Date()
    var endsAt: Date = Date()
    var claimed: Bool = false

    var isComplete: Bool { current >= target }
    var progressFraction: Double { target > 0 ? min(1.0, Double(current) / Double(target)) : 0 }

    var timeRemaining: String {
        let now = Date()
        guard endsAt > now else { return "Ended" }
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: endsAt)
        if let days = components.day, days > 0 {
            return "\(days)d \(components.hour ?? 0)h left"
        }
        return "\(components.hour ?? 0)h left"
    }

    var rewardLabel: String {
        switch rewardType {
        case "epicCard": return "Epic Card"
        case "essence100": return "100 Essence"
        case "essence200": return "200 Essence"
        case "xpBomb": return "500 XP Bomb"
        default: return "Reward"
        }
    }

    var rewardIcon: String {
        switch rewardType {
        case "epicCard": return "sparkles.rectangle.stack"
        case "essence100", "essence200": return "diamond.fill"
        case "xpBomb": return "bolt.fill"
        default: return "gift.fill"
        }
    }

    init(id: String, title: String, description: String, target: Int, rewardType: String, startsAt: Date, endsAt: Date) {
        self.id = id
        self.title = title
        self.challengeDescription = description
        self.target = target
        self.rewardType = rewardType
        self.startsAt = startsAt
        self.endsAt = endsAt
    }
}
