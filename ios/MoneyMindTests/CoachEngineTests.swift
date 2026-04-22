import Testing
import Foundation
@testable import MoneyMind

/// CoachEngine decision logic. Each test sets up a snapshot and asserts
/// the expected SOS / in-app-banner / none outcome.
struct CoachEngineTests {

    @Test func hrvDipPlusRiskyWindowPlusPendingFiresFullSOS() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 23,
            hrv: 40, baselineHRV: 70,
            pendingMerchant: "ASOS",
            pendingAmount: 89,
            pendingCategory: "Shopping"
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .fullSOS)
        #expect(decision.reason.contains("hrv-dip+risk-window"))
    }

    @Test func hrvDipPlusPendingWithoutRiskyWindowFiresBanner() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 14,
            hrv: 45, baselineHRV: 70,
            pendingMerchant: "ASOS",
            pendingAmount: 45,
            pendingCategory: "Shopping"
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .inAppBanner)
    }

    @Test func hrvDipAloneFiresBanner() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 14,
            hrv: 45, baselineHRV: 70,
            pendingMerchant: nil, pendingAmount: nil, pendingCategory: nil
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .inAppBanner)
    }

    @Test func lateNightBigPendingWithoutHRVFiresFullSOS() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 23,
            hrv: nil, baselineHRV: nil,
            pendingMerchant: "ASOS",
            pendingAmount: 89,
            pendingCategory: "Shopping"
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .fullSOS)
        #expect(decision.reason.contains("late-night"))
    }

    @Test func daytimeLargePendingFiresBanner() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 15,
            hrv: nil, baselineHRV: nil,
            pendingMerchant: "ASOS",
            pendingAmount: 89,
            pendingCategory: "Shopping"
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .inAppBanner)
    }

    @Test func calmDayNoSignalsFiresNothing() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 11,
            hrv: 65, baselineHRV: 68,
            pendingMerchant: nil, pendingAmount: nil, pendingCategory: nil
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .none)
    }

    @Test func smallDaytimePurchaseDoesNotFire() {
        CoachEngine.shared.clearThrottle()
        let snap = CoachSnapshot(
            hourOfDay: 11,
            hrv: 65, baselineHRV: 68,
            pendingMerchant: "Coffee",
            pendingAmount: 5,
            pendingCategory: "Food & Drink"
        )
        let decision = CoachEngine.shared.evaluate(snap)
        #expect(decision.action == .none)
    }

    @Test func throttleSuppressesRapidRefires() {
        CoachEngine.shared.clearThrottle()
        let risky = CoachSnapshot(
            hourOfDay: 23,
            hrv: 40, baselineHRV: 70,
            pendingMerchant: "ASOS",
            pendingAmount: 89,
            pendingCategory: "Shopping"
        )
        let first = CoachEngine.shared.evaluate(risky)
        #expect(first.action == .fullSOS)
        CoachEngine.shared.markFired()
        let second = CoachEngine.shared.evaluate(risky)
        #expect(second.action == .none)
    }
}
