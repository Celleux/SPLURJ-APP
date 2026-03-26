import SwiftUI

@Observable
@MainActor
class PremiumManager {
    var isPremium: Bool = false
    var showPaywall: Bool = false
    var installDate: Date = Date()

    private static let trialDuration: TimeInterval = 3 * 24 * 60 * 60

    var isInTrial: Bool {
        Date().timeIntervalSince(installDate) < Self.trialDuration
    }

    var hasFullAccess: Bool {
        isPremium || isInTrial
    }

    var trialDaysRemaining: Int {
        let remaining = Self.trialDuration - Date().timeIntervalSince(installDate)
        guard remaining > 0 else { return 0 }
        return Int(ceil(remaining / (24 * 60 * 60)))
    }

    var trialEndDate: Date {
        installDate.addingTimeInterval(Self.trialDuration)
    }

    var shouldShowTrialBanner: Bool {
        isInTrial && trialDaysRemaining <= 2
    }

    func updateInstallDate(_ date: Date) {
        installDate = date
    }

    func unlock() {
        isPremium = true
        showPaywall = false
    }

    func restore() {
        isPremium = true
        showPaywall = false
    }
}
