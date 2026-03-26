import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var merchantMappings: [MerchantCategoryMapping]
    @Query(sort: \Transaction.date, order: .reverse) private var recentTransactions: [Transaction]

    @Query private var profiles: [UserProfile]
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var hapticTrigger: Bool = false
    @State private var showLearnPrompt: Bool = false
    @State private var learnMerchantName: String = ""

    private var currencySymbol: String { CurrencyHelper.symbol(for: profiles.first?.defaultCurrency ?? "USD") }

    private let categories = TransactionCategory.expenseCategories
    @State private var engine = CategoryMLEngine()

    private var smartSuggestions: [TransactionCategory] {
        let recentCats = recentTransactions
            .filter { $0.transactionType == .expense }
            .prefix(10)
            .map(\.transactionCategory)
        return engine.suggestCategories(
            note: note,
            amount: Double(amount),
            date: Date(),
            recentCategories: Array(recentCats),
            userMappings: merchantMappings
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("How much?")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(currencySymbol)
                                .font(Typography.displayMedium)
                                .foregroundStyle(Theme.textMuted)
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

                    if !smartSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(Typography.bodySmall)
                                    .foregroundStyle(Theme.accent)
                                Text("Suggested")
                                    .font(Typography.bodySmall)
                                    .foregroundStyle(Theme.textMuted)
                            }

                            HStack(spacing: 8) {
                                ForEach(smartSuggestions, id: \.self) { cat in
                                    let catColor = Color(hex: UInt(cat.color, radix: 16) ?? 0x64748B)
                                    Button {
                                        selectedCategory = cat
                                        hapticTrigger.toggle()
                                    } label: {
                                        HStack(spacing: 5) {
                                            Text(cat.emoji)
                                                .font(Typography.bodyMedium)
                                            Text(cat.rawValue)
                                                .font(Typography.bodySmall)
                                                .foregroundStyle(selectedCategory == cat ? .white : Theme.textSecondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == cat ? catColor.opacity(0.8) : Theme.card,
                                            in: .capsule
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(selectedCategory == cat ? catColor : Theme.border, lineWidth: 0.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .animation(Theme.spring, value: smartSuggestions)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 90), spacing: 10)
                        ], spacing: 10) {
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
                                            .lineLimit(1)
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
                        Text("Merchant / Note (optional)")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("What was this for?", text: $note)
                            .font(Typography.bodyLarge)
                            .padding(14)
                            .background(Theme.elevated, in: .rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Theme.border, lineWidth: 0.5)
                            )
                    }

                    Button {
                        saveExpense()
                    } label: {
                        Text("Add Expense")
                            .font(Typography.headingMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.danger.opacity(amount.isEmpty ? 0.4 : 1), in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .destructive, size: .large))
                    .disabled(amount.isEmpty)
                    .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .alert("Learn this category?", isPresented: $showLearnPrompt) {
                Button("Always") {
                    engine.learnMapping(merchantKeyword: learnMerchantName, category: selectedCategory, context: modelContext)
                    engine.applyCategoryRetroactively(merchantKeyword: learnMerchantName, newCategory: selectedCategory, context: modelContext)
                }
                Button("Just this time", role: .cancel) {}
            } message: {
                Text("Always categorize \"\(learnMerchantName)\" as \(selectedCategory.rawValue)?")
            }
            .onChange(of: note) { _, newValue in
                if !newValue.isEmpty {
                    if let matched = engine.matchMerchant(note: newValue, userMappings: merchantMappings) {
                        withAnimation(Theme.spring) {
                            selectedCategory = matched
                        }
                    }
                }
            }
        }
    }

    private func saveExpense() {
        guard let value = Double(amount), value > 0 else { return }
        let transaction = Transaction(
            amount: value,
            category: selectedCategory,
            note: note,
            type: .expense
        )
        modelContext.insert(transaction)

        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        if !trimmedNote.isEmpty {
            let matched = engine.matchMerchant(note: trimmedNote, userMappings: merchantMappings)
            if matched == nil || matched != selectedCategory {
                learnMerchantName = trimmedNote
                showLearnPrompt = true
            }
        }

        hapticTrigger.toggle()
        NotificationCenter.default.post(name: .transactionSaved, object: transaction)
        if learnMerchantName.isEmpty {
            dismiss()
        }
    }
}
