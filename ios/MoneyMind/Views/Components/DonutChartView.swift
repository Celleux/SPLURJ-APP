import SwiftUI

struct DonutChartView: View {
    let segments: [CategorySpending]
    @Binding var selectedIndex: Int?

    @State private var animatedEndAngles: [Double] = []
    @State private var appeared = false

    private let lineWidth: CGFloat = 28
    private let size: CGFloat = 200

    private var totalSpent: Double {
        segments.reduce(0) { $0 + $1.spent }
    }

    private var segmentAngles: [(start: Double, end: Double)] {
        guard totalSpent > 0 else { return [] }
        var angles: [(Double, Double)] = []
        var current: Double = -90
        for seg in segments {
            let sweep = (seg.spent / totalSpent) * 360
            angles.append((current, current + sweep))
            current += sweep
        }
        return angles
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Theme.accent)
                Text("Where Your Money Goes")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            if segments.isEmpty || totalSpent == 0 {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textMuted)
                    Text("No spending data yet")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ZStack {
                    ForEach(segments.indices, id: \.self) { i in
                        let angles = segmentAngles
                        if i < angles.count && i < animatedEndAngles.count {
                            DonutSegment(
                                startAngle: .degrees(angles[i].start),
                                endAngle: .degrees(animatedEndAngles[i]),
                                lineWidth: lineWidth
                            )
                            .fill(segments[i].color.opacity(selectedIndex == nil || selectedIndex == i ? 1 : 0.3))
                            .scaleEffect(selectedIndex == i ? 1.06 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedIndex = selectedIndex == i ? nil : i
                                }
                            }
                        }
                    }

                    if let idx = selectedIndex, idx < segments.count {
                        VStack(spacing: 2) {
                            Text(segments[idx].name)
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textSecondary)
                            Text("$\(Int(segments[idx].spent))")
                                .font(Typography.displaySmall)
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(Int(segments[idx].percentage))%")
                                .font(Typography.bodySmall)
                                .foregroundStyle(segments[idx].color)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: 2) {
                            Text("Total")
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textSecondary)
                            Text("$\(Int(totalSpent))")
                                .font(Typography.displaySmall)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity)

                legend
            }
        }
        .padding(20)
        .splurjCard(.elevated)
        .onAppear {
            guard !appeared else { return }
            appeared = true
            let angles = segmentAngles
            animatedEndAngles = angles.map { $0.start }
            for i in angles.indices {
                withAnimation(.easeInOut(duration: 0.6).delay(Double(i) * 0.12)) {
                    animatedEndAngles[i] = angles[i].end
                }
            }
        }
        .onChange(of: segments.count) { _, _ in
            resetAnimations()
        }
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(segments.indices, id: \.self) { i in
                let seg = segments[i]
                HStack(spacing: 10) {
                    Circle()
                        .fill(seg.color)
                        .frame(width: 8, height: 8)

                    Text(seg.name)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text("$\(Int(seg.spent))")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Text("\(Int(seg.percentage))%")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .background(selectedIndex == i ? seg.color.opacity(0.08) : .clear, in: .rect(cornerRadius: 6))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = selectedIndex == i ? nil : i
                    }
                }
            }
        }
    }

    private func resetAnimations() {
        let angles = segmentAngles
        animatedEndAngles = angles.map { $0.start }
        for i in angles.indices {
            withAnimation(.easeInOut(duration: 0.6).delay(Double(i) * 0.12)) {
                animatedEndAngles[i] = angles[i].end
            }
        }
    }
}

private struct DonutSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
    }
}
