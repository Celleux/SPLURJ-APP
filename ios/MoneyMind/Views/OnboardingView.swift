import SwiftUI
import SwiftData

nonisolated enum OnboardingScreenV2: Int, CaseIterable, Sendable {
    case splash
    case intro
    case dnaIntro
    case spendingCards
    case emotionalTriggers
    case moneyMemory
    case riskTolerance
    case dnaAnalysis
    case dnaReveal
    case premiumOffer
    case personalizedPlan
    case firstQuest
    case launch
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    @AppStorage("onboardingStep") private var savedStep: Int = 0
    @State private var currentScreen: OnboardingScreenV2 = .splash
    @State private var dna = FinancialDNA.default
    @State private var cardAnswers: [String] = []
    @State private var triggerRatings: [String: Double] = [:]
    @State private var memoryAnswers: [String] = []
    @State private var riskScore: Double = 0.5
    @State private var showSOSSheet = false

    private var showSkip: Bool {
        let skipScreens: [OnboardingScreenV2] = [.spendingCards, .emotionalTriggers, .moneyMemory, .riskTolerance]
        return skipScreens.contains(currentScreen)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch currentScreen {
            case .splash:
                CinematicSplashView { advance() }

            case .intro:
                IntroOnboardingView { advance() }

            case .dnaIntro:
                FinancialDNAIntroView { advance() }

            case .spendingCards:
                SpendingPatternCardsView(dna: $dna, cardAnswers: $cardAnswers) { advance() }

            case .emotionalTriggers:
                EmotionalTriggersView(dna: $dna, triggerRatings: $triggerRatings) { advance() }

            case .moneyMemory:
                MoneyMemoryView(dna: $dna, memoryAnswers: $memoryAnswers) { advance() }

            case .riskTolerance:
                RiskToleranceView(dna: $dna, riskScore: $riskScore) { advance() }

            case .dnaAnalysis:
                DNAAnalysisView { advance() }

            case .dnaReveal:
                FinancialDNARevealView(dna: dna) { advance() }

            case .premiumOffer:
                OnboardingPaywallView(dna: dna) { advance() }

            case .personalizedPlan:
                PersonalizedPlanView(dna: dna) { advance() }

            case .firstQuest:
                FirstQuestScreen(dna: dna) { advance() }

            case .launch:
                LaunchScreenView(dna: dna, modelContext: modelContext) {
                    let result = FinancialDNAResult(
                        dna: dna,
                        cardSortAnswers: cardAnswers,
                        triggerRatings: triggerRatings,
                        memoryAnswers: memoryAnswers,
                        riskScore: riskScore
                    )
                    modelContext.insert(result)
                    try? modelContext.save()
                    savedStep = 0
                    onComplete()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if currentScreen != .splash && currentScreen != .intro {
                Button {
                    showSOSSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sos")
                            .font(Typography.labelSmall)
                        Text("SOS")
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(Theme.bossRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.bossRed.opacity(0.15), in: Capsule())
                }
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
        }
        .overlay(alignment: .topLeading) {
            if showSkip {
                Button {
                    skipToLaunch()
                } label: {
                    Text("Skip")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.leading, 20)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showSOSSheet) {
            UrgeSurfSheet()
                .presentationDetents([.large])
        }
        .onAppear {
            if savedStep > 0, let restored = OnboardingScreenV2(rawValue: savedStep) {
                currentScreen = restored
            }
        }
        .onChange(of: currentScreen) { _, newValue in
            savedStep = newValue.rawValue
        }
    }

    private func advance() {
        let allScreens = OnboardingScreenV2.allCases
        guard let currentIndex = allScreens.firstIndex(of: currentScreen),
              currentIndex + 1 < allScreens.count else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentScreen = allScreens[currentIndex + 1]
        }
    }

    private func skipToLaunch() {
        dna = .default
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentScreen = .launch
        }
    }
}
