import Foundation
import SwiftData
import WidgetKit

@Observable
class WidgetDataWriter {
    private let appGroupID = "group.app.rork.moneymind.shared"
    private let dataKey = "widgetData"

    func updateWidgetData(
        transactions: [Transaction],
        budgets: [BudgetCategory],
        challenges: [SavingsChallenge],
        quizResult: QuizResult?
    ) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let monthExpenses = transactions.filter {
            $0.transactionType == .expense && $0.date >= startOfMonth && $0.date < endOfMonth
        }
        let monthIncome = transactions.filter {
            $0.transactionType == .income && $0.date >= startOfMonth && $0.date < endOfMonth
        }

        let totalSpent = monthExpenses.reduce(0) { $0 + $1.amount }
        let totalIncome = monthIncome.reduce(0) { $0 + $1.amount }
        let totalBudget = budgets.reduce(0) { $0 + $1.monthlyLimit }

        let categoryData: [WidgetCategoryData] = budgets.sorted(by: { $0.sortOrder < $1.sortOrder }).prefix(5).map { budget in
            let spent = monthExpenses
                .filter { $0.category == budget.name }
                .reduce(0) { $0 + $1.amount }
            return WidgetCategoryData(
                name: budget.name,
                icon: budget.icon,
                colorHex: budget.colorHex,
                spent: spent,
                limit: budget.monthlyLimit
            )
        }

        let today = calendar.startOfDay(for: now)
        let weeklySpending: [WidgetDailySpending] = (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let daySpent = transactions.filter {
                $0.transactionType == .expense && $0.date >= day && $0.date < nextDay
            }.reduce(0) { $0 + $1.amount }

            let formatter = DateFormatter()
            formatter.dateFormat = "EEEEE"
            return WidgetDailySpending(
                dayLabel: formatter.string(from: day),
                amount: daySpent,
                isToday: daysAgo == 0
            )
        }

        let noSpendStreak = challenges
            .filter { $0.challengeType == .noSpend && $0.isActive }
            .map(\.noSpendStreak)
            .max() ?? 0

        let personality = quizResult?.personality ?? .builder
        let personalityHex: UInt = {
            switch personality {
            case .saver: return 0x00E676
            case .builder: return 0x6C5CE7
            case .hustler: return 0xFF9100
            case .minimalist: return 0x00D2FF
            case .generous: return 0xFFD700
            }
        }()

        let widgetPayload = WidgetPayload(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalIncome: totalIncome,
            noSpendStreak: noSpendStreak,
            personalityColorHex: personalityHex,
            personalityIcon: personality.icon,
            categories: categoryData,
            weeklySpending: weeklySpending
        )

        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(widgetPayload) else { return }
        defaults.set(data, forKey: dataKey)

        WidgetCenter.shared.reloadAllTimelines()
    }
}

private nonisolated struct WidgetPayload: Codable, Sendable {
    let totalBudget: Double
    let totalSpent: Double
    let totalIncome: Double
    let noSpendStreak: Int
    let personalityColorHex: UInt
    let personalityIcon: String
    let categories: [WidgetCategoryData]
    let weeklySpending: [WidgetDailySpending]
}

private nonisolated struct WidgetCategoryData: Codable, Sendable {
    let name: String
    let icon: String
    let colorHex: String
    let spent: Double
    let limit: Double
}

private nonisolated struct WidgetDailySpending: Codable, Sendable {
    let dayLabel: String
    let amount: Double
    let isToday: Bool
}
