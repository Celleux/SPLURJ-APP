import SwiftUI

struct MoneyMemoryView: View {
    @Binding var dna: FinancialDNA
    @Binding var memoryAnswers: [String]
    let onComplete: () -> Void

    @State private var currentPrompt: Int = 0
    @State private var selectedOption: String? = nil
    @State private var appeared = false

    private let prompts: [MemoryPrompt] = [
        MemoryPrompt(
            question: "Growing up, money was...",
            options: [
                MemoryOption(text: "Scarce — we counted every coin", icon: "drop.fill", adjustments: [.spending: -0.08, .risk: -0.08, .emotional: -0.1]),
                MemoryOption(text: "Present — comfortable but careful", icon: "leaf.fill", adjustments: [.risk: -0.04, .emotional: 0.05]),
                MemoryOption(text: "Invisible — never discussed", icon: "eye.slash.fill", adjustments: [.social: -0.1, .emotional: -0.06]),
                MemoryOption(text: "Abundant — never a worry", icon: "sparkles", adjustments: [.spending: 0.08, .risk: 0.08]),
            ],
            bgShift: Theme.background
        ),
        MemoryPrompt(
            question: "My parents taught me that money is...",
            options: [
                MemoryOption(text: "Something to fear running out of", icon: "exclamationmark.triangle.fill", adjustments: [.emotional: -0.1, .risk: -0.08]),
                MemoryOption(text: "A reward for hard work", icon: "hammer.fill", adjustments: [.emotional: 0.06, .spending: -0.05]),
                MemoryOption(text: "Not polite to talk about", icon: "speaker.slash.fill", adjustments: [.social: -0.12]),
                MemoryOption(text: "Something to share freely", icon: "gift.fill", adjustments: [.social: 0.1, .spending: 0.05]),
            ],
            bgShift: Color(hex: 0x0C1016)
        ),
        MemoryPrompt(
            question: "The first thing I remember buying with my own money was...",
            options: [
                MemoryOption(text: "Something practical I needed", icon: "wrench.and.screwdriver.fill", adjustments: [.spending: -0.06, .emotional: 0.05]),
                MemoryOption(text: "A gift for someone else", icon: "heart.fill", adjustments: [.social: 0.1]),
                MemoryOption(text: "Something exciting I wanted forever", icon: "star.fill", adjustments: [.spending: 0.08, .risk: 0.04]),
                MemoryOption(text: "I don't remember — it wasn't significant", icon: "questionmark.circle.fill", adjustments: [:]),
            ],
            bgShift: Color(hex: 0x0D1218)
        ),
        MemoryPrompt(
            question: "If I check my bank balance right now, I feel...",
            options: [
                MemoryOption(text: "Calm — I know roughly what's there", icon: "checkmark.seal.fill", adjustments: [.emotional: 0.1, .risk: 0.04]),
                MemoryOption(text: "Anxious — I'd rather not look", icon: "bolt.heart.fill", adjustments: [.emotional: -0.12, .risk: -0.06]),
                MemoryOption(text: "Curious — let's see what happened", icon: "magnifyingglass", adjustments: [.spending: 0.05, .emotional: 0.04]),
                MemoryOption(text: "Indifferent — it is what it is", icon: "minus.circle.fill", adjustments: [.emotional: 0.02]),
            ],
            bgShift: Color(hex: 0x0E141A)
        ),
    ]

    var body: some View {
        ZStack {
            prompts[currentPrompt].bgShift
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPrompt)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<prompts.count, id: \.self) { i in
                        Circle()
                            .fill(i < currentPrompt ? Theme.accent : i == currentPrompt ? .white : Theme.elevated)
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == currentPrompt ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPrompt)
                    }
                }
                .padding(.top, 24)

                Text("MONEY MEMORIES")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                    .tracking(3)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 28) {
                    Text(prompts[currentPrompt].question)
                        .font(Typography.displaySmall)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .id("question-\(currentPrompt)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    VStack(spacing: 10) {
                        ForEach(Array(prompts[currentPrompt].options.enumerated()), id: \.element.text) { index, option in
                            Button {
                                selectOption(option)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: option.icon)
                                        .font(Typography.headingLarge)
                                        .foregroundStyle(selectedOption == option.text ? Theme.accent : Theme.textSecondary)
                                        .frame(width: 32)

                                    Text(option.text)
                                        .font(Typography.bodyMedium)
                                        .foregroundStyle(selectedOption == option.text ? .white : Theme.textSecondary)
                                        .multilineTextAlignment(.leading)

                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedOption == option.text ? Theme.accent.opacity(0.12) : Theme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            selectedOption == option.text ? Theme.accent.opacity(0.4) : Theme.elevated.opacity(0.5),
                                            lineWidth: selectedOption == option.text ? 1.5 : 0.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.06),
                                value: appeared
                            )
                            .id("option-\(currentPrompt)-\(index)")
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: currentPrompt)
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private func selectOption(_ option: MemoryOption) {
        selectedOption = option.text
        memoryAnswers.append(option.text)

        for (axis, adjustment) in option.adjustments {
            switch axis {
            case .spending:
                dna.spendingAxis = max(0, min(1, dna.spendingAxis + adjustment))
            case .emotional:
                dna.emotionalAxis = max(0, min(1, dna.emotionalAxis + adjustment))
            case .risk:
                dna.riskAxis = max(0, min(1, dna.riskAxis + adjustment))
            case .social:
                dna.socialAxis = max(0, min(1, dna.socialAxis + adjustment))
            }
        }

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            if currentPrompt + 1 < prompts.count {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    selectedOption = nil
                    currentPrompt += 1
                }
            } else {
                onComplete()
            }
        }
    }
}

struct MemoryPrompt {
    let question: String
    let options: [MemoryOption]
    let bgShift: Color
}

struct MemoryOption {
    let text: String
    let icon: String
    let adjustments: [DNAAxis: Double]
}
