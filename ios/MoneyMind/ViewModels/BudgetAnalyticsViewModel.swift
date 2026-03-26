import SwiftUI
import SwiftData

nonisolated struct MonthlySpending: Sendable {
    let month: Date
    let total: Double
    let label: String
}

nonisolated struct CategorySpending: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let spent: Double
    let limit: Double
    let percentage: Double

    var progress: Double {
        guard limit > 0 else { return 0 }
        return spent / limit
    }

    var isOverBudget: Bool { spent > limit && limit > 0 }

    var color: Color {
        Color(hex: UInt(colorHex, radix: 16) ?? 0x64748B)
    }

    var ringColor: Color {
        if isOverBudget { return Color(hex: 0xFF5252) }
        if progress < 0.5 { return Color(hex: 0x00E676) }
        return color
    }
}

@Observable
class BudgetAnalyticsViewModel {
    var selectedMonth: Date = Date()
    var appeared = false
    var selectedDonutIndex: Int? = nil
    var showAddBudget = false
    var selectedBudget: BudgetCategory? = nil
    var selectedBudgetSpent: Double = 0
    var monthChangeTrigger: Int = 0

    private let calendar = Calendar.current

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var daysLeftInMonth: Int {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else { return 0 }
        let totalDays = range.count
        let currentDay = calendar.component(.day, from: Date())
        let isCurrentMonth = calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
        return isCurrentMonth ? max(totalDays - currentDay, 0) : totalDays
    }

    var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    func previousMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return }
        selectedMonth = newDate
        monthChangeTrigger += 1
    }

    func nextMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) else { return }
        let maxDate = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        if newDate <= maxDate {
            selectedMonth = newDate
            monthChangeTrigger += 1
        }
    }

    func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    func endOfMonth(for date: Date) -> Date {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth(for: date)) else {
            return date
        }
        return nextMonth
    }

    func categorySpending(budgets: [BudgetCategory], transactions: [Transaction]) -> [CategorySpending] {
        let start = startOfMonth(for: selectedMonth)
        let end = endOfMonth(for: selectedMonth)

        return budgets.sorted(by: { $0.sortOrder < $1.sortOrder }).map { budget in
            let budgetName = budget.name.lowercased()
            let spent = transactions
                .filter {
                    $0.transactionType == .expense &&
                    ($0.category.lowercased() == budgetName || $0.transactionCategory.resolvedCategory.rawValue.lowercased() == budgetName) &&
                    $0.date >= start && $0.date < end
                }
                .reduce(0) { $0 + $1.amount }

            let totalSpent = totalSpent(budgets: budgets, transactions: transactions)
            let pct = totalSpent > 0 ? (spent / totalSpent) * 100 : 0

            return CategorySpending(
                id: budget.name,
                name: budget.name,
                icon: budget.icon,
                colorHex: budget.colorHex,
                spent: spent,
                limit: budget.monthlyLimit,
                percentage: pct
            )
        }
    }

    func totalSpent(budgets: [BudgetCategory], transactions: [Transaction]) -> Double {
        let start = startOfMonth(for: selectedMonth)
        let end = endOfMonth(for: selectedMonth)
        return transactions
            .filter { $0.transactionType == .expense && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }

    func totalBudget(budgets: [BudgetCategory]) -> Double {
        budgets.reduce(0) { $0 + $1.monthlyLimit }
    }

    func hasOverBudget(categories: [CategorySpending]) -> Bool {
        categories.contains(where: { $0.isOverBudget })
    }

    func monthlySpendingTrend(transactions: [Transaction]) -> [MonthlySpending] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<6).reversed().map { monthsAgo in
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: selectedMonth) ?? Date()
            let start = startOfMonth(for: date)
            let end = endOfMonth(for: date)

            let total = transactions
                .filter { $0.transactionType == .expense && $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.amount }

            return MonthlySpending(
                month: start,
                total: total,
                label: formatter.string(from: start)
            )
        }
    }

    func uncategorizedSpending(budgets: [BudgetCategory], transactions: [Transaction]) -> Double {
        let start = startOfMonth(for: selectedMonth)
        let end = endOfMonth(for: selectedMonth)
        let budgetNames = Set(budgets.map(\.name))

        return transactions
            .filter { $0.transactionType == .expense && $0.date >= start && $0.date < end && !budgetNames.contains($0.category) }
            .reduce(0) { $0 + $1.amount }
    }
}
