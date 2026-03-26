import Foundation
import SwiftData

@Model
class QuestProgress {
    var questID: String = ""
    var status: String = "available"
    var currentStepIndex: Int = 0
    var stepCompletionData: Data = Data()
    var startedAt: Date?
    var completedAt: Date?
    var xpEarned: Int = 0
    var screenshotData: Data?

    var questStatus: QuestStatus {
        get { QuestStatus(rawValue: status) ?? .available }
        set { status = newValue.rawValue }
    }

    var stepCompletions: [String: Bool] {
        get {
            (try? JSONDecoder().decode([String: Bool].self, from: stepCompletionData)) ?? [:]
        }
        set {
            stepCompletionData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(questID: String) {
        self.questID = questID
        self.status = QuestStatus.available.rawValue
    }
}
