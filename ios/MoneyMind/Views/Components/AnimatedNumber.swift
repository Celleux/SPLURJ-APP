import SwiftUI

struct AnimatedNumber: View {
    let value: Double
    let format: NumberFormat
    var font: Font = Typography.moneyLarge
    var color: Color = Theme.textPrimary

    enum NumberFormat {
        case currency
        case integer
        case xp
        case level
        case streak
        case percentage
    }

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    private var formattedValue: String {
        switch format {
        case .currency:
            if displayedValue >= 1000 {
                return "$\(Int(displayedValue).formatted())"
            }
            return String(format: "$%.2f", displayedValue)
        case .integer:
            return "\(Int(displayedValue).formatted())"
        case .xp:
            return "\(Int(displayedValue).formatted()) XP"
        case .level:
            return "Lv. \(Int(displayedValue))"
        case .streak:
            let days = Int(displayedValue)
            return "\(days) day\(days == 1 ? "" : "s")"
        case .percentage:
            return "\(Int(displayedValue))%"
        }
    }

    var body: some View {
        Text(formattedValue)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedValue))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    displayedValue = newValue
                }
            }
    }
}
