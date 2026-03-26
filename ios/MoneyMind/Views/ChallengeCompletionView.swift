import SwiftUI

struct ChallengeCompletionView: View {
    let participants: [ChallengeParticipant]
    let groupTotalSavings: Double
    let challengeName: String
    let goalSavingFor: String
    let startDate: Date
    let endDate: Date
    let currentUserIsSpectator: Bool
    let currentUserSavings: Double
    let onDismiss: () -> Void
    let onShare: (UIImage) -> Void

    @State private var showContent = false
    @State private var confettiPhase: CGFloat = 0
    @State private var crownBounce = false

    private var completedParticipants: [ChallengeParticipant] {
        participants.filter { $0.status == "completed" }
    }

    private var durationDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }

    private var confettiParticles: [CompletionConfetti] {
        (0..<60).map { _ in
            CompletionConfetti(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.3...0),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.2),
                color: [Theme.accent, Theme.gold, Theme.accentSecondary, Theme.accentBright, .white].randomElement()!
            )
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            Canvas { context, size in
                for particle in confettiParticles {
                    let x = particle.x * size.width
                    let targetY = size.height * 1.2
                    let currentY = (particle.y * size.height) + (targetY * confettiPhase)
                    let rotation = Angle.degrees(particle.rotation + Double(confettiPhase) * 360)

                    context.opacity = max(0, 1.0 - Double(confettiPhase) * 0.6)
                    context.translateBy(x: x, y: currentY)
                    context.rotate(by: rotation)
                    context.scaleBy(x: particle.scale, y: particle.scale)

                    let rect = CGRect(x: -4, y: -6, width: 8, height: 12)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )

                    context.scaleBy(x: 1 / particle.scale, y: 1 / particle.scale)
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -currentY)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    ZStack {
                        Circle()
                            .fill(Theme.gold.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(Theme.gold.opacity(0.2))
                            .frame(width: 72, height: 72)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.gold)
                            .symbolEffect(.bounce, value: crownBounce)
                    }
                    .scaleEffect(showContent ? 1 : 0.3)
                    .opacity(showContent ? 1 : 0)

                    Text("Challenge Complete!")
                        .font(Typography.displayLarge)
                        .foregroundStyle(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    if !goalSavingFor.isEmpty {
                        Text("Time to \(goalSavingFor)!")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.gold)
                            .opacity(showContent ? 1 : 0)
                    }

                    championsRow
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 16)

                    groupStatsCard
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    if currentUserIsSpectator {
                        Text("The challenge is complete! You contributed $\(Int(currentUserSavings)).")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .opacity(showContent ? 1 : 0)
                    }

                    VStack(spacing: 12) {
                        Button {
                            renderAndShare()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Results")
                            }
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.buttonTextOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button {
                            onDismiss()
                        } label: {
                            Text("Continue")
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
            HapticManager.notification(.success)
            crownBounce.toggle()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 2.5)) {
                confettiPhase = 1
            }
        }
    }

    private var championsRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: -6) {
                ForEach(completedParticipants.prefix(10), id: \.id) { p in
                    ZStack {
                        Circle()
                            .fill(Theme.gold.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Circle()
                            .strokeBorder(Theme.gold, lineWidth: 2)
                            .frame(width: 48, height: 48)
                        Text(p.emoji.isEmpty ? "👤" : p.emoji)
                            .font(.system(size: 22))
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.gold)
                            .offset(y: -22)
                    }
                    .frame(width: 52, height: 56)
                }
            }

            Text("\(completedParticipants.count) Challenge Champion\(completedParticipants.count == 1 ? "" : "s")")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.gold)
        }
    }

    private var groupStatsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(challengeName)
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            HStack {
                Text("Duration")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(durationDays) days")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            HStack {
                Text("Group savings")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("$\(Int(groupTotalSavings))")
                    .font(Typography.moneyMedium)
                    .foregroundStyle(Theme.gold)
            }

            HStack {
                Text("Completers")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(completedParticipants.count) of \(participants.count)")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            Theme.divider.frame(height: 0.5)

            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                Text("Challenge your friends on MoneyMind")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .splurjCard(.hero)
    }

    private func renderAndShare() {
        let card = ChallengeCompletionShareCard(
            participants: participants,
            groupTotalSavings: groupTotalSavings,
            challengeName: challengeName,
            goalSavingFor: goalSavingFor,
            durationDays: durationDays
        )
        if let image = ShareCardRenderer.render(card) {
            onShare(image)
        }
    }
}

private struct CompletionConfetti {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color
}

struct ChallengeCompletionShareCard: View {
    let participants: [ChallengeParticipant]
    let groupTotalSavings: Double
    let challengeName: String
    let goalSavingFor: String
    let durationDays: Int

    private var completedParticipants: [ChallengeParticipant] {
        participants.filter { $0.status == "completed" }
    }

    var body: some View {
        ZStack {
            CardBackground(accentColor: Theme.gold, secondaryColor: Theme.accent)

            VStack(spacing: 24) {
                Spacer().frame(height: 30)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.gold)

                Text("Challenge Complete!")
                    .font(Typography.displayMedium)
                    .foregroundStyle(.white)

                Text(challengeName)
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: -4) {
                    ForEach(completedParticipants.prefix(8), id: \.id) { p in
                        ZStack {
                            Circle()
                                .fill(Theme.gold.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Text(p.emoji.isEmpty ? "👤" : p.emoji)
                                .font(.system(size: 18))
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Theme.gold)
                                .offset(y: -18)
                        }
                        .frame(width: 44, height: 48)
                    }
                }

                VStack(spacing: 12) {
                    Text("$\(Int(groupTotalSavings))")
                        .font(Typography.moneyLarge)
                        .foregroundStyle(Theme.gold)
                    Text("saved together")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }

                if !goalSavingFor.isEmpty {
                    Text("Time to \(goalSavingFor)!")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.accent)
                }

                Text("\(durationDays) days · \(completedParticipants.count) champions")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                CardWatermark()
                    .padding(.bottom, 20)
            }
        }
        .frame(width: ShareCardRenderer.viewSize.width, height: ShareCardRenderer.viewSize.height)
    }
}
