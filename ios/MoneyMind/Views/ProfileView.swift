import SwiftUI
import SwiftData
import PhosphorSwift

nonisolated enum ProfileSegment: String, CaseIterable, Identifiable, Sendable {
    case journey, stats, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .journey: "Journey"
        case .stats: "Stats"
        case .settings: "Settings"
        }
    }
    var icon: String {
        switch self {
        case .journey: "map.fill"
        case .stats: "chart.bar.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Query private var impulseLogs: [ImpulseLog]
    @Query(filter: #Predicate<DailyEntry> { $0.typeRaw == "checkIn" }) private var checkIns: [DailyEntry]
    @Query(sort: \PGSIAssessment.date) private var pgsiAssessments: [PGSIAssessment]
    @Query private var quizResults: [QuizResult]
    @Query(filter: #Predicate<Achievement> { $0.typeRaw == "badge" }) private var badges: [Achievement]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager

    @State private var showPGSI = false
    @State private var showWeeklySummary = false
    @State private var showMoneyWrapped = false
    @State private var showAnnualWrapped = false
    @State private var showPaywall = false
    @State private var showRetakeQuiz = false
    @State private var showShareCharacter = false
    @State private var segment: ProfileSegment = .journey
    @State private var sectionAppeared: [Bool] = Array(repeating: false, count: 7)

    private var profile: UserProfile? { profiles.first }

    private var dayCount: Int {
        guard let start = profile?.startDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
    }

    private var characterStage: CharacterStage {
        CharacterStage.from(xp: profile?.xpPoints ?? 0)
    }

    private var characterLevel: Int {
        CharacterStage.level(from: profile?.xpPoints ?? 0)
    }

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private var showRecoveryContent: Bool {
        let path = profile?.userPath ?? .generalSaver
        return path == .gambling || path == .impulseShopper
    }

    private var totalSaved: Double { profile?.totalSaved ?? 0 }
    private var bestStreak: Int { profile?.longestStreak ?? 0 }
    private var totalWins: Int { impulseLogs.filter(\.resisted).count }

    private var xpProgress: Double {
        let xp = profile?.xpPoints ?? 0
        let lvl = CharacterStage.level(from: xp)
        let cur = CharacterStage.xpForLevel(lvl)
        let nxt = CharacterStage.xpForNextLevel(lvl)
        let range = nxt - cur
        guard range > 0 else { return 1.0 }
        return Double(xp - cur) / Double(range)
    }

    private var currentXP: Int { profile?.xpPoints ?? 0 }
    private var nextLevelXP: Int { CharacterStage.xpForNextLevel(characterLevel) }
    private var earnedBadges: [Achievement] { badges.filter(\.isEarned) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeroCard
                        .sectionFadeIn(index: 0, appeared: $sectionAppeared)
                    segmentPicker
                        .sectionFadeIn(index: 1, appeared: $sectionAppeared)

                    switch segment {
                    case .journey:
                        journeySection
                            .sectionFadeIn(index: 2, appeared: $sectionAppeared)
                        shareCelebrateSection
                            .sectionFadeIn(index: 3, appeared: $sectionAppeared)
                    case .stats:
                        statsGrid
                            .sectionFadeIn(index: 2, appeared: $sectionAppeared)
                        if showRecoveryContent {
                            recoverySection
                                .sectionFadeIn(index: 3, appeared: $sectionAppeared)
                        }
                    case .settings:
                        premiumSection
                            .sectionFadeIn(index: 2, appeared: $sectionAppeared)
                        settingsLink
                            .sectionFadeIn(index: 3, appeared: $sectionAppeared)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: segment)
            }
            .background(
                ZStack {
                    Theme.background.ignoresSafeArea()
                    SplurjSwoosh()
                        .fill(Theme.accent.opacity(0.03))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                seedBadgesIfNeeded()
                staggerAppear()
            }
            .sheet(isPresented: $showPGSI) {
                PGSIAssessmentView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showWeeklySummary) {
                WeeklySummarySheet(
                    totalSaved: weekSaved,
                    purchasesResisted: weekResisted,
                    streak: profile?.currentStreak ?? 0,
                    characterStage: characterStage,
                    level: characterLevel
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showMoneyWrapped) {
                if hasMonthlyData {
                    MoneyWrappedView(data: buildMonthlyWrappedData())
                } else {
                    wrappedEmptyState
                }
            }
            .fullScreenCover(isPresented: $showAnnualWrapped) {
                MoneyWrappedView(data: buildAnnualWrappedData())
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showShareCharacter) {
                ShareCharacterCardView(
                    stage: characterStage,
                    level: characterLevel,
                    totalSaved: totalSaved,
                    streak: profile?.currentStreak ?? 0,
                    dayCount: dayCount
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 6) {
            ForEach(ProfileSegment.allCases) { option in
                let selected = option == segment
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        segment = option
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(option.title)
                            .font(Typography.labelMedium)
                    }
                    .foregroundStyle(selected ? Theme.buttonTextOnAccent : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selected {
                                Capsule().fill(Theme.accentGradient)
                            } else {
                                Capsule().fill(Color.clear)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: segment)
            }
        }
        .padding(4)
        .background(Theme.elevated, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 0.5))
    }

    // MARK: - Profile Hero Card

    private var profileHeroCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Text(profile?.name ?? "User")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)
                Text("\u{00B7}")
                    .foregroundStyle(Theme.textMuted)
                Text(personality.rawValue)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.accent)
                Text("\u{00B7}")
                    .foregroundStyle(Theme.textMuted)
                Text("Lv. \(characterLevel)")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.accent)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            HStack(spacing: 8) {
                ForEach(personality.traits, id: \.self) { trait in
                    Text(trait)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.1), in: .capsule)
                }
            }

            Button {
                showRetakeQuiz = true
            } label: {
                Text("Retake Quiz")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let startDate = profile?.startDate {
                Text("Member since \(startDate, format: .dateTime.month(.wide).year())")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .splurjCard(.hero)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            ProfileStatCard(
                value: "\(profile?.currentStreak ?? 0)",
                label: "Day Streak",
                icon: "flame.fill",
                color: Theme.accent
            )
            ProfileStatCard(
                value: profile?.totalSaved.formatted(.currency(code: profile?.defaultCurrency ?? "USD").precision(.fractionLength(0))) ?? "$0",
                label: "Total Saved",
                icon: "dollarsign.circle.fill",
                color: Theme.accent
            )
            ProfileStatCard(
                value: "\(impulseLogs.count)",
                label: "Wins Logged",
                icon: "star.fill",
                color: Theme.accent
            )
        }
    }

    // MARK: - My Journey

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(icon: "leaf.fill", title: "My Journey")

            characterLevelCard
            milestoneTimeline
            badgeCollectionPreview
            shareCharacterButton
        }
    }

    private var characterLevelCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(personality.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .shadow(color: personality.color.opacity(0.3), radius: 12)
                Image(systemName: characterStage.bodyIcon)
                    .font(Typography.displayMedium)
                    .foregroundStyle(characterStage.primaryColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(characterStage.name)
                    .font(Typography.headingLarge)
                    .foregroundStyle(.white)
                Text("Level \(characterLevel) \(personality.rawValue)")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(personality.color)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.elevated).frame(height: 8)
                        Capsule()
                            .fill(personality.color)
                            .frame(width: geo.size.width * xpProgress, height: 8)
                            .shadow(color: personality.color.opacity(0.5), radius: 4)
                    }
                }
                .frame(height: 8)

                Text("\(currentXP)/\(nextLevelXP) XP")
                    .font(Typography.moneySmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private var milestoneTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(icon: "flag.fill", title: "Milestones")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    MilestoneCard(icon: "star.fill", title: "First Save", subtitle: "Logged your first win", isCompleted: totalWins >= 1, accentColor: Theme.accent)
                    MilestoneCard(icon: "flame.fill", title: "7-Day Streak", subtitle: "Saved 7 days in a row", isCompleted: bestStreak >= 7, accentColor: .orange)
                    MilestoneCard(icon: "dollarsign.circle.fill", title: "$100 Club", subtitle: "Total savings hit $100", isCompleted: totalSaved >= 100, accentColor: Theme.accent)
                    MilestoneCard(icon: "trophy.fill", title: "$500 Saver", subtitle: "Total savings hit $500", isCompleted: totalSaved >= 500, accentColor: Theme.gold)
                    MilestoneCard(icon: "crown.fill", title: "$1,000 Legend", subtitle: "Total savings hit $1,000", isCompleted: totalSaved >= 1000, accentColor: Theme.gold)
                    MilestoneCard(icon: "bolt.fill", title: "30-Day Warrior", subtitle: "30-day streak achieved", isCompleted: bestStreak >= 30, accentColor: .purple)
                }
                .padding(.horizontal, 4)
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var badgeCollectionPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(destination: BadgeGalleryView()) {
                HStack {
                    Text("Badges")
                        .font(Typography.headingMedium)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(earnedBadges.count)/\(badges.count)")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                    PhIcon.caretRight
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(Array(badges.prefix(10)), id: \.name) { badge in
                    ZStack {
                        Circle()
                            .fill(badge.isEarned ? badgeColor(for: badge).opacity(0.15) : Theme.elevated)
                            .frame(width: 48, height: 48)
                            .shadow(color: badge.isEarned ? badgeColor(for: badge).opacity(0.3) : .clear, radius: 6)
                        Image(systemName: badge.iconName)
                            .font(Typography.bodyLarge)
                            .foregroundStyle(badge.isEarned ? badgeColor(for: badge) : Theme.textMuted.opacity(0.3))
                    }
                }
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private var shareCharacterButton: some View {
        Button {
            showShareCharacter = true
        } label: {
            HStack {
                PhIcon.shareFat
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Theme.accent)
                Text("Share My Character Card")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white)
                Spacer()
                PhIcon.caretRight
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(16)
            .background(Theme.elevated, in: .rect(cornerRadius: 12))
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showShareCharacter)
    }

    // MARK: - Share & Celebrate

    private var shareCelebrateSection: some View {
        SettingsSectionCard(title: "Share & Celebrate", icon: "sparkles", iconColor: Theme.accent) {
            SettingsNavRow(icon: "calendar", title: "Weekly Summary", subtitle: "Share your 7-day highlights", color: Theme.accent) {
                showWeeklySummary = true
            }
            SettingsDividerLine()
            SettingsNavRow(icon: "sparkles", title: "Monthly Recap", subtitle: "Your month in 6 story cards", color: Theme.accent, badge: "NEW") {
                showMoneyWrapped = true
            }
            SettingsDividerLine()
            SettingsNavRow(icon: "gift.fill", title: "Splurj Wrapped", subtitle: "Your all-time journey in cards", color: Theme.accent) {
                showAnnualWrapped = true
            }
        }
    }

    // MARK: - Recovery Progress

    private var recoverySection: some View {
        SettingsSectionCard(title: "Recovery Progress", icon: "chart.line.downtrend.xyaxis", iconColor: Theme.accent) {
            SettingsNavRow(icon: "chart.line.downtrend.xyaxis", title: "Recovery Progress", subtitle: "PGSI assessments & trends", color: Theme.accent) {
                showPGSI = true
            }

            if !pgsiAssessments.isEmpty {
                PGSITrendChart(assessments: pgsiAssessments)
                    .padding(.top, 8)
            }

            pgsiPromptCard
        }
    }

    // MARK: - Premium

    private var premiumSection: some View {
        SettingsSectionCard(title: "Premium", icon: "crown.fill", iconColor: Theme.gold) {
            HStack(spacing: 14) {
                SettingsIconBadge(icon: "crown.fill", color: Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Text(premiumStatusText)
                        .font(Typography.labelSmall)
                        .foregroundStyle(premiumStatusColor)
                }
                Spacer()
                if premiumManager.isPremium {
                    Text("PRO")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.buttonTextOnAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.goldGradient, in: .capsule)
                } else if premiumManager.isInTrial {
                    Text("TRIAL")
                        .font(Typography.labelSmall)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent, in: .capsule)
                }
            }

            if !premiumManager.hasFullAccess {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text("Upgrade to Premium")
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(Typography.labelSmall)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .medium))
            }
        }
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundStyle(Theme.textSecondary)
                Text("Settings")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(16)
            .background(Theme.elevated, in: .rect(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private var premiumStatusText: String {
        if premiumManager.isPremium { return "Premium Active" }
        if premiumManager.isInTrial {
            let days = premiumManager.trialDaysRemaining
            return "3-Day Trial \u{2022} \(days) day\(days == 1 ? "" : "s") left"
        }
        return "Free Plan"
    }

    private var premiumStatusColor: Color {
        (premiumManager.isPremium || premiumManager.isInTrial) ? Theme.accent : Theme.textSecondary
    }

    private var pgsiPromptCard: some View {
        Group {
            let showPrompt: Bool = {
                guard showRecoveryContent else { return false }
                let day = Calendar.current.component(.day, from: Date())
                guard day <= 7 else { return false }
                let thisMonth = Calendar.current.startOfDay(for: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!)
                return !pgsiAssessments.contains { $0.date >= thisMonth }
            }()

            if showPrompt {
                Button {
                    showPGSI = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly Check-In")
                                .font(Typography.headingSmall)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Track your recovery progress")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("Optional")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accent.opacity(0.1), in: .capsule)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    private func badgeColor(for badge: Achievement) -> Color {
        switch badge.category {
        case "Money": Theme.accentGreen
        case "Streak": .orange
        case "Skill": Theme.teal
        default: Theme.textSecondary
        }
    }

    private func seedBadgesIfNeeded() {
        guard badges.isEmpty else { return }
        for info in BadgeDefinition.all {
            let badge = Achievement.badge(name: info.name, category: info.category, badgeDescription: info.description, iconName: info.icon)
            modelContext.insert(badge)
        }
    }

    private func staggerAppear() {
        for i in sectionAppeared.indices {
            sectionAppeared[i] = true
        }
    }

    // MARK: - Wrapped Data

    private var hasMonthlyData: Bool {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return transactions.contains { $0.date >= monthAgo } || impulseLogs.contains { $0.date >= monthAgo }
    }

    private var wrappedEmptyState: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { showMoneyWrapped = false } label: {
                        Image(systemName: "xmark")
                            .font(Typography.headingMedium)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                PersonalityEmptyStateView(
                    personality: personality,
                    icon: "calendar.badge.clock",
                    secondaryIcon: "sparkles",
                    headline: "Your First Wrapped Is Coming",
                    subtext: "Keep tracking your spending this month\nand we'll create your story"
                )
            }
        }
    }

    private var weekSaved: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return impulseLogs.filter { $0.resisted && $0.date >= weekAgo }.reduce(0) { $0 + $1.amount }
    }

    private var weekResisted: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return impulseLogs.filter { $0.resisted && $0.date >= weekAgo }.count
    }

    private func buildMonthlyWrappedData() -> WrappedData {
        let cal = Calendar.current
        let monthAgo = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        let monthTx = transactions.filter { $0.transactionType == .expense && $0.date >= monthAgo }
        let lastMonthTx = transactions.filter { $0.transactionType == .expense && $0.date >= twoMonthsAgo && $0.date < monthAgo }
        let monthSpent = monthTx.reduce(0) { $0 + $1.amount }
        let lastMonthSpent = lastMonthTx.reduce(0) { $0 + $1.amount }
        let monthSaved = impulseLogs.filter { $0.resisted && $0.date >= monthAgo }.reduce(0) { $0 + $1.amount }
        let monthResisted = impulseLogs.filter { $0.resisted && $0.date >= monthAgo }.count
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return WrappedData(
            periodLabel: formatter.string(from: Date()),
            isAnnual: false,
            totalSpent: monthSpent,
            lastPeriodSpent: lastMonthSpent,
            totalSaved: monthSaved,
            savingsGoal: 1000,
            purchasesResisted: monthResisted,
            longestStreak: profile?.longestStreak ?? 0,
            currentStreak: profile?.currentStreak ?? 0,
            characterStage: characterStage,
            startStage: .seedling,
            level: characterLevel,
            personality: personality,
            categoryBreakdown: buildCategoryBreakdown(from: monthTx),
            moodBreakdown: buildMoodBreakdown(from: monthTx)
        )
    }

    private func buildAnnualWrappedData() -> WrappedData {
        let expenseTx = transactions.filter { $0.transactionType == .expense }
        return WrappedData(
            periodLabel: String(Calendar.current.component(.year, from: Date())),
            isAnnual: true,
            totalSpent: expenseTx.reduce(0) { $0 + $1.amount },
            lastPeriodSpent: 0,
            totalSaved: profile?.totalSaved ?? 0,
            savingsGoal: 5000,
            purchasesResisted: impulseLogs.filter(\.resisted).count,
            longestStreak: profile?.longestStreak ?? 0,
            currentStreak: profile?.currentStreak ?? 0,
            characterStage: characterStage,
            startStage: .seedling,
            level: characterLevel,
            personality: personality,
            categoryBreakdown: buildCategoryBreakdown(from: expenseTx),
            moodBreakdown: buildMoodBreakdown(from: expenseTx)
        )
    }

    private func buildCategoryBreakdown(from txs: [Transaction]) -> [(category: String, amount: Double, color: String)] {
        var amounts: [String: Double] = [:]
        var colors: [String: String] = [:]
        for tx in txs {
            let cat = tx.transactionCategory
            amounts[cat.rawValue, default: 0] += tx.amount
            colors[cat.rawValue] = cat.color
        }
        return amounts.sorted { $0.value > $1.value }.map { (category: $0.key, amount: $0.value, color: colors[$0.key] ?? "6C5CE7") }
    }

    private func buildMoodBreakdown(from txs: [Transaction]) -> [(emoji: String, count: Int)] {
        var counts: [String: Int] = [:]
        for tx in txs where !tx.moodEmoji.isEmpty {
            counts[tx.moodEmoji, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.map { (emoji: $0.key, count: $0.value) }
    }
}

// MARK: - Profile Stat Card

private struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(Typography.headingLarge)
                .foregroundStyle(color)
            Text(value)
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .splurjCard(.outlined)
    }
}

// MARK: - Stagger Animation Modifier

private struct SectionFadeInModifier: ViewModifier {
    let index: Int
    @Binding var appeared: [Bool]

    private var isVisible: Bool {
        index < appeared.count && appeared[index]
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.08), value: isVisible)
    }
}

extension View {
    fileprivate func sectionFadeIn(index: Int, appeared: Binding<[Bool]>) -> some View {
        modifier(SectionFadeInModifier(index: index, appeared: appeared))
    }
}

struct ProfileSettingsRowLabel: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color, in: .rect(cornerRadius: 8))
            Text(title)
                .font(Typography.bodyLarge)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.cardSurface)
    }
}
