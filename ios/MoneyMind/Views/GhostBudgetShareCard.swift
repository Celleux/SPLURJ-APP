import SwiftUI

struct GhostBudgetShareCard: View {
    let savings: Double
    let timeframe: String
    let topHabit: String
    let personalityColor: Color
    let personalityIcon: String

    var body: some View {
        ZStack {
            CardBackground(accentColor: Theme.success, secondaryColor: personalityColor)

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Theme.success)
                        Text("Splurj")
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Text("👻 Ghost Budget")
                        .font(Typography.bodySmall)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 24) {
                    Text("If I stopped spending on")
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white.opacity(0.6))

                    Text(topHabit)
                        .font(Typography.displayMedium)
                        .foregroundStyle(personalityColor)

                    VStack(spacing: 8) {
                        Text("I'd have")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.white.opacity(0.5))

                        Text("$\(Int(savings))")
                            .font(Typography.displayLarge)
                            .foregroundStyle(Theme.success)

                        Text("more in \(timeframe)")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.success.opacity(0.7))
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Theme.card)
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Theme.success.opacity(0.2), lineWidth: 1)
                        }
                    )
                    .padding(.horizontal, 24)

                    ZStack {
                        Circle()
                            .fill(personalityColor.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Image(systemName: personalityIcon)
                            .font(Typography.displayMedium)
                            .foregroundStyle(personalityColor)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Text("Made with Splurj")
                        .font(Typography.bodySmall)
                        .foregroundStyle(.white.opacity(0.3))
                    CardWatermark()
                }
                .padding(.bottom, 50)
            }
        }
        .frame(width: ShareCardRenderer.viewSize.width, height: ShareCardRenderer.viewSize.height)
        .preferredColorScheme(.dark)
    }
}
