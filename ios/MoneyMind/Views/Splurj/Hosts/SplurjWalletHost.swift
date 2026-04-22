import SwiftUI
import SwiftData

// MARK: - Splurj Wallet host
//
// Feeds real Transaction + BudgetCategory data into SplurjWalletView
// and routes every Tool tile, budget row, Log Win, and "I gave in"
// action to its existing production view (BudgetAnalyticsView,
// RecurringExpensesView, GhostBudgetView, DNSBlockingWizardView,
// BudgetDetailSheet, LogWinSheet/WalletLogWinSheet, SpendingAutopsySheet).

struct SplurjWalletHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Query(sort: \BudgetCategory.sortOrder) private var budgets: [BudgetCategory]

    @State private var showProfile = false
    @State private var activeTool: ToolDestination?
    @State private var selectedBudgetID: String?
    @State private var showLogWin = false
    @State private var showAutopsy = false

    enum ToolDestination: String, Identifiable {
        case autoSave, coolingOff, merchantBlock, subSweep, goalVault
        var id: String { rawValue }
    }

    private var profile: UserProfile? { profiles.first }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }
    private var equippedCosmetics: Set<CosmeticID> { profile?.equippedCosmetics ?? [] }
    private var currencySymbol: String { profile?.currencySymbol ?? "$" }

    private var level: Int {
        max(profile?.splurjLevel ?? 1, (profile?.currentStreak ?? 0) / 3 + 1)
    }

    private var isConnected: Bool {
        !transactions.isEmpty || !impulseLogs.isEmpty
    }

    private var netPosition: Double {
        transactions.reduce(0.0) { acc, tx in
            acc + (tx.type == TransactionType.income.rawValue ? tx.amount : -tx.amount)
        }
    }

    private var netPositionWhole: Int { Int(netPosition.rounded(.down)) }
    private var netPositionCents: Int { Int((abs(netPosition) * 100).rounded()) % 100 }

    private var deltaThisMonth: Double {
        SavingsMath.thisCalendarMonth(logs: impulseLogs)
    }

    private var accountCount: Int {
        isConnected ? 1 : 0
    }

    private var activityGroups: [SplurjWalletView.ActivityGroup] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        let dayFmt = DateFormatter(); dayFmt.dateFormat = "EEE"

        var buckets: [(label: String, order: Int, rows: [SplurjWalletView.ActivityRow])] = []
        func bucketIndex(for label: String, order: Int) -> Int {
            if let i = buckets.firstIndex(where: { $0.label == label }) { return i }
            buckets.append((label, order, []))
            return buckets.count - 1
        }

        for tx in transactions.prefix(30) {
            let day = calendar.startOfDay(for: tx.date)
            let (label, order, flagged): (String, Int, Bool)
            if day == today {
                (label, order, flagged) = ("TODAY", 0, false)
            } else if day == yesterday {
                let isLateNightSpend = tx.type == TransactionType.expense.rawValue
                    && calendar.component(.hour, from: tx.date) >= 21
                (label, order, flagged) = (isLateNightSpend ? "YESTERDAY \u{00B7} FLAGGED" : "YESTERDAY", 1, isLateNightSpend)
            } else {
                (label, order, flagged) = (dayFmt.string(from: tx.date).uppercased(), 2, false)
            }

            let amountSigned = tx.type == TransactionType.income.rawValue ? tx.amount : -tx.amount
            let row = SplurjWalletView.ActivityRow(
                id: "\(tx.persistentModelID.hashValue)",
                emoji: emoji(for: tx.category),
                merchant: tx.note.isEmpty ? tx.category : tx.note,
                category: tx.category,
                time: tf.string(from: tx.date),
                amount: amountSigned,
                flagged: flagged,
                mood: moodTag(for: tx)
            )
            let idx = bucketIndex(for: label, order: order)
            buckets[idx].rows.append(row)
        }

        return buckets.sorted { $0.order < $1.order }
            .map { SplurjWalletView.ActivityGroup(id: $0.label, label: $0.label, rows: $0.rows) }
    }

    private var budgetRows: [SplurjWalletView.BudgetRowData] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let palette: [SplurjWalletView.BudgetRowData.Tone] = [.glow, .honey, .sky, .petal]
        return budgets.enumerated().map { idx, b in
            let spent = transactions
                .filter { $0.type == TransactionType.expense.rawValue && $0.category == b.name && $0.date >= startOfMonth }
                .reduce(0.0) { $0 + $1.amount }
            return SplurjWalletView.BudgetRowData(
                id: "\(b.persistentModelID.hashValue)",
                emoji: b.icon.isEmpty ? "\u{1F4B0}" : b.icon,
                label: b.name,
                spent: spent,
                cap: b.monthlyLimit,
                tone: palette[idx % palette.count]
            )
        }
    }

    private var monthLabel: String {
        let f = DateFormatter(); f.dateFormat = "LLLL"
        return f.string(from: Date())
    }

    private var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .month, for: now),
              let days = calendar.dateComponents([.day], from: now, to: interval.end).day
        else { return 0 }
        return max(0, days)
    }

    var body: some View {
        SplurjWalletView(
            variant: variant,
            level: level,
            equippedCosmetics: equippedCosmetics,
            isConnected: isConnected,
            netPositionWhole: netPositionWhole,
            netPositionCents: netPositionCents,
            deltaThisMonth: deltaThisMonth,
            accountCount: accountCount,
            currencySymbol: currencySymbol,
            activityGroups: activityGroups,
            budgetRows: budgetRows,
            monthLabel: monthLabel,
            daysLeftInMonth: daysLeftInMonth,
            onConnectPlaid: { },
            onOpenProfile: { showProfile = true },
            onTapTool: { action in activeTool = toolDestination(for: action) },
            onTapBudget: { id in selectedBudgetID = id },
            onLogAvoided: { showLogWin = true },
            onLogGaveIn: { showAutopsy = true }
        )
        .sheet(isPresented: $showProfile) {
            SplurjProfileHost()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLogWin) { WalletLogWinSheet() }
        .sheet(isPresented: $showAutopsy) { SpendingAutopsySheet() }
        .sheet(item: $activeTool) { tool in
            toolDestinationView(tool)
        }
        .sheet(item: Binding(
            get: { selectedBudgetID.flatMap { id in budgets.first { "\($0.persistentModelID.hashValue)" == id } } },
            set: { _ in selectedBudgetID = nil }
        )) { budget in
            BudgetDetailSheet(budget: budget, spent: spentForBudget(budget))
        }
    }

    private func spentForBudget(_ budget: BudgetCategory) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { $0.type == TransactionType.expense.rawValue && $0.category == budget.name && $0.date >= startOfMonth }
            .reduce(0.0) { $0 + $1.amount }
    }

    private func toolDestination(for action: SplurjWalletView.ToolAction) -> ToolDestination {
        switch action {
        case .autoSave:      .autoSave
        case .coolingOff:    .coolingOff
        case .merchantBlock: .merchantBlock
        case .subSweep:      .subSweep
        case .goalVault:     .goalVault
        }
    }

    @ViewBuilder
    private func toolDestinationView(_ tool: ToolDestination) -> some View {
        switch tool {
        case .autoSave:      NavigationStack { GhostBudgetView() }
        case .coolingOff:    NavigationStack { CoolingOffView() }
        case .merchantBlock: NavigationStack { DNSBlockingWizardView() }
        case .subSweep:      NavigationStack { RecurringExpensesView() }
        case .goalVault:     NavigationStack { BudgetAnalyticsView() }
        }
    }

    // MARK: - Mapping helpers

    private func emoji(for category: String) -> String {
        switch category.lowercased() {
        case "food", "food & dining", "groceries", "food & drink": "\u{1F37D}"
        case "transport":      "\u{1F686}"
        case "shopping":       "\u{1F6CD}"
        case "bills":          "\u{1F4DC}"
        case "entertainment":  "\u{1F3AC}"
        case "health":         "\u{1FA7A}"
        case "education":      "\u{1F393}"
        case "personal care":  "\u{1F485}"
        case "home":           "\u{1F3E0}"
        case "travel":         "\u{2708}"
        case "gifts":          "\u{1F381}"
        case "subscriptions":  "\u{1F4F1}"
        case "other":          "\u{2728}"
        case "income":         "\u{1F4BC}"
        default:               "\u{1F4B3}"
        }
    }

    private func moodTag(for tx: Transaction) -> SplurjWalletView.ActivityRow.MoodTag? {
        switch tx.moodEmoji {
        case "\u{1F60C}", "\u{1F4AB}", "\u{2728}":
            return .init(label: "Mindful", tone: .mindful)
        case "\u{1F62C}", "\u{1F629}", "\u{1F615}":
            return .init(label: "Restless", tone: .restless)
        default:
            return nil
        }
    }
}
