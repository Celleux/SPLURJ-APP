import SwiftUI
import SwiftData

// MARK: - Splurj Home host
//
// Bridges UserProfile + streak/savings data into SplurjHomeView. Replaces
// the old HomeView as the Home tab's root — production dashboards
// (transactions, HRV, quests) redistribute to other tabs under the
// Copy Pack v2 design language.

struct SplurjHomeHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit

    private var profile: UserProfile? { profiles.first }

    private var variant: SplurjVariant {
        profile?.splurjVariant ?? .her
    }

    private var archetype: SplurjArchetype {
        profile?.splurjArchetype ?? .builder
    }

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

    private var equippedCosmetics: Set<CosmeticID> {
        profile?.equippedCosmetics ?? []
    }

    var body: some View {
        SplurjHomeView(
            variant: variant,
            personality: personality,
            stage: stage,
            level: level,
            equippedCosmetics: equippedCosmetics
        )
        .task {
            await healthKit.refresh()
            profile?.lastOpenDate = Date()
            try? modelContext.save()
        }
    }
}

#if DEBUG
#Preview("SplurjHomeHost") {
    SplurjHomeHost()
        .modelContainer(for: [UserProfile.self, ImpulseLog.self], inMemory: true)
        .environment(HealthKitService.shared)
}
#endif
