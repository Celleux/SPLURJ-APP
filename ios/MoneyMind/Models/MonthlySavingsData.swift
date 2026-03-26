import Foundation

nonisolated struct MonthlySavingsData: Identifiable, Sendable {
    let month: String
    let amount: Double
    let date: Date
    var id: String { month }
    var isProjected: Bool = false
}
