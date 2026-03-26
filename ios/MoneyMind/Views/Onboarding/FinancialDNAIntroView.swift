import SwiftUI

struct FinancialDNAIntroView: View {
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var buttonPulse = false

    private let axes: [(title: String, icon: String, color: Color)] = [
        ("Spending Style", "shield.lefthalf.filled", Theme.accent),
        ("Money Emotions", "brain.head.profile.fill", Theme.axisEmotional),
        ("Risk Profile", "flame.fill", Theme.axisRisk),
        ("Social Money", "person.2.fill", Theme.axisSocial),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Discover Your")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("Financial DNA")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.accent)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Text("A 2-minute deep scan of how\nyour brain handles money")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(response: 0.5).delay(0.15), value: appeared)

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                    DNAAxisPreviewCard(
                        title: axis.title,
                        icon: axis.icon,
                        color: axis.color,
                        showShimmer: appeared
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(0.25 + Double(index) * 0.1),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            Text("Based on behavioral economics research.\nNot a personality label — a full financial fingerprint.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.7), value: appeared)

            Spacer()

            Button(action: onComplete) {
                Text("Start My Scan")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                    .scaleEffect(buttonPulse ? 1.02 : 1.0)
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .sensoryFeedback(.impact(weight: .medium), trigger: true)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.8), value: appeared)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.0)) {
                buttonPulse = true
            }
        }
    }
}
