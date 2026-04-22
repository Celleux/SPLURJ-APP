import Foundation

// MARK: - Pronouns
//
// Preserved as an atom for any copy that names the user in 3rd person
// (rare under the new voice — Splurj talks in first person "i"). Still
// shipped because a few legacy strings and future share-card text may
// need pronoun substitution.

nonisolated struct SplurjPronouns: Sendable {
    let they: String
    let their: String
    let them: String
    let reflexive: String
    let isAre: String
    let possessive: String
}

extension SplurjVariant {
    var pronouns: SplurjPronouns {
        switch self {
        case .her:
            return .init(they: "she", their: "her", them: "her",
                         reflexive: "herself", isAre: "is", possessive: "hers")
        case .him:
            return .init(they: "he", their: "his", them: "him",
                         reflexive: "himself", isAre: "is", possessive: "his")
        case .neutral:
            return .init(they: "they", their: "their", them: "them",
                         reflexive: "themself", isAre: "are", possessive: "theirs")
        }
    }

    /// Mascot name — always "Splurj" per the brief. Never render "Splurji" in UI.
    var mascotName: String { "Splurj" }
}

// MARK: - Copy keys
//
// Every single-string user-facing copy point in the app. Structured
// groups:
//   greet*       — Home greetings
//   nudge*       — in-app intercept banners
//   celebrate*   — level-ups, pacts, streaks
//   error*       — sync / HRV edge cases
//   share*       — share-card titles (secondary to the new Share views)
//   voice*       — the new Copy Pack's in-product tagline surfaces
//
// Voice (Copy Pack §05):
//   · lowercase openings ("morning. ready?" not "Good morning!")
//   · Splurj speaks first-person "i"
//   · specific numbers, short sentences
//   · approved emoji only: 🔥 🌙 ☕ ✨ 🏆
//
// Most new keys return the SAME string across the three variants because
// Splurj's voice uses first-person; pronouns only re-appear when the
// copy references the user in third person (rare).

nonisolated enum CopyKey: Sendable, Hashable {
    // Greetings (rewritten in new voice)
    case greetEvening(name: String)
    case greetMorning(name: String)
    case greetPayday(name: String)

    // Nudges — short "i" voice intercepts
    case nudgeLatenight
    case nudgeHrv
    case nudgeOverBudget(amount: Int)

    // Celebrations
    case celebrateStreak(days: Int)
    case celebrateLevelup(level: Int)
    case celebratePactWon(partner: String)

    // Errors
    case errorSync
    case errorNoHrv

    // Share-card titles (condensed — full share cards render via
    // ShareCard* views; these are fallback social captions.)
    case shareStreak(days: Int)
    case shareSaved(amount: Int)

    // New Copy Pack additions
    case taglineHero           // onboarding hero sub-tagline
    case seamCodeMarker        // dev-only string kept for analytics
}

// MARK: - Resolver

extension CopyKey {
    func resolve(for variant: SplurjVariant) -> String {
        switch self {

        case .greetEvening(let n):
            // First-person: Splurj says "i'm"
            return "evening, \(n). i\u{2019}m curled up."

        case .greetMorning(let n):
            // First-person: Splurj is the one stretching
            return "morning, \(n). i\u{2019}m already up."

        case .greetPayday(let n):
            return "\(n), paycheck hit. i grew half an inch."

        case .nudgeLatenight:
            return "it\u{2019}s 11:23pm. your pattern hour. one breath first?"

        case .nudgeHrv:
            return "hrv\u{2019}s dipping. breathe with me — 60s."

        case .nudgeOverBudget(let amount):
            return "$\(amount) over shopping. not a lecture — just a heads-up."

        case .celebrateStreak(let days):
            return "\(days) days. unmistakably bigger. \u{1F525}"

        case .celebrateLevelup(let lv):
            return "level \(lv). i\u{2019}m taller. look what we did. \u{2728}"

        case .celebratePactWon(let partner):
            return "you and \(partner) held the line. proud."

        case .errorSync:
            return "i\u{2019}m offline. no rush — we\u{2019}ll reconnect."

        case .errorNoHrv:
            return "no hrv today. flying blind on mood — still with you."

        case .shareStreak(let days):
            // Variant-aware: share captions reference the mascot by name
            switch variant {
            case .her:     return "Splurji and me \u{00B7} \(days) days"
            case .him:     return "\(days) days with Splurji"
            case .neutral: return "\(days)-day streak \u{00B7} Splurji"
            }

        case .shareSaved(let amount):
            switch variant {
            case .her:     return "Splurji helped me save $\(amount)"
            case .him, .neutral: return "Splurji \u{00B7} $\(amount) saved"
            }

        case .taglineHero:
            return "a tiny creature that grows when you save — and wilts when you splurge."

        case .seamCodeMarker:
            return "copy-seam.v2"
        }
    }
}

// MARK: - Public API

func copy(_ key: CopyKey, for variant: SplurjVariant) -> String {
    key.resolve(for: variant)
}
