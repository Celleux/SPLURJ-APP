import Foundation
import HealthKit

nonisolated struct HRVDataPoint: Sendable {
    let date: Date
    let value: Double
}

class HealthKitService {
    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKCategoryType(.mindfulSession)
        ]

        var writeTypes: Set<HKSampleType> = [
            HKCategoryType(.mindfulSession)
        ]

        writeTypes.insert(HKObjectType.stateOfMindType())

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    func fetchHRVData(days: Int = 7) async -> [HRVDataPoint] {
        guard isHealthDataAvailable, isAuthorized else { return [] }

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .forward)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [sortDescriptor],
            limit: 100
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

    @available(iOS 18.0, *)
    func saveStateOfMind(valence: Double) async {
        guard isHealthDataAvailable, isAuthorized else { return }

        let sample = HKStateOfMind(
            date: Date(),
            kind: .dailyMood,
            valence: valence,
            labels: [],
            associations: [.health]
        )

        do {
            try await healthStore.save(sample)
        } catch {
            // Silent fail
        }
    }

    static func generateDemoData(days: Int = 7) -> [HRVDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let baseHRV = 42.0

        return (0..<days).compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -days + 1 + i, to: now) else { return nil }
            let variation = Double.random(in: -8...8)
            let trend = Double(i) * 0.3
            let value = max(15, baseHRV + variation + trend)
            return HRVDataPoint(date: date, value: value)
        }
    }

    static func mapStarRatingToValence(_ stars: Int) -> Double {
        switch stars {
        case 1: return -0.8
        case 2: return -0.4
        case 3: return 0.0
        case 4: return 0.4
        case 5: return 0.8
        default: return 0.0
        }
    }
}
