import Foundation

nonisolated struct WidgetData: Codable, Sendable {
    var totalBudget: Double
    var totalSpent: Double
    var totalIncome: Double
    var noSpendStreak: Int
    var personalityColorHex: UInt
    var personalityIcon: String
    var categories: [CategoryData]
    var weeklySpending: [DailySpending]

    nonisolated struct CategoryData: Codable, Sendable {
        var name: String
        var icon: String
        var colorHex: String
        var spent: Double
        var limit: Double
    }

    nonisolated struct DailySpending: Codable, Sendable {
        var dayLabel: String
        var amount: Double
        var isToday: Bool
    }

    var budgetRemaining: Double {
        max(0, totalBudget - totalSpent)
    }

    var budgetProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(1.0, totalSpent / totalBudget)
    }

    var isOverBudget: Bool {
        totalSpent > totalBudget && totalBudget > 0
    }

    static let appGroupID = "group.app.rork.moneymind.shared"
    static let dataKey = "widgetData"

    static var placeholder: WidgetData {
        WidgetData(
            totalBudget: 1500,
            totalSpent: 875,
            totalIncome: 3200,
            noSpendStreak: 5,
            personalityColorHex: 0x6C5CE7,
            personalityIcon: "chart.line.uptrend.xyaxis",
            categories: [
                CategoryData(name: "Food", icon: "fork.knife", colorHex: "FF6B6B", spent: 320, limit: 500),
                CategoryData(name: "Shopping", icon: "bag.fill", colorHex: "A55EEA", spent: 180, limit: 300),
                CategoryData(name: "Transport", icon: "car.fill", colorHex: "54A0FF", spent: 95, limit: 200),
            ],
            weeklySpending: [
                DailySpending(dayLabel: "M", amount: 45, isToday: false),
                DailySpending(dayLabel: "T", amount: 82, isToday: false),
                DailySpending(dayLabel: "W", amount: 30, isToday: false),
                DailySpending(dayLabel: "T", amount: 65, isToday: false),
                DailySpending(dayLabel: "F", amount: 110, isToday: false),
                DailySpending(dayLabel: "S", amount: 55, isToday: true),
                DailySpending(dayLabel: "S", amount: 0, isToday: false),
            ]
        )
    }

    static func load() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: dataKey) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.dataKey)
    }
}
