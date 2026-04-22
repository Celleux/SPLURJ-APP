#if DEBUG
import SwiftUI

// MARK: - Splurj v2 preview entry
//
// Debug-only hub that lets designers / engineers jump into any new
// Splurj-handoff screen without wiring them into production ContentView.
// Reachable from SettingsView → "Splurj v2 previews" when compiled in
// DEBUG (Chunk 10 wires that link).

struct SplurjPreviewEntry: View {
    @State private var route: Route?

    enum Route: String, CaseIterable, Identifiable {
        case mascotStorybook, onboarding, home, pacts, coachAllClear, coachEngaged, sos, walletEmpty, walletConnected, profile
        var id: String { rawValue }
        var title: String {
            switch self {
            case .mascotStorybook: "Mascot storybook"
            case .onboarding:      "Onboarding flow"
            case .home:            "Splurj Home (Hub)"
            case .pacts:           "Splurj Pacts"
            case .coachAllClear:   "Splurj Coach · all clear"
            case .coachEngaged:    "Splurj Coach · engaged"
            case .sos:             "SOS intercept"
            case .walletEmpty:     "Wallet · empty state"
            case .walletConnected: "Wallet · connected"
            case .profile:         "Profile sheet"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Splurj v2 · Night Terrarium") {
                    ForEach(Route.allCases) { r in
                        Button(r.title) { route = r }
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                Section("Notes") {
                    Text("These views are built from the Splurj-handoff prototype. They are NOT yet wired into production ContentView — use them to spot-check fidelity.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Splurj v2 previews")
            .sheet(item: $route) { r in
                destination(for: r)
            }
        }
    }

    @ViewBuilder
    private func destination(for r: Route) -> some View {
        switch r {
        case .mascotStorybook:
            NavigationStack { MascotStorybookView() }
        case .onboarding:
            SplurjOnboardingFlow { _, _ in }
        case .home:
            SplurjHomeView(
                variant: .her,
                personality: .empath,
                stage: .leafy,
                level: 7,
                equippedCosmetics: [.crown, .butterfly, .firefly]
            )
        case .pacts:
            SplurjPactsView(variant: .her, level: 7)
        case .coachAllClear:
            SplurjCoachView(variant: .her, level: 7, isAllClear: true)
        case .coachEngaged:
            SplurjCoachView(variant: .her, level: 7, isAllClear: false)
        case .sos:
            SplurjSOSView(variant: .her)
        case .walletEmpty:
            SplurjWalletView(variant: .her, level: 1, isConnected: false)
        case .walletConnected:
            SplurjWalletView(variant: .her, level: 7, isConnected: true)
        case .profile:
            SplurjProfileView(
                equippedCosmetics: [.daisy, .leafCape, .firefly],
                onDismiss: {}
            )
        }
    }
}

#Preview("Splurj v2 previews") {
    SplurjPreviewEntry()
}
#endif
