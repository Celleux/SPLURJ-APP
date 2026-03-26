import SwiftUI

struct MMProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80

    @State private var animatedProgress: Double = 0

    private let gradient = AngularGradient(
        gradient: Gradient(colors: [
            Theme.accent,
            Theme.accent.opacity(0.8),
            Theme.secondary.opacity(0.9),
            Theme.secondary
        ]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.border, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(Theme.accent.opacity(0.15))
                .frame(width: lineWidth + 4, height: lineWidth + 4)
                .offset(y: -(size - lineWidth) / 2)
                .rotationEffect(.degrees(animatedProgress * 360 - 90))
                .opacity(animatedProgress > 0.03 ? 1 : 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = min(max(progress, 0), 1)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
}
