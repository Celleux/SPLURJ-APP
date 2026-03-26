import Foundation
import SwiftData

@Model
class BudgetCategory {
    var name: String
    var icon: String
    var colorHex: String
    var monthlyLimit: Double
    var sortOrder: Int

    init(
        name: String,
        icon: String,
        colorHex: String,
        monthlyLimit: Double,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.monthlyLimit = monthlyLimit
        self.sortOrder = sortOrder
    }

    static let defaults: [(String, String, String, Double)] = [
        ("Food", "fork.knife", "FF6B6B", 500),
        ("Shopping", "bag.fill", "A55EEA", 300),
        ("Entertainment", "tv.fill", "FF9F43", 200),
    ]
}
