import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Query private var recurringExpenses: [RecurringExpense]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var quizResults: [QuizResult]
    @Query private var profiles: [UserProfile]
    @State private var vm = RecurringExpenseViewModel()
    @Environment(\.modelContext) private var modelContext

    private var currencyCode: String { profiles.first?.defaultCurrency ?? "USD" }
    private var currencySymbol: String { CurrencyHelper.symbol(for: currencyCode) }

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    var body: some View {
        ScrollView {
            if recurringExpenses.filter({ $0.isActive || $0.isPending }).isEmpty {
                emptyState
            } else {
                VStack(spacing: 20) {
                    headerSection
                        .staggerIn(appeared: vm.appeared, delay: 0.0)

                    viewModePicker
                        .staggerIn(appeared: vm.appeared, delay: 0.05)

                    pendingDetections
                        .staggerIn(appeared: vm.appeared, delay: 0.1)

                    unusedWarnings
                        .staggerIn(appeared: vm.appeared, delay: 0.12)

                    if vm.viewMode == .list {
                        listSection
                            .staggerIn(appeared: vm.appeared, delay: 0.18)
                    } else {
                        calendarSection
                            .staggerIn(appeared: vm.appeared, delay: 0.18)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Recurring Expenses")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $vm.selectedExpense) { expense in
            RecurringDetailSheet(expense: expense)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .onAppear {
            vm.runDetection(transactions: transactions, existing: recurringExpenses, context: modelContext)
            vm.scheduleNotifications(recurringExpenses)
            withAnimation(.easeOut(duration: 0.1)) {
                vm.appeared = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        PersonalityEmptyStateView(
            personality: personality,
            icon: "arrow.triangle.2.circlepath",
            secondaryIcon: "calendar.badge.clock",
            headline: "No Recurring Expenses",
            subtext: "Add transactions regularly and we'll\nautomatically detect your subscriptions & bills",
            buttonLabel: nil,
            buttonIcon: nil
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(Typography.headingLarge)
                    .foregroundStyle(personality.color)
                Text("Monthly Recurring")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()

                let count = vm.sortedExpenses(recurringExpenses).count
                Text("\(count) active")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.elevated, in: .capsule)
            }

            let total = vm.totalMonthlyRecurring(recurringExpenses)
            Text(total, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(Typography.displayLarge)
                .foregroundStyle(personality.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText(value: total))

            let pct = vm.incomePercentage(recurringExpenses, transactions: transactions)
            if pct > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "chart.pie.fill")
                        .font(Typography.labelSmall)
                    Text("\(pct, specifier: "%.0f")% of your income")
                        .font(Typography.labelSmall)
                }
                .foregroundStyle(pct > 50 ? Theme.danger : Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .splurjCard(.hero)
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(RecurringViewMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.viewMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .list ? "list.bullet" : "calendar")
                            .font(Typography.labelSmall)
                        Text(mode.rawValue)
                            .font(Typography.bodyMedium)
                    }
                    .foregroundStyle(vm.viewMode == mode ? Theme.textPrimary : Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        vm.viewMode == mode ? Theme.elevated : Color.clear,
                        in: .rect(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .splurjCard(.subtle)
    }

    // MARK: - Pending Detections

    @ViewBuilder
    private var pendingDetections: some View {
        let pending = vm.pendingExpenses(recurringExpenses)
        if !pending.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.gold)
                    Text("Detected Patterns")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                }

                ForEach(pending) { expense in
                    DetectionBannerCard(expense: expense) {
                        withAnimation(.spring(response: 0.35)) {
                            vm.acceptSuggestion(expense)
                        }
                    } onDismiss: {
                        withAnimation(.spring(response: 0.35)) {
                            vm.dismissSuggestion(expense, context: modelContext)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Unused Warnings

    @ViewBuilder
    private var unusedWarnings: some View {
        let unused = vm.unusedSuggestions(recurringExpenses)
        if !unused.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(unused) { expense in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.warning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.merchant)
                                .font(Typography.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Text("No activity in 30+ days. Consider cancelling?")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer()

                        Button {
                            vm.removeExpense(expense, context: modelContext)
                        } label: {
                            Text("Remove")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.danger)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.danger.opacity(0.12), in: .capsule)
                        }
                    }
                    .padding(14)
                    .background(Theme.warning.opacity(0.06), in: .rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.warning.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - List Section

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("All Recurring")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()

                Menu {
                    ForEach(RecurringSortOption.allCases, id: \.rawValue) { option in
                        Button {
                            vm.sortOption = option
                        } label: {
                            Label(option.rawValue, systemImage: vm.sortOption == option ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(Typography.labelSmall)
                        Text(vm.sortOption.rawValue)
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.elevated, in: .capsule)
                }
            }

            let sorted = vm.sortedExpenses(recurringExpenses)
            if sorted.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textMuted)
                        Text("No confirmed recurring expenses yet")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                VStack(spacing: 2) {
                    ForEach(sorted) { expense in
                        RecurringExpenseRow(expense: expense) {
                            vm.selectedExpense = expense
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation { vm.removeExpense(expense, context: modelContext) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }

                            Button {
                                withAnimation { vm.skipMonth(expense) }
                            } label: {
                                Label("Skip", systemImage: "forward.fill")
                            }
                            .tint(Theme.warning)

                            Button {
                                withAnimation { vm.markAsPaid(expense) }
                            } label: {
                                Label("Paid", systemImage: "checkmark.circle.fill")
                            }
                            .tint(Theme.success)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 16) {
            calendarHeader
            calendarGrid
            calendarDateDetail
        }
    }

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) { vm.previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.elevated, in: .circle)
            }

            Spacer()

            Text(vm.monthTitle)
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { vm.nextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.elevated, in: .circle)
            }
        }
    }

    private var calendarGrid: some View {
        let days = vm.calendarDays()
        let expenseDates = vm.expenseDatesInMonth(recurringExpenses)
        let weekdays = Calendar.current.shortWeekdaySymbols

        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day.prefix(2))
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(days) { day in
                    CalendarDayCell(
                        day: day,
                        expenseDates: expenseDates,
                        selectedDate: vm.selectedCalendarDate,
                        accentColor: personality.color
                    ) { date in
                        withAnimation(.spring(response: 0.3)) {
                            vm.selectedCalendarDate = date
                        }
                    }
                }
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    @ViewBuilder
    private var calendarDateDetail: some View {
        if let selectedDate = vm.selectedCalendarDate {
            let dateExpenses = vm.expensesForDate(selectedDate, expenses: recurringExpenses)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(selectedDate, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()

                    if !dateExpenses.isEmpty {
                        let total = dateExpenses.reduce(0.0) { $0 + $1.amount }
                        Text("\(currencySymbol)\(Int(total))")
                            .font(Typography.headingSmall)
                            .foregroundStyle(personality.color)
                    }
                }

                if dateExpenses.isEmpty {
                    HStack {
                        Spacer()
                        Text("No expenses due this day")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                            .padding(.vertical, 12)
                        Spacer()
                    }
                } else {
                    ForEach(dateExpenses) { expense in
                        Button {
                            vm.selectedExpense = expense
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: UInt(expense.category.color, radix: 16) ?? 0x6C5CE7))
                                    .frame(width: 8, height: 8)

                                Text(expense.merchant)
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.textPrimary)

                                Spacer()

                                Text("\(currencySymbol)\(Int(expense.amount))")
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .splurjCard(.elevated)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let day: CalendarDay
    let expenseDates: [Date: [RecurringExpense]]
    let selectedDate: Date?
    let accentColor: Color
    let onSelect: (Date) -> Void

    var body: some View {
        if let date = day.date {
            let dayExpenses = expenseDates[Calendar.current.startOfDay(for: date)] ?? []
            let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false

            Button {
                onSelect(date)
            } label: {
                VStack(spacing: 3) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: day.isToday ? .bold : .regular))
                        .foregroundStyle(dayTextColor(isSelected: isSelected))

                    dotsRow(dayExpenses)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(bgColor(isSelected: isSelected), in: .rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor(isSelected: isSelected), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(height: 40)
        }
    }

    private func dotsRow(_ expenses: [RecurringExpense]) -> some View {
        HStack(spacing: 2) {
            ForEach(expenses.prefix(3)) { expense in
                Circle()
                    .fill(Color(hex: UInt(expense.category.color, radix: 16) ?? 0x6C5CE7))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 4)
    }

    private func dayTextColor(isSelected: Bool) -> Color {
        if day.isToday { return accentColor }
        if isSelected { return Theme.textPrimary }
        return Theme.textSecondary
    }

    private func bgColor(isSelected: Bool) -> Color {
        if day.isToday { return accentColor.opacity(0.12) }
        if isSelected { return Theme.elevated }
        if day.isCurrentWeek { return Theme.card.opacity(0.6) }
        return Color.clear
    }

    private func borderColor(isSelected: Bool) -> Color {
        if day.isToday { return accentColor.opacity(0.4) }
        if isSelected { return Theme.border }
        return Color.clear
    }
}

// MARK: - Detection Banner Card

private struct DetectionBannerCard: View {
    let expense: RecurringExpense
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: UInt(expense.category.color, radix: 16) ?? 0x6C5CE7).opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(expense.category.emoji)
                        .font(Typography.bodyLarge)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Is \(expense.merchant) recurring?")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(CurrencyHelper.symbol(for: "USD"))\(Int(expense.amount))/\(expense.frequency.rawValue.lowercased())")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(Theme.elevated, in: .circle)
                }

                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark")
                        .font(Typography.labelSmall)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Theme.success, in: .circle)
                }
            }
        }
        .padding(14)
        .background(Theme.gold.opacity(0.04), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.gold.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Recurring Expense Row

private struct RecurringExpenseRow: View {
    let expense: RecurringExpense
    let onTap: () -> Void

    private var categoryColor: Color {
        Color(hex: UInt(expense.category.color, radix: 16) ?? 0x6C5CE7)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(expense.category.emoji)
                            .font(Typography.headingLarge)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.merchant)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(expense.frequency.rawValue)
                            .font(Typography.labelSmall)
                            .foregroundStyle(categoryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.12), in: .capsule)

                        if expense.isOverdue {
                            Text("OVERDUE")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.danger)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.danger.opacity(0.12), in: .capsule)
                        } else {
                            Text("Due \(expense.nextDueDate, format: .dateTime.month(.abbreviated).day())")
                                .font(Typography.labelSmall)
                                .foregroundStyle(expense.isDueWithinWeek ? Theme.warning : Theme.textMuted)
                        }
                    }
                }

                Spacer()

                Text("\(CurrencyHelper.symbol(for: "USD"))\(Int(expense.amount))")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.card)
        }
        .buttonStyle(.plain)
    }
}
