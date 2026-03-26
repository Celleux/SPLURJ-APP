import SwiftUI
import SwiftData

struct UrgeSurfView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var characterVM = CharacterViewModel()
    var siriTriggered: Bool = false

    @State private var isRunning = false
    @State private var isCompleted = false
    @State private var timerSeconds: Int = 0
    @State private var breathScale: CGFloat = 0.6
    @State private var breathPhase: String = "Tap to begin"
    @State private var waveOffset: CGFloat = 0
    @State private var timerTask: Task<Void, Never>?

    private var profile: UserProfile? { profiles.first }

    private var guidanceMessage: String {
        switch timerSeconds {
        case 0..<30: "Close your eyes"
        case 30..<120: "Focus on the sensation"
        case 120..<300: "Your breath is your anchor"
        case 300..<480: "Watch the wave"
        default: "You did it!"
        }
    }

    private var waveProgress: Double {
        min(1.0, Double(timerSeconds) / 720.0)
    }

    private var waveColor: Color {
        let t = waveProgress
        return Color(
            red: 1.0 * (1 - t),
            green: 0.3 + 0.45 * t,
            blue: 0.2 + 0.45 * t
        )
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if siriTriggered {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.teal)
                        Text("Siri detected an urge — let's ride it out")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.teal)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Theme.teal.opacity(0.1), in: .capsule)
                    .padding(.top, 8)
                }
                header
                Spacer()
                breathingCircles
                Spacer()
                sineWave
                phaseGuidance
                Spacer()
                bottomAction
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        HStack {
            Button("Close") { stopAndDismiss() }
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            VStack(spacing: 2) {
                Text(formatTime(timerSeconds))
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.default, value: timerSeconds)
                Text("Urge Surf")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Circle()
                .fill(.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.top, 16)
    }

    private var breathingCircles: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Theme.teal.opacity(0.06 + Double(i) * 0.03))
                    .frame(width: CGFloat(200 - i * 30), height: CGFloat(200 - i * 30))
                    .scaleEffect(breathScale + CGFloat(i) * 0.02)
            }

            Circle()
                .strokeBorder(Theme.teal.opacity(0.4), lineWidth: 2)
                .frame(width: 200, height: 200)
                .scaleEffect(breathScale)

            VStack(spacing: 8) {
                Text(breathPhase)
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.teal)
                    .animation(.easeInOut(duration: 0.3), value: breathPhase)

                if isRunning {
                    Text(guidanceMessage)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.5), value: guidanceMessage)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var sineWave: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let amplitude = size.height * 0.35 * (1.0 - waveProgress * 0.7)
            var path = Path()
            for x in stride(from: 0, to: size.width, by: 1) {
                let normalX = x / size.width
                let sineInput: Double = normalX * .pi * 4.0 + Double(waveOffset)
                let y: Double = midY + sin(sineInput) * amplitude
                if x == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(waveColor), lineWidth: 3)
        }
        .frame(height: 60)
        .padding(.vertical, 8)
    }

    private var phaseGuidance: some View {
        Text(guidanceMessage)
            .font(Typography.headingLarge)
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.5), value: guidanceMessage)
            .padding(.vertical, 8)
    }

    private var bottomAction: some View {
        Group {
            if isCompleted {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.displayLarge)
                        .foregroundStyle(Theme.accentGreen)

                    Text("Session Complete")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text("+75 XP")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.gold)

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                Button {
                    if !isRunning { startSession() }
                } label: {
                    Text(isRunning ? "Breathe with the circles..." : "Start Urge Surf")
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
            }
        }
    }

    private func startSession() {
        isRunning = true
        timerSeconds = 0
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timerSeconds += 1

                let cyclePosition = timerSeconds % 12
                if cyclePosition == 0 {
                    breathPhase = "Breathe in..."
                    withAnimation(.easeInOut(duration: 4)) { breathScale = 1.0 }
                } else if cyclePosition == 4 {
                    breathPhase = "Hold..."
                } else if cyclePosition == 8 {
                    breathPhase = "Breathe out..."
                    withAnimation(.easeInOut(duration: 4)) { breathScale = 0.6 }
                }

                withAnimation(.linear(duration: 1)) {
                    waveOffset += 0.3
                }

                if timerSeconds >= 720 {
                    completeSession()
                    return
                }
            }
        }
    }

    private func completeSession() {
        timerTask?.cancel()
        isRunning = false

        let session = UrgeSurfSession(durationSeconds: timerSeconds)
        modelContext.insert(session)

        if let profile {
            characterVM.syncFromProfile(profile)
            characterVM.onUrgeSurf(profile: profile)
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isCompleted = true
        }
    }

    private func stopAndDismiss() {
        timerTask?.cancel()
        if isRunning && timerSeconds >= 60 {
            let session = UrgeSurfSession(durationSeconds: timerSeconds)
            modelContext.insert(session)
            if let profile {
                characterVM.syncFromProfile(profile)
                characterVM.onUrgeSurf(profile: profile)
            }
        }
        dismiss()
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
