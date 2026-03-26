import Foundation
import SwiftData

@Model
class FinancialDNAResult {
    var spendingAxis: Double
    var emotionalAxis: Double
    var riskAxis: Double
    var socialAxis: Double
    var primaryArchetype: String
    var secondaryArchetype: String
    var superpower: String
    var vulnerability: String
    var createdAt: Date
    var cardSortAnswers: [String]
    var triggerRatings: [String: Double]
    var memoryAnswers: [String]
    var riskScore: Double

    var dna: FinancialDNA {
        FinancialDNA(
            spendingAxis: spendingAxis,
            emotionalAxis: emotionalAxis,
            riskAxis: riskAxis,
            socialAxis: socialAxis
        )
    }

    init(dna: FinancialDNA, cardSortAnswers: [String], triggerRatings: [String: Double], memoryAnswers: [String], riskScore: Double) {
        self.spendingAxis = dna.spendingAxis
        self.emotionalAxis = dna.emotionalAxis
        self.riskAxis = dna.riskAxis
        self.socialAxis = dna.socialAxis
        self.primaryArchetype = dna.primaryArchetype.rawValue
        self.secondaryArchetype = dna.secondaryArchetype.rawValue
        self.superpower = dna.superpower
        self.vulnerability = dna.vulnerability
        self.createdAt = Date()
        self.cardSortAnswers = cardSortAnswers
        self.triggerRatings = triggerRatings
        self.memoryAnswers = memoryAnswers
        self.riskScore = riskScore
    }
}
