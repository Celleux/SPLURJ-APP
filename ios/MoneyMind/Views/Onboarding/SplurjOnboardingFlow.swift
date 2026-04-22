import SwiftUI
import SwiftData

// MARK: - Onboarding flow root
//
// 5 steps: Splash → Choose → Quiz (5 sub-questions) → Reveal → Paywall.
// Quiz drives SplurjQuiz.score → SplurjArchetype. Every copy point
// routes through the copy pack.

struct SplurjOnboardingFlow: View {
    @State private var step: Step = .splash
    @State private var variant: SplurjVariant? = nil
    @State private var answers: [QuizOption] = []
    @State private var quizIndex: Int = 0
    @State private var plan: PaywallPlan = .year
    var onComplete: (SplurjVariant, SplurjArchetype) -> Void

    enum Step { case splash, choose, quiz, reveal, paywall }

    var body: some View {
        ZStack {
            switch step {
            case .splash:  SplashScreen(onNext: advance)
            case .choose:  ChooseScreen(variant: $variant, onNext: advance, onBack: back)
            case .quiz:
                QuizScreen(
                    variant: variant ?? .her,
                    question: SplurjQuiz.questions[quizIndex],
                    questionIndex: quizIndex,
                    onAnswer: handleAnswer,
                    onBack: backFromQuiz
                )
            case .reveal:
                RevealScreen(
                    variant: variant ?? .her,
                    archetype: resolvedArchetype,
                    onNext: advance,
                    onBack: back
                )
            case .paywall:
                PaywallScreen(
                    variant: variant ?? .her,
                    archetype: resolvedArchetype,
                    plan: $plan,
                    onStart: completeFlow,
                    onBack: back
                )
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: quizIndex)
    }

    private var resolvedArchetype: SplurjArchetype {
        answers.isEmpty ? .builder : SplurjQuiz.score(answers)
    }

    private func advance() {
        switch step {
        case .splash:  step = .choose
        case .choose:  quizIndex = 0; answers = []; step = .quiz
        case .quiz:    step = .reveal   // shouldn't be called — quiz advances itself
        case .reveal:  step = .paywall
        case .paywall: break
        }
    }

    private func back() {
        switch step {
        case .splash:  break
        case .choose:  step = .splash
        case .quiz:    break
        case .reveal:  quizIndex = SplurjQuiz.questions.count - 1; answers = Array(answers.dropLast()); step = .quiz
        case .paywall: step = .reveal
        }
    }

    private func handleAnswer(_ option: QuizOption) {
        answers.append(option)
        if quizIndex + 1 < SplurjQuiz.questions.count {
            quizIndex += 1
        } else {
            step = .reveal
        }
    }

    private func backFromQuiz() {
        if quizIndex > 0 {
            quizIndex -= 1
            if !answers.isEmpty { answers.removeLast() }
        } else {
            step = .choose
        }
    }

    private func completeFlow() {
        guard let v = variant else { return }
        onComplete(v, resolvedArchetype)
    }
}

// MARK: - Paywall plan

enum PaywallPlan: String, CaseIterable { case month, year }

// MARK: - Shared chrome

private struct OnboardingBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 38, height: 38)
                .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

// MARK: - 01 · Splash

private struct SplashScreen: View {
    var onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        TerrariumBG(withStump: true) {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Kicker("The Finance Garden", tracking: 3.0)
                    SplurjWordmark(height: 72)
                        .shadow(color: Theme.glow.opacity(0.35), radius: 18, y: 0)
                    Text(copy(.taglineHero, for: .her))
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 24)

                Spacer(minLength: 16)

                SplurjMascot(variant: .her, stage: .leafy, size: 240)

                Spacer(minLength: 20)

