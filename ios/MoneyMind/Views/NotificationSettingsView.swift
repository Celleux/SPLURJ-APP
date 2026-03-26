import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Query private var profiles: [UserProfile]
    @Query private var patterns: [HighRiskPattern]
    @Query(filter: #Predicate<CoachInteraction> { $0.typeRaw == "curriculum" }, sort: \CoachInteraction.sessionNumber) private var sessions: [CoachInteraction]
    @State private var notifService = NotificationService.shared

    private var profile: UserProfile? { profiles.first }

    private var nextIncompleteSession: Int? {
        for i in 1...8 {
            if !sessions.contains(where: { $0.sessionNumber == i && $0.isCompleted }) { return i }
        }
        return nil
    }

    private var lastSessionCompletionDate: Date? {
        sessions.filter(\.isCompleted).compactMap(\.completedDate).max()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                masterToggleSection

                if profile?.notificationsEnabled == true {
                    groupToggle(
                        title: "Daily Reminders",
                        subtitle: "Pledge, reflection, check-in",
                        icon: "sun.max.fill",
                        iconColor: Theme.gold,
                        isOn: dailyRemindersBinding
                    )

                    groupToggle(
                        title: "Motivation",
                        subtitle: "Milestones, streaks, tips",
                        icon: "trophy.fill",
                        iconColor: Theme.accent,
                        isOn: motivationBinding
                    )

                    groupToggle(
                        title: "Smart & Budget",
                        subtitle: "Budget alerts, adaptive, digest",
                        icon: "brain.head.profile.fill",
                        iconColor: Theme.teal,
                        isOn: smartBudgetBinding
                    )

                    quietHoursSection
                    styleSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func reschedule() {
        guard let profile else { return }
        notifService.scheduleAllNotifications(
            profile: profile,
            patterns: Array(patterns),
            nextIncompleteSession: nextIncompleteSession,
            lastSessionCompletionDate: lastSessionCompletionDate
        )
    }

    // MARK: - Master Toggle

    private var masterToggleSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accentGreen.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "bell.badge.fill").font(Typography.headingLarge).foregroundStyle(Theme.accentGreen)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Notifications").font(Typography.headingMedium).foregroundStyle(Theme.textPrimary)
                Text(profile?.notificationsEnabled == true ? "All notifications active" : "Notifications are off")
                    .font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if let profile {
                Toggle("", isOn: Binding(
                    get: { profile.notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let granted = await notifService.requestPermission()
                                profile.notificationsEnabled = granted
                                if granted { reschedule() }
                            }
                        } else {
                            profile.notificationsEnabled = false
                        }
                    }
                ))
                .labelsHidden()
                .tint(Theme.accentGreen)
            }
        }
        .padding(16)
        .splurjCard(.elevated)
        .sensoryFeedback(.selection, trigger: profile?.notificationsEnabled)
    }

    // MARK: - Group Toggle

    private func groupToggle(title: String, subtitle: String, icon: String, iconColor: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(iconColor.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(Typography.bodyLarge).foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typography.headingSmall).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Theme.accentGreen)
        }
        .padding(16)
        .splurjCard(.elevated)
        .sensoryFeedback(.selection, trigger: isOn.wrappedValue)
    }

    // MARK: - Bindings

    private var dailyRemindersBinding: Binding<Bool> {
        Binding(
            get: {
                guard let p = profile else { return false }
                return p.morningPledgeNotif || p.eveningReflectionNotif || p.midDayIntentionNotif
            },
            set: { newValue in
                guard let p = profile else { return }
                p.morningPledgeNotif = newValue
                p.eveningReflectionNotif = newValue
                p.midDayIntentionNotif = newValue
                p.emaMorningNotif = newValue
                p.emaAfternoonNotif = newValue
                p.emaEveningNotif = newValue
                reschedule()
            }
        )
    }

    private var motivationBinding: Binding<Bool> {
        Binding(
            get: {
                guard let p = profile else { return false }
                return p.milestoneApproachingNotif || p.streakMaintenanceNotif || p.weeklyPaycheckNotif
            },
            set: { newValue in
                guard let p = profile else { return }
                p.milestoneApproachingNotif = newValue
                p.streakMaintenanceNotif = newValue
                p.weeklyPaycheckNotif = newValue
                p.curriculumReminderNotif = newValue
                reschedule()
            }
        )
    }

    private var smartBudgetBinding: Binding<Bool> {
        Binding(
            get: {
                guard let p = profile else { return false }
                return p.jitaiAdaptiveNotif || p.billRemindersEnabled || p.dailyCheckInNotif
            },
            set: { newValue in
                guard let p = profile else { return }
                p.jitaiAdaptiveNotif = newValue
                p.reEngagementNotif = newValue
                p.billRemindersEnabled = newValue
                p.budgetAlert50 = newValue
                p.budgetAlert80 = newValue
                p.budgetAlert100 = newValue
                p.dailyCheckInNotif = newValue
                p.weeklyDigestNotif = newValue
                reschedule()
            }
        )
    }

    // MARK: - Quiet Hours

    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill").font(Typography.bodyMedium).foregroundStyle(Color(red: 0.4, green: 0.5, blue: 0.9))
                Text("Quiet Hours").font(Typography.headingSmall).foregroundStyle(Theme.textPrimary)
            }

            if let profile {
                Toggle(isOn: Binding(
                    get: { profile.quietHoursEnabled },
                    set: { profile.quietHoursEnabled = $0; reschedule() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Quiet Hours").font(Typography.bodyMedium).foregroundStyle(Theme.textPrimary)
                        Text("No notifications \(profile.quietHoursStart > 12 ? "\(profile.quietHoursStart - 12)PM" : "\(profile.quietHoursStart)AM") – \(profile.quietHoursEnd > 12 ? "\(profile.quietHoursEnd - 12)PM" : "\(profile.quietHoursEnd)AM")")
                            .font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
                    }
                }
                .tint(Theme.accentGreen)
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    // MARK: - Style

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "text.bubble.fill").font(Typography.bodyMedium).foregroundStyle(Theme.accentGreen)
                Text("Notification Style").font(Typography.headingSmall).foregroundStyle(Theme.textPrimary)
            }

            if let profile {
                Picker("Style", selection: Binding(
                    get: { profile.notificationStyle },
                    set: { profile.notificationStyle = $0; reschedule() }
                )) {
                    Text("Supportive").tag("standard")
                    Text("Minimal").tag("minimal")
                }
                .pickerStyle(.segmented)

                Text(profile.notificationStyle == "minimal" ? "Brief, to-the-point messages" : "Longer, warmer messages with encouragement")
                    .font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }
}
