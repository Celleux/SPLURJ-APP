import SwiftUI

struct MMAmountDisplay: View {
    let amount: Double
    var prefix: String = ""
    var currencyCode: String = "USD"
    var font: Font = Theme.amountXL
    var color: Color = Theme.textPrimary

    private var displayPrefix: String {
        prefix.isEmpty ? CurrencyHelper.symbol(for: currencyCode) : prefix
    }

    @State private var displayedAmount: Double = 0
    @State private var hasAppeared = false

    var body: some View {
        Text("\(displayPrefix)\(displayedAmount, specifier: displayedAmount >= 1000 ? "%.0f" : "%.2f")")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedAmount))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    displayedAmount = amount
                }
            }
            .onChange(of: amount) { _, newValue in
                withAnimation(Theme.numericSpring) {
                    displayedAmount = newValue
                }
            }
    }
}
