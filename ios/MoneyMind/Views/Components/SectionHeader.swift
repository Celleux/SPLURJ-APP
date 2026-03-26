import SwiftUI
import PhosphorSwift

struct SectionHeader: View {
    let icon: String
    let title: String
    var phosphorIcon: Image? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let phosphorIcon {
                    phosphorIcon
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(Theme.accent)
            .frame(width: 28, height: 28)
            .background(Theme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if let action {
                Button(actionLabel) { action() }
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}
