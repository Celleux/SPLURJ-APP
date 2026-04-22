import SwiftUI
import SwiftData

// MARK: - Onboarding flow root
//
// 5 screens: Splash → Choose → Quiz → Reveal → Paywall. Each screen
// pulls state from a single shared model so "back" preserves answers.
// Ships as a standalone flow — Chunk 5 decides whether to replace the
// existing OnboardingView or show this new flow for first-run users.

struct SplurjOnboardingFlow: View {
    @State private var step: Int = 0
    @State private var variant: SplurjVariant? = nil
    @State private var dnaAnswer: DnaAnswer? = nil
    @State private var plan: PaywallPlan = .year
    var onComplete: (SplurjVariant, DnaAnswer) -> Void

    var body: some View {
        ZStack {
            switch step {
            case 0: SplashScreen(onNext: advance)
            case 1: ChooseScreen(variant: $variant, onNext: advance, onBack: back)
            case 2: QuizScreen(variant: variant ?? .her, answer: $dnaAnswer, onNext: advance, onBack: back)
            case 3: RevealScreen(variant: variant ?? .her, answer: dnaAnswer ?? .stress, onNext: advance, onBack: back)
            default: PaywallScreen(variant: variant ?? .her, plan: $plan, onStart: completeFlow, onBack: back)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private func advance() { step = min(step + 1, 4) }
    private func back() { step = max(step - 1, 0) }

    private func completeFlow() {
        guard let v = variant, let a = dnaAnswer else { return }
        onComplete(v, a)
    }
}

// MARK: - Model bits

nonisolated enum DnaAnswer: String, CaseIterable, Sendable {
    case stress, social, reward, bored, other

    var label: String {
        switch self {
        case .stress: "Stress & bad days"
        case .social: "FOMO & social spirals"
        case .reward: "I-earned-it rewards"
        case .bored:  "Boredom & dopamine dips"
        case .other:  "Something else"
        }
    }

    var subtitle: String {
        switch self {
        case .stress: "HALT triggers · emotional spending"
        case .social: "Friends buying · late-night scrolling"
        case .reward: "Payday splurges · \u{201C}treat yourself\u{201D}"
        case .bored:  "Apps open · nothing to do"
        case .other:  "Tell Splurj what you notice"
        }
    }

    var emoji: String {
        switch self {
        case .stress: "\u{1F327}"     // 🌧
        case .social: "\u{1F440}"     // 👀
        case .reward: "\u{2728}"      // ✨
        case .bored:  "\u{1F300}"     // 🌀
        case .other:  "\u{1F331}"     // 🌱
        }
    }

    /// Headline revealed on step 4.
    var dnaLabel: String {
        switch self {
        case .stress: "Stress Shield"
        case .social: "FOMO Fighter"
        case .reward: "Reward Reframer"
        case .bored:  "Boredom Buster"
        case .other:  "Custom Track"
        }
    }
}

enum PaywallPlan: String, CaseIterable { case month, year }

// MARK: - Shared screen chrome

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
            GeometryReader { geo in
                ZStack {
                    VStack(spacing: 12) {
                        Kicker("The Finance Garden", tracking: 2.5)
                        Text("splurj")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: 0xC8F088)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        Text("A tiny creature that grows when you\nsave — and wilts when you splurge.")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 32)
                    }
                    .offset(y: -geo.size.height * 0.18)

                    SplurjMascot(variant: .her, stage: .leafy, size: 240)
                        .offset(y: geo.size.height * 0.05)

                    VStack(spacing: 10) {
                        PrimaryCtaButton(title: "Plant your first seed", trailingSymbol: "\u{2192}") {
                            onNext()
                        }
                        GhostLinkButton(title: "I already have an account") { }
                    }
                    .padding(.horizontal, 28)
                    .offset(y: geo.size.height * 0.38)
                }
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

// MARK: - 03 · DNA Quiz

private struct QuizScreen: View {
    let variant: SplurjVariant
    @Binding var answer: DnaAnswer?
    var onNext: () -> Void
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
                        Tag("02 · Splurge DNA", color: Theme.honey)
                        Text("When do you splurge most?")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    SplurjMascot(variant: variant, stage: .sprout, size: 96)
                        .frame(width: 100, height: 100)
                }
                .padding(.horizontal, 28)
                .padding(.top, 36)

                VStack(spacing: 8) {
                    ForEach(DnaAnswer.allCases, id: \.self) { option in
                        answerRow(option)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                Spacer()

                PrimaryCtaButton(title: "Continue", disabled: answer == nil) {
                    onNext()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
    }

    private func answerRow(_ option: DnaAnswer) -> some View {
        let selected = answer == option
        return Button {
            answer = option
        } label: {
            HStack(spacing: 12) {
                Text(option.emoji)
                    .font(.system(size: 20))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 1) {
                    Text(option.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(option.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Circle()
                    .strokeBorder(selected ? Theme.glow : Theme.textMuted.opacity(0.5), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(selected ? Theme.glow : .clear)
                            .frame(width: 22, height: 22)
                    )
                    .overlay {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Theme.background)
                        }
                    }
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(
                selected
                ? AnyShapeStyle(LinearGradient(colors: [Theme.glow.opacity(0.22), Theme.glow.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(Color.white.opacity(0.03))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Theme.glow : Theme.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 04 · Reveal

private struct RevealScreen: View {
    let variant: SplurjVariant
    let answer: DnaAnswer
    var onNext: () -> Void
    var onBack: () -> Void
    @State private var appeared = false

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

                // Aura + mascot
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.glow.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                    SplurjMascot(variant: variant, stage: .seedling, size: 220)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 20)

                VStack(alignment: .center, spacing: 10) {
                    Tag("Your Splurj is born", color: Theme.honey)
                    (
                        Text("Meet your ") + Text(answer.dnaLabel)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: 0xFFF4C4), Theme.honey],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    )
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)

                    Text(subcopy)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 22)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.top, 24)

                // Stats row
                HStack(spacing: 8) {
                    statPill(label: "LV", value: "01")
                    statPill(label: "STAGE", value: "Seed")
                    statPill(label: "DNA", value: answer.dnaLabel.components(separatedBy: " ").first ?? "DNA")
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

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
        }
    }

    private var subcopy: String {
        switch variant {
        case .her:     "She\u{2019}ll grow as you save, meditate, and hit pacts. She starts as a seedling."
        case .him:     "He\u{2019}ll grow as you save, meditate, and hit pacts. He starts as a seedling."
        case .neutral: "They\u{2019}ll grow as you save, meditate, and hit pacts. They start as a seedling."
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Theme.glow)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }
}

// MARK: - 05 · Paywall

private struct PaywallScreen: View {
    let variant: SplurjVariant
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

                SplurjMascot(variant: variant, stage: .flowering, size: 170)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 10) {
                    Tag("Splurj+ · Start free", color: Theme.honey)
                    Text("Help your Splurj\nreach full bloom.")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 10) {
                    feature("All 6 evolution stages", detail: "seed → bonsai")
                    feature("AI Money Coach", detail: "1-tap Pause & Breathe, HALT check, SOS")
                    feature("Unlimited Pacts", detail: "pool money with friends, hold each other honest")
                    feature("Apple Health HRV", detail: "catch stress spirals before they spend")
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)

                HStack(spacing: 10) {
                    planCard(.month, title: "Monthly", price: "$9.99", sub: "/mo · cancel any time", badge: nil)
                    planCard(.year, title: "Yearly", price: "$59", sub: "$4.91/mo · save 50%", badge: "BEST")
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer(minLength: 0)

                VStack(spacing: 2) {
                    PrimaryCtaButton(title: "Start 7-day free trial") { onStart() }
                    HStack(spacing: 2) {
                        Text("Then $4.91/mo · cancel anytime · ")
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
}

#if DEBUG
#Preview("Onboarding flow") {
    SplurjOnboardingFlow { v, a in
        print("Flow completed: \(v), \(a)")
    }
}
#endif
