import SwiftUI

// MARK: - Share cards (Phase E)
//
// 4 templates × 2 output sizes (story 1080×1920, square 1080×1080).
// Port of explorations/share-cards.jsx + the Splurj Share Cards spec.
// Each returns a SwiftUI view that ImageRenderer can rasterize for
// UIActivityViewController.

nonisolated enum ShareSize: String, Sendable { case story, square
    var dimensions: CGSize {
        switch self {
        case .story: .init(width: 1080, height: 1920)
        case .square: .init(width: 1080, height: 1080)
        }
    }
}

// MARK: - Streak card

struct ShareCardStreak: View {
    var variant: SplurjVariant = .her
    var days: Int = 23
    var username: String = "@you"
    var size: ShareSize = .story

    var body: some View {
        ShareCardFrame(size: size, background: .streak) {
            VStack(spacing: 24) {
                header(kicker: "SPLURJ · STREAK", username: username)

                VStack(spacing: 8) {
                    Kicker("SPLURGE-FREE STREAK", color: Theme.textSecondary, tracking: 3.2)
                    Text("\(days)")
                        .font(.system(size: size == .story ? 280 : 200, weight: .black, design: .rounded))
                        .tracking(-10)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: 0xC8F088)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Text("days")
                        .font(.system(size: size == .story ? 52 : 42, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }

                SplurjMascot(variant: variant, stage: stageForStreak(days), size: size == .story ? 300 : 220)

                VStack(spacing: 6) {
                    Text(caption)
                        .font(.system(size: size == .story ? 40 : 34, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textPrimary)
                    Text("splurj.app")
                        .font(.system(size: size == .story ? 22 : 18, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 64)
        }
    }

    private var caption: String {
        switch variant {
        case .her:     "Splurj and me \u{00B7} \(days) days"
        case .him:     "\(days) days with Splurj"
        case .neutral: "\(days)-day streak \u{00B7} Splurj"
        }
    }

    private func stageForStreak(_ d: Int) -> SlimeStage {
        switch d {
        case ..<7: .seedling
        case 7..<21: .sprout
        case 21..<60: .grass
        case 60..<150: .leafy
        case 150..<365: .flowering
        default: .bonsai
        }
    }
}

// MARK: - Level-up card

struct ShareCardLevelUp: View {
    var variant: SplurjVariant = .her
    var level: Int = 7
    var size: ShareSize = .story

    var body: some View {
        ShareCardFrame(size: size, background: .levelUp) {
            VStack(spacing: 24) {
                header(kicker: "SPLURJ · LEVEL UP", username: nil, accent: Theme.honey)

                VStack(spacing: 6) {
                    Kicker("REACHED", color: Theme.honey, tracking: 4.0)
                    Text("LV \(String(format: "%02d", level))")
                        .font(.system(size: size == .story ? 220 : 170, weight: .black, design: .rounded))
                        .tracking(-6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0xFFF4C4), Theme.honey],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }

                SplurjMascot(variant: variant, stage: stageForLevel(level), size: size == .story ? 340 : 260)

                VStack(spacing: 4) {
                    Text(caption)
                        .font(.system(size: size == .story ? 40 : 32, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(hex: 0xFFF4C4))
                    Text("splurj.app")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 64)
        }
    }

    private var caption: String {
        switch variant {
        case .her:     "Splurj unfurled her canopy."
        case .him:     "Splurj hit leafy-cap stage."
        case .neutral: "Splurj\u{2019}s fully-leaved now."
        }
    }

    private func stageForLevel(_ lvl: Int) -> SlimeStage {
        for stage in SlimeStage.allCases.reversed() where lvl >= stage.minLevel {
            return stage
        }
        return .seedling
    }
}

// MARK: - Pact victory card

struct ShareCardPact: View {
    var variant: SplurjVariant = .her
    var partnerName: String = "Sam"
    var potAmount: Int = 120
    var durationDays: Int = 30
    var size: ShareSize = .story

    var body: some View {
        ShareCardFrame(size: size, background: .pact) {
            VStack(spacing: 28) {
                header(kicker: "PACT \u{00B7} VICTORY", username: nil)

                HStack(alignment: .center, spacing: 40) {
                    VStack(spacing: 8) {
                        SplurjMascot(variant: variant, stage: .leafy, size: size == .story ? 220 : 170)
                        Kicker("YOU", color: Theme.textSecondary, tracking: 3)
                    }
                    Text("×")
                        .font(.system(size: 72, weight: .black))
                        .foregroundStyle(Theme.honey)
                    VStack(spacing: 8) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Theme.sky, Color(hex: 0x5A84B0)],
                                    center: UnitPoint(x: 0.35, y: 0.3),
                                    startRadius: 0, endRadius: 100
                                )
                            )
                            .frame(width: size == .story ? 220 : 170, height: size == .story ? 220 : 170)
                            .overlay(
                                Text(String(partnerName.first ?? "?"))
                                    .font(.system(size: size == .story ? 80 : 60, weight: .black))
                                    .foregroundStyle(Theme.background)
                            )
                        Kicker(partnerName.uppercased(), color: Theme.textSecondary, tracking: 3)
                    }
                }

                VStack(spacing: 6) {
                    Kicker("\(durationDays)-DAY PACT \u{00B7} WON", color: Theme.textSecondary, tracking: 3.6)
                    Text("$\(potAmount)")
                        .font(.system(size: size == .story ? 180 : 140, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: 0xC8F088)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Text("pot claimed \u{00B7} split the leaves")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.textSecondary)
                }

                Text(caption)
                    .font(.system(size: size == .story ? 32 : 26, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                Text("splurj.app")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 64)
        }
    }

    private var caption: String {
        switch variant {
        case .her:     "You and \(partnerName) held the line. Splurj\u{2019}s proud."
        case .him:     "You + \(partnerName): solid. Splurj approves."
        case .neutral: "You both kept the pact. Splurj\u{2019}s bigger."
        }
    }
}

// MARK: - Savings milestone card

struct ShareCardSavings: View {
    var variant: SplurjVariant = .her
    var amount: Int = 427
    var size: ShareSize = .story

    var body: some View {
        ShareCardFrame(size: size, background: .savings) {
            VStack(spacing: 28) {
                header(kicker: "SPLURJ \u{00B7} SAVED", username: nil, accent: Theme.honey)

                VStack(spacing: 6) {
                    Kicker("AVOIDED & STASHED", color: Theme.honey, tracking: 3.2)
                    Text("$\(amount)")
                        .font(.system(size: size == .story ? 240 : 180, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0xFFE899), Theme.honey],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }

                SplurjMascot(variant: variant, stage: .flowering, size: size == .story ? 300 : 230)

                VStack(spacing: 4) {
                    Text(caption)
                        .font(.system(size: size == .story ? 38 : 30, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textPrimary)
                    Text("splurj.app")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 64)
        }
    }

    private var caption: String {
        switch variant {
        case .her:     "Splurj helped me save $\(amount)."
        case .him:     "Splurj \u{00B7} $\(amount) saved."
        case .neutral: "Splurj \u{00B7} $\(amount) saved."
        }
    }
}

// MARK: - Card frame

@ViewBuilder
private func header(kicker: String, username: String?, accent: Color = Theme.honey) -> some View {
    HStack {
        Text(kicker)
            .font(.system(size: 22, weight: .heavy, design: .monospaced))
            .tracking(4)
            .foregroundStyle(accent)
        Spacer()
        if let username {
            Text(username)
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .tracking(2.4)
                .foregroundStyle(Theme.textMuted)
        }
    }
}

private enum ShareBackground { case streak, levelUp, pact, savings }

private struct ShareCardFrame<Content: View>: View {
    let size: ShareSize
    let background: ShareBackground
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .center) {
            bg
            content()
                .frame(width: size.dimensions.width, height: size.dimensions.height)
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
    }

    @ViewBuilder
    private var bg: some View {
        switch background {
        case .streak:
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x0F2820), Color(hex: 0x0A1612), Color(hex: 0x050C0A)],
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [Theme.glow.opacity(0.35), .clear],
                    center: UnitPoint(x: 0.5, y: 0.85),
                    startRadius: 0, endRadius: 900
                )
                fireflies()
            }

        case .levelUp:
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x1A1408), Color(hex: 0x0F1210), Color(hex: 0x0A0F0D)],
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [Theme.honey.opacity(0.3), .clear],
                    center: .init(x: 0.5, y: 0.42),
                    startRadius: 0, endRadius: 900
                )
                rays()
            }

        case .pact:
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x0F2820), Color(hex: 0x0A1612)],
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [Theme.petal.opacity(0.18), .clear],
                    center: .init(x: 0.3, y: 0.3),
                    startRadius: 0, endRadius: 700
                )
                RadialGradient(
                    colors: [Theme.sky.opacity(0.18), .clear],
                    center: .init(x: 0.7, y: 0.8),
                    startRadius: 0, endRadius: 700
                )
            }

        case .savings:
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x1E1A0C), Color(hex: 0x121008), Color(hex: 0x0A0906)],
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [Theme.honey.opacity(0.28), .clear],
                    center: .init(x: 0.5, y: 0.5),
                    startRadius: 0, endRadius: 800
                )
                Canvas { ctx, rectSize in
                    for _ in 0..<25 {
                        let x = CGFloat.random(in: 0...rectSize.width)
                        let y = CGFloat.random(in: 0...rectSize.height)
                        var p = Path()
                        p.addEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
                        ctx.fill(p, with: .color(Theme.honey.opacity(Double.random(in: 0.2...0.7))))
                    }
                }
            }
        }
    }

    private func fireflies() -> some View {
        Canvas { ctx, rectSize in
            for i in 0..<30 {
                let x = (CGFloat(i) * 127).truncatingRemainder(dividingBy: rectSize.width)
                let y = (CGFloat(i) * 211).truncatingRemainder(dividingBy: rectSize.height)
                var p = Path()
                p.addEllipse(in: CGRect(x: x, y: y, width: 4, height: 4))
                ctx.fill(p, with: .color(Theme.glow.opacity(Double.random(in: 0.3...0.9))))
            }
        }
    }

    private func rays() -> some View {
        Canvas { ctx, rectSize in
            let cx = rectSize.width / 2
            let cy = rectSize.height * 0.42
            for i in 0..<18 {
                let angle = Double(i) / 18.0 * .pi * 2
                var p = Path()
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(
                    x: cx + CGFloat(cos(angle)) * 1200,
                    y: cy + CGFloat(sin(angle)) * 1200
                ))
                ctx.stroke(p, with: .color(Theme.honey.opacity(0.3)), lineWidth: 2)
            }
        }
    }
}

