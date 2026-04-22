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
                    OnboardingView {
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
