import SwiftUI

// MARK: - Splurj wordmark
//
// Port of brand/logo.jsx SplurjWordmark. "Splur" sets in Inter Tight 900
// (system rounded as proxy until TTFs ship), followed by a custom-drawn
// `j` whose descender curls into a leaf — the single distinctive move.

struct SplurjWordmark: View {
    var height: CGFloat = 48
    var color: Color = Theme.textPrimary
    var accent: Color = Theme.glow

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("Splur")
                .font(.system(size: height, weight: .black, design: .rounded))
                .tracking(-height * 0.045)
                .foregroundStyle(color)
                .lineLimit(1)
            customJ
                .frame(width: height * 0.52, height: height * 1.2)
                .offset(x: -height * 0.01, y: height * 0.18)
        }
        .accessibilityElement()
        .accessibilityLabel("Splurj")
    }

    private var customJ: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let sx = w / 52
            let sy = h / 120

            // j dot
            let dot = Path { p in
                p.addEllipse(in: CGRect(x: (26 - 8) * sx, y: (6 - 8) * sy,
                                         width: 16 * sx, height: 16 * sy))
            }
            ctx.fill(dot, with: .color(color))

            // j stem: M 26 20 L 26 88 C 26 100 20 108 10 108
            let stem = Path { p in
                p.move(to: CGPoint(x: 26 * sx, y: 20 * sy))
                p.addLine(to: CGPoint(x: 26 * sx, y: 88 * sy))
                p.addCurve(
                    to: CGPoint(x: 10 * sx, y: 108 * sy),
                    control1: CGPoint(x: 26 * sx, y: 100 * sy),
                    control2: CGPoint(x: 20 * sx, y: 108 * sy)
                )
            }
            ctx.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: 14 * sx, lineCap: .round))

            // Leaf on the j's curl
            let leaf = Path { p in
                p.move(to: CGPoint(x: 10 * sx, y: 108 * sy))
                p.addQuadCurve(to: CGPoint(x: 0 * sx, y: 82 * sy),
                               control: CGPoint(x: -6 * sx, y: 104 * sy))
                p.addQuadCurve(to: CGPoint(x: 18 * sx, y: 110 * sy),
                               control: CGPoint(x: 18 * sx, y: 92 * sy))
                p.closeSubpath()
            }
            ctx.fill(leaf, with: .linearGradient(
                Gradient(colors: [Color(hex: 0xC8F088), accent]),
                startPoint: CGPoint(x: w/2, y: 82 * sy),
                endPoint: CGPoint(x: w/2, y: 110 * sy)
            ))
            ctx.stroke(leaf, with: .color(Color(hex: 0x1A3D1A)),
                       style: StrokeStyle(lineWidth: 1.2 * sx))
        }
    }
}

// MARK: - App icon (Concept A — Coin + Leaf)
//
// The "safe pick" from brand/icons.jsx. Dark terrarium bg, green glow,
// gold coin with an "S" stroke in honey, two sprout leaves. Rendered as
// a SwiftUI view so it can be exported to any size for the iOS asset
// catalog via ImageRenderer.

