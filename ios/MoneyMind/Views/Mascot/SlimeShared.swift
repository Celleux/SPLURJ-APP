import SwiftUI

// MARK: - Stage + palette model
//
// Six evolution stages shared by every variant. Values align with the
// prototype lab/slime*.jsx data and CharacterStage.level(from:) on the
// Swift side.

nonisolated enum SlimeStage: Int, CaseIterable, Identifiable, Sendable {
    case seedling = 1, sprout, grass, leafy, flowering, bonsai

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .seedling:   "Seedling"
        case .sprout:     "Sprout"
        case .grass:      "Grass"
        case .leafy:      "Leafy"
        case .flowering:  "Flowering"
        case .bonsai:     "Bonsai"
        }
    }

    /// Minimum XP-derived level that unlocks this stage. Keep in lock-step
    /// with CharacterStage.level(from:) in the Swift repo.
    var minLevel: Int {
        switch self {
        case .seedling:   1
        case .sprout:     5
        case .grass:      10
        case .leafy:      20
        case .flowering:  40
        case .bonsai:     70
        }
    }

    /// Aura intensity used by glow overlays (0.0 seedling → 1.0 bonsai).
    var aura: Double {
        switch self {
        case .seedling:   0.0
        case .sprout:     0.15
        case .grass:      0.35
        case .leafy:      0.55
        case .flowering:  0.80
        case .bonsai:     1.00
        }
    }
}

/// Clay body palette used by every variant. Changing `base / hi / lo`
/// tints the egg body without altering silhouette — this is the plug the
/// personality system will use.
nonisolated struct ClayPalette: Sendable {
    let base: Color
    let hi: Color
    let lo: Color
    let baseTop: Color
    let baseLo: Color

    static let her = ClayPalette(
        base: Color(hex: 0xF7EEDC),
        hi:   Color(hex: 0xFFFBF0),
        lo:   Color(hex: 0xB89560),
        baseTop: Color(hex: 0xA8D07A),
        baseLo:  Color(hex: 0x5A8838)
    )

    static let him = ClayPalette(
        base: Color(hex: 0xEADFC8),
        hi:   Color(hex: 0xFAF4E0),
        lo:   Color(hex: 0x6A5028),
        baseTop: Color(hex: 0x8FB860),
        baseLo:  Color(hex: 0x3A5820)
    )

    static let neutral = ClayPalette(
        base: Color(hex: 0xF1E3C6),
        hi:   Color(hex: 0xFCF5E4),
        lo:   Color(hex: 0x8A6A3C),
        baseTop: Color(hex: 0x9EB872),
        baseLo:  Color(hex: 0x4A6A28)
    )
}

// MARK: - Body gradients

/// Radial gradient that fills the pear body. Highlight top-left, shadow
/// bottom-right — matches ClayDefs `-body` in shared-clay.jsx.
func clayBodyGradient(_ palette: ClayPalette) -> RadialGradient {
    RadialGradient(
        colors: [palette.hi, palette.base, palette.lo, palette.lo],
        center: UnitPoint(x: 0.32, y: 0.26),
        startRadius: 0,
        endRadius: 110
    )
}

/// Belly highlight — soft glow at the bottom of the body.
func clayBellyGradient(_ palette: ClayPalette) -> RadialGradient {
    RadialGradient(
        colors: [palette.hi.opacity(0.9), palette.hi.opacity(0)],
        center: UnitPoint(x: 0.5, y: 0.8),
        startRadius: 0,
        endRadius: 40
    )
}

/// Specular white blob applied at the upper-left of the body.
let claySpecGradient = RadialGradient(
    colors: [.white.opacity(0.95), .white.opacity(0.1), .white.opacity(0)],
    center: UnitPoint(x: 0.5, y: 0.5),
    startRadius: 0,
    endRadius: 20
)

func clayBaseTopGradient(_ palette: ClayPalette) -> RadialGradient {
    RadialGradient(
        colors: [palette.baseTop, Color(hex: 0x6FA850), palette.baseLo],
        center: UnitPoint(x: 0.5, y: 0.4),
        startRadius: 0,
        endRadius: 45
    )
}

let clayBaseRimGradient = LinearGradient(
    colors: [Color(hex: 0xF5A870), Color(hex: 0xC9683E)],
    startPoint: .top, endPoint: .bottom
)

/// Leaf face — deep green center fading to dark emerald at the edges.
let leafGradient = RadialGradient(
    colors: [Color(hex: 0xA8E67F), Color(hex: 0x66C050), Color(hex: 0x2F7A35)],
    center: UnitPoint(x: 0.4, y: 0.3),
    startRadius: 0,
    endRadius: 22
)

