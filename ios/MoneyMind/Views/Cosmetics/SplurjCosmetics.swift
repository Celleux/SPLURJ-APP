import SwiftUI

// MARK: - Cosmetic model
//
// Port of cosmetics/items.jsx. 24 clay-style items across 4 buckets:
// flowers (8), wearables (6), props (5), orbit particles (5). Each is
// a 64-point SVG-equivalent rendered as a SwiftUI View. A locked state
// desaturates.
//
// `slot` drives where the item attaches to the mascot in-app:
//   .head  — on top (flowers, caps, crowns)
//   .face  — over the face (glasses, monocle)
//   .neck  — around the neck (scarf)
//   .body  — on/around the body (cape, lavender, bellflower)
//   .base  — at the feet (lotus)
//   .bg    — rendered behind the mascot (moon, constellation, stump)
//   .orbit — floats around the mascot at angle × radius (firefly, etc.)

nonisolated enum CosmeticSlot: String, Sendable, CaseIterable {
    case head, face, neck, body, base, bg, orbit
}

nonisolated enum CosmeticBucket: String, Sendable, CaseIterable {
    case flowers, wearables, props, orbit
    var title: String {
        switch self {
        case .flowers:   "Flowers"
        case .wearables: "Wearables"
        case .props:     "Props"
        case .orbit:     "Orbit"
        }
    }
}

nonisolated enum CosmeticRarity: String, Sendable {
    case common, rare, epic, legendary

    var color: Color {
        switch self {
        case .common:    Theme.textMuted
        case .rare:      Theme.sky
        case .epic:      Color(hex: 0xC8A8E8)
        case .legendary: Theme.honey
        }
    }
}

nonisolated enum CosmeticID: String, Identifiable, CaseIterable, Sendable, Hashable {
    // Flowers
    case rosebud, daisy, sunflower, lavender, cherry, marigold, lotus, bellflower
    // Wearables
    case acornCap = "acorn-cap", leafCape = "leaf-cape", monocle, glasses, scarf, crown
    // Props
    case stump, moon, stars, stones, mushroom
    // Orbit
    case firefly, butterfly, sparkle, petal, dewdrop

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rosebud:    "Rosebud"
        case .daisy:      "Daisy"
        case .sunflower:  "Sunflower"
        case .lavender:   "Lavender"
        case .cherry:     "Cherry Bloom"
        case .marigold:   "Marigold"
        case .lotus:      "Lotus"
        case .bellflower: "Bellflower"
        case .acornCap:   "Acorn Cap"
        case .leafCape:   "Leaf Cape"
        case .monocle:    "Coin Monocle"
        case .glasses:    "Scholar\u{2019}s Glasses"
        case .scarf:      "Cozy Scarf"
        case .crown:      "Bloom Crown"
        case .stump:      "Mossy Stump"
        case .moon:       "Crescent Moon"
        case .stars:      "Constellation"
        case .stones:     "River Stones"
        case .mushroom:   "Red Mushroom"
        case .firefly:    "Firefly"
        case .butterfly:  "Butterfly"
        case .sparkle:    "Sparkle"
        case .petal:      "Petal"
        case .dewdrop:    "Dewdrop"
        }
    }

    var slot: CosmeticSlot {
        switch self {
        case .rosebud, .daisy, .sunflower, .cherry, .marigold, .acornCap, .crown: .head
        case .monocle, .glasses: .face
        case .scarf: .neck
        case .lavender, .bellflower, .leafCape: .body
        case .lotus: .base
        case .stump, .moon, .stars, .stones, .mushroom: .bg
        case .firefly, .butterfly, .sparkle, .petal, .dewdrop: .orbit
        }
    }

    var bucket: CosmeticBucket {
        switch self {
        case .rosebud, .daisy, .sunflower, .lavender, .cherry, .marigold, .lotus, .bellflower: .flowers
        case .acornCap, .leafCape, .monocle, .glasses, .scarf, .crown: .wearables
        case .stump, .moon, .stars, .stones, .mushroom: .props
        case .firefly, .butterfly, .sparkle, .petal, .dewdrop: .orbit
        }
    }

    var rarity: CosmeticRarity {
        switch self {
        case .rosebud, .daisy, .lavender, .bellflower, .acornCap, .scarf, .stump, .stones, .sparkle, .petal, .firefly: .common
        case .sunflower, .cherry, .marigold, .leafCape, .glasses, .moon, .mushroom, .butterfly, .dewdrop: .rare
        case .lotus, .monocle, .stars: .epic
        case .crown: .legendary
        }
    }
}

