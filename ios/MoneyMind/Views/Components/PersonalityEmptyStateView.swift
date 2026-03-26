import SwiftUI

struct PersonalityEmptyStateView: View {
    let personality: MoneyPersonality
    let icon: String
    let secondaryIcon: String?
    let headline: String
    let subtext: String
    let buttonLabel: String?
    let buttonIcon: String?
    let action: (() -> Void)?

    @State private var floatOffset: CGFloat = 0
    @State private var appeared = false

    init(
        personality: MoneyPersonality,
        icon: String,
        secondaryIcon: String? = nil,
        headline: String,
        subtext: String,
        buttonLabel: String? = nil,
        buttonIcon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.personality = personality
        self.icon = icon
        self.secondaryIcon = secondaryIcon
        self.headline = headline
        self.subtext = subtext
        self.buttonLabel = buttonLabel
        self.buttonIcon = buttonIcon
        self.action = action
    }

    private var personalityIcon: String {
        switch personality {
        case .saver: "banknote.fill"
        case .builder: "chart.line.uptrend.xyaxis"
        case .hustler: "flame.fill"
        case .minimalist: "leaf.fill"
        case .generous: "heart.fill"
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
                .frame(height: 32)

            illustration
                .offset(y: floatOffset)

            VStack(spacing: 10) {
                Text(headline)
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)

                Text(subtext)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            if let buttonLabel, let action {
                Button(action: action) {
                    Label(buttonLabel, systemImage: buttonIcon ?? "plus.circle.fill")
                        .font(Typography.headingMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                floatOffset = -4
            }
        }
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(personality.color.opacity(0.04))
                .frame(width: 180, height: 180)

            Circle()
                .fill(personality.color.opacity(0.08))
                .frame(width: 130, height: 130)

            Circle()
                .fill(personality.color.opacity(0.14))
                .frame(width: 90, height: 90)

            Image(systemName: icon)
                .font(Typography.displayLarge)
                .foregroundStyle(personality.color)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            if let secondaryIcon {
                Image(systemName: secondaryIcon)
                    .font(Typography.headingLarge)
                    .foregroundStyle(personality.color.opacity(0.7))
                    .offset(x: 34, y: -30)
            }

            Image(systemName: personalityIcon)
                .font(Typography.headingSmall)
                .foregroundStyle(personality.color.opacity(0.5))
                .offset(x: -36, y: 28)
        }
    }
}
