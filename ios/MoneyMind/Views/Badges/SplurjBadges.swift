import SwiftUI

// MARK: - Splurj achievement badges (12)
//
// Port of badges/badges.jsx. Each badge is a 64-point SVG silhouette
// (Hex / Circle / Shield / Sunburst) + medal fill + specular + copy.
// Locked state greyscales + dims + shows a tiny padlock corner chip.

nonisolated enum BadgeGroup: String, Sendable { case streak, savings, pact, onboard }

nonisolated enum BadgeID: String, CaseIterable, Identifiable, Sendable, Hashable {
    case streak7, streak30, streak90, streak365
    case save100, save500, save1k, save5k
    case pactFirst, pact5, pact10
    case onboard

    var id: String { rawValue }

    var name: String {
        switch self {
        case .streak7:    "7-Night Streak"
        case .streak30:   "30-Night Streak"
        case .streak90:   "90-Night Streak"
        case .streak365:  "One Full Year"
        case .save100:    "First Step"
        case .save500:    "Foundation"
        case .save1k:     "Threshold"
        case .save5k:     "Altitude"
        case .pactFirst:  "First Pact"
        case .pact5:      "Kept Five"
        case .pact10:     "Kept Ten"
        case .onboard:    "Seed Planted"
        }
    }

    var trigger: String {
        switch self {
        case .streak7:    "7 consecutive days"
        case .streak30:   "30 consecutive days"
        case .streak90:   "90 consecutive days"
        case .streak365:  "365 consecutive days"
        case .save100:    "$100 saved"
        case .save500:    "$500 saved"
        case .save1k:     "$1,000 saved"
        case .save5k:     "$5,000 saved"
        case .pactFirst:  "first pact completed"
        case .pact5:      "5 pacts won"
        case .pact10:     "10 pacts won"
        case .onboard:    "onboarding complete"
        }
    }

    var group: BadgeGroup {
        switch self {
        case .streak7, .streak30, .streak90, .streak365: .streak
        case .save100, .save500, .save1k, .save5k: .savings
        case .pactFirst, .pact5, .pact10: .pact
        case .onboard: .onboard
        }
    }
}

// MARK: - Metal palettes

private enum MedalMetal {
    case bronze, silver, gold, emerald, sky, petal, coral

    var gradient: RadialGradient {
        RadialGradient(
            colors: stops,
            center: UnitPoint(x: 0.38, y: 0.32),
            startRadius: 0, endRadius: 30
        )
    }

    private var stops: [Color] {
        switch self {
        case .bronze:  [Color(hex: 0xFFD8A8), Color(hex: 0xC88A4A), Color(hex: 0x5A2E10)]
        case .silver:  [Color(hex: 0xF5F8FA), Color(hex: 0xB8C0C8), Color(hex: 0x4A5258)]
        case .gold:    [Color(hex: 0xFFF2B8), Color(hex: 0xF5C542), Color(hex: 0x7A4618)]
        case .emerald: [Color(hex: 0xC8F088), Color(hex: 0x6AAF4A), Color(hex: 0x1F4A1A)]
        case .sky:     [Color(hex: 0xD4E4F8), Color(hex: 0x8DB8E8), Color(hex: 0x2E4A7A)]
        case .petal:   [Color(hex: 0xFFE0ED), Color(hex: 0xFFBCD9), Color(hex: 0x6A1A3A)]
        case .coral:   [Color(hex: 0xFFC8B8), Color(hex: 0xFF8E7E), Color(hex: 0x6A1A0A)]
        }
    }
}

// MARK: - Silhouette shapes

private struct HexShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 32, y: 6))
            p.addLine(to: CGPoint(x: 54, y: 18))
            p.addLine(to: CGPoint(x: 54, y: 46))
            p.addLine(to: CGPoint(x: 32, y: 58))
            p.addLine(to: CGPoint(x: 10, y: 46))
            p.addLine(to: CGPoint(x: 10, y: 18))
            p.closeSubpath()
        }
    }
}

