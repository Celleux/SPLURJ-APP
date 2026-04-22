import SwiftUI

// MARK: - Kicker
//
// Uppercase monospaced eyebrow label used across the prototype — the
// orange/honey-colored "SPLURJ · COPY SEAM · v1" line above section heros.
// Matches v2-shell.jsx `Kicker` with 9.5pt size and 0.18em letter-spacing.

struct Kicker: View {
    let text: String
    var color: Color = Theme.honey
    var tracking: CGFloat = 1.7

    init(_ text: String, color: Color = Theme.honey, tracking: CGFloat = 1.7) {
        self.text = text
        self.color = color
        self.tracking = tracking
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

// MARK: - Tag
//
// The pill-shaped label used on onboarding ("01 · CHOOSE YOUR SPLURJ",
// "YOUR SPLURJ IS BORN"). 5/11 padding, 18% alpha bg, 66% alpha border.
// Mono font, tracking 0.18em.

struct Tag: View {
    let text: String
    var color: Color = Theme.glow

    init(_ text: String, color: Color = Theme.glow) {
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: .capsule)
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Pill
//
// Smaller inline chip used inside cards for "ON TRACK", "AT RISK", "NOW", etc.
// Matches v2-shell.jsx `Pill` — 4/9 padding, 12% alpha bg, 55% alpha border.

struct Pill: View {
    let text: String
    var color: Color = Theme.glow

    init(_ text: String, color: Color = Theme.glow) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: .capsule)
            .overlay(Capsule().strokeBorder(color.opacity(0.33), lineWidth: 1))
    }
}

// MARK: - Onboarding dot progress
//
// The 5-dot progress indicator at the top of every onboarding screen. Active
// dot expands to 22pt and gains a glow; completed dots stay green-filled.

struct OnboardingProgress: View {
    let step: Int
    var total: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.glow : Theme.textPrimary.opacity(0.18))
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .shadow(color: i == step ? Theme.glow.opacity(0.8) : .clear, radius: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: step)
            }
        }
    }
}

// MARK: - Primary CTA button
//
// The gold 3-stop gradient button used on every onboarding and hero screen.
// Keeps the exact spec from explorations/onboarding.jsx `PrimaryButton`:
//   - linear-gradient(180deg, #FFE899, #E8B94E 48%, #B8871E)
//   - 18pt radius, 16/24 padding
//   - white-45% inset highlight, black-15% inset bottom edge
//   - shadow: 0 8 24 accent@28%
//   - disabled: accent@25%, dim text
//
// Different from existing SplurjButtonStyle.primary (which is retained for
// call-sites in the pre-Slime surfaces). Use this for any new Slime-era CTA.

struct PrimaryCtaButton: View {
    let title: String
    var icon: String? = nil
    var trailingSymbol: String? = nil
    var disabled: Bool = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(-0.15)
                if let trailingSymbol {
                    Text(trailingSymbol)
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundStyle(disabled ? Theme.buttonTextOnAccent.opacity(0.5) : Theme.buttonTextOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background {
                if disabled {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.honey.opacity(0.25))
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.primaryCtaGradient)
                }
            }
            .overlay(
                // White inset highlight at the top edge (prototype: inset 0 1px rgba(255,255,255,0.45))
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(disabled ? 0.18 : 0.45), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                // Dark inset at the bottom edge for the pressed-gold-medallion feel
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.clear, .black.opacity(disabled ? 0 : 0.15)],
                            startPoint: .center,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .allowsHitTesting(false)
            )
            .shadow(color: disabled ? .clear : Theme.honey.opacity(0.28), radius: 14, y: 6)
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: pressed)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !disabled { pressed = true } }
                .onEnded { _ in pressed = false }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: pressed)
    }
}

// MARK: - Ghost link button
//
// Low-visual-weight secondary action — "I already have an account",
// "I'll do this later". Muted text, transparent background, tap target
// kept generous.

