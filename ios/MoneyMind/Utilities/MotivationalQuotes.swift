import Foundation

nonisolated enum MotivationalQuotes: Sendable {
    static let all: [String] = [
        "Every dollar you keep is a vote for the life you want.",
        "You don't have to be perfect — just present.",
        "The urge will pass. You won't even remember it tomorrow.",
        "Small wins compound into extraordinary change.",
        "Your future self is thanking you right now.",
        "Awareness is the first step to freedom.",
        "You are not your impulses. You are the one who notices them.",
        "Progress, not perfection.",
        "The best time to start was yesterday. The second best is now.",
        "Financial peace isn't about having more — it's about needing less.",
        "Every mindful moment is a victory.",
        "Strength grows in the moments you think you can't go on.",
        "You've survived 100% of your hardest days.",
        "The craving is temporary. Your goals are permanent.",
        "One conscious choice at a time.",
        "Discomfort is the price of growth.",
        "You are building a new relationship with money.",
        "Today's restraint is tomorrow's freedom.",
        "The wave always passes. Always.",
        "Your worth isn't measured in what you spend.",
        "Courage is not the absence of fear — it's acting despite it.",
        "Each day you resist, your brain rewires a little more.",
        "Money is a tool. You decide how to use it.",
        "Pause. Breathe. Choose.",
        "The strongest people are those who fight battles no one knows about.",
        "You are rewriting your story, one choice at a time.",
        "Impulse says now. Wisdom says wait.",
        "Freedom is on the other side of this moment.",
        "You've already proven you can do hard things.",
        "The gap between impulse and action — that's where your power lives.",
        "Healing isn't linear, but every step counts.",
        "What you resist, persists. What you observe, dissolves.",
        "Your bank account reflects your values. Make it intentional.",
        "Don't count the days. Make the days count.",
        "The most powerful word in finance: 'No.'",
        "You don't need it. You just want the feeling it promises.",
        "Delayed gratification is a superpower.",
        "Every urge you surf makes the next one smaller.",
        "Be patient with yourself. Change takes time.",
        "The money you save today funds the dreams of tomorrow.",
        "Mindfulness is remembering what you truly want.",
        "Your triggers don't define you. Your responses do.",
        "Start where you are. Use what you have. Do what you can.",
        "The best investment you can make is in yourself.",
        "Recovery is not a destination — it's a daily practice.",
        "You are stronger than any craving.",
        "Peace of mind is the ultimate luxury.",
        "Every 'no' to impulse is a 'yes' to your future.",
        "The path to financial wellness starts with self-compassion.",
        "Trust the process. Trust yourself."
    ]

    static func quoteForToday() -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return all[(dayOfYear - 1) % all.count]
    }
}
