import SwiftUI

struct NoSpendChallengeView: View {
    @Bindable var challenge: SavingsChallenge
    @Bindable var vm: ChallengesViewModel
    let personalityColor: Color
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var displayedMonth = Date()
    @State private var shareTrigger = false

    private let calendar = Calendar.current
    private let dayColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var streakMilestones: [(Int, String, String)] {
        [
            (3, "3-Day Warrior", "flame.fill"),
            (7, "Week Champion", "star.fill"),
            (14, "Fortnight Hero", "shield.fill"),
            (30, "Month Master", "crown.fill")
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    streakHeader
                    milestoneRow
                    calendarSection
                    shareSection
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("No-Spend Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .overlay {
                if vm.showCelebration {
                    ChallengesCelebrationOverlay(
                        message: vm.celebrationMessage,
                        particles: vm.confettiParticles
                    ) {
                        vm.showCelebration = false
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: vm.hapticTrigger)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    private var streakHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(personalityColor.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(personalityColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)

                VStack(spacing: 2) {
                    Text("\(challenge.noSpendStreak)")
                        .font(Typography.displayMedium)
                        .foregroundStyle(personalityColor)
                    Text("day streak")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(challenge.noSpendDays.count)")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.success)
                    Text("No-Spend")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
                VStack(spacing: 4) {
                    Text("\(challenge.spentDays.count)")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.danger)
                    Text("Spent")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
                VStack(spacing: 4) {
                    Text("\(challenge.daysActive)")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Days In")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .splurjCard(.hero)
        .padding(.top, 8)
    }

    private var milestoneRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(streakMilestones, id: \.0) { days, name, icon in
                    let earned = challenge.noSpendStreak >= days
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(earned ? personalityColor.opacity(0.15) : Theme.elevated)
                                .frame(width: 44, height: 44)
                            Image(systemName: icon)
                                .font(Typography.bodyLarge)
                                .foregroundStyle(earned ? personalityColor : Theme.textMuted)
                        }
                        Text(name)
                            .font(Typography.labelSmall)
                            .foregroundStyle(earned ? Theme.textPrimary : Theme.textMuted)
                        Text("\(days)d")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(
                        earned ? personalityColor.opacity(0.06) : Color.clear,
                        in: .rect(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(earned ? personalityColor.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private var calendarSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(monthYearString(displayedMonth))
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }

            LazyVGrid(columns: dayColumns, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                        .frame(height: 24)
                }

                ForEach(daysInMonth(), id: \.self) { item in
                    if item.day == 0 {
                        Color.clear.frame(height: 40)
                    } else {
                        DayCell(
                            day: item.day,
                            date: item.date,
                            status: dayStatus(item.date),
                            isFuture: item.date > Date(),
                            personalityColor: personalityColor,
                            onNoSpend: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    vm.markNoSpendDay(item.date, challenge: challenge)
                                }
                            },
                            onSpent: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    vm.markSpentDay(item.date, challenge: challenge)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private var shareSection: some View {
        Button {
            shareTrigger = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Progress")
            }
            .font(Typography.headingSmall)
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent.opacity(0.1), in: .rect(cornerRadius: 12))
        }
        .buttonStyle(SplurjButtonStyle(variant: .secondary, size: .medium))
        .sheet(isPresented: $shareTrigger) {
            let text = vm.shareChallenge(challenge)
            ShareSheetView(items: [text])
                .presentationDetents([.medium])
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dayStatus(_ date: Date) -> DayCellStatus {
        let key = dateKey(date)
        if challenge.noSpendDays.contains(key) { return .noSpend }
        if challenge.spentDays.contains(key) { return .spent }
        return .unmarked
    }

    private func daysInMonth() -> [CalendarDayItem] {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: comps) else { return [] }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<31

        var items: [CalendarDayItem] = []
        for _ in 1..<weekday {
            items.append(CalendarDayItem(day: 0, date: Date.distantPast))
        }
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? firstOfMonth
            items.append(CalendarDayItem(day: day, date: date))
        }
        return items
    }
}

nonisolated enum DayCellStatus: Sendable {
    case noSpend, spent, unmarked
}

nonisolated struct CalendarDayItem: Hashable, Sendable {
    let day: Int
    let date: Date
}

private struct DayCell: View {
    let day: Int
    let date: Date
    let status: DayCellStatus
    let isFuture: Bool
    let personalityColor: Color
    let onNoSpend: () -> Void
    let onSpent: () -> Void

    var body: some View {
        Button {
            switch status {
            case .unmarked:
                onNoSpend()
            case .noSpend:
                onSpent()
            case .spent:
                onNoSpend()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                if status != .unmarked {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }

                Text("\(day)")
                    .font(.system(size: 13, weight: status == .unmarked ? .regular : .semibold, design: .rounded))
                    .foregroundStyle(textColor)
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.3 : 1)
        .accessibilityLabel("Day \(day), \(statusLabel)")
    }

    private var backgroundColor: Color {
        switch status {
        case .noSpend: Theme.success.opacity(0.15)
        case .spent: Theme.danger.opacity(0.15)
        case .unmarked: Theme.elevated
        }
    }

    private var borderColor: Color {
        switch status {
        case .noSpend: Theme.success.opacity(0.5)
        case .spent: Theme.danger.opacity(0.5)
        case .unmarked: .clear
        }
    }

    private var textColor: Color {
        switch status {
        case .noSpend: Theme.success
        case .spent: Theme.danger
        case .unmarked: Theme.textSecondary
        }
    }

    private var statusLabel: String {
        switch status {
        case .noSpend: "no spend"
        case .spent: "spent"
        case .unmarked: "unmarked"
        }
    }
}
