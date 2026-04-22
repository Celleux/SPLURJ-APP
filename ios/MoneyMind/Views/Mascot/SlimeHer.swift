import SwiftUI

// MARK: - Slime Her — 6 evolution stages
//
// SwiftUI port of lab/slime-f.jsx. Each stage is a 160×160 canvas composed
// from SlimeShared primitives. The only per-stage art is the head content
// (sprout/grass/leaves/flowers/bonsai), arm pose, and optional decorations.
//
// All stages share:
//   - DioramaBase (moss disc with grass tufts)
//   - SlimeBody (pear egg with gradient, belly highlight, specular, feet)
//   - FaceHer (lashes, blush, soft smile)

struct SlimeHerStage1: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .her)
            // Arms holding seed — inner elbows
            ArmNub(palette: .her, offset: CGPoint(x: -20, y: 22), rotation: -25, size: CGSize(width: 9, height: 5.5))
            ArmNub(palette: .her, offset: CGPoint(x: 20, y: 22), rotation: 25, size: CGSize(width: 9, height: 5.5))
            SlimeBody(palette: .her)
            FaceHer(cy: 76)
            SeedInHands()
                .offset(x: 0, y: 28)
            MiniStar(cx: 36, cy: 56, size: 3, color: Color(hex: 0xFFB5D6))
            MiniStar(cx: 124, cy: 60, size: 3, color: Color(hex: 0xFFD166))
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeHerStage2: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .her)
            ArmNub(palette: .her, offset: CGPoint(x: -40, y: 16), rotation: -15, size: CGSize(width: 9, height: 5.5))
            ArmNub(palette: .her, offset: CGPoint(x: 40, y: 16), rotation: 15, size: CGSize(width: 9, height: 5.5))
            SlimeBody(palette: .her)
            // Sprout stem + 2 leaves on top of head (translate 80, 52)
            ZStack {
                Path { p in
                    p.move(to: .zero)
                    p.addQuadCurve(to: CGPoint(x: 0, y: -14), control: CGPoint(x: -1, y: -8))
                }
                .stroke(Color(hex: 0x4A8F3A), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                Leaf(cx: -5 + 80, cy: -12 + 80, rx: 5.5, ry: 8, rotation: -30)
                Leaf(cx: 5 + 80, cy: -14 + 80, rx: 5.5, ry: 8, rotation: 30)
            }
            .offset(x: 0, y: 52 - 80)
            FaceHer(cy: 82)
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeHerStage3: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .her)
            ArmNub(palette: .her, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .her, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            SlimeBody(palette: .her)
            // Grass tufts on head — shadow disc + 7 blades + flower bud
            Ellipse()
                .fill(Color(hex: 0x2A5822).opacity(0.4))
                .frame(width: 44, height: 8)
                .offset(x: 0, y: 55 - 80)
            grassBlades
            Circle()
                .fill(Color(hex: 0xFFD166))
                .frame(width: 5)
                .offset(x: 0, y: 26 - 80)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 2)
                .offset(x: -0.5, y: 25 - 80)
            FaceHer(cy: 92)
        }
        .frame(width: 160, height: 160)
    }

    private var grassBlades: some View {
        let blades: [(CGFloat, CGFloat, CGFloat)] = [
            (60, 15, -0.18), (68, 22, -0.06), (74, 26, -0.02), (80, 28, 0),
            (86, 26, 0.02), (92, 22, 0.06), (100, 15, 0.18)
        ]
        return ZStack {
            ForEach(0..<blades.count, id: \.self) { i in
                let (x, h, r) = blades[i]
                Path { p in
                    p.move(to: CGPoint(x: x, y: 55))
                    p.addQuadCurve(
                        to: CGPoint(x: x + r * 0.5, y: 55 - h - 2),
                        control: CGPoint(x: x + r * 0.3, y: 55 - h)
                    )
                }
                .stroke(Color(hex: 0x2A5822), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: x, y: 55))
                    p.addQuadCurve(
                        to: CGPoint(x: x + r * 0.5, y: 55 - h - 2),
                        control: CGPoint(x: x + r * 0.3, y: 55 - h)
                    )
                }
                .stroke(Color(hex: 0x7EC552), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            }
        }
        .offset(x: -80, y: -80)
    }
}