struct SplurjAppIcon: View {
    var size: CGFloat = 1024
    var cornerRadius: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            bg
            coin
            leaves
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: size * 0.05, y: size * 0.02)
    }

    private var bg: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1A3028), Color(hex: 0x081512)],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [
                    Color(hex: 0x7EC552).opacity(0.35),
                    Color(hex: 0x7EC552).opacity(0.05),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.95),
                startRadius: 0,
                endRadius: size * 0.8
            )
            // Warm top highlight
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: size, y: 0))
                p.addLine(to: CGPoint(x: size, y: size * 0.41))
                p.addQuadCurve(
                    to: CGPoint(x: 0, y: size * 0.41),
                    control: CGPoint(x: size / 2, y: size * 0.33)
                )
                p.closeSubpath()
            }
            .fill(Color.white.opacity(0.03))
        }
    }

    private var coin: some View {
        let cx = size * 0.5
        let cy = size * 0.547
        let rimR = size * 0.303
        let innerR = size * 0.252
        return ZStack {
            // Rim
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xFFF2B8),
                            Color(hex: 0xF5C542),
                            Color(hex: 0xC8872C),
                            Color(hex: 0x7A4618)
                        ],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 0,
                        endRadius: rimR
                    )
                )
                .frame(width: rimR * 2, height: rimR * 2)
                .position(x: cx, y: cy)

            // Inner face
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xFFE899),
                            Color(hex: 0xF5C542),
                            Color(hex: 0xC8872C)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: innerR
                    )
                )
                .frame(width: innerR * 2, height: innerR * 2)
                .position(x: cx, y: cy)

            // Rim shadow ring
            Circle()
                .strokeBorder(Color(hex: 0x7A4618).opacity(0.45), lineWidth: size * 0.0024)
                .frame(width: innerR * 2, height: innerR * 2)
                .position(x: cx, y: cy)

            // Specular
            Ellipse()
                .fill(Color.white.opacity(0.35))
                .frame(width: size * 0.254, height: size * 0.098)
                .position(x: size * 0.41, y: size * 0.43)
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: size * 0.137, height: size * 0.043)
                .position(x: size * 0.39, y: size * 0.415)

            sStroke
        }
    }

    private var sStroke: some View {
        // Three-layered S stroke (shadow / white / honey)
        let sPath = Path { p in
            p.move(to: CGPoint(x: 620, y: 460))
            p.addCurve(to: CGPoint(x: 484, y: 376),
                       control1: CGPoint(x: 620, y: 398),
                       control2: CGPoint(x: 548, y: 376))
            p.addCurve(to: CGPoint(x: 366, y: 466),
                       control1: CGPoint(x: 410, y: 376),
                       control2: CGPoint(x: 366, y: 412))
            p.addCurve(to: CGPoint(x: 490, y: 554),
                       control1: CGPoint(x: 366, y: 522),
                       control2: CGPoint(x: 422, y: 542))
            p.addCurve(to: CGPoint(x: 622, y: 646),
                       control1: CGPoint(x: 558, y: 566),
                       control2: CGPoint(x: 622, y: 588))
            p.addCurve(to: CGPoint(x: 484, y: 738),
                       control1: CGPoint(x: 622, y: 704),
                       control2: CGPoint(x: 558, y: 738))
            p.addCurve(to: CGPoint(x: 360, y: 672),
                       control1: CGPoint(x: 420, y: 738),
                       control2: CGPoint(x: 374, y: 714))
        }
        let scale = size / 1024
        return ZStack {
            sPath.stroke(Color(hex: 0x7A4618).opacity(0.22),
                         style: StrokeStyle(lineWidth: 62, lineCap: .round, lineJoin: .round))
            sPath.stroke(Color(hex: 0xFFF6D8),
                         style: StrokeStyle(lineWidth: 54, lineCap: .round, lineJoin: .round))
            sPath.stroke(Color(hex: 0xE8B94E).opacity(0.6),
                         style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
        }
        .scaleEffect(scale, anchor: .topLeading)
    }

    private var leaves: some View {
        let scale = size / 1024
        return ZStack {
            // Big leaf upper-right
            leafShape(large: true)
                .offset(x: 600 - 512, y: 250 - 512)
                .rotationEffect(.degrees(18))
            // Small leaf left
            leafShape(large: false)
                .offset(x: 470 - 512, y: 282 - 512)
                .rotationEffect(.degrees(-22))
        }
        .frame(width: 1024, height: 1024)
        .scaleEffect(scale)
    }

    @ViewBuilder
    private func leafShape(large: Bool) -> some View {
        let leafPath = Path { p in
            if large {
                p.move(to: .zero)
                p.addQuadCurve(to: CGPoint(x: -12, y: -170),
                               control: CGPoint(x: -50, y: -80))
                p.addQuadCurve(to: CGPoint(x: 38, y: -24),
                               control: CGPoint(x: 62, y: -118))
                p.closeSubpath()
            } else {
                p.move(to: .zero)
                p.addQuadCurve(to: CGPoint(x: -4, y: -82),
                               control: CGPoint(x: -28, y: -38))
                p.addQuadCurve(to: CGPoint(x: 18, y: -14),
                               control: CGPoint(x: 32, y: -52))
                p.closeSubpath()
            }
        }
        leafPath
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0xC8F088), Color(hex: 0x7EC552), Color(hex: 0x2F6B1F)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                leafPath.stroke(Color(hex: 0x1A3D1A),
                                 style: StrokeStyle(lineWidth: large ? 3 : 2.5))
            )
    }
}

