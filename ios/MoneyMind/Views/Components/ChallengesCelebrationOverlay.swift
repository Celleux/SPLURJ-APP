import SwiftUI

struct ChallengesCelebrationOverlay: View {
    let message: String
    let particles: [ChallengeConfetti]
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            Canvas { context, size in
                for particle in particles {
                    let x = particle.x * size.width
                    let targetY = size.height * 1.2
                    let currentY = (particle.y * size.height) + (targetY * particlePhase)
                    let rotation = Angle.degrees(particle.rotation + particlePhase * 360)

                    context.opacity = max(0, 1.0 - particlePhase * 0.6)
                    context.translateBy(x: x, y: currentY)
                    context.rotate(by: rotation)
                    context.scaleBy(x: particle.scale, y: particle.scale)

                    let rect = CGRect(x: -4, y: -6, width: 8, height: 12)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )

                    context.scaleBy(x: 1 / particle.scale, y: 1 / particle.scale)
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -currentY)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.gold.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Theme.gold.opacity(0.2))
                        .frame(width: 72, height: 72)
                    Image(systemName: "trophy.fill")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.gold)
                }
                .scaleEffect(showContent ? 1 : 0.3)
                .opacity(showContent ? 1 : 0)

                Text(message)
                    .font(Typography.displaySmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Theme.gold, in: .capsule)
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 2.5)) {
                particlePhase = 1
            }
        }
        .sensoryFeedback(.success, trigger: showContent)
    }
}