struct SlimeHerStage4: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .her)
            // Back leaves (behind head)
            Leaf(cx: 52, cy: 42, rx: 14, ry: 12, rotation: -20)
            Leaf(cx: 108, cy: 42, rx: 14, ry: 12, rotation: 20)
            Leaf(cx: 80, cy: 30, rx: 14, ry: 13)
            SlimeBody(palette: .her)
            ArmNub(palette: .her, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .her, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            // Front leafy hair clumps
            Group {
                Leaf(cx: 60, cy: 46, rx: 11, ry: 10, rotation: -25)
                Leaf(cx: 72, cy: 40, rx: 10, ry: 9, rotation: -10)
                Leaf(cx: 80, cy: 38, rx: 11, ry: 10)
                Leaf(cx: 88, cy: 40, rx: 10, ry: 9, rotation: 10)
                Leaf(cx: 100, cy: 46, rx: 11, ry: 10, rotation: 25)
                Leaf(cx: 66, cy: 34, rx: 8, ry: 7, rotation: -18)
                Leaf(cx: 94, cy: 34, rx: 8, ry: 7, rotation: 18)
            }
            // Sprig
            Path { p in
                p.move(to: CGPoint(x: 80, y: 26))
                p.addLine(to: CGPoint(x: 80, y: 18))
            }
            .stroke(Color(hex: 0x2A5822), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            Ellipse()
                .fill(Color(hex: 0x7EC552))
                .frame(width: 6, height: 8)
                .offset(x: 0, y: 17 - 80)
            FaceHer(cy: 92, eyeGap: 22, eyeR: 7)
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeHerStage5: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .her)
            Leaf(cx: 46, cy: 38, rx: 18, ry: 16, rotation: -15)
            Leaf(cx: 114, cy: 38, rx: 18, ry: 16, rotation: 15)
            Leaf(cx: 80, cy: 22, rx: 20, ry: 15)
            SlimeBody(palette: .her)
            ArmNub(palette: .her, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .her, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            // Front canopy clumps
            Group {
                Leaf(cx: 56, cy: 40, rx: 13, ry: 12)
                Leaf(cx: 70, cy: 32, rx: 12, ry: 11)
                Leaf(cx: 82, cy: 30, rx: 13, ry: 12)
                Leaf(cx: 96, cy: 32, rx: 12, ry: 11)
                Leaf(cx: 104, cy: 40, rx: 13, ry: 12)
                Leaf(cx: 62, cy: 22, rx: 10, ry: 9)
                Leaf(cx: 88, cy: 20, rx: 11, ry: 10)
            }
            // Pink flowers scattered
            flowerAt(cx: 50, cy: 32, color: Color(hex: 0xFFB5D6))
            flowerAt(cx: 72, cy: 24, color: Color(hex: 0xFF8FBE))
            flowerAt(cx: 92, cy: 22, color: Color(hex: 0xFFB5D6))
            flowerAt(cx: 110, cy: 32, color: Color(hex: 0xFF8FBE))
            flowerAt(cx: 64, cy: 38, color: Color(hex: 0xFFB5D6))
            flowerAt(cx: 96, cy: 38, color: Color(hex: 0xFFE899))
            FaceHer(cy: 92, eyeGap: 22, eyeR: 7)
            MiniStar(cx: 28, cy: 52, size: 3.5, color: Color(hex: 0xFFB5D6))
            MiniStar(cx: 132, cy: 56, size: 3.5, color: Color(hex: 0xFFD166))
        }
        .frame(width: 160, height: 160)
    }

    private func flowerAt(cx: CGFloat, cy: CGFloat, color: Color) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(color)
                    .frame(width: 5, height: 7)
                    .offset(y: -3)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(Color(hex: 0xFFD166))
                .frame(width: 3.6)
        }
        .offset(x: cx - 80, y: cy - 80)
    }
}