/// Leaf highlight — bright chartreuse sweeping across the top.
let leafHighlightGradient = RadialGradient(
    colors: [Color(hex: 0xD4F5A0), Color(hex: 0xD4F5A0).opacity(0)],
    center: UnitPoint(x: 0.5, y: 0.4),
    startRadius: 0,
    endRadius: 12
)

// MARK: - Slime body shape
//
// The pear/egg silhouette shared across every stage and variant. Uses a
// fixed 160×160 canvas so coordinates map 1:1 from the prototype JSX.
// Anchor the body at (80, 88) with w=36, h=36 — matches slime-f.jsx
// SlimeBody defaults.

struct SlimeBodyShape: Shape {
    var cx: CGFloat = 80
    var cy: CGFloat = 88
    var w: CGFloat = 36
    var h: CGFloat = 36

    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 10-point bezier loop matching the JS version's Q-curves. Each
        // quad curve connects the midpoint of the last segment to the
        // next vertex using the vertex itself as the control point.
        let pts: [CGPoint] = [
            .init(x: cx,              y: cy - h),
            .init(x: cx + w*0.78,     y: cy - h*0.6),
            .init(x: cx + w,          y: cy - h*0.05),
            .init(x: cx + w*0.95,     y: cy + h*0.5),
            .init(x: cx + w*0.6,      y: cy + h*0.95),
            .init(x: cx,              y: cy + h),
            .init(x: cx - w*0.6,      y: cy + h*0.95),
            .init(x: cx - w*0.95,     y: cy + h*0.5),
            .init(x: cx - w,          y: cy - h*0.05),
            .init(x: cx - w*0.78,     y: cy - h*0.6),
        ]
        p.move(to: pts[0])
        for i in 1..<pts.count {
            let prev = pts[i - 1]
            let next = pts[i]
            let mid = CGPoint(x: (prev.x + next.x)/2, y: (prev.y + next.y)/2)
            p.addQuadCurve(to: mid, control: prev)
        }
        // Close back to the first point.
        let last = pts.last!
        p.addQuadCurve(to: pts[0], control: last)
        p.closeSubpath()
        return p
    }
}

// MARK: - Slime body view

struct SlimeBody: View {
    let palette: ClayPalette

    var body: some View {
        ZStack {
            // Drop shadow under body (80, 131 ellipse)
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 76, height: 10)
                .offset(x: 0, y: 131 - 80)

            // Main body
            SlimeBodyShape()
                .fill(clayBodyGradient(palette))

            // Belly highlight at y ≈ 108
            Ellipse()
                .fill(clayBellyGradient(palette))
                .frame(width: 50, height: 22)
                .offset(x: 0, y: 108 - 80)

            // Specular highlight upper-left at (~58, 54) rotated -18°
            Ellipse()
                .fill(claySpecGradient)
                .frame(width: 28, height: 44)
                .rotationEffect(.degrees(-18))
                .offset(x: 58 - 80, y: 54 - 80)

            // Tiny specular pop
            Ellipse()
                .fill(Color.white.opacity(0.8))
                .frame(width: 7, height: 10)
                .rotationEffect(.degrees(-18))
                .offset(x: 52 - 80, y: 44 - 80)

            // Feet
            ArmNub(palette: palette, offset: CGPoint(x: -14, y: 47), rotation: 0, size: CGSize(width: 10, height: 5))
            ArmNub(palette: palette, offset: CGPoint(x: 14, y: 47), rotation: 0, size: CGSize(width: 10, height: 5))
        }
        .frame(width: 160, height: 160)
    }
}

// MARK: - Arm / hand nub

struct ArmNub: View {
    let palette: ClayPalette
    let offset: CGPoint     // offset from center of 160×160 canvas
    let rotation: Double    // degrees
    let size: CGSize

    var body: some View {
        Ellipse()
            .fill(clayBodyGradient(palette))
            .frame(width: size.width * 2, height: size.height * 2)
            .rotationEffect(.degrees(rotation))
            .offset(x: offset.x, y: offset.y)
    }
}

// MARK: - Feminine face (lashes, blush, soft smile)

struct FaceHer: View {
    var cy: CGFloat = 76
    var eyeGap: CGFloat = 22
    var eyeR: CGFloat = 7.8
    var mouth: Mouth = .happy
    var blushColor: Color = Color(hex: 0xFFA8B4)
    var blinkClose: Double = 0    // 0 = open, 1 = closed

    enum Mouth { case happy, openSmile, soft, smirk }

    var body: some View {
        ZStack {
            eyesGroup
            blushGroup
            noseGroup
            mouthGroup
        }
        .frame(width: 160, height: 160)
    }

    private var eyesGroup: some View {
        ZStack {
            eye(cx: 80 - eyeGap/2, cy: cy)
            eye(cx: 80 + eyeGap/2, cy: cy)

            // Lashes above each eye (the "Her" hallmark)
            lash(cx: 80 - eyeGap/2, cy: cy - eyeR, mirror: false)
            lash(cx: 80 + eyeGap/2, cy: cy - eyeR, mirror: true)
        }
    }

