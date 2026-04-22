import SwiftUI

// MARK: - Mood

nonisolated enum SlimeMood: Sendable {
    case happy        // default
    case sleeping     // Zzz particles, eyes closed, slower breath
    case alert        // wider eyes, faster breath
    case sad          // slower breath, droopy, 20% desaturate
    case celebrating  // bouncing + wider smile
    case thinking     // eye offset
    case encouraging  // happy variant
    case proud        // happy variant

    var breathPeriod: Double {
        switch self {
        case .alert: 2.0
        case .sad, .sleeping: 5.0
        default: 3.2
        }
    }

    var saturation: Double {
        self == .sad ? 0.8 : 1.0
    }
}

// MARK: - Breathing

private struct BreathingModifier: ViewModifier {
    let period: Double
    let amplitude: CGFloat    // scale delta, 0.03 = 3%
    let verticalShift: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let eased = sin(t * 2 * .pi / period) * 0.5 + 0.5   // 0..1
                let scale = 1.0 + amplitude * CGFloat(eased)
                let dy = -verticalShift * CGFloat(eased)
                content
                    .scaleEffect(scale, anchor: .bottom)
                    .offset(y: dy)
            }
        }
    }
}

extension View {
    /// Mascot breathing — 3.2s default per prototype. Anchor bottom so feet
    /// stay planted while the body expands up.
    func splurjBreathing(period: Double = 3.2, amplitude: CGFloat = 0.03, verticalShift: CGFloat = 2) -> some View {
        modifier(BreathingModifier(period: period, amplitude: amplitude, verticalShift: verticalShift))
    }
}

// MARK: - Blinking
//
// The prototype specifies 120ms close every 4-7s. Random per-instance
// phase so multiple mascots don't blink in unison. Stage-specific: early
// stages blink both eyes together, bonsai blinks independently — but we
// keep it simple here and blink together for all stages.

struct BlinkTimer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var nextBlinkAt: Double = 0
    @State private var blinkStart: Double = -10
    let onChange: (Double) -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Color.clear
                .onChange(of: timeline.date) { _, newDate in
                    tick(now: newDate.timeIntervalSinceReferenceDate)
                }
        }
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    private func tick(now: Double) {
        if nextBlinkAt == 0 {
            nextBlinkAt = now + Double.random(in: 3.5...6.5)
        }
        if now >= nextBlinkAt && blinkStart < now - 0.2 {
            blinkStart = now
            nextBlinkAt = now + Double.random(in: 4...7)
        }
        let elapsed = now - blinkStart
        let closed: Double
        if elapsed < 0.06 {
            closed = elapsed / 0.06
        } else if elapsed < 0.12 {
            closed = 1.0 - (elapsed - 0.06) / 0.06
        } else {
            closed = 0
        }
        onChange(reduceMotion ? 0 : max(0, min(1, closed)))
    }
}

// MARK: - Idle sway

private struct IdleSwayModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // 5s period, phase-offset from breathing
                let angle = sin(t * 2 * .pi / 5.0 + .pi / 2) * 1.5
                content
                    .rotationEffect(.degrees(angle), anchor: .bottom)
            }
        }
    }
}

extension View {
    /// Gentle ±1.5° sway, 5s period, anchored at the diorama base.
    func splurjIdleSway() -> some View {
        modifier(IdleSwayModifier())
    }
}

// MARK: - Tap squash
//
// Squash + stretch the body for 320ms on tap. Plus a single sparkle burst
// rendered by SparkleBurstOverlay below.

struct TapSquashModifier: ViewModifier {
    @Binding var trigger: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: trigger ? 1.08 : 1.0, y: trigger ? 0.88 : 1.0, anchor: .bottom)
            .animation(.spring(response: 0.32, dampingFraction: 0.5), value: trigger)
    }
}

extension View {
    func splurjTapSquash(trigger: Binding<Bool>) -> some View {
        modifier(TapSquashModifier(trigger: trigger))
    }
}

// MARK: - Sparkle burst (tap feedback)

