import SwiftUI

struct ReferralGateView: View {
    let onContinue: () -> Void
    let onFindTherapist: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.teal.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(Typography.displayLarge)
                        .foregroundStyle(Theme.teal)
                }

                Text("A Gentle Recommendation")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)

                Text("Based on your recent check-in, we think connecting with a licensed professional could be really helpful right now. This doesn't replace the coach — it adds to your support.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button {
                    onFindTherapist()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                        Text("Find a Therapist")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.teal, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .accessibilityLabel("Find a therapist through SAMHSA")

                Text("Opens SAMHSA treatment locator")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))

                Button {
                    onContinue()
                } label: {
                    Text("Continue to Coach")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .splurjCard(.outlined)
                }
                .buttonStyle(SplurjButtonStyle(variant: .ghost, size: .medium))
                .accessibilityLabel("Continue to AI coach")
            }
            .padding(.horizontal, 24)

            Spacer()

            Text("The Splurj Coach is an AI wellness tool, not a substitute for professional care.")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
    }
}
