import Foundation
import SwiftData

@Model
class SpendingAutopsy {
    var trigger: String
    var emotion: String
    var amount: Double
    var reflection: String
    var date: Date

    init(trigger: String = "", emotion: String = "", amount: Double = 0, reflection: String = "") {
        self.trigger = trigger
        self.emotion = emotion
        self.amount = amount
        self.reflection = reflection
        self.date = Date()
    }
}
