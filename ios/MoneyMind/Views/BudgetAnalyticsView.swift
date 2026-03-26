import SwiftUI
import SwiftData

struct BudgetAnalyticsView: View {
    @Query private var budgets: [BudgetCategory]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var quizResults: [QuizResult]
    @Environment(PremiumManager.self) private var premiumManager
    @State private var vm = BudgetAnalyticsViewModel()
    @State private var showTemplates = false
    @State private var showRecurring = false
    @State private var showGhostBudget = false
    @Environment(\.modelContext) private var modelContext

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private var categories: [CategorySpending] {
        vm.categorySpending(budgets: budgets, transactions: transactions)
    }

    private var totalSpent: Double {
        vm.totalSpent(budgets: budgets, transactions: transactions)
    }

    private var totalBudget: Double {
        vm.totalBudget(budgets: budgets)
    }

    private var overallProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return totalSpent / totalBudget
    }

    private var remaining: Double {
        max(totalBudget - totalSpent, 0)
    }

    var body: some View {
        ScrollView {
            if budgets.isEmpty {
                emptyState
            } else {
                VStack(spacing: 20) {
                    monthSelector
                        .staggerIn(appeared: vm.appeared, delay: 0.0)

                    if vm.hasOverBudget(categories: categories) {
                        overBudgetBanner
                            .staggerIn(appeared: vm.appeared, delay: 0.05)
                    }

                    heroRing
                        .staggerIn(appeared: vm.appeared, delay: 0.08)

                    categoryGrid
                        .staggerIn(appeared: vm.appeared, delay: 0.16)

                    DonutChartView(segments: categories, selectedIndex: $vm.selectedDonutIndex)
                        .staggerIn(appeared: vm.appeared, delay: 0.24)

                    SpendingTrendChartView(
                        data: vm.monthlySpendingTrend(transactions: transactions),
                        isCurrentMonthSelected: vm.isCurrentMonth
                    )
                    .staggerIn(appeared: vm.appeared, delay: 0.32)

                    recurringExpensesCard
                        .staggerIn(appeared: vm.appeared, delay: 0.36)

                    ghostBudgetCard
                        .staggerIn(appeared: vm.appeared, delay: 0.44)
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Budget & Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $vm.selectedBudget) { budget in
            BudgetDetailSheet(budget: budget, spent: vm.selectedBudgetSpent)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showAddBudget) {
            AddBudgetSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTemplates) {
            BudgetTemplateSelectionView()
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRecurring) {
            NavigationStack {
                RecurringExpensesView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { showRecurring = false } label: {
                                Image(systemName: "xmark")
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 30, height: 30)
                                    .background(Theme.elevated, in: .circle)
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showGhostBudget) {
            NavigationStack {
                GhostBudgetView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { showGhostBudget = false } label: {
                                Image(systemName: "xmark")
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 30, height: 30)
                                    .background(Theme.elevated, in: .circle)
                            }
                        }
                    }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: vm.monthChangeTrigger)
        .onAppear {
            withAnimation(.easeOut(duration: 0.1)) {
                vm.appeared = true
            }
        }
    }

    // MARK: - Recurring Expenses Card

    private var recurringExpensesCard: some View {
        Button { showRecurring = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.secondary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Recurring Expenses")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Track subscriptions & bills")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
            .padding(16)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ghost Budget Card

    private var ghostBudgetCard: some View {
        Button { showGhostBudget = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.success.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Text("👻")
                        .font(Typography.displaySmall)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Ghost Budget")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.textPrimary)
                        if !premiumManager.hasFullAccess {
                            Label("PRO", systemImage: "crown.fill")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.12), in: .capsule)
                        }
                    }
                    Text("See your parallel financial timeline")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
            .padding(16)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    vm.previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.elevated, in: .circle)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(vm.monthLabel)
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())

                if vm.isCurrentMonth {
                    Text("\(vm.daysLeftInMonth) days left")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    vm.nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.elevated, in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: - Over Budget Banner

    private var overBudgetBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.bodyLarge)
                .foregroundStyle(Theme.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text("Over Budget")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.danger)
                Text("Some categories have exceeded their limit")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Theme.danger.opacity(0.1), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.danger.opacity(0.25), lineWidth: 1)
        )
        .sensoryFeedback(.warning, trigger: vm.appeared)
    }

    // MARK: - Hero Ring

    private var heroRing: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("Spent $\(Int(totalSpent)) of $\(Int(totalBudget))")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            ZStack {
                Circle()
                    .stroke(Theme.border, lineWidth: 10)
                    .frame(width: 120, height: 120)

                MMProgressRing(
                    progress: min(overallProgress, 1.0),
                    lineWidth: 10,
                    size: 120
                )

                VStack(spacing: 2) {
                    Text("$\(Int(remaining))")
                        .font(Typography.displayMedium)
                        .foregroundStyle(overallProgress > 1 ? Theme.danger : Theme.textPrimary)
                        .contentTransition(.numericText(value: remaining))
                    Text("remaining")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(Int(overallProgress * 100))%")
                        .font(Typography.headingLarge)
                        .foregroundStyle(overallProgress > 0.9 ? Theme.danger : overallProgress > 0.7 ? Theme.warning : Theme.accentGreen)
                    Text("used")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1, height: 28)

                VStack(spacing: 4) {
                    Text("\(vm.daysLeftInMonth)")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.textPrimary)
                    Text("days left")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1, height: 28)

                VStack(spacing: 4) {
                    Text("\(budgets.count)")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.accent)
                    Text("categories")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Categories")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()

                Button {
                    showTemplates = true
                } label: {
                    Image(systemName: "rectangle.grid.1x2.fill")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                Button {
                    vm.showAddBudget = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }

            if categories.allSatisfy({ $0.spent == 0 }) && !budgets.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textMuted)
                    Text("No transactions this month")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Your budget rings will fill as you spend")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .splurjCard(.subtle)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(categories) { cat in
                        categoryCard(cat)
                    }
                }
            }
        }
    }

    private func categoryCard(_ cat: CategorySpending) -> some View {
        Button {
            if let budget = budgets.first(where: { $0.name == cat.name }) {
                vm.selectedBudgetSpent = cat.spent
                vm.selectedBudget = budget
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Theme.border, lineWidth: 5)
                        .frame(width: 48, height: 48)

                    Circle()
                        .trim(from: 0, to: min(cat.progress, 1.0))
                        .stroke(
                            cat.isOverBudget
                                ? AnyShapeStyle(Theme.danger)
                                : cat.progress < 0.5
                                    ? AnyShapeStyle(Theme.accentGreen)
                                    : AnyShapeStyle(Theme.accentGradient),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: cat.icon)
                        .font(Typography.labelLarge)
                        .foregroundStyle(cat.isOverBudget ? Theme.danger : cat.color)
                }

                Text(cat.name)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text("\(Int(cat.spent)) / \(Int(cat.limit))")
                    .font(Typography.bodySmall)
                    .foregroundStyle(cat.isOverBudget ? Theme.danger : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            PersonalityEmptyStateView(
                personality: personality,
                icon: "chart.pie.fill",
                secondaryIcon: "percent",
                headline: "Set Your First Budget",
                subtext: "Choose from popular templates or\nbuild your own budget from scratch",
                buttonLabel: "Browse Templates",
                buttonIcon: "rectangle.grid.1x2.fill"
            ) {
                showTemplates = true
            }

            Button {
                vm.showAddBudget = true
            } label: {
                Label("Create Custom Budget", systemImage: "plus")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent.opacity(0.12), in: .rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
    }

    private func templateRow(emoji: String, label: String, desc: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(Typography.displaySmall)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text(desc)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
        .padding(14)
        .splurjCard(.subtle)
    }

    private func createDefaultBudgets() {
        let defaults: [(String, String, String, Double)] = [
            ("Housing", "house.fill", "5F27CD", 1500),
            ("Food", "fork.knife", "FF6B6B", 500),
            ("Transport", "car.fill", "54A0FF", 300),
            ("Shopping", "bag.fill", "A55EEA", 300),
            ("Entertainment", "tv.fill", "FF9F43", 200),
            ("Health", "heart.fill", "FF6348", 150),
            ("Savings", "banknote.fill", "00E676", 500),
        ]

        for (i, def) in defaults.enumerated() {
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
