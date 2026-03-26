import SwiftUI

struct UrgeSurfSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var breathPhase: BreathPhase = .idle
    @State private var circleScale: CGFloat = 0.6
    @State private var timerSeconds: Int = 0
    @State private var isRunning = false

    nonisolated enum BreathPhase: String, Sendable {
        case idle = "Tap to start"
        case breatheIn = "Breathe in..."
        case hold = "Hold..."
        case breatheOut = "Breathe out..."
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Text("Urge Surfing")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.textPrimary)

                    Text("The urge is a wave. It will pass.\nBreathe through it.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    Circle()
                        .fill(Theme.teal.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)

                    Circle()
                        .strokeBorder(Theme.teal.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)

                    VStack(spacing: 8) {
                        Text(breathPhase.rawValue)
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.teal)

                        if isRunning {
                            Text("\(timerSeconds)s")
                                .font(Typography.displayMedium)
                                .foregroundStyle(Theme.textPrimary)
                                .contentTransition(.numericText())
                        }
                    }
                }

                Button {
                    if !isRunning { startBreathing() }
                } label: {
                    Text(isRunning ? "Keep going..." : "Start Breathing")
                        .font(Typography.headingMedium)
                        .foregroundStyle(isRunning ? Theme.textSecondary : Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isRunning ? AnyShapeStyle(Theme.cardSurface) : AnyShapeStyle(Theme.accentGradient),
                            in: .rect(cornerRadius: 12)
                        )
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .disabled(isRunning)
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accentGreen)
                }
            }
        }
    }

    private func startBreathing() {
        isRunning = true
        timerSeconds = 0
        runBreathCycle()
    }

    private func runBreathCycle() {
        Task {
            for _ in 0..<3 {
                breathPhase = .breatheIn
                withAnimation(.easeInOut(duration: 4)) { circleScale = 1.0 }
                for _ in 0..<4 {
                    try? await Task.sleep(for: .seconds(1))
                    timerSeconds += 1
                }

                breathPhase = .hold
                for _ in 0..<4 {
                    try? await Task.sleep(for: .seconds(1))
                    timerSeconds += 1
                }

                breathPhase = .breatheOut
                withAnimation(.easeInOut(duration: 4)) { circleScale = 0.6 }
                for _ in 0..<4 {
                    try? await Task.sleep(for: .seconds(1))
                    timerSeconds += 1
                }
            }
            breathPhase = .idle
            isRunning = false
        }
    }
}
