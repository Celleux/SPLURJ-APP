import SwiftUI

nonisolated enum MoneyPersonality: String, CaseIterable, Codable, Sendable {
    case saver = "The Saver"
    case builder = "The Builder"
    case hustler = "The Hustler"
    case minimalist = "The Minimalist"
    case generous = "The Generous"

    var toArchetype: FinancialArchetype {
        switch self {
        case .saver: .guardian
        case .builder: .visionary
        case .hustler: .adventurer
        case .minimalist: .strategist
        case .generous: .empath
        }
    }

    var icon: String {
        switch self {
        case .saver: "leaf.fill"
        case .builder: "chart.line.uptrend.xyaxis"
        case .hustler: "flame.fill"
        case .minimalist: "sparkles"
        case .generous: "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .saver: Color(hex: 0x00E676)
        case .builder: Color(hex: 0x6C5CE7)
        case .hustler: Color(hex: 0xFF9100)
        case .minimalist: Color(hex: 0x00D2FF)
        case .generous: Color(hex: 0xFFD700)
        }
    }

    var traits: [String] {
        switch self {
        case .saver: ["Patient", "Strategic", "Future-focused"]
        case .builder: ["Ambitious", "Analytical", "Growth-driven"]
        case .hustler: ["Bold", "Resourceful", "Action-oriented"]
        case .minimalist: ["Intentional", "Peaceful", "Experience-driven"]
        case .generous: ["Compassionate", "Abundant", "Community-minded"]
        }
    }

    var description: String {
        switch self {
        case .saver:
            "You find security in growing your nest egg. Every dollar saved feels like a win, and you naturally think long-term."
        case .builder:
            "You see money as fuel for growth. Investments, side projects, career moves — you're always building toward something bigger."
        case .hustler:
            "You're energized by opportunity. Whether it's a deal, a side gig, or a bold bet, you thrive on making things happen."
        case .minimalist:
            "You value freedom over things. Money is a tool for experiences and peace of mind, not possessions."
        case .generous:
            "You light up when sharing with others. Your generosity creates connection, but sometimes at the cost of your own goals."
        }
    }
}
