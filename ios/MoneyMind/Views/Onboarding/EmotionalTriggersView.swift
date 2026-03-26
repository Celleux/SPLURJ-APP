import SwiftUI

struct EmotionalTriggersView: View {
    @Binding var dna: FinancialDNA
    @Binding var triggerRatings: [String: Double]
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var selectedTrigger: Int? = nil
    @State private var ratedCount: Int = 0

    private let triggers: [EmotionalTrigger] = [
        EmotionalTrigger(name: "Stress", icon: "brain.head.profile.fill", color: Theme.dangerLight, description: "When I'm stressed, I spend to cope", angle: -60),
        EmotionalTrigger(name: "Boredom", icon: "moon.fill", color: Theme.axisEmotional, description: "When I'm bored, I browse and buy", angle: 0),
        EmotionalTrigger(name: "Celebration", icon: "party.popper.fill", color: Theme.celebrationYellow, description: "Good news means treating myself", angle: 60),
        EmotionalTrigger(name: "Social Pressure", icon: "person.2.fill", color: Theme.axisRisk, description: "I spend to keep up with others", angle: 120),
        EmotionalTrigger(name: "Sadness", icon: "cloud.rain.fill", color: Theme.lavender, description: "Shopping is my comfort blanket", angle: 180),
        EmotionalTrigger(name: "FOMO", icon: "clock.badge.exclamationmark.fill", color: Theme.accent, description: "Limited time offers get me every time", angle: 240),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Emotional Triggers")
                .font(Typography.displayMedium)
                .foregroundStyle(.white)
                .opacity(appeared ? 1 : 0)
                .padding(.top, 24)

            Text("How much does each emotion\naffect your spending?")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)

            Spacer()

            if let selected = selectedTrigger {
                triggerDetailView(triggers[selected])
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
            } else {
                triggerWheel
                    .transition(.opacity)
            }

            Spacer()

            if selectedTrigger == nil && ratedCount >= triggers.count {
                Button(action: {
                    applyToDNA()
                    onComplete()
                }) {
                    Text("Continue")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if selectedTrigger == nil {
                Text("Tap each trigger to rate it")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.bottom, 48)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTrigger)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: ratedCount)
        .onAppear {
            for trigger in triggers {
                if triggerRatings[trigger.name] == nil {
                    triggerRatings[trigger.name] = 0.3
                }
            }
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var triggerWheel: some View {
        ZStack {
            Circle()
                .fill(Theme.surface)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .strokeBorder(Theme.elevated, lineWidth: 1)
                )

            VStack(spacing: 2) {
                Text("\(ratedCount)")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                Text("of 6")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }

            ForEach(Array(triggers.enumerated()), id: \.element.name) { index, trigger in
                let rating = triggerRatings[trigger.name] ?? 0.3
                let isRated = triggerRatings[trigger.name] != nil && ratedCount > 0 && hasBeenManuallyRated(trigger.name)
                let angleDeg = -90.0 + Double(index) * 60.0
                let angleRad = angleDeg * .pi / 180
                let radius: CGFloat = 120

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTrigger = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(trigger.color.opacity(0.1 + rating * 0.2))
                                .frame(width: 56, height: 56)
                                .shadow(color: trigger.color.opacity(rating * 0.4), radius: rating * 12)

                            Circle()
                                .strokeBorder(trigger.color.opacity(0.3 + rating * 0.4), lineWidth: 2)
                                .frame(width: 56, height: 56)

                            Image(systemName: trigger.icon)
                                .font(Typography.displaySmall)
                                .foregroundStyle(trigger.color)
                        }
                        .scaleEffect(0.8 + rating * 0.3)

                        Text(trigger.name)
                            .font(Typography.labelSmall)
                            .foregroundStyle(isRated ? trigger.color : Theme.textMuted)
                            .lineLimit(1)

                        if isRated {
                            Text("\(Int(rating * 100))%")
                                .font(Typography.labelSmall)
                                .foregroundStyle(trigger.color.opacity(0.7))
                        }
                    }
                }
                .offset(
                    x: cos(angleRad) * radius,
                    y: sin(angleRad) * radius
                )
                .opacity(appeared ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(index) * 0.08),
                    value: appeared
                )
            }
        }
        .frame(height: 340)
    }

    private func triggerDetailView(_ trigger: EmotionalTrigger) -> some View {
        let binding = Binding<Double>(
            get: { triggerRatings[trigger.name] ?? 0.3 },
            set: { triggerRatings[trigger.name] = $0 }
        )

        return VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(trigger.color.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .shadow(color: trigger.color.opacity(binding.wrappedValue * 0.5), radius: binding.wrappedValue * 20)

                Circle()
                    .strokeBorder(trigger.color.opacity(0.4), lineWidth: 2)
                    .frame(width: 88, height: 88)

                Image(systemName: trigger.icon)
                    .font(Typography.displayMedium)
                    .foregroundStyle(trigger.color)
            }
            .scaleEffect(0.9 + binding.wrappedValue * 0.2)
            .animation(.spring(response: 0.3), value: binding.wrappedValue)

            Text(trigger.name)
                .font(Typography.displaySmall)
                .foregroundStyle(.white)

            Text(trigger.description)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                HStack {
                    Text("Rarely")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Text("\(Int(binding.wrappedValue * 100))%")
                        .font(Typography.headingSmall)
                        .foregroundStyle(trigger.color)
                        .contentTransition(.numericText())
                    Spacer()
                    Text("Always")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.elevated)
                        .frame(height: 8)

                    GeometryReader { geo in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [trigger.color.opacity(0.6), trigger.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * max(0.05, binding.wrappedValue), height: 8)
                            .animation(.spring(response: 0.3), value: binding.wrappedValue)
                    }
                    .frame(height: 8)
                }

                Slider(value: binding, in: 0...1, step: 0.05)
                    .tint(trigger.color)
            }
            .padding(.horizontal, 40)

            Button {
                markAsRated(trigger.name)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTrigger = nil
                }
            } label: {
                Text("Save & Back")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(trigger.color, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .padding(.horizontal, 40)
            .sensoryFeedback(.impact(weight: .medium), trigger: binding.wrappedValue)
        }
        .padding(.vertical, 20)
    }

    @State private var manuallyRated: Set<String> = []

    private func hasBeenManuallyRated(_ name: String) -> Bool {
        manuallyRated.contains(name)
    }

    private func markAsRated(_ name: String) {
        if !manuallyRated.contains(name) {
            manuallyRated.insert(name)
            ratedCount = manuallyRated.count
        }
    }

    private func applyToDNA() {
        let stress = triggerRatings["Stress"] ?? 0.3
        let sadness = triggerRatings["Sadness"] ?? 0.3
        let fomo = triggerRatings["FOMO"] ?? 0.3
        let social = triggerRatings["Social Pressure"] ?? 0.3
        let boredom = triggerRatings["Boredom"] ?? 0.3

        let emotionalPush = (stress + sadness) / 2.0 * 0.2
        dna.emotionalAxis = max(0, min(1, dna.emotionalAxis - emotionalPush))

        let spendingPush = (fomo + social + boredom) / 3.0 * 0.15
        dna.spendingAxis = max(0, min(1, dna.spendingAxis + spendingPush))
    }
}

struct EmotionalTrigger {
    let name: String
    let icon: String
    let color: Color
    let description: String
    let angle: Double
}
