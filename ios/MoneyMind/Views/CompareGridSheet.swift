import SwiftUI

struct CompareGridSheet: View {
    let participants: [ChallengeParticipant]
    let checkIns: [ChallengeCheckIn]
    let startDate: Date
    let endDate: Date

    @Environment(\.dismiss) private var dismiss

    private var allDays: [Date] {
        let cal = Calendar.current
        var days: [Date] = []
        var current = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        while current <= end {
            days.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    private var leadingPadding: Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: allDays.first ?? startDate)
        return (weekday + 5) % 7
    }

    private func checkInsForParticipant(_ p: ChallengeParticipant) -> [String: ChallengeCheckIn] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var dict: [String: ChallengeCheckIn] = [:]
        for ci in checkIns where ci.participantID == p.id {
            dict[formatter.string(from: ci.date)] = ci
        }
        return dict
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(participants, id: \.id) { participant in
                        participantGrid(participant)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Compare All")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func participantGrid(_ p: ChallengeParticipant) -> some View {
        let ciMap = checkInsForParticipant(p)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let days = allDays

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(p.emoji.isEmpty ? "👤" : p.emoji)
                    .font(.system(size: 20))
                Text(p.displayName)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("🔥 \(p.currentStreak)")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.gold)
            }

            LazyVGrid(columns: gridColumns, spacing: 2) {
                ForEach(weekdayHeaders.indices, id: \.self) { i in
                    Text(weekdayHeaders[i])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                        .frame(height: 14)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 2) {
                ForEach(0..<leadingPadding, id: \.self) { _ in
                    Color.clear.frame(width: 24, height: 24)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    let key = formatter.string(from: day)
                    let ci = ciMap[key]
                    let isFuture = day > today

                    compareDayCell(checkIn: ci, isFuture: isFuture, index: index, ciMap: ciMap, days: days)
                }
            }
        }
        .splurjCard(.elevated)
    }

    @ViewBuilder
    private func compareDayCell(checkIn: ChallengeCheckIn?, isFuture: Bool, index: Int, ciMap: [String: ChallengeCheckIn], days: [Date]) -> some View {
        let color = compareCellColor(checkIn: checkIn, isFuture: isFuture, index: index, ciMap: ciMap, days: days)

        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay {
                if isFuture {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Theme.elevated, lineWidth: 0.5)
                }
                if checkIn?.shieldUsed == true {
                    Image(systemName: "snowflake")
                        .font(.system(size: 6))
                        .foregroundStyle(.white)
                }
            }
    }

    private func compareCellColor(checkIn: ChallengeCheckIn?, isFuture: Bool, index: Int, ciMap: [String: ChallengeCheckIn], days: [Date]) -> Color {
        if isFuture { return Theme.surface }
        guard let ci = checkIn else { return Theme.elevated.opacity(0.5) }
        if ci.shieldUsed { return Theme.accentTertiary.opacity(0.6) }
        if !ci.didHold { return Theme.danger.opacity(0.6) }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var streak = 0
        var i = index
        while i >= 0 {
            let key = formatter.string(from: days[i])
            if let c = ciMap[key], c.didHold {
                streak += 1
                i -= 1
            } else {
                break
            }
        }
        if streak >= 7 { return Color(hex: 0x2ECC71).opacity(0.7) }
        return Theme.accent.opacity(0.6)
    }
}
