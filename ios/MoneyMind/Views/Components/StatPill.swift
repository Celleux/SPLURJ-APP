import SwiftUI

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Text(label)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.3), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
