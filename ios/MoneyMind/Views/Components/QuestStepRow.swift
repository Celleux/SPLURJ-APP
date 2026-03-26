import SwiftUI

struct QuestStepRow: View {
    let step: QuestStep
    let stepNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Theme.accent : isCurrent ? Theme.accent.opacity(0.2) : Theme.elevated)
                    .frame(width: 28, height: 28)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(Typography.labelMedium)
                        .foregroundStyle(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(Typography.labelMedium)
                        .foregroundStyle(isCurrent ? Theme.accent : Theme.textMuted)
                }
            }

            Text(step.instruction)
                .font(Typography.bodySmall)
                .foregroundStyle(isCurrent ? .white : Theme.textSecondary)
                .strikethrough(isCompleted, color: Theme.accent)

            Spacer()

            if isCurrent {
                Text("+\(step.xpReward) XP")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent ? Theme.elevated : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stepAccessibilityLabel)
    }

    private var stepAccessibilityLabel: String {
        var label = "Step \(stepNumber): \(step.instruction)."
        if isCompleted {
            label += " Completed."
        } else if isCurrent {
            label += " Current step. \(step.xpReward) XP reward."
        } else {
            label += " Locked."
        }
        return label
    }
}
