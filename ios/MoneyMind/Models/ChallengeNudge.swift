import Foundation
import SwiftData

@Model
class ChallengeNudge {
    var id: String = UUID().uuidString
    var challengeID: String = ""
    var senderName: String = ""
    var senderEmoji: String = ""
    var receiverName: String = ""
    var date: Date = Date()
    var type: String = "nudge"

    init(
        challengeID: String = "",
        senderName: String = "",
        senderEmoji: String = "",
        receiverName: String = "",
        type: String = "nudge"
    ) {
        self.challengeID = challengeID
        self.senderName = senderName
        self.senderEmoji = senderEmoji
        self.receiverName = receiverName
        self.type = type
    }
}