// MARK: - Palettes used across cosmetics

private enum CosmeticPalette {
    case leafGreen, petalPink, petalHoney, petalLavender, petalCoral, petalWhite
    case moss, stone, gold, sky, amber, night

    func gradient(center: UnitPoint = UnitPoint(x: 0.4, y: 0.3), radius: CGFloat = 20) -> RadialGradient {
        RadialGradient(colors: [light, hue, dark], center: center, startRadius: 0, endRadius: radius)
    }

    var hue: Color {
        switch self {
        case .leafGreen:     Color(hex: 0x7EC552)
        case .petalPink:     Color(hex: 0xFFBCD9)
        case .petalHoney:    Color(hex: 0xE8B94E)
        case .petalLavender: Color(hex: 0xC8A8E8)
        case .petalCoral:    Color(hex: 0xFF8E7E)
        case .petalWhite:    Color(hex: 0xF5F0E4)
        case .moss:          Color(hex: 0x6A9B4A)
        case .stone:         Color(hex: 0x8A8E80)
        case .gold:          Color(hex: 0xE8B94E)
        case .sky:            Color(hex: 0x8DB8E8)
        case .amber:          Color(hex: 0xE8805A)
        case .night:          Color(hex: 0x2E3E5A)
        }
    }

    var light: Color {
        switch self {
        case .leafGreen:     Color(hex: 0xD4F0A0)
        case .petalPink:     Color(hex: 0xFFE0ED)
        case .petalHoney:    Color(hex: 0xFFE899)
        case .petalLavender: Color(hex: 0xE8D8F5)
        case .petalCoral:    Color(hex: 0xFFC8B8)
        case .petalWhite:    Color(hex: 0xFFFFFF)
        case .moss:          Color(hex: 0xA8D888)
        case .stone:         Color(hex: 0xC8CCBE)
        case .gold:          Color(hex: 0xFFE899)
        case .sky:           Color(hex: 0xD4E4F8)
        case .amber:         Color(hex: 0xFFB498)
        case .night:         Color(hex: 0x6A7E9E)
        }
    }

    var dark: Color {
        switch self {
        case .leafGreen:     Color(hex: 0x2F6B1F)
        case .petalPink:     Color(hex: 0xA04A78)
        case .petalHoney:    Color(hex: 0x8B5A1A)
        case .petalLavender: Color(hex: 0x6A4A8E)
        case .petalCoral:    Color(hex: 0xA03E2E)
        case .petalWhite:    Color(hex: 0x8E8878)
        case .moss:          Color(hex: 0x2F4E1F)
        case .stone:         Color(hex: 0x3E4238)
        case .gold:          Color(hex: 0x7A4618)
        case .sky:           Color(hex: 0x3E6A9E)
        case .amber:         Color(hex: 0x8E3A1E)
        case .night:         Color(hex: 0x0E1A2E)
        }
    }
}

// MARK: - Petal shape — used in most flowers

private struct ClayPetalShape: Shape {
    var rx: CGFloat
    var ry: CGFloat
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addEllipse(in: CGRect(
                x: rect.midX - rx, y: rect.midY - ry,
                width: rx * 2, height: ry * 2
            ))
        }
    }
}

private struct ClayPetal: View {
    let cx: CGFloat
    let cy: CGFloat
    let rx: CGFloat
    let ry: CGFloat
    var rotation: Double = 0
    let palette: CosmeticPalette

    var body: some View {
        Ellipse()
            .fill(palette.gradient(radius: max(rx, ry)))
            .frame(width: rx * 2, height: ry * 2)
            .overlay(Ellipse().stroke(palette.dark, lineWidth: 0.8))
            .rotationEffect(.degrees(rotation), anchor: UnitPoint(x: 0.5, y: 1))
            .offset(x: cx - 32, y: cy - 32)
    }
}

// MARK: - Small leaf used as accent

private struct MiniLeaf: View {
    let x: CGFloat
    let y: CGFloat
    var scale: CGFloat = 0.5
    var rotation: Double = 0

    var body: some View {
        Path { p in
            p.move(to: .zero)
            p.addQuadCurve(to: CGPoint(x: -6, y: -18), control: CGPoint(x: -10, y: -10))
            p.addQuadCurve(to: CGPoint(x: 6, y: -4), control: CGPoint(x: 12, y: -14))
            p.closeSubpath()
        }
        .fill(CosmeticPalette.leafGreen.gradient(radius: 12))
        .overlay(
            Path { p in
                p.move(to: .zero)
                p.addQuadCurve(to: CGPoint(x: -6, y: -18), control: CGPoint(x: -10, y: -10))
                p.addQuadCurve(to: CGPoint(x: 6, y: -4), control: CGPoint(x: 12, y: -14))
            }.stroke(Color(hex: 0x1A3D1A), lineWidth: 1)
        )
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .offset(x: x - 32, y: y - 32)
    }
}

