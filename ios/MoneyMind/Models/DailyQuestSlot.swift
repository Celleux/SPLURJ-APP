import Foundation
import SwiftData

@Model
class DailyQuestSlot {
    var questID: String = ""
    var cadence: String = "daily"
    var offeredDate: Date = Date()
    var isLuckyQuest: Bool = false
    var expiresAt: Date = Date()

    init(questID: String, cadence: String, offeredDate: Date, isLuckyQuest: Bool = false) {
        self.questID = questID
        self.cadence = cadence
        self.offeredDate = offeredDate
        self.isLuckyQuest = isLuckyQuest

        if cadence == "daily" {
            self.expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: offeredDate)) ?? offeredDate
        } else {
            self.expiresAt = Calendar.current.nextDate(after: offeredDate, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) ?? offeredDate
        }
    }
}