private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 32, y: 4))
            p.addLine(to: CGPoint(x: 54, y: 12))
            p.addLine(to: CGPoint(x: 54, y: 34))
            p.addCurve(to: CGPoint(x: 32, y: 60),
                       control1: CGPoint(x: 54, y: 46),
                       control2: CGPoint(x: 44, y: 56))
            p.addCurve(to: CGPoint(x: 10, y: 34),
                       control1: CGPoint(x: 20, y: 56),
                       control2: CGPoint(x: 10, y: 46))
            p.addLine(to: CGPoint(x: 10, y: 12))
            p.closeSubpath()
        }
    }
}

private struct SunburstShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords: [CGPoint] = [
            .init(x: 32, y: 4),  .init(x: 38, y: 18), .init(x: 52, y: 14),
            .init(x: 48, y: 28), .init(x: 60, y: 36), .init(x: 46, y: 40),
            .init(x: 50, y: 54), .init(x: 36, y: 50), .init(x: 32, y: 62),
            .init(x: 28, y: 50), .init(x: 14, y: 54), .init(x: 18, y: 40),
            .init(x: 4,  y: 36), .init(x: 16, y: 28), .init(x: 12, y: 14),
            .init(x: 26, y: 18)
        ]
        return Path { p in
            p.move(to: coords[0])
            for c in coords.dropFirst() { p.addLine(to: c) }
            p.closeSubpath()
        }
    }
}

// MARK: - Badge render

struct SplurjBadge: View {
    let id: BadgeID
    var size: CGFloat = 80
    var locked: Bool = false

    var body: some View {
        Canvas { ctx, _ in
            // Cast shadow
            let shadow = Path(ellipseIn: CGRect(x: 14, y: 57.5, width: 36, height: 5))
            ctx.fill(shadow, with: .color(.black.opacity(0.35)))
        }
        .frame(width: 64, height: 64)
        .overlay(
            badgeContent
                .saturation(locked ? 0.0 : 1.0)
                .brightness(locked ? -0.4 : 0)
                .opacity(locked ? 0.7 : 1.0)
        )
        .overlay(alignment: .bottomTrailing) {
            if locked {
                lockBadge
                    .offset(x: -5, y: -5)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(size / 64)
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("\(id.name), \(locked ? "locked" : "earned"). Unlocks after \(id.trigger).")
    }

    @ViewBuilder
    private var badgeContent: some View {
        switch id {
        case .streak7:    streakBadge(metal: .bronze, numeral: "7",   caption: "NIGHTS")
        case .streak30:   streakBadge(metal: .silver, numeral: "30",  caption: "NIGHTS")
        case .streak90:   streakBadge(metal: .gold,   numeral: "90",  caption: "NIGHTS")
        case .streak365:  streak365
        case .save100:    savingsBadge(metal: .bronze, text: "$100",    caption: "FIRST STEP")
        case .save500:    savingsBadge(metal: .silver, text: "$500",    caption: "FOUNDATION")
        case .save1k:     savingsBadge(metal: .gold,   text: "$1,000",  caption: "THRESHOLD")
        case .save5k:     save5k
        case .pactFirst:  pactFirst
        case .pact5:      pactBadge(metal: .sky,     numeral: "5",  caption: "PACTS WON", dark: Color(hex: 0x0E1E38))
        case .pact10:     pactBadge(metal: .emerald, numeral: "10", caption: "KEPT TEN",  dark: Color(hex: 0x0E2008))
        case .onboard:    onboardBadge
        }
    }

    // MARK: Streak variants

    private func streakBadge(metal: MedalMetal, numeral: String, caption: String) -> some View {
        ZStack {
            HexShape().fill(metal.gradient)
            HexShape().stroke(Color(hex: 0x1A0808), lineWidth: 2)
            specular
            VStack(spacing: 2) {
                Text(numeral)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2E1608))
                Text(caption)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .tracking(2.1)
                    .foregroundStyle(Color(hex: 0x2E1608))
            }
            .offset(y: 4)
        }
        .frame(width: 64, height: 64)
    }

