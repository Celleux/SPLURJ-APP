import SwiftUI
import SwiftData

enum SplurjiContext: String {
    case home, games, quests, vault, onboarding, other
}

@Observable
class SplurjiMoodEngine {
    private(set) var currentMood: SplurjiMood = .idle
    private(set) var moodMessage: String = ""
    private(set) var shouldShowSpeechBubble: Bool = false
    var currentContext: SplurjiContext = .home

    private var lastQuestCompletedAt: Date?
    private var lastLevelUpAt: Date?
    private var streakBroken: Bool = false
    private var streakActive: Bool = false
    private var appOpenedAt: Date = Date()
    private var hasShownDailyGreeting: Bool = false

    func update(
        streakDays: Int,
        questCompletedRecently: Bool,
        leveledUpRecently: Bool,
        streakJustBroken: Bool
    ) {
        if questCompletedRecently {
            lastQuestCompletedAt = Date()
        }
        if leveledUpRecently {
            lastLevelUpAt = Date()
        }
        streakBroken = streakJustBroken
        streakActive = streakDays > 0

        recalculate(streakDays: streakDays)
    }

    func setContext(_ context: SplurjiContext) {
        guard currentContext != context else { return }
        currentContext = context
        recalculate(streakDays: streakActive ? 1 : 0)
    }

    func showGreetingIfNeeded() {
        guard !hasShownDailyGreeting else { return }
        hasShownDailyGreeting = true
        shouldShowSpeechBubble = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            shouldShowSpeechBubble = false
        }
    }

    func showRandomMessage() {
        moodMessage = contextMessage()
        shouldShowSpeechBubble = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            shouldShowSpeechBubble = false
        }
    }

    func dismissBubble() {
        shouldShowSpeechBubble = false
    }

    private func recalculate(streakDays: Int) {
        let now = Date()

        if let levelUp = lastLevelUpAt, now.timeIntervalSince(levelUp) < 600 {
            currentMood = .proud
            moodMessage = "LEVEL UP! You're getting so strong!"
            return
        }

        if let quest = lastQuestCompletedAt, now.timeIntervalSince(quest) < 300 {
            currentMood = .celebrating
            moodMessage = "YES! That was amazing!"
            return
        }

        if streakBroken {
            currentMood = .sad
            moodMessage = "It's okay! Every champion falls. Let's start fresh"
            return
        }

        switch currentContext {
        case .quests:
            currentMood = .encouraging
            moodMessage = "Pick a quest! I believe in you!"
        case .vault:
            currentMood = .thinking
            moodMessage = "Ooh, let's see what cards you've got..."
        case .games:
            currentMood = streakActive ? .happy : .encouraging
            moodMessage = streakActive ? "Let's keep this streak going!" : "Ready to play?"
        case .home:
            if streakActive {
                currentMood = .happy
                moodMessage = greetingForTime()
            } else {
                currentMood = .idle
                moodMessage = greetingForTime()
            }
        case .onboarding:
            currentMood = .encouraging
            moodMessage = "Welcome! Let's get started!"
        case .other:
            currentMood = .idle
            moodMessage = ""
        }

        if streakDays >= 7 {
            moodMessage = "A whole week! You're unstoppable!"
        }
    }

    private func greetingForTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning! Ready to crush it today?"
        case 12..<17: return "Keep up the great work this afternoon!"
        case 17..<22: return "Great job today! Your streak is safe"
        default: return "Burning the midnight oil? Rest well!"
        }
    }

    private func contextMessage() -> String {
        switch currentContext {
        case .home:
            return [
                "You've got this!",
                "Every small step counts!",
                "Your future self will thank you!",
                "Consistency is your superpower!"
            ].randomElement()!
        case .quests:
            return [
                "Pick a quest! I believe in you!",
                "Which challenge calls to you?",
                "Let's earn some XP today!",
                "Your next adventure awaits!"
            ].randomElement()!
        case .vault:
            return [
                "Feeling lucky?",
                "I wonder what's under there...",
                "Scratch carefully... or go wild!",
                "Ooh, shiny cards await!"
            ].randomElement()!
        case .games:
            return [
                "The arcade is calling!",
                "Ready to level up?",
                "Let's make some progress!"
            ].randomElement()!
        case .onboarding:
            return "Welcome to Splurj!"
        case .other:
            return "Hey there!"
        }
    }
}
