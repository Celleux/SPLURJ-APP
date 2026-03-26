import SwiftUI

struct CinematicSplashView: View {
    let onComplete: () -> Void
    @State private var phase: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: phase >= 2
                    ? [Theme.background, Color(hex: 0x0d1f15)]
                    : [Theme.background, Theme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: phase)

            VStack(spacing: 16) {
                Text("SPLURJ")
                    .font(Typography.displayMedium)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .tracking(8)
                    .opacity(phase >= 1 ? 1 : 0)
                    .scaleEffect(phase >= 2 ? 1.05 : 0.95)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: phase)

                Text("Your money. Unmasked.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.accent)
                    .opacity(phase >= 2 ? 1 : 0)
                    .offset(y: phase >= 2 ? 0 : 10)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: phase)
            }
            .opacity(phase >= 4 ? 0 : 1)
            .offset(y: phase >= 4 ? -30 : 0)
            .animation(.easeIn(duration: 0.4), value: phase)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                phase = 1
                try? await Task.sleep(for: .milliseconds(600))
                phase = 2
                try? await Task.sleep(for: .milliseconds(1600))
                phase = 4
                try? await Task.sleep(for: .milliseconds(400))
                onComplete()
            }
        }
    }
}
