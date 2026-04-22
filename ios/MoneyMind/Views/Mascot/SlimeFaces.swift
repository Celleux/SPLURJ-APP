import SwiftUI

// MARK: - Face Him
//
// Masculine face: no lashes, no blush, smirk mouth. Kept structurally
// identical to FaceHer so blink / eye-offset / pupil tracking can share
// the same seams later.

struct FaceHim: View {
    var cy: CGFloat = 78
    var eyeGap: CGFloat = 22
    var eyeR: CGFloat = 5.5
    var blinkClose: Double = 0

    var body: some View {
        ZStack {
            eye(cx: 80 - eyeGap/2, cy: cy)
            eye(cx: 80 + eyeGap/2, cy: cy)
            // Thicker brow marks — flat strokes just above each eye
            brow(cx: 80 - eyeGap/2, cy: cy - eyeR - 3)
            brow(cx: 80 + eyeGap/2, cy: cy - eyeR - 3, flip: true)
            smirkMouth(cy: cy + 14)
        }
        .frame(width: 160, height: 160)
    }

    @ViewBuilder
    private func eye(cx: CGFloat, cy: CGFloat) -> some View {
        let clamped = max(0.05, 1.0 - blinkClose)
        Ellipse()
            .fill(Color(hex: 0x1A0F08))
            .frame(width: eyeR * 2, height: eyeR * 2.05 * clamped)
            .offset(x: cx - 80, y: cy - 80)
        Ellipse()
            .fill(Color.white.opacity(0.95))
            .frame(width: eyeR * 0.72, height: eyeR * 0.82 * clamped)
            .offset(x: cx - 80 + eyeR * 0.3, y: cy - 80 - eyeR * 0.35)
    }

    private func brow(cx: CGFloat, cy: CGFloat, flip: Bool = false) -> some View {
        Path { p in
            let len: CGFloat = 8
            p.move(to: CGPoint(x: -len/2, y: 0))
            p.addLine(to: CGPoint(x: len/2, y: flip ? -1 : 1))
        }
        .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        .frame(width: 12, height: 6)
        .offset(x: cx - 80, y: cy - 80)
    }

    private func smirkMouth(cy: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 74, y: 92))
            p.addQuadCurve(
                to: CGPoint(x: 86, y: 90),
                control: CGPoint(x: 80, y: 96)
            )
        }
        .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .offset(x: -80, y: cy - 92)
    }
}

// MARK: - Face Neutral
//
// No lashes, no blush, no accessories, soft symmetrical smile. The ungendered
// canonical face — Dave's "just the creature" spec from the brief.

struct FaceNeutral: View {
    var cy: CGFloat = 78
    var eyeGap: CGFloat = 21
    var eyeR: CGFloat = 6
    var blinkClose: Double = 0

    var body: some View {
        ZStack {
            eye(cx: 80 - eyeGap/2, cy: cy)
            eye(cx: 80 + eyeGap/2, cy: cy)
            softMouth(cy: cy + 14)
        }
        .frame(width: 160, height: 160)
    }

    @ViewBuilder
    private func eye(cx: CGFloat, cy: CGFloat) -> some View {
        let clamped = max(0.05, 1.0 - blinkClose)
        Ellipse()
            .fill(Color(hex: 0x1A0F08))
            .frame(width: eyeR * 2, height: eyeR * 2.05 * clamped)
            .offset(x: cx - 80, y: cy - 80)
        Ellipse()
            .fill(Color.white.opacity(0.95))
            .frame(width: eyeR * 0.76, height: eyeR * 0.86 * clamped)
            .offset(x: cx - 80 + eyeR * 0.3, y: cy - 80 - eyeR * 0.35)
    }

    private func softMouth(cy: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 76, y: 92))
            p.addQuadCurve(
                to: CGPoint(x: 84, y: 92),
                control: CGPoint(x: 80, y: 95)
            )
        }
        .stroke(Color(hex: 0x1A0F08), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .offset(x: -80, y: cy - 92)
    }
}
