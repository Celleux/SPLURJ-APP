import Foundation
import SwiftData

@Model
class HALTCheckIn {
    var date: Date
    var hungryScore: Int
    var angryScore: Int
    var lonelyScore: Int
    var tiredScore: Int
    var need: String
    var contextNote: String

    init(hungryScore: Int = 0, angryScore: Int = 0, lonelyScore: Int = 0, tiredScore: Int = 0, need: String = "", contextNote: String = "") {
        self.date = Date()
        self.hungryScore = hungryScore
        self.angryScore = angryScore
        self.lonelyScore = lonelyScore
        self.tiredScore = tiredScore
        self.need = need
        self.contextNote = contextNote
    }
}
