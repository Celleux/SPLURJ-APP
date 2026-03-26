import Foundation
import SwiftData

@Model
class ScratchCard {
    var id: UUID = UUID()
    var resistedAmount: Double = 0
    var currency: String = "USD"
    var earnedAt: Date = Date()
    var scratchedAt: Date?
    var cardPullID: String?
    var cardRarity: String = "Common"

    var isScratched: Bool { scratchedAt != nil }

    init(resistedAmount: Double = 0, currency: String = "USD", cardPullID: String? = nil, cardRarity: String = "Common") {
        self.resistedAmount = resistedAmount
        self.currency = currency
        self.cardPullID = cardPullID
        self.cardRarity = cardRarity
    }
}
