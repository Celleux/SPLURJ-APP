import Foundation
import SwiftData

struct ScratchCardEarnResult {
    let card: ScratchCard
    let isGlowing: Bool
}

enum ScratchCardService {
    static let maxPendingCards = 5

    static func earnScratchCard(
        resistedAmount: Double,
        currency: String,
        engine: GachaEngine,
        gachaState: GachaState?,
        modelContext: ModelContext
    ) -> ScratchCardEarnResult? {
        let pendingCount = pendingCardCount(in: modelContext)
        guard pendingCount < maxPendingCards else { return nil }

        let pulledCard = engine.pull()
        if let state = gachaState {
            engine.saveToState(state)
        }

        let scratchCard = ScratchCard(
            resistedAmount: resistedAmount,
            currency: currency,
            cardPullID: pulledCard.id,
            cardRarity: pulledCard.rarity.rawValue
        )
        modelContext.insert(scratchCard)

        let isGlowing = pulledCard.rarity == .epic || pulledCard.rarity == .legendary
        return ScratchCardEarnResult(card: scratchCard, isGlowing: isGlowing)
    }

    static func pendingCardCount(in modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<ScratchCard>(
            predicate: #Predicate<ScratchCard> { $0.scratchedAt == nil }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    static func canEarnMore(in modelContext: ModelContext) -> Bool {
        pendingCardCount(in: modelContext) < maxPendingCards
    }
}
