import SwiftUI
import SwiftData

struct RecurringDetailSheet: View {
    @Bindable var expense: RecurringExpense
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var showDeleteConfirm = false
    @State private var paidHaptic = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.45).delay(0.05), value: appeared)

                    statsGrid
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.45).delay(0.1), value: appeared)

                    quickActions
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.45).delay(0.15), value: appeared)

                    settingsSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.45).delay(0.2), value: appeared)

                    paymentHistory
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.45).delay(0.25), value: appeared)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(expense.merchant)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .alert("Remove Recurring Expense?", isPresented: $showDeleteConfirm) {
                Button("Remove", role: .destructive) {
                    expense.isActive = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove \(expense.merchant) from your recurring expenses.")
            }
            .sensoryFeedback(.success, trigger: paidHaptic)
            .onAppear {
                withAnimation { appeared = true }
            }
        }
    }

    // MARK: - Hero

    private var categoryColor: Color {
        Color(hex: UInt(expense.category.color, radix: 16) ?? 0x6C5CE7)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(categoryColor.opacity(0.12))
                .frame(width: 72, height: 72)
                .overlay {
                    Text(expense.category.emoji)
                        .font(Typography.displayMedium)
                }

            Text("$\(Int(expense.amount))")
                .font(Typography.displayLarge)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 12) {
                Label(expense.frequency.rawValue, systemImage: expense.frequency.icon)
                    .font(Typography.labelSmall)
                    .foregroundStyle(categoryColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(categoryColor.opacity(0.12), in: .capsule)

                Label(expense.category.rawValue, systemImage: expense.category.icon)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.elevated, in: .capsule)
            }

            if expense.isOverdue {
                Label("Overdue", systemImage: "exclamationmark.circle.fill")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.danger.opacity(0.12), in: .capsule)
            } else {
                Text("Next due \(expense.nextDueDate, format: .dateTime.month(.abbreviated).day(.twoDigits).year())")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatCell(label: "Total Paid", value: "$\(Int(expense.totalPaid))", color: Theme.success)
            StatCell(label: "Payments", value: "\(expense.paidDates.count)", color: Theme.secondary)
            StatCell(label: "Skipped", value: "\(expense.skippedDates.count)", color: Theme.warning)
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    expense.markAsPaid()
                    paidHaptic.toggle()
                }
            } label: {
                Label("Mark Paid", systemImage: "checkmark.circle.fill")
                    .font(Typography.headingSmall)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.success, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))

            Button {
                withAnimation(.spring(response: 0.35)) {
                    expense.skipThisMonth()
                }
            } label: {
                Label("Skip", systemImage: "forward.fill")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.warning)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.warning.opacity(0.12), in: .rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.warning.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(SplurjButtonStyle(variant: .secondary, size: .medium))

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.danger)
                    .frame(width: 48, height: 48)
                    .background(Theme.danger.opacity(0.12), in: .rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.danger.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(SplurjButtonStyle(variant: .destructive, size: .medium))
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 0) {
                settingsRow(label: "Reminder") {
                    Picker("Reminder", selection: $expense.reminderRaw) {
                        ForEach(ReminderPreference.allCases, id: \.rawValue) { pref in
                            Text(pref.rawValue).tag(pref.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textSecondary)
                }

                Divider()
                    .background(Theme.border)

                settingsRow(label: "Frequency") {
                    Picker("Frequency", selection: $expense.frequencyRaw) {
                        ForEach(RecurringFrequency.allCases, id: \.rawValue) { freq in
                            Text(freq.rawValue).tag(freq.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textSecondary)
                }

                Divider()
                    .background(Theme.border)

                settingsRow(label: "Category") {
                    Picker("Category", selection: $expense.categoryRaw) {
                        ForEach(TransactionCategory.expenseCategories, id: \.rawValue) { cat in
                            Text(cat.rawValue).tag(cat.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.textSecondary)
                }
            }
            .splurjCard(.elevated)
        }
    }

    private func settingsRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Payment History

    private var paymentHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Payment History")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(expense.paidDates.count + expense.skippedDates.count) entries")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }

            let allEntries = buildHistoryEntries()

            if allEntries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textMuted)
                        Text("No payment history yet")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .splurjCard(.elevated)
            } else {
                VStack(spacing: 2) {
                    ForEach(allEntries) { entry in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(entry.isPaid ? Theme.success.opacity(0.15) : Theme.warning.opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: entry.isPaid ? "checkmark" : "forward.fill")
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(entry.isPaid ? Theme.success : Theme.warning)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.isPaid ? "Paid" : "Skipped")
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textMuted)
                            }

                            Spacer()

                            if entry.isPaid {
                                Text("$\(Int(expense.amount))")
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.success)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.card)
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Theme.border, lineWidth: 0.5)
                )
            }
        }
    }

    private func buildHistoryEntries() -> [HistoryEntry] {
        var entries: [HistoryEntry] = []

        for date in expense.paidDates {
            entries.append(HistoryEntry(date: date, isPaid: true))
        }
        for date in expense.skippedDates {
            entries.append(HistoryEntry(date: date, isPaid: false))
        }

        return entries.sorted { $0.date > $1.date }
    }
}

private struct HistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let isPaid: Bool
}

private struct StatCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Typography.headingLarge)
                .foregroundStyle(color)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .splurjCard(.elevated)
    }
}
