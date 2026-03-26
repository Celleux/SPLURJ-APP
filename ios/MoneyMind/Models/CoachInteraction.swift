import Foundation
import SwiftData

nonisolated enum CoachInteractionType: String, Codable, Sendable {
    case message
    case session
    case curriculum
}

nonisolated enum CoachMessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

@Model
class CoachInteraction {
    var typeRaw: String
    var date: Date

    var id: UUID = UUID()
    var roleRaw: String
    var content: String
    var sessionID: UUID

    var startTime: Date
    var endTime: Date?
    var sessionNumber: Int
    var xpAwarded: Bool

    var completedDate: Date?
    var notes: String
    var isCompleted: Bool

    var interactionType: CoachInteractionType {
        get { CoachInteractionType(rawValue: typeRaw) ?? .message }
        set { typeRaw = newValue.rawValue }
    }

    var role: CoachMessageRole {
        get { CoachMessageRole(rawValue: roleRaw) ?? .system }
        set { roleRaw = newValue.rawValue }
    }

    private init(type: CoachInteractionType) {
        self.typeRaw = type.rawValue
        self.date = Date()
        self.id = UUID()
        self.roleRaw = CoachMessageRole.system.rawValue
        self.content = ""
        self.sessionID = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.sessionNumber = 1
        self.xpAwarded = false
        self.completedDate = nil
        self.notes = ""
        self.isCompleted = false
    }

    static func message(role: CoachMessageRole, content: String, sessionID: UUID) -> CoachInteraction {
        let entry = CoachInteraction(type: .message)
        entry.roleRaw = role.rawValue
        entry.content = content
        entry.sessionID = sessionID
        return entry
    }

    static func session(sessionNumber: Int) -> CoachInteraction {
        let entry = CoachInteraction(type: .session)
        entry.sessionNumber = sessionNumber
        return entry
    }

    static func curriculum(sessionNumber: Int, notes: String = "") -> CoachInteraction {
        let entry = CoachInteraction(type: .curriculum)
        entry.sessionNumber = sessionNumber
        entry.notes = notes
        return entry
    }
}
