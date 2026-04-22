import SwiftUI

// MARK: - Splurj Wallet — v2 (canonical port of explorations/v2-wallet.jsx)
//
// Hero net-position ALWAYS visible. Segmented: Activity · Budgets · Tools.
// Data types are passed in — the host queries SwiftData and threads real
// transactions, budgets, and net-position numbers through.

struct SplurjWalletView: View {
    var variant: SplurjVariant = .her
    var level: Int = 7
    var equippedCosmetics: Set<CosmeticID> = []

    var isConnected: Bool = false
    var netPositionWhole: Int = 0
    var netPositionCents: Int = 0
    var deltaThisMonth: Double = 0
    var accountCount: Int = 0
    var currencySymbol: String = "$"

    var activityGroups: [ActivityGroup] = []
    var budgetRows: [BudgetRowData] = []
    var monthLabel: String = "This month"
    var daysLeftInMonth: Int = 0

    var onConnectPlaid: () -> Void = {}
    var onOpenProfile: () -> Void = {}
    var onTapTool: (ToolAction) -> Void = { _ in }
    var onTapBudget: (String) -> Void = { _ in }
    var onLogAvoided: () -> Void = {}
    var onLogGaveIn: () -> Void = {}

    @State private var segment: WalletSeg = .activity

    nonisolated enum WalletSeg: String, CaseIterable, Identifiable, Sendable {
        case activity, budgets, tools
        var id: String { rawValue }
        var title: String {
            switch self {
            case .activity: "Activity"
            case .budgets:  "Budgets"
            case .tools:    "Tools"
            }
        }
    }

    nonisolated enum ToolAction: String, Sendable {
        case autoSave, coolingOff, merchantBlock, subSweep, goalVault
    }

    struct ActivityGroup: Identifiable, Hashable {
        let id: String
        let label: String                 // "TODAY", "YESTERDAY · FLAGGED", "MON"
        let rows: [ActivityRow]
    }

    struct ActivityRow: Identifiable, Hashable {
        let id: String
        let emoji: String
        let merchant: String
        let category: String
        let time: String
        let amount: Double                // negative = spend, positive = income
        let flagged: Bool
        let mood: MoodTag?

        struct MoodTag: Hashable { let label: String; let tone: MoodTone }
        enum MoodTone: Hashable { case mindful, restless, neutral }
    }

    struct BudgetRowData: Identifiable, Hashable {
        let id: String
        let emoji: String
        let label: String
        let spent: Double
        let cap: Double
        let tone: Tone
        enum Tone: Hashable { case glow, honey, sky, petal }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    SplurjTopBar(
                        title: "",
                        variant: variant,
                        level: level,
                        stateDotColor: Theme.glow,
                        onAvatarTap: onOpenProfile
                    ) {
                        SplurjMascotPlaceholder(variant: variant)
                    }

