import SwiftUI

nonisolated enum CardSet: String, Codable, CaseIterable, Sendable {
    case saversGuild = "The Savers Guild"
    case compoundInterest = "Masters of Compound Interest"
    case budgetWarriors = "Budget Warriors"
    case debtSlayers = "Debt Slayers"
    case impulseDefenders = "Impulse Defenders"

    var icon: String {
        switch self {
        case .saversGuild: return "shield.checkered"
        case .compoundInterest: return "chart.line.uptrend.xyaxis"
        case .budgetWarriors: return "figure.fencing"
        case .debtSlayers: return "bolt.shield.fill"
        case .impulseDefenders: return "hand.raised.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .saversGuild: return Theme.accent
        case .compoundInterest: return Theme.gold
        case .budgetWarriors: return Theme.axisEmotional
        case .debtSlayers: return Theme.bossRed
        case .impulseDefenders: return Theme.lavender
        }
    }

    var totalCards: Int { 10 }
}
