import SwiftUI

enum ShareCardRenderer {
    static let cardSize = CGSize(width: 1080, height: 1920)
    static let viewSize = CGSize(width: 390, height: 693)
    static let scale = cardSize.width / viewSize.width

    @MainActor
    static func render<V: View>(_ view: V) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: cardSize)
        let scaled = view
            .frame(width: viewSize.width, height: viewSize.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: cardSize.width, height: cardSize.height)

        let hostingController = UIHostingController(rootView: scaled)
        hostingController.view.bounds = CGRect(origin: .zero, size: cardSize)
        hostingController.view.backgroundColor = .clear
        hostingController.view.layoutIfNeeded()

        return renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct CardWatermark: View {
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Theme.accentGreen)
                Text("splurj.app")
                    .font(Typography.labelSmall)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Text("Don't splurge. Splurj.")
                .font(Typography.labelSmall)
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}

struct CardBackground: View {
    var accentColor: Color = Theme.accentGreen
    var secondaryColor: Color = Theme.teal

    var body: some View {
        ZStack {
            Theme.background

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .clear, accentColor.opacity(0.1), .clear,
                    secondaryColor.opacity(0.08), .clear, accentColor.opacity(0.06),
                    .clear, secondaryColor.opacity(0.1), .clear
                ]
            )

            RadialGradient(
                colors: [accentColor.opacity(0.12), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 300
            )
        }
    }
}
