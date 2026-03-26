import SwiftUI

struct ChallengeEliminationView: View {
    let participant: ChallengeParticipant
    let moneySaved: Double
    let totalDays: Int
    let groupTotalSavings: Double
    let challengeName: String
    let isVoluntary: Bool
    let onContinueAsSpectator: () -> Void
    let onShare: (UIImage) -> Void

    @State private var showContent = false
    @State private var avatarScale: CGFloat = 0.3
    @State private var avatarPulse = false
    @State private var shareImage: UIImage?

    private var title: String {
        isVoluntary ? "You stepped back" : "Your active run has ended"
    }

    private var subtitle: String {
        "But what you built is real."
    }

    private var daysHeld: Int {
        participant.successfulCheckIns
    }

    private var bestStreak: Int {
        participant.longestStreak
    }

    private var successRate: Double {
        participant.completionRate
    }

    private var groupContribution: Double {
        guard groupTotalSavings > 0 else { return 0 }
        return moneySaved / groupTotalSavings
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.danger.opacity(0.08), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.danger.opacity(0.06), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(avatarPulse ? 0.08 : 0.04))
                            .frame(width: 120, height: 120)

                        Text(participant.emoji.isEmpty ? "👤" : participant.emoji)
                            .font(.system(size: 80))
                    }
                    .scaleEffect(avatarScale)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(Typography.bodyLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)

                    exitSummaryCard
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    Text("You resisted \(daysHeld) times. Each one was a win.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)

                    VStack(spacing: 12) {
                        Button {
                            renderAndShare()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share My Results")
                            }
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.buttonTextOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button {
                            onContinueAsSpectator()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "eye.fill")
                                Text("Continue as Spectator")
                            }
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.elevated, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 24)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            HapticManager.notification(.warning)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                avatarScale = 1.0
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                avatarPulse = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                showContent = true
            }
        }
    }

    private var exitSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Days held")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(daysHeld) of \(totalDays)")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.elevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.accentGradient)
                        .frame(
                            width: totalDays > 0 ? geo.size.width * CGFloat(daysHeld) / CGFloat(totalDays) : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            HStack {
                Text("Money saved")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("$\(Int(moneySaved))")
                    .font(Typography.moneyMedium)
                    .foregroundStyle(Theme.gold)
            }

            HStack {
                Text("Best streak")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(bestStreak) days")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                }
            }

            HStack {
                Text("Success rate")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(successRate * 100))%")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            HStack {
                Text("Group contribution")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(groupContribution * 100))%")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.accent)
            }
        }
        .splurjCard(.hero)
    }

    private func renderAndShare() {
        let card = ChallengeExitShareCard(
            emoji: participant.emoji,
            displayName: participant.displayName,
            daysHeld: daysHeld,
            totalDays: totalDays,
            moneySaved: moneySaved,
            bestStreak: bestStreak,
            successRate: successRate,
            groupContribution: groupContribution,
            challengeName: challengeName
        )
        if let image = ShareCardRenderer.render(card) {
            onShare(image)
        }
    }
}
