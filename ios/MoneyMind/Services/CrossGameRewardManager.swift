import SwiftUI
import SwiftData

@Observable
final class CrossGameRewardManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Quest → Vault Rewards

    func awardStreakMilestoneCards(streak: Int) -> Int {
        let guaranteedRarity: CardRarity?
        switch streak {
        case 7: guaranteedRarity = .rare
        case 21: guaranteedRarity = .epic
        case 50: guaranteedRarity = .epic
        case 100: guaranteedRarity = .legendary
        case 200: guaranteedRarity = nil
        default: guaranteedRarity = nil
        }

        var cardsCreated = 0

        if let rarity = guaranteedRarity {
            if createGuaranteedScratchCard(rarity: rarity) {
                cardsCreated += 1
            }
        }

        if streak == 200 {
            for _ in 0..<2 {
                if createGuaranteedScratchCard(rarity: .legendary) {
                    cardsCreated += 1
                }
            }
        }

        return cardsCreated
    }

    func awardBossDefeatCards() -> Int {
        var cardsCreated = 0
        for _ in 0..<3 {
            if createScratchCard() {
                cardsCreated += 1
            }
        }
        return cardsCreated
    }

    func awardChainCompletionCard(allChainsComplete: Bool) -> Bool {
        let rarity: CardRarity = allChainsComplete ? .legendary : .epic
        return createGuaranteedScratchCard(rarity: rarity)
    }

    // MARK: - Vault → Quest Rewards

    func awardNewCardXP() -> Int {
        let xp = 25
        addXPToPlayer(xp)
        return xp
    }

    func awardSetCompletionXP(setName: String) -> Int {
        let xp = 500
        addXPToPlayer(xp)
        return xp
    }

    func awardEvolutionXP(evolutionLevel: Int) -> Int {
        let xp = 10 * evolutionLevel
        addXPToPlayer(xp)
        return xp
    }

    func activateDoubleXPBuff() {
        let descriptor = FetchDescriptor<PlayerProfile>()
        guard let player = try? modelContext.fetch(descriptor).first else { return }
        player.doubleXPUntil = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        try? modelContext.save()
    }

    func isDoubleXPActive() -> Bool {
        let descriptor = FetchDescriptor<PlayerProfile>()
        guard let player = try? modelContext.fetch(descriptor).first else { return false }
        guard let until = player.doubleXPUntil else { return false }
        return until > Date()
    }

    // MARK: - Critical Scratch Bonus

    func rollCriticalScratch() -> CriticalScratchBonus? {
        guard Double.random(in: 0...1) < 0.10 else { return nil }

        let roll = Double.random(in: 0...1)
        if roll < 0.4 {
            return .bonusEssence(50)
        } else if roll < 0.7 {
            _ = createScratchCard()
            return .extraScratchCard
        } else {
            activateDoubleXPBuff()
            return .doubleXP
        }
    }

    // MARK: - Query Helpers

    func availableQuestCount() -> Int {
        let engine = QuestEngine(modelContext: modelContext)
        return engine.pendingQuestCount()
    }

    func pendingScratchCardCount() -> Int {
        let descriptor = FetchDescriptor<ScratchCard>(
            predicate: #Predicate<ScratchCard> { $0.scratchedAt == nil }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    func isSetComplete(_ setName: String) -> Bool {
        let descriptor = FetchDescriptor<Achievement>(predicate: #Predicate { $0.typeRaw == "card" })
        let allCollected = (try? modelContext.fetch(descriptor)) ?? []
        let setCards = allCollected.filter { $0.setName == setName }
        let setDefinitions = CardDatabase.cards(forSet: CardSet(rawValue: setName) ?? .saversGuild)
        let uniqueIDs = Set(setCards.map(\.cardID))
        return uniqueIDs.count >= setDefinitions.count && !setDefinitions.isEmpty
    }

    // MARK: - Private

    private func createScratchCard() -> Bool {
        let pendingDescriptor = FetchDescriptor<ScratchCard>(
            predicate: #Predicate<ScratchCard> { $0.scratchedAt == nil }
        )
        let pendingCount = (try? modelContext.fetch(pendingDescriptor).count) ?? 0
        guard pendingCount < 8 else { return false }

        let engine = GachaEngine()
        syncGachaEngine(engine)
        let pulled = engine.pull()
        saveGachaEngine(engine)

        let card = ScratchCard(
            resistedAmount: 0,
            currency: "USD",
            cardPullID: pulled.id,
            cardRarity: pulled.rarity.rawValue
        )
        modelContext.insert(card)
        try? modelContext.save()
        return true
    }

    private func createGuaranteedScratchCard(rarity: CardRarity) -> Bool {
        let pendingDescriptor = FetchDescriptor<ScratchCard>(
            predicate: #Predicate<ScratchCard> { $0.scratchedAt == nil }
        )
        let pendingCount = (try? modelContext.fetch(pendingDescriptor).count) ?? 0
        guard pendingCount < 8 else { return false }

        let pool = CardDatabase.cards(forRarity: rarity)
        guard let selected = pool.randomElement() else { return false }

        let engine = GachaEngine()
        syncGachaEngine(engine)
        if rarity == .legendary {
            engine.resetLegendaryPity()
        } else if rarity == .epic {
            engine.resetEpicPity()
        }
        saveGachaEngine(engine)

        let card = ScratchCard(
            resistedAmount: 0,
            currency: "USD",
            cardPullID: selected.id,
            cardRarity: selected.rarity.rawValue
        )
        modelContext.insert(card)
        try? modelContext.save()
        return true
    }

    private func addXPToPlayer(_ xp: Int) {
        let descriptor = FetchDescriptor<PlayerProfile>()
        guard let player = try? modelContext.fetch(descriptor).first else { return }
        player.totalXP += xp
        try? modelContext.save()

        let userDescriptor = FetchDescriptor<UserProfile>()
        if let userProfile = try? modelContext.fetch(userDescriptor).first {
            userProfile.xpPoints += xp
        }
        try? modelContext.save()
    }

    private func syncGachaEngine(_ engine: GachaEngine) {
        let descriptor = FetchDescriptor<GachaState>()
        if let state = try? modelContext.fetch(descriptor).first {
            engine.syncFromState(state)
        }
    }

    private func saveGachaEngine(_ engine: GachaEngine) {
        let descriptor = FetchDescriptor<GachaState>()
        let state: GachaState
        if let existing = try? modelContext.fetch(descriptor).first {
            state = existing
        } else {
            state = GachaState()
            modelContext.insert(state)
        }
        engine.saveToState(state)
        try? modelContext.save()
    }
}
