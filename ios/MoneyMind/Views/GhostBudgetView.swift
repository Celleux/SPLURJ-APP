import SwiftUI
import SwiftData

struct GhostBudgetView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var quizResults: [QuizResult]
    @Environment(PremiumManager.self) private var premiumManager
    @State private var vm = GhostBudgetViewModel()
    @State private var showShare = false
    @State private var shareImage: UIImage?
    @State private var equivalentTimer: Timer?

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                    .staggerIn(appeared: vm.appeared, delay: 0.0)

                if vm.categories.isEmpty {
                    emptyState
                        .staggerIn(appeared: vm.appeared, delay: 0.1)
                } else {
                    habitToggles
                        .staggerIn(appeared: vm.appeared, delay: 0.08)

                    if !vm.eliminatedCategories.isEmpty {
                        timelineSelector
                            .staggerIn(appeared: vm.appeared, delay: 0.14)

                        savingsCallout
                            .staggerIn(appeared: vm.appeared, delay: 0.20)

                        comparisonChart
                            .staggerIn(appeared: vm.appeared, delay: 0.26)

                        shareButton
                            .staggerIn(appeared: vm.appeared, delay: 0.32)
                    } else {
                        promptCard
                            .staggerIn(appeared: vm.appeared, delay: 0.14)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Ghost Budget")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: vm.toggleHaptic)
        .sensoryFeedback(.impact(weight: .medium), trigger: vm.horizonHaptic)
        .sheet(isPresented: $showShare) {
            if let shareImage {
                GhostSharePreviewSheet(image: shareImage)
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            vm.loadCategories(transactions: transactions)
            withAnimation(.easeOut(duration: 0.1)) {
                vm.appeared = true
            }
            startEquivalentCycling()
        }
        .onDisappear {
            equivalentTimer?.invalidate()
            equivalentTimer = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Text("👻")
                .font(Typography.displayMedium)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ghost Budget")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)

                Text("What if you changed your habits?")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            if !premiumManager.hasFullAccess {
                Label("PRO", systemImage: "crown.fill")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.gold.opacity(0.12), in: .capsule)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Habit Toggles

    private var habitToggles: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Spending Habits")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(vm.eliminatedCategories.count) eliminated")
                    .font(Typography.bodySmall)
                    .foregroundStyle(vm.eliminatedCategories.isEmpty ? Theme.textMuted : Theme.accent)
            }

            VStack(spacing: 0) {
                ForEach(vm.categories) { cat in
                    habitToggleRow(cat)

                    if cat.id != vm.categories.last?.id {
                        Rectangle()
                            .fill(Theme.border)
                            .frame(height: 0.5)
                            .padding(.leading, 48)
                    }
                }
            }
            .splurjCard(.elevated)
        }
    }

    private func habitToggleRow(_ item: GhostCategoryItem) -> some View {
        Button {
            withAnimation(Theme.spring) {
                vm.toggleCategory(item.id)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.isEliminated ? Theme.accent.opacity(0.15) : item.color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(item.isEliminated ? Theme.accent : item.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Text("~$\(Int(item.monthlyAverage))/mo avg")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                ZStack {
                    Capsule()
                        .fill(item.isEliminated ? Theme.accent : Theme.elevated)
                        .frame(width: 48, height: 28)

                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .offset(x: item.isEliminated ? 10 : -10)
                }
                .animation(Theme.spring, value: item.isEliminated)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                item.isEliminated
                    ? Theme.accent.opacity(0.04)
                    : Color.clear
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline Selector

    private var timelineSelector: some View {
        HStack(spacing: 6) {
            ForEach(TimelineHorizon.allCases, id: \.rawValue) { horizon in
                Button {
                    withAnimation(Theme.spring) {
                        vm.selectHorizon(horizon)
                    }
                } label: {
                    Text(horizon.rawValue)
                        .font(Typography.headingSmall)
                        .foregroundStyle(
                            vm.selectedHorizon == horizon ? .white : Theme.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            vm.selectedHorizon == horizon
                                ? Theme.accent
                                : Theme.elevated,
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .splurjCard(.subtle)
    }

    // MARK: - Savings Callout

    private var savingsCallout: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("You'd have")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textMuted)

                ZStack {
                    Circle()
                        .fill(Theme.success.opacity(0.06))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    MMAmountDisplay(
                        amount: vm.projectedSavings,
                        font: Theme.amountLG,
                        color: Theme.success
                    )
                }

                Text("more in \(vm.selectedHorizon.label)")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.success.opacity(0.8))
            }

            if let equiv = vm.currentEquivalent {
                HStack(spacing: 6) {
                    Text(equiv.emoji)
                        .font(Typography.labelLarge)
                    Text(equiv.text)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("equiv-\(vm.equivalentIndex)")
                .animation(.easeInOut(duration: 0.4), value: vm.equivalentIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .splurjCard(.elevated)
    }

    // MARK: - Comparison Chart

    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Balance Projection")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 16) {
                chartLegendDot(color: Theme.textSecondary, label: "Reality")
                chartLegendDot(color: Theme.success, label: "Ghost")
            }

            GhostComparisonChart(
                points: vm.chartPoints,
                drawProgress: vm.lineDrawProgress,
                maxValue: vm.projectedSavings
            )
            .frame(height: 200)
            .onAppear {
                vm.animateLines()
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private func chartLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            generateAndShare()
        } label: {
            Label("Share My Ghost Budget", systemImage: "square.and.arrow.up")
                .font(Typography.headingMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accent, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
    }

    // MARK: - Prompt Card

    private var promptCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.tap.fill")
                .font(Typography.displayMedium)
                .foregroundStyle(Theme.accent.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)

            Text("Toggle a spending category\nto see your ghost timeline")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .splurjCard(.elevated)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        PersonalityEmptyStateView(
            personality: personality,
            icon: "eye.trianglebadge.exclamationmark.fill",
            secondaryIcon: "chart.line.flattrend.xyaxis",
            headline: "Not Enough Data Yet",
            subtext: "Add some transactions first so we can\nanalyze your spending habits"
        )
    }

    // MARK: - Helpers

    private func startEquivalentCycling() {
        equivalentTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    vm.cycleEquivalent()
                }
            }
        }
    }

    private func generateAndShare() {
        let card = GhostBudgetShareCard(
            savings: vm.projectedSavings,
            timeframe: vm.selectedHorizon.label,
            topHabit: vm.topEliminatedName ?? "spending",
            personalityColor: personality.color,
            personalityIcon: personality.icon
        )
        shareImage = ShareCardRenderer.render(card)
        if shareImage != nil {
            showShare = true
        }
    }
}

// MARK: - Comparison Chart

struct GhostComparisonChart: View {
    let points: [GhostChartPoint]
    let drawProgress: CGFloat
    let maxValue: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxY = max(maxValue * 1.15, 1)
            let count = max(points.count - 1, 1)

            ZStack(alignment: .bottom) {
                ForEach(0..<4, id: \.self) { i in
                    let yPos = h - (h * CGFloat(i) / 3.0)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: yPos))
                        path.addLine(to: CGPoint(x: w, y: yPos))
                    }
                    .stroke(Theme.border.opacity(0.4), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                }

                realityLine(w: w, h: h, maxY: maxY, count: count)
                ghostLine(w: w, h: h, maxY: maxY, count: count)
                ghostArea(w: w, h: h, maxY: maxY, count: count)

                if drawProgress > 0.95, let last = points.last {
                    let x = w
                    let y = h - (CGFloat(last.ghostBalance / maxY) * h)
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                        .transition(.scale)
                }
            }
        }
    }

    private func realityLine(w: CGFloat, h: CGFloat, maxY: Double, count: Int) -> some View {
        Path { path in
            for (i, point) in points.enumerated() {
                let x = w * CGFloat(i) / CGFloat(count)
                let y = h - (CGFloat(point.realityBalance / maxY) * h)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
        .trim(from: 0, to: drawProgress)
        .stroke(
            LinearGradient(
                colors: [Theme.ghostRed, Theme.textSecondary],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func ghostLine(w: CGFloat, h: CGFloat, maxY: Double, count: Int) -> some View {
        Path { path in
            for (i, point) in points.enumerated() {
                let x = w * CGFloat(i) / CGFloat(count)
                let y = h - (CGFloat(point.ghostBalance / maxY) * h)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
        .trim(from: 0, to: drawProgress)
        .stroke(
            LinearGradient(
                colors: [Theme.success, Theme.success.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    private func ghostArea(w: CGFloat, h: CGFloat, maxY: Double, count: Int) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: h))
            for (i, point) in points.enumerated() {
                let x = w * CGFloat(i) / CGFloat(count)
                let y = h - (CGFloat(point.ghostBalance / maxY) * h)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Theme.success.opacity(0.12), Theme.success.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .opacity(Double(drawProgress))
    }
}

// MARK: - Ghost Share Preview Sheet

struct GhostSharePreviewSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    .padding(.horizontal, 40)

                ShareLink(item: Image(uiImage: image), preview: SharePreview("My Ghost Budget", image: Image(uiImage: image))) {
                    Label("Share Image", systemImage: "square.and.arrow.up")
                        .font(Typography.headingMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}
