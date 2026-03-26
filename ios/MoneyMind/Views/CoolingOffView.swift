import SwiftUI
import SwiftData
import ActivityKit

struct CoolingOffView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CoolingOffSession.startDate, order: .reverse) private var sessions: [CoolingOffSession]

    @State private var selectedDuration: Int?
    @State private var showConfirmCancel = false
    @State private var quoteIndex: Int = 0
    @State private var timerTick: Int = 0
    @State private var timerTask: Task<Void, Never>?

    private var activeSession: CoolingOffSession? {
        sessions.first(where: { $0.isActive })
    }

    private let durations: [(String, Int)] = [
        ("10 min", 600),
        ("30 min", 1800),
        ("1 hour", 3600),
        ("4 hours", 14400),
        ("24 hours", 86400),
        ("72 hours", 259200)
    ]

    private let quotes: [String] = [
        "This urge is temporary. You are permanent.",
        "Every minute you wait is a victory.",
        "The impulse will pass whether you act on it or not.",
        "You've survived every difficult moment so far.",
        "Future you will be grateful for this patience.",
        "Discomfort is not an emergency.",
        "You are stronger than any craving.",
        "This moment of restraint builds your freedom.",
        "Breathe. The wave is passing.",
        "Willpower is a muscle. You're training it right now.",
        "What you resist today, you won't even remember next month.",
        "You're not missing out — you're gaining control."
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if let session = activeSession {
                    activeTimerView(session: session)
                } else {
                    durationPicker
                }
            }
        }
        .onAppear { startTickIfNeeded() }
        .onDisappear { timerTask?.cancel() }
        .alert("End Timer?", isPresented: $showConfirmCancel) {
            Button("Keep Going", role: .cancel) { }
            Button("End Timer", role: .destructive) { cancelActiveSession() }
        } message: {
            Text("Are you sure? You've been doing great holding on.")
        }
    }

    private var header: some View {
        HStack {
            Button("Close") { dismiss() }
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text("Cooling Off")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Circle().fill(.clear).frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var durationPicker: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "timer")
                .font(Typography.displayLarge)
                .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 1.0))

            VStack(spacing: 8) {
                Text("Set a Cooling Off Period")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)

                Text("Give yourself time before acting on an impulse.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(durations, id: \.1) { label, seconds in
                    Button {
                        startTimer(seconds: seconds)
                    } label: {
                        Text(label)
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .splurjCard(.interactive)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Set timer for \(label)")
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    private func activeTimerView(session: CoolingOffSession) -> some View {
        let remaining = max(0, session.remainingSeconds + (timerTick * 0 ))
        let total = session.durationSeconds
        let progress = 1.0 - (Double(remaining) / Double(total))

        return VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.cardSurface, lineWidth: 12)
                    .frame(width: 240, height: 240)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Color(red: 0.3, green: 0.5, blue: 1.0), Theme.teal],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerTick)

                VStack(spacing: 8) {
                    Text(formatCountdown(remaining))
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.default, value: remaining)

                    Text("remaining")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text(quotes[quoteIndex % quotes.count])
                .font(.subheadline.italic())
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .animation(.easeInOut(duration: 0.5), value: quoteIndex)
                .frame(minHeight: 50)

            Spacer()

            if remaining == 0 {
                completedView(session: session)
            } else {
                Button {
                    showConfirmCancel = true
                } label: {
                    Text("End Timer")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .splurjCard(.outlined)
                }
                .buttonStyle(SplurjButtonStyle(variant: .ghost, size: .medium))
            }

            Spacer().frame(height: 32)
        }
    }

    private func completedView(session: CoolingOffSession) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.displayLarge)
                .foregroundStyle(Theme.accentGreen)

            Text("You made it!")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)

            Text("The urge has passed. You're in control.")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            Button {
                session.completed = true
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
            .padding(.horizontal, 24)
        }
        .sensoryFeedback(.success, trigger: session.completed)
    }

    private func startTimer(seconds: Int) {
        let session = CoolingOffSession(durationSeconds: seconds)
        modelContext.insert(session)
        CoolingOffActivityManager.startActivity(
            endTime: session.endDate,
            triggerReason: "Cooling off timer"
        )
        startTickIfNeeded()
    }

    private func startTickIfNeeded() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timerTick += 1
                if timerTick % 30 == 0 {
                    quoteIndex += 1
                }
            }
        }
    }

    private func cancelActiveSession() {
        if let session = activeSession {
            session.completed = true
        }
        CoolingOffActivityManager.endAllActivities()
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