// MARK: - Render to image (for share sheet)

@MainActor
struct SplurjShareRenderer {
    /// Renders any share-card view into a UIImage at its native pixel size.
    static func render<V: View>(_ view: V, size: ShareSize) -> UIImage? {
        let renderer = ImageRenderer(content:
            view.frame(width: size.dimensions.width, height: size.dimensions.height)
        )
        renderer.scale = 1.0   // The card dimensions are already final pixels.
        return renderer.uiImage
    }
}

#if DEBUG
#Preview("Share · streak") {
    ScrollView {
        ShareCardStreak(variant: .her, days: 23, username: "@maya")
            .scaleEffect(0.25)
            .frame(width: 270, height: 480)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Share · level up") {
    ScrollView {
        ShareCardLevelUp(variant: .him, level: 14)
            .scaleEffect(0.25)
            .frame(width: 270, height: 480)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Share · pact") {
    ScrollView {
        ShareCardPact(variant: .her, partnerName: "Sam", potAmount: 120, durationDays: 30)
            .scaleEffect(0.25)
            .frame(width: 270, height: 480)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Share · savings") {
    ScrollView {
        ShareCardSavings(variant: .neutral, amount: 427)
            .scaleEffect(0.25)
            .frame(width: 270, height: 480)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
#endif