// MARK: - Nav icons (5, all 24×24 stroke-based)

nonisolated enum SplurjNavIcon: String, CaseIterable, Sendable {
    case home, coach, wallet, pacts, hub
}

struct SplurjNavIconView: View {
    let icon: SplurjNavIcon
    var size: CGFloat = 24
    var color: Color = Color.primary

    var body: some View {
        Group {
            switch icon {
            case .home:   HomeIcon()
            case .coach:  CoachIcon()
            case .wallet: WalletIcon()
            case .pacts:  PactsIcon()
            case .hub:    HubIcon()
            }
        }
        .frame(width: size, height: size)
        .foregroundStyle(color)
    }
}

private struct HomeIcon: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 3, y: 11.5))
                p.addLine(to: CGPoint(x: 12, y: 4))
                p.addLine(to: CGPoint(x: 21, y: 11.5))
            }
            .stroke(Color.primary, style: stroke)

            Path { p in
                p.move(to: CGPoint(x: 5, y: 10.5))
                p.addLine(to: CGPoint(x: 5, y: 20))
                p.addQuadCurve(to: CGPoint(x: 6, y: 21), control: CGPoint(x: 5, y: 21))
                p.addLine(to: CGPoint(x: 18, y: 21))
                p.addQuadCurve(to: CGPoint(x: 19, y: 20), control: CGPoint(x: 19, y: 21))
                p.addLine(to: CGPoint(x: 19, y: 10.5))
            }
            .stroke(Color.primary, style: stroke)

            // Leaf above roof
            Path { p in
                p.move(to: CGPoint(x: 12, y: 4))
                p.addQuadCurve(to: CGPoint(x: 12, y: 0.4), control: CGPoint(x: 10, y: 1.8))
                p.addQuadCurve(to: CGPoint(x: 12, y: 4), control: CGPoint(x: 14, y: 1.8))
                p.closeSubpath()
            }
            .fill(Color.primary)

            // Doorway
            Path { p in
                p.move(to: CGPoint(x: 10, y: 21))
                p.addLine(to: CGPoint(x: 10, y: 15))
                p.addQuadCurve(to: CGPoint(x: 14, y: 15), control: CGPoint(x: 12, y: 13))
                p.addLine(to: CGPoint(x: 14, y: 21))
            }
            .stroke(Color.primary, style: stroke)
        }
        .compositingGroup()
        .accessibilityHidden(true)
    }
    private var stroke: StrokeStyle { StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round) }
}

private struct CoachIcon: View {
    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.primary, lineWidth: 2).frame(width: 18, height: 18)
            // Compass needle — softened 4-point
            Path { p in
                p.move(to: CGPoint(x: 12, y: 6.5))
                p.addLine(to: CGPoint(x: 14, y: 12))
                p.addLine(to: CGPoint(x: 12, y: 17.5))
                p.addLine(to: CGPoint(x: 10, y: 12))
                p.closeSubpath()
            }
            .stroke(Color.primary, style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
            Circle().fill(Color.primary).frame(width: 2.2, height: 2.2)
        }
        .accessibilityHidden(true)
    }
}

