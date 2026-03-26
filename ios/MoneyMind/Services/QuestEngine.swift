import Foundation
import SwiftData

@Observable
final class QuestEngine {
    private let modelContext: ModelContext
    private let questDB = QuestDataManager.shared.allQuests
    private let gachaEngine = GachaEngine()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        syncGachaState()
    }

    // MARK: - Daily Quest Rotation

    func refreshDailyQuests(player: PlayerProfile) {
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyQuestSlot>(
            predicate: #Predicate<DailyQuestSlot> { slot in
                slot.offeredDate >= today && slot.cadence == "daily"
            }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        cleanupExpiredSlots()

        let eligible = dailyEligibleQuests(for: player)
        let selected = weightedSelection(from: eligible, count: 3, player: player)

        guard !selected.isEmpty else { return }

        let daySeed = deterministicSeed(for: today, playerLevel: player.level, salt: "lucky")
        let luckyIndex = daySeed % selected.count

        for (i, quest) in selected.enumerated() {
            let slot = DailyQuestSlot(
                questID: quest.id,
                cadence: "daily",
                offeredDate: today,
                isLuckyQuest: i == luckyIndex
            )
            modelContext.insert(slot)
        }

        try? modelContext.save()
    }

    // MARK: - Weekly Quest Rotation

    func refreshWeeklyQuests(player: PlayerProfile) {
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        let monday: Date
        if weekday == 2 {
            monday = today
        } else {
            let daysBack = (weekday + 5) % 7
            monday = Calendar.current.date(byAdding: .day, value: -daysBack, to: today) ?? today
        }

        let descriptor = FetchDescriptor<DailyQuestSlot>(
            predicate: #Predicate<DailyQuestSlot> { slot in
                slot.offeredDate >= monday && slot.cadence == "weekly"
            }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let eligible = weeklyEligibleQuests(for: player)
        let selected = weightedSelection(from: eligible, count: 2, player: player)

        for quest in selected {
            let slot = DailyQuestSlot(
                questID: quest.id,
                cadence: "weekly",
                offeredDate: monday,
                isLuckyQuest: false
            )
            modelContext.insert(slot)
        }

        try? modelContext.save()
    }

    // MARK: - Complete a Quest

    func completeQuest(_ questID: String, player: PlayerProfile) -> QuestReward {
        guard let quest = questDB.first(where: { $0.id == questID }) else {
            return .empty
        }

        var xp = Int(Double(quest.baseXP) * quest.difficulty.xpMultiplier)

        if let doubleUntil = player.doubleXPUntil, doubleUntil > Date() {
            xp = xp * 2
        }

        if player.questStreak >= 30 {
            xp = Int(Double(xp) * 2.0)
        } else if player.questStreak >= 7 {
            xp = Int(Double(xp) * 1.5)
        }

        let isLucky = checkIfLucky(questID)
        if isLucky {
            xp = Int(Double(xp) * 1.5)
        }

        player.totalXP += xp
        player.totalQuestsCompleted += 1

        syncXPToUserProfile(xp: xp)

        updateStreak(player: player)

        let didLevelUp = checkAndApplyLevelUp(player: player)

        var earnedScratchCard = false
        let cardChance = quest.cadence == .weekly ? 1.0 : quest.scratchCardChance
        if Double.random(in: 0...1) < cardChance {
            earnedScratchCard = createScratchCard()
        }

        let bossDamage: Int
        if let bossHP = quest.bossHP {
            bossDamage = bossHP
        } else {
            bossDamage = xp / 10
        }
        player.currentBossDamageDealt += bossDamage

        if player.currentBossZone == nil {
            player.currentBossZone = player.currentQuestZone.rawValue
        }

        let essence = quest.essenceReward + (isLucky ? 5 : 0)
        addEssence(essence)

        if let amount = quest.estimatedSavingsAmount {
            player.totalMoneySaved += amount
            syncSavingsToUserProfile(amount: amount)
        }

        let progress = getOrCreateProgress(for: questID)
        progress.questStatus = .completed
        progress.completedAt = Date()
        progress.xpEarned = xp

        try? modelContext.save()

        let streakCards = checkAndAwardStreakCards(player: player)

        return QuestReward(
            xp: xp,
            scratchCard: earnedScratchCard,
            essence: essence,
            didLevelUp: didLevelUp,
            newLevel: player.level,
            isLucky: isLucky,
            bossDamage: bossDamage,
            tiktokMoment: quest.tiktokMoment,
            streakBonusCards: streakCards,
            hasDoubleXP: player.doubleXPUntil != nil && player.doubleXPUntil! > Date()
        )
    }

    // MARK: - Advance Quest Step

    func advanceQuestStep(_ questID: String) -> Bool {
        guard let quest = questDB.first(where: { $0.id == questID }) else { return false }

        let progress = getOrCreateProgress(for: questID)

        if progress.questStatus == .available {
            progress.questStatus = .active
            progress.startedAt = Date()
        }

        guard progress.questStatus == .active else { return false }

        let currentIndex = progress.currentStepIndex
        guard currentIndex < quest.steps.count else { return false }

        let step = quest.steps[currentIndex]
        var completions = progress.stepCompletions
        completions[step.id] = true
        progress.stepCompletions = completions
        progress.currentStepIndex = currentIndex + 1

        let allDone = progress.currentStepIndex >= quest.steps.count
        try? modelContext.save()

        return allDone
    }

    // MARK: - Start Quest

    func startQuest(_ questID: String) {
        let progress = getOrCreateProgress(for: questID)
        guard progress.questStatus == .available else { return }
        progress.questStatus = .active
        progress.startedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Archive Quest (Write-Off Decision)

    func archiveQuest(_ questID: String, player: PlayerProfile) {
        let progress = getOrCreateProgress(for: questID)
        progress.questStatus = .archived
        progress.completedAt = Date()
        player.totalXP += 15
        try? modelContext.save()
    }

    // MARK: - Defeat Boss

    func defeatBoss(player: PlayerProfile, zone: QuestZone) -> Bool {
        guard player.currentBossDamageDealt >= zone.bossHP else { return false }

        var defeated = player.bossesDefeated
        if !defeated.contains(zone.rawValue) {
            defeated.append(zone.rawValue)
            player.bossesDefeated = defeated
        }

        player.currentBossDamageDealt = 0

        let nextZone = QuestZone.allCases.first { $0.levelRange.lowerBound > zone.levelRange.upperBound }
        player.currentBossZone = nextZone?.rawValue

        let rewardManager = CrossGameRewardManager(modelContext: modelContext)
        _ = rewardManager.awardBossDefeatCards()

        addEssence(100)

        try? modelContext.save()
        return true
    }

    // MARK: - Query Helpers

    func questProgress(for questID: String) -> QuestProgress? {
        let descriptor = FetchDescriptor<QuestProgress>(
            predicate: #Predicate<QuestProgress> { $0.questID == questID }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func isQuestCompleted(_ questID: String) -> Bool {
        guard let progress = questProgress(for: questID) else { return false }
        return progress.questStatus == .completed || progress.questStatus == .claimed
    }

    func todaysDailySlots() -> [DailyQuestSlot] {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyQuestSlot>(
            predicate: #Predicate<DailyQuestSlot> { slot in
                slot.offeredDate >= today && slot.cadence == "daily"
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func currentWeeklySlots() -> [DailyQuestSlot] {
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        let daysBack = (weekday + 5) % 7
        let monday = Calendar.current.date(byAdding: .day, value: -daysBack, to: today) ?? today

        let descriptor = FetchDescriptor<DailyQuestSlot>(
            predicate: #Predicate<DailyQuestSlot> { slot in
                slot.offeredDate >= monday && slot.cadence == "weekly"
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func pendingQuestCount() -> Int {
        let dailySlots = todaysDailySlots()
        let weeklySlots = currentWeeklySlots()
        let allSlotIDs = (dailySlots + weeklySlots).map(\.questID)
        return allSlotIDs.filter { !isQuestCompleted($0) }.count
    }

    func chainProgress(chainID: String) -> (completed: Int, total: Int) {
        let chainQuests = QuestDataManager.shared.quests(forChain: chainID)
        let completedCount = chainQuests.filter { isQuestCompleted($0.id) }.count
        return (completedCount, chainQuests.count)
    }

    func nextChainQuest(chainID: String) -> QuestDefinition? {
        let chainQuests = QuestDataManager.shared.quests(forChain: chainID)
        return chainQuests.first { !isQuestCompleted($0.id) }
    }

    // MARK: - Private Helpers

    private func dailyEligibleQuests(for player: PlayerProfile) -> [QuestDefinition] {
        let zone = player.currentQuestZone
        let adjacentZones = adjacentZonesFor(zone)
        let allowedZones = [zone] + adjacentZones

        return questDB.filter { quest in
            quest.cadence == .daily &&
            allowedZones.contains(quest.zone) &&
            !isQuestCompleted(quest.id) &&
            isSeasonallyAvailable(quest)
        }
    }

    private func weeklyEligibleQuests(for player: PlayerProfile) -> [QuestDefinition] {
        let zone = player.currentQuestZone
        let adjacentZones = adjacentZonesFor(zone)
        let allowedZones = [zone] + adjacentZones

        return questDB.filter { quest in
            quest.cadence == .weekly &&
            allowedZones.contains(quest.zone) &&
            !isQuestCompleted(quest.id) &&
            isSeasonallyAvailable(quest)
        }
    }

    private func adjacentZonesFor(_ zone: QuestZone) -> [QuestZone] {
        let all = QuestZone.allCases
        guard let idx = all.firstIndex(of: zone) else { return [] }
        var result: [QuestZone] = []
        if idx > 0 { result.append(all[idx - 1]) }
        if idx < all.count - 1 { result.append(all[idx + 1]) }
        return result
    }

    private func isSeasonallyAvailable(_ quest: QuestDefinition) -> Bool {
        guard let months = quest.seasonalMonths else { return true }
        let currentMonth = Calendar.current.component(.month, from: Date())
        return months.contains(currentMonth)
    }

    private func weightedSelection(from quests: [QuestDefinition], count: Int, player: PlayerProfile) -> [QuestDefinition] {
        guard !quests.isEmpty else { return [] }

        let today = Calendar.current.startOfDay(for: Date())
        var rng = SeededRandomNumberGenerator(
            seed: UInt64(deterministicSeed(for: today, playerLevel: player.level, salt: "selection"))
        )

        let lastCompleted = lastCompletedDifficulty()
        let favorEasy = lastCompleted == .hard || lastCompleted == .legendary

        var weighted: [(QuestDefinition, Double)] = quests.map { quest in
            var weight = 1.0

            if favorEasy && quest.difficulty == .easy {
                weight *= 2.5
            } else if !favorEasy && quest.difficulty == .medium {
                weight *= 1.5
            }

            let categoryCount = completedCountForCategory(quest.category)
            if categoryCount == 0 {
                weight *= 2.0
            }

            return (quest, weight)
        }

        var selected: [QuestDefinition] = []
        var usedCategories: Set<QuestCategory> = []

        for _ in 0..<count {
            guard !weighted.isEmpty else { break }

            var adjusted = weighted.map { item -> (QuestDefinition, Double) in
                var w = item.1
                if usedCategories.contains(item.0.category) {
                    w *= 0.3
                }
                return (item.0, w)
            }

            let totalWeight = adjusted.reduce(0.0) { $0 + $1.1 }
            guard totalWeight > 0 else { break }

            var roll = Double.random(in: 0..<totalWeight, using: &rng)
            var picked: QuestDefinition?

            for (quest, w) in adjusted {
                roll -= w
                if roll <= 0 {
                    picked = quest
                    break
                }
            }

            guard let choice = picked ?? adjusted.first?.0 else { break }
            selected.append(choice)
            usedCategories.insert(choice.category)
            weighted.removeAll { $0.0.id == choice.id }
        }

        return selected
    }

    // MARK: - Deterministic Seed

    private func deterministicSeed(for date: Date, playerLevel: Int, salt: String) -> Int {
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        var hasher = Hasher()
        hasher.combine(day)
        hasher.combine(playerLevel)
        hasher.combine(salt)
        return abs(hasher.finalize())
    }

    private func lastCompletedDifficulty() -> QuestDifficulty? {
        let descriptor = FetchDescriptor<QuestProgress>(
            predicate: #Predicate<QuestProgress> { $0.status == "completed" || $0.status == "claimed" },
            sortBy: [SortDescriptor(\QuestProgress.completedAt, order: .reverse)]
        )
        guard let last = try? modelContext.fetch(descriptor).first,
              let quest = questDB.first(where: { $0.id == last.questID }) else {
            return nil
        }
        return quest.difficulty
    }

    private func completedCountForCategory(_ category: QuestCategory) -> Int {
        let raw = category.rawValue
        let descriptor = FetchDescriptor<QuestProgress>(
            predicate: #Predicate<QuestProgress> { $0.status == "completed" || $0.status == "claimed" }
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.filter { progress in
            questDB.first { $0.id == progress.questID }?.category == category
        }.count
    }

    private func checkIfLucky(_ questID: String) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyQuestSlot>(
            predicate: #Predicate<DailyQuestSlot> { slot in
                slot.questID == questID && slot.offeredDate >= today && slot.isLuckyQuest == true
            }
        )
        return ((try? modelContext.fetch(descriptor))?.first) != nil
    }

    private func checkAndApplyLevelUp(player: PlayerProfile) -> Bool {
        var leveled = false
        while player.xpProgressInCurrentLevel >= player.xpForCurrentLevel && player.level < 50 {
            player.level += 1
            leveled = true
            player.avatarStage = min(4, (player.level - 1) / 10)
            player.currentZone = player.currentQuestZone.rawValue
        }
        return leveled
    }

    private func updateStreak(player: PlayerProfile) {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = player.lastQuestDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 1 {
                player.questStreak += 1
            } else if daysBetween > 1 {
                player.questStreak = 1
            }
        } else {
            player.questStreak = 1
        }

        player.lastQuestDate = today

        if player.questStreak > player.longestStreak {
            player.longestStreak = player.questStreak
        }
    }

    private func getOrCreateProgress(for questID: String) -> QuestProgress {
        if let existing = questProgress(for: questID) {
            return existing
        }
        let progress = QuestProgress(questID: questID)
        modelContext.insert(progress)
        return progress
    }

    private func createScratchCard() -> Bool {
        let pendingDescriptor = FetchDescriptor<ScratchCard>(
            predicate: #Predicate<ScratchCard> { $0.scratchedAt == nil }
        )
        let pendingCount = (try? modelContext.fetch(pendingDescriptor).count) ?? 0
        guard pendingCount < 5 else { return false }

        let pulled = gachaEngine.pull()
        saveGachaState()

        let card = ScratchCard(
            resistedAmount: 0,
            currency: "USD",
            cardPullID: pulled.id,
            cardRarity: pulled.rarity.rawValue
        )
        modelContext.insert(card)
        return true
    }

    private func addEssence(_ amount: Int) {
        gachaEngine.addEssence(amount)
        saveGachaState()
    }

    private func syncGachaState() {
        let descriptor = FetchDescriptor<GachaState>()
        if let state = try? modelContext.fetch(descriptor).first {
            gachaEngine.syncFromState(state)
        }
    }

    private func saveGachaState() {
        let descriptor = FetchDescriptor<GachaState>()
        let state: GachaState
        if let existing = try? modelContext.fetch(descriptor).first {
            state = existing
        } else {
            state = GachaState()
            modelContext.insert(state)
        }
        gachaEngine.saveToState(state)
    }

    private func syncXPToUserProfile(xp: Int) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        profile.xpPoints += xp
    }

    private func syncSavingsToUserProfile(amount: Double) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        profile.totalSaved += amount
    }

    // MARK: - Micro-Quest Support

    func checkMicroQuestEligibility() -> Bool {
        allDailyQuestsComplete()
    }

    func getMicroQuests(count: Int = 5) -> [QuestDefinition] {
        let today = Calendar.current.startOfDay(for: Date())
        let completedToday = todayCompletedQuestIDs()

        let eligible = QuestDataManager.shared.microQuests.filter { quest in
            !completedToday.contains(quest.id)
        }

        guard !eligible.isEmpty else { return [] }

        var rng = SeededRandomNumberGenerator(
            seed: UInt64(deterministicSeed(for: today, playerLevel: 0, salt: "micro"))
        )
        return Array(eligible.shuffled(using: &rng).prefix(count))
    }

    // MARK: - Streak Milestone Support

    func checkStreakMilestoneQuest(player: PlayerProfile) -> QuestDefinition? {
        let streak = player.questStreak
        guard QuestDataManager.shared.streakMilestones.contains(streak) else { return nil }
        guard let quest = QuestDataManager.shared.streakQuest(forMilestone: streak) else { return nil }
        guard !isQuestCompleted(quest.id) else { return nil }
        return quest
    }

    func checkComebackQuest(player: PlayerProfile) -> QuestDefinition? {
        guard let lastDate = player.lastQuestDate else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let daysBetween = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        guard daysBetween > 1 else { return nil }
        guard player.questStreak == 0 || daysBetween > 1 else { return nil }
        let comeback = QuestDataManager.shared.randomComebackQuest()
        guard !isQuestCompleted(comeback.id) else { return nil }
        return comeback
    }

    // MARK: - Dynamic Context Quests

    func availableDynamicQuests() -> [QuestDefinition] {
        let dynamicQuests = QuestDataManager.shared.availableDynamicQuests()
        return dynamicQuests.filter { !isQuestCompleted($0.id) }
    }

    // MARK: - Helper

    private func todayCompletedQuestIDs() -> Set<String> {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<QuestProgress>(
            predicate: #Predicate<QuestProgress> { $0.completedAt != nil && $0.completedAt! >= today }
        )
        let completed = (try? modelContext.fetch(descriptor)) ?? []
        return Set(completed.map(\.questID))
    }

    private func checkAndAwardStreakCards(player: PlayerProfile) -> Int {
        let milestones = [7, 21, 50, 100, 200]
        guard milestones.contains(player.questStreak) else { return 0 }
        let rewardManager = CrossGameRewardManager(modelContext: modelContext)
        return rewardManager.awardStreakMilestoneCards(streak: player.questStreak)
    }

    func luckyQuestForToday() -> QuestDefinition? {
        let slots = todaysDailySlots()
        guard let luckySlot = slots.first(where: { $0.isLuckyQuest }) else {
            return slots.first.flatMap { slot in questDB.first { $0.id == slot.questID } }
        }
        return questDB.first { $0.id == luckySlot.questID }
    }

    func allDailyQuestsComplete() -> Bool {
        let slots = todaysDailySlots()
        guard !slots.isEmpty else { return false }
        return slots.allSatisfy { isQuestCompleted($0.questID) }
    }

    private func cleanupExpiredSlots() {
        let now = Date()
        let descriptor = FetchDescriptor<DailyQuestSlot>(
            predicate: #Predicate<DailyQuestSlot> { $0.expiresAt < now }
        )
        let expired = (try? modelContext.fetch(descriptor)) ?? []
        for slot in expired {
            let progress = questProgress(for: slot.questID)
            if let p = progress, p.questStatus == .active || p.questStatus == .available {
                p.questStatus = .expired
            }
            modelContext.delete(slot)
        }
    }

    // MARK: - Fetch Player or Create

    func getOrCreatePlayer() -> PlayerProfile {
        let descriptor = FetchDescriptor<PlayerProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let player = PlayerProfile()
        modelContext.insert(player)
        try? modelContext.save()
        return player
    }
}

nonisolated struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