// MARK: - Cosmetic render

struct SplurjCosmeticView: View {
    let id: CosmeticID
    var size: CGFloat = 64
    var locked: Bool = false

    var body: some View {
        Group {
            switch id {
            case .rosebud:    rosebud
            case .daisy:      daisy
            case .sunflower:  sunflower
            case .lavender:   lavender
            case .cherry:     cherry
            case .marigold:   marigold
            case .lotus:      lotus
            case .bellflower: bellflower
            case .acornCap:   acornCap
            case .leafCape:   leafCape
            case .monocle:    monocle
            case .glasses:    glasses
            case .scarf:      scarf
            case .crown:      crown
            case .stump:      stump
            case .moon:       moon
            case .stars:      stars
            case .stones:     stones
            case .mushroom:   mushroom
            case .firefly:    firefly
            case .butterfly:  butterfly
            case .sparkle:    sparkle
            case .petal:      petalOrbit
            case .dewdrop:    dewdrop
            }
        }
        .frame(width: 64, height: 64)
        .saturation(locked ? 0 : 1)
        .brightness(locked ? -0.3 : 0)
        .opacity(locked ? 0.55 : 1)
        .frame(width: size, height: size)
        .scaleEffect(size / 64)
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("\(id.displayName), \(locked ? "locked" : "unlocked")")
    }

    // MARK: Flowers

