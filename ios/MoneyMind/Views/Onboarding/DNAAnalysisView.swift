import SwiftUI

struct DNAAnalysisView: View {
    let onComplete: () -> Void

    @State private var currentStep: Int = -1
    @State private var progressValue: Double = 0.0
    @State private var pulsing: Bool = false

    private let steps: [(text: String, duration: Double)] = [
        ("Mapping spending triggers", 1.0),
        ("Identifying risk patterns", 1.2),
        ("Building your recovery plan", 1.4),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.accent.opacity(0.15), Theme.accent.opacity(0.03), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulsing ? 1.15 : 1.0)

                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.pulse, options: .repeating, value: pulsing)
                }

                VStack(spacing: 10) {
                    Text("Analyzing your\nfinancial psychology")
                        .font(Typography.displaySmall)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("This takes a moment...")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }

                ProgressView(value: progressValue, total: 1.0)
                    .tint(Theme.accent)
                    .scaleEffect(y: 1.5)
                    .padding(.horizontal, 48)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        analysisRow(step.text, completed: index < currentStep, active: index == currentStep)
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            startSequence()
        }
    }

    private func analysisRow(_ text: String, completed: Bool, active: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                if completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .transition(.scale.combined(with: .opacity))
                } else if active {
                    ProgressView()
                        .tint(Theme.accent)
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                        .transition(.opacity)
                } else {
                    Circle()
                        .strokeBorder(Theme.border, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 24, height: 24)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: completed)
            .animation(.easeInOut(duration: 0.3), value: active)

            HStack(spacing: 6) {
                Text(text)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(completed || active ? Theme.textPrimary : Theme.textMuted)

                if completed {
                    Text("done")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .animation(.easeOut(duration: 0.3), value: completed)
        }
        .opacity(completed || active ? 1.0 : 0.4)
        .animation(.easeOut(duration: 0.3), value: active)
    }

    private func startSequence() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulsing = true
        }

        Task {
            for i in 0..<steps.count {
                withAnimation { currentStep = i }

                let stepDuration = steps[i].duration
                let tickCount = 20
                let tickDuration = stepDuration / Double(tickCount)
                let progressPerTick = (1.0 / Double(steps.count)) / Double(tickCount)

                for _ in 0..<tickCount {
                    try? await Task.sleep(for: .milliseconds(Int(tickDuration * 1000)))
                    withAnimation(.linear(duration: tickDuration)) {
                        progressValue = min(1.0, progressValue + progressPerTick)
                    }
                }

                withAnimation { currentStep = i + 1 }
                HapticManager.impact(.light)
            }

            try? await Task.sleep(for: .milliseconds(400))
            HapticManager.notification(.success)
            onComplete()
        }
    }
}
