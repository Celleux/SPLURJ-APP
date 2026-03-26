import SwiftUI

struct AllQuestsCompleteCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(Typography.displayLarge)
                .foregroundStyle(Theme.accent)
                .symbolEffect(.pulse)

            Text("All Quests Complete")
                .font(Typography.headingLarge)
                .foregroundStyle(.white)

            Text("You conquered today's challenges. New quests arrive at midnight")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}
