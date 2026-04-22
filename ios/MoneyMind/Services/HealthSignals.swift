import Foundation

// MARK: - HealthSignals
//
// Thin wrapper around platform-specific HRV and mood signals so the rest
// of Splurj doesn't need to know whether the source is Apple HealthKit,
// Google Health Connect, or a mock.
//
// iOS ships Apple Health via the existing HealthKitService (see
// Services/HealthKitService.swift). Android stub lives elsewhere and
// would plug in via a separate conforming type.

protocol HealthSignalsProvider: Sendable {
    var isAvailable: Bool { get async }
    var authState: HealthAuthState { get async }

    /// Latest HRV reading (SDNN in ms). Nil if no sample today.
    func latestHRV() async -> Double?

    /// Rolling baseline — average of the last `days` daily readings.
    func rollingBaselineHRV(days: Int) async -> Double?

    /// `true` when the latest reading dips more than the `threshold`
    /// fraction below the rolling baseline (default 0.2 = 20%).
    func isStressDetected(threshold: Double) async -> Bool

    /// Write the user's VibeCheck response into Apple Health as an
    /// HKStateOfMind sample on iOS 17+. No-op on Android / missing
    /// entitlement.
    func writeStateOfMind(valence: Double) async
}

enum HealthSignals {
    /// Default provider — wraps HealthKitService on iOS.
    static let shared: HealthSignalsProvider = AppleHealthSignals()
}

// MARK: - Apple Health implementation

private struct AppleHealthSignals: HealthSignalsProvider {
    var isAvailable: Bool {
        get async {
            await MainActor.run { HealthKitService.shared.authState != .unavailable }
        }
    }

    var authState: HealthAuthState {
        get async { await MainActor.run { HealthKitService.shared.authState } }
    }

    func latestHRV() async -> Double? {
        await MainActor.run { HealthKitService.shared.latestHRV }
    }

    func rollingBaselineHRV(days: Int) async -> Double? {
        let baseline = await MainActor.run { HealthKitService.shared.baselineHRV }
        return baseline > 0 ? baseline : nil
    }

    func isStressDetected(threshold: Double = 0.2) async -> Bool {
        await MainActor.run { HealthKitService.shared.isStressDetected }
    }

    func writeStateOfMind(valence: Double) async {
        await HealthKitService.shared.saveStateOfMind(valence: valence)
    }
}
