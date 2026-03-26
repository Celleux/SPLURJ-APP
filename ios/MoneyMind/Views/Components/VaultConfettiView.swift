import SwiftUI

struct VaultConfettiView: View {
    @State private var particles: [VaultConfettiParticle] = []
    @State private var isAnimating: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed > 0 else { continue }

                    let x = particle.startX * size.width + particle.velocityX * elapsed
                    let y = particle.startY + (particle.velocityY * elapsed) + (120 * elapsed * elapsed)
                    let opacity = max(0, 1.0 - elapsed / particle.lifetime)

                    guard opacity > 0, y < size.height + 20 else { continue }

                    context.opacity = opacity
                    let rect = CGRect(x: x - 4, y: y - 6, width: 8, height: 12)
                    context.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { spawnParticles() }
    }

    private func spawnParticles() {
        let colors: [Color] = [Theme.accent, Theme.gold, .white, Theme.lavender, Theme.axisEmotional]
        let now = Date().timeIntervalSinceReferenceDate
        particles = (0..<60).map { _ in
            VaultConfettiParticle(
                startX: .random(in: 0.05...0.95),
                startY: .random(in: -60...(-10)),
                velocityX: .random(in: -40...40),
                velocityY: .random(in: 80...220),
                color: colors.randomElement()!,
                startTime: now + .random(in: 0...0.3),
                lifetime: .random(in: 1.8...3.0)
            )
        }
    }
}

private struct VaultConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let color: Color
    let startTime: TimeInterval
    let lifetime: TimeInterval
}
