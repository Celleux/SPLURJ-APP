import SwiftUI
import Foundation

// MARK: - Splurj DNA archetype (from Copy Pack — 5 splurge-trigger types)
//
// Claude Design names each Splurji after the splurge pattern it's built to
// shield against. Enum cases keep their legacy names (builder/empath/riser/
// minimalist/generous) for SwiftData stability; the user-facing name comes
// from pitch.name. The 5 DNA types:
//   • builder    → "Stress Shield"     (stress & bad days)
//   • empath     → "FOMO Filter"       (social spirals, late-night scroll)
//   • riser      → "Reward Regulator"  (payday splurges, "treat yourself")
//   • minimalist → "Boredom Buddy"     (dopamine dips, apps-open)
//   • generous   → "Your Splurji"      (custom / other triggers)

nonisolated enum SplurjArchetype: String, CaseIterable, Identifiable, Codable, Sendable, Hashable {
    case builder, empath, riser, minimalist, generous

    var id: String { rawValue }

    struct Pitch: Sendable {
        let name: String       // "Stress Shield"
        let kicker: String     // "YOUR SPLURJI IS BORN"
        let description: String
        let stats: [String]    // ["LV 01", "STAGE Seed", "DNA Stress"]
        let sigil: String      // single glyph used on reveal
        let accent: Color
    }

    /// The DNA chip label used on the reveal, in share cards, and in
    /// Profile.Stats (e.g. "Stress", "FOMO", "Rewards", "Boredom", "Custom").
    var dnaLabel: String {
        switch self {
        case .builder:    "Stress"
        case .empath:     "FOMO"
        case .riser:      "Rewards"
        case .minimalist: "Boredom"
        case .generous:   "Custom"
        }
    }

    var pitch: Pitch {
        switch self {
        case .builder:
            return .init(
                name: "Stress Shield",
                kicker: "YOUR SPLURJI IS BORN",
                description: "She\u{2019}ll grow as you save, meditate, and hit pacts. She starts as a seedling.",
                stats: ["LV 01", "STAGE Seed", "DNA Stress"],
                sigil: "\u{1F6E1}",   // 🛡
                accent: Theme.glow
            )
        case .empath:
            return .init(
                name: "FOMO Filter",
                kicker: "YOUR SPLURJI IS BORN",
                description: "She\u{2019}ll grow as you save, meditate, and hit pacts. She starts as a seedling.",
                stats: ["LV 01", "STAGE Seed", "DNA FOMO"],
                sigil: "\u{1F441}",   // 👁
                accent: Theme.petal
            )
        case .riser:
            return .init(
                name: "Reward Regulator",
                kicker: "YOUR SPLURJI IS BORN",
                description: "She\u{2019}ll grow as you save, meditate, and hit pacts. She starts as a seedling.",
                stats: ["LV 01", "STAGE Seed", "DNA Rewards"],
                sigil: "\u{2728}",   // ✨
                accent: Theme.honey
            )
        case .minimalist:
            return .init(
                name: "Boredom Buddy",
                kicker: "YOUR SPLURJI IS BORN",
                description: "She\u{2019}ll grow as you save, meditate, and hit pacts. She starts as a seedling.",
                stats: ["LV 01", "STAGE Seed", "DNA Boredom"],
                sigil: "\u{1F319}",   // 🌙
                accent: Theme.sky
            )
        case .generous:
            return .init(
                name: "Your Splurji",
                kicker: "YOUR SPLURJI IS BORN",
                description: "Unique triggers, unique mascot. She\u{2019}ll grow as you save, meditate, and hit pacts. She starts as a seedling.",
                stats: ["LV 01", "STAGE Seed", "DNA Custom"],
                sigil: "\u{1F33F}",   // 🌿
                accent: Theme.textPrimary
            )
        }
    }
}

// MARK: - Push notifications
//
// Port of Copy Pack §01. 12 messages × 4 categories. `title` is the bold
// lockscreen headline, `body` is the subline. Emojis are restricted per
// voice law §06 (🔥 🌙 ☕ ✨ 🏆 only).

nonisolated struct PushMessage: Sendable, Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

nonisolated enum PushCategory: String, Sendable, CaseIterable {
    case morning, sos, celebration, streakRisk
}

