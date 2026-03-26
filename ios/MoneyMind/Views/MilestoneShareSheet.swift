import SwiftUI

struct MilestoneShareSheet: View {
    let milestoneAmount: Double

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("Milestone Reached!")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text("\(Text(milestoneAmount, format: .currency(code: "USD")).bold()) saved")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.accent)

            ShareLink(
                item: "I just hit a \(String(format: "$%.0f", milestoneAmount)) savings milestone on Splurj!",
                preview: SharePreview("Savings Milestone", image: Image(systemName: "star.circle.fill"))
            ) {
                Text("Share Milestone")
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
