import SwiftUI
import SwiftData

@main
struct SplurjApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var premiumManager = PremiumManager()
    @State private var healthKit = HealthKitService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    SplurjOnboardingHost {
                        withAnimation(.spring(response: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .environment(premiumManager)
            .environment(healthKit)
            .preferredColorScheme(.dark)
            .onAppear {
                SoundManager.shared.preload()
                ChallengeNotificationService.requestPermission()
                Task { await healthKit.refresh() }
            }
        }
        .modelContainer(for: [
            UserProfile.self,
            ImpulseLog.self,
            DailyEntry.self,
            ImplementationIntention.self,
            QuizResult.self,
            SpendingAutopsy.self,
            UrgeSurfSession.self,
            HALTCheckIn.self,
            CoolingOffSession.self,

            PGSIAssessment.self,
            Achievement.self,
            HighRiskPattern.self,
            CoachInteraction.self,
            ACTExercise.self,

            Transaction.self,
            BudgetCategory.self,
            SavingsChallenge.self,
            MerchantCategoryMapping.self,
            RecurringExpense.self,
            InAppNotification.self,
            VibeCheckEntry.self,
            ScratchCard.self,

            GachaState.self,
            QuestProgress.self,
            PlayerProfile.self,
            DailyQuestSlot.self,
            FinancialDNAResult.self,
            WeeklyChallenge.self,

            ChallengeParticipant.self,
            ChallengeCheckIn.self,
            ChallengeNudge.self,
            ChallengeActivityEvent.self,
        ])
    }
}

// MARK: - Onboarding host
//
// Bridges SplurjOnboardingFlow (UI-only) with SwiftData persistence.
// On completion, either creates a new UserProfile or updates the existing
// one with the chosen variant + archetype, writes a compatible QuizResult
// so legacy views (BudgetAnalytics, ChallengesHub, CardCollection, etc.)
// can read .personality without falling back to .builder, and flips the
// onboarding flag.

private struct SplurjOnboardingHost: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var existingQuizResults: [QuizResult]
    var onComplete: () -> Void

    var body: some View {
        SplurjOnboardingFlow { variant, archetype in
            persist(variant: variant, archetype: archetype)
            onComplete()
        }
    }

    private func persist(variant: SplurjVariant, archetype: SplurjArchetype) {
        let profile: UserProfile
        if let existing = profiles.first {
            profile = existing
        } else {
            profile = UserProfile(name: "you")
            modelContext.insert(profile)
        }
        profile.splurjVariant = variant
        profile.splurjArchetype = archetype

        // Mirror into legacy QuizResult so views querying quizResults.first?.personality
        // pick up the Splurj DNA result. Reuse existing record if one exists.
        let result = existingQuizResults.first ?? {
            let r = QuizResult(answers: [])
            modelContext.insert(r)
            return r
        }()
        result.personalityType = moneyPersonality(for: archetype).rawValue
        result.createdAt = Date()

        try? modelContext.save()
    }

    private func moneyPersonality(for archetype: SplurjArchetype) -> MoneyPersonality {
        switch archetype {
        case .builder:    .builder       // Stress Shield
        case .empath:     .saver         // FOMO Filter → savings-first coping
        case .riser:      .hustler       // Reward Regulator → growth mindset
        case .minimalist: .minimalist    // Boredom Buddy → low-footprint
        case .generous:   .generous      // Custom / other
        }
    }
}
