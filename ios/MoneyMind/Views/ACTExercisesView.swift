import SwiftUI
import SwiftData

struct ACTExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: ACTExerciseType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(Typography.displayMedium)
                            .foregroundStyle(Theme.teal)

                        Text("ACT Exercises")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Acceptance & Commitment Therapy exercises to build psychological flexibility.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)

                    ForEach(ACTExerciseType.allCases) { type in
                        Button {
                            selectedExercise = type
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: type.icon)
                                    .font(Typography.displaySmall)
                                    .foregroundStyle(Theme.teal)
                                    .frame(width: 48, height: 48)
                                    .background(Theme.teal.opacity(0.12), in: .rect(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(type.title)
                                        .font(Typography.headingSmall)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(type.subtitle)
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
                            }
                            .padding(16)
                            .splurjCard(.interactive)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(type.title)
                        .accessibilityHint(type.subtitle)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(item: $selectedExercise) { type in
                ACTExerciseFlowView(exerciseType: type)
            }
        }
    }
}

struct ACTExerciseFlowView: View {
    let exerciseType: ACTExerciseType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: Int = 0
    @State private var responses: [String] = []
    @State private var initialRating: Double = 5
    @State private var finalRating: Double = 5
    @State private var currentInput: String = ""
    @State private var valuesRatings: [Int] = Array(repeating: 5, count: 6)
    @State private var showTimer = false
    @State private var timerSeconds: Int = 120
    @State private var timerActive = false
    @State private var completed = false

    private var steps: [ACTExerciseStep] {
        switch exerciseType {
        case .valuesClarity: ACTContent.valuesSteps
        case .cognitiveDefusion: ACTContent.defusionSteps
        case .willingness: ACTContent.willingnessSteps
        }
    }

    private var isLastStep: Bool {
        currentStep >= steps.count - 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if completed {
                    completionView
                } else {
                    exerciseContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(exerciseType.title)
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var exerciseContent: some View {
        VStack(spacing: 0) {
            progressDots

            ScrollView {
                VStack(spacing: 24) {
                    let step = steps[currentStep]

                    Text(step.instruction)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.textPrimary)
                        .lineSpacing(4)
                        .padding(.top, 24)

                    if exerciseType == .valuesClarity && currentStep == 1 {
                        valuesRatingSection
                    } else if exerciseType == .willingness && currentStep == 1 {
                        ratingSlider(value: $initialRating, label: "Discomfort Level")
                    } else if exerciseType == .willingness && currentStep == 2 {
                        willingnessTimerSection
                    } else if exerciseType == .willingness && currentStep == 3 {
                        ratingSlider(value: $finalRating, label: "Discomfort Level Now")
                    }

                    if exerciseType == .cognitiveDefusion && currentStep == 1 {
                        if let lastResponse = responses.last {
                            defusionReframeSection(thought: lastResponse)
                        }
                    }

                    if let prompt = step.prompt, step.isReflection {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(prompt)
                                .font(Typography.bodyMedium)
                                .foregroundStyle(Theme.teal)

                            TextField("Your reflection...", text: $currentInput, axis: .vertical)
                                .lineLimit(3...6)
                                .font(Typography.bodyMedium)
                                .padding(14)
                                .splurjCard(.outlined)
                                .foregroundStyle(Theme.textPrimary)
                                .tint(Theme.teal)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }

            Spacer(minLength: 0)

            navigationButtons
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Theme.teal : Theme.cardSurface)
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.top, 12)
    }

    private var valuesRatingSection: some View {
        VStack(spacing: 14) {
            ForEach(Array(ACTContent.valuesAreas.enumerated()), id: \.offset) { index, area in
                HStack {
                    Text(area)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 160, alignment: .leading)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(1...10, id: \.self) { value in
                            Button {
                                valuesRatings[index] = value
                            } label: {
                                Circle()
                                    .fill(value <= valuesRatings[index] ? Theme.teal : Theme.cardSurface)
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(value)")
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Theme.cardSurface.opacity(0.5), in: .rect(cornerRadius: 16))
    }

    private func ratingSlider(value: Binding<Double>, label: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.teal)
            }

            Slider(value: value, in: 0...10, step: 1)
                .tint(Theme.teal)

            HStack {
                Text("None")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("Extreme")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private var willingnessTimerSection: some View {
        VStack(spacing: 20) {
            if !timerActive && timerSeconds == 120 {
                Button {
                    timerActive = true
                    startTimer()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Start 2-Minute Stillness")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(Theme.teal, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .sensoryFeedback(.impact(weight: .medium), trigger: timerActive)
            } else {
                ZStack {
                    Circle()
                        .stroke(Theme.cardSurface, lineWidth: 6)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: Double(120 - timerSeconds) / 120.0)
                        .stroke(Theme.teal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerSeconds)

                    Text(timerFormatted)
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                }

                if timerSeconds <= 0 {
                    Text("Well done. Take a moment to notice how you feel.")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.teal)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 20)
    }

    private var timerFormatted: String {
        let mins = timerSeconds / 60
        let secs = timerSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                if timerSeconds > 0 {
                    timerSeconds -= 1
                } else {
                    timer.invalidate()
                    timerActive = false
                }
            }
        }
    }

    private func defusionReframeSection(thought: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your thought:")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                Text("\"\(thought)\"")
                    .font(.subheadline.italic())
                    .foregroundStyle(Theme.textPrimary.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Now reframe:")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.teal)
                Text("\"I notice I'm having the thought that \(thought.lowercased())\"")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.teal.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("And again:")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.teal)
                Text("\"My mind is telling me that \(thought.lowercased())\"")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.teal.opacity(0.9))
            }
        }
        .padding(16)
        .background(Theme.teal.opacity(0.06), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.teal.opacity(0.15), lineWidth: 1)
        )
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .splurjCard(.outlined)
                }
                .buttonStyle(SplurjButtonStyle(variant: .ghost, size: .medium))
            }

            Spacer()

            Button {
                if !currentInput.isEmpty {
                    responses.append(currentInput)
                    currentInput = ""
                }

                if isLastStep {
                    saveExercise()
                    withAnimation(.spring(response: 0.4)) {
                        completed = true
                    }
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        currentStep += 1
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLastStep ? "Complete" : "Next")
                    Image(systemName: isLastStep ? "checkmark" : "chevron.right")
                }
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.background)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(Theme.teal, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .sensoryFeedback(.impact(weight: .light), trigger: currentStep)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Theme.background)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.teal.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.teal)
            }

            Text("Exercise Complete")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text("Great work. Every exercise strengthens your psychological flexibility.")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if exerciseType == .willingness {
                VStack(spacing: 8) {
                    Text("Before: \(Int(initialRating)) → After: \(Int(finalRating))")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.teal)

                    if finalRating < initialRating {
                        Text("Your discomfort decreased by sitting with it")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.accentGreen)
                    }
                }
                .padding(16)
                .splurjCard(.elevated)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.teal, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func saveExercise() {
        let exercise = ACTExercise(
            type: exerciseType,
            responses: responses,
            initialRating: Int(initialRating),
            finalRating: Int(finalRating)
        )
        modelContext.insert(exercise)
    }
}
