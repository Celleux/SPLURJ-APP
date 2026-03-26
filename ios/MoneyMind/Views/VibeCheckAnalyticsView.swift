import SwiftUI
import SwiftData

struct VibeCheckAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @Query(sort: \VibeCheckEntry.timestamp, order: .reverse) private var entries: [VibeCheckEntry]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var quizResults: [QuizResult]

    @State private var vm = VibeCheckViewModel()
    @State private var selectedMonth: Date = Date()
    @State private var appeared: Bool = false

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private var months: [Date] {
        let calendar = Calendar.current
        var result: [Date] = []
        let now = Date()
        for offset in 0..<6 {
            if let month = calendar.date(byAdding: .month, value: -offset, to: now) {
                let comps = calendar.dateComponents([.year, .month], from: month)
                if let start = calendar.date(from: comps) {
                    result.append(start)
                }
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        sentimentSummary
                            .staggerIn(appeared: appeared, delay: 0.05)

                        moodMap
                            .staggerIn(appeared: appeared, delay: 0.15)

                        weeklyTrendSection
                            .staggerIn(appeared: appeared, delay: 0.25)

                        insightsSection
                            .staggerIn(appeared: appeared, delay: 0.35)

                        monthlyGrid
                            .staggerIn(appeared: appeared, delay: 0.45)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Your Spending Moods")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Theme.card, in: .circle)
                    }
                }
            }
            .onAppear {
                vm.load(entries: entries, transactions: transactions, personality: personality)
                withAnimation(.easeOut(duration: 0.1)) {
                    appeared = true
                }
            }
            .onChange(of: entries.count) { _, _ in
                vm.load(entries: entries, transactions: transactions, personality: personality)
            }
            .premiumGate(feature: "Advanced Mood Analytics", teaser: "Unlock detailed spending mood trends, insights, and monthly patterns")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        PersonalityEmptyStateView(
            personality: personality,
            icon: "face.smiling.inverse",
            secondaryIcon: "sparkle",
            headline: "No Vibes Yet",
            subtext: "Rate your purchases after saving\ntransactions to see mood analytics",
            buttonLabel: "Got it",
            buttonIcon: "checkmark"
        ) {
            dismiss()
        }
        .padding(.top, 40)
    }

    // MARK: - Sentiment Summary

    private var sentimentSummary: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(personality.color)
                Text("Mood Distribution")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            if !vm.moodDistribution.isEmpty {
                moodPieChart

                VStack(spacing: 10) {
                    ForEach(vm.moodDistribution, id: \.vibeType) { dist in
                        HStack(spacing: 12) {
                            Text(dist.vibeType.emoji)
                                .font(Typography.displaySmall)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(dist.vibeType.label)
                                        .font(Typography.headingSmall)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(Int(dist.percentage))%")
                                        .font(Typography.labelMedium)
                                        .foregroundStyle(personality.color)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Theme.elevated)
                                            .frame(height: 6)

                                        Capsule()
                                            .fill(colorForVibe(dist.vibeType))
                                            .frame(width: geo.size.width * CGFloat(dist.percentage / 100), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }

                            Spacer()

                            Text("$\(Int(dist.totalAmount))")
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                summaryText
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private var moodPieChart: some View {
        ZStack {
            let distribution = vm.moodDistribution
            let total = distribution.reduce(0) { $0 + $1.count }

            ForEach(Array(distribution.enumerated()), id: \.element.vibeType) { index, dist in
                let startAngle = startAngle(for: index, in: distribution, total: total)
                let endAngle = startAngle + Angle(degrees: 360 * Double(dist.count) / Double(max(total, 1)))

                VibeCheckPieSlice(startAngle: startAngle, endAngle: endAngle)
                    .fill(colorForVibe(dist.vibeType))
            }

            Circle()
                .fill(Theme.card)
                .frame(width: 80, height: 80)

            VStack(spacing: 2) {
                Text("\(entries.count)")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)
                Text("rated")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(height: 160)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var summaryText: some View {
        if let top = vm.topVibe {
            VStack(spacing: 6) {
                Text("\(Int(top.percentage))% of your purchases felt \(top.vibeType.label).")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                let regretDist = vm.moodDistribution.first(where: { $0.vibeType == .regret })
                if let regret = regretDist, regret.percentage < 15 {
                    Text("Only \(Int(regret.percentage))% were Regrets \u{2014} nice!")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.success)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Mood Map

    private var moodMap: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundStyle(personality.color)
                Text("Mood Map")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()

                monthPicker
            }

            let monthEntries = vm.monthlyEntries(for: selectedMonth)
            if monthEntries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textMuted)
                        Text("No ratings this month")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(Array(monthEntries.enumerated()), id: \.offset) { _, entry in
                        moodMapCell(entry)
                    }
                }
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private func moodMapCell(_ entry: VibeCheckEntry) -> some View {
        let vibe = entry.vibeType
        let intensity = min(entry.amount / 200, 1.0)

        return VStack(spacing: 2) {
            Text(vibe?.emoji ?? "?")
                .font(Typography.labelLarge)
            Text("$\(Int(entry.amount))")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            (vibe.map { colorForVibe($0) } ?? Theme.elevated).opacity(0.1 + intensity * 0.2),
            in: .rect(cornerRadius: 8)
        )
    }

    private var monthPicker: some View {
        Menu {
            ForEach(months, id: \.self) { month in
                Button {
                    selectedMonth = month
                } label: {
                    Text(month.formatted(.dateTime.month(.wide).year()))
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedMonth.formatted(.dateTime.month(.abbreviated)))
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.secondary)
                Image(systemName: "chevron.down")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.secondary.opacity(0.1), in: .capsule)
        }
    }

    // MARK: - Weekly Trend

    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(personality.color)
                Text("Trend Analysis")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            let trends = vm.weeklyTrends
            let maxCount = trends.map(\.count).max() ?? 1

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(trends.enumerated()), id: \.offset) { _, trend in
                    VStack(spacing: 6) {
                        if let vibe = trend.dominantVibe {
                            Text(vibe.emoji)
                                .font(Typography.bodySmall)
                        } else {
                            Text("-")
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textMuted)
                        }

                        let height = trend.count > 0
                            ? max(CGFloat(trend.count) / CGFloat(max(maxCount, 1)) * 80, 8)
                            : 4

                        let barColor: Color = {
                            guard let vibe = trend.dominantVibe else { return Theme.elevated }
                            return colorForVibe(vibe)
                        }()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor.opacity(trend.count > 0 ? 0.7 : 0.2))
                            .frame(height: height)

                        Text(trend.weekLabel)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130)
            .padding(.top, 4)

            sentimentTrendLine(trends)
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private func sentimentTrendLine(_ trends: [VibeCheckViewModel.WeeklyTrend]) -> some View {
        let activeTrends = trends.filter { $0.count > 0 }
        guard activeTrends.count >= 2 else { return AnyView(EmptyView()) }

        let firstSentiment = activeTrends.first?.averageSentiment ?? 0
        let lastSentiment = activeTrends.last?.averageSentiment ?? 0
        let improving = lastSentiment >= firstSentiment

        return AnyView(
            HStack(spacing: 6) {
                Image(systemName: improving ? "arrow.up.right" : "arrow.down.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(improving ? Theme.success : Theme.danger)
                Text(improving ? "Your spending mood is trending positive" : "Spending satisfaction dipped recently")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 4)
        )
    }

    // MARK: - Insights

    private var insightsSection: some View {
        let insights = vm.patternInsights
        guard !insights.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Theme.gold)
                    Text("Insights")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }

                VStack(spacing: 10) {
                    ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: insight.icon)
                                .font(Typography.labelLarge)
                                .foregroundStyle(personality.color)
                                .frame(width: 32, height: 32)
                                .background(personality.color.opacity(0.1), in: .rect(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(insight.title)
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(insight.description)
                                    .font(Typography.bodySmall)
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(Theme.elevated, in: .rect(cornerRadius: 14))
                    }
                }
            }
            .padding(20)
            .splurjCard(.elevated)
        )
    }

    // MARK: - Monthly Grid

    private var monthlyGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(personality.color)
                Text("Monthly Overview")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            ForEach(months.prefix(3), id: \.self) { month in
                let monthEntries = vm.monthlyEntries(for: month)
                if !monthEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(month.formatted(.dateTime.month(.wide).year()))
                            .font(Typography.labelMedium)
                            .foregroundStyle(Theme.textSecondary)

                        let grouped = Dictionary(grouping: monthEntries) { $0.emoji }
                        let total = monthEntries.count
                        let totalAmount = monthEntries.reduce(0.0) { $0 + $1.amount }

                        HStack(spacing: 14) {
                            ForEach(VibeType.allCases, id: \.self) { vibe in
                                let count = grouped[vibe.emoji]?.count ?? 0
                                if count > 0 {
                                    VStack(spacing: 4) {
                                        Text(vibe.emoji)
                                            .font(Typography.bodyLarge)
                                        Text("\(count)")
                                            .font(Typography.labelMedium)
                                            .foregroundStyle(Theme.textPrimary)
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(total) rated")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textSecondary)
                                Text("$\(Int(totalAmount))")
                                    .font(Typography.labelMedium)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Theme.elevated, in: .rect(cornerRadius: 14))
                }
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    // MARK: - Helpers

    private func colorForVibe(_ vibe: VibeType) -> Color {
        switch vibe {
        case .worthIt: Theme.success
        case .meh: Theme.textMuted
        case .regret: Theme.danger
        case .necessary: Theme.secondary
        case .flex: Theme.gold
        }
    }

    private func startAngle(for index: Int, in distribution: [VibeCheckViewModel.MoodDistribution], total: Int) -> Angle {
        let precedingCount = distribution.prefix(index).reduce(0) { $0 + $1.count }
        return Angle(degrees: -90 + 360 * Double(precedingCount) / Double(max(total, 1)))
    }
}

struct VibeCheckPieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
