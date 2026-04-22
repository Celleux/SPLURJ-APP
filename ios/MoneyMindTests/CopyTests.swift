import Testing
@testable import MoneyMind

/// Exhaustiveness tests for the copy seam.
///
/// The resolver enforces all three variants via the compiler (nested
/// switches that must cover every SplurjVariant case). These tests
/// complement that by asserting at runtime that:
/// - every key returns a non-empty string for every variant
/// - every key contains the word "Splurj" where the prototype specifies it
/// - templated args (name, days, level, amount, partner) interpolate
/// - pronouns resolve consistently across all six forms
struct CopyTests {

    /// Every key × every variant → a non-empty string.
    @Test func allKeysNonEmptyAcrossVariants() {
        let keys: [CopyKey] = allKeys()
        for key in keys {
            for variant in SplurjVariant.allCases {
                let result = copy(key, for: variant)
                #expect(!result.isEmpty, "Empty copy for \(key) × \(variant)")
                #expect(!result.contains("Splurji"), "Leaked 'Splurji' in \(key) × \(variant) — use 'Splurj'")
            }
        }
    }

    /// Keys that reference the mascot by name should contain "Splurj".
    @Test func mascotNameReferenced() {
        let mascotKeys: [CopyKey] = [
            .greetEvening(name: "Maya"), .greetPayday(name: "Maya"),
            .nudgeLatenight, .nudgeHrv, .nudgeOverBudget(amount: 12),
            .celebrateStreak(days: 23), .celebrateLevelup(level: 7),
            .celebratePactWon(partner: "Sam"),
            .errorSync, .errorNoHrv,
            .shareStreak(days: 23), .shareSaved(amount: 427),
        ]
        for key in mascotKeys {
            for variant in SplurjVariant.allCases {
                let result = copy(key, for: variant)
                #expect(result.contains("Splurj"), "Expected 'Splurj' in \(key) × \(variant) — got: \(result)")
            }
        }
    }

    @Test func greetingsInterpolateName() {
        let name = "Alex"
        for variant in SplurjVariant.allCases {
            let evening = copy(.greetEvening(name: name), for: variant)
            let morning = copy(.greetMorning(name: name), for: variant)
            let payday = copy(.greetPayday(name: name), for: variant)
            #expect(evening.contains(name))
            #expect(morning.contains(name))
            #expect(payday.contains(name))
        }
    }

    @Test func celebrationsInterpolateNumbers() {
        let streak = copy(.celebrateStreak(days: 42), for: .her)
        #expect(streak.contains("42"))

        let levelup = copy(.celebrateLevelup(level: 9), for: .him)
        #expect(levelup.contains("9"))

        let overBudget = copy(.nudgeOverBudget(amount: 18), for: .neutral)
        #expect(overBudget.contains("18"))

        let saved = copy(.shareSaved(amount: 500), for: .her)
        #expect(saved.contains("500"))
    }

    @Test func pactWonInterpolatesPartner() {
        for variant in SplurjVariant.allCases {
            let result = copy(.celebratePactWon(partner: "Riley"), for: variant)
            // Only the 'her' and 'him' variants name the partner; neutral uses "You both".
            if variant != .neutral {
                #expect(result.contains("Riley"))
            }
        }
    }

    @Test func pronounsCoverAllSixForms() {
        for variant in SplurjVariant.allCases {
            let p = variant.pronouns
            #expect(!p.they.isEmpty)
            #expect(!p.their.isEmpty)
            #expect(!p.them.isEmpty)
            #expect(!p.reflexive.isEmpty)
            #expect(!p.isAre.isEmpty)
            #expect(!p.possessive.isEmpty)
        }
    }

    @Test func mascotNameIsAlwaysSplurj() {
        for variant in SplurjVariant.allCases {
            #expect(variant.mascotName == "Splurj")
        }
    }

    // MARK: - Exhaustive key list
    //
    // Every CopyKey case must appear here. If someone adds a new case
    // without adding it to this list, `allKeysNonEmptyAcrossVariants`
    // won't cover it — we treat this list as the registry.

    private func allKeys() -> [CopyKey] {
        return [
            .greetEvening(name: "Maya"),
            .greetMorning(name: "Maya"),
            .greetPayday(name: "Maya"),
            .nudgeLatenight,
            .nudgeHrv,
            .nudgeOverBudget(amount: 12),
            .celebrateStreak(days: 23),
            .celebrateLevelup(level: 7),
            .celebratePactWon(partner: "Sam"),
            .errorSync,
            .errorNoHrv,
            .shareStreak(days: 23),
            .shareSaved(amount: 427),
        ]
    }
}