    @ViewBuilder
    private func eye(cx: CGFloat, cy: CGFloat) -> some View {
        let clamped = max(0.05, 1.0 - blinkClose)
        Ellipse()
            .fill(Color(hex: 0x1A0F08))
            .frame(width: eyeR * 2, height: eyeR * 2.1 * clamped)
            .offset(x: cx - 80, y: cy - 80)

        // Catchlight — big soft upper-left
        Ellipse()
            .fill(Color.white.opacity(0.95))
            .frame(width: eyeR * 0.76, height: eyeR * 0.9 * clamped)
            .offset(x: cx - 80 + eyeR * 0.3, y: cy - 80 - eyeR * 0.35)

        // Tiny crisp catchlight — lower-left
        Circle()
            .fill(Color.white.opacity(0.7))
            .frame(width: eyeR * 0.36)
            .offset(x: cx - 80 - eyeR * 0.35, y: cy - 80 + eyeR * 0.3)
            .opacity(clamped > 0.5 ? 1 : 0)
    }

    private func lash(cx: CGFloat, cy: CGFloat, mirror: Bool) -> some View {
        let flip: CGFloat = mirror ? -1 : 1
        return ZStack {
            // Upper-lid mascara line — thick curved sweep above the eye
            Path { p in
                p.move(to: CGPoint(x: -eyeR * 1.05 * flip, y: 0.8))
                p.addQuadCurve(
                    to: CGPoint(x: eyeR * 1.05 * flip, y: 0.8),
                    control: CGPoint(x: 0, y: -eyeR * 0.55)
                )
            }
            .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

            // 4 radial lashes flaring outward
            Path { p in
                let angles: [CGFloat] = [-0.55, -0.25, 0.05, 0.35]
                for a in angles {
                    let len: CGFloat = 6
                    let start = CGPoint(
                        x: CGFloat(sin(Double(a))) * (eyeR * 0.6) * flip,
                        y: -CGFloat(cos(Double(a))) * (eyeR * 0.2)
                    )
                    let end = CGPoint(
                        x: CGFloat(sin(Double(a))) * (len + eyeR * 0.6) * flip,
                        y: -CGFloat(cos(Double(a))) * (len + eyeR * 0.2)
                    )
                    p.move(to: start)
                    p.addLine(to: end)
                }
            }
            .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: 22, height: 10)
        .offset(x: cx - 80, y: cy - 80 - 1)
    }

    private var blushGroup: some View {
        Group {
            Ellipse()
                .fill(blushColor.opacity(0.7))
                .frame(width: 13, height: 7)
                .offset(x: -eyeGap/2 - 8, y: cy - 80 + 10)
            Ellipse()
                .fill(blushColor.opacity(0.9))
                .frame(width: 6, height: 3)
                .offset(x: -eyeGap/2 - 8, y: cy - 80 + 10)
            Ellipse()
                .fill(blushColor.opacity(0.7))
                .frame(width: 13, height: 7)
                .offset(x: eyeGap/2 + 8, y: cy - 80 + 10)
            Ellipse()
                .fill(blushColor.opacity(0.9))
                .frame(width: 6, height: 3)
                .offset(x: eyeGap/2 + 8, y: cy - 80 + 10)
        }
    }

    private var noseGroup: some View {
        Group {
            Ellipse()
                .fill(Color(hex: 0xFF6F7F))
                .frame(width: 5.6, height: 4)
                .offset(x: 0, y: cy - 80 + 12)
            Ellipse()
                .fill(Color.white.opacity(0.7))
                .frame(width: 2, height: 1.4)
                .offset(x: -0.7, y: cy - 80 + 11.4)
        }
    }

    @ViewBuilder
    private var mouthGroup: some View {
        switch mouth {
        case .happy, .soft:
            Path { p in
                p.move(to: CGPoint(x: 76, y: 92))
                p.addQuadCurve(
                    to: CGPoint(x: 84, y: 92),
                    control: CGPoint(x: 80, y: 96)
                )
            }
            .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .offset(x: -80, y: cy - 80 - 12)
        case .openSmile:
            Path { p in
                p.move(to: CGPoint(x: 74, y: 92))
                p.addQuadCurve(
                    to: CGPoint(x: 86, y: 92),
                    control: CGPoint(x: 80, y: 101)
                )
            }
            .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            .offset(x: -80, y: cy - 80 - 12)
        case .smirk:
            Path { p in
                p.move(to: CGPoint(x: 74, y: 92))
                p.addQuadCurve(
                    to: CGPoint(x: 86, y: 90),
                    control: CGPoint(x: 80, y: 96)
                )
            }
            .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .offset(x: -80, y: cy - 80 - 12)
        }
    }
}