    private var rosebud: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                ClayPetal(cx: 32, cy: 30, rx: 8, ry: 11, rotation: Double(i) * 72, palette: .petalPink)
            }
            Circle().fill(Color(hex: 0xE8B94E)).frame(width: 8, height: 8).offset(y: -4)
            Circle().fill(Color(hex: 0xFFF0B8)).frame(width: 3, height: 3).offset(x: -1, y: -5)
            MiniLeaf(x: 42, y: 40, scale: 0.5, rotation: 30)
        }
    }

    private var daisy: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                ClayPetal(cx: 32, cy: 30, rx: 5.5, ry: 10, rotation: Double(i) * 45, palette: .petalWhite)
            }
            Circle().fill(CosmeticPalette.gold.gradient(radius: 6)).frame(width: 10, height: 10).offset(y: -4)
        }
    }

    private var sunflower: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                ClayPetal(cx: 32, cy: 30, rx: 5, ry: 11, rotation: Double(i) * 36, palette: .petalHoney)
            }
            Circle().fill(Color(hex: 0x5A3410)).frame(width: 13, height: 13).offset(y: -4)
            // Seed dots
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(Color(hex: 0x8E6A3A)).frame(width: 1.6, height: 1.6)
                    .offset(x: [-2, 2, 0][i], y: [-6, -5, -2][i])
            }
        }
    }

    private var lavender: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x2F6B1F))
                .frame(width: 1.8, height: 22)
                .offset(y: 7)
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(CosmeticPalette.petalLavender.gradient(radius: 8))
                    .frame(width: 10 - CGFloat(i) * 0.4, height: 6)
                    .overlay(Ellipse().stroke(CosmeticPalette.petalLavender.dark, lineWidth: 0.6))
                    .offset(y: CGFloat(i) * 4 - 14)
            }
            MiniLeaf(x: 26, y: 46, scale: 0.4, rotation: -30)
            MiniLeaf(x: 38, y: 44, scale: 0.4, rotation: 30)
        }
    }

    private var cherry: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let angle = Double(i) * 72 * .pi / 180
                ClayPetal(
                    cx: 32 + 9 * CGFloat(cos(angle - .pi / 2)),
                    cy: 30 + 9 * CGFloat(sin(angle - .pi / 2)),
                    rx: 7, ry: 8,
                    rotation: Double(i) * 72,
                    palette: .petalPink
                )
            }
            Circle().fill(CosmeticPalette.gold.gradient(radius: 4)).frame(width: 6, height: 6).offset(y: -2)
        }
    }

    private var marigold: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                ClayPetal(cx: 32, cy: 30, rx: 4, ry: 9, rotation: Double(i) * (360.0/14), palette: .amber)
            }
            ForEach(0..<8, id: \.self) { i in
                ClayPetal(cx: 32, cy: 30, rx: 3.5, ry: 6, rotation: Double(i) * 45 + 22, palette: .petalHoney)
            }
            Circle().fill(Color(hex: 0x8E3A1E)).frame(width: 6, height: 6).offset(y: -2)
        }
    }

    private var lotus: some View {
        ZStack {
            ForEach([-60.0, -30, 0, 30, 60], id: \.self) { r in
                ClayPetal(cx: 32, cy: 32, rx: 7, ry: 14, rotation: r, palette: .petalPink)
            }
            ForEach([-40.0, -15, 15, 40], id: \.self) { r in
                ClayPetal(cx: 32, cy: 34, rx: 5, ry: 10, rotation: r, palette: .petalWhite)
            }
            Ellipse().fill(CosmeticPalette.gold.gradient(radius: 4)).frame(width: 6, height: 4).offset(y: 2)
            // Water ripples
            Path { p in
                p.move(to: CGPoint(x: 10, y: 48))
                p.addQuadCurve(to: CGPoint(x: 30, y: 48), control: CGPoint(x: 20, y: 46))
            }
            .stroke(Color(hex: 0x8DB8E8).opacity(0.6), lineWidth: 0.8)
        }
    }

    private var bellflower: some View {
        ZStack {
            // Stem
            Path { p in
                p.move(to: CGPoint(x: 32, y: 52))
                p.addQuadCurve(to: CGPoint(x: 32, y: 22), control: CGPoint(x: 30, y: 40))
            }
            .stroke(Color(hex: 0x2F6B1F), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

            // 3 bells
            bellPath(offset: CGPoint(x: 25, y: 24))
            bellPath(offset: CGPoint(x: 41, y: 30))
            bellPath(offset: CGPoint(x: 29, y: 38))

            MiniLeaf(x: 38, y: 44, scale: 0.45, rotation: 40)
        }
    }

    private func bellPath(offset: CGPoint) -> some View {
        Path { p in
            p.move(to: CGPoint(x: offset.x - 3, y: offset.y))
            p.addQuadCurve(to: CGPoint(x: offset.x + 3, y: offset.y - 8),
                           control: CGPoint(x: offset.x - 3, y: offset.y - 8))
            p.addQuadCurve(to: CGPoint(x: offset.x + 7, y: offset.y),
                           control: CGPoint(x: offset.x + 3, y: offset.y))
            p.addQuadCurve(to: CGPoint(x: offset.x - 3, y: offset.y),
                           control: CGPoint(x: offset.x + 3, y: offset.y + 4))
            p.closeSubpath()
        }
        .fill(CosmeticPalette.petalLavender.gradient(radius: 6))
        .overlay(
            Path { p in
                p.move(to: CGPoint(x: offset.x - 3, y: offset.y))
                p.addQuadCurve(to: CGPoint(x: offset.x + 3, y: offset.y - 8),
                               control: CGPoint(x: offset.x - 3, y: offset.y - 8))
                p.addQuadCurve(to: CGPoint(x: offset.x + 7, y: offset.y),
                               control: CGPoint(x: offset.x + 3, y: offset.y))
                p.addQuadCurve(to: CGPoint(x: offset.x - 3, y: offset.y),
                               control: CGPoint(x: offset.x + 3, y: offset.y + 4))
            }.stroke(CosmeticPalette.petalLavender.dark, lineWidth: 0.8)
        )
    }

    // MARK: Wearables

    private var acornCap: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 16, y: 36))
                p.addQuadCurve(to: CGPoint(x: 48, y: 36), control: CGPoint(x: 32, y: 10))
                p.addQuadCurve(to: CGPoint(x: 16, y: 36), control: CGPoint(x: 32, y: 44))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.amber.gradient(radius: 20))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 16, y: 36))
                    p.addQuadCurve(to: CGPoint(x: 48, y: 36), control: CGPoint(x: 32, y: 10))
                    p.addQuadCurve(to: CGPoint(x: 16, y: 36), control: CGPoint(x: 32, y: 44))
                }.stroke(CosmeticPalette.amber.dark, lineWidth: 1)
            )
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(CosmeticPalette.amber.dark.opacity(0.5))
                    .frame(width: 3.6, height: 3.6)
                    .offset(x: CGFloat(i) * 6 - 12, y: CGFloat(i % 2 == 0 ? -6 : -3))
            }
            // Stem
            Capsule()
                .fill(Color(hex: 0x4A2810))
                .frame(width: 2.5, height: 8)
                .offset(y: -22)
        }
    }

    private var leafCape: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 12, y: 30))
                p.addQuadCurve(to: CGPoint(x: 20, y: 54), control: CGPoint(x: 8, y: 48))
                p.addQuadCurve(to: CGPoint(x: 44, y: 54), control: CGPoint(x: 32, y: 56))
                p.addQuadCurve(to: CGPoint(x: 52, y: 30), control: CGPoint(x: 56, y: 48))
                p.addQuadCurve(to: CGPoint(x: 32, y: 36), control: CGPoint(x: 42, y: 36))
                p.addQuadCurve(to: CGPoint(x: 12, y: 30), control: CGPoint(x: 22, y: 36))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.leafGreen.gradient(radius: 24))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 30))
                    p.addQuadCurve(to: CGPoint(x: 20, y: 54), control: CGPoint(x: 8, y: 48))
                    p.addQuadCurve(to: CGPoint(x: 44, y: 54), control: CGPoint(x: 32, y: 56))
                    p.addQuadCurve(to: CGPoint(x: 52, y: 30), control: CGPoint(x: 56, y: 48))
                }.stroke(Color(hex: 0x1A3D1A), lineWidth: 1)
            )
        }
    }

    private var monocle: some View {
        ZStack {
            Circle()
                .strokeBorder(CosmeticPalette.gold.gradient(radius: 16), lineWidth: 3.5)
                .frame(width: 28, height: 28)
                .offset(x: 4)
            Circle()
                .strokeBorder(Color(hex: 0x7A4618), lineWidth: 0.8)
                .frame(width: 28, height: 28)
                .offset(x: 4)
            Circle()
                .fill(Color(hex: 0x1E3028).opacity(0.35))
                .frame(width: 21, height: 21)
                .offset(x: 4)
            // Chain
            Path { p in
                p.move(to: CGPoint(x: 12, y: 14))
                p.addQuadCurve(to: CGPoint(x: 30, y: 28),
                               control: CGPoint(x: 20, y: 22))
                p.addQuadCurve(to: CGPoint(x: 40, y: 44),
                               control: CGPoint(x: 40, y: 36))
            }
            .stroke(CosmeticPalette.gold.hue, style: StrokeStyle(lineWidth: 0.8, dash: [1, 1.5]))
        }
    }

    private var glasses: some View {
        ZStack {
            Circle().fill(Color(hex: 0x0E1A16)).frame(width: 20, height: 20).offset(x: -12)
            Circle().strokeBorder(CosmeticPalette.gold.hue, lineWidth: 2).frame(width: 20, height: 20).offset(x: -12)
            Circle().fill(Color(hex: 0x0E1A16)).frame(width: 20, height: 20).offset(x: 12)
            Circle().strokeBorder(CosmeticPalette.gold.hue, lineWidth: 2).frame(width: 20, height: 20).offset(x: 12)
            Rectangle().fill(CosmeticPalette.gold.hue).frame(width: 4, height: 2)
            Ellipse().fill(Color.white.opacity(0.35)).frame(width: 6, height: 4).offset(x: -16, y: -4)
            Ellipse().fill(Color.white.opacity(0.35)).frame(width: 6, height: 4).offset(x: 8, y: -4)
        }
    }

    private var scarf: some View {
        ZStack {
            // Wrap
            Path { p in
                p.move(to: CGPoint(x: 14, y: 26))
                p.addQuadCurve(to: CGPoint(x: 50, y: 26), control: CGPoint(x: 32, y: 22))
                p.addQuadCurve(to: CGPoint(x: 44, y: 36), control: CGPoint(x: 48, y: 34))
                p.addQuadCurve(to: CGPoint(x: 20, y: 36), control: CGPoint(x: 32, y: 34))
                p.addQuadCurve(to: CGPoint(x: 14, y: 26), control: CGPoint(x: 16, y: 34))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.petalCoral.gradient(radius: 22))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 14, y: 26))
                    p.addQuadCurve(to: CGPoint(x: 50, y: 26), control: CGPoint(x: 32, y: 22))
                }.stroke(CosmeticPalette.petalCoral.dark, lineWidth: 0.8)
            )
            // Draped end
            Path { p in
                p.move(to: CGPoint(x: 18, y: 36))
                p.addQuadCurve(to: CGPoint(x: 20, y: 52), control: CGPoint(x: 16, y: 44))
                p.addLine(to: CGPoint(x: 26, y: 50))
                p.addQuadCurve(to: CGPoint(x: 24, y: 36), control: CGPoint(x: 24, y: 44))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.petalCoral.gradient(radius: 12))
        }
    }

    private var crown: some View {
        ZStack {
            // Base band
            Path { p in
                p.move(to: CGPoint(x: 12, y: 34))
                p.addLine(to: CGPoint(x: 52, y: 34))
                p.addLine(to: CGPoint(x: 50, y: 42))
                p.addLine(to: CGPoint(x: 14, y: 42))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.gold.gradient(radius: 22))
            // Points
            Path { p in
                p.move(to: CGPoint(x: 12, y: 34))
                p.addLine(to: CGPoint(x: 16, y: 20))
                p.addLine(to: CGPoint(x: 22, y: 30))
                p.addLine(to: CGPoint(x: 32, y: 14))
                p.addLine(to: CGPoint(x: 42, y: 30))
                p.addLine(to: CGPoint(x: 48, y: 20))
                p.addLine(to: CGPoint(x: 52, y: 34))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.gold.gradient(radius: 22))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 34))
                    p.addLine(to: CGPoint(x: 16, y: 20))
                    p.addLine(to: CGPoint(x: 22, y: 30))
                    p.addLine(to: CGPoint(x: 32, y: 14))
                    p.addLine(to: CGPoint(x: 42, y: 30))
                    p.addLine(to: CGPoint(x: 48, y: 20))
                    p.addLine(to: CGPoint(x: 52, y: 34))
                }.stroke(Color(hex: 0x7A4618), lineWidth: 1)
            )
            // Gems
            Circle().fill(Color(hex: 0xE8805A)).frame(width: 5, height: 5).offset(x: -10, y: -2)
            Circle().fill(Color(hex: 0x8DB8E8)).frame(width: 6, height: 6).offset(y: -10)
            Circle().fill(Color(hex: 0xC8A8E8)).frame(width: 5, height: 5).offset(x: 10, y: -2)
        }
    }

    // MARK: Props

    private var stump: some View {
        ZStack {
            Ellipse().fill(CosmeticPalette.stone.gradient(radius: 24))
                .frame(width: 44, height: 16).offset(y: 12)
            RoundedRectangle(cornerRadius: 3).fill(CosmeticPalette.stone.gradient(radius: 22))
                .frame(width: 44, height: 18).offset(y: 4)
            Ellipse().fill(Color(hex: 0xC8CCBE)).frame(width: 44, height: 12).offset(y: -4)
            // Rings
            ForEach([17.0, 11, 5], id: \.self) { r in
                Ellipse()
                    .strokeBorder(Color(hex: 0x6A6E60), lineWidth: 0.6)
                    .frame(width: r * 2, height: r * 0.55)
                    .offset(y: -4)
            }
        }
    }

    private var moon: some View {
        ZStack {
            Circle().fill(CosmeticPalette.petalWhite.gradient(radius: 22))
                .frame(width: 40, height: 40).offset(y: -2)
            Circle().fill(Theme.background).frame(width: 38, height: 38).offset(x: 8, y: -6)
            // Craters
            Circle().fill(Color(hex: 0x8E8878).opacity(0.4)).frame(width: 5, height: 5).offset(x: -10, y: -6)
            Circle().fill(Color(hex: 0x8E8878).opacity(0.4)).frame(width: 3.6, height: 3.6).offset(x: -6, y: 4)
        }
    }

    private var stars: some View {
        let coords: [(CGFloat, CGFloat)] = [
            (14,20), (24,14), (34,22), (46,16), (50,30),
            (40,36), (28,32), (18,38), (32,46)
        ]
        return ZStack {
            ForEach(0..<coords.count, id: \.self) { i in
                Circle().fill(Color(hex: 0xFFE899))
                    .frame(width: 3, height: 3)
                    .offset(x: coords[i].0 - 32, y: coords[i].1 - 32)
                Circle()
                    .strokeBorder(Color(hex: 0xFFE899).opacity(0.5), lineWidth: 0.3)
                    .frame(width: 6, height: 6)
                    .offset(x: coords[i].0 - 32, y: coords[i].1 - 32)
            }
        }
    }

    private var stones: some View {
        ZStack {
            Ellipse().fill(CosmeticPalette.stone.gradient(radius: 14)).frame(width: 24, height: 14).offset(x: -10, y: 8)
            Ellipse().fill(CosmeticPalette.stone.gradient(radius: 12)).frame(width: 20, height: 12).offset(x: 6, y: 4)
            Ellipse().fill(CosmeticPalette.stone.gradient(radius: 10)).frame(width: 16, height: 10).offset(x: 16, y: 12)
            Ellipse().fill(CosmeticPalette.stone.gradient(radius: 9)).frame(width: 14, height: 8).offset(x: -18, y: 16)
            // Water line
            Path { p in
                p.move(to: CGPoint(x: 4, y: 52))
                p.addQuadCurve(to: CGPoint(x: 32, y: 52), control: CGPoint(x: 16, y: 50))
                p.addQuadCurve(to: CGPoint(x: 60, y: 52), control: CGPoint(x: 48, y: 54))
            }
            .stroke(Color(hex: 0x8DB8E8).opacity(0.55), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }
    }

    private var mushroom: some View {
        ZStack {
            // Stem
            Path { p in
                p.move(to: CGPoint(x: 26, y: 52))
                p.addQuadCurve(to: CGPoint(x: 28, y: 32), control: CGPoint(x: 24, y: 38))
                p.addLine(to: CGPoint(x: 36, y: 32))
                p.addQuadCurve(to: CGPoint(x: 38, y: 52), control: CGPoint(x: 40, y: 38))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.petalWhite.gradient(radius: 12))

            // Cap
            Path { p in
                p.move(to: CGPoint(x: 12, y: 32))
                p.addQuadCurve(to: CGPoint(x: 32, y: 14), control: CGPoint(x: 14, y: 16))
                p.addQuadCurve(to: CGPoint(x: 52, y: 32), control: CGPoint(x: 50, y: 16))
                p.addQuadCurve(to: CGPoint(x: 12, y: 32), control: CGPoint(x: 32, y: 36))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.amber.gradient(radius: 22))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 32))
                    p.addQuadCurve(to: CGPoint(x: 32, y: 14), control: CGPoint(x: 14, y: 16))
                    p.addQuadCurve(to: CGPoint(x: 52, y: 32), control: CGPoint(x: 50, y: 16))
                }.stroke(CosmeticPalette.amber.dark, lineWidth: 1)
            )
            // Spots
            Circle().fill(Color(hex: 0xF5F0E4)).frame(width: 5, height: 5).offset(x: -10, y: -8)
            Circle().fill(Color(hex: 0xF5F0E4)).frame(width: 6, height: 6).offset(x: 2, y: -12)
            Circle().fill(Color(hex: 0xF5F0E4)).frame(width: 4, height: 4).offset(x: 12, y: -6)
        }
    }

    // MARK: Orbit particles

    private var firefly: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE899).opacity(0.15)).frame(width: 36, height: 36)
            Circle().fill(Color(hex: 0xFFE899).opacity(0.3)).frame(width: 22, height: 22)
            Circle().fill(Color(hex: 0xFFF8D0)).frame(width: 10, height: 10)
            Circle().fill(.white).frame(width: 3.6, height: 3.6).offset(x: -1, y: -1)
        }
    }

    private var butterfly: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 32, y: 32))
                p.addQuadCurve(to: CGPoint(x: 14, y: 28), control: CGPoint(x: 18, y: 18))
                p.addQuadCurve(to: CGPoint(x: 32, y: 36), control: CGPoint(x: 16, y: 38))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.petalLavender.gradient(radius: 14))
            Path { p in
                p.move(to: CGPoint(x: 32, y: 32))
                p.addQuadCurve(to: CGPoint(x: 50, y: 28), control: CGPoint(x: 46, y: 18))
                p.addQuadCurve(to: CGPoint(x: 32, y: 36), control: CGPoint(x: 48, y: 38))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.petalLavender.gradient(radius: 14))
            // Body
            Capsule().fill(Color(hex: 0x2E1808)).frame(width: 3, height: 16)
            Circle().fill(Color(hex: 0x2E1808)).frame(width: 3.6, height: 3.6).offset(y: -4)
        }
    }

    private var sparkle: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 32, y: 8))
                p.addLine(to: CGPoint(x: 34, y: 28))
                p.addLine(to: CGPoint(x: 54, y: 32))
                p.addLine(to: CGPoint(x: 34, y: 36))
                p.addLine(to: CGPoint(x: 32, y: 56))
                p.addLine(to: CGPoint(x: 30, y: 36))
                p.addLine(to: CGPoint(x: 10, y: 32))
                p.addLine(to: CGPoint(x: 30, y: 28))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.gold.gradient(radius: 24))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 32, y: 8))
                    p.addLine(to: CGPoint(x: 34, y: 28))
                    p.addLine(to: CGPoint(x: 54, y: 32))
                    p.addLine(to: CGPoint(x: 34, y: 36))
                    p.addLine(to: CGPoint(x: 32, y: 56))
                    p.addLine(to: CGPoint(x: 30, y: 36))
                    p.addLine(to: CGPoint(x: 10, y: 32))
                    p.addLine(to: CGPoint(x: 30, y: 28))
                    p.closeSubpath()
                }.stroke(Color(hex: 0x7A4618), lineWidth: 0.8)
            )
            Circle().fill(Color(hex: 0xFFF8D0).opacity(0.6)).frame(width: 8, height: 8)
        }
    }

    private var petalOrbit: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 32, y: 14))
                p.addQuadCurve(to: CGPoint(x: 24, y: 36), control: CGPoint(x: 22, y: 22))
                p.addQuadCurve(to: CGPoint(x: 32, y: 50), control: CGPoint(x: 28, y: 48))
                p.addQuadCurve(to: CGPoint(x: 40, y: 36), control: CGPoint(x: 36, y: 48))
                p.addQuadCurve(to: CGPoint(x: 32, y: 14), control: CGPoint(x: 42, y: 22))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.petalPink.gradient(radius: 20))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 32, y: 14))
                    p.addQuadCurve(to: CGPoint(x: 24, y: 36), control: CGPoint(x: 22, y: 22))
                    p.addQuadCurve(to: CGPoint(x: 32, y: 50), control: CGPoint(x: 28, y: 48))
                    p.addQuadCurve(to: CGPoint(x: 40, y: 36), control: CGPoint(x: 36, y: 48))
                    p.addQuadCurve(to: CGPoint(x: 32, y: 14), control: CGPoint(x: 42, y: 22))
                }.stroke(CosmeticPalette.petalPink.dark, lineWidth: 1)
            )
            .rotationEffect(.degrees(25))
        }
    }

    private var dewdrop: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 32, y: 8))
                p.addQuadCurve(to: CGPoint(x: 22, y: 38), control: CGPoint(x: 22, y: 28))
                p.addArc(center: CGPoint(x: 32, y: 38), radius: 10,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.addQuadCurve(to: CGPoint(x: 32, y: 8), control: CGPoint(x: 42, y: 28))
                p.closeSubpath()
            }
            .fill(CosmeticPalette.sky.gradient(radius: 22))
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: 32, y: 8))
                    p.addQuadCurve(to: CGPoint(x: 22, y: 38), control: CGPoint(x: 22, y: 28))
                    p.addArc(center: CGPoint(x: 32, y: 38), radius: 10,
                             startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    p.addQuadCurve(to: CGPoint(x: 32, y: 8), control: CGPoint(x: 42, y: 28))
                }.stroke(CosmeticPalette.sky.dark, lineWidth: 1)
            )
            Ellipse().fill(.white.opacity(0.65)).frame(width: 6, height: 12).offset(x: -4, y: -2)
            Circle().fill(.white).frame(width: 3, height: 3).offset(x: -6, y: -6)
        }
    }
}