struct SparkleBurstOverlay: View {
    @Binding var fire: Bool
    var color: Color = Theme.honey
    var count: Int = 8
    @State private var active = false
    @State private var particles: [Particle] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Particle: Identifiable {
        let id = UUID()
        var angle: Double
        var distance: CGFloat
        var size: CGFloat
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(color)
                    .frame(width: p.size, height: p.size)
                    .offset(
                        x: CGFloat(cos(p.angle)) * p.distance * (active ? 1 : 0),
                        y: CGFloat(sin(p.angle)) * p.distance * (active ? 1 : 0)
                    )
                    .opacity(active ? 0 : 1)
                    .animation(.easeOut(duration: 0.6), value: active)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: fire) { _, shouldFire in
            guard shouldFire, !reduceMotion else {
                fire = false
                return
            }
            particles = (0..<count).map { i in
                Particle(
                    angle: Double(i) / Double(count) * .pi * 2,
                    distance: CGFloat.random(in: 30...50),
                    size: CGFloat.random(in: 3...5)
                )
            }
            active = false
            withAnimation {
                active = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                particles = []
                fire = false
            }
        }
    }
}

// MARK: - Evolution ceremony
//
// 900ms transition when stage advances: old stage scale→0, new stage
// scale 0→1, radial glow pulse, "+1 LEAF" label floats up and fades,
// haptic medium at peak. Used by SplurjMascot when `stage` changes.

struct EvolutionCeremony: View {
    let oldStage: SlimeStage
    let newStage: SlimeStage
    let variant: SplurjVariant
    let onComplete: () -> Void

    @State private var phase: Double = 0
    @State private var fireCoins: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Radial glow pulse behind new stage
            Circle()
                .fill(
                    RadialGradient(
                        colors: [variant.accent.opacity(0.6), variant.accent.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .scaleEffect(reduceMotion ? 1 : (phase > 0.2 ? 1.4 : 0.3))
                .opacity(reduceMotion ? 1 : (phase > 0.3 ? 0 : (phase > 0.15 ? 1 : 0)))

            // Old stage scales down
            variantStage(oldStage)
                .scaleEffect(reduceMotion ? 0 : max(0, 1 - phase * 2))
                .opacity(reduceMotion ? 0 : max(0, 1 - phase * 2))

            // New stage scales up
            variantStage(newStage)
                .scaleEffect(reduceMotion ? 1 : max(0, min(1, (phase - 0.35) * 2.5)))
                .opacity(reduceMotion ? 1 : max(0, min(1, (phase - 0.35) * 2.5)))

            // +1 LEAF label rises and fades
            if phase > 0.55 {
                Text("+1 LEAF")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(Theme.honey)
                    .offset(y: -70 - CGFloat((phase - 0.55) * 80))
                    .opacity(reduceMotion ? 1 : max(0, 1 - (phase - 0.55) * 2.5))
                    .shadow(color: Theme.honey.opacity(0.7), radius: 10)
            }

            // Coin burst fires as the new stage reveals
            CoinBurstOverlay(fire: $fireCoins, count: 16, color: Theme.honey)
        }
        .frame(width: 160, height: 160)
        .onAppear {
            if reduceMotion {
                onComplete()
            } else {
                withAnimation(.easeInOut(duration: 0.9)) {
                    phase = 1.0
                }
                // Haptic at peak + coin burst
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    fireCoins = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                    onComplete()
                }
            }
        }
    }

    @ViewBuilder
    private func variantStage(_ stage: SlimeStage) -> some View {
        switch variant {
        case .her:     SlimeHerStage(stage)
        case .him:     SlimeHimStage(stage)
        case .neutral: SlimeNeutralStage(stage)
        }
    }
}

// MARK: - Sleeping Zzz

struct SleepingZs: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date()

    var body: some View {
        if reduceMotion {
            Text("z")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.7))
                .offset(x: 60 - 80, y: -60 - 80 + 160)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                let dt = timeline.date.timeIntervalSince(startedAt).truncatingRemainder(dividingBy: 2.4)
                let t = dt / 2.4
                Text("z")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.8 - t * 0.8))
                    .offset(x: 60 - 80 + CGFloat(t * 8), y: -60 - 80 + 160 - CGFloat(t * 14))
            }
        }
    }
}
