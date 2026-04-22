import SwiftUI
import SwiftData

// MARK: - Splurj Coach host
//
// Renders SplurjCoachView and wires SOS → UrgeSurfView fullScreenCover.
// Other impulse-control tools still live in the legacy CoachTabView —
// a later pass will consolidate.

struct SplurjCoachHost: View {
    @Query private var profiles: [UserProfile]
    @Environment(HealthKitService.self) private var healthKit

    @State private var showUrgeSurf = false

    private var profile: UserProfile? { profiles.first }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }
    private var equippedCosmetics: Set<CosmeticID> { profile?.equippedCosmetics ?? [] }

    private var level: Int {
        max(profile?.splurjLevel ?? 1, (profile?.currentStreak ?? 0) / 3 + 1)
    }

    private var hrvText: String {
        guard let ms = healthKit.latestHRV else { return "--" }
        return "\(Int(ms.rounded()))ms"
    }

    var body: some View {
        SplurjCoachView(
            variant: variant,
            level: level,
            equippedCosmetics: equippedCosmetics,
            isAllClear: true,
            hrv: hrvText,
            onOpenSOS: { showUrgeSurf = true }
        )
        .fullScreenCover(isPresented: $showUrgeSurf) {
            UrgeSurfView(siriTriggered: false)
        }
    }
}
