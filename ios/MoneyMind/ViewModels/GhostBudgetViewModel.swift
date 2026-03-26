import SwiftUI
import SwiftData

nonisolated enum TimelineHorizon: String, CaseIterable, Sendable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var months: Int {
        switch self {
        case .oneMonth: 1
        case .threeMonths: 3
        case .sixMonths: 6
        case .oneYear: 12
        }
    }

    var label: String {
        switch self {
        case .oneMonth: "1 month"
        case .threeMonths: "3 months"
        case .sixMonths: "6 months"
        case .oneYear: "1 year"
        }
    }
}

nonisolated struct GhostCategoryItem: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let monthlyAverage: Double
    var isEliminated: Bool

    var color: Color {
        Color(hex: UInt(colorHex, radix: 16) ?? 0x64748B)
    }
}

nonisolated struct GhostChartPoint: Identifiable, Sendable {
    let id: Int
    let month: Int
    let realityBalance: Double
    let ghostBalance: Double
}

nonisolated struct FunEquivalent: Identifiable, Sendable {
    let id: Int
    let emoji: String
    let text: String
}

@Observable
class GhostBudgetViewModel {
    var categories: [GhostCategoryItem] = []
    var selectedHorizon: TimelineHorizon = .sixMonths
    var appeared = false
    var equivalentIndex: Int = 0
    var toggleHaptic: Int = 0
    var horizonHaptic: Int = 0
    var lineDrawProgress: CGFloat = 0

    private let calendar = Calendar.current

    var eliminatedCategories: [GhostCategoryItem] {
        categories.filter(\.isEliminated)
    }

    var monthlySavings: Double {
        eliminatedCategories.reduce(0) { $0 + $1.monthlyAverage }
    }

    var projectedSavings: Double {
        monthlySavings * Double(selectedHorizon.months)
    }

    var chartPoints: [GhostChartPoint] {
        let months = selectedHorizon.months
        var realRunning: Double = 0
        var ghostRunning: Double = 0
        var points: [GhostChartPoint] = []

        points.append(GhostChartPoint(id: 0, month: 0, realityBalance: 0, ghostBalance: 0))

        for m in 1...months {
            realRunning += 0
            ghostRunning += monthlySavings
            points.append(GhostChartPoint(id: m, month: m, realityBalance: realRunning, ghostBalance: ghostRunning))
        }
        return points
    }

    var funEquivalents: [FunEquivalent] {
        let saved = projectedSavings
        guard saved > 0 else { return [] }

        var items: [FunEquivalent] = []
        var idx = 0

        let iphones = saved / 1199
        if iphones >= 0.5 {
            items.append(FunEquivalent(id: idx, emoji: "📱", text: "That's \(formatCount(iphones)) iPhones"))
            idx += 1
        }

        let rent = saved / 1500
        if rent >= 0.5 {
            items.append(FunEquivalent(id: idx, emoji: "🏠", text: "That's \(formatCount(rent)) months of rent"))
            idx += 1
        }

        let flights = saved / 450
        if flights >= 0.5 {
            items.append(FunEquivalent(id: idx, emoji: "✈️", text: "That's \(formatCount(flights)) round-trip flights"))
            idx += 1
        }

        let dinners = saved / 75
        if dinners >= 1 {
            items.append(FunEquivalent(id: idx, emoji: "🍽️", text: "That's \(formatCount(dinners)) fancy dinners"))
            idx += 1
        }

        let coffees = saved / 5.5
        if coffees >= 1 {
            items.append(FunEquivalent(id: idx, emoji: "☕", text: "That's \(formatCount(coffees)) coffees"))
            idx += 1
        }

        return items
    }

    var currentEquivalent: FunEquivalent? {
        guard !funEquivalents.isEmpty else { return nil }
        return funEquivalents[equivalentIndex % funEquivalents.count]
    }

    var topEliminatedName: String? {
        eliminatedCategories.max(by: { $0.monthlyAverage < $1.monthlyAverage })?.name
    }

    func loadCategories(transactions: [Transaction]) {
        let expenseCategories = Set(
            transactions
                .filter { $0.transactionType == .expense }
                .map(\.category)
        )

        let grouped = Dictionary(grouping: transactions.filter { $0.transactionType == .expense }) { $0.category }

        let monthsTracked = max(monthsOfData(transactions: transactions), 1)

        categories = expenseCategories.sorted().compactMap { catName in
            guard let cat = TransactionCategory(rawValue: catName) else { return nil }
            let total = grouped[catName]?.reduce(0) { $0 + $1.amount } ?? 0
            let avg = total / Double(monthsTracked)
            guard avg > 0 else { return nil }

            return GhostCategoryItem(
                id: catName,
                name: catName,
                icon: cat.icon,
                colorHex: cat.color,
                monthlyAverage: avg,
                isEliminated: false
            )
        }.sorted { $0.monthlyAverage > $1.monthlyAverage }
    }

    func toggleCategory(_ id: String) {
        guard let idx = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[idx].isEliminated.toggle()
        toggleHaptic += 1
        resetLineAnimation()
    }

    func selectHorizon(_ horizon: TimelineHorizon) {
        selectedHorizon = horizon
        horizonHaptic += 1
        resetLineAnimation()
    }

    func cycleEquivalent() {
        guard !funEquivalents.isEmpty else { return }
        equivalentIndex += 1
    }

    func animateLines() {
        withAnimation(.easeInOut(duration: 1.5)) {
            lineDrawProgress = 1.0
        }
    }

    private func resetLineAnimation() {
        lineDrawProgress = 0
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            animateLines()
        }
    }

    private func monthsOfData(transactions: [Transaction]) -> Int {
        guard let earliest = transactions.min(by: { $0.date < $1.date })?.date else { return 1 }
        let components = calendar.dateComponents([.month], from: earliest, to: Date())
        return max(components.month ?? 1, 1)
    }

    private func formatCount(_ value: Double) -> String {
        if value >= 10 {
            return "\(Int(value))"
        } else if value == Double(Int(value)) {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}
