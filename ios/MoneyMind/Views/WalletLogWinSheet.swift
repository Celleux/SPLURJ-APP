import SwiftUI
import SwiftData

struct WalletLogWinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var gachaStates: [GachaState]
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedTrigger: String = ""
    @State private var scratchCardToast: ScratchCardToastData?

    let onSaved: (Double) -> Void
    @State private var showShareWin = false
    @State private var savedAmount: Double = 0
    @State private var savedNote: String = ""
    @State private var savedTrigger: String = ""

    private let triggers = ["Boredom", "Stress", "Social Pressure", "FOMO", "Habit", "Reward"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("What did you resist?")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Every resist is a win worth celebrating")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Text(CurrencyHelper.symbol(for: profiles.first?.defaultCurrency ?? "USD"))
                                .font(Typography.displayMedium)
                                .foregroundStyle(Theme.accentGreen)
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(Typography.displayMedium)
                                .foregroundStyle(Theme.textPrimary)
                                .tint(Theme.accentGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .splurjCard(.elevated)
                    }

                    TextField("What was the temptation? (optional)", text: $note)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.accentGreen)
                        .padding(16)
                        .splurjCard(.outlined)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What triggered it?")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 90), spacing: 8)
                        ], spacing: 8) {
                            ForEach(triggers, id: \.self) { trigger in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTrigger = selectedTrigger == trigger ? "" : trigger
                                    }
                                } label: {
                                    Text(trigger)
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(selectedTrigger == trigger ? Theme.background : Theme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedTrigger == trigger ? Theme.accentGreen : Theme.cardSurface,
                                            in: .capsule
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    selectedTrigger == trigger ? Theme.accentGreen : Theme.textSecondary.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .sensoryFeedback(.selection, trigger: selectedTrigger)
                                .accessibilityLabel("Trigger: \(trigger)")
                            }
                        }
                    }

                    Button {
                        saveWin()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(Typography.bodyLarge)
                            Text("I Saved This!")
                                .font(Typography.headingMedium)
                        }
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(amount.isEmpty)
                    .opacity(amount.isEmpty ? 0.5 : 1)
                    .sensoryFeedback(.impact(weight: .medium), trigger: savedAmount)
                    .accessibilityLabel("Save this win")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Log a Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .overlay(alignment: .top) {
            if let toast = scratchCardToast {
                ScratchCardToast(data: toast) {
                    withAnimation { scratchCardToast = nil }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showShareWin, onDismiss: { dismiss() }) {
            ShareWinSheet(
                amount: savedAmount,
                itemName: savedNote,
                trigger: savedTrigger,
                hourlyRate: profiles.first?.hourlyRate ?? 20
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func saveWin() {
        guard let value = Double(amount), value > 0 else { return }
        let log = ImpulseLog(amount: value, note: note, resisted: true, emotionalTrigger: selectedTrigger)
        modelContext.insert(log)
        if let profile = profiles.first {
            profile.totalSaved += value
            profile.xpPoints += 25
        }

        let engine = GachaEngine()
        if let state = gachaStates.first {
            engine.syncFromState(state)
        }
        let currency = profiles.first?.defaultCurrency ?? "USD"
        if let result = ScratchCardService.earnScratchCard(
            resistedAmount: value,
            currency: currency,
            engine: engine,
            gachaState: gachaStates.first,
            modelContext: modelContext
        ) {
            scratchCardToast = ScratchCardToastData(isGlowing: result.isGlowing)
        }

        savedAmount = value
        savedNote = note
        savedTrigger = selectedTrigger
        onSaved(value)
        showShareWin = true
    }
}
