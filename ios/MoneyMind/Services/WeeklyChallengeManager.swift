import Foundation
import SwiftData

@Observable
final class WeeklyChallengeManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func currentChallenge() -> WeeklyChallenge? {
        let now = Date()
        let descriptor = FetchDescriptor<WeeklyChallenge>(
            sortBy: [SortDescriptor(\WeeklyChallenge.startsAt, order: .reverse)]
        )
        guard let challenge = try? modelContext.fetch(descriptor).first else {
            return generateChallenge()
        }
        if challenge.endsAt < now {
            modelContext.delete(challenge)
            return generateChallenge()
        }
        return challenge
    }

    func incrementProgress(by amount: Int = 1) {
        guard let challenge = currentChallenge() else { return }
        challenge.current = min(challenge.target, challenge.current + amount)
        try? modelContext.save()
    }

    func claimReward() -> Bool {
        guard let challenge = currentChallenge(), challenge.isComplete, !challenge.claimed else { return false }
        challenge.claimed = true
        try? modelContext.save()
        return true
    }

    @discardableResult
    private func generateChallenge() -> WeeklyChallenge {
        let monday = currentMonday()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: monday) ?? monday

        let seed = deterministicSeed(for: monday)
        let template = Self.challengePool[seed % Self.challengePool.count]

        let challenge = WeeklyChallenge(
            id: "weekly_\(Int(monday.timeIntervalSince1970))",
            title: template.title,
            description: template.description,
            target: template.target,
            rewardType: template.rewardType,
            startsAt: monday,
            endsAt: endDate
        )
        modelContext.insert(challenge)
        try? modelContext.save()
        return challenge
    }

    private func currentMonday() -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        let daysBack = (weekday + 5) % 7
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: today) ?? today
    }

    private func deterministicSeed(for date: Date) -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        var hasher = Hasher()
        hasher.combine(day)
        hasher.combine("weeklyChallenge")
        return abs(hasher.finalize())
    }

    private struct ChallengeTemplate {
        let title: String
        let description: String
        let target: Int
        let rewardType: String
    }

    private static let challengePool: [ChallengeTemplate] = [
        ChallengeTemplate(title: "Quest Crusher", description: "Complete 10 quests this week", target: 10, rewardType: "epicCard"),
        ChallengeTemplate(title: "Mission Master", description: "Complete 15 quests this week", target: 15, rewardType: "essence200"),
        ChallengeTemplate(title: "Quest Legend", description: "Complete 20 quests this week", target: 20, rewardType: "xpBomb"),
        ChallengeTemplate(title: "Card Collector", description: "Earn 3 scratch cards this week", target: 3, rewardType: "epicCard"),
        ChallengeTemplate(title: "Scratch Fever", description: "Earn 5 scratch cards this week", target: 5, rewardType: "essence100"),
        ChallengeTemplate(title: "Lucky Streak", description: "Earn 8 scratch cards this week", target: 8, rewardType: "xpBomb"),
        ChallengeTemplate(title: "Streak Keeper", description: "Maintain a 5-day streak", target: 5, rewardType: "epicCard"),
        ChallengeTemplate(title: "Streak Champion", description: "Maintain a 7-day streak", target: 7, rewardType: "essence200"),
        ChallengeTemplate(title: "Boss Slayer", description: "Deal 50 damage to your current boss", target: 50, rewardType: "epicCard"),
        ChallengeTemplate(title: "Boss Crusher", description: "Deal 100 damage to your current boss", target: 100, rewardType: "xpBomb"),
        ChallengeTemplate(title: "Daily Devotion", description: "Complete all daily quests for 3 days", target: 3, rewardType: "essence100"),
        ChallengeTemplate(title: "Consistency King", description: "Complete all daily quests for 5 days", target: 5, rewardType: "epicCard"),
    ]
}
