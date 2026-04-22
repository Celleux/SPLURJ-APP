import Foundation
import UserNotifications
import SwiftData

@Observable
class NotificationService {
    static let shared = NotificationService()

    var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()
    private let maxDailyNotifications = 3
    private var scheduledTodayCount = 0
    private var lastCountResetDate: Date?

    private init() {
        Task { await checkAuthorizationStatus() }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule All

    func scheduleAllNotifications(profile: UserProfile, patterns: [HighRiskPattern] = [], nextIncompleteSession: Int? = nil, lastSessionCompletionDate: Date? = nil) {
        guard profile.notificationsEnabled else {
            center.removeAllPendingNotificationRequests()
            return
        }

        center.removeAllPendingNotificationRequests()
        resetDailyCountIfNeeded()

        let isSupportive = profile.notificationStyle != "minimal"

        if profile.morningPledgeNotif {
            // Splurj Copy Pack voice: lowercase, first-person, friend-of-mine tone.
            let msg = isSupportive
                ? PushCopy.randomMessage(for: .morning)
                : PushMessage(title: "Daily Pledge",
                              body: "Time for your daily pledge.")
            scheduleDailyNotification(id: "morning_pledge", hour: profile.dailyPledgeTime, minute: 0,
                title: msg.title, body: msg.body, profile: profile)
        }

        if profile.eveningReflectionNotif {
            scheduleDailyNotification(id: "evening_reflection", hour: profile.eveningReflectionTime, minute: 0,
                title: isSupportive ? "Evening Check-In" : "Reflection Time",
                body: isSupportive ? "How was your day? Take a moment to reflect on your journey." : "Time for your evening reflection.",
                profile: profile)
        }

        if profile.midDayIntentionNotif {
            scheduleDailyNotification(id: "midday_intention", hour: profile.midDayIntentionTime, minute: 0,
                title: isSupportive ? "Spending Intention" : "Intention Check",
                body: isSupportive ? "Any spending planned? Set your intention and stay mindful." : "Set your spending intention.",
                profile: profile)
        }

        if profile.streakMaintenanceNotif && profile.currentStreak > 0 {
            // Streak-risk evening nudges now pull from PushCopy §01 §streakRisk.
            let msg = isSupportive
                ? PushCopy.randomMessage(for: .streakRisk)
                : PushMessage(title: "Streak",
                              body: "\(profile.currentStreak)-day streak active.")
            scheduleDailyNotification(id: "streak_maintenance", hour: 21, minute: 45,
                title: msg.title, body: msg.body, profile: profile)
        }

        if profile.milestoneApproachingNotif {
            scheduleMilestoneApproaching(profile: profile, isSupportive: isSupportive)
        }

        if profile.weeklyPaycheckNotif {
            scheduleWeeklyNotification(id: "weekly_paycheck", weekday: 1, hour: 10,
                title: isSupportive ? "Your Weekly Paycheck" : "Weekly Summary",
                body: isSupportive ? "Great week! You stayed mindful and saved real money." : "Great week of mindful choices!",
                profile: profile)
        }

        if profile.weeklyDigestNotif {
            scheduleWeeklyNotification(id: "weekly_digest", weekday: 1, hour: 9,
                title: isSupportive ? "Your Weekly Digest" : "Weekly Digest",
                body: isSupportive ? "Your weekly spending summary is ready. See how you did!" : "Weekly summary available.",
                profile: profile)
        }

        if profile.dailyCheckInNotif {
            scheduleDailyNotification(id: "daily_checkin", hour: 20, minute: 0,
                title: isSupportive ? "How Was Your Spending Today?" : "Daily Check-In",
                body: isSupportive ? "Take a moment to reflect. Every conscious choice counts." : "Rate your spending day.",
                profile: profile)
        }

        if profile.jitaiAdaptiveNotif {
            scheduleJITAI(patterns: patterns, profile: profile, isSupportive: isSupportive)
        }

        if profile.reEngagementNotif {
            scheduleReEngagement(profile: profile, isSupportive: isSupportive)
        }
    }

    // MARK: - Budget Threshold Alerts

    func checkBudgetThresholds(budgets: [BudgetCategory], transactions: [Transaction], profile: UserProfile, modelContext: ModelContext) {
        guard profile.notificationsEnabled else { return }
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!

        for budget in budgets {
            let spent = transactions
                .filter { $0.transactionType == .expense && $0.category == budget.name && $0.date >= startOfMonth }
                .reduce(0.0) { $0 + $1.amount }
            guard budget.monthlyLimit > 0 else { continue }
            let pct = spent / budget.monthlyLimit

            if pct >= 1.0 && profile.budgetAlert100 {
                createInAppNotification(type: .budgetExceeded, title: "Over Budget", body: "Over budget on \(budget.name) by $\(Int(spent - budget.monthlyLimit)).", deepLink: .budgetAnalytics, modelContext: modelContext)
            } else if pct >= 0.8 && profile.budgetAlert80 {
                createInAppNotification(type: .budgetCritical, title: "Heads Up", body: "\(budget.name) budget at \(Int(pct * 100))%.", deepLink: .budgetAnalytics, modelContext: modelContext)
            } else if pct >= 0.5 && profile.budgetAlert50 {
                createInAppNotification(type: .budgetWarning, title: "Budget Update", body: "Halfway through your \(budget.name) budget.", deepLink: .budgetAnalytics, modelContext: modelContext)
            }
        }
    }

    // MARK: - Celebrations

    func celebrateSavings(amount: Double, profile: UserProfile, modelContext: ModelContext) {
        guard profile.notificationsEnabled else { return }
        let formatted = amount.formatted(.currency(code: profile.defaultCurrency).precision(.fractionLength(0)))
        // New voice — lowercase, specific numbers, first-person
        createInAppNotification(
            type: .savingsCelebration,
            title: "\(formatted) deflected. proud.",
            body: "that\u{2019}s a real day 1. i felt it.",
            deepLink: .wallet,
            modelContext: modelContext
        )
    }

    func celebrateStreak(days: Int, profile: UserProfile, modelContext: ModelContext) {
        guard profile.notificationsEnabled else { return }
        let milestones = [3, 7, 10, 14, 21, 30, 60, 90, 100, 180, 365]
        guard milestones.contains(days) else { return }
        // Pull a celebration-bucket push from the Copy Pack; substitute the
        // day count into the title when the message template uses it.
        let template = PushCopy.celebration.first ?? PushMessage(
            title: "streak \(days). \u{1F525}",
            body: "unmistakably bigger. keep going."
        )
        createInAppNotification(
            type: .streakCelebration,
            title: "\(days) days. \u{1F525}",
            body: template.body,
            deepLink: .home,
            modelContext: modelContext
        )
    }

    /// New-voice level-up push fired by the EvolutionCeremony.
    func celebrateLevelup(level: Int, profile: UserProfile, modelContext: ModelContext) {
        guard profile.notificationsEnabled else { return }
        createInAppNotification(
            type: .streakCelebration,
            title: "level \(level) \u{2728}",
            body: "i\u{2019}m taller. look what we did.",
            deepLink: .home,
            modelContext: modelContext
        )
    }

    func sendJITAINudge(dayName: String, profile: UserProfile, modelContext: ModelContext) {
        guard profile.notificationsEnabled && profile.jitaiAdaptiveNotif else { return }
        createInAppNotification(type: .jitaiNudge, title: "Heads Up", body: "It's \(dayName) — your spending tends to increase. Plan ahead.", deepLink: .budgetAnalytics, modelContext: modelContext)
    }

    func generateWeeklyDigest(transactions: [Transaction], profile: UserProfile, modelContext: ModelContext) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let spent = transactions.filter { $0.transactionType == .expense && $0.date >= weekAgo }.reduce(0.0) { $0 + $1.amount }
        let formatted = spent.formatted(.currency(code: profile.defaultCurrency).precision(.fractionLength(0)))
        createInAppNotification(type: .weeklyDigest, title: "Weekly Digest", body: "Last week: spent \(formatted).", deepLink: .budgetAnalytics, modelContext: modelContext)
    }

