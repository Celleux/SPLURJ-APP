import Foundation
import SwiftData
import UserNotifications

@Observable
class RecurringExpenseDetector {

    func detectRecurringPatterns(transactions: [Transaction], existingRecurring: [RecurringExpense]) -> [RecurringExpense] {
        let expenses = transactions.filter { $0.transactionType == .expense }
        let grouped = Dictionary(grouping: expenses) { merchantKey($0) }
        var suggestions: [RecurringExpense] = []
        let existingMerchants = Set(existingRecurring.map { $0.merchant.lowercased() })

        for (merchant, txns) in grouped where txns.count >= 2 {
            let normalizedMerchant = txns.first?.note.isEmpty == true ? txns.first?.category ?? merchant : merchant
            guard !existingMerchants.contains(normalizedMerchant.lowercased()) else { continue }

            let sorted = txns.sorted { $0.date < $1.date }
            guard let detected = detectFrequency(sorted) else { continue }

            let avgAmount = sorted.reduce(0.0) { $0 + $1.amount } / Double(sorted.count)
            let lastDate = sorted.last?.date ?? Date()
            let nextDue = calculateNextDueDate(lastDate: lastDate, frequency: detected)
            let category = TransactionCategory(rawValue: sorted.first?.category ?? "") ?? .subscriptions

            let expense = RecurringExpense(
                merchant: normalizedMerchant.isEmpty ? (sorted.first?.transactionCategory.rawValue ?? "Unknown") : normalizedMerchant,
                amount: (avgAmount * 100).rounded() / 100,
                frequency: detected,
                category: category,
                nextDueDate: nextDue,
                isPending: true
            )
            suggestions.append(expense)
        }

        return suggestions
    }

    func scheduleBillReminders(expenses: [RecurringExpense]) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let billIds = requests.filter { $0.identifier.hasPrefix("bill_") }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: billIds)
        }

        let active = expenses.filter { $0.isActive && !$0.isPending }

        for expense in active {
            guard let daysBefore = expense.reminder.daysBefore else { continue }
            guard let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expense.nextDueDate) else { continue }
            guard reminderDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Bill Reminder"
            content.body = "\(expense.merchant) ($\(Int(expense.amount))) is due \(daysBefore == 1 ? "tomorrow" : "in \(daysBefore) days")."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
            var triggerComponents = components
            triggerComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "bill_\(expense.merchant.hashValue)", content: content, trigger: trigger)
            center.add(request)
        }

        scheduleMonthSummary(expenses: active)
    }

    private func scheduleMonthSummary(expenses: [RecurringExpense]) {
        guard !expenses.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let thisMonthExpenses = expenses.filter { $0.nextDueDate >= startOfMonth && $0.nextDueDate <= endOfMonth }
        let total = thisMonthExpenses.reduce(0.0) { $0 + $1.amount }

        guard total > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Monthly Recurring Summary"
        content.body = "You have \(thisMonthExpenses.count) recurring expenses totaling $\(Int(total)) this month."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 10
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "bill_monthly_summary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Private

    private func merchantKey(_ transaction: Transaction) -> String {
        let note = transaction.note.lowercased().trimmingCharacters(in: .whitespaces)
        return note.isEmpty ? transaction.category.lowercased() : note
    }

    private func detectFrequency(_ sorted: [Transaction]) -> RecurringFrequency? {
        guard sorted.count >= 2 else { return nil }

        var intervals: [Int] = []
        for i in 1..<sorted.count {
            let days = Calendar.current.dateComponents([.day], from: sorted[i-1].date, to: sorted[i].date).day ?? 0
            intervals.append(days)
        }

        let avgInterval = Double(intervals.reduce(0, +)) / Double(intervals.count)

        if avgInterval >= 3 && avgInterval <= 10 { return .weekly }
        if avgInterval >= 11 && avgInterval <= 18 { return .biweekly }
        if avgInterval >= 25 && avgInterval <= 38 { return .monthly }
        if avgInterval >= 80 && avgInterval <= 100 { return .quarterly }
        if avgInterval >= 350 && avgInterval <= 380 { return .yearly }

        let amountVariance = Set(sorted.map { Int($0.amount) }).count <= 2
        if amountVariance && avgInterval >= 25 && avgInterval <= 45 {
            return .monthly
        }

        return nil
    }

    private func calculateNextDueDate(lastDate: Date, frequency: RecurringFrequency) -> Date {
        let calendar = Calendar.current
        var next: Date

        switch frequency {
        case .weekly:
            next = calendar.date(byAdding: .day, value: 7, to: lastDate) ?? lastDate
        case .biweekly:
            next = calendar.date(byAdding: .day, value: 14, to: lastDate) ?? lastDate
        case .monthly:
            next = calendar.date(byAdding: .month, value: 1, to: lastDate) ?? lastDate
        case .quarterly:
            next = calendar.date(byAdding: .month, value: 3, to: lastDate) ?? lastDate
        case .yearly:
            next = calendar.date(byAdding: .year, value: 1, to: lastDate) ?? lastDate
        }

        while next < Date() {
            switch frequency {
            case .weekly:
                next = calendar.date(byAdding: .day, value: 7, to: next) ?? next
            case .biweekly:
                next = calendar.date(byAdding: .day, value: 14, to: next) ?? next
            case .monthly:
                next = calendar.date(byAdding: .month, value: 1, to: next) ?? next
            case .quarterly:
                next = calendar.date(byAdding: .month, value: 3, to: next) ?? next
            case .yearly:
                next = calendar.date(byAdding: .year, value: 1, to: next) ?? next
            }
        }

        return next
    }
}
