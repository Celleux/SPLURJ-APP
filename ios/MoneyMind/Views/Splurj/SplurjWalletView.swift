import SwiftUI

// MARK: - Splurj Wallet — v2
//
// Covers the two canonical states from states.jsx:
//   - EmptyWallet (no bank connected) — mascot hero + connect-bank CTA
//   - connected (stubbed data) — segmented Activity / Budgets / Tools

struct SplurjWalletView: View {
    var variant: SplurjVariant = .her
    var level: Int = 1
    var equippedCosmetics: Set<CosmeticID> = []
    var isConnected: Bool = false
    var onConnectPlaid: () -> Void = {}

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

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    SplurjTopBar(
                        title: isConnected ? "Wallet" : "",
                        variant: variant,
                        level: level,
                        stateDotColor: isConnected ? Theme.glow : Theme.textMuted
                    ) {
                        SplurjMascotPlaceholder(variant: variant)
                    }
                    Group {
                        if isConnected {
                            connectedBody
                        } else {
                            emptyBody
                        }
                    }
                    .padding(.horizontal, 22)
                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
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
            Kicker("Wallet · not connected")
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
                PrimaryCtaButton(title: "Connect bank · Plaid", icon: "building.columns.fill") { onConnectPlaid() }
                GhostLinkButton(title: "I\u{2019}ll do this later") { }
            }
            trustCard
        }
    }

    private var emptyTitle: String {
        switch variant {
        case .her:     "Splurj is sniffing around."
        case .him:     "Splurj is hungry for data."
        case .neutral: "Splurj needs signals."
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
                Text("Splurj can\u{2019}t move money. Ever.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Connected body

    private var connectedBody: some View {
        VStack(spacing: 16) {
            totalSavedHero
            segmentPicker
            switch segment {
            case .activity: activitySection
            case .budgets:  budgetsSection
            case .tools:    toolsSection
            }
        }
    }

    private var totalSavedHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Kicker("Total saved")
            Text("$247.82")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                Text("$32 from last month")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Theme.glow)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Theme.cardTintHi, Theme.cardTint],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.borderHi, lineWidth: 1))
    }

    private var segmentPicker: some View {
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

    private var activitySection: some View {
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                txRow(amount: [42, 18, 76, 9, 33][i], merchant: ["Starbucks", "DoorDash", "Whole Foods", "Spotify", "REI"][i], avoided: i % 2 == 0)
            }
        }
    }

    private func txRow(amount: Int, merchant: String, avoided: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(avoided ? Theme.glow.opacity(0.18) : Color.white.opacity(0.05))
                    .frame(width: 38, height: 38)
                Image(systemName: avoided ? "arrow.uturn.backward" : "bag")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(avoided ? Theme.glow : Theme.textSecondary)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(merchant)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(avoided ? "Avoided · Splurj noticed" : "Spent · today")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(avoided ? "+$\(amount)" : "-$\(amount)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(avoided ? Theme.glow : Theme.textPrimary)
        }
        .padding(12)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    private var budgetsSection: some View {
        VStack(spacing: 8) {
            budgetRow(name: "Shopping", spent: 240, limit: 300)
            budgetRow(name: "Groceries", spent: 180, limit: 400)
            budgetRow(name: "Dining", spent: 120, limit: 150)
        }
    }

    private func budgetRow(name: String, spent: Int, limit: Int) -> some View {
        let progress = min(1.0, Double(spent) / Double(limit))
        let overHalf = progress > 0.8
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("$\(spent) / $\(limit)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(overHalf ? Theme.honey : Theme.textSecondary)
            }
            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(overHalf ? Theme.honey : Theme.glow)
                            .frame(width: geo.size.width * progress, height: 6)
                            .shadow(color: (overHalf ? Theme.honey : Theme.glow).opacity(0.5), radius: 4)
                    }
                    .frame(height: 6)
                }
        }
        .padding(14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
    }

    private var toolsSection: some View {
        VStack(spacing: 10) {
            toolRow(emoji: "\u{1F47B}", title: "Ghost Budget", sub: "Project forward — what-ifs")
            toolRow(emoji: "\u{1F4C8}", title: "Savings trend", sub: "90 days of progress at a glance")
            toolRow(emoji: "\u{1F52E}", title: "1-year projection", sub: "See where the pacts take you")
        }
    }

    private func toolRow(emoji: String, title: String, sub: String) -> some View {
        Button { } label: {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 18))
                    .frame(width: 38, height: 38)
                    .background(Theme.cardTintHi, in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
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
            .padding(12)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Wallet · empty") {
    SplurjWalletView(isConnected: false)
}
#Preview("Wallet · connected") {
    SplurjWalletView(level: 7, isConnected: true)
}
#endif
