import SwiftUI

nonisolated enum QuestZone: String, Codable, CaseIterable, Sendable {
    case awakening = "The Awakening"
    case budgetForge = "The Budget Forge"
    case savingsCitadel = "The Savings Citadel"
    case incomeFrontier = "The Income Frontier"
    case legacy = "The Legacy"

    var levelRange: ClosedRange<Int> {
        switch self {
        case .awakening: return 1...10
        case .budgetForge: return 11...20
        case .savingsCitadel: return 21...30
        case .incomeFrontier: return 31...40
        case .legacy: return 41...50
        }
    }

    var themeDescription: String {
        switch self {
        case .awakening: return "Financial awareness. Look at your money. Counter the ostrich effect."
        case .budgetForge: return "Spending control. First no-spend day, first budget, first impulse wait."
        case .savingsCitadel: return "Active savings. Automation, HYSA, bill negotiation, emergency fund."
        case .incomeFrontier: return "Income growth. Sell items, salary research, side hustles, raises."
        case .legacy: return "Long-term wealth. Investing, retirement, mentoring, financial independence."
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .awakening: return [Theme.background, Color(hex: 0x1E2230)]
        case .budgetForge: return [Theme.background, Color(hex: 0x1E1828)]
        case .savingsCitadel: return [Theme.background, Color(hex: 0x162824)]
        case .incomeFrontier: return [Theme.background, Color(hex: 0x2A1E10)]
        case .legacy: return [Theme.background, Color(hex: 0x1E1E10)]
        }
    }

    var bossName: String {
        switch self {
        case .awakening: return "The Mirror of Truth"
        case .budgetForge: return "The Overdraft Ogre"
        case .savingsCitadel: return "The Emergency Fund Colossus"
        case .incomeFrontier: return "The Income Dragon"
        case .legacy: return "The Final Boss"
        }
    }

    var bossHP: Int {
        switch self {
        case .awakening: return 100
        case .budgetForge: return 200
        case .savingsCitadel: return 500
        case .incomeFrontier: return 1000
        case .legacy: return 2000
        }
    }

    var bossDescription: String {
        switch self {
        case .awakening: return "Complete a full financial snapshot"
        case .budgetForge: return "30 consecutive days without overdraft fees"
        case .savingsCitadel: return "Reach $1,000 in savings"
        case .incomeFrontier: return "Earn $500 from non-primary income sources"
        case .legacy: return "Achieve positive net worth"
        }
    }

    var sfSymbol: String {
        switch self {
        case .awakening: return "eye.fill"
        case .budgetForge: return "hammer.fill"
        case .savingsCitadel: return "building.columns.fill"
        case .incomeFrontier: return "mountain.2.fill"
        case .legacy: return "crown.fill"
        }
    }

    static func zone(forLevel level: Int) -> QuestZone {
        allCases.first { $0.levelRange.contains(level) } ?? .awakening
    }
}
