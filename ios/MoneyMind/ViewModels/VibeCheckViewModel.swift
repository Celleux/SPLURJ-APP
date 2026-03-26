import SwiftUI
import SwiftData

@Observable
class VibeCheckViewModel {
    var entries: [VibeCheckEntry] = []
    var transactions: [Transaction] = []
    var personality: MoneyPersonality = .builder

    struct MoodDistribution {
        let vibeType: VibeType
        let count: Int
        let percentage: Double
        let totalAmount: Double
    }

    struct WeeklyTrend {
        let weekLabel: String
        let averageSentiment: Float
        let dominantVibe: VibeType?
        let count: Int
    }

    struct PatternInsight {
        let title: String
        let description: String
        let icon: String
    }

    var moodDistribution: [MoodDistribution] {
        let grouped = Dictionary(grouping: entries) { $0.emoji }
        let total = max(entries.count, 1)

        return VibeType.allCases.compactMap { vibe in
            let matching = grouped[vibe.emoji] ?? []
            guard !matching.isEmpty else { return nil }
            let totalAmount = matching.reduce(0.0) { $0 + $1.amount }
            return MoodDistribution(
                vibeType: vibe,
                count: matching.count,
                percentage: Double(matching.count) / Double(total) * 100,
                totalAmount: totalAmount
            )
        }
        .sorted { $0.count > $1.count }
    }

    var weeklyTrends: [WeeklyTrend] {
        let calendar = Calendar.current
        let now = Date()
        var trends: [WeeklyTrend] = []

        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? now

            let weekEntries = entries.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }
            guard !weekEntries.isEmpty else {
                let label = weekOffset == 0 ? "This Week" : "\(weekOffset)w ago"
                trends.append(WeeklyTrend(weekLabel: label, averageSentiment: 0, dominantVibe: nil, count: 0))
                continue
            }

            let avgSentiment = weekEntries.reduce(Float(0)) { $0 + $1.sentiment } / Float(weekEntries.count)
            let grouped = Dictionary(grouping: weekEntries) { $0.emoji }
            let dominant = grouped.max(by: { $0.value.count < $1.value.count })
            let dominantVibe = dominant.flatMap { VibeType(fromEmoji: $0.key) }

            let label = weekOffset == 0 ? "This Week" : "\(weekOffset)w ago"
            trends.append(WeeklyTrend(
                weekLabel: label,
                averageSentiment: avgSentiment,
                dominantVibe: dominantVibe,
                count: weekEntries.count
            ))
        }

        return trends
    }

    var patternInsights: [PatternInsight] {
        var insights: [PatternInsight] = []
        let calendar = Calendar.current

        let regretEntries = entries.filter { $0.vibeType == .regret }
        if !regretEntries.isEmpty {
            let weekendRegrets = regretEntries.filter {
                let weekday = calendar.component(.weekday, from: $0.timestamp)
                return weekday == 1 || weekday == 7
            }
            if Double(weekendRegrets.count) > Double(regretEntries.count) * 0.5 && regretEntries.count >= 3 {
                insights.append(PatternInsight(
                    title: "Weekend Regrets",
                    description: "Your Regret purchases cluster on weekends.",
                    icon: "calendar.badge.exclamationmark"
                ))
            }
        }

        let flexEntries = entries.filter { $0.vibeType == .flex }
        if !flexEntries.isEmpty {
            let fridayFlex = flexEntries.filter {
                calendar.component(.weekday, from: $0.timestamp) == 6
            }
            if Double(fridayFlex.count) > Double(flexEntries.count) * 0.3 && flexEntries.count >= 3 {
                insights.append(PatternInsight(
                    title: "Friday Flex",
                    description: "Friday nights have the most Flex spending.",
                    icon: "party.popper.fill"
                ))
            }
        }

        let regretAvg = regretEntries.isEmpty ? 0 : regretEntries.reduce(0.0) { $0 + $1.amount } / Double(regretEntries.count)
        let worthItEntries = entries.filter { $0.vibeType == .worthIt }
        let worthItAvg = worthItEntries.isEmpty ? 0 : worthItEntries.reduce(0.0) { $0 + $1.amount } / Double(worthItEntries.count)

        if regretAvg > 0 && worthItAvg > 0 {
            insights.append(PatternInsight(
                title: "Regret vs Worth It",
                description: "Your Regret purchases average $\(Int(regretAvg)) vs Worth It at $\(Int(worthItAvg)).",
                icon: "arrow.left.arrow.right"
            ))
        }

        let dist = moodDistribution
        if let top = dist.first {
            let personalityNote: String
            switch personality {
            case .saver:
                personalityNote = top.vibeType == .regret
                    ? "As a Saver, let's work on reducing those regrets."
                    : "As a Saver, your low Regret rate shows strong financial alignment."
            case .builder:
                personalityNote = "As a Builder, your spending patterns reflect strategic choices."
            case .hustler:
                personalityNote = "As a Hustler, your bold spending reflects your action-oriented style."
            case .minimalist:
                personalityNote = "As a Minimalist, your intentional spending keeps things balanced."
            case .generous:
                personalityNote = "As a Generous type, your spending reflects your community values."
            }
            insights.append(PatternInsight(
                title: "Personality Insight",
                description: personalityNote,
                icon: personality.icon
            ))
        }

        return insights
    }

    var topVibe: MoodDistribution? {
        moodDistribution.first
    }

    func monthlyEntries(for month: Date) -> [VibeCheckEntry] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
        return entries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    func load(entries: [VibeCheckEntry], transactions: [Transaction], personality: MoneyPersonality) {
        self.entries = entries
        self.transactions = transactions
        self.personality = personality
    }
}