struct GhostLinkButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Firefly field
//
// Deterministic scatter of dim green fireflies used in TerrariumBG and
// AppBG. Positions are stable per render so they don't jitter on re-layout.

struct FireflyField: View {
    /// Tuples of (x, y, opacity) in the parent's coordinate space. Provide
    /// any stable set — the prototype uses 4 for AppBG and 7 for TerrariumBG.
    let points: [(x: CGFloat, y: CGFloat, opacity: Double)]
    var color: Color = Theme.glow
    var dotSize: CGFloat = 3
    var glowRadius: CGFloat = 10

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(points.indices, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: color, radius: glowRadius)
                    .opacity(points[i].opacity)
                    .position(x: points[i].x, y: points[i].y)
            }
        }
        .allowsHitTesting(false)
    }

    /// The 4-firefly set from v2-shell.jsx `AppBG`.
    static let appBGDefaults: [(CGFloat, CGFloat, Double)] = [
        (30, 320, 0.4), (340, 200, 0.3), (350, 560, 0.3), (20, 680, 0.35)
    ]

    /// The 7-firefly set from explorations/onboarding.jsx `TerrariumBG`.
    static let onboardingDefaults: [(CGFloat, CGFloat, Double)] = [
        (30, 140, 1.0), (320, 160, 0.6), (60, 280, 0.8),
        (300, 380, 0.7), (50, 500, 0.9), (290, 560, 0.6), (160, 620, 0.5)
    ]
}

// MARK: - Terrarium background
//
// Shared backdrop for every onboarding screen and the Splurj mascot
// terrarium on Home. Radial green glow pooling at 50% 90%, a secondary
// glow top-left, fireflies, a moon, and an optional wooden stump footer
// for "Splash" and "Reveal" screens.
//
// `intensity: 1.0` = onboarding full glow. `intensity: 0.5` = app chrome
// (v2 `AppBG`).

struct TerrariumBG<Content: View>: View {
    var intensity: Double = 1.0
    var withMoon: Bool = true
    var withStump: Bool = false
    var fireflies: [(CGFloat, CGFloat, Double)]
    @ViewBuilder var content: () -> Content

    init(
        intensity: Double = 1.0,
        withMoon: Bool = true,
        withStump: Bool = false,
        fireflies: [(CGFloat, CGFloat, Double)] = FireflyField.onboardingDefaults,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.intensity = intensity
        self.withMoon = withMoon
        self.withStump = withStump
        self.fireflies = fireflies
        self.content = content
    }

    var body: some View {
        ZStack {
            // Base gradient — paints first so glows can overlay it.
            LinearGradient(
                colors: [
                    Color(hex: 0x0F2820),
                    Color(hex: 0x0A1612),
                    Color(hex: 0x050C0A)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Bottom green glow pool
            RadialGradient(
                colors: [Theme.glow.opacity(0.30 * intensity), .clear],
                center: UnitPoint(x: 0.5, y: 0.9),
                startRadius: 0,
                endRadius: 480
            )
            .ignoresSafeArea()

            // Top-left secondary glow
            RadialGradient(
                colors: [Theme.glow.opacity(0.08 * intensity), .clear],
                center: UnitPoint(x: 0.2, y: 0.2),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            FireflyField(
                points: fireflies.map { (x: $0.0, y: $0.1, opacity: $0.2 * intensity) }
            )

            if withMoon {
                moon
            }

            if withStump {
                stump
            }

            content()
        }
        .background(Theme.background)
    }

    private var moon: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white, Color(hex: 0xD8E5DC)],
                    center: UnitPoint(x: 0.35, y: 0.35),
                    startRadius: 0,
                    endRadius: 20
                )
            )
            .frame(width: 36, height: 36)
            .shadow(color: .white.opacity(0.28), radius: 12)
            .position(x: 355, y: 56)
    }

    private var stump: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x8F5A30), Color(hex: 0x4A2A14)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 10)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x6B4024), Color(hex: 0x3A2510)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 30)
                .shadow(color: .black.opacity(0.5), radius: 10, y: 10)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 70)
    }
}
