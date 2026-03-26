import Foundation

nonisolated enum VibeType: String, CaseIterable, Codable, Sendable {
    case worthIt = "Worth It"
    case meh = "Meh"
    case regret = "Regret"
    case necessary = "Necessary"
    case flex = "Flex"

    var emoji: String {
        switch self {
        case .worthIt: "\u{1F44D}"
        case .meh: "\u{1F610}"
        case .regret: "\u{1F62C}"
        case .necessary: "\u{1F937}"
        case .flex: "\u{1F60E}"
        }
    }

    var sentiment: Float {
        switch self {
        case .worthIt: 0.8
        case .meh: 0.0
        case .regret: -0.8
        case .necessary: 0.3
        case .flex: 0.6
        }
    }

    var label: String { rawValue }

    init?(fromEmoji emoji: String) {
        switch emoji {
        case "\u{1F44D}": self = .worthIt
        case "\u{1F610}": self = .meh
        case "\u{1F62C}": self = .regret
        case "\u{1F937}": self = .necessary
        case "\u{1F60E}": self = .flex
        case "\u{1F911}": self = .worthIt
        case "\u{2705}": self = .necessary
        case "\u{1F4AA}": self = .flex
        default: return nil
        }
    }
}
