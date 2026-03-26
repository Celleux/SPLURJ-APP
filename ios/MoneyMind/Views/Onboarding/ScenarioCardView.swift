import SwiftUI

struct ScenarioCardView: View {
    let scenario: SpendingScenario
    let response: SwipeDirection?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(scenario.axisColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: scenario.icon)
                    .font(Typography.displayMedium)
                    .foregroundStyle(scenario.axisColor)
            }

            Text(scenario.text)
                .font(Typography.headingLarge)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            Text(scenario.axisLabel.uppercased())
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .tracking(2)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    borderColor,
                    lineWidth: response != nil ? 2 : 0.5
                )
        )
        .overlay(alignment: .topLeading) {
            if response == .left {
                stampLabel(scenario.leftShort, color: Theme.axisEmotional, rotation: -15)
                    .padding(20)
            }
        }
        .overlay(alignment: .topTrailing) {
            if response == .right {
                stampLabel(scenario.rightShort, color: Theme.axisRisk, rotation: 15)
                    .padding(20)
            }
        }
    }

    private var borderColor: Color {
        switch response {
        case .right: Theme.axisRisk.opacity(0.6)
        case .left: Theme.axisEmotional.opacity(0.6)
        case nil: Theme.elevated
        }
    }

    private func stampLabel(_ text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(Typography.headingSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: .rect(cornerRadius: 8))
            .rotationEffect(.degrees(rotation))
    }
}
