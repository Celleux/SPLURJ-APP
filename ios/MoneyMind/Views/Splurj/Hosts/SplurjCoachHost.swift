import SwiftUI
import SwiftData

// MARK: - Splurj Coach host
//
// Renders SplurjCoachView and wires every tool tile to its existing
// production view via fullScreenCover. All impulse-control tooling
// stays accessible — only the visual shell changed.

struct SplurjCoachHost: View {
    @Query private var profiles: [UserProfile]
    @Environment(HealthKitService.self) private var healthKit

    @State private var activeTool: Tool?
    @State private var showProfile = false
    @State private var showPactsHub = false

    enum Tool: String, Identifiable {
        case sos, urgeSurf, halt, coolDown, ifThen, oneSec, act, aiCoach, dnsBlocking
        var id: String { rawValue }
    }

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

    // Below ~35ms SDNN is commonly flagged as elevated stress.
    private var isAllClear: Bool {
        guard let ms = healthKit.latestHRV else { return true }
        return ms >= 35
    }

    var body: some View {
        SplurjCoachView(
            variant: variant,
            level: level,
            equippedCosmetics: equippedCosmetics,
            isAllClear: isAllClear,
            hrv: hrvText,
            onOpenSOS:     { activeTool = .sos },
            onUrgeSurf:    { activeTool = .urgeSurf },
            onHALT:        { activeTool = .halt },
            onCoolDown:    { activeTool = .coolDown },
            onIfThen:      { activeTool = .ifThen },
            onOneSec:      { activeTool = .oneSec },
            onACT:         { activeTool = .act },
            onAICoach:     { activeTool = .aiCoach },
            onDNSBlocking: { activeTool = .dnsBlocking },
            onDraftPact: { showPactsHub = true },
            onOpenProfile: { showProfile = true }
        )
        .fullScreenCover(item: $activeTool) { tool in
            destination(for: tool)
        }
        .sheet(isPresented: $showProfile) {
            SplurjProfileHost()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPactsHub) {
            NavigationStack { ChallengesHubView() }
        }
    }

    @ViewBuilder
    private func destination(for tool: Tool) -> some View {
        switch tool {
        case .sos:          EmergencyCrisisView()
        case .urgeSurf:     UrgeSurfView(siriTriggered: false)
        case .halt:         HALTCheckView()
        case .coolDown:     CoolingOffView()
        case .ifThen:       ImplementationIntentionsView()
        case .oneSec:       OneSecBreathingGuideView()
        case .act:          ACTExercisesView()
        case .aiCoach:      CoachChatView()
        case .dnsBlocking:  DNSBlockingWizardView()
        }
    }
}
