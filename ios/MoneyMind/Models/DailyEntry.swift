import Foundation
import SwiftData

nonisolated enum DailyEntryType: String, Codable, Sendable {
    case checkIn
    case pledge
    case ema
    case reflection
}

nonisolated enum EMATimeOfDay: String, Codable, Sendable {
    case morning
    case afternoon
    case evening
}

@Model
class DailyEntry {
    var typeRaw: String
    var date: Date

    var mood: Int
    var urgeLevel: Int
    var didResist: Bool
    var note: String

    var quoteShown: String
    var completed: Bool

    var emaTypeRaw: String
    var urgeFloat: Float
    var moodString: String
    var spendingIntention: String
    var stuckToIntention: Bool

    var starRating: Int
    var triggers: [String]
    var urgeIntensity: Double
    var moneySavedToday: Double

    var entryType: DailyEntryType {
        get { DailyEntryType(rawValue: typeRaw) ?? .checkIn }
        set { typeRaw = newValue.rawValue }
    }

    var emaTime: EMATimeOfDay {
        get { EMATimeOfDay(rawValue: emaTypeRaw) ?? .morning }
        set { emaTypeRaw = newValue.rawValue }
    }

    init(type: DailyEntryType) {
        self.typeRaw = type.rawValue
        self.date = Date()
        self.mood = 3
        self.urgeLevel = 1
        self.didResist = true
        self.note = ""
        self.quoteShown = ""
        self.completed = false
        self.emaTypeRaw = EMATimeOfDay.morning.rawValue
        self.urgeFloat = 0
        self.moodString = ""
        self.spendingIntention = ""
        self.stuckToIntention = true
        self.starRating = 3
        self.triggers = []
        self.urgeIntensity = 0
        self.moneySavedToday = 0
    }

    static func checkIn(mood: Int = 3, urgeLevel: Int = 1, didResist: Bool = true, note: String = "") -> DailyEntry {
        let entry = DailyEntry(type: .checkIn)
        entry.mood = mood
        entry.urgeLevel = urgeLevel
        entry.didResist = didResist
        entry.note = note
        return entry
    }

    static func pledge(quoteShown: String = "", completed: Bool = false) -> DailyEntry {
        let entry = DailyEntry(type: .pledge)
        entry.quoteShown = quoteShown
        entry.completed = completed
        return entry
    }

    static func ema(time: EMATimeOfDay, urgeLevel: Float = 0, mood: String = "", spendingIntention: String = "", stuckToIntention: Bool = true) -> DailyEntry {
        let entry = DailyEntry(type: .ema)
        entry.emaTypeRaw = time.rawValue
        entry.urgeFloat = urgeLevel
        entry.moodString = mood
        entry.spendingIntention = spendingIntention
        entry.stuckToIntention = stuckToIntention
        return entry
    }

    static func reflection(starRating: Int = 3, triggers: [String] = [], urgeIntensity: Double = 0, moneySavedToday: Double = 0, note: String = "") -> DailyEntry {
        let entry = DailyEntry(type: .reflection)
        entry.starRating = starRating
        entry.triggers = triggers
        entry.urgeIntensity = urgeIntensity
        entry.moneySavedToday = moneySavedToday
        entry.note = note
        return entry
    }
}
