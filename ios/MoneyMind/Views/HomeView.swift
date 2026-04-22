import SwiftUI
import SwiftData
import PhosphorSwift

struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var budgets: [BudgetCategory]
    @Query private var quizResults: [QuizResult]
    @Query(filter: #Predicate<InAppNotification> { !$0.isDismissed && !$0.isRead }) private var unreadNotifications: [InAppNotification]
    @State private var showLogWin = false
    @State private var showAddExpense = false
    @State private var showNotificationCenter = false
    @State private var appeared = false
    @State private var isLoading = true
    @State private var refreshRotation: Double = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(HealthKitService.self) private var healthKit

    private var profile: UserProfile? { profiles.first }
    private var currencyCode: String { profile?.defaultCurrency ?? "USD" }
    private var currencySymbol: String { CurrencyHelper.symbol(for: currencyCode) }

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private var characterLevel: Int {
        CharacterStage.level(from: profile?.xpPoints ?? 0)
    }

    private var totalSavedThisMonth: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return impulseLogs.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.amount }
    }

    private var totalSavedLastMonth: Double {
        let calendar = Calendar.current
        let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
        return impulseLogs.filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }.reduce(0) { $0 + $1.amount }
    }

    private var savedDifference: Double {
        totalSavedThisMonth - totalSavedLastMonth
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    if isLoading {
                        DashboardSkeletonView()
                            .padding(.horizontal)
                            .transition(.opacity)
                    } else if transactions.isEmpty && impulseLogs.isEmpty {
                        emptyState
                    } else {
                        dashboardContent
                    }
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    withAnimation(.linear(duration: 0.6)) { refreshRotation += 360 }
                    try? await Task.sleep(for: .seconds(0.5))
                }
                .sensoryFeedback(.impact(weight: .light), trigger: refreshRotation)

                floatingButtons
            }
            .background {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    SplurjSwoosh()
                        .fill(Theme.accent.opacity(0.03))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLogWin) {
                LogWinSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNotificationCenter) {
                NotificationCenterView { _ in }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(Theme.background)
            }
            .onAppear {
                if let profile {
                    premiumManager.updateInstallDate(profile.installDate)
                    profile.lastOpenDate = Date()
                    NotificationService.shared.scheduleAllNotifications(profile: profile)
                    NotificationService.shared.checkBudgetThresholds(
                        budgets: Array(budgets),
                        transactions: Array(transactions),
                        profile: profile,
                        modelContext: modelContext
                    )
                    if profile.currentStreak > 0 {
                        NotificationService.shared.celebrateStreak(
                            days: profile.currentStreak,
                            profile: profile,
                            modelContext: modelContext
                        )
                    }
                }
                ensureDefaultBudgets()
                Task {
                    try? await Task.sleep(for: .seconds(0.4))
                    withAnimation(Theme.springSnappy) { isLoading = false }
                }
                Task {
                    await healthKit.refresh()
                    if let profile {
                        healthKit.evaluateJITAI(profile: profile, modelContext: modelContext)
                    }
                }
            }
            .profileAvatarToolbar()
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        VStack(spacing: 20) {
            greetingHeader
            heroSavedCard
            HRVStateOfMindCard(service: healthKit) {
                Task { _ = await healthKit.requestAuthorization() }
            }
            .staggerIn(appeared: appeared, delay: 0.06)
            QuestOfTheDayCard()
                .staggerIn(appeared: appeared, delay: 0.08)
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
        .onAppear {
            withAnimation(Theme.springStagger) { appeared = true }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            greetingHeader
                .padding(.horizontal)
            PersonalityEmptyStateView(
                personality: personality,
                icon: "rocket.fill",
                secondaryIcon: "sparkles",
                headline: "Start Your Journey",
                subtext: "Add your first transaction or log a win\nto see your dashboard come alive",
                buttonLabel: "Add Your First Transaction",
                buttonIcon: "arrow.down.circle.fill"
            ) {
                showAddExpense = true
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greetingText), \(profile?.name ?? "Friend")")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: personality.icon)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.accent)
                    Text("\(personality.rawValue)")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                    Text("•")
                        .foregroundStyle(Theme.textMuted)
                    Text("Level \(characterLevel)")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            Button {
                showNotificationCenter = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.elevated)
                        .frame(width: 36, height: 36)
                        .overlay {
                            PhIcon.bellFill
                                .frame(width: 18, height: 18)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    if !unreadNotifications.isEmpty {
                        Text("\(min(unreadNotifications.count, 99))")
                            .font(Typography.labelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.danger, in: .capsule)
                            .offset(x: 4, y: -4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
        .staggerIn(appeared: appeared, delay: 0.0)
    }

    // MARK: - Hero Saved Card

    private var heroSavedCard: some View {
        AmbientLightView {
            ZStack {
                SplurjSwoosh()
                    .fill(Theme.accent.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .allowsHitTesting(false)

                VStack(spacing: 10) {
                    Text("Total Saved This Month")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)

                    AnimatedNumber(value: totalSavedThisMonth, format: .currency, font: Typography.moneyHero, color: Theme.accent)

                    HStack(spacing: 4) {
                        (savedDifference >= 0 ? PhIcon.arrowUpRight : PhIcon.arrowDownRight)
                            .frame(width: 12, height: 12)
                        Text("\(currencySymbol)\(abs(savedDifference), specifier: "%.0f") from last month")
                            .font(Typography.bodySmall)
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(savedDifference >= 0 ? Theme.accent : Theme.danger)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .splurjCard(.hero)
        }
        .staggerIn(appeared: appeared, delay: 0.04)
    }

    // MARK: - Floating Buttons

    private var floatingButtons: some View {
        HStack(spacing: 12) {
            Button {
                showLogWin = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Log Win")
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Theme.background)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Theme.accentGradient, in: .capsule)
            }
            .buttonStyle(.plain)

            Button {
                showAddExpense = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Expense")
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Theme.elevated, in: .capsule)
                .overlay { Capsule().strokeBorder(Theme.border, lineWidth: 1) }
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 16)
        .sensoryFeedback(.impact(weight: .light), trigger: showLogWin)
        .sensoryFeedback(.impact(weight: .light), trigger: showAddExpense)
    }

    // MARK: - Helpers

    private func ensureDefaultBudgets() {
        guard budgets.isEmpty else { return }
        for (i, def) in BudgetCategory.defaults.enumerated() {
            let budget = BudgetCategory(
                name: def.0,
                icon: def.1,
                colorHex: def.2,
                monthlyLimit: def.3,
                sortOrder: i
            )
            modelContext.insert(budget)
        }
    }
}

// MARK: - Home Quick Action Button

struct HomeQuickAction: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var hapticTrigger = false

    var body: some View {
        Button {
            hapticTrigger.toggle()
            action()
        } label: {
            HomeQuickActionLabel(icon: icon, label: label)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }
}

struct HomeQuickActionLabel: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.accent)
            }
            Text(label)
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(14)
        .splurjCard(.interactive)
    }
}

