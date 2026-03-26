import SwiftUI

struct SpendingPatternCardsView: View {
    @Binding var dna: FinancialDNA
    @Binding var cardAnswers: [String]
    let onComplete: () -> Void

    @State private var currentCard: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var hapticTrigger: Int = 0
    @State private var showSwipeHint: Bool = true
    @State private var swipeHintPhase: Bool = false

    private let scenarios = SpendingScenario.all

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<scenarios.count, id: \.self) { i in
                    Circle()
                        .fill(dotColor(for: i))
                        .frame(width: 8, height: 8)
                        .scaleEffect(i == currentCard ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3), value: currentCard)
                }
            }
            .padding(.top, 20)

            Text("\(currentCard + 1) of \(scenarios.count)")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textMuted)
                .tracking(1)
                .padding(.top, 10)

            Spacer()

            ZStack {
                if currentCard + 1 < scenarios.count {
                    ScenarioCardView(scenario: scenarios[currentCard + 1], response: nil)
                        .scaleEffect(0.92)
                        .opacity(0.3)
                }

                if currentCard < scenarios.count {
                    ScenarioCardView(
                        scenario: scenarios[currentCard],
                        response: dragDirection
                    )
                    .offset(dragOffset)
                    .rotationEffect(.degrees(cardRotation))
                    .gesture(cardDragGesture)
                    .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if showSwipeHint {
                swipeHandHint
                    .transition(.opacity)
                    .padding(.bottom, 12)
            }

            if currentCard < scenarios.count {
                choiceButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }

            swipeHints
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
    }

    private var dragDirection: SwipeDirection? {
        if dragOffset.width > 50 { return .right }
        if dragOffset.width < -50 { return .left }
        return nil
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentCard { return Theme.accent }
        if index == currentCard { return .white }
        return Theme.elevated
    }

    private var swipeHandHint: some View {
        VStack(spacing: 8) {
            Text("Swipe the card or tap a button")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.textMuted)

            HStack(spacing: 0) {
                Image(systemName: "chevron.left")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.axisEmotional)
                    .opacity(swipeHintPhase ? 0.3 : 0.8)
                    .offset(x: swipeHintPhase ? -6 : 0)

                Image(systemName: "chevron.left")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.axisEmotional)
                    .opacity(swipeHintPhase ? 0.6 : 0.3)
                    .offset(x: swipeHintPhase ? -3 : 0)

                Spacer().frame(width: 16)

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .scaleEffect(swipeHintPhase ? 1.15 : 1.0)

                    Image(systemName: "hand.draw.fill")
                        .font(Typography.displaySmall)
                        .foregroundStyle(.white.opacity(0.8))
                        .offset(x: swipeHintPhase ? 14 : -14)
                }

                Spacer().frame(width: 16)

                Image(systemName: "chevron.right")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.axisRisk)
                    .opacity(swipeHintPhase ? 0.6 : 0.3)
                    .offset(x: swipeHintPhase ? 3 : 0)

                Image(systemName: "chevron.right")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.axisRisk)
                    .opacity(swipeHintPhase ? 0.3 : 0.8)
                    .offset(x: swipeHintPhase ? 6 : 0)
            }
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: swipeHintPhase
            )
        }
        .onAppear {
            swipeHintPhase = true
        }
    }

    private var choiceButtons: some View {
        HStack(spacing: 12) {
            Button {
                triggerChoice(swipedRight: false)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(Typography.labelMedium)
                    Text(currentCard < scenarios.count ? scenarios[currentCard].leftShort : "")
                        .font(Typography.labelMedium)
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.axisEmotional)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.axisEmotional.opacity(0.12), in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.axisEmotional.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                triggerChoice(swipedRight: true)
            } label: {
                HStack(spacing: 6) {
                    Text(currentCard < scenarios.count ? scenarios[currentCard].rightShort : "")
                        .font(Typography.labelMedium)
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(Typography.labelMedium)
                }
                .foregroundStyle(Theme.axisRisk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.axisRisk.opacity(0.12), in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.axisRisk.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var swipeHints: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                Text(currentCard < scenarios.count ? scenarios[currentCard].leftLabel : "")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(Typography.labelSmall)
            .foregroundStyle(
                Theme.axisEmotional.opacity(
                    abs(dragOffset.width) > 50 && dragOffset.width < 0 ? 1.0 : 0.4
                )
            )

            Spacer()

            HStack(spacing: 6) {
                Text(currentCard < scenarios.count ? scenarios[currentCard].rightLabel : "")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: "arrow.right")
            }
            .font(Typography.labelSmall)
            .foregroundStyle(
                Theme.axisRisk.opacity(
                    abs(dragOffset.width) > 50 && dragOffset.width > 0 ? 1.0 : 0.4
                )
            )
        }
    }

    private var cardDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                cardRotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                if abs(value.translation.width) > 100 {
                    let swipedRight = value.translation.width > 0
                    recordAnswer(scenario: scenarios[currentCard], swipedRight: swipedRight)
                    hapticTrigger += 1

                    if showSwipeHint {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSwipeHint = false
                        }
                    }

                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = CGSize(
                            width: swipedRight ? 500 : -500,
                            height: value.translation.height
                        )
                    }

                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        dragOffset = .zero
                        cardRotation = 0
                        currentCard += 1
                        if currentCard >= scenarios.count {
                            onComplete()
                        }
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = .zero
                        cardRotation = 0
                    }
                }
            }
    }

    @State private var isAnimatingChoice = false

    private func triggerChoice(swipedRight: Bool) {
        guard !isAnimatingChoice, currentCard < scenarios.count else { return }
        isAnimatingChoice = true

        recordAnswer(scenario: scenarios[currentCard], swipedRight: swipedRight)
        hapticTrigger += 1

        if showSwipeHint {
            withAnimation(.easeOut(duration: 0.3)) {
                showSwipeHint = false
            }
        }

        withAnimation(.spring(response: 0.3)) {
            dragOffset = CGSize(width: swipedRight ? 500 : -500, height: 0)
            cardRotation = swipedRight ? 15 : -15
        }

        Task {
            try? await Task.sleep(for: .milliseconds(300))
            dragOffset = .zero
            cardRotation = 0
            currentCard += 1
            isAnimatingChoice = false
            if currentCard >= scenarios.count {
                onComplete()
            }
        }
    }

    private func recordAnswer(scenario: SpendingScenario, swipedRight: Bool) {
        let adjustment = swipedRight ? 0.15 : -0.15

        switch scenario.axis {
        case .spending:
            dna.spendingAxis = max(0, min(1, dna.spendingAxis + adjustment))
        case .emotional:
            dna.emotionalAxis = max(0, min(1, dna.emotionalAxis + adjustment))
        case .risk:
            dna.riskAxis = max(0, min(1, dna.riskAxis + adjustment))
        case .social:
            dna.socialAxis = max(0, min(1, dna.socialAxis + adjustment))
        }

        cardAnswers.append(swipedRight ? "right" : "left")
    }
}
