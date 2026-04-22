import SwiftUI
import SwiftData

nonisolated enum AppTab: Int, Sendable {
    case home, wallet, pacts, coach, hub, profile
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showSiriUrgeSurf = false
    @State private var showSiriCheckIn = false
    @State private var vibeCheckTransaction: Transaction?
    @State private var showVibeCheck: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var recentTransactions: [Transaction]

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            Tab("Wallet", systemImage: "wallet.bifold", value: .wallet) {
                WalletView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            Tab("Pacts", systemImage: "person.2.fill", value: .pacts) {
                PactsView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            Tab("Coach", systemImage: "brain.head.profile.fill", value: .coach) {
                CoachTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            Tab("Hub", systemImage: "square.grid.2x2.fill", value: .hub) {
                HubView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            Tab("Profile", systemImage: "person.circle", value: .profile) {
                ProfileView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .tint(Theme.accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .fullScreenCover(isPresented: $showSiriUrgeSurf) {
            UrgeSurfView(siriTriggered: true)
        }
        .fullScreenCover(isPresented: $showSiriCheckIn) {
            SiriCheckInView()
        }
        .syncWidgetData()
        .onReceive(NotificationCenter.default.publisher(for: .siriUrgeDetected)) { _ in
            showSiriUrgeSurf = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .siriCheckInRequested)) { _ in
            showSiriCheckIn = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionSaved)) { notification in
            if let tx = notification.object as? Transaction {
                vibeCheckTransaction = tx
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showVibeCheck = true
                }
            }
        }
        .overlay { NoiseOverlay() }
        .overlay {
            if showVibeCheck, let tx = vibeCheckTransaction {
                VibeCheckOverlay(
                    transaction: tx,
                    onSelect: { vibe in
                        tx.moodEmoji = vibe.emoji
                        let entry = VibeCheckEntry(
                            transactionID: "\(tx.persistentModelID.hashValue)",
                            emoji: vibe.emoji,
                            sentiment: vibe.sentiment,
                            amount: tx.amount,
                            categoryName: tx.category
                        )
                        modelContext.insert(entry)
                        Task {
                            await HealthKitService.shared.saveStateOfMind(
                                valence: HealthKitService.valence(for: vibe)
                            )
                        }
                        showVibeCheck = false
                        vibeCheckTransaction = nil
                    },
                    onSkip: {
                        showVibeCheck = false
                        vibeCheckTransaction = nil
                    }
                )
                .transition(.identity)
            }
        }
    }
}
