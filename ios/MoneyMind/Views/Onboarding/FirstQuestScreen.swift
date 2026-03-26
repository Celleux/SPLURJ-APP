import SwiftUI

struct FirstQuestScreen: View {
    let dna: FinancialDNA
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var accepted = false
    @State private var confettiTriggered = false

    private var archetype: FinancialArchetype { dna.primaryArchetype }

    private var quest: (title: String, subtitle: String, icon: String, description: String, xp: Int) {
        switch archetype {
        case .guardian:
            return ("The Mirror", "Check your credit score", "creditcard.viewfinder", "Pull up your credit score from any free service. Knowledge is your first line of defense.", 10)
        case .strategist:
            return ("Statement Archaeology", "Review your last bank statement", "doc.text.magnifyingglass", "Open your banking app and review last month's statement. Find one surprise.", 10)
        case .adventurer:
            return ("Treasure Hunter", "Find one item to sell", "tag.fill", "Look around your space. Find one thing you don't use anymore and list it on a marketplace.", 10)
        case .empath:
            return ("Gratitude Strike", "Send a thank-you", "heart.text.square.fill", "Send a message to someone who helped you financially — a parent, friend, or mentor.", 10)
        case .visionary:
            return ("The Intel Mission", "Research your market salary", "magnifyingglass", "Spend 5 minutes researching what people in your role earn. Know your worth.", 10)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Text("YOUR FIRST QUEST")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .tracking(3)
                .opacity(appeared ? 1 : 0)

            Text("Chosen for your DNA")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)

            Spacer()

            ZStack {
                if accepted {
                    acceptedCard
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                } else {
                    questCard
                        .transition(.identity)
                }

                if confettiTriggered {
                    confettiBurst
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: accepted)

            Spacer()

            if !accepted {
                Button {
                    acceptQuest()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(Typography.headingLarge)
                        Text("Accept Quest")
                            .font(Typography.headingMedium)
                    }
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                    .shadow(color: Theme.accent.opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.6), value: appeared)
            } else {
                Button(action: onComplete) {
                    Text("Let's Go")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Text("This quest was chosen based on your Financial DNA.")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var questCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(archetype.color.opacity(0.15))
                    .frame(width: 72, height: 72)

                Circle()
                    .stroke(archetype.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 72, height: 72)

                Image(systemName: quest.icon)
                    .font(Typography.displayMedium)
                    .foregroundStyle(archetype.color)
            }

            VStack(spacing: 6) {
                Text(quest.title)
                    .font(Typography.displaySmall)
                    .foregroundStyle(.white)

                Text(quest.subtitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(quest.description)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(Typography.labelSmall)
                    Text("+\(quest.xp) XP")
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Theme.gold)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(Typography.labelSmall)
                    Text("~5 min")
                        .font(Typography.bodySmall)
                }
                .foregroundStyle(Theme.textMuted)

                Text("EASY")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent.opacity(0.15), in: Capsule())
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .splurjCard(.hero)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(archetype.color.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 28)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    private var acceptedCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: "checkmark")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.accent)
            }

            Text("Quest Accepted!")
                .font(Typography.displaySmall)
                .foregroundStyle(.white)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(Typography.bodyMedium)
                Text("+\(quest.xp) XP")
                    .font(Typography.headingLarge)
            }
            .foregroundStyle(Theme.gold)

            Text("Complete it to start earning XP")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .splurjCard(.hero)
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var confettiBurst: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * (360.0 / 12.0) * .pi / 180
                let distance: CGFloat = confettiTriggered ? CGFloat.random(in: 40...80) : 0
                let colors: [Color] = [Theme.accent, Theme.gold, archetype.color]

                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: CGFloat.random(in: 4...7))
                    .offset(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance
                    )
                    .opacity(confettiTriggered ? 0 : 1)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.5).delay(Double(i) * 0.02),
                        value: confettiTriggered
                    )
            }
        }
    }

    private func acceptQuest() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            accepted = true
        }

        Task {
            try? await Task.sleep(for: .milliseconds(100))
            confettiTriggered = true
        }
    }
}
