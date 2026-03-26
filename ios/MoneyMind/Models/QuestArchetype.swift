import Foundation

nonisolated enum QuestArchetype: String, Codable, Sendable, Hashable {
    case kill
    case interaction
    case delivery
    case exploration
    case fetch
    case escort
    case bossBattle
}

nonisolated enum VerificationType: String, Codable, Sendable, Hashable {
    case selfReport
    case photoProof
    case appCheck
    case automatic
    case inAppAction
}
