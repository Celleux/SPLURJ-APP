import SwiftUI

// MARK: - Slime Him — 6 evolution stages
//
// Masculine variant. Same silhouette and evolution arc as SlimeHer but
// with:
//   - cooler palette (bodyBase #EADFC8 vs #F7EEDC)
//   - FaceHim: flat brows, smirk, no blush, no lashes
//   - accessory progression: nothing → headband → bandana →
//     backwards-cap → shades → watering-can in hand

struct SlimeHimStage1: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .him)
            ArmNub(palette: .him, offset: CGPoint(x: -20, y: 22), rotation: -25, size: CGSize(width: 9, height: 5.5))
            ArmNub(palette: .him, offset: CGPoint(x: 20, y: 22), rotation: 25, size: CGSize(width: 9, height: 5.5))
            SlimeBody(palette: .him)
            FaceHim(cy: 78)
            SeedInHands().offset(x: 0, y: 28)
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeHimStage2: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .him)
            ArmNub(palette: .him, offset: CGPoint(x: -40, y: 16), rotation: -15, size: CGSize(width: 9, height: 5.5))
            ArmNub(palette: .him, offset: CGPoint(x: 40, y: 16), rotation: 15, size: CGSize(width: 9, height: 5.5))
            SlimeBody(palette: .him)
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
            headband(cy: 72)
            FaceHim(cy: 84)
        }
        .frame(width: 160, height: 160)
    }

    private func headband(cy: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 52, y: cy))
            p.addQuadCurve(to: CGPoint(x: 108, y: cy), control: CGPoint(x: 80, y: cy - 6))
            p.addLine(to: CGPoint(x: 108, y: cy + 4))
            p.addQuadCurve(to: CGPoint(x: 52, y: cy + 4), control: CGPoint(x: 80, y: cy - 2))
            p.closeSubpath()
        }
        .fill(Color(hex: 0x3F6A8F))
        .offset(x: -80, y: -80)
    }
}

struct SlimeHimStage3: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .him)
            ArmNub(palette: .him, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .him, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            SlimeBody(palette: .him)
            grassTufts
            bandana
            FaceHim(cy: 92)
        }
        .frame(width: 160, height: 160)
    }

    private var grassTufts: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: 0x2A5822).opacity(0.4))
                .frame(width: 44, height: 8)
                .offset(x: 0, y: 55 - 80)
            let blades: [(CGFloat, CGFloat, CGFloat)] = [
                (60, 15, -0.18), (68, 22, -0.06), (74, 26, -0.02), (80, 28, 0),
                (86, 26, 0.02), (92, 22, 0.06), (100, 15, 0.18)
            ]
            ForEach(0..<blades.count, id: \.self) { i in
                let (x, h, r) = blades[i]
                Path { p in
                    p.move(to: CGPoint(x: x, y: 55))
                    p.addQuadCurve(to: CGPoint(x: x + r * 0.5, y: 55 - h - 2), control: CGPoint(x: x + r * 0.3, y: 55 - h))
                }
                .stroke(Color(hex: 0x2A5822), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
                .offset(x: -80, y: -80)
                Path { p in
                    p.move(to: CGPoint(x: x, y: 55))
                    p.addQuadCurve(to: CGPoint(x: x + r * 0.5, y: 55 - h - 2), control: CGPoint(x: x + r * 0.3, y: 55 - h))
                }
                .stroke(Color(hex: 0x7EC552), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .offset(x: -80, y: -80)
            }
        }
    }

    private var bandana: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 46, y: 76))
                p.addQuadCurve(to: CGPoint(x: 114, y: 76), control: CGPoint(x: 80, y: 68))
                p.addLine(to: CGPoint(x: 114, y: 82))
                p.addQuadCurve(to: CGPoint(x: 46, y: 82), control: CGPoint(x: 80, y: 72))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x3F6A8F))
            // Knot on right side
            Path { p in
                p.move(to: CGPoint(x: 108, y: 78))
                p.addLine(to: CGPoint(x: 122, y: 74))
                p.addLine(to: CGPoint(x: 118, y: 84))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x2A4D6A))
        }
        .offset(x: -80, y: -80)
    }
}

