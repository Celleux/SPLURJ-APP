import SwiftUI
import SwiftData

@Observable
class CharacterViewModel {
    var currentReaction: CharacterReaction = .idle
    var reactionMessage: String = ""
    var showReactionMessage: Bool = false
    var xpGainAnimation: Int = 0
    var showXPGain: Bool = false
    var lastXPGain: Int = 0

    var stage: CharacterStage {
        CharacterStage.from(xp: currentXP)
    }

    var level: Int {
        CharacterStage.level(from: currentXP)
    }

    var currentXP: Int = 0

    var levelProgress: Double {
        let currentLevelXP = CharacterStage.xpForLevel(level)
        let nextLevelXP = CharacterStage.xpForNextLevel(level)
        let range = nextLevelXP - currentLevelXP
        guard range > 0 else { return 1.0 }
        return Double(currentXP - currentLevelXP) / Double(range)
    }

    var sdtPhase: SDTPhase {
        SDTPhase.from(daysSinceStart: daysSinceStart)
    }

    var daysSinceStart: Int = 0

    func syncFromProfile(_ profile: UserProfile) {
        currentXP = profile.xpPoints
        let calendar = Calendar.current
        daysSinceStart = calendar.dateComponents([.day], from: profile.startDate, to: Date()).day ?? 0

        resetGraceIfNeeded(profile)
    }

    func awardXP(_ action: XPAction, to profile: UserProfile) {
        let xp = action.xpValue
        profile.xpPoints += xp
        profile.totalConsciousChoices += 1
        currentXP = profile.xpPoints
        lastXPGain = xp

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showXPGain = true
            xpGainAnimation += 1
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showXPGain = false
                }
            }
        }
    }

    func triggerReaction(_ reaction: CharacterReaction, message: String = "") {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            currentReaction = reaction
        }

        if !message.isEmpty {
            reactionMessage = message
            withAnimation(.spring(response: 0.3).delay(0.3)) {
                showReactionMessage = true
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.5)) {
                    currentReaction = .idle
                    showReactionMessage = false
                }
            }
        }
    }

    func onAvoidedPurchase(amount: Double, profile: UserProfile) {
        awardXP(.avoidedPurchase(amount: amount), to: profile)
        triggerReaction(.celebrate)
        profile.lastReactionType = CharacterReaction.celebrate.rawValue
        profile.lastReactionDate = Date()
    }

    func onUrgeSurf(profile: UserProfile) {
        awardXP(.urgeSurfComplete, to: profile)
        triggerReaction(.breathe, message: "Breathing through it together.")
        profile.lastReactionType = CharacterReaction.breathe.rawValue
        profile.lastReactionDate = Date()
    }

    func onSpendingAutopsy(profile: UserProfile) {
        awardXP(.spendingAutopsy, to: profile)
        triggerReaction(.sympathize, message: "Takes courage to reflect.")
        profile.lastReactionType = CharacterReaction.sympathize.rawValue
        profile.lastReactionDate = Date()
    }

    func onStreakBreak(profile: UserProfile) -> Bool {
        if canUseGrace(profile) {
            profile.graceUsedThisMonth = true
            triggerReaction(.grace, message: "Everyone needs a break sometimes.")
            return true
        }
        triggerReaction(.encourage, message: "Day 1 is the bravest day. I'm right here with you.")
        return false
    }

    func onDailyCheckIn(profile: UserProfile) {
        awardXP(.dailyCheckIn, to: profile)
    }

    func onImplementationIntention(profile: UserProfile) {
        awardXP(.implementationIntention, to: profile)
    }

    func canUseGrace(_ profile: UserProfile) -> Bool {
        !profile.graceUsedThisMonth
    }

    func sdtMessage(profile: UserProfile) -> String? {
        let phase = sdtPhase
        switch phase {
        case .extrinsic:
            return nil
        case .transition:
            let choices = profile.totalConsciousChoices
            if choices > 0 {
                return "You made \(choices) conscious choices. That's real growth."
            }
            return nil
        case .intrinsic:
            let saved = profile.totalSaved
            if saved > 100 {
                return "You saved \(saved.formatted(.currency(code: "USD").precision(.fractionLength(0)))). What does freedom mean to you?"
            }
            return "Every mindful moment matters. You're building something lasting."
        }
    }

    var socialProofStats: [(String, String)] {
        let totalSaved = "47.2M"
        let streakCount = "3,247"
        let percentile = "32"
        return [
            ("dollarsign.circle.fill", "Users have collectively saved $\(totalSaved) this month"),
            ("flame.fill", "\(streakCount) people maintained their streak today"),
            ("chart.bar.fill", "You're in the top \(percentile)% of consistent savers")
        ]
    }

    private func resetGraceIfNeeded(_ profile: UserProfile) {
        let calendar = Calendar.current
        let now = Date()
        let lastResetMonth = calendar.component(.month, from: profile.lastGraceReset)
        let currentMonth = calendar.component(.month, from: now)
        let lastResetYear = calendar.component(.year, from: profile.lastGraceReset)
        let currentYear = calendar.component(.year, from: now)

        if currentMonth != lastResetMonth || currentYear != lastResetYear {
            profile.graceUsedThisMonth = false
            profile.lastGraceReset = now
        }
    }
}
