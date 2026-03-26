import SwiftUI

enum ShareAchievementType {
    case streak(days: Int)
    case saved(amount: Double)
    case level(level: Int)
    case collection(collected: Int, total: Int, setName: String)
    case quest(name: String)

    var shareText: String {
        switch self {
        case .streak(let days): "I'm on a \(days)-day streak on Splurj!"
        case .saved(let amount): "I've saved \(String(format: "$%.0f", amount)) with Splurj!"
        case .level(let level): "I just reached Level \(level) on Splurj!"
        case .collection(_, _, let setName): "I completed the \(setName) collection on Splurj!"
        case .quest(let name): "I just completed the \(name) quest on Splurj!"
        }
    }

    var icon: String {
        switch self {
        case .streak: "flame.fill"
        case .saved: "dollarsign.circle.fill"
        case .level: "star.fill"
        case .collection: "checkmark.seal.fill"
        case .quest: "flag.checkered"
        }
    }

    var label: String {
        switch self {
        case .streak(let days): "\(days)-Day Streak"
        case .saved(let amount): String(format: "$%.0f Saved", amount)
        case .level(let level): "Level \(level)"
        case .collection(_, _, let setName): "\(setName) Complete"
        case .quest(let name): name
        }
    }
}

enum ShareButtonStyle {
    case pill
    case card
    case icon
    case compact
}

struct ShareAchievementButton: View {
    let type: ShareAchievementType
    let level: Int
    let archetypeName: String
    var style: ShareButtonStyle = .pill

    var body: some View {
        ShareLink(
            item: type.shareText,
            preview: SharePreview("My Splurj Achievement", image: Image(systemName: type.icon))
        ) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(Typography.labelSmall)
                Text(type.label)
                    .font(Typography.labelSmall)
                Image(systemName: "square.and.arrow.up")
                    .font(Typography.labelSmall)
            }
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.accent.opacity(0.1), in: Capsule())
            .overlay(Capsule().stroke(Theme.accent.opacity(0.3), lineWidth: 0.5))
        }
    }
}
