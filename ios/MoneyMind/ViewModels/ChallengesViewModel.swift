import SwiftUI
import SwiftData

@Observable
class ChallengesViewModel {
    var showCelebration = false
    var celebrationMessage = ""
    var hapticTrigger = 0
    var confettiParticles: [ChallengeConfetti] = []

    func startChallenge(type: ChallengeType, context: ModelContext) {
        let challenge = SavingsChallenge(type: type)
        context.insert(challenge)
        hapticTrigger += 1
    }

    func markEnvelope(_ number: Int, challenge: SavingsChallenge) {
        guard !challenge.completedItems.contains(number) else { return }
        challenge.completedItems.append(number)
        challenge.totalSaved += Double(number)
        hapticTrigger += 1
        checkMilestones(challenge: challenge)
    }

    func markWeek(_ week: Int, challenge: SavingsChallenge) {
        guard !challenge.completedItems.contains(week) else { return }
        challenge.completedItems.append(week)
        challenge.totalSaved += Double(week)
        hapticTrigger += 1
        checkMilestones(challenge: challenge)
    }

    func markNoSpendDay(_ date: Date, challenge: SavingsChallenge) {
        let key = dateKey(date)
        if challenge.spentDays.contains(key) {
            challenge.spentDays.removeAll { $0 == key }
        }
        if !challenge.noSpendDays.contains(key) {
            challenge.noSpendDays.append(key)
            hapticTrigger += 1
        }
        checkStreakMilestones(challenge: challenge)
    }

    func markSpentDay(_ date: Date, challenge: SavingsChallenge) {
        let key = dateKey(date)
        if challenge.noSpendDays.contains(key) {
            challenge.noSpendDays.removeAll { $0 == key }
        }
        if !challenge.spentDays.contains(key) {
            challenge.spentDays.append(key)
        }
    }

    func addRoundUp(_ amount: Double, challenge: SavingsChallenge) {
        let rounded = ceil(amount)
        let roundUp = rounded - amount
        guard roundUp > 0 else { return }
        challenge.roundUpTotal += roundUp
        challenge.totalSaved += roundUp
    }

    func deleteChallenge(_ challenge: SavingsChallenge, context: ModelContext) {
        context.delete(challenge)
    }

    func shareChallenge(_ challenge: SavingsChallenge) -> String {
        let type = challenge.challengeType
        switch type {
        case .envelope100:
            return "I've saved $\(Int(challenge.totalSaved)) in the 100 Envelope Challenge on Splurj! \(challenge.completedItems.count)/100 envelopes opened. Join me: \(challenge.inviteCode)"
        case .week52:
            return "I've saved $\(Int(challenge.totalSaved)) in the 52-Week Savings Challenge on Splurj! Week \(challenge.completedItems.count)/52. Join me: \(challenge.inviteCode)"
        case .noSpend:
            return "Day \(challenge.noSpendDays.count) of my No-Spend Challenge on Splurj! Current streak: \(challenge.noSpendStreak) days. Join me: \(challenge.inviteCode)"
        case .roundUp:
            return "I've saved $\(String(format: "%.2f", challenge.roundUpTotal)) from round-ups on Splurj! Every penny counts. Join me: \(challenge.inviteCode)"
        }
    }

    private func checkMilestones(challenge: SavingsChallenge) {
        let saved = challenge.totalSaved
        let milestones: [(Double, String)] = [
            (100, "You saved $100!"),
            (500, "Half a grand saved!"),
            (1000, "$1,000 milestone reached!"),
            (2500, "$2,500 — incredible!"),
            (5000, "$5,000 — legendary!")
        ]
        for (threshold, message) in milestones {
            let prevSaved = saved - Double(challenge.completedItems.last ?? 0)
            if prevSaved < threshold && saved >= threshold {
                triggerCelebration(message)
                return
            }
        }
        if challenge.isCompleted {
            triggerCelebration("Challenge Complete!")
        }
    }

    private func checkStreakMilestones(challenge: SavingsChallenge) {
        let streak = challenge.noSpendStreak
        let milestones = [3, 7, 14, 30]
        if milestones.contains(streak) {
            triggerCelebration("\(streak)-day no-spend streak!")
        }
    }

    private func triggerCelebration(_ message: String) {
        celebrationMessage = message
        confettiParticles = (0..<60).map { _ in
            ChallengeConfetti(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.3...0),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.2),
                color: [Theme.accent, Theme.secondary, Theme.success, Theme.gold, Theme.warning].randomElement()!,
                speed: Double.random(in: 1.5...3.0)
            )
        }
        showCelebration = true
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

nonisolated struct ChallengeConfetti: Sendable, Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color
    let speed: Double
}
