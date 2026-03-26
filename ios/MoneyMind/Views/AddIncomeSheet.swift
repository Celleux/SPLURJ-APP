import SwiftUI
import SwiftData

struct AddIncomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: TransactionCategory = .income
    @State private var hapticTrigger: Bool = false

    private let categories = TransactionCategory.incomeCategories

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("Amount received")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(CurrencyHelper.symbol(for: profiles.first?.defaultCurrency ?? "USD"))
                                .font(Typography.displayMedium)
                                .foregroundStyle(Theme.accentGreen.opacity(0.6))
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(Typography.displayLarge)
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 200)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Source")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)

                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                let catColor = Color(hex: UInt(cat.color, radix: 16) ?? 0x64748B)
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(catColor.opacity(selectedCategory == cat ? 0.25 : 0.1))
                                                .frame(width: 44, height: 44)
                                            Text(cat.emoji)
                                                .font(Typography.headingLarge)
                                        }
                                        Text(cat.rawValue)
                                            .font(Typography.labelSmall)
                                            .foregroundStyle(selectedCategory == cat ? Theme.textPrimary : Theme.textSecondary)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedCategory == cat ? Theme.elevated : Theme.card,
                                        in: .rect(cornerRadius: 12)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                selectedCategory == cat
                                                    ? catColor.opacity(0.4)
                                                    : Theme.border,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("Description", text: $note)
                            .font(Typography.bodyLarge)
                            .padding(14)
                            .background(Theme.elevated, in: .rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Theme.border, lineWidth: 0.5)
                            )
                    }

                    Button {
                        saveIncome()
                    } label: {
                        Text("Add Income")
                            .font(Typography.headingMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGreen.opacity(amount.isEmpty ? 0.4 : 1), in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    .disabled(amount.isEmpty)
                    .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func saveIncome() {
        guard let value = Double(amount), value > 0 else { return }
        let transaction = Transaction(
            amount: value,
            category: selectedCategory,
            note: note,
            type: .income
        )
        modelContext.insert(transaction)
        hapticTrigger.toggle()
        NotificationCenter.default.post(name: .transactionSaved, object: transaction)
        dismiss()
    }
}