                VStack(spacing: 12) {
                    PrimaryCtaButton(title: "Plant your first seed", trailingSymbol: "\u{2192}") {
                        onNext()
                    }
                    GhostLinkButton(title: "I already have an account") { }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - 02 · Choose

private struct ChooseScreen: View {
    @Binding var variant: SplurjVariant?
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        TerrariumBG {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    OnboardingBackButton(action: onBack)
                    Spacer()
                    OnboardingProgress(step: 1)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 14) {
                    Tag("01 · Choose your Splurj", color: Theme.honey)
                    Text("Who\u{2019}s growing with you?")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("You can change this later in settings. It shapes how Splurj greets you and how rewards look.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .padding(.top, 40)

                HStack(spacing: 10) {
                    ForEach(SplurjVariant.allCases) { v in
                        VariantCard(variant: v, selected: variant == v) {
                            variant = v
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)

                Spacer()

                disclosureCard
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)

                PrimaryCtaButton(title: "Continue", disabled: variant == nil) {
                    onNext()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
    }

    private var disclosureCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("ⓘ")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.honey)
                .frame(width: 26, height: 26)
                .background(Theme.honey.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            Text("Used only for mascot design. Not shared, not used for ads. ")
                .foregroundStyle(Theme.textSecondary)
            +
            Text("Change anytime")
                .foregroundStyle(Theme.glow)
        }
        .font(.system(size: 11))
        .padding(14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}

private struct VariantCard: View {
    let variant: SplurjVariant
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                SplurjMascot(variant: variant, stage: .leafy, size: 96)
                    .frame(width: 96, height: 96)
                Text(variant.label)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(selected ? variant.accent : Theme.textPrimary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if selected {
                        RadialGradient(
                            colors: [variant.accent.opacity(0.2), .clear],
                            center: UnitPoint(x: 0.5, y: 0.85),
                            startRadius: 0,
                            endRadius: 80
                        )
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    } else {
                        Color.white.opacity(0.03)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(selected ? variant.accent : Theme.border, lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? variant.accent.opacity(0.28) : .clear, radius: 10, y: 6)
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Theme.background)
                        .frame(width: 22, height: 22)
                        .background(variant.accent, in: Circle())
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 03 · Quiz (5 questions)

private struct QuizScreen: View {
    let variant: SplurjVariant
    let question: QuizQuestion
    let questionIndex: Int
    var onAnswer: (QuizOption) -> Void
    var onBack: () -> Void

    var body: some View {
        TerrariumBG {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    OnboardingBackButton(action: onBack)
                    Spacer()
                    OnboardingProgress(step: 2)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28).padding(.top, 16)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 14) {
                        Tag(question.kicker, color: Theme.honey)
                        Text(question.prompt)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    SplurjMascot(
                        variant: variant,
                        stage: .sprout,
                        size: 96
                    )
                    .frame(width: 100, height: 100)
                }
                .padding(.horizontal, 28)
                .padding(.top, 36)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(question.options) { opt in
                            QuizOptionRow(option: opt) { onAnswer(opt) }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                }

                Spacer(minLength: 20)
            }
        }
        .id("quiz-\(question.id)")
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(x: 40)),
            removal: .opacity.combined(with: .offset(x: -40))
        ))
    }

    private func stageForQuestion(_ q: Int) -> SlimeStage {
        // Mascot "grows" as the quiz progresses — visual reward loop
        [.seedling, .sprout, .grass, .leafy, .flowering][max(0, min(4, q - 1))]
    }
}

private struct QuizOptionRow: View {
    let option: QuizOption
    var onSelect: () -> Void
    @State private var tapped = false

    var body: some View {
        Button {
            tapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { onSelect() }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(option.archetype.pitch.accent)
                    .frame(width: 38, height: 38)
                    .background(option.archetype.pitch.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(option.archetype.pitch.accent.opacity(0.28), lineWidth: 1))
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(option.sub)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: tapped ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tapped ? Theme.glow : Theme.textMuted)
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(tapped ? Theme.glow.opacity(0.14) : Theme.cardTint,
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(tapped ? Theme.glow : Theme.border, lineWidth: tapped ? 2 : 1)
            )
            .scaleEffect(tapped ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: tapped)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: tapped)
    }
}

// MARK: - 04 · Reveal

private struct RevealScreen: View {
    let variant: SplurjVariant
    let archetype: SplurjArchetype
    var onNext: () -> Void
    var onBack: () -> Void
    @State private var appeared = false
    @State private var fireBurst = false

    var body: some View {
        TerrariumBG(withStump: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    OnboardingBackButton(action: onBack)
                    Spacer()
                    OnboardingProgress(step: 3)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28).padding(.top, 16)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [archetype.pitch.accent.opacity(0.4), .clear],
                                center: .center, startRadius: 0, endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                    SplurjMascot(
                        variant: variant,
                        stage: .seedling,
                        personality: personality(for: archetype),
                        size: 220
                    )
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                    CoinBurstOverlay(fire: $fireBurst, count: 12, color: archetype.pitch.accent)
                }
                .padding(.top, 20)

