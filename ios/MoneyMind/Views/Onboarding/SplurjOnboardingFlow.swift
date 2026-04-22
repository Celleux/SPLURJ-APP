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
    @State private var goal: OnboardingGoal? = nil
    @State private var plan: PaywallPlan = .year
    var onComplete: (SplurjVariant, SplurjArchetype) -> Void

    enum Step { case splash, choose, goal, quiz, reveal, building, proof, paywall }

    var body: some View {
        ZStack {
            switch step {
            case .splash:  SplashScreen(onNext: advance)
            case .choose:  ChooseScreen(variant: $variant, onNext: advance, onBack: back)
            case .goal:    GoalScreen(variant: variant ?? .her, goal: $goal, onNext: advance, onBack: back)
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
            case .building:
                BuildingPlanScreen(
                    variant: variant ?? .her,
                    archetype: resolvedArchetype,
                    goal: goal,
                    onNext: advance
                )
            case .proof:
                SocialProofScreen(
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
        case .splash:   step = .choose
        case .choose:   step = .goal
        case .goal:     quizIndex = 0; answers = []; step = .quiz
        case .quiz:     step = .reveal
        case .reveal:   step = .building
        case .building: step = .proof
        case .proof:    step = .paywall
        case .paywall:  break
        }
    }

    private func back() {
        switch step {
        case .splash:   break
        case .choose:   step = .splash
        case .goal:     step = .choose
        case .quiz:     break
        case .reveal:   quizIndex = SplurjQuiz.questions.count - 1; answers = Array(answers.dropLast()); step = .quiz
        case .building: step = .reveal
        case .proof:    step = .building
        case .paywall:  step = .proof
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
            step = .goal
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
                    OnboardingProgress(step: 6, total: 7)
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

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            feature("All 6 evolution stages", detail: "seed \u{2192} bonsai")
                            feature("AI Money Coach", detail: "1-tap Pause & Breathe, HALT check, SOS")
                            feature("Unlimited Pacts", detail: "pool money with friends, hold each other honest")
                            feature("Apple Health HRV", detail: "catch stress spirals before they spend")
                        }

                        TrialTimelineView()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                }

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

// MARK: - 02b · Goal commitment (Noom-style micro-commitment)

nonisolated enum OnboardingGoal: String, CaseIterable, Identifiable, Sendable {
    case stopImpulse, saveFirst, payOffDebt, investMore, controlAnxiety

    var id: String { rawValue }
    var title: String {
        switch self {
        case .stopImpulse:    "Stop impulse spending"
        case .saveFirst:      "Build my first $1,000"
        case .payOffDebt:     "Pay down debt faster"
        case .investMore:     "Invest more consistently"
        case .controlAnxiety: "Calm my money anxiety"
        }
    }
    var sub: String {
        switch self {
        case .stopImpulse:    "Stop the 2am cart regret loop"
        case .saveFirst:      "An emergency buffer that actually holds"
        case .payOffDebt:     "Snowball it — with a plan that sticks"
        case .investMore:     "Automate so you never skip a month"
        case .controlAnxiety: "Sleep at night, spend with intent"
        }
    }
    var systemImage: String {
        switch self {
        case .stopImpulse:    "hand.raised.fill"
        case .saveFirst:      "banknote.fill"
        case .payOffDebt:     "chart.line.downtrend.xyaxis"
        case .investMore:     "chart.line.uptrend.xyaxis"
        case .controlAnxiety: "heart.fill"
        }
    }
}

private struct GoalScreen: View {
    let variant: SplurjVariant
    @Binding var goal: OnboardingGoal?
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        TerrariumBG {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    OnboardingBackButton(action: onBack)
                    Spacer()
                    OnboardingProgress(step: 1, total: 7)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28).padding(.top, 16)

                VStack(alignment: .leading, spacing: 14) {
                    Tag("02 · Your north star", color: Theme.honey)
                    Text("What brought you\nhere tonight?")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("We’ll tune your Splurji around this. You can change it anytime.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 28)
                .padding(.top, 36)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(OnboardingGoal.allCases) { g in
                            GoalRow(goal: g, selected: goal == g) { goal = g }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                }

                PrimaryCtaButton(title: "Continue", disabled: goal == nil) { onNext() }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
            }
        }
    }
}

private struct GoalRow: View {
    let goal: OnboardingGoal
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: goal.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.honey)
                    .frame(width: 38, height: 38)
                    .background(Theme.honey.opacity(0.15), in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Theme.honey.opacity(0.28), lineWidth: 1))
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(goal.sub)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? Theme.glow : Theme.textMuted)
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(selected ? Theme.glow.opacity(0.14) : Theme.cardTint,
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(selected ? Theme.glow : Theme.border, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }
}

// MARK: - 05 · Building your plan (personalization theater)

private struct BuildingPlanScreen: View {
    let variant: SplurjVariant
    let archetype: SplurjArchetype
    let goal: OnboardingGoal?
    var onNext: () -> Void

    @State private var progress: Double = 0
    @State private var checkedCount: Int = 0
    @State private var done: Bool = false

    private var steps: [String] {
        [
            "Mapping your \(archetype.dnaLabel.lowercased()) triggers",
            "Calibrating Splurji’s personality",
            "Planting your first savings seed",
            "Linking your goal: \(goal?.title ?? "calm money")",
            "Pre-loading your crisis toolkit"
        ]
    }