private struct WalletIcon: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 4, y: 8))
                p.addCurve(to: CGPoint(x: 6, y: 6),
                           control1: CGPoint(x: 4, y: 6.9),
                           control2: CGPoint(x: 4.9, y: 6))
                p.addLine(to: CGPoint(x: 17, y: 6))
                p.addCurve(to: CGPoint(x: 19, y: 8),
                           control1: CGPoint(x: 18.1, y: 6),
                           control2: CGPoint(x: 19, y: 6.9))
                p.addLine(to: CGPoint(x: 19, y: 9))
            }
            .stroke(Color.primary, style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))

            Path { p in
                p.move(to: CGPoint(x: 3, y: 10))
                p.addCurve(to: CGPoint(x: 5, y: 8),
                           control1: CGPoint(x: 3, y: 8.9),
                           control2: CGPoint(x: 3.9, y: 8))
                p.addLine(to: CGPoint(x: 19, y: 8))
                p.addCurve(to: CGPoint(x: 21, y: 10),
                           control1: CGPoint(x: 20.1, y: 8),
                           control2: CGPoint(x: 21, y: 8.9))
                p.addLine(to: CGPoint(x: 21, y: 18))
                p.addCurve(to: CGPoint(x: 19, y: 20),
                           control1: CGPoint(x: 21, y: 19.1),
                           control2: CGPoint(x: 20.1, y: 20))
                p.addLine(to: CGPoint(x: 5, y: 20))
                p.addCurve(to: CGPoint(x: 3, y: 18),
                           control1: CGPoint(x: 3.9, y: 20),
                           control2: CGPoint(x: 3, y: 19.1))
                p.closeSubpath()
            }
            .stroke(Color.primary, style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Clasp button
            Circle().strokeBorder(Color.primary, lineWidth: 2)
                .frame(width: 2.6, height: 2.6)
                .offset(x: 5, y: 2.5)
        }
        .accessibilityHidden(true)
    }
}

private struct PactsIcon: View {
    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.primary, lineWidth: 2)
                .frame(width: 10, height: 10)
                .offset(x: -3, y: 0)
            Circle().strokeBorder(Color.primary, lineWidth: 2)
                .frame(width: 10, height: 10)
                .offset(x: 3, y: 0)
            // Overlap emphasis
            Path { p in
                p.move(to: CGPoint(x: 12, y: 8.2))
                p.addQuadCurve(to: CGPoint(x: 12, y: 15.8), control: CGPoint(x: 10.6, y: 12))
                p.addQuadCurve(to: CGPoint(x: 12, y: 8.2), control: CGPoint(x: 13.4, y: 12))
                p.closeSubpath()
            }
            .fill(Color.primary.opacity(0.18))
            .stroke(Color.primary, style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

private struct HubIcon: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 12, y: 3.5))
                p.addLine(to: CGPoint(x: 13, y: 10.5))
                p.addLine(to: CGPoint(x: 20, y: 12))
                p.addLine(to: CGPoint(x: 13, y: 13.5))
                p.addLine(to: CGPoint(x: 12, y: 20.5))
                p.addLine(to: CGPoint(x: 11, y: 13.5))
                p.addLine(to: CGPoint(x: 4, y: 12))
                p.addLine(to: CGPoint(x: 11, y: 10.5))
                p.closeSubpath()
            }
            .stroke(Color.primary, style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Small satellite
            Path { p in
                p.move(to: CGPoint(x: 18.5, y: 6))
                p.addLine(to: CGPoint(x: 19.2, y: 7.5))
                p.addLine(to: CGPoint(x: 20.7, y: 8.2))
                p.addLine(to: CGPoint(x: 19.2, y: 8.9))
                p.addLine(to: CGPoint(x: 18.5, y: 10.4))
                p.addLine(to: CGPoint(x: 17.8, y: 8.9))
                p.addLine(to: CGPoint(x: 16.3, y: 8.2))
                p.addLine(to: CGPoint(x: 17.8, y: 7.5))
                p.closeSubpath()
            }
            .stroke(Color.primary, style: .init(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Wordmark") {
    SplurjWordmark(height: 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}

#Preview("App icon") {
    VStack(spacing: 20) {
        SplurjAppIcon(size: 200)
        SplurjAppIcon(size: 80)
        SplurjAppIcon(size: 40)
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Nav icons") {
    HStack(spacing: 24) {
        ForEach(SplurjNavIcon.allCases, id: \.self) { icon in
            VStack(spacing: 6) {
                SplurjNavIconView(icon: icon, size: 28, color: Theme.glow)
                Text(icon.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
#endif
