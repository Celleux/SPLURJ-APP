import SwiftUI
import SwiftData
import PhosphorSwift

nonisolated enum WalletSegment: String, CaseIterable, Identifiable, Sendable {
    case activity, budgets, tools
    var id: String { rawValue }
    var title: String {
        switch self {
        case .activity: "Activity"
        case .budgets: "Budgets"
        case .tools: "Tools"
        }
    }
    var icon: String {
        switch self {
        case .activity: "list.bullet.rectangle.fill"
        case .budgets: "chart.pie.fill"
        case .tools: "wand.and.stars"
        }
    }
}

struct WalletView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]
    @Query private var quizResults: [QuizResult]
    @State private var vm = WalletViewModel()
    @State private var segment: WalletSegment = .activity
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager

    private var profile: UserProfile? { profiles.first }
    private var gentle: Bool { profile?.gentleViewMode ?? false }
    private var currencyCode: String { profile?.defaultCurrency ?? "USD" }
    private var currencySymbol: String { CurrencyHelper.symbol(for: currencyCode) }

    private var effectiveTotal: Double {
        vm.effectiveTotal(profile?.totalSaved ?? 0, phantomApplied: profile?.phantomProgressApplied ?? false)
    }

    private var todaySaved: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return impulseLogs.filter { $0.resisted && $0.date >= today }.reduce(0) { $0 + $1.amount }
    }

    private var weekSaved: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return impulseLogs.filter { $0.resisted && $0.date >= weekAgo }.reduce(0) { $0 + $1.amount }
    }

    private var monthSaved: Double {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return impulseLogs.filter { $0.resisted && $0.date >= monthAgo }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    if impulseLogs.isEmpty && (profile?.totalSaved ?? 0) <= 2.0 {
                        SplurjEmptyState(
                            icon: PhIcon.wallet,
                            title: "No transactions yet",
                            subtitle: "Log your first win — every saved dollar counts!",
                            ctaTitle: "Log a Win"
                        ) {
                            vm.showLogWin = true
                        }
                    } else {
                        VStack(spacing: 24) {
                            heroCounterCard
                            segmentPicker

                            switch segment {
                            case .activity:
                                walletVisualization
                                statsRow
                                recentTransactions
                            case .budgets:
                                budgetToolsSection
                            case .tools:
                                savingsTrendChart
                                projectionCard
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                        .padding(.top, 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: segment)
                    }
                }
                .scrollIndicators(.hidden)

                floatingActions
            }
            .background(
                ZStack {
                    Theme.background.ignoresSafeArea()
                    SplurjSwoosh()
                        .fill(Theme.accent.opacity(0.03))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            )
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $vm.showLogWin) {
                WalletLogWinSheet(onSaved: { amount in
                    vm.celebrationAmount = amount
                    vm.showCelebration = true
                    let oldTotal = profile?.totalSaved ?? 0
                    vm.checkMilestone(oldTotal: oldTotal, newTotal: oldTotal + amount)
                })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
            }
            .sheet(isPresented: $vm.showAutopsy) {
                SpendingAutopsySheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
            .overlay {
                if vm.showCelebration {
                    CelebrationOverlay(amount: vm.celebrationAmount) {
                        vm.showCelebration = false
                    }
                }
            }
            .overlay {
                if vm.showMilestone {
                    MilestoneOverlay(amount: vm.milestoneValue) {
                        vm.showMilestone = false
                    }
                }
            }
            .onAppear {
                applyPhantomProgress()
            }
            .profileAvatarToolbar()
        }
    }

    private func applyPhantomProgress() {
        guard let profile, !profile.phantomProgressApplied, profile.totalSaved == 0 else { return }
        profile.totalSaved = 2.0
        profile.phantomProgressApplied = true
    }

    // MARK: - Hero Counter

    private var heroCounterCard: some View {
        VStack(spacing: 14) {
            HStack {
                PhIcon.walletFill
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Theme.accentGreen)
                Text("Total Saved")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if let progress = vm.milestoneProgress(for: effectiveTotal),
                   let next = vm.nextMilestone(for: effectiveTotal) {
                    goalGradientBadge(progress: progress, milestone: next)
                }
            }

            if gentle && !vm.revealExact {
                Text(vm.displayAmount(effectiveTotal, gentle: true))
                    .font(Typography.moneyLarge)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
                    .onTapGesture { vm.revealExact = true }
                    .accessibilityLabel("Total saved approximately \(Int(effectiveTotal)) dollars")
            } else {
                Text(effectiveTotal, format: .currency(code: currencyCode))
                    .font(Typography.moneyLarge)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText(value: effectiveTotal))
                    .animation(Theme.numericSpring, value: effectiveTotal)
                    .sensoryFeedback(.impact(weight: .medium), trigger: effectiveTotal)
                    .accessibilityLabel("Total saved \(effectiveTotal, format: .currency(code: currencyCode))")
            }

            HStack(spacing: 4) {
                PhIcon.clockFill
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Theme.teal)
                let hours = vm.workHours(for: effectiveTotal, rate: profile?.hourlyRate ?? 20)
                Text("That's \(hours, specifier: "%.1f") hours of your work")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.teal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .splurjCard(.hero)
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: vm.appeared)
        .onAppear { vm.appeared = true }
    }

    private func goalGradientBadge(progress: Double, milestone: Double) -> some View {
        HStack(spacing: 4) {
            PhIcon.flagCheckered
                .frame(width: 14, height: 14)
            Text("\(CurrencyHelper.symbol(for: profiles.first?.defaultCurrency ?? "USD"))\(Int(milestone))")
                .font(Typography.labelSmall)
        }
        .foregroundStyle(Theme.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.gold.opacity(0.15), in: .capsule)
        .overlay(
            Capsule()
                .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
        )
        .symbolEffect(.pulse, options: .repeating, isActive: true)
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 6) {
            ForEach(WalletSegment.allCases) { option in
                let selected = option == segment
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        segment = option
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(option.title)
                            .font(Typography.labelMedium)
                    }
                    .foregroundStyle(selected ? Theme.buttonTextOnAccent : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selected {
                                Capsule().fill(Theme.accentGradient)
                            } else {
                                Capsule().fill(Color.clear)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: segment)
            }
        }
        .padding(4)
        .background(Theme.elevated, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 0.5))
    }

    // MARK: - Wallet Visualization

    private var walletVisualization: some View {
        let level = vm.currentLevel(for: effectiveTotal)
        let progress = vm.levelProgress(for: effectiveTotal)

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentGreen.opacity(0.06))
                    .frame(width: 100, height: 100)

                Circle()
                    .strokeBorder(Theme.accentGreen.opacity(0.15), lineWidth: 2)
                    .frame(width: 100, height: 100)

                Image(systemName: level.icon)
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.accentGradient)
                    .symbolEffect(.breathe, options: .repeating, isActive: vm.appeared)

                SparkleParticlesView()
                    .frame(width: 120, height: 120)
                    .allowsHitTesting(false)
            }

            Text(level.name)
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.cardSurface)
                        .frame(height: 6)
                    Capsule()
                        .fill(Theme.accentGradient)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 8)
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.08), value: vm.appeared)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            WalletStatPill(label: "Today", amount: todaySaved, color: Theme.accentGreen, gentle: gentle, revealExact: vm.revealExact, currencyCode: currencyCode)
            WalletStatPill(label: "This Week", amount: weekSaved, color: Theme.teal, gentle: gentle, revealExact: vm.revealExact, currencyCode: currencyCode)
            WalletStatPill(label: "This Month", amount: monthSaved, color: Theme.gold, gentle: gentle, revealExact: vm.revealExact, currencyCode: currencyCode)
        }
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: vm.appeared)
    }

    // MARK: - Savings Trend Chart

    private var savingsTrendChart: some View {
        let monthlyData = vm.monthlySavings(from: impulseLogs)
        let projected = projectedMonths(from: monthlyData)
        let allData = monthlyData + projected
        let maxVal = max((allData.map(\.amount).max() ?? 1) * 1.15, 1)

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "chart.line.uptrend.xyaxis", title: "Savings Trend", actionLabel: "Last 6 months")

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let totalPoints = max(allData.count - 1, 1)

                ZStack(alignment: .bottomLeading) {
                    Path { path in
                        for (i, data) in monthlyData.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(totalPoints)
                            let y = h - (CGFloat(data.amount / maxVal) * h)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        for (i, data) in monthlyData.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(totalPoints)
                            let y = h - (CGFloat(data.amount / maxVal) * h)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        let lastX = w * CGFloat(monthlyData.count - 1) / CGFloat(totalPoints)
                        path.addLine(to: CGPoint(x: lastX, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.2), Theme.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    if !projected.isEmpty, let lastData = monthlyData.last {
                        Path { path in
                            let startIdx = monthlyData.count - 1
                            for (i, data) in ([lastData] + projected).enumerated() {
                                let idx = startIdx + i
                                let x = w * CGFloat(idx) / CGFloat(totalPoints)
                                let y = h - (CGFloat(data.amount / maxVal) * h)
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(Theme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    }
                }
            }
            .frame(height: 160)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Theme.accent).frame(width: 8, height: 8)
                    Text("Actual").font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(Theme.accent.opacity(0.4)).frame(width: 8, height: 8)
                    Text("Projected").font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(20)
        .splurjCard(.elevated)
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.13), value: vm.appeared)
    }

    private func projectedMonths(from actual: [MonthlySavingsData]) -> [MonthlySavingsData] {
        guard actual.count >= 2, let lastAmount = actual.last?.amount else { return [] }
        let secondLast = actual[actual.count - 2].amount
        let growthRate = lastAmount > 0 ? (lastAmount - secondLast) / max(lastAmount, 1) : 0.1
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var projected: [MonthlySavingsData] = []
        var currentAmount = lastAmount
        for i in 1...3 {
            currentAmount = max(0, currentAmount * (1 + growthRate))
            let futureDate = calendar.date(byAdding: .month, value: i, to: Date()) ?? Date()
            projected.append(MonthlySavingsData(month: formatter.string(from: futureDate), amount: currentAmount, date: futureDate, isProjected: true))
        }
        return projected
    }

    // MARK: - Budget Tools

    private var budgetToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "chart.bar.fill", title: "Budget & Planning")

            NavigationLink(destination: BudgetAnalyticsView()) {
                HStack(spacing: 14) {
                    Image(systemName: "chart.pie.fill")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 36, height: 36)
                        .background(Theme.accent.opacity(0.12), in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Budget Overview")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Track spending across categories")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(14)
                .background(Theme.cardSurface, in: .rect(cornerRadius: 14))
            }

            if premiumManager.hasFullAccess {
                NavigationLink(destination: GhostBudgetView()) {
                    HStack(spacing: 14) {
                        Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                            .font(Typography.bodyLarge)
                            .foregroundStyle(Theme.gold)
                            .frame(width: 36, height: 36)
                            .background(Theme.gold.opacity(0.12), in: .rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ghost Budget")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Text("What-if scenarios for your money")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("PRO")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.buttonTextOnAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.goldGradient, in: .capsule)
                    }
                    .padding(14)
                    .background(Theme.cardSurface, in: .rect(cornerRadius: 14))
                }
            } else {
                Button {
                    vm.showPaywall = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                            .font(Typography.bodyLarge)
                            .foregroundStyle(Theme.gold)
                            .frame(width: 36, height: 36)
                            .background(Theme.gold.opacity(0.12), in: .rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ghost Budget")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Unlock what-if money scenarios")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(14)
                    .background(Theme.cardSurface, in: .rect(cornerRadius: 14))
                }
            }

            NavigationLink(destination: RecurringExpensesView()) {
                HStack(spacing: 14) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.teal)
                        .frame(width: 36, height: 36)
                        .background(Theme.teal.opacity(0.12), in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recurring Expenses")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Manage subscriptions & bills")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(14)
                .background(Theme.cardSurface, in: .rect(cornerRadius: 14))
            }
        }
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.14), value: vm.appeared)
    }

    // MARK: - Recent Transactions

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "clock.arrow.circlepath", title: "Recent Activity", actionLabel: !impulseLogs.isEmpty ? "\(impulseLogs.count) total" : "")

            if impulseLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.gold.opacity(0.4))
                    Text("No activity yet")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Tap the green button to log your first resist!")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .splurjCard(.subtle)
            } else {
                VStack(spacing: 2) {
                    ForEach(impulseLogs.prefix(10)) { log in
                        WalletTransactionRow(log: log, gentle: gentle, revealExact: vm.revealExact, currencyCode: currencyCode)
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
            }
        }
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.16), value: vm.appeared)
    }

    // MARK: - Projection (with Impulse Impact)

    private var projectionCard: some View {
        let allSaves = impulseLogs.filter { $0.resisted }
        let totalSaved = allSaves.reduce(0.0) { $0 + $1.amount }
        let totalGaveIn = vm.totalGaveIn(from: impulseLogs)
        let firstDate = allSaves.map(\.date).min() ?? Date()
        let daysActive = max(1, Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 1)
        let dailyAverage = totalSaved / Double(daysActive)
        let yearProjection = dailyAverage * 365

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
                Text("1-Year Projection")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
            }

            Text(yearProjection, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(Typography.moneyLarge)
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText(value: yearProjection))

            Text("based on your \(currencySymbol)\(dailyAverage, specifier: "%.0f")/day average over \(daysActive) days")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)

            if totalSaved > 0 || totalGaveIn > 0 {
                Divider().background(Theme.border)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.accentGreen)
                            .font(Typography.labelSmall)
                        Text("Resisted")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(currencySymbol)\(Int(totalSaved))")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.accentGreen)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.emergency)
                            .font(Typography.labelSmall)
                        Text("Gave In")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(currencySymbol)\(Int(totalGaveIn))")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.emergency)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .splurjCard(.elevated)
        .opacity(vm.appeared ? 1 : 0)
        .offset(y: vm.appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.20), value: vm.appeared)
    }

    // MARK: - Floating Actions

    private var floatingActions: some View {
        VStack(spacing: 10) {
            Button {
                vm.showLogWin = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.accentGreen)
                        .frame(width: 60, height: 60)
                        .shadow(color: Theme.accentGreen.opacity(0.4), radius: 12, y: 4)

                    Image(systemName: "plus")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.background)
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: vm.showLogWin)
            .accessibilityLabel("Log a win")
            .accessibilityHint("Record an impulse you resisted")

            Button {
                vm.showAutopsy = true
            } label: {
                Text("I gave in")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.cardSurface, in: .capsule)
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.textSecondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(SplurjButtonStyle(variant: .ghost, size: .medium))
            .accessibilityLabel("I gave in")
            .accessibilityHint("Log a spending slip for reflection")
        }
        .padding(.bottom, 8)
        .fullScreenCover(isPresented: $vm.showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Supporting Views

private struct WalletStatPill: View {
    let label: String
    let amount: Double
    let color: Color
    let gentle: Bool
    let revealExact: Bool
    var currencyCode: String = "USD"

    var body: some View {
        VStack(spacing: 6) {
            if gentle && !revealExact {
                Text("~\(CurrencyHelper.symbol(for: currencyCode))\(Int((amount / 10).rounded() * 10))")
                    .font(Typography.moneySmall)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text(amount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                    .font(Typography.moneySmall)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .splurjCard(.outlined)
    }
}

private struct WalletTransactionRow: View {
    let log: ImpulseLog
    let gentle: Bool
    let revealExact: Bool
    var currencyCode: String = "USD"

    private var sym: String { CurrencyHelper.symbol(for: currencyCode) }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(log.resisted ? Theme.accentGreen.opacity(0.15) : Theme.emergency.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: log.resisted ? "checkmark" : "arrow.uturn.backward")
                        .font(Typography.labelSmall)
                        .foregroundStyle(log.resisted ? Theme.accentGreen : Theme.emergency)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(log.note.isEmpty ? (log.resisted ? "Impulse resisted" : "Gave in") : log.note)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(log.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)

                    if !log.emotionalTrigger.isEmpty {
                        Text(log.emotionalTrigger)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.teal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.teal.opacity(0.12), in: .capsule)
                    }
                }
            }

            Spacer()

            if gentle && !revealExact {
                Text(log.resisted ? "+~\(sym)\(Int((log.amount / 10).rounded() * 10))" : "-~\(sym)\(Int((log.amount / 10).rounded() * 10))")
                    .font(Typography.headingSmall)
                    .foregroundStyle(log.resisted ? Theme.accentGreen : Theme.emergency)
            } else {
                Text(log.resisted ? "+\(sym)\(log.amount, specifier: "%.0f")" : "-\(sym)\(log.amount, specifier: "%.0f")")
                    .font(Typography.headingSmall)
                    .foregroundStyle(log.resisted ? Theme.accentGreen : Theme.emergency)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.cardSurface)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Sparkle Particles

struct SparkleParticlesView: View {
    @State private var particles: [SparkleParticle] = (0..<8).map { _ in SparkleParticle() }
    @State private var animating = false

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let x = size.width * particle.x + (animating ? CGFloat.random(in: -4...4) : 0)
                let y = size.height * particle.y + (animating ? CGFloat.random(in: -4...4) : 0)
                let opacity = animating ? particle.opacity : particle.opacity * 0.5
                context.opacity = opacity
                let symbol = context.resolve(Image(systemName: "sparkle"))
                let sz = particle.size
                context.draw(symbol, in: CGRect(x: x - sz/2, y: y - sz/2, width: sz, height: sz))
            }
        }
        .foregroundStyle(Theme.gold)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}

