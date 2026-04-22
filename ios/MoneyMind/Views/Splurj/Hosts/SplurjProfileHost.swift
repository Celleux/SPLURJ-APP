import SwiftUI
import SwiftData

// MARK: - Splurj Profile host
//
// Feeds real data into SplurjProfileView and wires Settings-sheet rows
// (Notifications, Recovery check-in / PGSI, Vibe insights, Badges,
// Money Wrapped, Apple Health, Paywall, Help, Sign out) to the existing
// production views via NavigationStack-wrapped sheets.

struct SplurjProfileHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Query private var allChallenges: [SavingsChallenge]
    @Query(filter: #Predicate<InAppNotification> { !$0.isDismissed && !$0.isRead })
    private var unreadNotifications: [InAppNotification]
    @Query(sort: \PGSIAssessment.date, order: .reverse) private var pgsiHistory: [PGSIAssessment]
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.dismiss) private var dismiss

    @State private var activeSheet: ProfileSheet?

    enum ProfileSheet: String, Identifiable {
        case notifications, pgsi, vibe, badges, moneyWrapped, settings, health, paywall, help
        var id: String { rawValue }
    }

    private var profile: UserProfile? { profiles.first }
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

    private var xpPoints: Int { profile?.xpPoints ?? 0 }

    private var splurgeFreeDays: Int {
        let calendar = Calendar.current
        let thirtyAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let resistedDays = Set(
            impulseLogs
                .filter { $0.resisted && $0.date >= thirtyAgo }
                .map { calendar.startOfDay(for: $0.date) }
        )
        return resistedDays.count
    }

    private var pactsWon: Int {
        allChallenges.filter { !$0.isActive && $0.totalSaved > 0 }.count
    }

    private var pgsiDueThisMonth: Bool {
        guard let last = pgsiHistory.first?.date else { return true }
        return !Calendar.current.isDate(last, equalTo: Date(), toGranularity: .month)
    }

    private var journey: [SplurjProfileView.JourneyEvent] {
        let relDate = RelativeDateTimeFormatter()
        relDate.unitsStyle = .abbreviated
        let recent = Array(impulseLogs.prefix(8))
        return recent.enumerated().map { idx, log in
            let when: String
            if Calendar.current.isDateInToday(log.date) {
                when = "Today"
            } else if Calendar.current.isDateInYesterday(log.date) {
                when = "Yesterday"
            } else {
                when = relDate.localizedString(for: log.date, relativeTo: Date())
            }
            let tone: SplurjProfileView.JourneyEvent.Tone = log.resisted ? .glow : .muted
            let xp = log.resisted ? "+\(Int(log.amount))" : "\u{2014}"
            let title = log.resisted ? "Saved \(Int(log.amount)) \u{00B7} \(log.category)" : "Spent on \(log.category)"
            return .init(
                id: "\(log.persistentModelID.hashValue)",
                when: when,
                title: title,
                xp: xp,
                tone: tone,
                hero: idx == 0 && log.resisted && log.amount >= 100
            )
        }
    }

    private var triggers: [SplurjProfileView.TriggerRow] {
        let nonResisted = impulseLogs.filter { !$0.resisted }
        guard !nonResisted.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for log in nonResisted { counts[log.category, default: 0] += 1 }
        let total = nonResisted.count
        let sorted = counts.sorted { $0.value > $1.value }.prefix(4)
        let palette: [SplurjProfileView.TriggerRow.Tone] = [.danger, .honey, .petal, .sky]
        return sorted.enumerated().map { idx, entry in
            let pct = Int((Double(entry.value) / Double(total) * 100).rounded())
            return .init(id: entry.key, label: entry.key, pct: pct, tone: palette[idx % palette.count])
        }
    }

    private var notificationsOnCount: Int {
        guard let p = profile else { return 0 }
        var n = 0
        if p.morningPledgeNotif       { n += 1 }
        if p.eveningReflectionNotif   { n += 1 }
        if p.weeklyPaycheckNotif      { n += 1 }
        if p.streakMaintenanceNotif   { n += 1 }
        if p.milestoneApproachingNotif{ n += 1 }
        return n
    }

    private var appleHealthConnected: Bool { healthKit.latestHRV != nil }

    var body: some View {
        SplurjProfileView(
            variant: variant,
            personality: personality,
            stage: stage,
            level: level,
            xpProgress: xpProgress,
            xpPoints: xpPoints,
            trackLabel: archetype.pitch.name,
            name: profile?.name.trimmingCharacters(in: .whitespaces).isEmpty == false
                ? profile!.name
                : "you",
            streak: profile?.currentStreak ?? 0,
            longestStreak: profile?.longestStreak ?? 0,
            totalSaved: Int((profile?.totalSaved ?? 0).rounded()),
            pactsWon: pactsWon,
            splurgeFreeDays: splurgeFreeDays,
            earnedBadges: profile?.earnedBadges ?? [],
            equippedCosmetics: profile?.equippedCosmetics ?? [],
            journey: journey,
            triggers: triggers,
            subscriptionStatus: "Free plan",
            notificationsOnCount: notificationsOnCount,
            appleHealthConnected: appleHealthConnected,
            unreadNotificationCount: unreadNotifications.count,
            pgsiDueThisMonth: pgsiDueThisMonth,
            onDismiss: { dismiss() },
            onOpenNotifications: { activeSheet = .notifications },
            onOpenPGSI:          { activeSheet = .pgsi },
            onOpenMoneyWrapped:  { activeSheet = .moneyWrapped },
            onOpenVibeAnalytics: { activeSheet = .vibe },
            onOpenBadgeGallery:  { activeSheet = .badges },
            onOpenSettings:      { activeSheet = .settings },
            onOpenHealthSettings:{ activeSheet = .health },
            onOpenPaywall:       { activeSheet = .paywall },
            onOpenHelp:          { activeSheet = .help },
            onSignOut:           { /* TODO: hook to AccountService */ }
        )
        .sheet(item: $activeSheet) { sheet in
            destinationView(for: sheet)
        }
    }

    private var wrappedData: WrappedData {
        let xp = profile?.xpPoints ?? 0
        let stage = CharacterStage.from(xp: xp)
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        let mp: MoneyPersonality
        switch personality {
        case .builder:    mp = .builder
        case .empath:     mp = .generous
        case .hustler:    mp = .hustler
        case .minimalist: mp = .minimalist
        case .generous:   mp = .generous
        }
        return WrappedData(
            periodLabel: f.string(from: Date()),
            isAnnual: false,
            totalSpent: 0,
            lastPeriodSpent: 0,
            totalSaved: profile?.totalSaved ?? 0,
            savingsGoal: 1000,
            purchasesResisted: impulseLogs.filter(\.resisted).count,
            longestStreak: profile?.longestStreak ?? 0,
            currentStreak: profile?.currentStreak ?? 0,
            characterStage: stage,
            startStage: .seedling,
            level: CharacterStage.level(from: xp),
            personality: mp,
            categoryBreakdown: [],
            moodBreakdown: []
        )
    }

    @ViewBuilder
    private func destinationView(for sheet: ProfileSheet) -> some View {
        switch sheet {
        case .notifications:  NavigationStack { NotificationCenterView() }
        case .pgsi:           NavigationStack { PGSIAssessmentView() }
        case .vibe:           NavigationStack { VibeCheckAnalyticsView() }
        case .badges:         NavigationStack { BadgeGalleryView() }
        case .moneyWrapped:   NavigationStack { MoneyWrappedView(data: wrappedData) }
        case .settings:       NavigationStack { SettingsView() }
        case .health:         NavigationStack { SettingsView() }
        case .paywall:        PaywallView()
        case .help:           NavigationStack { SettingsView() }
        }
    }
}
