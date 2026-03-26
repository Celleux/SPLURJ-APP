import SwiftUI
import SwiftData

struct AddBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [BudgetCategory]
    @Query private var profiles: [UserProfile]

    @State private var name: String = ""
    @State private var icon: String = "cart.fill"
    @State private var colorHex: String = "6C5CE7"
    @State private var monthlyLimit: String = ""
    @State private var saveTrigger: Bool = false

    private let iconOptions = [
        "cart.fill", "house.fill", "car.fill", "heart.fill",
        "book.fill", "gift.fill", "gamecontroller.fill", "tshirt.fill",
        "cup.and.saucer.fill", "airplane", "pawprint.fill", "wrench.fill",
        "music.note", "dumbbell.fill", "creditcard.fill", "leaf.fill"
    ]

    private let colorOptions = [
        "6C5CE7", "FF6B6B", "00D2FF", "00E676",
        "FF9100", "A55EEA", "54A0FF", "FFD700",
        "FF6348", "01A3A4", "5F27CD", "2ED573"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    previewCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Name")
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("e.g. Groceries", text: $name)
                            .font(Typography.bodyLarge)
                            .padding(14)
                            .background(Theme.elevated, in: .rect(cornerRadius: 12))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Budget")
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.textSecondary)
                        HStack {
                            Text(CurrencyHelper.symbol(for: profiles.first?.defaultCurrency ?? "USD"))
                                .font(Typography.headingLarge)
                                .foregroundStyle(Theme.textSecondary)
                            TextField("0", text: $monthlyLimit)
                                .font(Typography.headingLarge)
                                .keyboardType(.decimalPad)
                                .foregroundStyle(Theme.textPrimary)
                                .tint(Theme.accent)
                        }
                        .padding(14)
                        .background(Theme.elevated, in: .rect(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { ic in
                                Button {
                                    icon = ic
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(icon == ic ? selectedColor.opacity(0.2) : Theme.elevated)
                                            .frame(width: 40, height: 40)
                                        if icon == ic {
                                            Circle()
                                                .strokeBorder(selectedColor, lineWidth: 2)
                                                .frame(width: 40, height: 40)
                                        }
                                        Image(systemName: ic)
                                            .font(Typography.labelLarge)
                                            .foregroundStyle(icon == ic ? selectedColor : Theme.textSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(colorOptions, id: \.self) { hex in
                                let c = Color(hex: UInt(hex, radix: 16) ?? 0x6C5CE7)
                                Button {
                                    colorHex = hex
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(c)
                                            .frame(width: 36, height: 36)
                                        if colorHex == hex {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2.5)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "checkmark")
                                                .font(Typography.labelMedium)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .font(Typography.headingMedium)
                    .foregroundStyle(canSave ? Theme.accent : Theme.textMuted)
                    .disabled(!canSave)
                }
            }
            .sensoryFeedback(.success, trigger: saveTrigger)
        }
    }

    private var selectedColor: Color {
        Color(hex: UInt(colorHex, radix: 16) ?? 0x6C5CE7)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Double(monthlyLimit) ?? 0) > 0
    }

    private var previewCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 5)
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(Typography.headingLarge)
                    .foregroundStyle(selectedColor)
            }

            Text(name.isEmpty ? "Category" : name)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textPrimary)

            Text("$0 / $\(monthlyLimit.isEmpty ? "0" : monthlyLimit)")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .splurjCard(.elevated)
    }

    private func saveBudget() {
        guard canSave, let limit = Double(monthlyLimit) else { return }
        let budget = BudgetCategory(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            colorHex: colorHex,
            monthlyLimit: limit,
            sortOrder: budgets.count
        )
        modelContext.insert(budget)
        saveTrigger.toggle()
        dismiss()
    }
}
