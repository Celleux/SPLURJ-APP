import SwiftUI

// MARK: - Slime Neutral — 6 evolution stages
//
// Accessory-free canonical form. Same silhouette and evolution arc as
// Her/Him, but:
//   - palette shifted warm neutral (bodyBase #F1E3C6)
//   - FaceNeutral: no lashes, no blush, soft symmetrical smile
//   - flowers at stage 5 swap to amber/cream (no pink)
//   - fruit at stage 6 is amber, no book or watering can

struct SlimeNeutralStage1: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .neutral)
            ArmNub(palette: .neutral, offset: CGPoint(x: -20, y: 22), rotation: -25, size: CGSize(width: 9, height: 5.5))
            ArmNub(palette: .neutral, offset: CGPoint(x: 20, y: 22), rotation: 25, size: CGSize(width: 9, height: 5.5))
            SlimeBody(palette: .neutral)
            FaceNeutral(cy: 78)
            SeedInHands().offset(x: 0, y: 28)
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeNeutralStage2: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .neutral)
            ArmNub(palette: .neutral, offset: CGPoint(x: -40, y: 16), rotation: -15, size: CGSize(width: 9, height: 5.5))
            ArmNub(palette: .neutral, offset: CGPoint(x: 40, y: 16), rotation: 15, size: CGSize(width: 9, height: 5.5))
            SlimeBody(palette: .neutral)
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
            FaceNeutral(cy: 84)
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeNeutralStage3: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .neutral)
            ArmNub(palette: .neutral, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .neutral, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            SlimeBody(palette: .neutral)
            grassTufts
            FaceNeutral(cy: 92)
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
}

struct SlimeNeutralStage4: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .neutral)
            Leaf(cx: 52, cy: 42, rx: 14, ry: 12, rotation: -20)
            Leaf(cx: 108, cy: 42, rx: 14, ry: 12, rotation: 20)
            Leaf(cx: 80, cy: 30, rx: 14, ry: 13)
            SlimeBody(palette: .neutral)
            ArmNub(palette: .neutral, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .neutral, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            Group {
                Leaf(cx: 60, cy: 46, rx: 11, ry: 10, rotation: -25)
                Leaf(cx: 72, cy: 40, rx: 10, ry: 9, rotation: -10)
                Leaf(cx: 80, cy: 38, rx: 11, ry: 10)
                Leaf(cx: 88, cy: 40, rx: 10, ry: 9, rotation: 10)
                Leaf(cx: 100, cy: 46, rx: 11, ry: 10, rotation: 25)
                Leaf(cx: 66, cy: 34, rx: 8, ry: 7, rotation: -18)
                Leaf(cx: 94, cy: 34, rx: 8, ry: 7, rotation: 18)
            }
            FaceNeutral(cy: 92, eyeGap: 22, eyeR: 6.5)
        }
        .frame(width: 160, height: 160)
    }
}

struct SlimeNeutralStage5: View {
    var body: some View {
        ZStack {
            DioramaBase(palette: .neutral)
            Leaf(cx: 46, cy: 38, rx: 18, ry: 16, rotation: -15)
            Leaf(cx: 114, cy: 38, rx: 18, ry: 16, rotation: 15)
            Leaf(cx: 80, cy: 22, rx: 20, ry: 15)
            SlimeBody(palette: .neutral)
            ArmNub(palette: .neutral, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .neutral, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
            Group {
                Leaf(cx: 56, cy: 40, rx: 13, ry: 12)
                Leaf(cx: 70, cy: 32, rx: 12, ry: 11)
                Leaf(cx: 82, cy: 30, rx: 13, ry: 12)
                Leaf(cx: 96, cy: 32, rx: 12, ry: 11)
                Leaf(cx: 104, cy: 40, rx: 13, ry: 12)
                Leaf(cx: 62, cy: 22, rx: 10, ry: 9)
                Leaf(cx: 88, cy: 20, rx: 11, ry: 10)
            }
            // Amber/cream flowers — no pink per Neutral spec
            let flowerColors: [(CGFloat, CGFloat, Color)] = [
                (50, 32, Color(hex: 0xFFE899)),
                (72, 24, Color(hex: 0xFFD166)),
                (92, 22, Color(hex: 0xFFE899)),
                (110, 32, Color(hex: 0xFFD166)),
                (64, 38, Color(hex: 0xFFE899)),
                (96, 38, Color(hex: 0xF5C26A))
            ]
            ForEach(0..<flowerColors.count, id: \.self) { i in
                flowerAt(cx: flowerColors[i].0, cy: flowerColors[i].1, color: flowerColors[i].2)
            }
            FaceNeutral(cy: 92, eyeGap: 22, eyeR: 6.5)
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
                .fill(Color(hex: 0xD38B2A))
                .frame(width: 3.6)
        }
        .offset(x: cx - 80, y: cy - 80)
    }
}

struct SlimeNeutralStage6: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xE8D79A).opacity(0.14))
                .frame(width: 124, height: 124)
                .offset(y: 60 - 80)
            DioramaBase(palette: .neutral)
            Leaf(cx: 40, cy: 36, rx: 22, ry: 18, rotation: -10)
            Leaf(cx: 120, cy: 36, rx: 22, ry: 18, rotation: 10)
            Leaf(cx: 80, cy: 14, rx: 26, ry: 14)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x8B5A30))
                .frame(width: 8, height: 24)
                .offset(y: 36 - 80)
            SlimeBody(palette: .neutral)
            ArmNub(palette: .neutral, offset: CGPoint(x: -42, y: 14), rotation: -10, size: CGSize(width: 10, height: 6))
            ArmNub(palette: .neutral, offset: CGPoint(x: 42, y: 14), rotation: 10, size: CGSize(width: 10, height: 6))
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
            ForEach(0..<5, id: \.self) { i in
                let positions: [(CGFloat, CGFloat)] = [(50,34),(108,32),(70,40),(94,38),(80,44)]
                fruit(cx: positions[i].0, cy: positions[i].1)
            }
            FaceNeutral(cy: 92, eyeGap: 22, eyeR: 6.5)
        }
        .frame(width: 160, height: 160)
    }

    private func fruit(cx: CGFloat, cy: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xE8A852))
                .frame(width: 6.8)
            Ellipse().fill(Color(hex: 0xFFDD99)).frame(width: 2, height: 2.6).offset(x: -1, y: -1)
            Path { p in
                p.move(to: CGPoint(x: 0, y: -3))
                p.addLine(to: CGPoint(x: 0, y: -5))
            }
            .stroke(Color(hex: 0x3A2510), style: StrokeStyle(lineWidth: 0.8))
        }
        .offset(x: cx - 80, y: cy - 80)
    }
}

struct SlimeNeutralStage: View {
    let stage: SlimeStage
    init(_ stage: SlimeStage) { self.stage = stage }

    @ViewBuilder
    var body: some View {
        switch stage {
        case .seedling:   SlimeNeutralStage1()
        case .sprout:     SlimeNeutralStage2()
        case .grass:      SlimeNeutralStage3()
        case .leafy:      SlimeNeutralStage4()
        case .flowering:  SlimeNeutralStage5()
        case .bonsai:     SlimeNeutralStage6()
        }
    }
}
