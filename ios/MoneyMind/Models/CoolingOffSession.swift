import Foundation
import SwiftData

@Model
class CoolingOffSession {
    var startDate: Date
    var durationSeconds: Int
    var completed: Bool

    init(durationSeconds: Int) {
        self.startDate = Date()
        self.durationSeconds = durationSeconds
        self.completed = false
    }

    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(durationSeconds))
    }

    var isActive: Bool {
        !completed && Date() < endDate
    }

    var remainingSeconds: Int {
        max(0, Int(endDate.timeIntervalSince(Date())))
    }
}
