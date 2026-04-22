import SwiftUI
import Foundation

// MARK: - Splurj archetype (from Copy Pack — 5 post-quiz archetypes)
//
// Locked names per 2026-04 decision: Builder / Empath / Riser / Minimalist /
// Generous. The "Hustler" slot was retired for tonal conflict; "Riser"
// compounds with the mascot's growth metaphor.

nonisolated enum SplurjArchetype: String, CaseIterable, Identifiable, Codable, Sendable, Hashable {
    case builder, empath, riser, minimalist, generous

    var id: String { rawValue }

    struct Pitch: Sendable {
        let name: String       // "The Builder"
        let kicker: String     // "ARCHETYPE 01 · DISCIPLINE"
        let description: String
        let stats: [String]    // ["PLAN-DRIVEN", "MOMENTUM: +"]
        let sigil: String      // single glyph used on reveal
        let accent: Color
    }

    var pitch: Pitch {
        switch self {
        case .builder:
            return .init(
                name: "The Builder",
                kicker: "ARCHETYPE 01 \u{00B7} DISCIPLINE",
                description: "You like the graph going up. Pacts, streaks, milestones — they work on you. Splurj turns every dollar into a level you can see.",
                stats: ["PLAN-DRIVEN", "MOMENTUM: +"],
                sigil: "\u{25C6}",    // ◆
                accent: Theme.glow
            )
        case .empath:
            return .init(
                name: "The Empath",
                kicker: "ARCHETYPE 02 \u{00B7} FEELING",
                description: "Money is emotional for you. A hard day shows up on the card. That\u{2019}s not weakness — it\u{2019}s signal. Splurj catches the feeling before the cart.",
                stats: ["FEELS EVERY DOLLAR", "KIND ALERTS"],
                sigil: "\u{25C8}",    // ◈
                accent: Color(hex: 0xFF8E7E)
            )
        case .riser:
            return .init(
                name: "The Riser",
                kicker: "ARCHETYPE 03 \u{00B7} GROWTH",
                description: "You came from somewhere — and you\u{2019}re going somewhere better. Every save is proof. Splurj is here for the climb, not the finish line.",
                stats: ["UPWARD MINDSET", "STAGE-DRIVEN"],
                sigil: "\u{25B2}",    // ▲
                accent: Theme.honey
            )
        case .minimalist:
            return .init(
                name: "The Minimalist",
                kicker: "ARCHETYPE 04 \u{00B7} CLARITY",
                description: "Less is the goal. Fewer subs. Fewer taps. More room to breathe. Splurj will help you cut what doesn\u{2019}t earn its keep.",
                stats: ["LOW-FOOTPRINT", "SUBS: TRIMMED"],
                sigil: "\u{25C7}",    // ◇
                accent: Theme.sky
            )
        case .generous:
            return .init(
                name: "The Generous",
                kicker: "ARCHETYPE 05 \u{00B7} CARE",
                description: "You save so someone else doesn\u{2019}t have to worry. Family, partner, the future you. Splurj holds the vision and guards the vault.",
                stats: ["OTHERS-FIRST", "VAULT: SHARED"],
                sigil: "\u{2661}",    // ♡
                accent: Theme.petal
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

// MARK: - DNA quiz (5 questions, weighted scoring)
//
// Port of Copy Pack §02. Each option carries the archetype it votes for;
// QuizResult tallies the votes and returns the highest-scoring archetype
// (ties broken by order → Builder wins over Empath etc., per spec).

nonisolated struct QuizOption: Sendable, Identifiable {
    let id: String
    let label: String
    let archetype: SplurjArchetype
}

nonisolated struct QuizQuestion: Sendable, Identifiable {
    let id: Int                 // 1–5
    let prompt: String
    let options: [QuizOption]
}

nonisolated enum SplurjQuiz {
    static let questions: [QuizQuestion] = [
        .init(id: 1, prompt: "When money stress hits, you\u{2026}", options: [
            .init(id: "q1a", label: "Buy something small to feel in control",  archetype: .empath),
            .init(id: "q1b", label: "Open every app, make a plan",              archetype: .builder),
            .init(id: "q1c", label: "Step back. Cut one thing.",                 archetype: .minimalist),
            .init(id: "q1d", label: "Talk it out with someone who gets it",     archetype: .generous),
        ]),
        .init(id: 2, prompt: "Your last impulse buy was because\u{2026}", options: [
            .init(id: "q2a", label: "It would move me toward a goal",                                      archetype: .builder),
            .init(id: "q2b", label: "I\u{2019}d had a hard day. I deserved it.",                           archetype: .empath),
            .init(id: "q2c", label: "I\u{2019}m tired of the thing I had",                                  archetype: .riser),
            .init(id: "q2d", label: "Honestly? I don\u{2019}t own much — this fills a real gap",           archetype: .minimalist),
        ]),
        .init(id: 3, prompt: "Checking your bank account feels like\u{2026}", options: [
            .init(id: "q3a", label: "A gut punch — I feel every dollar",                 archetype: .empath),
            .init(id: "q3b", label: "A checkpoint — a step toward the next level",       archetype: .riser),
            .init(id: "q3c", label: "A map — numbers moving toward a plan",              archetype: .builder),
            .init(id: "q3d", label: "A mirror — am I living with just enough?",          archetype: .minimalist),
        ]),
        .init(id: 4, prompt: "You save best when\u{2026}", options: [
            .init(id: "q4a", label: "There\u{2019}s a plan and a deadline",              archetype: .builder),
            .init(id: "q4b", label: "I\u{2019}m saving for someone I love",              archetype: .generous),
            .init(id: "q4c", label: "I own less, so there\u{2019}s more left over",      archetype: .minimalist),
            .init(id: "q4d", label: "I\u{2019}m leveling up — the old me wouldn\u{2019}t have", archetype: .riser),
        ]),
        .init(id: 5, prompt: "A year from now, you want to be\u{2026}", options: [
            .init(id: "q5a", label: "First $10K saved",               archetype: .builder),
            .init(id: "q5b", label: "Calmer — kinder to myself",      archetype: .empath),
            .init(id: "q5c", label: "Leveled up — a version I\u{2019}m proud of", archetype: .riser),
            .init(id: "q5d", label: "Owning less. Needing less.",     archetype: .minimalist),
            .init(id: "q5e", label: "Helping the people I love",      archetype: .generous),
        ]),
    ]

    /// Tally the archetype votes across answered questions. Ties resolve
    /// by SplurjArchetype.allCases ordering (builder first).
    static func score(_ answers: [QuizOption]) -> SplurjArchetype {
        var counts: [SplurjArchetype: Int] = [:]
        for a in answers {
            counts[a.archetype, default: 0] += 1
        }
        let ranked = SplurjArchetype.allCases.map { ($0, counts[$0] ?? 0) }
        return ranked.max(by: { $0.1 < $1.1 })?.0 ?? .builder
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
