import Foundation
import SwiftData

@Model
class HighRiskPattern {
    var dayOfWeek: Int
    var hourOfDay: Int
    var triggerType: String
    var frequency: Int
    var lastDetected: Date

    init(dayOfWeek: Int, hourOfDay: Int, triggerType: String, frequency: Int = 1) {
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
        self.triggerType = triggerType
        self.frequency = frequency
        self.lastDetected = Date()
    }
}
