import SwiftUI
import SwiftData

// MARK: - Splurj Money Home host
//
// The Home tab's root. Queries UserProfile + ImpulseLog + HealthKit and
// threads real data into SplurjMoneyHomeView. Hosts the Profile sheet
// triggered from the mascot avatar tap.

struct SplurjMoneyHomeHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit

    @State private var showProfile = false

    private var profile: UserProfile? { profiles.first }
    private var name: String {
        let raw = profile?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return raw.isEmpty ? "friend" : raw
    }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }
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
        max(profile?.splurjLevel ?? 1, (profile?.currentStreak ?? 0) / 3 + 1)
    }

    private var stage: SlimeStage {
        switch level {
        case ...3:    .seedling
        case 4...6:   .sprout
        case 7...10:  .grass
        case 11...15: .leafy
        case 16...22: .flowering
        default:      .bonsai
        }
    }

    private var xpProgress: Double {
        let streak = Double(profile?.currentStreak ?? 0)
        let into = streak.truncatingRemainder(dividingBy: 3)
        return min(1.0, into / 3.0)
    }

    private var savedThisMonth: Double {
        SavingsMath.thisCalendarMonth(logs: impulseLogs)
    }

    private var monthDeltaPercent: Int {
        let delta = SavingsMath.monthOverMonthDelta(logs: impulseLogs)
        let base = max(1.0, savedThisMonth - delta)
        return Int((delta / base * 100).rounded())
    }

    private var hrvText: String {
        guard let ms = healthKit.latestHRV else { return "--" }
        return "\(Int(ms.rounded()))ms"
    }

    private var hrvState: SplurjMoneyHomeView.HRVState {
        guard let ms = healthKit.latestHRV else { return .steady }
        if ms < 25 { return .low }
        if ms < 40 { return .alert }
        return .steady
    }

    private var currencySymbol: String { profile?.currencySymbol ?? "$" }

    var body: some View {
        SplurjMoneyHomeView(
            variant: variant,
            personality: personality,
            stage: stage,
            level: level,
            xpProgress: xpProgress,
            equippedCosmetics: profile?.equippedCosmetics ?? [],
            name: name,
            savedThisMonth: savedThisMonth,
            monthDeltaPercent: monthDeltaPercent,
            streak: profile?.currentStreak ?? 0,
            currencySymbol: currencySymbol,
            hrvText: hrvText,
            hrvState: hrvState,
            questTitle: "Skip the 10pm scroll-shop",
            questSubtitle: "Your top splurge window. Hold the line.",
            questXP: 20,
            onOpenProfile: { showProfile = true },
            onOpenQuest: { }
        )
        .task {
            await healthKit.refresh()
            profile?.lastOpenDate = Date()
            try? modelContext.save()
        }
        .sheet(isPresented: $showProfile) {
            SplurjProfileHost()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
