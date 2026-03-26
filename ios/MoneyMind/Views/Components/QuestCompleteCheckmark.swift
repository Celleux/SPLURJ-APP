import SwiftUI

struct CheckmarkShape: Shape {
    var trimEnd: CGFloat

    var animatableData: CGFloat {
        get { trimEnd }
        set { trimEnd = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.22, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.30))
        return path.trimmedPath(from: 0, to: trimEnd)
    }
}

struct QuestCompleteCheckmark: View {
    let xpEarned: Int
    let onFinished: () -> Void

    @State private var fillExpand: Bool = false
    @State private var checkmarkTrim: CGFloat = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var xpFloatOffset: CGFloat = 0
    @State private var xpFloatOpacity: Double = 1.0
    @State private var showCheckmark: Bool = false
    @State private var overallOpacity: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.accent)
                .scaleEffect(fillExpand ? 1.0 : 0.0, anchor: .center)
                .opacity(fillExpand ? 1.0 : 0.0)

            if showCheckmark {
                CheckmarkShape(trimEnd: checkmarkTrim)
                    .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 56, height: 56)
            }

            if xpFloatOpacity > 0 && xpFloatOffset != 0 {
                Text("+\(xpEarned) XP")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 8)
                    .offset(y: xpFloatOffset)
                    .opacity(xpFloatOpacity)
            }
        }
        .scaleEffect(cardScale)
        .opacity(overallOpacity)
        .onAppear {
            if reduceMotion {
                runReducedMotion()
            } else {
                runFullAnimation()
            }
        }
    }

    private func runFullAnimation() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            fillExpand = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCheckmark = true
            withAnimation(.easeOut(duration: 0.35)) {
                checkmarkTrim = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                cardScale = 0.92
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                cardScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            xpFloatOffset = 0
            xpFloatOpacity = 1.0
            withAnimation(.easeOut(duration: 0.8)) {
                xpFloatOffset = -60
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                xpFloatOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeIn(duration: 0.25)) {
                overallOpacity = 0
                cardScale = 0.9
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            onFinished()
        }
    }

    private func runReducedMotion() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        fillExpand = true
        showCheckmark = true
        checkmarkTrim = 1.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            overallOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onFinished()
        }
    }
}