// MARK: - Leaf

struct Leaf: View {
    let cx: CGFloat
    let cy: CGFloat
    let rx: CGFloat
    let ry: CGFloat
    var rotation: Double = 0

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.18))
                .frame(width: rx * 1.9, height: ry * 1.8)
                .offset(x: rx * 0.15, y: ry * 0.4)
            Ellipse()
                .fill(leafGradient)
                .frame(width: rx * 2, height: ry * 2)
            Ellipse()
                .fill(leafHighlightGradient)
                .frame(width: rx * 0.84, height: ry * 0.96)
                .offset(x: -rx * 0.28, y: -ry * 0.32)
        }
        .rotationEffect(.degrees(rotation))
        .offset(x: cx - 80, y: cy - 80)
    }
}

// MARK: - Diorama base (moss disc + rim + grass tufts)

struct DioramaBase: View {
    var palette: ClayPalette
    var showGrass: Bool = true

    var body: some View {
        ZStack {
            Ellipse()
                .fill(clayBaseRimGradient)
                .frame(width: 120, height: 20)
                .offset(x: 0, y: 64)
            Ellipse()
                .fill(clayBaseTopGradient(palette))
                .frame(width: 120, height: 20)
                .offset(x: 0, y: 60)
            Ellipse()
                .fill(Color(hex: 0x7FB858).opacity(0.6))
                .frame(width: 108, height: 14)
                .offset(x: 0, y: 56)

            if showGrass {
                grassTufts
            }
        }
        .frame(width: 160, height: 160)
    }

    private var grassTufts: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 28, y: 138))
                p.addLine(to: CGPoint(x: 27, y: 130))
                p.addLine(to: CGPoint(x: 30, y: 134))
                p.addLine(to: CGPoint(x: 33, y: 128))
                p.addLine(to: CGPoint(x: 35, y: 136))
                p.closeSubpath()

                p.move(to: CGPoint(x: 128, y: 138))
                p.addLine(to: CGPoint(x: 127, y: 130))
                p.addLine(to: CGPoint(x: 130, y: 134))
                p.addLine(to: CGPoint(x: 133, y: 128))
                p.addLine(to: CGPoint(x: 135, y: 136))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x4F8538))

            Path { p in
                p.move(to: CGPoint(x: 44, y: 138))
                p.addLine(to: CGPoint(x: 43, y: 134))
                p.addLine(to: CGPoint(x: 46, y: 132))
                p.addLine(to: CGPoint(x: 47, y: 138))
                p.closeSubpath()

                p.move(to: CGPoint(x: 118, y: 138))
                p.addLine(to: CGPoint(x: 117, y: 134))
                p.addLine(to: CGPoint(x: 120, y: 132))
                p.addLine(to: CGPoint(x: 121, y: 138))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x5EA043))
        }
        .offset(x: -80, y: -80)
    }
}

// MARK: - Decorative sparkles

struct MiniStar: View {
    let cx: CGFloat
    let cy: CGFloat
    var size: CGFloat = 3
    var color: Color = Color(hex: 0xFFE899)

    var body: some View {
        Path { p in
            let half = size
            p.move(to: CGPoint(x: 0, y: -half))
            p.addLine(to: CGPoint(x: half * 0.35, y: -half * 0.35))
            p.addLine(to: CGPoint(x: half, y: 0))
            p.addLine(to: CGPoint(x: half * 0.35, y: half * 0.35))
            p.addLine(to: CGPoint(x: 0, y: half))
            p.addLine(to: CGPoint(x: -half * 0.35, y: half * 0.35))
            p.addLine(to: CGPoint(x: -half, y: 0))
            p.addLine(to: CGPoint(x: -half * 0.35, y: -half * 0.35))
            p.closeSubpath()
        }
        .fill(color)
        .frame(width: size * 2, height: size * 2)
        .offset(x: cx - 80, y: cy - 80)
    }
}

// MARK: - Seed (held in stage 1)

struct SeedInHands: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: 20, height: 5)
                .offset(y: 3)
            Ellipse()
                .fill(Color(hex: 0x6B4024))
                .frame(width: 14, height: 18)
            Ellipse()
                .fill(Color(hex: 0xA56A3C))
                .frame(width: 6, height: 9)
                .offset(x: -2, y: -2.5)
            Path { p in
                p.move(to: CGPoint(x: -1, y: -8))
                p.addQuadCurve(to: CGPoint(x: 1, y: -8), control: CGPoint(x: 0, y: -11))
            }
            .stroke(Color(hex: 0x4A8F3A), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            Circle()
                .fill(Color(hex: 0x7EC552))
                .frame(width: 4)
                .offset(y: -10)
        }
        .frame(width: 30, height: 30)
    }
}
