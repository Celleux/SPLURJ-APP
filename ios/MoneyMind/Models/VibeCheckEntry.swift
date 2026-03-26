import Foundation
import SwiftData

@Model
class VibeCheckEntry {
    var transactionID: String
    var emoji: String
    var sentiment: Float
    var timestamp: Date
    var amount: Double
    var categoryName: String

    init(
        transactionID: String,
        emoji: String,
        sentiment: Float,
        timestamp: Date = Date(),
        amount: Double = 0,
        categoryName: String = ""
    ) {
        self.transactionID = transactionID
        self.emoji = emoji
        self.sentiment = sentiment
        self.timestamp = timestamp
        self.amount = amount
        self.categoryName = categoryName
    }

    var vibeType: VibeType? {
        VibeType(fromEmoji: emoji)
    }
}
