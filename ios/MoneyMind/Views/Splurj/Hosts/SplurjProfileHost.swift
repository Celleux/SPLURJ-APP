import SwiftUI
import SwiftData

// MARK: - Splurj Profile host
//
// Replaces the legacy GamesHub as the 5th tab. Renders SplurjProfileView
// with real UserProfile data — the mascot's room, cosmetic closet, badge
// shelf, and share cards. Scratch-card / gacha surfaces are intentionally
// retired here for a problem-gambling recovery app.

struct SplurjProfileHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]

    private var profile: UserProfile? { profiles.first }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }
    private var equippedCosmetics: Set<CosmeticID> { profile?.equippedCosmetics ?? [] }
    private var earnedBadges: Set<BadgeID> { profile?.earnedBadges ?? [] }

    private var archetype: SplurjArchetype { profile?.splurjArchetype ?? .builder }

    private var personality: SplurjPersonality {
        switch archetype {
        case .builder:    .builder
        case .empath:     .empath
        case .riser:      .hustler
        case .minimalist: .minimalist
        case .generous:   .generous
        }
    }

    private var level: Int {
        let base = profile?.splurjLevel ?? 1
        let fromStreak = max(1, (profile?.currentStreak ?? 0) / 3 + 1)
        return max(base, fromStreak)
    }

    private var stage: SlimeStage {
        switch level {
        case ...3:   .seedling
        case 4...6:  .sprout
        case 7...10: .grass
        case 11...15: .leafy
        case 16...22: .flowering
        default:      .bonsai
        }
    }

    // XP progress inside the current level block — rough 0...1 fraction.
    // Each level spans 3 streak-days in the current mapping.
    private var xpProgress: Double {
        let streak = Double(profile?.currentStreak ?? 0)
        let into = streak.truncatingRemainder(dividingBy: 3)
        return min(1.0, into / 3.0)
    }

    var body: some View {
        SplurjProfileView(
            variant: variant,
            personality: personality,
            stage: stage,
            level: level,
            xpProgress: xpProgress,
            streak: profile?.currentStreak ?? 0,
            totalSaved: Int(profile?.totalSaved ?? 0),
            purchasesResisted: impulseLogs.count,
            earnedBadges: earnedBadges,
            equippedCosmetics: equippedCosmetics,
            onDismiss: nil
        )
    }
}