struct SlimeHimStage4: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .him)
            Leaf(cx: 52, cy: 42, rx: 14, ry: 12, rotation: -20)
            Leaf(cx: 108, cy: 42, rx: 14, ry: 12, rotation: 20)
            Leaf(cx: 80, cy: 30, rx: 14, ry: 13)
            SlimeBody(palette: .him)
            ArmNub(palette: .him, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .him, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            Group {
                Leaf(cx: 60, cy: 46, rx: 11, ry: 10, rotation: -25)
                Leaf(cx: 72, cy: 40, rx: 10, ry: 9, rotation: -10)
                Leaf(cx: 80, cy: 38, rx: 11, ry: 10)
                Leaf(cx: 88, cy: 40, rx: 10, ry: 9, rotation: 10)
                Leaf(cx: 100, cy: 46, rx: 11, ry: 10, rotation: 25)
                Leaf(cx: 66, cy: 34, rx: 8, ry: 7, rotation: -18)
                Leaf(cx: 94, cy: 34, rx: 8, ry: 7, rotation: 18)
            }
            bandana
            FaceHim(cy: 92, eyeGap: 22, eyeR: 6)
        }
        .frame(width: 160, height: 160)
    }

    private var bandana: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 50, y: 82))
                p.addQuadCurve(to: CGPoint(x: 110, y: 82), control: CGPoint(x: 80, y: 74))
                p.addLine(to: CGPoint(x: 110, y: 89))
                p.addQuadCurve(to: CGPoint(x: 50, y: 89), control: CGPoint(x: 80, y: 79))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x3F6A8F))
            // White dots pattern
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 2.2)
                    .offset(x: CGFloat(-24 + i * 12), y: 5)
            }
            // Knot on right side
            Path { p in
                p.move(to: CGPoint(x: 108, y: 82))
                p.addLine(to: CGPoint(x: 124, y: 78))
                p.addLine(to: CGPoint(x: 120, y: 90))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x2A4D6A))
        }
        .offset(x: -80, y: -80)
    }

    private var backwardsCap: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 56, y: 52))
                p.addQuadCurve(to: CGPoint(x: 104, y: 52), control: CGPoint(x: 80, y: 38))
                p.addLine(to: CGPoint(x: 108, y: 64))
                p.addQuadCurve(to: CGPoint(x: 54, y: 64), control: CGPoint(x: 80, y: 58))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x2B4A68))
            // Strap tab
            Path { p in
                p.move(to: CGPoint(x: 76, y: 54))
                p.addLine(to: CGPoint(x: 84, y: 54))
                p.addLine(to: CGPoint(x: 82, y: 58))
                p.addLine(to: CGPoint(x: 78, y: 58))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x1A3148))
            Circle()
                .fill(Color(hex: 0xD97757))
                .frame(width: 6)
                .offset(x: 0, y: 48 - 80)
        }
        .offset(x: -80, y: -80)
    }
}

struct SlimeHimStage5: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .him)
            Leaf(cx: 46, cy: 38, rx: 18, ry: 16, rotation: -15)
            Leaf(cx: 114, cy: 38, rx: 18, ry: 16, rotation: 15)
            Leaf(cx: 80, cy: 22, rx: 20, ry: 15)
            SlimeBody(palette: .him)
            ArmNub(palette: .him, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .him, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            Group {
                Leaf(cx: 56, cy: 40, rx: 13, ry: 12)
                Leaf(cx: 70, cy: 32, rx: 12, ry: 11)
                Leaf(cx: 82, cy: 30, rx: 13, ry: 12)
                Leaf(cx: 96, cy: 32, rx: 12, ry: 11)
                Leaf(cx: 104, cy: 40, rx: 13, ry: 12)
                Leaf(cx: 62, cy: 22, rx: 10, ry: 9)
                Leaf(cx: 88, cy: 20, rx: 11, ry: 10)
            }
            // Amber flowers (Him palette)
            ForEach(0..<6, id: \.self) { i in
                let positions: [(CGFloat, CGFloat)] = [(50,32),(72,24),(92,22),(110,32),(64,38),(96,38)]
                flowerAt(cx: positions[i].0, cy: positions[i].1)
            }
            shades
            smirkMouth
            MiniStar(cx: 28, cy: 52, size: 3.5, color: Color(hex: 0xFFD166))
            MiniStar(cx: 132, cy: 56, size: 3.5, color: Color(hex: 0x4A8FC9))
        }
        .frame(width: 160, height: 160)
    }

    private func flowerAt(cx: CGFloat, cy: CGFloat) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(Color(hex: 0xFFE899))
                    .frame(width: 5, height: 7)
                    .offset(y: -3)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(Color(hex: 0xD97757))
                .frame(width: 3.6)
        }
        .offset(x: cx - 80, y: cy - 80)
    }

    private var shades: some View {
        ZStack {
            // Lens bar
            Path { p in
                p.move(to: CGPoint(x: 58, y: 86))
                p.addLine(to: CGPoint(x: 102, y: 86))
            }
            .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 1.5))
            // Left lens
            Path { p in
                p.move(to: CGPoint(x: 60, y: 86))
                p.addQuadCurve(to: CGPoint(x: 78, y: 86), control: CGPoint(x: 62, y: 102))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x1A0F08))
            // Right lens
            Path { p in
                p.move(to: CGPoint(x: 100, y: 86))
                p.addQuadCurve(to: CGPoint(x: 82, y: 86), control: CGPoint(x: 98, y: 102))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x1A0F08))
            // Lens highlights
            Ellipse().fill(Color(hex: 0x4A6A88).opacity(0.5)).frame(width: 8, height: 5).offset(x: 66 - 80, y: 92 - 80)
            Ellipse().fill(Color(hex: 0x4A6A88).opacity(0.5)).frame(width: 8, height: 5).offset(x: 94 - 80, y: 92 - 80)
        }
        .offset(x: -80, y: -80)
    }

    private var smirkMouth: some View {
        Path { p in
            p.move(to: CGPoint(x: 74, y: 108))
            p.addQuadCurve(to: CGPoint(x: 88, y: 104), control: CGPoint(x: 79, y: 112))
        }
        .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .offset(x: -80, y: -80)
    }
}

