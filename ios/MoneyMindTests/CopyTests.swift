import Testing
@testable import MoneyMind

/// Copy seam tests updated for the Copy Pack v2 voice.
///
/// What changed:
///   · Most keys now return variant-invariant strings (Splurj speaks
///     first-person "i"), so we stopped asserting strict per-variant
///     differences for every key.
///   · We DO enforce that share-card titles stay variant-specific (they
///     reference the mascot by pronoun in social posts).
///   · Voice-law checks: no shame words, no banned emoji, no "Splurji".
struct CopyTests {

    private let allKeys: [CopyKey] = [
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
        .taglineHero,
        .seamCodeMarker,
    ]

    @Test func everyKeyResolvesNonEmptyForEveryVariant() {
        for key in allKeys {
            for variant in SplurjVariant.allCases {
                let s = copy(key, for: variant)
                #expect(!s.isEmpty, "Empty: \(key) × \(variant)")
                #expect(!s.contains("Splurji"), "Leaked Splurji: \(key) × \(variant) → \(s)")
            }
        }
    }

    @Test func shareCaptionsVaryByVariant() {
        let her = copy(.shareStreak(days: 23), for: .her)
        let him = copy(.shareStreak(days: 23), for: .him)
        let neu = copy(.shareStreak(days: 23), for: .neutral)
        #expect(her != him || him != neu,
                "Share captions should differ across variants")
    }

    @Test func templatedArgsInterpolate() {
        #expect(copy(.greetEvening(name: "Alex"), for: .her).contains("Alex"))
        #expect(copy(.celebrateStreak(days: 42), for: .him).contains("42"))
        #expect(copy(.celebrateLevelup(level: 9), for: .neutral).contains("9"))
        #expect(copy(.nudgeOverBudget(amount: 18), for: .her).contains("18"))
        #expect(copy(.shareSaved(amount: 500), for: .her).contains("500"))
        #expect(copy(.celebratePactWon(partner: "Riley"), for: .her).contains("Riley"))
    }

    @Test func voiceLawNoShame() {
        let bannedWords = ["failed", "stupid", "bad job", "you messed up"]
        for key in allKeys {
            for variant in SplurjVariant.allCases {
                let s = copy(key, for: variant).lowercased()
                for word in bannedWords {
                    #expect(!s.contains(word.lowercased()),
                            "Shame word \(word) in \(key) × \(variant)")
                }
            }
        }
    }

    @Test func voiceLawApprovedEmojiOnly() {
        // Approved: 🔥 🌙 ☕ ✨ 🏆
        let approved = Set("\u{1F525}\u{1F319}\u{2615}\u{2728}\u{1F3C6}".unicodeScalars)
        let banned = ["\u{1F60A}", "\u{1F4B0}", "\u{1F389}", "\u{1F609}", "\u{1F44D}"]
        for key in allKeys {
            for variant in SplurjVariant.allCases {
                let s = copy(key, for: variant)
                for banned in banned {
                    #expect(!s.contains(banned),
                            "Banned emoji \(banned) in \(key) × \(variant)")
                }
                // Ensure any emoji present is in the approved set.
                for scalar in s.unicodeScalars where scalar.properties.isEmoji && scalar.value > 0x2000 {
                    // Skip skin-tone / variation selectors / the approved ones
                    if approved.contains(scalar) { continue }
                    if scalar.properties.isEmojiModifier { continue }
                    if scalar.value == 0xFE0F { continue } // variation selector
                    // Let through basic digits / punctuation flagged as emoji-like
                    if scalar.properties.isEmojiPresentation == false { continue }
                    #expect(false, "Unapproved emoji \(scalar) in \(key) × \(variant): \(s)")
                }
            }
        }
    }

    @Test func mascotNameIsAlwaysSplurj() {
        for variant in SplurjVariant.allCases {
            #expect(variant.mascotName == "Splurj")
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

    // MARK: - Copy Pack v2 structural tests

    @Test func allFiveArchetypesHavePitches() {
        for arch in SplurjArchetype.allCases {
            let p = arch.pitch
            #expect(!p.name.isEmpty)
            #expect(p.name.hasPrefix("The "),
                    "Archetype name should start with 'The ': \(p.name)")
            #expect(!p.kicker.isEmpty)
            #expect(!p.description.isEmpty)
            #expect(!p.stats.isEmpty)
            #expect(!p.sigil.isEmpty)
        }
    }

    @Test func quizHasFiveQuestionsAndMapsToFiveArchetypes() {
        #expect(SplurjQuiz.questions.count == 5)
        let mapped = Set(SplurjQuiz.questions.flatMap { $0.options.map(\.archetype) })
        #expect(mapped == Set(SplurjArchetype.allCases),
                "Quiz options should cover all 5 archetypes")
    }

    @Test func quizScoringTalliesCorrectly() {
        let options = SplurjQuiz.questions.flatMap(\.options)
        // Pick 3 Builder + 2 Empath → Builder wins
        let picks = [
            options.first { $0.archetype == .builder }!,
            options.first { $0.archetype == .builder }!,
            options.first { $0.archetype == .builder }!,
            options.first { $0.archetype == .empath }!,
            options.first { $0.archetype == .empath }!,
        ]
        #expect(SplurjQuiz.score(picks) == .builder)
    }

    @Test func pushCopyCategoriesPopulated() {
        #expect(PushCopy.morning.count == 3)
        #expect(PushCopy.sos.count == 3)
        #expect(PushCopy.celebration.count == 3)
        #expect(PushCopy.streakRisk.count == 3)
        for msg in PushCopy.morning + PushCopy.sos + PushCopy.celebration + PushCopy.streakRisk {
            #expect(!msg.title.isEmpty)
            #expect(!msg.body.isEmpty)
            #expect(msg.title.count <= 60, "Push title too long: \(msg.title)")
            #expect(msg.body.count <= 90, "Push body too long: \(msg.body)")
            #expect(!msg.title.contains("Splurji"))
            #expect(!msg.body.contains("Splurji"))
        }
    }

    @Test func everyEmptyStateHasCopy() {
        for kind in EmptyStateKind.allCases {
            let c = kind.copy
            #expect(!c.title.isEmpty)
            #expect(!c.subtitle.isEmpty)
            #expect(!c.ctaLabel.isEmpty)
            #expect(!c.art.isEmpty)
            #expect(!c.title.contains("Splurji"))
            #expect(!c.subtitle.contains("Splurji"))
        }
    }

    @Test func voiceLawsAreWellFormed() {
        for law in SplurjVoiceLaw.allCases {
            #expect(!law.rawValue.isEmpty)
        }
        #expect(SplurjVoiceLaw.allCases.count == 6)
    }
}