    // MARK: - In-App

    func createInAppNotification(type: NotificationType, title: String, body: String, deepLink: NotificationDeepLink = .none, modelContext: ModelContext) {
        let notification = InAppNotification(type: type, title: title, body: body, deepLink: deepLink)
        modelContext.insert(notification)
    }

    // MARK: - Private Scheduling

    private func scheduleDailyNotification(id: String, hour: Int, minute: Int, title: String, body: String, profile: UserProfile) {
        guard !isInQuietHours(hour: hour, minute: minute, profile: profile) else { return }
        var dc = DateComponents()
        dc.hour = hour; dc.minute = minute
        let content = makeContent(title: title, body: body)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)))
    }

    private func scheduleWeeklyNotification(id: String, weekday: Int, hour: Int, title: String, body: String, profile: UserProfile) {
        guard !isInQuietHours(hour: hour, minute: 0, profile: profile) else { return }
        var dc = DateComponents()
        dc.weekday = weekday; dc.hour = hour; dc.minute = 0
        let content = makeContent(title: title, body: body)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)))
    }

    private func scheduleMilestoneApproaching(profile: UserProfile, isSupportive: Bool) {
        let milestones: [Double] = [100, 500, 1_000, 5_000, 10_000, 25_000, 50_000, 100_000]
        guard let next = milestones.first(where: { $0 > profile.totalSaved }) else { return }
        let remaining = next - profile.totalSaved
        guard remaining <= 50 && remaining > 0 else { return }
        let formatted = next.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        let content = makeContent(title: isSupportive ? "Almost There!" : "Milestone", body: "You're close to \(formatted)!")
        center.add(UNNotificationRequest(identifier: "milestone_approaching", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)))
    }

    private func scheduleJITAI(patterns: [HighRiskPattern], profile: UserProfile, isSupportive: Bool) {
        for (i, pattern) in patterns.sorted(by: { $0.frequency > $1.frequency }).prefix(3).enumerated() {
            let hour = pattern.hourOfDay > 0 ? pattern.hourOfDay - 1 : 23
            guard !isInQuietHours(hour: hour, minute: 45, profile: profile) else { continue }
            var dc = DateComponents()
            dc.weekday = pattern.dayOfWeek; dc.hour = hour; dc.minute = 45
            let dayName = Calendar.current.weekdaySymbols[max(0, min(6, pattern.dayOfWeek - 1))]
            let content = makeContent(title: "Heads Up", body: isSupportive ? "It's \(dayName) evening — spending tends to increase." : "\(dayName) pattern detected.")
            center.add(UNNotificationRequest(identifier: "jitai_\(i)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)))
        }
    }

    private func scheduleReEngagement(profile: UserProfile, isSupportive: Bool) {
        let campaigns: [(days: Int, title: String, body: String)] = [
            (3, "We Miss You", isSupportive ? "Your character misses you. Come back!" : "Waiting for you."),
            (7, "So Close", isSupportive ? "You're close to your next milestone!" : "Milestone approaching."),
            (21, "Fresh Start", isSupportive ? "Day 1 is the bravest day." : "Ready for Day 1?")
        ]
        for campaign in campaigns {
            guard let fireDate = Calendar.current.date(byAdding: .day, value: campaign.days, to: Date()) else { continue }
            var dc = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
            dc.hour = 10; dc.minute = 0
            guard !isInQuietHours(hour: 10, minute: 0, profile: profile) else { continue }
            let content = makeContent(title: campaign.title, body: campaign.body)
            center.add(UNNotificationRequest(identifier: "reengagement_day\(campaign.days)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)))
        }
    }

    // MARK: - Helpers

    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body; c.sound = .default
        return c
    }

    private func resetDailyCountIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if lastCountResetDate != today { scheduledTodayCount = 0; lastCountResetDate = today }
    }

    private func isInQuietHours(hour: Int, minute: Int, profile: UserProfile) -> Bool {
        guard profile.quietHoursEnabled else { return false }
        let t = hour * 60 + minute
        let s = profile.quietHoursStart * 60
        let e = profile.quietHoursEnd * 60
        return s <= e ? (t >= s && t < e) : (t >= s || t < e)
    }
}
