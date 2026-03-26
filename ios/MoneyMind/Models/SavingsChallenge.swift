import Foundation
import SwiftData

nonisolated enum ChallengeType: String, Codable, Sendable, CaseIterable {
    case envelope100 = "envelope100"
    case week52 = "week52"
    case noSpend = "noSpend"
    case roundUp = "roundUp"

    var title: String {
        switch self {
        case .envelope100: "100 Envelope Challenge"
        case .week52: "52-Week Savings"
        case .noSpend: "No-Spend Challenge"
        case .roundUp: "Round-Up Race"
        }
    }

    var subtitle: String {
        switch self {
        case .envelope100: "Save $1–$100 by picking envelopes. Total: $5,050"
        case .week52: "Save $1 more each week for a year. Total: $1,378"
        case .noSpend: "Go as many days as possible without non-essential spending"
        case .roundUp: "Round up every transaction and watch pennies grow"
        }
    }

    var icon: String {
        switch self {
        case .envelope100: "envelope.fill"
        case .week52: "calendar"
        case .noSpend: "xmark.circle.fill"
        case .roundUp: "arrow.up.circle.fill"
        }
    }

    var totalGoal: Double {
        switch self {
        case .envelope100: 5050
        case .week52: 1378
        case .noSpend: 0
        case .roundUp: 0
        }
    }

    var durationLabel: String {
        switch self {
        case .envelope100: "100 days"
        case .week52: "52 weeks"
        case .noSpend: "30 days"
        case .roundUp: "Ongoing"
        }
    }

    var difficulty: Int {
        switch self {
        case .envelope100: 2
        case .week52: 2
        case .noSpend: 3
        case .roundUp: 1
        }
    }
}

@Model
class SavingsChallenge {
    var typeRaw: String
    var startDate: Date
    var isActive: Bool
    var completedItems: [Int]
    var noSpendDays: [String]
    var spentDays: [String]
    var roundUpTotal: Double
    var totalSaved: Double
    var inviteCode: String

    init(type: ChallengeType) {
        self.typeRaw = type.rawValue
        self.startDate = Date()
        self.isActive = true
        self.completedItems = []
        self.noSpendDays = []
        self.spentDays = []
        self.roundUpTotal = 0
        self.totalSaved = 0
        self.inviteCode = "MC-" + String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })
    }

    var challengeType: ChallengeType {
        ChallengeType(rawValue: typeRaw) ?? .envelope100
    }

    var progress: Double {
        switch challengeType {
        case .envelope100:
            return totalSaved / 5050.0
        case .week52:
            return totalSaved / 1378.0
        case .noSpend:
            let total = noSpendDays.count + spentDays.count
            guard total > 0 else { return 0 }
            return Double(noSpendDays.count) / Double(total)
        case .roundUp:
            return min(1.0, roundUpTotal / 100.0)
        }
    }

    var noSpendStreak: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        while true {
            let key = formatter.string(from: checkDate)
            if noSpendDays.contains(key) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    var daysActive: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 1)
    }

    var isCompleted: Bool {
        switch challengeType {
        case .envelope100: return completedItems.count >= 100
        case .week52: return completedItems.count >= 52
        case .noSpend: return daysActive >= 30 && noSpendStreak >= 30
        case .roundUp: return false
        }
    }

    var dailySuggestedEnvelope: Int? {
        guard challengeType == .envelope100 else { return nil }
        let remaining = (1...100).filter { !completedItems.contains($0) }
        guard !remaining.isEmpty else { return nil }
        let dayHash = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return remaining[dayHash % remaining.count]
    }
}
