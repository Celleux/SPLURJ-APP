import SwiftUI

nonisolated struct WrappedData: Sendable {
    let periodLabel: String
    let isAnnual: Bool
    let totalSpent: Double
    let lastPeriodSpent: Double
    let totalSaved: Double
    let savingsGoal: Double
    let purchasesResisted: Int
    let longestStreak: Int
    let currentStreak: Int
    let characterStage: CharacterStage
    let startStage: CharacterStage
    let level: Int
    let personality: MoneyPersonality
    let categoryBreakdown: [(category: String, amount: Double, color: String)]
    let moodBreakdown: [(emoji: String, count: Int)]

    var spendingChangePercent: Double {
        guard lastPeriodSpent > 0 else { return 0 }
        return ((totalSpent - lastPeriodSpent) / lastPeriodSpent) * 100
    }

    var topCategory: (category: String, amount: Double, color: String)? {
        categoryBreakdown.max(by: { $0.amount < $1.amount })
    }

    var topMood: (emoji: String, count: Int)? {
        moodBreakdown.max(by: { $0.count < $1.count })
    }

    var totalMoodCount: Int {
        moodBreakdown.reduce(0) { $0 + $1.count }
    }

    var savingsProgress: Double {
        guard savingsGoal > 0 else { return 0 }
        return min(1.0, totalSaved / savingsGoal)
    }

    var goalMet: Bool {
        savingsGoal > 0 && totalSaved >= savingsGoal
    }

    var coffeEquivalent: Int {
        guard let top = topCategory else { return 0 }
        return max(1, Int(top.amount / 5.50))
    }

    var fortune: String {
        let fortunes = [
            "Keep your \(personality.rawValue) energy — next month looks bright for your savings streak.",
            "The stars align for a low-spend month. Your wallet will thank you.",
            "A surprise expense may appear, but your discipline will carry you through.",
            "Next month favors the patient. Small wins will compound into something big.",
            "Your spending habits are shifting. Trust the process — growth is coming.",
            "A mindful month ahead. Every conscious choice builds your financial future."
        ]
        let index = abs((periodLabel + "\(totalSpent)").hashValue) % fortunes.count
        return fortunes[index]
    }
}
