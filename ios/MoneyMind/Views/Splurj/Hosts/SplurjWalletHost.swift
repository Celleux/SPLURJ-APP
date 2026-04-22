import SwiftUI
import SwiftData

// MARK: - Splurj Wallet host
//
// Wraps SplurjWalletView. Decides empty vs connected state from whether
// any transactions or impulse logs exist in SwiftData.

struct SplurjWalletHost: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \ImpulseLog.date, order: .reverse) private var impulseLogs: [ImpulseLog]

    private var profile: UserProfile? { profiles.first }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }
    private var equippedCosmetics: Set<CosmeticID> { profile?.equippedCosmetics ?? [] }

    private var level: Int {
        max(profile?.splurjLevel ?? 1, (profile?.currentStreak ?? 0) / 3 + 1)
    }

    private var isConnected: Bool {
        !transactions.isEmpty || !impulseLogs.isEmpty
    }

    var body: some View {
        SplurjWalletView(
            variant: variant,
            level: level,
            equippedCosmetics: equippedCosmetics,
            isConnected: isConnected,
            onConnectPlaid: { }
        )
    }
}
