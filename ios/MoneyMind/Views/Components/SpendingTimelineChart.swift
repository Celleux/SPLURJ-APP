import SwiftUI

struct SpendingTimelineChart: View {
    let dailyAmounts: [Double]
    let dayLabels: [String]
    let currentDayIndex: Int
    var currencySymbol: String = "$"

    @State private var animatedHeights: [CGFloat] = Array(repeating: 0, count: 7)

    private let maxBarHeight: CGFloat = 120
    private let barWidth: CGFloat = 28

    private var maxAmount: Double {
        max(dailyAmounts.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("See All")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.secondary)
            }

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 8) {
                        if dailyAmounts[index] > 0 {
                            Text("\(currencySymbol)\(Int(dailyAmounts[index]))")
                                .font(Typography.labelSmall)
                                .foregroundStyle(index == currentDayIndex ? Theme.textPrimary : Theme.textMuted)
                                .opacity(animatedHeights[index] > 0 ? 1 : 0)
                        }

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                index == currentDayIndex
                                    ? AnyShapeStyle(Theme.accentGradient)
                                    : AnyShapeStyle(Theme.border)
                            )
                            .frame(width: barWidth, height: max(animatedHeights[index], 4))

                        Text(dayLabels[index])
                            .font(.system(size: 11, weight: index == currentDayIndex ? .bold : .regular))
                            .foregroundStyle(index == currentDayIndex ? Theme.textPrimary : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxBarHeight + 40)
        }
        .padding(20)
        .splurjCard(.elevated)
        .onAppear {
            for i in 0..<7 {
                let targetHeight = dailyAmounts[i] > 0
                    ? CGFloat(dailyAmounts[i] / maxAmount) * maxBarHeight
                    : 4
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.06)) {
                    animatedHeights[i] = targetHeight
                }
            }
        }
    }
}
