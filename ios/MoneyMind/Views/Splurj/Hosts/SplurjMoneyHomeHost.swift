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
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \BudgetCategory.sortOrder) private var budgets: [BudgetCategory]
    @Query(
        filter: #Predicate<DailyQuestSlot> { $0.cadence == "daily" },
        sort: \DailyQuestSlot.offeredDate, order: .reverse
    )
    private var dailyQuestSlots: [DailyQuestSlot]
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit
    @Environment(PremiumManager.self) private var premiumManager

    @State private var showProfile = false
    @State private var showQuestHub = false

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

    /// Today's active DailyQuestSlot — the one whose offeredDate is today.
    private var todaysQuestSlot: DailyQuestSlot? {
        let calendar = Calendar.current
        return dailyQuestSlots.first {
            calendar.isDateInToday($0.offeredDate) && $0.expiresAt > Date()
        }
    }

    private var todaysQuestDefinition: QuestDefinition? {
        guard let slot = todaysQuestSlot else { return nil }
        return QuestDataManager.shared.quest(byID: slot.questID)
    }

    private var questTitle: String {
        todaysQuestDefinition?.title ?? "Skip the 10pm scroll-shop"
    }

    private var questSubtitle: String {
        todaysQuestDefinition?.subtitle ?? "Your top splurge window. Hold the line."
    }

    private var questXP: Int {
        todaysQuestDefinition?.baseXP ?? 20
    }

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
            questTitle: questTitle,
            questSubtitle: questSubtitle,
            questXP: questXP,
            onOpenProfile: { showProfile = true },
            onOpenQuest: { showQuestHub = true }
        )
        .task {
            // --- Session open side effects (restored from legacy HomeView.onAppear) ---
            if let profile {
                premiumManager.updateInstallDate(profile.installDate)
                profile.lastOpenDate = Date()
                NotificationService.shared.scheduleAllNotifications(profile: profile)
                NotificationService.shared.checkBudgetThresholds(
                    budgets: Array(budgets),
                    transactions: Array(transactions),
                    profile: profile,
                    modelContext: modelContext
                )
                if profile.currentStreak > 0 {
                    NotificationService.shared.celebrateStreak(
                        days: profile.currentStreak,
                        profile: profile,
                        modelContext: modelContext
                    )
                }
            }
            ensureDefaultBudgets()
            applyPhantomProgressIfNeeded()
            try? modelContext.save()

            await healthKit.refresh()
            if let profile {
                healthKit.evaluateJITAI(profile: profile, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showProfile) {
            SplurjProfileHost()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showQuestHub) {
            NavigationStack { QuestHubView() }
        }
    }

    /// First-run: seed default budget categories so Wallet · Budgets shows
    /// sensible rows before the user has set anything up.
    private func ensureDefaultBudgets() {
        guard budgets.isEmpty else { return }
        for (i, def) in BudgetCategory.defaults.enumerated() {
            let budget = BudgetCategory(
                name: def.0,
                icon: def.1,
                colorHex: def.2,
                monthlyLimit: def.3,
                sortOrder: i
            )
            modelContext.insert(budget)
        }
    }

    /// Phantom progress (legacy WalletView behavior): seed profile.totalSaved
    /// with $2 on first run so Profile stats + share cards show a non-zero
    /// starting value. Psychological hook from the BillionDollar Design
    /// Blueprint — makes Day 1 feel like "something already happened."
    private func applyPhantomProgressIfNeeded() {
        guard let profile,
              !profile.phantomProgressApplied,
              profile.totalSaved == 0
        else { return }
        profile.totalSaved = 2.0
        profile.phantomProgressApplied = true
    }
}
