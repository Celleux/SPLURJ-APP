import Foundation

// MARK: - Pronouns
//
// One atom that everything else composes from. Resolves from SplurjVariant.
// Keys are explicit rather than subscripted — the compiler holds us to the
// six forms so we can't silently drift across variants.

nonisolated struct SplurjPronouns: Sendable {
    let they: String        // "she" / "he" / "they"
    let their: String       // "her" / "his" / "their"
    let them: String        // "her" / "him" / "them"
    let reflexive: String   // "herself" / "himself" / "themself"
    let isAre: String       // "is" / "is" / "are"
    let possessive: String  // "hers" / "his" / "theirs"
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
// One case per user-visible string. Associated values carry the template
// arguments — compiler-checked so we can't call a greeting key without a
// name or a celebration key without a level.
//
// Sourced directly from explorations/copy-seam.jsx (COPY_MAP). Anytime a
// new copy key is added in the prototype, add it here + provide resolvers
// for all three variants — the exhaustive `resolve(for:)` switch below
// will refuse to compile until you do.

nonisolated enum CopyKey: Sendable, Hashable {
    // Greetings — Home, rotated by time of day
    case greetEvening(name: String)
    case greetMorning(name: String)
    case greetPayday(name: String)

    // Nudges (intercepts) — fire when a risky purchase is detected
    case nudgeLatenight
    case nudgeHrv
    case nudgeOverBudget(amount: Int)

    // Celebrations — streaks, level-ups, pact wins
    case celebrateStreak(days: Int)
    case celebrateLevelup(level: Int)
    case celebratePactWon(partner: String)

    // Errors & edge cases — sync failures, missing HRV
    case errorSync
    case errorNoHrv

    // Share-card titles — Instagram / iMessage exports
    case shareStreak(days: Int)
    case shareSaved(amount: Int)
}

// MARK: - Resolver

extension CopyKey {
    func resolve(for variant: SplurjVariant) -> String {
        switch self {

        case .greetEvening(let n):
            switch variant {
            case .her:     return "Evening, \(n). Splurj\u{2019}s curled up."
            case .him:     return "Evening, \(n). Splurj\u{2019}s tucked in."
            case .neutral: return "Evening, \(n). Splurj\u{2019}s resting."
            }

        case .greetMorning(let n):
            switch variant {
            case .her:     return "Morning, \(n). She\u{2019}s waiting by the window."
            case .him:     return "Morning, \(n). He\u{2019}s already out stretching."
            case .neutral: return "Morning, \(n). They\u{2019}re up and about."
            }

        case .greetPayday(let n):
            switch variant {
            case .her:     return "\(n), money just landed. Splurj grew half an inch."
            case .him:     return "\(n), paycheck hit. Splurj noticed."
            case .neutral: return "\(n), funds are in. Splurj felt it."
            }

        case .nudgeLatenight:
            switch variant {
            case .her:     return "Splurj flinched. It\u{2019}s 11:23pm \u{2014} her least favorite hour for your cart."
            case .him:     return "Splurj perked up. 11:23pm. You know what he\u{2019}s going to say."
            case .neutral: return "Splurj stirred. It\u{2019}s 11:23pm \u{2014} your pattern hour."
            }

        case .nudgeHrv:
            switch variant {
            case .her:     return "Your HRV\u{2019}s dipping. Splurj wants to breathe with you first."
            case .him:     return "HRV\u{2019}s climbing the wrong way. Splurj says pause \u{2014} 60 seconds."
            case .neutral: return "Signals are spiking. Splurj suggests a breath."
            }

        case .nudgeOverBudget(let amount):
            switch variant {
            case .her:     return "This lands you $\(amount) over Shopping. Splurj hid her leaves."
            case .him:     return "\(amount) dollars past Shopping. Splurj isn\u{2019}t judging \u{2014} just noticing."
            case .neutral: return "$\(amount) over Shopping. Splurj\u{2019}s keeping count with you."
            }

        case .celebrateStreak(let days):
            switch variant {
            case .her:     return "\(days) days. Splurj\u{2019}s blooming \u{2014} look at her."
            case .him:     return "\(days) days clean. Splurj grew a new leaf."
            case .neutral: return "\(days) in a row. Splurj\u{2019}s unmistakably bigger."
            }

        case .celebrateLevelup(let lv):
            switch variant {
            case .her:     return "Level \(lv). Splurj unfurled her canopy."
            case .him:     return "Level \(lv). Splurj hit leafy-cap stage."
            case .neutral: return "Level \(lv). Splurj\u{2019}s fully-leaved now."
            }

        case .celebratePactWon(let partner):
            switch variant {
            case .her:     return "You and \(partner) held the line. Splurj\u{2019}s proud."
            case .him:     return "You + \(partner): solid. Splurj is doing a little shake."
            case .neutral: return "You both kept the pact. Splurj approves."
            }

        case .errorSync:
            switch variant {
            case .her:     return "Splurj lost her signal. Reconnect when you can."
            case .him:     return "Splurj is offline. No rush \u{2014} we\u{2019}ll reconnect."
            case .neutral: return "Splurj\u{2019}s offline. No pressure \u{2014} reconnect later."
            }

        case .errorNoHrv:
            switch variant {
            case .her:     return "No wrist data today. Splurj\u{2019}s eyes are closed for this one."
            case .him:     return "No HRV signal. Splurj is flying blind on mood today."
            case .neutral: return "No HRV. Splurj can\u{2019}t read your signals right now."
            }

        case .shareStreak(let days):
            switch variant {
            case .her:     return "Splurj and me \u{00B7} \(days) days"
            case .him:     return "\(days) days with Splurj"
            case .neutral: return "\(days)-day streak \u{00B7} Splurj"
            }

        case .shareSaved(let amount):
            switch variant {
            case .her:     return "Splurj helped me save $\(amount)"
            case .him:     return "Splurj \u{00B7} $\(amount) saved"
            case .neutral: return "Splurj \u{00B7} $\(amount) saved"
            }
        }
    }
}

// MARK: - Public API
//
// Every user-facing string should go through this function. Pulls the
// user's variant from the model layer (UserProfile.splurj later) — for
// now the caller passes it explicitly.

@inlinable
public func copy(_ key: CopyKey, for variant: SplurjVariant) -> String {
    key.resolve(for: variant)
}
