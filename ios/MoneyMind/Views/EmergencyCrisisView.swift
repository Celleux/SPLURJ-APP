import SwiftUI

struct EmergencyCrisisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: CrisisSection = .hotlines
    @State private var groundingStep: Int = 0
    @State private var groundingInputs: [String] = Array(repeating: "", count: 5)
    @State private var phq1Score: Int = -1
    @State private var phq2Score: Int = -1
    @State private var showPHQResult = false

    nonisolated enum CrisisSection: String, CaseIterable, Identifiable, Sendable {
        case hotlines = "Crisis Lines"
        case grounding = "Grounding"
        case phq2 = "Quick Screen"

        nonisolated var id: String { rawValue }
    }

    private var regionHotlines: [CrisisHotline] {
        let region = Locale.current.region?.identifier ?? "US"
        switch region {
        case "GB":
            return [
                CrisisHotline(name: "GamCare", number: "0808 802 0133", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "Samaritans", number: "116 123", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "National Gambling Helpline", number: "0808 8020 133", available: "24/7", icon: "phone.fill")
            ]
        case "AU":
            return [
                CrisisHotline(name: "Gambling Help", number: "1800 858 858", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "Lifeline", number: "13 11 14", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "Beyond Blue", number: "1300 22 4636", available: "24/7", icon: "phone.fill")
            ]
        case "CA":
            return [
                CrisisHotline(name: "ConnexOntario", number: "1-866-531-2600", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "Crisis Services Canada", number: "1-833-456-4566", available: "24/7", icon: "phone.fill")
            ]
        default:
            return [
                CrisisHotline(name: "Suicide & Crisis Lifeline", number: "988", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "Gambling Helpline", number: "1-800-522-4700", available: "24/7, Free & Confidential", icon: "phone.fill"),
                CrisisHotline(name: "SAMHSA Helpline", number: "1-800-662-4357", available: "24/7, Free", icon: "phone.fill"),
                CrisisHotline(name: "Crisis Text Line", number: "Text HOME to 741741", available: "24/7", icon: "message.fill")
            ]
        }
    }

    private let groundingPrompts: [(Int, String, String)] = [
        (5, "things you can SEE", "eye.fill"),
        (4, "things you can TOUCH", "hand.raised.fill"),
        (3, "things you can HEAR", "ear.fill"),
        (2, "things you can SMELL", "nose.fill"),
        (1, "thing you can TASTE", "mouth.fill")
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                sectionPicker
                sectionContent
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Close") { dismiss() }
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }

            Image(systemName: "heart.fill")
                .font(Typography.displayMedium)
                .foregroundStyle(Theme.emergency)
                .symbolEffect(.pulse, options: .repeating)

            Text("You're Not Alone")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text("This moment will pass. Let's get through it together.")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(CrisisSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSection = section
                    }
                } label: {
                    Text(section.rawValue)
                        .font(Typography.labelSmall)
                        .foregroundStyle(selectedSection == section ? Theme.background : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedSection == section
                                ? AnyShapeStyle(Theme.emergency)
                                : AnyShapeStyle(Theme.cardSurface),
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedSection)
                .accessibilityLabel(section.rawValue)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .hotlines:
            hotlinesSection
        case .grounding:
            groundingSection
        case .phq2:
            phq2Section
        }
    }

    private var hotlinesSection: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(regionHotlines) { hotline in
                    Button {
                        callNumber(hotline.number)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: hotline.icon)
                                .font(Typography.headingLarge)
                                .foregroundStyle(Theme.emergency)
                                .frame(width: 44, height: 44)
                                .background(Theme.emergency.opacity(0.12), in: .rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(hotline.name)
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(hotline.number)
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.accentGreen)
                                Text(hotline.available)
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "phone.arrow.up.right.fill")
                                .foregroundStyle(Theme.accentGreen)
                        }
                        .padding(14)
                        .splurjCard(.interactive)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(hotline.name), \(hotline.number)")
                    .accessibilityHint("Tap to call")
                }

                Text("Remember: You've resisted before and you can do it again.")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
    }

    private var groundingSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("5-4-3-2-1 Grounding")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)

                Text("Focus on your senses to anchor yourself in the present moment.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                ForEach(0..<5, id: \.self) { i in
                    let prompt = groundingPrompts[i]
                    let isActive = i == groundingStep
                    let isDone = i < groundingStep

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(isDone ? Theme.accentGreen : (isActive ? Theme.gold : Theme.cardSurface))
                                    .frame(width: 36, height: 36)

                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(.white)
                                } else {
                                    Image(systemName: prompt.2)
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(isActive ? Theme.background : Theme.textSecondary)
                                }
                            }

                            Text("Name \(prompt.0) \(prompt.1)")
                                .font(.subheadline.weight(isActive ? .semibold : .regular))
                                .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                        }

                        if isActive {
                            TextField("Type here...", text: $groundingInputs[i])
                                .font(Typography.bodyMedium)
                                .padding(12)
                                .splurjCard(.outlined)
                                .foregroundStyle(Theme.textPrimary)
                                .transition(.opacity.combined(with: .move(edge: .top)))

                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    groundingStep += 1
                                }
                            } label: {
                                Text(i < 4 ? "Next" : "Done")
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Theme.accentGradient, in: .rect(cornerRadius: 10))
                            }
                            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .medium))
                            .sensoryFeedback(.impact(weight: .light), trigger: groundingStep)
                        }
                    }
                    .padding(14)
                    .background(
                        isActive ? Theme.cardSurface : Color.clear,
                        in: .rect(cornerRadius: 14)
                    )
                    .overlay(
                        isActive
                            ? RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
                            : nil
                    )
                }

                if groundingStep >= 5 {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Typography.displayMedium)
                            .foregroundStyle(Theme.accentGreen)

                        Text("You're grounded.")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Take a few more deep breaths. You're safe.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
    }

    private var phq2Section: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("PHQ-2 Quick Screen")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textPrimary)

                Text("Over the last 2 weeks, how often have you been bothered by:")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                phqQuestion(
                    text: "Little interest or pleasure in doing things?",
                    score: $phq1Score
                )

                phqQuestion(
                    text: "Feeling down, depressed, or hopeless?",
                    score: $phq2Score
                )

                if phq1Score >= 0 && phq2Score >= 0 {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            showPHQResult = true
                        }
                    } label: {
                        Text("See Results")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                }

                if showPHQResult {
                    phqResult
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
    }

    private func phqQuestion(text: String, score: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textPrimary)

            let options = ["Not at all", "Several days", "More than half", "Nearly every day"]
            ForEach(0..<4, id: \.self) { i in
                Button {
                    score.wrappedValue = i
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(score.wrappedValue == i ? Theme.teal : Theme.cardSurface)
                            .frame(width: 20, height: 20)
                            .overlay(
                                score.wrappedValue == i
                                    ? Circle().fill(.white).frame(width: 8, height: 8)
                                    : nil
                            )

                        Text(options[i])
                            .font(Typography.bodyMedium)
                            .foregroundStyle(score.wrappedValue == i ? Theme.textPrimary : Theme.textSecondary)

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: score.wrappedValue)
                .accessibilityLabel(options[i])
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private var phqResult: some View {
        let total = phq1Score + phq2Score
        let (message, color): (String, Color) = {
            if total >= 3 {
                return ("Your score suggests you may benefit from speaking with a mental health professional. This is not a diagnosis — just a starting point. You deserve support.", Theme.gold)
            } else {
                return ("Your score is in the low range. If you're still struggling, don't hesitate to reach out for support. There's no wrong time to ask for help.", Theme.accentGreen)
            }
        }()

        return VStack(spacing: 14) {
            HStack(spacing: 8) {
                Text("Score: \(total)/6")
                    .font(Typography.headingMedium)
                    .foregroundStyle(color)
            }

            Text(message)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Text("This is a screening tool, not a clinical assessment. Please consult a healthcare provider for evaluation.")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(color.opacity(0.08), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func callNumber(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }
}

private struct CrisisHotline: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    let available: String
    let icon: String
}
