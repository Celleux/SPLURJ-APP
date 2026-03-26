import SwiftUI

nonisolated enum CardRarity: String, Codable, CaseIterable, Sendable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var color: Color {
        switch self {
        case .common: return Theme.textSecondary
        case .uncommon: return Theme.accent
        case .rare: return Theme.axisEmotional
        case .epic: return Theme.lavender
        case .legendary: return Theme.gold
        }
    }

    var glowOpacity: Double {
        switch self {
        case .common: return 0
        case .uncommon: return 0.1
        case .rare: return 0.2
        case .epic: return 0.35
        case .legendary: return 0.5
        }
    }

    var label: String {
        switch self {
        case .common: return "★"
        case .uncommon: return "★★"
        case .rare: return "★★★"
        case .epic: return "★★★★"
        case .legendary: return "★★★★★"
        }
    }
}
