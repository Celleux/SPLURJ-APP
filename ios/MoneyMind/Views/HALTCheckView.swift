import SwiftUI
import SwiftData

struct HALTCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var characterVM = CharacterViewModel()

    @State private var currentCard: Int = 0
    @State private var scores: [Double] = [0, 0, 0, 0]
    @State private var contextNote: String = ""
    @State private var selectedNeed: String = ""
    @State private var showResults = false
    @State private var showRecommendation = false
    @State private var isCompleted = false

    private var profile: UserProfile? { profiles.first }

    private let categories = [
        HALTCategory(name: "Hungry", icon: "fork.knife", color: Color(red: 1.0, green: 0.6, blue: 0.2), description: "Physical hunger or craving"),
        HALTCategory(name: "Angry", icon: "flame.fill", color: Theme.emergency, description: "Frustration, irritation, or resentment"),
        HALTCategory(name: "Lonely", icon: "person.fill.questionmark", color: Color(red: 0.3, green: 0.5, blue: 1.0), description: "Isolation, disconnection, or boredom"),
        HALTCategory(name: "Tired", icon: "moon.fill", color: Color(red: 0.6, green: 0.3, blue: 0.9), description: "Physical or mental exhaustion")
    ]

    private let needs = ["Connection", "Escape", "Excitement", "Control", "Comfort"]

    private var highScoreCategory: String? {
        if let idx = scores.firstIndex(where: { $0 > 7 }) {
            return categories[idx].name
        }
        return nil
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if !showResults {
                    sliderContent
                } else {
                    resultsContent
                }
            }
        }
        .sensoryFeedback(.selection, trigger: currentCard)
    }

    private var header: some View {
        HStack {
            Button("Close") { dismiss() }
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text("HALT Check")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if !showResults {
                Text("\(currentCard + 1)/4")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Circle().fill(.clear).frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var sliderContent: some View {
        VStack(spacing: 24) {
            progressDots

            TabView(selection: $currentCard) {
                ForEach(0..<4, id: \.self) { index in
                    haltCard(index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 320)

            if currentCard < 3 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentCard += 1
                    }
                } label: {
                    Text("Next")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal, 24)
            } else {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showResults = true
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
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i == currentCard ? categories[i].color : Theme.textSecondary.opacity(0.3))
                    .frame(width: i == currentCard ? 10 : 6, height: i == currentCard ? 10 : 6)
                    .animation(.spring(response: 0.3), value: currentCard)
            }
        }
        .padding(.top, 16)
    }

    private func haltCard(index: Int) -> some View {
        let cat = categories[index]
        return VStack(spacing: 20) {
            Image(systemName: cat.icon)
                .font(Typography.displayMedium)
                .foregroundStyle(cat.color)
                .frame(width: 72, height: 72)
                .background(cat.color.opacity(0.12), in: .circle)

            Text(cat.name)
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text(cat.description)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 8) {
                HStack {
                    Text("Not at all")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("Extremely")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Slider(value: $scores[index], in: 0...10, step: 1)
                    .tint(cat.color)
                    .sensoryFeedback(.selection, trigger: Int(scores[index]))

                Text("\(Int(scores[index]))")
                    .font(Typography.displayMedium)
                    .foregroundStyle(cat.color)
                    .contentTransition(.numericText())
                    .animation(.default, value: Int(scores[index]))
            }
        }
        .padding(24)
        .splurjCard(.elevated)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(cat.name) level slider")
    }

    private var resultsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                resultsBars

                if let high = highScoreCategory {
                    recommendationCard(for: high)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                functionalAnalysis

                needPicker

                Button {
                    saveAndComplete()
                } label: {
                    Text("Complete Check-In")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .sensoryFeedback(.success, trigger: isCompleted)

                if isCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.accentGreen)
                        Text("+15 XP")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.gold)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
    }

    private var resultsBars: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { i in
                HStack(spacing: 12) {
                    Image(systemName: categories[i].icon)
                        .foregroundStyle(categories[i].color)
                        .frame(width: 24)

                    Text(categories[i].name)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.cardSurface)
                                .frame(height: 8)

                            Capsule()
                                .fill(categories[i].color)
                                .frame(width: geo.size.width * scores[i] / 10.0, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(scores[i]))")
                        .font(Typography.headingSmall)
                        .foregroundStyle(categories[i].color)
                        .frame(width: 24)
                }
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private func recommendationCard(for category: String) -> some View {
        let (message, icon) = recommendation(for: category)
        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.gold)
                .frame(width: 44, height: 44)
                .background(Theme.gold.opacity(0.12), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("High \(category) Detected")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text(message)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.gold.opacity(0.08), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func recommendation(for category: String) -> (String, String) {
        switch category {
        case "Hungry":
            return ("Have a small snack or meal before making any decisions. Low blood sugar impairs willpower.", "carrot.fill")
        case "Angry":
            return ("Try the Urge Surf breathing tool or take a 10-minute walk. Anger narrows focus and drives impulsive action.", "wind")
        case "Lonely":
            return ("Reach out to someone — a friend or family member. Connection reduces impulse urges.", "person.2.fill")
        case "Tired":
            return ("Rest first, decide later. Fatigue depletes self-control. Even a 20-minute nap helps.", "bed.double.fill")
        default:
            return ("Take care of this need before making financial decisions.", "heart.fill")
        }
    }

    private var functionalAnalysis: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What was happening before this urge?")
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textPrimary)

            TextField("Describe the situation...", text: $contextNote, axis: .vertical)
                .font(Typography.bodyMedium)
                .lineLimit(3...6)
                .padding(12)
                .splurjCard(.outlined)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var needPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What need am I trying to meet?")
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(needs, id: \.self) { need in
                    Button {
                        selectedNeed = need
                    } label: {
                        Text(need)
                            .font(Typography.labelSmall)
                            .foregroundStyle(selectedNeed == need ? Theme.background : Theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedNeed == need ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.cardSurface),
                                in: .rect(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    .sensoryFeedback(.selection, trigger: selectedNeed)
                    .accessibilityLabel(need)
                }
            }
        }
    }

    private func saveAndComplete() {
        let checkIn = HALTCheckIn(
            hungryScore: Int(scores[0]),
            angryScore: Int(scores[1]),
            lonelyScore: Int(scores[2]),
            tiredScore: Int(scores[3]),
            need: selectedNeed,
            contextNote: contextNote
        )
        modelContext.insert(checkIn)

        if let profile {
            characterVM.syncFromProfile(profile)
            characterVM.awardXP(.haltCheckIn, to: profile)
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isCompleted = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }
}

private struct HALTCategory {
    let name: String
    let icon: String
    let color: Color
    let description: String
}