nonisolated enum PushCopy {

    /// 3 morning nudges. Cycled daily 8:30am by NotificationService.
    static let morning: [PushMessage] = [
        .init(title: "morning. ready?",   body: "3 pacts waiting. coffee first. \u{2615}"),
        .init(title: "day 17. \u{1F525}", body: "keep the streak alive — 2 min check-in?"),
        .init(title: "soft opening.",     body: "$42 deflected yesterday. proud of you."),
    ]

    /// 3 SOS intercepts. Fired by CoachEngine real-time.
    static let sos: [PushMessage] = [
        .init(title: "wait. breathe.",    body: "something tells me you\u{2019}re about to buy. tap for 60s pause."),
        .init(title: "hey. it\u{2019}s me.", body: "cart open. want to talk it through first?"),
        .init(title: "$189 at 11pm?",     body: "classic. let\u{2019}s sleep on it. i\u{2019}ll save the link."),
    ]

    /// 3 celebration pushes. Milestone, pact-kept, level-up.
    static let celebration: [PushMessage] = [
        .init(title: "$1,000 milestone \u{1F3C6}", body: "you just hit threshold. tap to see your badge."),
        .init(title: "pact kept. proud.",            body: "no doordash, 30 days. you earned the gold shield."),
        .init(title: "level up \u{2728}",             body: "i\u{2019}m a phoenix now. look what we did."),
    ]

    /// 3 evening streak-risk nudges. Escalate toward midnight.
    static let streakRisk: [PushMessage] = [
        .init(title: "don\u{2019}t break day 47.", body: "30 seconds to log. that\u{2019}s all."),
        .init(title: "last call \u{1F319}",       body: "streak resets at midnight. i\u{2019}ll wait up."),
        .init(title: "10 min. come on.",           body: "you didn\u{2019}t come this far to come this far."),
    ]

    static func randomMessage(for category: PushCategory, using rng: inout SystemRandomNumberGenerator) -> PushMessage {
        let pool: [PushMessage]
        switch category {
        case .morning:     pool = morning
        case .sos:         pool = sos
        case .celebration: pool = celebration
        case .streakRisk:  pool = streakRisk
        }
        return pool[Int.random(in: 0..<pool.count, using: &rng)]
    }

    static func randomMessage(for category: PushCategory) -> PushMessage {
        var rng = SystemRandomNumberGenerator()
        return randomMessage(for: category, using: &rng)
    }
}

// MARK: - Empty states
//
// Port of Copy Pack §04. 8 empty-state triples (title / subtitle / CTA).
// Views pull these by kind — never hardcode.

nonisolated enum EmptyStateKind: String, CaseIterable, Sendable {
    case walletNoTransactions, pactsNone, coachAllClear, hubFirstRun
    case streakBroken, collectionLocked, budgetOver, offline
}

nonisolated struct EmptyStateCopy: Sendable {
    let title: String
    let subtitle: String
    let ctaLabel: String
    let art: String   // single-glyph display, per prototype
}

extension EmptyStateKind {
    var copy: EmptyStateCopy {
        switch self {
        case .walletNoTransactions:
            return .init(title: "Nothing to report.",
                         subtitle: "Link a card and i\u{2019}ll start watching. Nothing spent yet — which, honestly, is a flex.",
                         ctaLabel: "Link a card",
                         art: "\u{25EF}")
        case .pactsNone:
            return .init(title: "Make me a promise.",
                         subtitle: "A pact is small and specific. \u{201C}No doordash this week.\u{201D} I\u{2019}ll hold the line with you.",
                         ctaLabel: "+ New pact",
                         art: "\u{25C7}")
        case .coachAllClear:
            return .init(title: "Nothing to fix.",
                         subtitle: "Your week is quiet. Enjoy it. I\u{2019}ll tap you if anything changes.",
                         ctaLabel: "Plan next week",
                         art: "\u{2713}")
        case .hubFirstRun:
            return .init(title: "Unlock your first room.",
                         subtitle: "Save $100 and i\u{2019}ll get a plant. Save $500 and we upgrade the walls.",
                         ctaLabel: "See the hub",
                         art: "\u{2605}")
        case .streakBroken:
            return .init(title: "Day 0. Happens.",
                         subtitle: "47 days was real. It doesn\u{2019}t un-happen. Let\u{2019}s start tomorrow clean.",
                         ctaLabel: "Reset the clock",
                         art: "\u{25D1}")
        case .collectionLocked:
            return .init(title: "Earn it, don\u{2019}t buy it.",
                         subtitle: "Cosmetics unlock by saving, not paying. Coin sticker at $100. Leaf at $250.",
                         ctaLabel: "How it works",
                         art: "\u{25D0}")
        case .budgetOver:
            return .init(title: "Over by $42.",
                         subtitle: "Not a crisis. Not a lecture. Just a heads-up. Want to rebalance next week?",
                         ctaLabel: "Rebalance",
                         art: "\u{25ED}")
        case .offline:
            return .init(title: "Lost the thread.",
                         subtitle: "Can\u{2019}t see your accounts right now. I\u{2019}ll reconnect when we\u{2019}re back online.",
                         ctaLabel: "Retry",
                         art: "\u{25CC}")
        }
    }
}

