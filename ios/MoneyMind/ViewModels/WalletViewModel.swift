import SwiftUI

nonisolated struct WalletLevel: Sendable {
    let name: String
    let icon: String
    let threshold: Double
}

@Observable
class WalletViewModel {
    var showLogWin = false
    var showAutopsy = false
    var showCelebration = false
    var showMilestone = false
    var celebrationAmount: Double = 0
    var milestoneValue: Double = 0
    var appeared = false
    var revealExact = false
    var showPaywall = false

    private let milestones: [Double] = [100, 500, 1_000, 5_000, 10_000]

    private let levels: [WalletLevel] = [
        WalletLevel(name: "Empty Pocket", icon: "wallet.bifold", threshold: 0),
        WalletLevel(name: "First Steps", icon: "wallet.bifold.fill", threshold: 10),
        WalletLevel(name: "Building Up", icon: "creditcard.fill", threshold: 50),
        WalletLevel(name: "Getting Stronger", icon: "banknote.fill", threshold: 100),
        WalletLevel(name: "Money Wise", icon: "dollarsign.circle.fill", threshold: 500),
        WalletLevel(name: "Wealth Builder", icon: "chart.line.uptrend.xyaxis.circle.fill", threshold: 1_000),
        WalletLevel(name: "Financial Freedom", icon: "crown.fill", threshold: 5_000),
    ]

    func effectiveTotal(_ totalSaved: Double, phantomApplied: Bool) -> Double {
        if totalSaved == 0 && !phantomApplied {
            return 2.0
        }
        return totalSaved
    }

    func workHours(for amount: Double, rate: Double) -> Double {
        guard rate > 0 else { return 0 }
        return amount / rate
    }

    func currentLevel(for total: Double) -> WalletLevel {
        levels.last(where: { total >= $0.threshold }) ?? levels[0]
    }

    func levelProgress(for total: Double) -> Double {
        let idx = levels.lastIndex(where: { total >= $0.threshold }) ?? 0
        let current = levels[idx]
        let next = idx + 1 < levels.count ? levels[idx + 1] : nil
        guard let next else { return 1.0 }
        let range = next.threshold - current.threshold
        guard range > 0 else { return 1.0 }
        return min(1.0, (total - current.threshold) / range)
    }

    func nextMilestone(for total: Double) -> Double? {
        milestones.first(where: { total < $0 })
    }

    func milestoneProgress(for total: Double) -> Double? {
        guard let next = nextMilestone(for: total) else { return nil }
        let prev = milestones.last(where: { $0 <= total }) ?? 0
        let range = next - prev
        guard range > 0 else { return nil }
        let progress = (total - prev) / range
        return progress >= 0.75 ? progress : nil
    }

    func checkMilestone(oldTotal: Double, newTotal: Double) {
        for m in milestones {
            if oldTotal < m && newTotal >= m {
                milestoneValue = m
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    self.showMilestone = true
                }
                return
            }
        }
    }

    func totalResisted(from logs: [ImpulseLog]) -> Double {
        logs.filter { $0.resisted }.reduce(0) { $0 + $1.amount }
    }

    func totalGaveIn(from logs: [ImpulseLog]) -> Double {
        logs.filter { !$0.resisted }.reduce(0) { $0 + $1.amount }
    }

    func dailySavings(from logs: [ImpulseLog]) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { daysAgo in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return 0 }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            return logs.filter { $0.resisted && $0.date >= day && $0.date < nextDay }
                .reduce(0) { $0 + $1.amount }
        }
    }

    func dayLabels() -> [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let label = formatter.string(from: day)
            return String(label.prefix(1))
        }
    }

    func displayAmount(_ amount: Double, gentle: Bool, symbol: String = "$") -> String {
        if gentle {
            let rounded = (amount / 100).rounded() * 100
            if rounded < 100 {
                let r10 = (amount / 10).rounded() * 10
                return "~\(symbol)\(Int(r10))"
            }
            return "~\(symbol)\(Int(rounded))"
        }
        return "\(symbol)\(String(format: "%.2f", amount))"
    }

    func displayAmountShort(_ amount: Double, gentle: Bool, symbol: String = "$") -> String {
        if gentle {
            let rounded = (amount / 10).rounded() * 10
            return "~\(symbol)\(Int(rounded))"
        }
        return "\(symbol)\(Int(amount))"
    }

    func monthlySavings(from logs: [ImpulseLog]) -> [MonthlySavingsData] {
        let calendar = Calendar.current
        let resistedLogs = logs.filter { $0.resisted }
        var monthlyTotals: [(date: Date, amount: Double)] = []

        for monthsAgo in (0..<6).reversed() {
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date()) ?? Date()
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let total = resistedLogs.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.amount }
            monthlyTotals.append((date: start, amount: total))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return monthlyTotals.map { MonthlySavingsData(month: formatter.string(from: $0.date), amount: $0.amount, date: $0.date) }
    }
}
