import SwiftUI

struct UnifiedProgressRing: View {
    let dailyProgress: Double
    let weeklyProgress: Double
    let bossProgress: Double
    let level: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animatedDaily: Double = 0
    @State private var animatedWeekly: Double = 0
    @State private var animatedBoss: Double = 0

    private let ringWidth: CGFloat = 5
    private let ringSpacing: CGFloat = 4

    var body: some View {
        ZStack {
            ring(progress: animatedDaily, color: Theme.accent, radius: 38)
            ring(progress: animatedWeekly, color: Theme.neonGold, radius: 38 - ringWidth - ringSpacing)
            ring(progress: animatedBoss, color: Theme.neonRed, radius: 38 - (ringWidth + ringSpacing) * 2)

            Text("\(level)")
                .font(Typography.headingMedium)
                .foregroundStyle(.white)
        }
        .frame(width: 80, height: 80)
        .onAppear {
            if reduceMotion {
                animatedDaily = dailyProgress
                animatedWeekly = weeklyProgress
                animatedBoss = bossProgress
            } else {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animatedDaily = dailyProgress
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                    animatedWeekly = weeklyProgress
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                    animatedBoss = bossProgress
                }
            }
        }
        .onChange(of: dailyProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) { animatedDaily = newValue }
        }
        .onChange(of: weeklyProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) { animatedWeekly = newValue }
        }
        .onChange(of: bossProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) { animatedBoss = newValue }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level). Daily quests \(Int(dailyProgress * 100))%, weekly challenge \(Int(weeklyProgress * 100))%, boss damage \(Int(bossProgress * 100))%")
    }

    private func ring(progress: Double, color: Color, radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: ringWidth)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct UnifiedProgressRingLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: Theme.accent, label: "Daily")
            legendItem(color: Theme.neonGold, label: "Weekly")
            legendItem(color: Theme.neonRed, label: "Boss")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
    }
}
