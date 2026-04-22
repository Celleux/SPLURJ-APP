import SwiftUI
import SwiftData

// MARK: - Splurj Pacts host
//
// Renders SplurjPactsView. Pact join/create actions are stubbed here —
// the CloudKit-backed ChallengesHubView logic will be folded in once the
// visual layer is stable.

struct SplurjPactsHost: View {
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }

    private var level: Int {
        max(profile?.splurjLevel ?? 1, (profile?.currentStreak ?? 0) / 3 + 1)
    }

    var body: some View {
        SplurjPactsView(variant: variant, level: level)
    }
}