    var body: some View {
        TerrariumBG(withStump: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer().frame(width: 38)
                    Spacer()
                    OnboardingProgress(step: 4, total: 7)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28).padding(.top, 16)

                VStack(spacing: 10) {
                    Kicker("Personalising", tracking: 3.0)
                    Text(done ? "Your plan is ready." : "Building your plan…")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(done ? "Every detail calibrated to your \(archetype.dnaLabel.lowercased()) pattern." : "This usually takes a moment — we only do it once.")
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 28)
                }
                .padding(.top, 28)
                .frame(maxWidth: .infinity)

                ZStack {
                    Circle()
                        .stroke(Theme.border, lineWidth: 6)
                        .frame(width: 150, height: 150)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [Theme.honey, Theme.glow, Theme.honey],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 150, height: 150)
                        .shadow(color: Theme.honey.opacity(0.4), radius: 10)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, line in
                        HStack(spacing: 12) {
                            ZStack {
                                if idx < checkedCount {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(Theme.background)
                                        .frame(width: 20, height: 20)
                                        .background(Theme.glow, in: RoundedRectangle(cornerRadius: 6))
                                        .transition(.scale.combined(with: .opacity))
                                } else if idx == checkedCount {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(Theme.honey)
                                        .frame(width: 20, height: 20)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Theme.border, lineWidth: 1)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            Text(line)
                                .font(.system(size: 13, weight: idx <= checkedCount ? .semibold : .regular))
                                .foregroundStyle(idx <= checkedCount ? Theme.textPrimary : Theme.textMuted)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer(minLength: 0)

                if done {
                    PrimaryCtaButton(title: "See my plan", trailingSymbol: "\u{2192}") { onNext() }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 36)
                        .transition(.opacity.combined(with: .offset(y: 10)))
                } else {
                    Text("Takes ~4 seconds")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 48)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: done)
            .animation(.easeInOut(duration: 0.3), value: checkedCount)
        }
        .onAppear { runLoader() }
    }

    private func runLoader() {
        let total = steps.count
        for i in 0..<total {
            let delay = 0.7 + Double(i) * 0.65
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    progress = Double(i + 1) / Double(total)
                }
                checkedCount = i + 1
                if i + 1 == total {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        done = true
                    }
                }
            }
        }
    }
}

// MARK: - 06 · Social proof

private struct SocialProofScreen: View {
    let variant: SplurjVariant
    let archetype: SplurjArchetype
    var onNext: () -> Void
    var onBack: () -> Void

    private struct Testimonial: Identifiable {
        let id = UUID()
        let name: String
        let handle: String
        let quote: String
        let emoji: String
    }

    private let testimonials: [Testimonial] = [
        .init(name: "Maya", handle: "Riser · age 27", quote: "Saved $1,840 in my first two months. Splurji literally called me out at 11pm.", emoji: "\u{1F331}"),
        .init(name: "Dani", handle: "FOMO Filter · age 31", quote: "The Pause & Breathe button is worth the whole app. It broke my late-night Amazon loop.", emoji: "\u{1F33F}"),
        .init(name: "Alex", handle: "Stress Shield · age 24", quote: "First finance app that doesn’t shame me. My Splurji is now a full bonsai and so is my savings.", emoji: "\u{1F338}")
    ]

    var body: some View {
        TerrariumBG {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    OnboardingBackButton(action: onBack)
                    Spacer()
                    OnboardingProgress(step: 5, total: 7)
                    Spacer()
                    Spacer().frame(width: 38)
                }
                .padding(.horizontal, 28).padding(.top, 16)

                VStack(spacing: 10) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(Theme.honey)
                        }
                    }
                    Text("4.9 · 12,400+ ratings")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 22)

                VStack(alignment: .leading, spacing: 10) {
                    Tag("06 · You’re in good company", color: Theme.honey)
                    Text("50,000+ people quietly\ntook back their money.")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(testimonials) { t in
                            TestimonialCard(
                                name: t.name,
                                handle: t.handle,
                                quote: t.quote,
                                emoji: t.emoji
                            )
                        }
                        HStack(spacing: 16) {
                            ProofStatPill(number: "$18M", label: "Saved\nby users")
                            ProofStatPill(number: "92%", label: "Stop\nimpulse buys")
                            ProofStatPill(number: "4.9", label: "App Store\nrating")
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                }

                PrimaryCtaButton(title: "I want this too", trailingSymbol: "\u{2192}") { onNext() }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
            }
        }
    }
}

private struct TestimonialCard: View {
    let name: String
    let handle: String
    let quote: String
    let emoji: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Theme.cardTintHi, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text("·").foregroundStyle(Theme.textMuted)
                    Text(handle)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    HStack(spacing: 1) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.honey)
                        }
                    }
                }
                Text("“\(quote)”")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}

private struct ProofStatPill: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Theme.honey],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Trial timeline (used inside paywall)

private struct TrialTimelineView: View {
    var body: some View {
        VStack(spacing: 0) {
            timelineRow(
                icon: "lock.open.fill",
                title: "Today",
                sub: "Unlock everything. No charge.",
                color: Theme.glow,
                isLast: false
            )
            timelineRow(
                icon: "bell.badge.fill",
                title: "Day 5",
                sub: "We’ll remind you before the trial ends.",
                color: Theme.honey,
                isLast: false
            )
            timelineRow(
                icon: "sparkles",
                title: "Day 7",
                sub: "Trial ends. Cancel anytime before.",
                color: Theme.textSecondary,
                isLast: true
            )
        }
        .padding(14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }

    private func timelineRow(icon: String, title: String, sub: String, color: Color, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Theme.background)
                    .frame(width: 24, height: 24)
                    .background(color, in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(color.opacity(0.4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(sub)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, isLast ? 0 : 10)
            }
            Spacer()
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
