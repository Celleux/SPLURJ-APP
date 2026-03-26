import SwiftUI
import SwiftData

struct PGSIAssessmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var answers: [Int] = Array(repeating: -1, count: 9)
    @State private var currentQuestion: Int = 0
    @State private var showResult = false

    private var totalScore: Int {
        answers.filter { $0 >= 0 }.reduce(0, +)
    }

    private var allAnswered: Bool {
        answers.allSatisfy { $0 >= 0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(currentQuestion + 1), total: 9)
                    .tint(Theme.teal)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("Question \(currentQuestion + 1) of 9")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)

                Spacer()

                questionContent
                    .padding(.horizontal)

                Spacer()

                navigationButtons
                    .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("PGSI Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showResult) {
                resultSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var questionContent: some View {
        VStack(spacing: 24) {
            Text(PGSIQuestions.questions[currentQuestion])
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("In the past 12 months...")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 10) {
                ForEach(PGSIQuestions.answerOptions, id: \.value) { option in
                    let isSelected = answers[currentQuestion] == option.value
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            answers[currentQuestion] = option.value
                        }
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(Typography.bodyLarge)
                                .foregroundStyle(isSelected ? Theme.background : Theme.textPrimary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.background)
                            }
                        }
                        .padding(16)
                        .background(
                            isSelected ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.cardSurface),
                            in: .rect(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isSelected ? Color.clear : Theme.textSecondary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    .sensoryFeedback(.selection, trigger: isSelected)
                    .accessibilityLabel("\(option.label)\(isSelected ? ", selected" : "")")
                }
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentQuestion > 0 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        currentQuestion -= 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .splurjCard(.outlined)
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            }

            if currentQuestion < 8 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        currentQuestion += 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        answers[currentQuestion] >= 0 ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.textSecondary.opacity(0.3)),
                        in: .rect(cornerRadius: 12)
                    )
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .disabled(answers[currentQuestion] < 0)
            } else {
                Button {
                    submitAssessment()
                } label: {
                    Text("See Results")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            allAnswered ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.textSecondary.opacity(0.3)),
                            in: .rect(cornerRadius: 12)
                        )
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .disabled(!allAnswered)
                .sensoryFeedback(.success, trigger: showResult)
            }
        }
    }

    private var resultSheet: some View {
        let risk = PGSIQuestions.riskLevel(for: totalScore)
        let riskColor: Color = {
            switch risk.color {
            case "green": return Theme.accentGreen
            case "teal": return Theme.teal
            case "gold": return Theme.gold
            default: return Theme.emergency
            }
        }()

        return VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(riskColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                Text("\(totalScore)")
                    .font(Typography.displayMedium)
                    .foregroundStyle(riskColor)
            }

            Text(risk.label)
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)

            Text("Score: \(totalScore) out of 27")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            Text("Lower scores indicate fewer gambling-related problems. This is a screening tool, not a diagnosis.")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button {
                showResult = false
                dismiss()
            } label: {
                Text("Done")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(riskColor, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
        }
        .padding(24)
    }

    private func submitAssessment() {
        let finalAnswers = answers.map { max(0, $0) }
        let assessment = PGSIAssessment(answers: finalAnswers)
        modelContext.insert(assessment)
        showResult = true
    }
}

struct PGSITrendChart: View {
    let assessments: [PGSIAssessment]

    private var sortedAssessments: [PGSIAssessment] {
        assessments.sorted { $0.date < $1.date }
    }

    private var isImproving: Bool {
        guard sortedAssessments.count >= 2 else { return false }
        let recent = sortedAssessments.suffix(2)
        guard let latest = recent.last, let previous = recent.first else { return false }
        return latest.totalScore < previous.totalScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundStyle(isImproving ? Theme.accentGreen : Theme.gold)
                Text("Recovery Progress")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if isImproving {
                    Label("Improving", systemImage: "arrow.down.right")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accentGreen)
                }
            }

            if sortedAssessments.isEmpty {
                VStack(spacing: 8) {
                    Text("No assessments yet")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Take the PGSI monthly to track your progress")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                chartView
            }
        }
        .padding(20)
        .splurjCard(.elevated)
    }

    private var chartView: some View {
        let maxScore = 27.0
        let points = sortedAssessments

        return VStack(spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 100
                let count = points.count

                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(Array(points.enumerated()), id: \.offset) { index, assessment in
                            let barHeight = max(4, CGFloat(assessment.totalScore) / CGFloat(maxScore) * h)
                            let barColor = colorForScore(assessment.totalScore)
                            VStack(spacing: 4) {
                                Text("\(assessment.totalScore)")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(barColor)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor)
                                    .frame(height: barHeight)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: h + 20)

                    if count >= 2 {
                        Path { path in
                            for (index, assessment) in points.enumerated() {
                                let x = (CGFloat(index) + 0.5) / CGFloat(count) * w
                                let y = (h + 20) - (CGFloat(assessment.totalScore) / CGFloat(maxScore) * h)
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(isImproving ? Theme.accentGreen : Theme.gold, lineWidth: 2)
                    }
                }
            }
            .frame(height: 120)

            HStack {
                ForEach(Array(points.enumerated()), id: \.offset) { _, assessment in
                    Text(assessment.date, format: .dateTime.month(.narrow))
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 0: Theme.accentGreen
        case 1...2: Theme.teal
        case 3...7: Theme.gold
        default: Theme.emergency
        }
    }
}