// MARK: - DNA quiz (single-question splurge-trigger picker)
//
// Claude Design's onboarding uses ONE question, not five: "When do you
// splurge most?" with 5 DNA options. Each option maps directly to an
// archetype. The QuizQuestion model keeps the array shape so the
// onboarding flow's existing iteration code stays unchanged — it just
// iterates over a single-element list now.

nonisolated struct QuizOption: Sendable, Identifiable {
    let id: String
    let label: String
    let sub: String                 // secondary line, e.g. "HALT triggers · emotional spending"
    let systemImage: String         // SF Symbol shown on the leading icon
    let archetype: SplurjArchetype
}

nonisolated struct QuizQuestion: Sendable, Identifiable {
    let id: Int
    let prompt: String
    let kicker: String              // e.g. "02 · SPLURGE DNA"
    let options: [QuizOption]
}

nonisolated enum SplurjQuiz {
    static let questions: [QuizQuestion] = [
        .init(
            id: 1,
            prompt: "When do you splurge most?",
            kicker: "02 \u{00B7} SPLURGE DNA",
            options: [
                .init(
                    id: "stress",
                    label: "Stress & bad days",
                    sub: "HALT triggers \u{00B7} emotional spending",
                    systemImage: "cloud.rain.fill",
                    archetype: .builder
                ),
                .init(
                    id: "fomo",
                    label: "FOMO & social spirals",
                    sub: "Friends buying \u{00B7} late-night scrolling",
                    systemImage: "person.2.fill",
                    archetype: .empath
                ),
                .init(
                    id: "rewards",
                    label: "I-earned-it rewards",
                    sub: "Payday splurges \u{00B7} \u{201C}treat yourself\u{201D}",
                    systemImage: "sparkles",
                    archetype: .riser
                ),
                .init(
                    id: "boredom",
                    label: "Boredom & dopamine dips",
                    sub: "Apps open \u{00B7} nothing to do",
                    systemImage: "moon.zzz.fill",
                    archetype: .minimalist
                ),
                .init(
                    id: "custom",
                    label: "Something else",
                    sub: "Tell Splurji what you notice",
                    systemImage: "leaf.fill",
                    archetype: .generous
                ),
            ]
        )
    ]

    /// With a single-question quiz, the score is simply the picked option's
    /// archetype. The signature stays the same so callers don't change.
    static func score(_ answers: [QuizOption]) -> SplurjArchetype {
        answers.first?.archetype ?? .builder
    }
}

// MARK: - Voice laws (dev reference, not user-facing)

nonisolated enum SplurjVoiceLaw: String, CaseIterable, Sendable {
    case lowercase     = "Most messages start lowercase. Casual, like a text from a friend."
    case noShame       = "Never \u{201C}you failed.\u{201D} Splurj says \u{201C}happens\u{201D} and moves on."
    case specificNumbers = "\u{201C}$42 deflected\u{201D} beats \u{201C}you saved today.\u{201D} Concrete numbers make it real."
    case shortSentences = "Notifications under 60 chars. Empty states under 20 words."
    case firstPerson   = "Splurj says \u{201C}i\u{201D}, not \u{201C}the app.\u{201D} It\u{2019}s a character, not a tool."
    case emojiSparingly = "Max one per message. Only \u{1F525} \u{1F319} \u{2615} \u{2728} \u{1F3C6}."
}
