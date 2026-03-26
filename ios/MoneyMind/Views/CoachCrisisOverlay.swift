import SwiftUI

struct CoachCrisisOverlay: View {
    let onDismiss: () -> Void
    @State private var canDismiss = false
    @State private var heartPulse = false
    @State private var countdown: Int = 30

    var body: some View {
        ZStack {
            Theme.background.opacity(0.97).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "heart.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.emergency)
                    .symbolEffect(.pulse, options: .repeating, value: heartPulse)
                    .onAppear { heartPulse = true }

                VStack(spacing: 10) {
                    Text("You Matter")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Text("I noticed something in what you shared. Please reach out to someone who can help right now.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    CrisisCallButton(
                        title: "Suicide & Crisis Lifeline",
                        number: "988",
                        icon: "phone.fill",
                        color: Theme.emergency
                    )

                    CrisisCallButton(
                        title: "Gambling Helpline",
                        number: "1-800-522-4700",
                        icon: "phone.fill",
                        color: Theme.gold
                    )

                    CrisisCallButton(
                        title: "Crisis Text Line",
                        number: "Text HOME to 741741",
                        icon: "message.fill",
                        color: Theme.teal
                    )
                }
                .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    Text("Grounding Exercise")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)

                    Text("Name 5 things you can see right now. Focus on each one for a breath.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(16)
                .splurjCard(.elevated)
                .padding(.horizontal, 24)

                Spacer()

                if canDismiss {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Return to Coach")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .background(Theme.cardSurface, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .ghost, size: .medium))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text("Please take a moment... (\(countdown)s)")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                }
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                if countdown > 0 {
                    countdown -= 1
                } else {
                    timer.invalidate()
                    withAnimation(.spring(response: 0.4)) {
                        canDismiss = true
                    }
                }
            }
        }
    }
}

private struct CrisisCallButton: View {
    let title: String
    let number: String
    let icon: String
    let color: Color

    var body: some View {
        Button {
            let digits = number.filter { $0.isNumber || $0 == "+" }
            guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(Typography.headingLarge)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text(number)
                        .font(Typography.labelSmall)
                        .foregroundStyle(color)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(color.opacity(0.6))
            }
            .padding(14)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .heavy), trigger: title)
        .accessibilityLabel("\(title): \(number)")
    }
}