                    if isConnected {
                        connectedBody
                    } else {
                        emptyBody
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Connected body

    private var connectedBody: some View {
        VStack(spacing: 16) {
            heroCard
            quickActionRow
                .padding(.horizontal, 22)
            segmented
                .padding(.horizontal, 22)
            Group {
                switch segment {
                case .activity: activitySection
                case .budgets:  budgetsSection
                case .tools:    toolsSection
                }
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: - Quick action row (Log Avoided / I Gave In)

    private var quickActionRow: some View {
        HStack(spacing: 10) {
            Button(action: onLogAvoided) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                    Text("Log a win")
                        .font(.system(size: 13, weight: .heavy))
                }
                .foregroundStyle(Color(hex: 0x0B1614))
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Theme.glow, in: Capsule())
                .shadow(color: Theme.glow.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            Button(action: onLogGaveIn) {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 13, weight: .semibold))
                    Text("I gave in")
                        .font(.system(size: 13, weight: .heavy))
                }
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Theme.cardTintHi, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var heroCard: some View {
        VStack(spacing: 6) {
            Kicker("Net position \u{00B7} all accounts", color: Theme.textMuted, tracking: 2.0)
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(currencySymbol)\(formatted(netPositionWhole))")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.glow)
                    .shadow(color: Theme.glow.opacity(0.3), radius: 14)
                Text(".\(String(format: "%02d", abs(netPositionCents)))")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 6)
            }
            .monospacedDigit()
            HStack(spacing: 8) {
                pill(
                    text: "\u{2191} \(currencySymbol)\(Int(deltaThisMonth.rounded())) THIS MONTH",
                    color: Theme.glow
                )
                pill(
                    text: "\(accountCount) ACCOUNT\(accountCount == 1 ? "" : "S")",
                    color: Theme.textMuted
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.33), lineWidth: 1))
    }

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(WalletSeg.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { segment = s }
                } label: {
                    Text(s.title)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(segment == s ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(segment == s ? AnyShapeStyle(Theme.cardTintHi) : AnyShapeStyle(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Activity section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if activityGroups.isEmpty {
                emptyActivityState
            } else {
                ForEach(activityGroups) { group in
                    Text(group.label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.top, 14)
                        .padding(.bottom, 2)
                    ForEach(group.rows) { row in
                        txRow(row)
                    }
                }
            }
        }
    }

    private var emptyActivityState: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(Theme.textMuted)
            Text("No transactions yet.")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Theme.textSecondary)
            Text("Log one via Home \u{2192} FEED \u{00B7} Log Win.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func txRow(_ row: ActivityRow) -> some View {
        HStack(spacing: 11) {
            ZStack(alignment: .topTrailing) {
                Text(row.emoji)
                    .font(.system(size: 18))
                    .frame(width: 38, height: 38)
                    .background(Theme.cardTintHi, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                if row.flagged {
                    Text("!")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 14, height: 14)
                        .background(Theme.danger, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
                        .offset(x: 4, y: -4)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(row.merchant)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(row.category)
                    Text("\u{00B7}").foregroundStyle(Theme.textMuted)
                    Text(row.time)
                    if let mood = row.mood {
                        Text("\u{00B7}").foregroundStyle(Theme.textMuted)
                        Text(mood.label)
                            .foregroundStyle(color(for: mood.tone))
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(row.amount > 0 ? "+" : "")\(currencySymbol)\(String(format: "%.2f", abs(row.amount)))")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(row.amount > 0 ? Theme.glow : Theme.textPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private func color(for tone: ActivityRow.MoodTone) -> Color {
        switch tone {
        case .mindful:  Theme.glow
        case .restless: Theme.danger
        case .neutral:  Theme.textSecondary
        }
    }

    // MARK: - Budgets section

    private var budgetsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(monthLabel.uppercased()) \u{00B7} \(daysLeftInMonth) DAYS LEFT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Text("+ New")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Theme.glow)
            }
            .padding(.top, 14)
            .padding(.bottom, 4)

            if budgetRows.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.textMuted)
                    Text("No budgets set up.")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Splurji will add defaults when you log your first spend.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                ForEach(budgetRows) { row in
                    budgetRow(row)
                }
            }
        }
    }

    private func budgetRow(_ row: BudgetRowData) -> some View {
        let pct = min(1.15, row.cap > 0 ? row.spent / row.cap : 0)
        let over = pct >= 1
        let left = max(0, row.cap - row.spent)
        let tint: Color = switch row.tone {
        case .glow:  Theme.glow
        case .honey: Theme.honey
        case .sky:   Theme.sky
        case .petal: Theme.petal
        }
        return Button { onTapBudget(row.id) } label: {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(row.emoji)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(Theme.cardTintHi, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.label)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(currencySymbol)\(Int(row.spent)) of \(currencySymbol)\(Int(row.cap)) \u{00B7} \(currencySymbol)\(Int(left)) left")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if over { pill(text: "OVER", color: Theme.danger) }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(over ? Theme.danger : tint)
                        .frame(width: geo.size.width * min(1.0, pct))
                        .shadow(color: (over ? Theme.danger : tint).opacity(0.6), radius: over ? 4 : 0)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tools section

    private var toolsSection: some View {
        VStack(spacing: 8) {
            toolRow(.autoSave,      title: "Auto-save rules",   sub: "Round-up, 1-5-10, on-payday", systemImage: "arrow.down.to.line.compact", tint: Theme.glow)
            toolRow(.coolingOff,    title: "Cooling-off timer", sub: "48h hold on purchases over \(currencySymbol)75", systemImage: "clock.fill", tint: Theme.honey)
            toolRow(.merchantBlock, title: "Merchant blocklist", sub: "Shein, TikTok Shop, Uber Eats late-night", systemImage: "lock.fill", tint: Theme.sky)
            toolRow(.subSweep,      title: "Subscription sweep", sub: "Finds unused subs you could cut", systemImage: "checkmark.seal.fill", tint: Theme.petal)
            toolRow(.goalVault,     title: "Goal vaults",        sub: "Save toward specific goals", systemImage: "star.fill", tint: Theme.glow)
        }
        .padding(.top, 16)
    }

    private func toolRow(_ action: ToolAction, title: String, sub: String, systemImage: String, tint: Color) -> some View {
        Button { onTapTool(action) } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(tint.opacity(0.28), lineWidth: 1))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(13)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state (no bank)

    private var emptyBody: some View {
        VStack(spacing: 22) {
            SplurjMascot(
                variant: variant,
                stage: .sprout,
                cosmetics: equippedCosmetics,
                size: 180
            )
            .padding(.top, 30)
            Kicker("Wallet \u{00B7} not connected")
            Text(emptyTitle)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(emptySub)
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
            VStack(spacing: 10) {
                PrimaryCtaButton(title: "Connect bank \u{00B7} Plaid", icon: "building.columns.fill") { onConnectPlaid() }
                GhostLinkButton(title: "I\u{2019}ll do this later") { }
            }
            trustCard
        }
        .padding(.horizontal, 22)
    }

    private var emptyTitle: String {
        switch variant {
        case .her:     "Splurji is sniffing around."
        case .him:     "Splurji is hungry for data."
        case .neutral: "Splurji needs signals."
        }
    }

    private var emptySub: String {
        switch variant {
        case .her:     "Connect a bank so she can smell the wins and the splurges. Takes 20 seconds."
        case .him:     "Connect a bank. He learns your patterns faster than you think."
        case .neutral: "Connect a bank to start tracking. 20 seconds, read-only."
        }
    }

    private var trustCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.glow)
                .frame(width: 32, height: 32)
                .background(Theme.glow.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text("Read-only, bank-grade encryption")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Splurji can\u{2019}t move money. Ever.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Helpers

    private func formatted(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

#if DEBUG
#Preview("Wallet · empty") {
    SplurjWalletView(isConnected: false)
}
#Preview("Wallet · connected") {
    SplurjWalletView(
        level: 7,
        isConnected: true,
        netPositionWhole: 12847,
        netPositionCents: 20,
        deltaThisMonth: 427,
        accountCount: 3,
        activityGroups: [
            .init(id: "today", label: "TODAY", rows: [
                .init(id: "t1", emoji: "\u{1F6D2}", merchant: "Whole Foods", category: "Groceries", time: "6:42 PM", amount: -47.82, flagged: false, mood: nil),
                .init(id: "t2", emoji: "\u{2615}", merchant: "Ritual Coffee", category: "Food & drink", time: "8:15 AM", amount: -6.50, flagged: false, mood: .init(label: "Mindful", tone: .mindful))
            ])
        ],
        budgetRows: [
            .init(id: "b1", emoji: "\u{1F37D}", label: "Food & dining", spent: 312, cap: 450, tone: .glow),
            .init(id: "b2", emoji: "\u{1F6CD}", label: "Shopping", spent: 180, cap: 150, tone: .honey),
        ],
        monthLabel: "November",
        daysLeftInMonth: 7
    )
}
#endif
