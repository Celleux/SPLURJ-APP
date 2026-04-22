import Foundation

// MARK: - CoachEngine
//
// Decides when to trigger the SOS intercept. Brief:
//
//   The SOS screen is triggered from a push notification tap OR from a
//   real-time signal (HRV spike + merchant-category detected during a
//   risky time window). Implement the trigger logic behind a CoachEngine
//   service.
//
// The engine is STATELESS apart from a `lastFireAt` throttle — callers
// feed it a snapshot of (HRV, pending transaction, hour of day, user
// profile) and get back a TriggerDecision. NotificationService + the
// UI layer decide what to do with the decision (surface SOS sheet vs.
// fire a lockscreen notification).

public struct CoachSnapshot: Sendable {
    public var hourOfDay: Int                   // 0-23, user's local time
    public var hrv: Double?                     // latest ms
    public var baselineHRV: Double?             // rolling 7d
    public var pendingMerchant: String?         // e.g. "ASOS"
    public var pendingAmount: Double?           // e.g. 89.00
    public var pendingCategory: String?         // Plaid category string
    public var isAtSpendingRiskWindow: Bool {
        // Late-night / early-morning by default
        (hourOfDay >= 22 || hourOfDay < 3)
    }
}

public struct CoachDecision: Sendable, Equatable {
    public enum Action: String, Sendable { case none, inAppBanner, fullSOS }
    public var action: Action
    public var reason: String
    public static let none = CoachDecision(action: .none, reason: "no-trigger")
}

public final class CoachEngine: @unchecked Sendable {
    public static let shared = CoachEngine()

    private let throttleKey = "splurj.coach.lastFireAt"
    private let minInterval: TimeInterval = 15 * 60  // don't re-fire within 15min

    /// Pure(ish) decision function. Pass a snapshot, get back what to
    /// do. NotificationService is NOT invoked here — callers decide.
    public func evaluate(_ snap: CoachSnapshot) -> CoachDecision {
        // Respect throttle
        if let last = UserDefaults.standard.object(forKey: throttleKey) as? Date,
           Date().timeIntervalSince(last) < minInterval {
            return .none
        }

        // Rule 1: HRV dip + pending risky spend → full SOS
        if let hrv = snap.hrv, let baseline = snap.baselineHRV, baseline > 0 {
            let dip = hrv < baseline * 0.80
            if dip, snap.pendingMerchant != nil, snap.isAtSpendingRiskWindow {
                return .init(action: .fullSOS, reason: "hrv-dip+risk-window+pending")
            }
            if dip, snap.pendingMerchant != nil {
                return .init(action: .inAppBanner, reason: "hrv-dip+pending")
            }
            if dip {
                return .init(action: .inAppBanner, reason: "hrv-dip-only")
            }
        }

        // Rule 2: late-night risky spend without HRV signal
        if snap.pendingMerchant != nil, snap.isAtSpendingRiskWindow,
           let amount = snap.pendingAmount, amount > 40 {
            return .init(action: .fullSOS, reason: "late-night-pending-big")
        }

        // Rule 3: daytime pending spend — gentle nudge
        if snap.pendingMerchant != nil, snap.pendingAmount ?? 0 > 60 {
            return .init(action: .inAppBanner, reason: "daytime-large-pending")
        }

        return .none
    }

    public func markFired() {
        UserDefaults.standard.set(Date(), forKey: throttleKey)
    }

    public func clearThrottle() {
        UserDefaults.standard.removeObject(forKey: throttleKey)
    }
}
