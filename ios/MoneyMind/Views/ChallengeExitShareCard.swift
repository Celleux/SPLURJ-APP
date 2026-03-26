import SwiftUI

struct ChallengeExitShareCard: View {
    let emoji: String
    let displayName: String
    let daysHeld: Int
    let totalDays: Int
    let moneySaved: Double
    let bestStreak: Int
    let successRate: Double
    let groupContribution: Double
    let challengeName: String

    var body: some View {
        ZStack {
            CardBackground(accentColor: Theme.accent, secondaryColor: Theme.danger)

            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Text(emoji)
                    .font(.system(size: 64))

                VStack(spacing: 6) {
                    Text(displayName)
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text(challengeName)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 16) {
                    exitStatRow(label: "Days held", value: "\(daysHeld) of \(totalDays)")
                    exitStatRow(label: "Money saved", value: "$\(Int(moneySaved))", isGold: true)
                    exitStatRow(label: "Best streak", value: "\(bestStreak) days 🔥")
                    exitStatRow(label: "Success rate", value: "\(Int(successRate * 100))%")
                    exitStatRow(label: "Group contribution", value: "\(Int(groupContribution * 100))%")
                }
                .padding(20)
                .background(Theme.elevated, in: .rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                VStack(spacing: 4) {
                    Text("I resisted \(daysHeld) times.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Each one was a win.")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.accent)
                }

                Spacer()

                CardWatermark()
                    .padding(.bottom, 20)
            }
        }
        .frame(width: ShareCardRenderer.viewSize.width, height: ShareCardRenderer.viewSize.height)
    }

    private func exitStatRow(label: String, value: String, isGold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Typography.headingSmall)
                .foregroundStyle(isGold ? Theme.gold : Theme.textPrimary)
        }
    }
}
