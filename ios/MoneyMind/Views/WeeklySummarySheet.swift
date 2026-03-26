import SwiftUI

struct WeeklySummarySheet: View {
    let totalSaved: Double
    let purchasesResisted: Int
    let streak: Int
    let characterStage: CharacterStage
    let level: Int

    var body: some View {
        VStack(spacing: 24) {
            Text("Weekly Summary")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 32)

            VStack(spacing: 16) {
                summaryRow(icon: "dollarsign.circle.fill", label: "Total Saved", value: String(format: "$%.2f", totalSaved), color: Theme.accent)
                summaryRow(icon: "hand.raised.fill", label: "Impulses Resisted", value: "\(purchasesResisted)", color: Theme.accentTertiary)
                summaryRow(icon: "flame.fill", label: "Current Streak", value: "\(streak) days", color: Theme.axisRisk)
                summaryRow(icon: "star.fill", label: "Level", value: "\(level)", color: Theme.gold)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func summaryRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Typography.headingMedium)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12), in: .rect(cornerRadius: 10))

            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text(value)
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(14)
        .splurjCard(.elevated)
    }
}
