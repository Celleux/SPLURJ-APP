import Foundation
import SwiftData

@Model
class ChallengeCheckIn {
    var id: String = UUID().uuidString
    var challengeID: String = ""
    var participantID: String = ""
    var date: Date = Date()
    var didHold: Bool = true
    var note: String = ""
    var amountSaved: Double = 0
    var reactions: [String] = []
    var livesLost: Int = 0
    var shieldUsed: Bool = false

    init(
        challengeID: String = "",
        participantID: String = "",
        didHold: Bool = true,
        note: String = "",
        amountSaved: Double = 0
    ) {
        self.challengeID = challengeID
        self.participantID = participantID
        self.didHold = didHold
        self.note = note
        self.amountSaved = amountSaved
    }
}
