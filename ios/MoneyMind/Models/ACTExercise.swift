import Foundation
import SwiftData

nonisolated enum ACTExerciseType: String, Codable, Sendable, CaseIterable, Identifiable {
    case valuesClarity = "values"
    case cognitiveDefusion = "defusion"
    case willingness = "willingness"

    nonisolated var id: String { rawValue }

    var title: String {
        switch self {
        case .valuesClarity: "Values Clarification"
        case .cognitiveDefusion: "Cognitive Defusion"
        case .willingness: "Willingness & Acceptance"
        }
    }

    var icon: String {
        switch self {
        case .valuesClarity: "heart.circle.fill"
        case .cognitiveDefusion: "bubble.left.and.text.bubble.right.fill"
        case .willingness: "hands.clap.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .valuesClarity: "Discover what matters most about money"
        case .cognitiveDefusion: "Create distance from unhelpful thoughts"
        case .willingness: "Build tolerance for discomfort"
        }
    }
}

@Model
class ACTExercise {
    var id: UUID
    var typeRaw: String
    var responses: [String]
    var completedDate: Date
    var initialRating: Int
    var finalRating: Int

    var exerciseType: ACTExerciseType {
        get { ACTExerciseType(rawValue: typeRaw) ?? .valuesClarity }
        set { typeRaw = newValue.rawValue }
    }

    init(type: ACTExerciseType, responses: [String] = [], initialRating: Int = 0, finalRating: Int = 0) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.responses = responses
        self.completedDate = Date()
        self.initialRating = initialRating
        self.finalRating = finalRating
    }
}
