import Foundation
import SwiftData

nonisolated enum RecurringFrequency: String, Codable, Sendable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var dayInterval: Int {
        switch self {
        case .weekly: 7
        case .biweekly: 14
        case .monthly: 30
        case .quarterly: 90
        case .yearly: 365
        }
    }

    var icon: String {
        switch self {
        case .weekly: "arrow.clockwise"
        case .biweekly: "arrow.2.squarepath"
        case .monthly: "calendar"
        case .quarterly: "calendar.badge.clock"
        case .yearly: "calendar.circle"
        }
    }
}

nonisolated enum ReminderPreference: String, Codable, Sendable, CaseIterable {
    case oneDay = "1 Day Before"
    case threeDays = "3 Days Before"
    case oneWeek = "1 Week Before"
    case none = "None"

    var daysBefore: Int? {
        switch self {
        case .oneDay: 1
        case .threeDays: 3
        case .oneWeek: 7
        case .none: nil
        }
    }
}

@Model
class RecurringExpense {
    var merchant: String
    var amount: Double
    var frequencyRaw: String
    var categoryRaw: String
    var nextDueDate: Date
    var reminderRaw: String
    var isActive: Bool
    var isPending: Bool
    var createdAt: Date
    var lastPaidDate: Date?
    var skippedDates: [Date]
    var paidDates: [Date]
    var notes: String

    init(
        merchant: String,
        amount: Double,
        frequency: RecurringFrequency,
        category: TransactionCategory,
        nextDueDate: Date,
        reminder: ReminderPreference = .oneDay,
        isActive: Bool = true,
        isPending: Bool = false
    ) {
        self.merchant = merchant
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.categoryRaw = category.rawValue
        self.nextDueDate = nextDueDate
        self.reminderRaw = reminder.rawValue
        self.isActive = isActive
        self.isPending = isPending
        self.createdAt = Date()
        self.lastPaidDate = nil
        self.skippedDates = []
        self.paidDates = []
        self.notes = ""
    }

    var frequency: RecurringFrequency {
        get { RecurringFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRaw) ?? .subscriptions }
        set { categoryRaw = newValue.rawValue }
    }

    var reminder: ReminderPreference {
        get { ReminderPreference(rawValue: reminderRaw) ?? .oneDay }
        set { reminderRaw = newValue.rawValue }
    }

    var totalPaid: Double {
        Double(paidDates.count) * amount
    }

    var averageAmount: Double {
        amount
    }

    var daysSinceLastPaid: Int? {
        guard let lastPaid = lastPaidDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastPaid, to: Date()).day
    }

    var isDueWithinWeek: Bool {
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return nextDueDate <= weekFromNow && nextDueDate >= Calendar.current.startOfDay(for: Date())
    }

    var isOverdue: Bool {
        nextDueDate < Calendar.current.startOfDay(for: Date())
    }

    var maybeUnused: Bool {
        guard let days = daysSinceLastPaid else {
            let daysSinceCreated = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
            return daysSinceCreated > 30
        }
        return days > 30 && frequency == .monthly
    }

    func markAsPaid() {
        paidDates.append(Date())
        lastPaidDate = Date()
        advanceDueDate()
    }

    func skipThisMonth() {
        skippedDates.append(nextDueDate)
        advanceDueDate()
    }

    private func advanceDueDate() {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            nextDueDate = calendar.date(byAdding: .day, value: 7, to: nextDueDate) ?? nextDueDate
        case .biweekly:
            nextDueDate = calendar.date(byAdding: .day, value: 14, to: nextDueDate) ?? nextDueDate
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
        case .quarterly:
            nextDueDate = calendar.date(byAdding: .month, value: 3, to: nextDueDate) ?? nextDueDate
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: nextDueDate) ?? nextDueDate
        }
    }
}
