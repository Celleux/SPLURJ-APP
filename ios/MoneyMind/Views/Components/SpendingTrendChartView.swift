import SwiftUI

struct SpendingTrendChartView: View {
    let data: [MonthlySpending]
    let isCurrentMonthSelected: Bool

    @State private var animatedProgress: CGFloat = 0
    @State private var hoveredIndex: Int? = nil

    private let chartHeight: CGFloat = 160
    private let dotSize: CGFloat = 8

    private var maxValue: Double {
        max(data.map(\.total).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(Theme.accent)
                Text("Spending Trend")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let last = data.last, last.total > 0 {
                    Text("$\(Int(last.total)) this month")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if data.allSatisfy({ $0.total == 0 }) {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.flattrend.xyaxis")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textMuted)
                    Text("Not enough data yet")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Keep tracking to see your trend")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                GeometryReader { geo in
                    let width = geo.size.width
                    let stepX = data.count > 1 ? width / CGFloat(data.count - 1) : width
                    let points = data.enumerated().map { i, item in
                        CGPoint(
                            x: CGFloat(i) * stepX,
                            y: chartHeight - (CGFloat(item.total / maxValue) * (chartHeight - 24))
                        )
                    }

                    ZStack {
                        gridLines(width: width)

                        if points.count >= 2 {
                            let solidPoints = isCurrentMonthSelected ? points : Array(points.dropLast())
                            let lastTwo = isCurrentMonthSelected ? [] : Array(points.suffix(2))

                            Path { path in
                                guard let first = solidPoints.first else { return }
                                path.move(to: first)
                                for pt in solidPoints.dropFirst() {
                                    path.addLine(to: pt)
                                }
                            }
                            .trim(from: 0, to: animatedProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )

                            if lastTwo.count == 2 {
                                Path { path in
                                    path.move(to: lastTwo[0])
                                    path.addLine(to: lastTwo[1])
                                }
                                .trim(from: 0, to: animatedProgress)
                                .stroke(
                                    Theme.secondary.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4])
                                )
                            }

                            Path { path in
                                guard let first = solidPoints.first else { return }
                                path.move(to: first)
                                for pt in solidPoints.dropFirst() {
                                    path.addLine(to: pt)
                                }
                                if let last = solidPoints.last {
                                    path.addLine(to: CGPoint(x: last.x, y: chartHeight))
                                    path.addLine(to: CGPoint(x: 0, y: chartHeight))
                                }
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [Theme.accent.opacity(0.15), Theme.accent.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(Double(animatedProgress))
                        }

                        ForEach(points.indices, id: \.self) { i in
                            let isLast = i == points.count - 1
                            let isDashed = !isCurrentMonthSelected && isLast

                            Circle()
                                .fill(isDashed ? Theme.secondary.opacity(0.5) : Theme.accent)
                                .frame(width: hoveredIndex == i ? 12 : dotSize, height: hoveredIndex == i ? 12 : dotSize)
                                .shadow(color: Theme.accent.opacity(0.4), radius: hoveredIndex == i ? 6 : 0)
                                .position(points[i])
                                .opacity(Double(animatedProgress))
                                .animation(.spring(response: 0.3), value: hoveredIndex)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        hoveredIndex = hoveredIndex == i ? nil : i
                                    }
                                }

                            if hoveredIndex == i {
                                Text("$\(Int(data[i].total))")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.elevated, in: .capsule)
                                    .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                                    .position(x: points[i].x, y: max(points[i].y - 20, 12))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }

                    HStack(spacing: 0) {
                        ForEach(data.indices, id: \.self) { i in
                            Text(data[i].label)
                                .font(Typography.labelSmall)
                                .foregroundStyle(i == data.count - 1 ? Theme.textPrimary : Theme.textMuted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .offset(y: chartHeight + 8)
                }
                .frame(height: chartHeight + 28)
            }
        }
        .padding(20)
        .splurjCard(.elevated)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = 1
            }
        }
    }

    private func gridLines(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Spacer()
                Rectangle()
                    .fill(Theme.border.opacity(0.4))
                    .frame(height: 0.5)
            }
        }
        .frame(height: chartHeight)
    }
}