    private var streak365: some View {
        ZStack {
            // Ray rosette
            Canvas { ctx, _ in
                for i in 0..<12 {
                    let a = Double(i) * 30 * .pi / 180
                    let x1 = 32.0
                    let y1 = 32.0
                    let x2 = x1 + cos(a) * 28
                    let y2 = y1 + sin(a) * 28
                    var p = Path()
                    p.move(to: CGPoint(x: x1, y: y1))
                    p.addLine(to: CGPoint(x: x2, y: y2))
                    ctx.stroke(p, with: .color(Color(hex: 0xFFE899).opacity(0.5)),
                               style: StrokeStyle(lineWidth: 1.5))
                }
            }
            .frame(width: 64, height: 64)

            HexShape().fill(MedalMetal.gold.gradient)
            HexShape().stroke(Color(hex: 0x1A0808), lineWidth: 2.5)
            specular
            VStack(spacing: 1) {
                Text("365")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3A1E08))
                Text("1 YEAR")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .tracking(1.8)
                    .foregroundStyle(Color(hex: 0x3A1E08))
            }
            .offset(y: 2)
        }
        .frame(width: 64, height: 64)
    }

    // MARK: Savings

    private func savingsBadge(metal: MedalMetal, text: String, caption: String) -> some View {
        ZStack {
            Circle().fill(metal.gradient)
                .frame(width: 52, height: 52)
            Circle().strokeBorder(Color(hex: 0x1A0808), lineWidth: 2)
                .frame(width: 52, height: 52)
            specular
            VStack(spacing: 2) {
                Text(text)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2E1608))
                Text(caption)
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(Color(hex: 0x2E1608))
            }
            .offset(y: 4)
        }
        .frame(width: 64, height: 64)
    }

    private var save5k: some View {
        ZStack {
            Canvas { ctx, _ in
                for i in 0..<10 {
                    let a = Double(i) * 36 * .pi / 180
                    var p = Path()
                    p.move(to: CGPoint(x: 32, y: 32))
                    p.addLine(to: CGPoint(x: 32 + cos(a) * 30, y: 32 + sin(a) * 30))
                    ctx.stroke(p, with: .color(Color(hex: 0xFFE899).opacity(0.4)),
                               style: StrokeStyle(lineWidth: 1.5))
                }
            }
            .frame(width: 64, height: 64)
            Circle().fill(MedalMetal.gold.gradient).frame(width: 52, height: 52)
            Circle().strokeBorder(Color(hex: 0x1A0808), lineWidth: 2.5).frame(width: 52, height: 52)
            specular
            VStack(spacing: 2) {
                Text("$5,000")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3A1E08))
                Text("ALTITUDE")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(Color(hex: 0x3A1E08))
            }
            .offset(y: 4)
        }
        .frame(width: 64, height: 64)
    }

    // MARK: Pacts

    private var pactFirst: some View {
        ZStack {
            ShieldShape().fill(MedalMetal.petal.gradient)
            ShieldShape().stroke(Color(hex: 0x1A0808), lineWidth: 2)
            specular
            HStack(spacing: 1) {
                Circle().strokeBorder(Color(hex: 0x3A0E22), lineWidth: 2)
                    .frame(width: 14, height: 14)
                Circle().strokeBorder(Color(hex: 0x3A0E22), lineWidth: 2)
                    .frame(width: 14, height: 14)
            }
            .offset(y: -2)
            Text("FIRST PACT")
                .font(.system(size: 6, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Color(hex: 0x3A0E22))
                .offset(y: 18)
        }
        .frame(width: 64, height: 64)
    }

    private func pactBadge(metal: MedalMetal, numeral: String, caption: String, dark: Color) -> some View {
        ZStack {
            ShieldShape().fill(metal.gradient)
            ShieldShape().stroke(Color(hex: 0x1A0808), lineWidth: 2)
            specular
            VStack(spacing: 2) {
                Text(numeral)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(dark)
                Text(caption)
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(dark)
            }
        }
        .frame(width: 64, height: 64)
    }

    // MARK: Onboarding

    private var onboardBadge: some View {
        ZStack {
            SunburstShape().fill(MedalMetal.emerald.gradient)
            SunburstShape().stroke(Color(hex: 0x1A0808), lineWidth: 2)
            specular

            // Sprout stem + 2 leaves
            Path { p in
                p.move(to: CGPoint(x: 32, y: 44))
                p.addQuadCurve(to: CGPoint(x: 32, y: 30), control: CGPoint(x: 32, y: 36))
            }
            .stroke(Color(hex: 0x0E2008), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { p in
                p.move(to: CGPoint(x: 32, y: 34))
                p.addQuadCurve(to: CGPoint(x: 24, y: 18), control: CGPoint(x: 20, y: 28))
                p.addQuadCurve(to: CGPoint(x: 34, y: 32), control: CGPoint(x: 34, y: 24))
                p.closeSubpath()
            }
            .fill(Color(hex: 0xC8F088))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 32, y: 34))
                    p.addQuadCurve(to: CGPoint(x: 24, y: 18), control: CGPoint(x: 20, y: 28))
                    p.addQuadCurve(to: CGPoint(x: 34, y: 32), control: CGPoint(x: 34, y: 24))
                }.stroke(Color(hex: 0x0E2008), lineWidth: 1.4)
            )

            Path { p in
                p.move(to: CGPoint(x: 32, y: 28))
                p.addQuadCurve(to: CGPoint(x: 42, y: 12), control: CGPoint(x: 44, y: 22))
                p.addQuadCurve(to: CGPoint(x: 30, y: 26), control: CGPoint(x: 32, y: 18))
                p.closeSubpath()
            }
            .fill(Color(hex: 0xC8F088))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 32, y: 28))
                    p.addQuadCurve(to: CGPoint(x: 42, y: 12), control: CGPoint(x: 44, y: 22))
                    p.addQuadCurve(to: CGPoint(x: 30, y: 26), control: CGPoint(x: 32, y: 18))
                }.stroke(Color(hex: 0x0E2008), lineWidth: 1.4)
            )
        }
        .frame(width: 64, height: 64)
    }

    // MARK: Shared

    private var specular: some View {
        Ellipse()
            .fill(Color.white.opacity(0.45))
            .frame(width: 20, height: 8)
            .offset(x: -10, y: -12)
    }

    private var lockBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0x0B1614))
                .frame(width: 14, height: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color(hex: 0x4A5A4E), lineWidth: 1)
                )
            // Shackle
            Path { p in
                p.move(to: CGPoint(x: 3, y: 4))
                p.addLine(to: CGPoint(x: 3, y: 2))
                p.addArc(center: CGPoint(x: 7, y: 2), radius: 4,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.addLine(to: CGPoint(x: 11, y: 4))
            }
            .stroke(Color(hex: 0x4A5A4E), lineWidth: 1.3)
            .frame(width: 14, height: 14)
            .offset(y: -6)
        }
    }
}

#if DEBUG
#Preview("Badges") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)], spacing: 16) {
            ForEach(BadgeID.allCases) { b in
                VStack(spacing: 6) {
                    SplurjBadge(id: b, size: 80)
                    Text(b.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(b.trigger)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Badges locked vs earned") {
    HStack(spacing: 22) {
        VStack(spacing: 10) {
            ForEach([BadgeID.streak7, .save500, .pactFirst, .onboard]) { b in
                SplurjBadge(id: b, size: 72, locked: true)
            }
            Text("LOCKED")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textMuted)
        }
        VStack(spacing: 10) {
            ForEach([BadgeID.streak7, .save500, .pactFirst, .onboard]) { b in
                SplurjBadge(id: b, size: 72, locked: false)
            }
            Text("EARNED")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.glow)
        }
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
#endif