struct SlimeHimStage6: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x3F6A8F).opacity(0.12))
                .frame(width: 124, height: 124)
                .offset(y: 60 - 80)
            DioramaBase(palette: .him)
            Leaf(cx: 40, cy: 36, rx: 22, ry: 18, rotation: -10)
            Leaf(cx: 120, cy: 36, rx: 22, ry: 18, rotation: 10)
            Leaf(cx: 80, cy: 14, rx: 26, ry: 14)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x8B5A30))
                .frame(width: 8, height: 24)
                .offset(y: 36 - 80)
            SlimeBody(palette: .him)
            ArmNub(palette: .him, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .him, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
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
            // Amber fruit (Him palette)
            ForEach(0..<5, id: \.self) { i in
                let positions: [(CGFloat, CGFloat)] = [(50,34),(108,32),(70,40),(94,38),(80,44)]
                fruit(cx: positions[i].0, cy: positions[i].1)
            }
            wateringCan
            FaceHim(cy: 92, eyeGap: 22, eyeR: 6)
            MiniStar(cx: 20, cy: 46, size: 4, color: Color(hex: 0xFFD166))
        }
        .frame(width: 160, height: 160)
    }

    private func fruit(cx: CGFloat, cy: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xD97757))
                .frame(width: 6.8)
            Ellipse().fill(Color(hex: 0xF5B896)).frame(width: 2, height: 2.6).offset(x: -1, y: -1)
            Path { p in
                p.move(to: CGPoint(x: 0, y: -3))
                p.addLine(to: CGPoint(x: 0, y: -5))
            }
            .stroke(Color(hex: 0x3A2510), style: StrokeStyle(lineWidth: 0.8))
        }
        .offset(x: cx - 80, y: cy - 80)
    }

    private var wateringCan: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.25)).frame(width: 28, height: 5).offset(y: 4)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x8FA8B8))
                .frame(width: 18, height: 12)
                .offset(y: 0)
            Rectangle()
                .fill(Color(hex: 0xA8C0D0))
                .frame(width: 18, height: 3)
                .offset(y: -4.5)
            // Spout
            Path { p in
                p.move(to: CGPoint(x: 9, y: -4))
                p.addLine(to: CGPoint(x: 16, y: -2))
                p.addLine(to: CGPoint(x: 16, y: 2))
                p.addLine(to: CGPoint(x: 9, y: 4))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x8FA8B8))
            // Handle
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: 0x6A8090))
                .frame(width: 3, height: 8)
                .offset(x: -7, y: -8)
        }
        .frame(width: 30, height: 16)
        .offset(x: 40 - 80, y: 112 - 80)
    }
}

struct SlimeHimStage: View {
    let stage: SlimeStage
    init(_ stage: SlimeStage) { self.stage = stage }

    @ViewBuilder
    var body: some View {
        switch stage {
        case .seedling:   SlimeHimStage1()
        case .sprout:     SlimeHimStage2()
        case .grass:      SlimeHimStage3()
        case .leafy:      SlimeHimStage4()
        case .flowering:  SlimeHimStage5()
        case .bonsai:     SlimeHimStage6()
        }
    }
}
