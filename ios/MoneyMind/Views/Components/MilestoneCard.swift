import SwiftUI
import PhosphorSwift

struct MilestoneCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isCompleted: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isCompleted ? accentColor.opacity(0.15) : Theme.elevated)
                    .frame(width: 48, height: 48)
                    .shadow(color: isCompleted ? accentColor.opacity(0.3) : .clear, radius: 8)

                Image(systemName: icon)
                    .font(Typography.headingLarge)
                    .foregroundStyle(isCompleted ? accentColor : Theme.textMuted.opacity(0.3))
            }

            Text(title)
                .font(Typography.labelSmall)
                .foregroundStyle(isCompleted ? .white : Theme.textMuted)

            Text(subtitle)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if isCompleted {
                PhIcon.checkCircleFill
                    .frame(width: 16, height: 16)
                    .foregroundStyle(accentColor)
            }
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .splurjCard(.subtle)
    }
}
