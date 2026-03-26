import SwiftUI

struct NoiseOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if UIImage(named: "noise-texture") != nil {
            Image("noise-texture")
                .resizable()
                .opacity(0.04)
                .blendMode(.overlay)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        } else {
            NoiseCanvas()
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
    }
}

private struct NoiseCanvas: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<3000 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.02...0.06)
                context.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .drawingGroup()
    }
}
