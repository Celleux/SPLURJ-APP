import SwiftUI

struct ParticleBurstView: View {
    let particleCount: Int
    let colors: [Color]
    let duration: Double
    let style: BurstStyle
    let trigger: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [BurstParticle] = []
    @State private var startTime: Date = .now

    enum BurstStyle {
        case confetti
        case coins
        case stars
        case shatter
    }

    var body: some View {
        if reduceMotion { Color.clear.frame(width: 0, height: 0) } else {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                guard elapsed < duration + 1.0 else { return }

                for particle in particles {
                    let t = elapsed - particle.delay
                    guard t > 0 else { continue }

                    let gravity: CGFloat = style == .confetti ? 120 : 200
                    let x = particle.startX + particle.velocityX * t
                    let y = particle.startY + particle.velocityY * t + 0.5 * gravity * t * t
                    let opacity = max(0, 1.0 - t / duration)
                    let rotation = particle.rotationSpeed * t

                    guard opacity > 0 else { continue }

                    context.opacity = opacity
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: x, y: y)
                    transform = transform.rotated(by: rotation)

                    let rect: CGRect
                    switch style {
                    case .confetti:
                        rect = CGRect(x: -particle.size / 2, y: -particle.size, width: particle.size, height: particle.size * 2)
                    case .coins:
                        rect = CGRect(x: -particle.size / 2, y: -particle.size / 2, width: particle.size, height: particle.size)
                    case .stars:
                        rect = CGRect(x: -particle.size / 2, y: -particle.size / 2, width: particle.size, height: particle.size)
                    case .shatter:
                        rect = CGRect(x: -particle.size / 2, y: -particle.size / 2, width: particle.size, height: particle.size * 0.6)
                    }

                    context.translateBy(x: x, y: y)
                    context.rotate(by: .radians(rotation))
                    context.fill(
                        RoundedRectangle(cornerRadius: style == .coins ? particle.size / 2 : 2).path(in: rect),
                        with: .color(particle.color)
                    )
                    context.rotate(by: .radians(-rotation))
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            if newValue {
                spawnParticles()
            }
        }
        .onAppear {
            if trigger { spawnParticles() }
        }
        } // end else
    }

    private func spawnParticles() {
        startTime = .now
        let count = min(particleCount, 60)
        particles = (0..<count).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed: CGFloat
            switch style {
            case .confetti:
                speed = CGFloat.random(in: 80...250)
            case .coins:
                speed = CGFloat.random(in: 100...300)
            case .stars:
                speed = CGFloat.random(in: 150...350)
            case .shatter:
                speed = CGFloat.random(in: 200...500)
            }

            return BurstParticle(
                startX: UIScreen.main.bounds.width / 2,
                startY: UIScreen.main.bounds.height * 0.4,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 150,
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement() ?? .white,
                rotationSpeed: Double.random(in: -8...8),
                delay: Double.random(in: 0...0.15)
            )
        }
    }
}

private struct BurstParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let size: CGFloat
    let color: Color
    let rotationSpeed: Double
    let delay: Double
}

struct XPCounterView: View {
    let targetValue: Int
    let prefix: String
    let suffix: String
    let duration: Double
    let color: Color
    let fontSize: CGFloat

    @State private var displayValue: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var started: Bool = false

    var body: some View {
        Text("\(prefix)\(displayValue) \(suffix)")
            .font(.system(size: fontSize + CGFloat(displayValue) / CGFloat(max(targetValue, 1)) * 8, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .scaleEffect(scale)
            .onAppear {
                guard !started else { return }
                started = true
                animateCount()
            }
    }

    private func animateCount() {
        let steps = 30
        let interval = duration / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.linear(duration: interval)) {
                    displayValue = Int(Double(targetValue) * Double(i) / Double(steps))
                }
                if i == steps {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        scale = 1.15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }
                }
            }
        }
    }
}

struct ShimmerView: View {
    let color: Color
    let speed: Double
    let angle: Angle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = -1

    var body: some View {
        if reduceMotion { Color.clear } else {
        GeometryReader { geo in
            let width = geo.size.width * 0.4
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, color.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width)
                .offset(x: offset * (geo.size.width + width))
                .rotationEffect(angle)
        }
        .clipped()
        .drawingGroup()
        .onAppear {
            withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                offset = 1.5
            }
        }
        } // end else
    }
}

struct GlowBorderView: View {
    let color: Color
    let cornerRadius: CGFloat
    let glowRadius: CGFloat
    let animated: Bool
    let speed: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    var body: some View {
        Group {
            if animated && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 10.0)) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let angle = (elapsed / speed).truncatingRemainder(dividingBy: 1.0) * 360

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            AngularGradient(
                                colors: [color, color.opacity(0.2), color.opacity(0.5), color],
                                center: .center,
                                startAngle: .degrees(angle),
                                endAngle: .degrees(angle + 360)
                            ),
                            lineWidth: 2
                        )
                        .shadow(color: color.opacity(0.4), radius: glowRadius)
                }
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: 2)
                    .shadow(color: color.opacity(0.4), radius: glowRadius)
            }
        }
    }
}

struct ScreenFlashView: View {
    let color: Color
    let duration: Double
    let trigger: Bool

    @State private var opacity: Double = 0

    var body: some View {
        color
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    opacity = 1.0
                    withAnimation(.easeOut(duration: duration)) {
                        opacity = 0
                    }
                }
            }
    }
}

struct FloatingTextView: View {
    let text: String
    let color: Color
    let fontSize: CGFloat

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.5), radius: 8)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offset = -60
                }
                withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                    opacity = 0
                }
            }
    }
}

struct ConfettiCanvasView: View {
    let active: Bool
    let colors: [Color]
    let particleCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [SplurjConfettiPiece] = []
    @State private var timer: Timer?

    var body: some View {
        if reduceMotion { Color.clear.allowsHitTesting(false) } else {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x - particle.size / 2,
                    y: particle.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size * 1.5
                )
                context.opacity = particle.opacity
                context.fill(
                    RoundedRectangle(cornerRadius: 2).path(in: rect),
                    with: .color(particle.color)
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: active) { _, newValue in
            if newValue { startConfetti() }
        }
        .onAppear {
            if active { startConfetti() }
        }
        } // end else
    }

    private func startConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        particles = (0..<min(particleCount, 60)).map { _ in
            SplurjConfettiPiece(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -50...(-10)),
                velocityX: CGFloat.random(in: -1.5...1.5),
                velocityY: CGFloat.random(in: 1.0...3.5),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.4...0.8)
            )
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
            for i in particles.indices {
                particles[i].x += particles[i].velocityX
                particles[i].y += particles[i].velocityY
                particles[i].velocityY += 0.04
                particles[i].x += sin(particles[i].y * 0.02) * 0.3
                if particles[i].y > screenHeight + 50 {
                    particles[i].y = CGFloat.random(in: -50...(-10))
                    particles[i].x = CGFloat.random(in: 0...screenWidth)
                    particles[i].velocityY = CGFloat.random(in: 1.0...3.5)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            timer?.invalidate()
            timer = nil
        }
    }
}

private struct SplurjConfettiPiece {
    var x: CGFloat
    var y: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
}
