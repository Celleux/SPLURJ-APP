import Foundation
import SwiftUI

nonisolated enum QuestCategory: String, Codable, Sendable, Hashable {
    case spendingDefense
    case financialLiteracy
    case incomeEarning
    case moneyRecovery
    case socialQuests
    case generosity

    @MainActor var color: Color {
        switch self {
        case .spendingDefense: Theme.accent
        case .financialLiteracy: Color(hex: 0x60A5FA)
        case .incomeEarning: Theme.accent
        case .moneyRecovery: Color(hex: 0xFB923C)
        case .socialQuests: Color(hex: 0xF472B6)
        case .generosity: Theme.accentTertiary
        }
    }

    @MainActor var icon: String {
        switch self {
        case .spendingDefense: "shield.lefthalf.filled"
        case .financialLiteracy: "book.fill"
        case .incomeEarning: "dollarsign.circle.fill"
        case .moneyRecovery: "arrow.uturn.up.circle.fill"
        case .socialQuests: "person.2.fill"
        case .generosity: "heart.circle.fill"
        }
    }
}

nonisolated enum QuestDifficulty: String, Codable, Sendable, Hashable {
    case easy
    case medium
    case hard
    case legendary

    var xpMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .legendary: return 3.0
        }
    }

    @MainActor var color: Color {
        switch self {
        case .easy: Theme.accent
        case .medium: Color(hex: 0xFB923C)
        case .hard: Color(hex: 0xF87171)
        case .legendary: Theme.gold
        }
    }
}

nonisolated enum QuestCadence: String, Codable, Sendable, Hashable {
    case daily
    case weekly
    case seasonal
    case story
}

nonisolated enum QuestStatus: String, Codable, Sendable {
    case available
    case active
    case completed
    case claimed
    case archived
    case expired
}
