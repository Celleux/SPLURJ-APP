import Foundation
import HealthKit
import SwiftData

nonisolated struct HRVDataPoint: Sendable, Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

nonisolated enum HealthAuthState: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case unavailable
}

@Observable
final class HealthKitService: @unchecked Sendable {
    @MainActor static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    var authState: HealthAuthState = .notDetermined
    var recentHRV: [HRVDataPoint] = []
    var latestHRV: Double?
    var baselineHRV: Double = 0
    var isRefreshing: Bool = false
    var lastRefresh: Date?

    private init() {
        if !HKHealthStore.isHealthDataAvailable() {
            authState = .unavailable
        }
    }

    var isStressDetected: Bool {
        guard let latestHRV, baselineHRV > 0 else { return false }
        return latestHRV < baselineHRV * 0.8
    }

    var isAuthorized: Bool { authState == .authorized }

    // MARK: - Authorization

    @MainActor
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authState = .unavailable
            return false
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKCategoryType(.mindfulSession),
            HKObjectType.stateOfMindType()
        ]

        let writeTypes: Set<HKSampleType> = [
            HKCategoryType(.mindfulSession),
            HKObjectType.stateOfMindType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            authState = .authorized
            await refresh()
            return true
        } catch {
            authState = .denied
            return false
        }
    }

    // MARK: - Refresh

    @MainActor
    func refresh() async {
        guard authState == .authorized, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let points = await fetchHRVData(days: 7)
        recentHRV = points
        latestHRV = points.last?.value
        if !points.isEmpty {
            baselineHRV = points.reduce(0) { $0 + $1.value } / Double(points.count)
        }
        lastRefresh = Date()
    }

    // MARK: - Queries

    private func fetchHRVData(days: Int = 7) async -> [HRVDataPoint] {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .forward)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [sortDescriptor],
            limit: 200
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            var dailyReadings: [String: [Double]] = [:]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            for sample in samples {
                let ms = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                let key = formatter.string(from: sample.startDate)
                dailyReadings[key, default: []].append(ms)
            }

            var results: [HRVDataPoint] = []
            for i in 0..<days {
                guard let date = calendar.date(byAdding: .day, value: -days + 1 + i, to: endDate) else { continue }
                let key = formatter.string(from: date)
                if let values = dailyReadings[key], !values.isEmpty {
                    let avg = values.reduce(0, +) / Double(values.count)
                    results.append(HRVDataPoint(date: date, value: avg))
                }
            }
            return results
        } catch {
            return []
        }
    }

    // MARK: - State of Mind

    @MainActor
    func saveStateOfMind(valence: Double, associations: [HKStateOfMind.Association] = [.money]) async {
        guard authState == .authorized else { return }
        let clamped = max(-1, min(1, valence))
        let sample = HKStateOfMind(
            date: Date(),
            kind: .momentaryEmotion,
            valence: clamped,
            labels: [],
            associations: associations
        )
        try? await healthStore.save(sample)
    }

    static func valence(for vibe: VibeType) -> Double {
        Double(vibe.sentiment)
    }

    // MARK: - JITAI

    @MainActor
    func evaluateJITAI(profile: UserProfile, modelContext: ModelContext) {
        guard profile.notificationsEnabled, profile.jitaiAdaptiveNotif else { return }
        guard isStressDetected else { return }
        guard !alreadyNudgedToday() else { return }

        NotificationService.shared.createInAppNotification(
            type: .jitaiNudge,
            title: "Low HRV detected",
            body: "Your heart-rate variability dipped below your baseline. Take two minutes for a breathing exercise before any big spending decision.",
            deepLink: .home,
            modelContext: modelContext
        )
        markNudgedToday()
    }

    private let nudgeKey = "splurj.healthkit.lastHRVNudge"

    private func alreadyNudgedToday() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: nudgeKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private func markNudgedToday() {
        UserDefaults.standard.set(Date(), forKey: nudgeKey)
    }
}
