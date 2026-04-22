import SwiftUI
import SwiftData

// MARK: - Splurj Home host
//
// Bridges UserProfile + streak data into SplurjHomeView and repurposes
// the terrarium command bar as the app's primary action surface:
//   FEED    → Log Win       (you fed the mascot with a saved dollar)
//   WATER   → Add Expense   (tend the plot honestly)
//   BREATHE → Urge Surf     (30-second breathing intercept)
//   BED     → Check-in      (evening reflection)

struct SplurjHomeHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit

    @State private var showLogWin = false
    @State private var showAddExpense = false
    @State private var showUrgeSurf = false
    @State private var showCheckIn = false
    @State private var showProfile = false

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

    private var isFirstRun: Bool {
        impulseLogs.isEmpty && (profile?.currentStreak ?? 0) == 0
    }

    var body: some View {
        SplurjHomeView(
            variant: variant,
            personality: personality,
            stage: stage,
            level: level,
            equippedCosmetics: equippedCosmetics,
            onFeed:    { showLogWin = true },
            onWater:   { showAddExpense = true },
            onBreathe: { showUrgeSurf = true },
            onBed:     { showCheckIn = true },
            onOpenProfile: { showProfile = true },
            isFirstRun: isFirstRun,
            onStartDay1Quest: { showLogWin = true }
        )
        .task {
            await healthKit.refresh()
            profile?.lastOpenDate = Date()
            try? modelContext.save()
        }
        .sheet(isPresented: $showLogWin) {
            LogWinSheet()
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet()
        }
        .fullScreenCover(isPresented: $showUrgeSurf) {
            UrgeSurfView(siriTriggered: false)
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            SiriCheckInView()
        }
        .sheet(isPresented: $showProfile) {
            SplurjProfileHost()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