// MARK: - Stagger Animation Modifier

struct StaggeredAppearance: ViewModifier {
    let index: Int
    @State private var appeared: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .scaleEffect(appeared ? 1 : 0.95)
            .animation(
                reduceMotion
                    ? .none
                    : .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(index) * 0.08),
                value: appeared
            )
            .onAppear {
                guard !appeared else { return }
                appeared = true
            }
    }
}

extension View {
    func staggerIn(index: Int) -> some View {
        modifier(StaggeredAppearance(index: index))
    }

    func staggerIn(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: appeared)
    }
}

// MARK: - LogWinSheet

struct LogWinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var gachaStates: [GachaState]
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var scratchCardToast: ScratchCardToastData?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("What did you resist?")
                        .font(Typography.headingMedium)
                        .foregroundStyle(.primary)

                    TextField("Amount saved", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(Typography.displayMedium)
                        .multilineTextAlignment(.center)
                        .tint(Theme.accent)

                    TextField("What was the temptation?", text: $note)
                        .font(Typography.bodyLarge)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                Button {
                    guard let value = Double(amount), value > 0 else { return }
                    let log = ImpulseLog(amount: value, note: note, resisted: true)
                    modelContext.insert(log)
                    if let profile = profiles.first {
                        profile.totalSaved += value
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

                    dismiss()
                } label: {
                    Text("Log Win")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accentGradient, in: .capsule)
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .disabled(amount.isEmpty)
                .sensoryFeedback(.success, trigger: note)
            }
            .padding()
            .navigationTitle("Log a Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
        }
    }
}
