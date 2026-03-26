import Foundation
import SwiftData

@Model
class ImplementationIntention {
    var intention: String
    var trigger: String
    var response: String
    var hasSigned: Bool
    var timesActivated: Int
    var createdAt: Date

    init(intention: String = "", trigger: String = "", response: String = "", hasSigned: Bool = false) {
        self.intention = intention
        self.trigger = trigger
        self.response = response
        self.hasSigned = hasSigned
        self.timesActivated = 0
        self.createdAt = Date()
    }
}
