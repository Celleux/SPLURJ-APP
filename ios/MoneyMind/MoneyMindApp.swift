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
// one with the chosen variant + archetype, then flips the onboarding flag.

private struct SplurjOnboardingHost: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
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
        try? modelContext.save()
    }
}
