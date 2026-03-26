import SwiftUI
import SwiftData

nonisolated enum RecurringSortOption: String, CaseIterable, Sendable {
    case dueDate = "Due Date"
    case amount = "Amount"
    case category = "Category"
}

nonisolated enum RecurringViewMode: String, CaseIterable, Sendable {
    case list = "List"
    case calendar = "Calendar"
}

@Observable
class RecurringExpenseViewModel {
    var viewMode: RecurringViewMode = .list
    var sortOption: RecurringSortOption = .dueDate
    var appeared = false
    var selectedExpense: RecurringExpense?
    var selectedCalendarDate: Date?
    var calendarMonth: Date = Date()
    var showSortMenu = false
    var detectionRan = false

    private let detector = RecurringExpenseDetector()

    func sortedExpenses(_ expenses: [RecurringExpense]) -> [RecurringExpense] {
        let active = expenses.filter { $0.isActive && !$0.isPending }
        switch sortOption {
        case .dueDate:
            return active.sorted { $0.nextDueDate < $1.nextDueDate }
        case .amount:
            return active.sorted { $0.amount > $1.amount }
        case .category:
            return active.sorted { $0.categoryRaw < $1.categoryRaw }
        }
    }

    func pendingExpenses(_ expenses: [RecurringExpense]) -> [RecurringExpense] {
        expenses.filter { $0.isPending }
    }

    func unusedSuggestions(_ expenses: [RecurringExpense]) -> [RecurringExpense] {
        expenses.filter { $0.isActive && !$0.isPending && $0.maybeUnused }
    }

    func totalMonthlyRecurring(_ expenses: [RecurringExpense]) -> Double {
        let active = expenses.filter { $0.isActive && !$0.isPending }
        return active.reduce(0.0) { total, expense in
            switch expense.frequency {
            case .weekly: total + expense.amount * 4.33
            case .biweekly: total + expense.amount * 2.17
            case .monthly: total + expense.amount
            case .quarterly: total + expense.amount / 3.0
            case .yearly: total + expense.amount / 12.0
            }
        }
    }

    func incomePercentage(_ expenses: [RecurringExpense], transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let monthlyIncome = transactions
            .filter { $0.transactionType == .income && $0.date >= startOfMonth }
            .reduce(0.0) { $0 + $1.amount }
        guard monthlyIncome > 0 else { return 0 }
        return (totalMonthlyRecurring(expenses) / monthlyIncome) * 100
    }

    func runDetection(transactions: [Transaction], existing: [RecurringExpense], context: ModelContext) {
        guard !detectionRan else { return }
        detectionRan = true

        let suggestions = detector.detectRecurringPatterns(transactions: transactions, existingRecurring: existing)
        for suggestion in suggestions {
            context.insert(suggestion)
        }
    }

    func acceptSuggestion(_ expense: RecurringExpense) {
        expense.isPending = false
    }

    func dismissSuggestion(_ expense: RecurringExpense, context: ModelContext) {
        context.delete(expense)
    }

    func markAsPaid(_ expense: RecurringExpense) {
        expense.markAsPaid()
    }

    func skipMonth(_ expense: RecurringExpense) {
        expense.skipThisMonth()
    }

    func removeExpense(_ expense: RecurringExpense, context: ModelContext) {
        expense.isActive = false
    }

    func scheduleNotifications(_ expenses: [RecurringExpense]) {
        detector.scheduleBillReminders(expenses: expenses)
    }

    // MARK: - Calendar

    func calendarDays() -> [CalendarDay] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendarMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [CalendarDay] = []

        for _ in 0..<leadingBlanks {
            days.append(CalendarDay(date: nil, isToday: false, isCurrentWeek: false))
        }

        let today = calendar.startOfDay(for: Date())
        let currentWeekOfYear = calendar.component(.weekOfYear, from: today)

        for day in range {
            let date = calendar.date(bySetting: .day, value: day, of: startOfMonth)!
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: today)
            let isCurrentWeek = weekOfYear == currentWeekOfYear && sameYear

            days.append(CalendarDay(date: date, isToday: isToday, isCurrentWeek: isCurrentWeek))
        }

        return days
    }

    func expensesForDate(_ date: Date, expenses: [RecurringExpense]) -> [RecurringExpense] {
        let calendar = Calendar.current
        let active = expenses.filter { $0.isActive && !$0.isPending }
        return active.filter { calendar.isDate($0.nextDueDate, inSameDayAs: date) }
    }

    func expenseDatesInMonth(_ expenses: [RecurringExpense]) -> [Date: [RecurringExpense]] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendarMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        let active = expenses.filter { $0.isActive && !$0.isPending }

        var result: [Date: [RecurringExpense]] = [:]

        for expense in active {
            var checkDate = expense.nextDueDate
            while checkDate < startOfMonth {
                switch expense.frequency {
                case .weekly: checkDate = calendar.date(byAdding: .day, value: 7, to: checkDate) ?? checkDate
                case .biweekly: checkDate = calendar.date(byAdding: .day, value: 14, to: checkDate) ?? checkDate
                case .monthly: checkDate = calendar.date(byAdding: .month, value: 1, to: checkDate) ?? checkDate
                case .quarterly: checkDate = calendar.date(byAdding: .month, value: 3, to: checkDate) ?? checkDate
                case .yearly: checkDate = calendar.date(byAdding: .year, value: 1, to: checkDate) ?? checkDate
                }
            }

            while checkDate <= endOfMonth {
                let day = calendar.startOfDay(for: checkDate)
                result[day, default: []].append(expense)

                switch expense.frequency {
                case .weekly: checkDate = calendar.date(byAdding: .day, value: 7, to: checkDate) ?? checkDate
                case .biweekly: checkDate = calendar.date(byAdding: .day, value: 14, to: checkDate) ?? checkDate
                case .monthly: checkDate = calendar.date(byAdding: .month, value: 1, to: checkDate) ?? checkDate
                case .quarterly: checkDate = calendar.date(byAdding: .month, value: 3, to: checkDate) ?? checkDate
                case .yearly: checkDate = calendar.date(byAdding: .year, value: 1, to: checkDate) ?? checkDate
                }
            }
        }

        return result
    }

    func previousMonth() {
        calendarMonth = Calendar.current.date(byAdding: .month, value: -1, to: calendarMonth) ?? calendarMonth
    }

    func nextMonth() {
        calendarMonth = Calendar.current.date(byAdding: .month, value: 1, to: calendarMonth) ?? calendarMonth
    }

    var monthTitle: String {
        calendarMonth.formatted(.dateTime.month(.wide).year())
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
    let isToday: Bool
    let isCurrentWeek: Bool
}
