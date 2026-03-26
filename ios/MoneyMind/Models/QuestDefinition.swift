import Foundation

nonisolated struct QuestStep: Codable, Identifiable, Sendable {
    let id: String
    let instruction: String
    let verification: VerificationType
    let xpReward: Int
}

nonisolated struct QuestDefinition: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let category: QuestCategory
    let archetype: QuestArchetype
    let difficulty: QuestDifficulty
    let cadence: QuestCadence
    let estimatedImpact: String
    let estimatedTime: String
    let verification: VerificationType
    let baseXP: Int
    let scratchCardChance: Double
    let essenceReward: Int
    let bossHP: Int?
    let steps: [QuestStep]
    let zone: QuestZone
    let chainID: String?
    let chainIndex: Int?
    let prerequisiteQuestID: String?
    let seasonalMonths: [Int]?
    let tiktokMoment: String?
    let estimatedSavingsAmount: Double?

    init(
        id: String,
        title: String,
        subtitle: String,
        description: String,
        category: QuestCategory,
        archetype: QuestArchetype,
        difficulty: QuestDifficulty,
        cadence: QuestCadence,
        estimatedImpact: String,
        estimatedTime: String,
        verification: VerificationType,
        baseXP: Int,
        scratchCardChance: Double,
        essenceReward: Int,
        bossHP: Int? = nil,
        steps: [QuestStep],
        zone: QuestZone,
        chainID: String? = nil,
        chainIndex: Int? = nil,
        prerequisiteQuestID: String? = nil,
        seasonalMonths: [Int]? = nil,
        tiktokMoment: String? = nil,
        estimatedSavingsAmount: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.category = category
        self.archetype = archetype
        self.difficulty = difficulty
        self.cadence = cadence
        self.estimatedImpact = estimatedImpact
        self.estimatedTime = estimatedTime
        self.verification = verification
        self.baseXP = baseXP
        self.scratchCardChance = scratchCardChance
        self.essenceReward = essenceReward
        self.bossHP = bossHP
        self.steps = steps
        self.zone = zone
        self.chainID = chainID
        self.chainIndex = chainIndex
        self.prerequisiteQuestID = prerequisiteQuestID
        self.seasonalMonths = seasonalMonths
        self.tiktokMoment = tiktokMoment
        self.estimatedSavingsAmount = estimatedSavingsAmount
    }
}