struct SlimeHerStage6: View {
    var body: some View {
        ZStack {
            // Halo aura
            Circle()
                .fill(Color(hex: 0xFFE899).opacity(0.14))
                .frame(width: 124, height: 124)
                .offset(x: 0, y: 60 - 80)
            DioramaBase(palette: .her)
            Leaf(cx: 40, cy: 36, rx: 22, ry: 18, rotation: -10)
            Leaf(cx: 120, cy: 36, rx: 22, ry: 18, rotation: 10)
            Leaf(cx: 80, cy: 14, rx: 26, ry: 14)
            // Trunk (above body)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x8B5A30))
                .frame(width: 8, height: 24)
                .offset(x: 0, y: 36 - 80)
            SlimeBody(palette: .her)
            ArmNub(palette: .her, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .her, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            // Canopy leaves
            Group {
                Leaf(cx: 46, cy: 36, rx: 16, ry: 14)
                Leaf(cx: 64, cy: 22, rx: 14, ry: 13)
                Leaf(cx: 80, cy: 16, rx: 16, ry: 14)
                Leaf(cx: 96, cy: 22, rx: 14, ry: 13)
                Leaf(cx: 114, cy: 36, rx: 16, ry: 14)
                Leaf(cx: 56, cy: 44, rx: 12, ry: 11)
                Leaf(cx: 104, cy: 44, rx: 12, ry: 11)
                Leaf(cx: 72, cy: 30, rx: 11, ry: 10)
                Leaf(cx: 88, cy: 30, rx: 11, ry: 10)
            }
            // Apples
            apple(cx: 50, cy: 34)
            apple(cx: 108, cy: 32)
            apple(cx: 70, cy: 40)
            apple(cx: 94, cy: 38)
            apple(cx: 80, cy: 44)
            // Book
            bookInHands
                .offset(x: 0, y: 118 - 80)
            FaceHer(cy: 92, eyeGap: 22, eyeR: 7)
            MiniStar(cx: 20, cy: 46, size: 4, color: Color(hex: 0xFFB5D6))
            MiniStar(cx: 140, cy: 46, size: 4, color: Color(hex: 0xFFD166))
        }
        .frame(width: 160, height: 160)
    }

    private func apple(cx: CGFloat, cy: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFF6F7F))
                .frame(width: 6.8)
            Ellipse()
                .fill(Color(hex: 0xFFC8CE))
                .frame(width: 2, height: 2.6)
                .offset(x: -1, y: -1)
            Path { p in
                p.move(to: CGPoint(x: 0, y: -3))
                p.addLine(to: CGPoint(x: 0, y: -5))
            }
            .stroke(Color(hex: 0x3A2510), style: StrokeStyle(lineWidth: 0.8))
        }
        .offset(x: cx - 80, y: cy - 80)
    }

    private var bookInHands: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: 44, height: 6)
                .offset(y: 8)
            Path { p in
                p.move(to: CGPoint(x: -22, y: 0))
                p.addLine(to: CGPoint(x: -22, y: 12))
                p.addLine(to: CGPoint(x: 0, y: 15))
                p.addLine(to: CGPoint(x: 0, y: 3))
                p.closeSubpath()
            }
            .fill(Color(hex: 0xF5C26A))
            Path { p in
                p.move(to: CGPoint(x: 22, y: 0))
                p.addLine(to: CGPoint(x: 22, y: 12))
                p.addLine(to: CGPoint(x: 0, y: 15))
                p.addLine(to: CGPoint(x: 0, y: 3))
                p.closeSubpath()
            }
            .fill(Color(hex: 0xE8A852))
        }
    }
}

// MARK: - Convenience dispatch

struct SlimeHerStage: View {
    let stage: SlimeStage

    init(_ stage: SlimeStage) {
        self.stage = stage
    }

    @ViewBuilder
    var body: some View {
        switch stage {
        case .seedling:   SlimeHerStage1()
        case .sprout:     SlimeHerStage2()
        case .grass:      SlimeHerStage3()
        case .leafy:      SlimeHerStage4()
        case .flowering:  SlimeHerStage5()
        case .bonsai:     SlimeHerStage6()
        }
    }
}
