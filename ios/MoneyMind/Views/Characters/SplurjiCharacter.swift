import SwiftUI

struct SplurjiCharacter: View {
    let mood: SplurjiMood
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var breathScale: CGFloat = 1.0
    @State private var bounceOffset: CGFloat = 0
    @State private var blinkScale: CGFloat = 1.0
    @State private var pupilOffset: CGSize = .zero
    @State private var tearOffset: CGFloat = 0
    @State private var tearOpacity: Double = 0
    @State private var zzzOffset: CGFloat = 0
    @State private var zzzOpacity: Double = 0
    @State private var celebrateBounceCount: Int = 0
    @State private var crownGlow: Double = 0.3
    @State private var questionMarkOffset: CGFloat = 0
    @State private var questionMarkOpacity: Double = 0
    @State private var animationTasks: [Task<Void, Never>] = []

    private var bodySize: CGFloat { size * 0.75 }
    private var eyeWidth: CGFloat { bodySize * 0.18 }
    private var eyeHeight: CGFloat { bodySize * 0.22 }
    private var pupilSize: CGFloat { bodySize * 0.09 }

    var body: some View {
        ZStack {
            sparkleOrbit

            VStack(spacing: 0) {
                crownAccessory
                    .offset(y: bodySize * 0.08)
                    .zIndex(1)

                ZStack {
                    characterBody
                    eyesView
                        .offset(y: -bodySize * 0.06)
                    mouthView
                        .offset(y: bodySize * 0.12)

                    if mood == .thinking {
                        handView
                    }
                }
            }
            .scaleEffect(x: breathScaleX, y: breathScaleY)
            .offset(y: bounceOffset)
            .rotationEffect(sleepTilt)

            moodOverlays
        }
        .frame(width: size, height: size)
        .saturation(mood == .sad || mood == .sleeping ? 0.8 : 1.0)
        .onAppear { startAnimations() }
        .onDisappear { cancelAllTasks() }
        .onChange(of: mood) { _, _ in
            cancelAllTasks()
            startAnimations()
        }
        .drawingGroup()
        .accessibilityLabel("Splurji mascot, current mood: \(mood.rawValue)")
    }

    private func cancelAllTasks() {
        for task in animationTasks { task.cancel() }
        animationTasks.removeAll()
    }

