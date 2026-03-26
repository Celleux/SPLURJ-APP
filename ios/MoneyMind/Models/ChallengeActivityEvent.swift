import Foundation
import SwiftData

@Model
class ChallengeActivityEvent {
    var id: String = UUID().uuidString
    var challengeID: String = ""
    var message: String = ""
    var date: Date = Date()
    var iconName: String = "info.circle.fill"

    init(challengeID: String, message: String, iconName: String = "info.circle.fill") {
        self.challengeID = challengeID
        self.message = message
        self.iconName = iconName
    }
}