                VStack(alignment: .center, spacing: 10) {
                    Text(archetype.pitch.sigil)
                        .font(.system(size: 42))
                        .foregroundStyle(archetype.pitch.accent)
                    Kicker(archetype.pitch.kicker, color: Theme.honey, tracking: 3.0)
                    Text(archetype.pitch.name)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, archetype.pitch.accent],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Text(archetype.pitch.description)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 22)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.top, 14)

                HStack(spacing: 10) {
                    ForEach(archetype.pitch.stats, id: \.self) { stat in
                        Kicker(stat, color: Theme.textMuted, tracking: 1.8)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Theme.cardTint, in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)

                Spacer()

                PrimaryCtaButton(title: "Continue") { onNext() }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                fireBurst = true
            }
        }
    }

    private func personality(for a: SplurjArchetype) -> SplurjPersonality? {
        // Map archetype → personality tint for the mascot aura
        switch a {
        case .builder:    .builder
        case .empath:     .empath
        case .riser:      .hustler    // tint-only; name stays "Riser" everywhere user-facing
        case .minimalist: .minimalist
        case .generous:   .generous
        }
    }
}

// MARK: - 05 · Paywall

private struct PaywallScreen: View {
    let variant: SplurjVariant
    let archetype: SplurjArchetype
    @Binding var plan: PaywallPlan
    var onStart: () -> Void
    var onBack: () -> Void

    var body: some View {
        TerrariumBG {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    OnboardingBackButton(action: onBack)
                    Spacer()
                    OnboardingProgress(step: 4)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28).padding(.top, 16)

                SplurjMascot(
                    variant: variant,
                    stage: .flowering,
                    personality: personality(for: archetype),
                    size: 170
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 10) {
                    Tag("Splurji+ \u{00B7} Start free", color: Theme.honey)
                    Text("Help your Splurji\nreach full bloom.")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 10) {
                    feature("All 6 evolution stages", detail: "seed \u{2192} bonsai")
                    feature("AI Money Coach", detail: "1-tap Pause & Breathe, HALT check, SOS")
                    feature("Unlimited Pacts", detail: "pool money with friends, hold each other honest")
                    feature("Apple Health HRV", detail: "catch stress spirals before they spend")
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)

                HStack(spacing: 10) {
                    planCard(.month, title: "Monthly", price: "$9.99", sub: "/mo \u{00B7} cancel any time", badge: nil)
                    planCard(.year, title: "Yearly", price: "$59", sub: "$4.91/mo \u{00B7} save 50%", badge: "BEST")
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer(minLength: 0)

                VStack(spacing: 2) {
                    PrimaryCtaButton(title: "Start 7-day free trial") { onStart() }
                    HStack(spacing: 2) {
                        Text("Then $4.91/mo \u{00B7} cancel anytime \u{00B7} ")
                            .foregroundStyle(Theme.textMuted)
                        Text("Restore")
                            .foregroundStyle(Theme.textSecondary)
                            .underline()
                    }
                    .font(.system(size: 10))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
    }

    private func feature(_ title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Theme.background)
                .frame(width: 20, height: 20)
                .background(Theme.glow, in: RoundedRectangle(cornerRadius: 6))
            (Text(title).bold() + Text(" · ") + Text(detail).foregroundStyle(Theme.textSecondary))
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func planCard(_ id: PaywallPlan, title: String, price: String, sub: String, badge: String?) -> some View {
        let selected = plan == id
        return Button {
            plan = id
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Kicker(title, tracking: 1.0)
                Text(price)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                selected
                ? AnyShapeStyle(LinearGradient(colors: [Theme.honey.opacity(0.2), Theme.honey.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(Color.white.opacity(0.03))
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(selected ? Theme.honey : Theme.border, lineWidth: selected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: 0x1A1208))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Theme.honey, in: Capsule())
                        .offset(x: -14, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func personality(for a: SplurjArchetype) -> SplurjPersonality? {
        switch a {
        case .builder:    .builder
        case .empath:     .empath
        case .riser:      .hustler
        case .minimalist: .minimalist
        case .generous:   .generous
        }
    }
}

#if DEBUG
#Preview("Onboarding flow") {
    SplurjOnboardingFlow { v, a in
        print("Completed: variant=\(v) archetype=\(a)")
    }
}
#endif
