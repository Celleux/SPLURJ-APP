import Foundation
import SwiftData

@Model
class UrgeSurfSession {
    var date: Date
    var durationSeconds: Int

    init(durationSeconds: Int) {
        self.date = Date()
        self.durationSeconds = durationSeconds
    }
}
