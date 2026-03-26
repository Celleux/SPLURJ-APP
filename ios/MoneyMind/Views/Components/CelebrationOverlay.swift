import SwiftUI

struct GenericCelebrationOverlay: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    var onDismiss: (() -> Void)?

    @State private var showContent: Bool = false
    @State private var flashOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.3
    @State private var confettiTrigger: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.gold.opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Color.black.opacity(showContent ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentColor.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Circle()
                        .strokeBorder(accentColor.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 88, height: 88)

                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundStyle(accentColor)
                        .symbolEffect(.bounce, value: showContent)
                }
                .scaleEffect(iconScale)

                Text(title)
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text(subtitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.buttonTextOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .rect(cornerRadius: 14)
                        )
                }
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Spacer().frame(height: 40)
            }

            ParticleBurstView(
                particleCount: 40,
                colors: [accentColor, accentColor.opacity(0.6), Theme.accent, .white],
                duration: 2.0,
                style: .confetti,
                trigger: confettiTrigger > 0
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
        .onAppear {
            if reduceMotion {
                showContent = true
                iconScale = 1.0
                return
            }
            runSequence()
        }
        .sensoryFeedback(.success, trigger: showContent)
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.15)) {
            flashOpacity = 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) {
                flashOpacity = 0
            }
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            showContent = true
        }

        confettiTrigger += 1
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
            iconScale = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

struct BadgeUnlockOverlay: View {
    let badgeName: String
    let badgeIcon: String
    let badgeColor: Color
    var onDismiss: (() -> Void)?

    @State private var show: Bool = false
    @State private var badgeScale: CGFloat = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(show ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.gold)
                    .tracking(3)
                    .opacity(show ? 1 : 0)

                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(glowPulse ? 0.25 : 0.1))
                        .frame(width: 120, height: 120)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: glowPulse)

                    Circle()
                        .strokeBorder(badgeColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)

                    Image(systemName: badgeIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(badgeColor)
                }
                .scaleEffect(badgeScale)
                .shadow(color: badgeColor.opacity(0.4), radius: glowPulse ? 20 : 10)

                Text(badgeName)
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(show ? 1 : 0)
                    .offset(y: show ? 0 : 16)

                Button { dismiss() } label: {
                    Text("Awesome!")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.buttonTextOnAccent)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: .capsule)
                }
                .opacity(show ? 1 : 0)
                .offset(y: show ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) {
                badgeScale = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    badgeScale = 1.0
                }
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                show = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                glowPulse = true
            }
        }
        .sensoryFeedback(.success, trigger: show)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            show = false
            badgeScale = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

struct QuestCompleteCelebrationOverlay: View {
    let xpEarned: Int
    let questTitle: String
    var onDismiss: (() -> Void)?

    @State private var show: Bool = false
    @State private var xpCounterValue: Double = 0
    @State private var progressFill: CGFloat = 0
    @State private var showContinue: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(show ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.gold)
                    .symbolEffect(.bounce, value: show)
                    .scaleEffect(show ? 1 : 0.3)
                    .opacity(show ? 1 : 0)

                Text("Quest Complete!")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(show ? 1 : 0)

                Text(questTitle)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(show ? 1 : 0)

                VStack(spacing: 8) {
                    Text("+\(Int(xpCounterValue)) XP")
                        .font(Typography.moneyLarge)
                        .foregroundStyle(Theme.gold)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: xpCounterValue))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.elevated)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.gold, Theme.accentDim],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progressFill, height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 60)
                }
                .opacity(show ? 1 : 0)

                Spacer()

                if showContinue {
                    Button { dismiss() } label: {
                        Text("Continue")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.buttonTextOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accentDim],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: .rect(cornerRadius: 14)
                            )
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            SplurjHaptics.questComplete()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                show = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                xpCounterValue = Double(xpEarned)
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                progressFill = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showContinue = true
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            show = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}
