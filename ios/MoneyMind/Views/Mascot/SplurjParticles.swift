import SwiftUI

// MARK: - Particle systems (Polish Pack)
//
// Port of the Splurj Polish Pack particle specs. Three reusable emitters
// that layer over any view (mascot / celebration / badge unlock). Each
// runs on a TimelineView so we don't burn CPU when they're not visible,
// and each respects accessibilityReduceMotion by falling back to a
// static single frame.
//
// CoinBurst    — level-up / savings-milestone fireworks
// LeafDrift    — passive ambient snow (falling leaves) for the Home hub
// SparkleHalo  — short orbiting halo around a newly-earned badge

// MARK: Coin burst

struct CoinBurstOverlay: View {
    @Binding var fire: Bool
    var count: Int = 14
    var color: Color = Theme.honey

    @State private var particles: [Particle] = []
    @State private var startedAt: Date = .distantPast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Particle: Identifiable {
        let id = UUID()
        var angle: Double
        var distance: CGFloat
        var spin: Double
        var size: CGFloat
        var delay: Double
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
            let now = timeline.date
            let elapsed = now.timeIntervalSince(startedAt)
            ZStack {
                ForEach(particles) { p in
                    let t = max(0, min(1, (elapsed - p.delay) / 0.9))
                    let eased = 1 - pow(1 - t, 3)
                    CoinGlyph(spin: p.spin * Double(t))
                        .frame(width: p.size, height: p.size)
                        .offset(
                            x: CGFloat(cos(p.angle)) * p.distance * CGFloat(eased),
                            y: CGFloat(sin(p.angle)) * p.distance * CGFloat(eased) + CGFloat(t * t * 60)
                        )
                        .opacity(Double(1 - t))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: fire) { _, shouldFire in
            if shouldFire { start() }
        }
    }

    private func start() {
        guard !reduceMotion else {
            fire = false
            return
        }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        startedAt = Date()
        particles = (0..<count).map { i in
            let baseAngle = Double(i) / Double(count) * .pi * 2
            return Particle(
                angle: baseAngle + Double.random(in: -0.2...0.2),
                distance: CGFloat.random(in: 70...130),
                spin: Double.random(in: 360...720),
                size: CGFloat.random(in: 10...16),
                delay: Double.random(in: 0...0.15)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            fire = false
            particles = []
        }
    }
}

private struct CoinGlyph: View {
    let spin: Double
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xFFF2B8), Color(hex: 0xF5C542), Color(hex: 0x7A4618)],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 0, endRadius: 8
                    )
                )
            Circle()
                .strokeBorder(Color(hex: 0x7A4618).opacity(0.6), lineWidth: 0.6)
            Text("S")
                .font(.system(size: 7, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x7A4618))
        }
        .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
    }
}

// MARK: Leaf drift (ambient)

struct LeafDriftField: View {
    var density: Int = 12
    var area: CGSize = CGSize(width: 400, height: 600)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<density, id: \.self) { i in
                    leaf(index: i, t: reduceMotion ? 0 : t)
                }
            }
            .frame(width: area.width, height: area.height)
        }
        .allowsHitTesting(false)
    }

    private func leaf(index i: Int, t: Double) -> some View {
        // Deterministic per-leaf parameters — stable between frames
        let seed = Double(i) * 73.0
        let speed = 18.0 + (seed.truncatingRemainder(dividingBy: 18))
        let drift = 40.0 + (seed.truncatingRemainder(dividingBy: 30))
        let size = 12 + (seed.truncatingRemainder(dividingBy: 6))
        let baseX = seed.truncatingRemainder(dividingBy: Double(area.width))
        let y = (t * speed + seed * 11).truncatingRemainder(dividingBy: Double(area.height + 80)) - 40
        let x = baseX + sin(t * 0.6 + seed) * drift
        let rotate = (t * 30 + seed * 17).truncatingRemainder(dividingBy: 360)

        return LeafShape()
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0xC8F088), Color(hex: 0x7EC552), Color(hex: 0x2F6B1F)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: size, height: size * 1.4)
            .rotationEffect(.degrees(rotate))
            .position(x: x, y: y)
            .opacity(0.45)
    }

    private struct LeafShape: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.midX, y: rect.minY))
                p.addQuadCurve(
                    to: CGPoint(x: rect.midX, y: rect.maxY),
                    control: CGPoint(x: rect.minX, y: rect.midY)
                )
                p.addQuadCurve(
                    to: CGPoint(x: rect.midX, y: rect.minY),
                    control: CGPoint(x: rect.maxX, y: rect.midY)
                )
                p.closeSubpath()
            }
        }
    }
}

// MARK: Sparkle halo

struct SparkleHaloOverlay: View {
    var radius: CGFloat = 60
    var sparkleCount: Int = 7
    var color: Color = Theme.glow
    var duration: Double = 1.4
    @State private var active: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<sparkleCount, id: \.self) { i in
                let angle = Double(i) / Double(sparkleCount) * .pi * 2
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                    .offset(
                        x: CGFloat(cos(angle)) * radius * (active ? 1 : 0.4),
                        y: CGFloat(sin(angle)) * radius * (active ? 1 : 0.4)
                    )
                    .opacity(active ? 0 : 1)
                    .scaleEffect(active ? 1.2 : 0.4)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: duration)) {
                active = true
            }
        }
        .allowsHitTesting(false)
    }
}

#if DEBUG
#Preview("Coin burst") {
    struct Demo: View {
        @State var fire = false
        var body: some View {
            ZStack {
                Theme.background.ignoresSafeArea()
                Button("Fire coin burst") {
                    fire = true
                }
                .buttonStyle(.borderedProminent)
                .overlay(CoinBurstOverlay(fire: $fire))
            }
        }
    }
    return Demo().preferredColorScheme(.dark)
}

#Preview("Leaf drift") {
    ZStack {
        Theme.background.ignoresSafeArea()
        LeafDriftField(density: 16, area: CGSize(width: 390, height: 700))
    }
    .preferredColorScheme(.dark)
}

#Preview("Sparkle halo") {
    ZStack {
        Theme.background.ignoresSafeArea()
        Circle()
            .fill(Theme.glow.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay(SparkleHaloOverlay())
    }
    .preferredColorScheme(.dark)
}
#endif
