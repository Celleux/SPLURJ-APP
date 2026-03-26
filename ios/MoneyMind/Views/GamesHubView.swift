import SwiftUI
import SwiftData
import PhosphorSwift

struct GamesHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var scratchCards: [ScratchCard]
    @Query(filter: #Predicate<Achievement> { $0.typeRaw == "card" }) private var cardCollection: [Achievement]
    @Query private var playerProfiles: [PlayerProfile]
    @Query private var gachaStates: [GachaState]
    @Query(filter: #Predicate<DailyQuestSlot> { $0.cadence == "daily" },
           sort: \DailyQuestSlot.offeredDate, order: .reverse)
    private var allDailySlots: [DailyQuestSlot]
    @Query private var weeklyChallenges: [WeeklyChallenge]

    @State private var tickerOffset: CGFloat = 0
    @State private var showQuickComplete: Bool = false
    @State private var selectedQuickQuestID: String?
    @State private var showRewardCelebration: Bool = false
    @State private var lastReward: QuestReward?
    @State private var animateStats: Bool = false
    @State private var meshPhase: Double = 0
    @State private var navigateToVault: Bool = false
    @State private var navigationPath = NavigationPath()
    @State private var cachedCompletedDailyCount: Int = 0
    @State private var cachedCurrentWeeklyChallenge: WeeklyChallenge?
    @State private var cachedPendingQuestCount: Int = 0
    @State private var completedQuestIDs: Set<String> = []
    @State private var isTabVisible: Bool = true
    @State private var cachedPlayer: PlayerProfile?

    private var player: PlayerProfile {
        cachedPlayer ?? playerProfiles.first ?? PlayerProfile()
    }
    private var pendingCards: Int { scratchCards.filter { !$0.isScratched }.count }
    private var essence: Int { gachaStates.first?.totalEssence ?? 0 }

    private var todaysSlots: [DailyQuestSlot] {
        let today = Calendar.current.startOfDay(for: Date())
        return allDailySlots.filter { $0.offeredDate >= today }
    }

    private var todaysQuests: [(slot: DailyQuestSlot, quest: QuestDefinition)] {
        todaysSlots.compactMap { slot in
            guard let quest = QuestDatabase.quest(byID: slot.questID) else { return nil }
            return (slot, quest)
        }
    }

    private var completedDailyCount: Int { cachedCompletedDailyCount }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    playerCommandBar
                        .staggerIn(index: 0)
                    liveTicker
                        .staggerIn(index: 1)
                    todaysMissions
                        .staggerIn(index: 2)
                    gameCards
                        .staggerIn(index: 3)
                    weeklyChallengeBanner
                        .staggerIn(index: 4)
                    unifiedProgressSection
                        .staggerIn(index: 5)
                    compactLeaderboard
                        .staggerIn(index: 6)
                    statsDashboard
                        .staggerIn(index: 7)
                }
                .padding(.bottom, 32)
            }
            .background(
                ZStack {
                    Theme.background.ignoresSafeArea()
                    SplurjSwoosh()
                        .fill(Theme.accent.opacity(0.02))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    if !reduceMotion && isTabVisible {
                        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            MeshGradient(
                                width: 3, height: 3,
                                points: [
                                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                                    [Float(0.0 + sin(t * 0.3) * 0.05), 0.5],
                                    [Float(0.5 + cos(t * 0.2) * 0.05), Float(0.5 + sin(t * 0.25) * 0.05)],
                                    [Float(1.0 + sin(t * 0.35) * 0.05), 0.5],
                                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                                ],
                                colors: [
                                    .clear, .clear, .clear,
                                    Theme.accent.opacity(0.03), .clear, Theme.neonGold.opacity(0.02),
                                    .clear, Theme.accent.opacity(0.02), .clear
                                ]
                            )
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                        }
                    } else if !reduceMotion {
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.02), .clear, Theme.neonGold.opacity(0.01)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    }
                }
            )
            .navigationTitle("Games")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                isTabVisible = true
                ensurePlayer()
                ensurePlayerAndQuests()
                refreshCachedData()
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animateStats = true
                }
            }
            .onDisappear {
                isTabVisible = false
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "vault" {
                    VaultGameView()
                }
            }
            .fullScreenCover(isPresented: $showRewardCelebration) {
                if let reward = lastReward {
                    QuestRewardCelebration(reward: reward) {
                        showRewardCelebration = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            navigationPath.append("vault")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Player Command Bar

    private var playerCommandBar: some View {
        HStack(spacing: 14) {
            RiveMascotView(mood: player.questStreak > 0 ? .happy : .idle, size: .small)

            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Theme.accent, Theme.neonGold, Theme.accent],
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: avatarIcon(stage: player.avatarStage))
                    .font(Typography.headingLarge)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.accent, Theme.neonGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .background(Theme.elevated)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Lv.\(player.level)")
                        .font(Typography.moneySmall)
                        .foregroundStyle(.white)

                    Text(player.activeTitle)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.elevated)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.accentGradient)
                            .frame(width: geo.size.width * player.xpProgressFraction, height: 8)

                        Text("\(player.xpProgressInCurrentLevel)/\(player.xpForCurrentLevel)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 8)
            }

            Spacer(minLength: 4)

            HStack(spacing: 12) {
                if player.questStreak > 0 {
                    HStack(spacing: 3) {
                        PhIcon.fireFill
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Theme.axisRisk)
                        Text("\(player.questStreak)")
                            .font(Typography.labelMedium)
                            .foregroundStyle(.white)
                    }
                }

                HStack(spacing: 3) {
                    PhIcon.diamondFill
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Theme.neonPurple)
                    Text("\(essence)")
                        .font(Typography.labelMedium)
                        .foregroundStyle(.white)
                }

                PhIcon.trophyFill
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Theme.neonGold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.6), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.glassBorder, lineWidth: 0.5)
        )
        .background(
            AmbientLightView(goldOpacity: 0.05, tealOpacity: 0.03) { Color.clear }
                .allowsHitTesting(false)
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(player.level), \(player.xpProgressInCurrentLevel) of \(player.xpForCurrentLevel) XP, \(player.questStreak) day streak, \(essence) essence")
    }

    // MARK: - Live Ticker

    private var liveTicker: some View {
        let events = tickerEvents()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                    HStack(spacing: 6) {
                        Text(event.icon)
                            .font(Typography.bodySmall)
                        Text(event.text)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .contentMargins(.horizontal, 0)
        .frame(height: 28)
    }

    // MARK: - Today's Missions

    private var todaysMissions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(icon: "target", title: "Today's Missions")
                Spacer()
                Text("\(completedDailyCount)/\(todaysQuests.count) done")
                    .font(Typography.labelSmall)
                    .foregroundStyle(completedDailyCount == todaysQuests.count ? Theme.accent : Theme.textMuted)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(todaysQuests, id: \.quest.id) { item in
                        let isComplete = completedQuestIDs.contains(item.quest.id)

                        CompactMissionCard(
                            quest: item.quest,
                            isLucky: item.slot.isLuckyQuest,
                            isComplete: isComplete,
                            onTap: {
                                if !isComplete {
                                    selectedQuickQuestID = item.quest.id
                                    showQuickComplete = true
                                }
                            }
                        )
                    }

                    if todaysQuests.isEmpty {
                        VStack(spacing: 8) {
                            PhIcon.sealCheckFill
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Theme.accent)
                            Text("Quests loading...")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .frame(width: 140, height: 120)
                        .splurjCard(.subtle)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, 20)
        }
        .sheet(isPresented: $showQuickComplete) {
            if let questID = selectedQuickQuestID,
               let quest = QuestDataManager.shared.quest(byID: questID) {
                QuickMissionSheet(quest: quest) {
                    completeQuest(questID)
                    showQuickComplete = false
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Game Cards

    private var gameCards: some View {
        VStack(spacing: 12) {
            SectionHeader(icon: "gamecontroller.fill", title: "Your Games")
                .padding(.horizontal, 20)

            NavigationLink(destination: QuestHubView()) {
                Parallax3DCard(maxRotation: 8, glowColor: Theme.accent, interactive: false) {
                    ArcadeGameCard(
                        icon: "map.fill",
                        title: "QUESTS",
                        subtitle: "Real-World Missions",
                        accentColor: Theme.accent,
                        badgeCount: cachedPendingQuestCount,
                        statLabel: "Boss: \(player.currentQuestZone.bossName)",
                        statProgress: bossProgressFraction
                    )
                }
                .neonGlow(color: Theme.accent, radius: 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            NavigationLink(destination: VaultGameView()) {
                Parallax3DCard(maxRotation: 8, glowColor: Theme.neonPurple, interactive: false) {
                    ArcadeGameCard(
                        icon: "sparkles.rectangle.stack",
                        title: "THE VAULT",
                        subtitle: "Scratch & Collect",
                        accentColor: Theme.neonPurple,
                        badgeCount: pendingCards,
                        statLabel: "Collection: \(cardCollection.count)/\(CardDatabase.totalCards)",
                        statProgress: CardDatabase.totalCards > 0 ? Double(cardCollection.count) / Double(CardDatabase.totalCards) : 0
                    )
                }
                .neonGlow(color: Theme.neonPurple, radius: 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Weekly Challenge Banner

    @ViewBuilder
    private var weeklyChallengeBanner: some View {
        if let challenge = cachedCurrentWeeklyChallenge {
            VStack(spacing: 10) {
                SectionHeader(icon: "trophy.fill", title: "Weekly Challenge")

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        PhIcon.trophyFill
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Theme.neonGold)

                        Text(challenge.title)
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white)

                        Spacer()

                        Text(challenge.timeRemaining)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }

                    Text(challenge.challengeDescription)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 12) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Theme.elevated)
                                    .frame(height: 10)

                                RoundedRectangle(cornerRadius: 5)
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.neonGold, Theme.neonGold.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * challenge.progressFraction, height: 10)
                            }
                        }
                        .frame(height: 10)

                        Text("\(challenge.current)/\(challenge.target)")
                            .font(Typography.moneySmall)
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: challenge.rewardIcon)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.neonGold)
                        Text("Reward: \(challenge.rewardLabel)")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.neonGold)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Theme.neonGold.opacity(0.3), Theme.neonGold.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: Theme.neonGold.opacity(0.08), radius: 12, y: 4)
                )
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Unified Progress

    private var unifiedProgressSection: some View {
        VStack(spacing: 10) {
            SectionHeader(icon: "chart.bar.fill", title: "Parallel Progress")
                .padding(.horizontal, 20)

            HStack(spacing: 20) {
                UnifiedProgressRing(
                    dailyProgress: dailyProgressFraction,
                    weeklyProgress: weeklyProgressFraction,
                    bossProgress: bossProgressFraction,
                    level: player.level
                )

                VStack(alignment: .leading, spacing: 8) {
                    progressRow(
                        color: Theme.accent,
                        label: "Daily Quests",
                        value: "\(completedDailyCount)/\(todaysQuests.count)"
                    )
                    progressRow(
                        color: Theme.neonGold,
                        label: "Weekly Challenge",
                        value: weeklyProgressText
                    )
                    progressRow(
                        color: Theme.neonRed,
                        label: "Boss Damage",
                        value: "\(Int(bossProgressFraction * 100))%"
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.surface, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.glassBorder, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
        }
    }

    private func progressRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Typography.labelMedium)
                .foregroundStyle(.white)
        }
    }

    private var dailyProgressFraction: Double {
        guard !todaysQuests.isEmpty else { return 0 }
        return Double(completedDailyCount) / Double(todaysQuests.count)
    }

    private var weeklyProgressFraction: Double {
        guard let challenge = cachedCurrentWeeklyChallenge else { return 0 }
        return challenge.progressFraction
    }

    private var weeklyProgressText: String {
        guard let challenge = cachedCurrentWeeklyChallenge else { return "--" }
        return "\(challenge.current)/\(challenge.target)"
    }

    // MARK: - Compact Leaderboard

    private var compactLeaderboard: some View {
        VStack(spacing: 10) {
            SectionHeader(icon: "list.number", title: "Leaderboard")
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(mockLeaderboard.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Text("\(entry.rank)")
                            .font(Typography.moneySmall)
                            .foregroundStyle(entry.rank <= 3 ? Theme.neonGold : Theme.textMuted)
                            .frame(width: 24, alignment: .center)

                        ZStack {
                            Circle()
                                .fill(entry.isCurrentUser ? Theme.accent.opacity(0.15) : Theme.elevated)
                                .frame(width: 32, height: 32)
                            Image(systemName: entry.icon)
                                .font(Typography.headingSmall)
                                .foregroundStyle(entry.isCurrentUser ? Theme.accent : Theme.textSecondary)
                        }

                        Text(entry.name)
                            .font(Typography.headingSmall)
                            .foregroundStyle(entry.isCurrentUser ? Theme.accent : .white)
                            .lineLimit(1)

                        Spacer()

                        Text(entry.score)
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(entry.isCurrentUser ? Theme.accent.opacity(0.06) : .clear)

                    if index < mockLeaderboard.count - 1 {
                        Rectangle().fill(Theme.divider).frame(height: 0.5).padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(Theme.surface.opacity(0.5), in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            .padding(.horizontal, 16)
        }
    }

    private var mockLeaderboard: [CompactLeaderEntry] {
        let userName = "You"
        let userSaved = player.totalMoneySaved
        return [
            CompactLeaderEntry(rank: 1, name: "Sarah K.", icon: "person.fill", score: "$1.2k", isCurrentUser: false),
            CompactLeaderEntry(rank: 2, name: "Alex R.", icon: "bolt.fill", score: "$980", isCurrentUser: false),
            CompactLeaderEntry(rank: 3, name: "Jordan P.", icon: "star.fill", score: "$870", isCurrentUser: false),
            CompactLeaderEntry(rank: 4, name: userName, icon: "shield.fill", score: formatCurrency(max(userSaved * 0.3, 50)), isCurrentUser: true),
            CompactLeaderEntry(rank: 5, name: "Taylor S.", icon: "flame.fill", score: "$420", isCurrentUser: false),
        ]
    }

    // MARK: - Stats Dashboard

    private var statsDashboard: some View {
        VStack(spacing: 10) {
            SectionHeader(icon: "chart.xyaxis.line", title: "Lifetime Stats")
                .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ArcadeStatCard(
                    icon: "dollarsign.circle.fill",
                    value: animateStats ? formatCurrency(player.totalMoneySaved) : "$0",
                    label: "Total Saved",
                    color: Theme.accent
                )
                ArcadeStatCard(
                    icon: "checkmark.seal.fill",
                    value: animateStats ? "\(player.totalQuestsCompleted)" : "0",
                    label: "Quests Done",
                    color: Theme.neonBlue
                )
                ArcadeStatCard(
                    icon: "rectangle.stack.fill",
                    value: animateStats ? "\(cardCollection.count)/\(CardDatabase.totalCards)" : "0",
                    label: "Cards Found",
                    color: Theme.neonPurple
                )
                ArcadeStatCard(
                    icon: "flame.fill",
                    value: animateStats ? "\(player.questStreak) days" : "0",
                    label: "Current Streak",
                    color: Theme.axisRisk
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private var bossProgressFraction: Double {
        let zone = player.currentQuestZone
        guard zone.bossHP > 0 else { return 0 }
        return min(1.0, Double(player.currentBossDamageDealt) / Double(zone.bossHP))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Typography.labelSmall)
            .foregroundStyle(Theme.textMuted)
            .tracking(2)
    }

    private func avatarIcon(stage: Int) -> String {
        switch stage {
        case 0: return "shield.fill"
        case 1: return "bolt.shield.fill"
        case 2: return "building.columns.fill"
        case 3: return "crown.fill"
        default: return "star.fill"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func tickerEvents() -> [(icon: String, text: String)] {
        var events: [(String, String)] = []

        if player.questStreak > 0 {
            events.append(("🔥", "You're on a \(player.questStreak)-day streak!"))
        }
        if player.totalQuestsCompleted > 0 {
            events.append(("⚔️", "\(player.totalQuestsCompleted) quests conquered"))
        }
        if pendingCards > 0 {
            events.append(("🎴", "\(pendingCards) cards waiting in The Vault"))
        }
        if player.totalMoneySaved > 0 {
            events.append(("💰", "You've saved \(formatCurrency(player.totalMoneySaved)) total"))
        }

        let bossZone = player.currentQuestZone
        let bossPercent = Int(bossProgressFraction * 100)
        if bossPercent > 0 {
            events.append(("🗡️", "\(bossZone.bossName) at \(100 - bossPercent)% HP"))
        }

        if events.isEmpty {
            events.append(("✨", "Welcome to the Arcade! Start your first quest"))
            events.append(("💡", "Complete quests to earn scratch cards"))
            events.append(("🎯", "Daily quests refresh at midnight"))
        }

        return events
    }

    private func ensurePlayer() {
        if cachedPlayer == nil {
            if let existing = playerProfiles.first {
                cachedPlayer = existing
            } else {
                let newProfile = PlayerProfile()
                modelContext.insert(newProfile)
                try? modelContext.save()
                cachedPlayer = newProfile
            }
        }
    }

    private func ensurePlayerAndQuests() {
        if playerProfiles.isEmpty && cachedPlayer == nil {
            let profile = PlayerProfile()
            modelContext.insert(profile)
            try? modelContext.save()
            cachedPlayer = profile
        }
        let engine = QuestEngine(modelContext: modelContext)
        let p = engine.getOrCreatePlayer()
        engine.refreshDailyQuests(player: p)
        engine.refreshWeeklyQuests(player: p)
        _ = WeeklyChallengeManager(modelContext: modelContext).currentChallenge()
    }

    private func refreshCachedData() {
        let engine = QuestEngine(modelContext: modelContext)
        let completed = Set(todaysQuests.filter { engine.isQuestCompleted($0.quest.id) }.map(\.quest.id))
        completedQuestIDs = completed
        cachedCompletedDailyCount = completed.count
        cachedCurrentWeeklyChallenge = WeeklyChallengeManager(modelContext: modelContext).currentChallenge()
        cachedPendingQuestCount = engine.pendingQuestCount()
    }

    private func completeQuest(_ questID: String) {
        let engine = QuestEngine(modelContext: modelContext)
        let playerDescriptor = FetchDescriptor<PlayerProfile>()
        guard let p = try? modelContext.fetch(playerDescriptor).first else { return }

        let quest = QuestDataManager.shared.quest(byID: questID)
        if let quest, quest.steps.count > 1 {
            let allDone = engine.advanceQuestStep(questID)
            if !allDone { return }
        }

        let reward = engine.completeQuest(questID, player: p)
        lastReward = reward
        refreshCachedData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRewardCelebration = true
        }
    }
}

// MARK: - Compact Leader Entry

private struct CompactLeaderEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let icon: String
    let score: String
    let isCurrentUser: Bool
}

// MARK: - Compact Mission Card

private struct CompactMissionCard: View {
    let quest: QuestDefinition
    let isLucky: Bool
    let isComplete: Bool
    let onTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(quest.difficulty.color)
                        .frame(width: 6, height: 6)

                    if isLucky {
                        Image(systemName: "sparkle")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.neonGold)
                    }

                    Spacer()

                    Text("+\(quest.baseXP) XP")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                }

                Text(quest.title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Image(systemName: quest.category.icon)
                        .font(Typography.labelSmall)
                        .foregroundStyle(quest.category.color)
                    Text(quest.estimatedTime)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(12)
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isLucky
                        ? AnyShapeStyle(LinearGradient(colors: [Theme.neonGold.opacity(0.6), Theme.neonGold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Theme.glassBorder),
                        lineWidth: isLucky ? 1 : 0.5
                    )
            )
            .shadow(color: isLucky ? Theme.neonGold.opacity(0.15) : .clear, radius: 8, y: 2)
            .overlay {
                if isComplete {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.accent.opacity(0.2))
                        Image(systemName: "checkmark.circle.fill")
                            .font(Typography.displayMedium)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
        .disabled(isComplete)
        .accessibilityLabel("\(quest.title), \(quest.difficulty.rawValue), \(quest.baseXP) XP\(isLucky ? ", Lucky quest" : "")\(isComplete ? ", Completed" : "")")
    }
}

// MARK: - Arcade Game Card

private struct ArcadeGameCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let badgeCount: Int
    let statLabel: String
    let statProgress: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                    .shadow(color: accentColor.opacity(0.2), radius: 8)

                Image(systemName: icon)
                    .font(Typography.displaySmall)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)

                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(Typography.labelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(accentColor, in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(Typography.labelSmall)
                    .foregroundStyle(accentColor.opacity(0.8))

                HStack(spacing: 8) {
                    Text(statLabel)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.elevated)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(accentColor.opacity(0.8))
                                .frame(width: max(0, geo.size.width * statProgress), height: 6)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: 80)

                    Text("\(Int(statProgress * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [accentColor.opacity(0.25), accentColor.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: accentColor.opacity(0.08), radius: 12, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle), \(statLabel), \(Int(statProgress * 100)) percent")
    }
}

// MARK: - Arcade Stat Card

private struct ArcadeStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(Typography.headingLarge)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.headingLarge)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: color.opacity(0.1), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Quick Mission Sheet

private struct QuickMissionSheet: View {
    let quest: QuestDefinition
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: quest.category.icon)
                        .foregroundStyle(quest.category.color)
                    Text(quest.category.rawValue)
                        .font(Typography.labelMedium)
                        .foregroundStyle(quest.category.color)
                }

                Text(quest.title)
                    .font(Typography.displaySmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(quest.description)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("+\(quest.baseXP)")
                        .font(Typography.moneyMedium)
                        .foregroundStyle(Theme.accent)
                    Text("XP")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }

                VStack(spacing: 2) {
                    Text(quest.difficulty.rawValue)
                        .font(Typography.headingSmall)
                        .foregroundStyle(quest.difficulty.color)
                    Text("Difficulty")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }

                VStack(spacing: 2) {
                    Text(quest.estimatedTime)
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)
                    Text("Time")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.vertical, 12)

            if quest.steps.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(quest.steps) { step in
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textMuted)
                            Text(step.instruction)
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            Button(action: onComplete) {
                Text(quest.steps.count <= 1 ? "Complete Quest" : "Start Quest")
                    .font(Typography.headingMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
            }
            .sensoryFeedback(.success, trigger: false)
        }
        .padding(24)
        .background(Theme.background)
    }
}