// MARK: - Collection grid

struct SplurjCosmeticsCollection: View {
    var unlocked: Set<CosmeticID> = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(CosmeticBucket.allCases, id: \.self) { bucket in
                    bucketSection(bucket)
                }
            }
            .padding(20)
        }
    }

    private func bucketSection(_ bucket: CosmeticBucket) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Kicker(bucket.title, color: Theme.glow, tracking: 1.8)
                Spacer()
                let items = CosmeticID.allCases.filter { $0.bucket == bucket }
                let earned = items.filter { unlocked.contains($0) }.count
                Text("\(earned) / \(items.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textMuted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(CosmeticID.allCases.filter { $0.bucket == bucket }) { item in
                    VStack(spacing: 4) {
                        SplurjCosmeticView(id: item, size: 64, locked: !unlocked.contains(item))
                            .frame(width: 72, height: 72)
                            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        unlocked.contains(item) ? item.rarity.color.opacity(0.45) : Theme.border,
                                        lineWidth: 1
                                    )
                            )
                        Text(item.displayName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Cosmetics · all") {
    SplurjCosmeticsCollection(unlocked: Set(CosmeticID.allCases))
        .background(Theme.background)
        .preferredColorScheme(.dark)
}

#Preview("Cosmetics · half locked") {
    let unlocked: Set<CosmeticID> = [.rosebud, .daisy, .lavender, .acornCap, .scarf, .stump, .firefly, .sparkle, .petal]
    return SplurjCosmeticsCollection(unlocked: unlocked)
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
#endif
