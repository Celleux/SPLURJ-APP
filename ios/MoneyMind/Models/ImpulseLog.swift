import Foundation
import SwiftData

@Model
class ImpulseLog {
    var amount: Double
    var category: String
    var note: String
    var resisted: Bool
    var date: Date
    var emotionalTrigger: String

    init(amount: Double, category: String = "General", note: String = "", resisted: Bool = true, emotionalTrigger: String = "") {
        self.amount = amount
        self.category = category
        self.note = note
        self.resisted = resisted
        self.date = Date()
        self.emotionalTrigger = emotionalTrigger
    }
}
