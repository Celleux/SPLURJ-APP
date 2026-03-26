import SwiftUI

struct ShareWinSheet: View {
    let amount: Double
    let itemName: String
    let trigger: String
    let hourlyRate: Double

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("You Saved \(Text(amount, format: .currency(code: "USD")).bold())")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)

            if !itemName.isEmpty {
                Text("by resisting \(itemName)")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
            }

            ShareLink(
                item: "I just saved \(String(format: "$%.2f", amount)) by resisting an impulse purchase with Splurj!",
                preview: SharePreview("My Savings Win", image: Image(systemName: "trophy.fill"))
            ) {
                Text("Share This Win")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
