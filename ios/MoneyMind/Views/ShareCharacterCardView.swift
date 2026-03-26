import SwiftUI

struct ShareCharacterCardView: View {
    let stage: CharacterStage
    let level: Int
    let totalSaved: Double
    let streak: Int
    let dayCount: Int

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Text("Splurj")
                    .font(Typography.labelSmall)
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(3)
                    .textCase(.uppercase)

                CharacterView(stage: stage, reaction: .idle, level: level)
                    .scaleEffect(1.3)
                    .frame(height: 160)

                VStack(spacing: 8) {
                    Text(stage.name)
                        .font(Typography.displayMedium)
                        .foregroundStyle(.white)

                    Text("Level \(level)")
                        .font(Typography.headingLarge)
                        .foregroundStyle(stage.primaryColor)
                }

                HStack(spacing: 24) {
                    shareStatPill(value: "\(streak)", label: "Day Streak", icon: "flame.fill")
                    shareStatPill(
                        value: totalSaved.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                        label: "Saved",
                        icon: "dollarsign.circle.fill"
                    )
                    shareStatPill(value: "\(dayCount)", label: "Days", icon: "calendar")
                }

                Text("Building a healthier relationship with money")
                    .font(Typography.labelSmall)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

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
            .padding(.bottom, 40)
        }
        .frame(width: 390, height: 693)
        .background(
            ZStack {
                Theme.background

                RadialGradient(
                    colors: [stage.primaryColor.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 50,
                    endRadius: 350
                )

                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        .clear, stage.primaryColor.opacity(0.08), .clear,
                        stage.secondaryColor.opacity(0.06), .clear, stage.primaryColor.opacity(0.06),
                        .clear, stage.secondaryColor.opacity(0.08), .clear
                    ]
                )
            }
        )
        .clipShape(.rect(cornerRadius: 24))
    }

    private func shareStatPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(Typography.labelSmall)
                .foregroundStyle(stage.primaryColor.opacity(0.8))
            Text(value)
                .font(Typography.headingSmall)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    @MainActor
    func renderImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1920))
        let hostingController = UIHostingController(
            rootView: self
                .frame(width: 390, height: 693)
                .scaleEffect(1080.0 / 390.0, anchor: .topLeading)
                .frame(width: 1080, height: 1920)
        )
        hostingController.view.bounds = CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920))
        hostingController.view.backgroundColor = .clear
        hostingController.view.layoutIfNeeded()

        return renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct ShareCharacterButton: View {
    let stage: CharacterStage
    let level: Int
    let totalSaved: Double
    let streak: Int
    let dayCount: Int

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        Button {
            let card = ShareCharacterCardView(
                stage: stage,
                level: level,
                totalSaved: totalSaved,
                streak: streak,
                dayCount: dayCount
            )
            shareImage = card.renderImage()
            if shareImage != nil {
                showShareSheet = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(Typography.headingSmall)
                Text("Share My Character")
                    .font(Typography.headingSmall)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.cardSurface, in: .capsule)
            .overlay(
                Capsule()
                    .strokeBorder(stage.primaryColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(SplurjButtonStyle(variant: .secondary, size: .medium))
        .accessibilityLabel("Share my character card")
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
