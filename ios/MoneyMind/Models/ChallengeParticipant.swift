import Foundation
import SwiftData

@Model
class ChallengeParticipant {
    var id: String = UUID().uuidString
    var challengeID: String = ""
    var userID: String = ""
    var displayName: String = ""
    var emoji: String = ""
    var joinedDate: Date = Date()

    var livesRemaining: Int = 3
    var streakShieldsAvailable: Int = 0
    var shieldActiveToday: Bool = false
    var status: String = "active"
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalCheckIns: Int = 0
    var successfulCheckIns: Int = 0
    var hasCoveredFriendIDs: [String] = []
    var wasCoveredToday: Bool = false
    var eliminationDate: Date?
    var exitSummary: String?
    var lastCheckInDate: Date?
    var isCreator: Bool = false

    init(
        challengeID: String = "",
        userID: String = "",
        displayName: String = "",
        emoji: String = ""
    ) {
        self.challengeID = challengeID
        self.userID = userID
        self.displayName = displayName
        self.emoji = emoji
    }

    var completionRate: Double {
        totalCheckIns > 0 ? Double(successfulCheckIns) / Double(totalCheckIns) : 0
    }

    var isActive: Bool {
        status == "active" || status == "shielded" || status == "atRisk" || status == "onThinIce" || status == "slipped"
    }

    var canCheckIn: Bool {
        isActive && status != "eliminated" && status != "spectator"
    }

    var hasSlippedToday: Bool {
        status == "slipped"
    }

    var isEliminated: Bool {
        status == "eliminated" || status == "spectator"
    }
}