private struct SparkleParticle {
    let x: CGFloat = .random(in: 0.1...0.9)
    let y: CGFloat = .random(in: 0.1...0.9)
    let opacity: Double = .random(in: 0.3...0.8)
    let size: CGFloat = .random(in: 6...12)
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    let amount: Double
    let onDismiss: () -> Void
    @State private var show = false
    @State private var coinY: CGFloat = -100
    @State private var coinScale: CGFloat = 1.2
    @State private var confettiTrigger: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(show ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.gold)
                    .scaleEffect(coinScale)
                    .offset(y: coinY)

                Text("+\(CurrencyHelper.symbol(for: "USD"))\(Int(amount))")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.accentGreen)

                Text("saved!")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)
            }
            .scaleEffect(show ? 1 : 0.5)
            .opacity(show ? 1 : 0)

            ConfettiView(trigger: confettiTrigger)
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                show = true
                coinY = 0
                coinScale = 1.0
            }
            confettiTrigger += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
        .sensoryFeedback(.success, trigger: show)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            show = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Milestone Overlay

struct MilestoneOverlay: View {
    let amount: Double
    let onDismiss: () -> Void
    @State private var show = false
    @State private var flashOpacity: Double = 0
    @State private var showMilestoneShare = false

    var body: some View {
        ZStack {
            Color.white.opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Color.black.opacity(show ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.goldGradient)
                    .symbolEffect(.bounce, value: show)

                Text("MILESTONE!")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.gold)
                    .tracking(4)

                Text("$\(Int(amount))")
                    .font(Typography.moneyHero)
                    .foregroundStyle(Theme.textPrimary)

                Text("You've reached a new level!")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 12) {
                    Button {
                        showMilestoneShare = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(Typography.headingSmall)
                            Text("Share")
                                .font(Typography.headingMedium)
                        }
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.goldGradient, in: .capsule)
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))

                    Button {
                        dismiss()
                    } label: {
                        Text("Later")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .ghost, size: .medium))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .scaleEffect(show ? 1 : 0.3)
            .opacity(show ? 1 : 0)

            ConfettiView(trigger: show ? 1 : 0)
                .allowsHitTesting(false)
        }
        .sheet(isPresented: $showMilestoneShare, onDismiss: { dismiss() }) {
            MilestoneShareSheet(milestoneAmount: amount)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.15)) {
                flashOpacity = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.3)) {
                    flashOpacity = 0
                }
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                show = true
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: show)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            show = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    let trigger: Int
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        Canvas { context, size in
            for p in particles {
                context.opacity = p.opacity
                context.fill(
                    Path(ellipseIn: CGRect(x: p.x * size.width - 4, y: p.y * size.height - 4, width: 8, height: 8)),
                    with: .color(p.color)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        particles = (0..<40).map { _ in
            ConfettiParticle(
                x: .random(in: 0.1...0.9),
                y: -0.1,
                opacity: 1,
                color: [Theme.accentGreen, Theme.gold, Theme.teal, Theme.emergency, .white].randomElement()!
            )
        }
        withAnimation(.easeOut(duration: 1.5)) {
            particles = particles.map { p in
                ConfettiParticle(
                    x: p.x + .random(in: -0.2...0.2),
                    y: .random(in: 0.6...1.2),
                    opacity: 0,
                    color: p.color
                )
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var color: Color
}