    private var characterBody: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.neonGold, Theme.accent, Theme.accentDim],
                        center: .center,
                        startRadius: 0,
                        endRadius: bodySize / 2
                    )
                )
                .frame(width: bodySize, height: bodySize)

            Circle()
                .fill(Theme.neonEmerald.opacity(0.25))
                .frame(width: bodySize * 0.7, height: bodySize * 0.7)
                .blur(radius: bodySize * 0.12)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.2), .clear],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: bodySize * 0.3
                    )
                )
                .frame(width: bodySize, height: bodySize)
        }
    }

    private var eyesView: some View {
        HStack(spacing: bodySize * 0.12) {
            singleEye
            singleEye
        }
        .scaleEffect(y: blinkScale)
        .scaleEffect(mood == .happy || mood == .celebrating ? 1.1 : 1.0)
    }

    private var singleEye: some View {
        ZStack {
            Ellipse()
                .fill(.white)
                .frame(width: eyeWidth, height: eyeHeight)

            Circle()
                .fill(.black)
                .frame(width: pupilSize, height: pupilSize)
                .offset(pupilOffset)

            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: pupilSize * 0.35, height: pupilSize * 0.35)
                .offset(x: pupilOffset.width + pupilSize * 0.15, y: pupilOffset.height - pupilSize * 0.15)
        }
        .clipShape(Ellipse().size(width: eyeWidth, height: eyeClipHeight).offset(y: eyeClipOffset))
    }

    private var eyeClipHeight: CGFloat {
        switch mood {
        case .sad: return eyeHeight * 0.5
        case .sleeping: return eyeHeight * 0.05
        default: return eyeHeight
        }
    }

    private var eyeClipOffset: CGFloat {
        switch mood {
        case .sad: return eyeHeight * 0.25
        case .sleeping: return eyeHeight * 0.47
        default: return 0
        }
    }

    private var mouthView: some View {
        Group {
            switch mood {
            case .happy, .encouraging, .proud:
                smileMouth
            case .celebrating:
                openMouth
            case .sad:
                sadMouth
            case .thinking:
                thinkingMouth
            case .sleeping:
                sleepingMouth
            default:
                smileMouth
            }
        }
    }

    private var smileMouth: some View {
        MouthArc(smile: true)
            .stroke(.white.opacity(0.9), lineWidth: max(2, bodySize * 0.025))
            .frame(width: bodySize * 0.25, height: bodySize * 0.1)
    }

    private var sadMouth: some View {
        MouthArc(smile: false)
            .stroke(.white.opacity(0.7), lineWidth: max(2, bodySize * 0.02))
            .frame(width: bodySize * 0.2, height: bodySize * 0.08)
    }

    private var openMouth: some View {
        Ellipse()
            .fill(.white.opacity(0.9))
            .frame(width: bodySize * 0.14, height: bodySize * 0.12)
    }

    private var thinkingMouth: some View {
        Circle()
            .fill(.white.opacity(0.7))
            .frame(width: bodySize * 0.06, height: bodySize * 0.06)
            .offset(x: bodySize * 0.05)
    }

    private var sleepingMouth: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.white.opacity(0.5))
            .frame(width: bodySize * 0.15, height: max(1.5, bodySize * 0.015))
    }

    private var crownAccessory: some View {
        ZStack {
            Image(systemName: "crown.fill")
                .font(.system(size: bodySize * 0.18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.neonGold, Color(hex: 0xFFA500)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Theme.neonGold.opacity(crownGlow), radius: 6)
        }
    }

    private var handView: some View {
        Circle()
            .fill(Theme.accent)
            .frame(width: bodySize * 0.1, height: bodySize * 0.1)
            .offset(x: bodySize * 0.2, y: bodySize * 0.08)
    }

    private var sparkleOrbit: some View {
        Group {
            if !reduceMotion && (mood != .sleeping && mood != .sad) {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, canvasSize in
                        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                        let orbitRadius = size * 0.42
                        let count = mood == .celebrating || mood == .happy ? 5 : 3
                        let speed = mood == .celebrating ? 1.5 : 0.8

                        for i in 0..<count {
                            let angle = (t * speed + Double(i) * (2.0 * .pi / Double(count)))
                            let x = center.x + orbitRadius * cos(angle)
                            let y = center.y + orbitRadius * sin(angle) * 0.6
                            let sparkleSize: CGFloat = mood == .celebrating ? 4 : 3
                            let opacity = 0.4 + 0.3 * sin(t * 2 + Double(i))

                            let rect = CGRect(x: x - sparkleSize / 2, y: y - sparkleSize / 2, width: sparkleSize, height: sparkleSize)
                            context.opacity = opacity
                            context.fill(Circle().path(in: rect), with: .color(Theme.neonGold))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var moodOverlays: some View {
        if mood == .sad {
            Circle()
                .fill(Theme.axisEmotional.opacity(tearOpacity))
                .frame(width: bodySize * 0.04, height: bodySize * 0.06)
                .offset(x: -bodySize * 0.12, y: -bodySize * 0.02 + tearOffset)
        }

        if mood == .sleeping {
            ForEach(0..<3, id: \.self) { i in
                Text("z")
                    .font(.system(size: bodySize * CGFloat(0.08 + Double(i) * 0.04), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textMuted.opacity(zzzOpacity))
                    .offset(
                        x: bodySize * CGFloat(0.2 + Double(i) * 0.08),
                        y: -bodySize * CGFloat(0.2 + Double(i) * 0.12) + zzzOffset
                    )
            }
        }

        if mood == .thinking {
            Text("?")
                .font(.system(size: bodySize * 0.15, weight: .black, design: .rounded))
                .foregroundStyle(Theme.neonGold)
                .offset(x: bodySize * 0.3, y: -bodySize * 0.35 + questionMarkOffset)
                .opacity(questionMarkOpacity)
        }

        if mood == .celebrating || mood == .proud {
            Circle()
                .fill(Theme.neonGold.opacity(0.15))
                .frame(width: bodySize * 1.4, height: bodySize * 1.4)
                .blur(radius: 20)
                .allowsHitTesting(false)
        }
    }

    private var breathScaleX: CGFloat {
        mood == .proud ? breathScale * 1.05 : breathScale
    }

    private var breathScaleY: CGFloat {
        let base: CGFloat = mood == .sad ? 0.95 : 1.0
        return base * (2.0 - breathScale)
    }

    private var sleepTilt: Angle {
        mood == .sleeping ? .degrees(5) : .zero
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        startBreathing()
        startBlinking()
        startPupilMovement()
        startCrownGlow()

        switch mood {
        case .celebrating:
            startCelebrating()
        case .sad:
            startTear()
        case .sleeping:
            startZzz()
        case .thinking:
            startQuestionMark()
        case .happy:
            startHappyBounce()
        default:
            bounceOffset = 0
        }
    }

    private func startBreathing() {
        let duration: Double = {
            switch mood {
            case .sleeping: return 3.5
            case .happy, .celebrating: return 1.5
            default: return 2.0
            }
        }()

        breathScale = 1.0
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            breathScale = 0.95
        }
    }

    private func startBlinking() {
        blinkScale = 1.0
        guard mood != .sleeping else { return }

        let task = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 3...5)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.08)) { blinkScale = 0.05 }
                try? await Task.sleep(for: .seconds(0.08))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.08)) { blinkScale = 1.0 }
            }
        }
        animationTasks.append(task)
    }

    private func startPupilMovement() {
        guard mood != .sleeping else {
            pupilOffset = .zero
            return
        }

        if mood == .thinking {
            withAnimation(.easeInOut(duration: 0.3)) {
                pupilOffset = CGSize(width: 0, height: -pupilSize * 0.4)
            }
            return
        }

        let task = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 2...4)))
                guard !Task.isCancelled else { break }
                let maxDrift = pupilSize * 0.3
                withAnimation(.easeInOut(duration: 0.8)) {
                    pupilOffset = CGSize(
                        width: CGFloat.random(in: -maxDrift...maxDrift),
                        height: CGFloat.random(in: -maxDrift * 0.5...maxDrift * 0.5)
                    )
                }
            }
        }
        animationTasks.append(task)
    }

    private func startCrownGlow() {
        crownGlow = 0.3
        let target: Double = mood == .proud || mood == .celebrating ? 0.8 : 0.3
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            crownGlow = target
        }
    }

    private func startCelebrating() {
        bounceOffset = 0
        celebrateBounceCount = 0

        let task = Task { @MainActor in
            for _ in 0..<3 {
                guard !Task.isCancelled else { break }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    bounceOffset = -15
                }
                try? await Task.sleep(for: .seconds(0.2))
                guard !Task.isCancelled else { break }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    bounceOffset = 0
                }
                try? await Task.sleep(for: .seconds(0.2))
            }
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                bounceOffset = 0
            }
        }
        animationTasks.append(task)
    }

    private func startHappyBounce() {
        bounceOffset = 0
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            bounceOffset = -3
        }
    }

    private func startTear() {
        tearOffset = 0
        tearOpacity = 0

        let task = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3...6)))
                guard !Task.isCancelled else { break }
                tearOffset = 0
                tearOpacity = 0.8
                withAnimation(.easeIn(duration: 1.2)) {
                    tearOffset = bodySize * 0.3
                    tearOpacity = 0
                }
                try? await Task.sleep(for: .seconds(1.2))
            }
        }
        animationTasks.append(task)
    }

    private func startZzz() {
        zzzOffset = 0
        zzzOpacity = 0

        let task = Task { @MainActor in
            while !Task.isCancelled {
                zzzOffset = 0
                withAnimation(.easeOut(duration: 0.3)) { zzzOpacity = 0.7 }
                withAnimation(.easeOut(duration: 2.0)) { zzzOffset = -bodySize * 0.2 }
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { break }
                withAnimation(.easeIn(duration: 0.5)) { zzzOpacity = 0 }
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
        animationTasks.append(task)
    }

    private func startQuestionMark() {
        questionMarkOffset = 0
        questionMarkOpacity = 0

        let task = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 2...4)))
                guard !Task.isCancelled else { break }
                questionMarkOffset = 0
                withAnimation(.easeOut(duration: 0.3)) { questionMarkOpacity = 1.0 }
                withAnimation(.easeOut(duration: 1.5)) { questionMarkOffset = -bodySize * 0.15 }
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { break }
                withAnimation(.easeIn(duration: 0.3)) { questionMarkOpacity = 0 }
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
        animationTasks.append(task)
    }
}

private struct MouthArc: Shape {
    let smile: Bool

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        if smile {
            path.move(to: CGPoint(x: 0, y: rect.midY * 0.3))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.midY * 0.3),
                control: CGPoint(x: rect.midX, y: rect.height * 1.2)
            )
        } else {
            path.move(to: CGPoint(x: 0, y: rect.height * 0.7))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.7),
                control: CGPoint(x: rect.midX, y: -rect.height * 0.2)
            )
        }
        return path
    }
}
