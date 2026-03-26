import Foundation
import SwiftData

nonisolated enum TransactionType: String, Codable, Sendable, CaseIterable {
    case expense
    case income
}

nonisolated enum TransactionCategory: String, Codable, Sendable, CaseIterable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case entertainment = "Entertainment"
    case health = "Health"
    case education = "Education"
    case personalCare = "Personal Care"
    case home = "Home"
    case travel = "Travel"
    case gifts = "Gifts"
    case subscriptions = "Subscriptions"
    case income = "Income"
    case savings = "Savings"
    case other = "Other"

    case housing = "Housing"
    case utilities = "Utilities"
    case salary = "Salary"
    case freelance = "Freelance"
    case gift = "Gift"

    var emoji: String {
        switch self {
        case .food: "\u{1F354}"
        case .transport: "\u{1F697}"
        case .shopping: "\u{1F6CD}"
        case .bills: "\u{1F4C4}"
        case .entertainment: "\u{1F3AC}"
        case .health: "\u{1F3CB}"
        case .education: "\u{1F393}"
        case .personalCare: "\u{1F485}"
        case .home: "\u{1F3E0}"
        case .travel: "\u{2708}"
        case .gifts: "\u{1F381}"
        case .subscriptions: "\u{1F4F1}"
        case .income: "\u{1F4B0}"
        case .savings: "\u{1F3AF}"
        case .other: "\u{1F4CC}"
        case .housing: "\u{1F3E0}"
        case .utilities: "\u{26A1}"
        case .salary: "\u{1F4B0}"
        case .freelance: "\u{1F4BB}"
        case .gift: "\u{1F381}"
        }
    }

    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .bills: "doc.text.fill"
        case .entertainment: "tv.fill"
        case .health: "figure.run"
        case .education: "book.fill"
        case .personalCare: "sparkles"
        case .home: "house.fill"
        case .travel: "airplane"
        case .gifts: "gift.fill"
        case .subscriptions: "arrow.triangle.2.circlepath"
        case .income: "banknote.fill"
        case .savings: "target"
        case .other: "ellipsis.circle.fill"
        case .housing: "house.fill"
        case .utilities: "bolt.fill"
        case .salary: "briefcase.fill"
        case .freelance: "laptopcomputer"
        case .gift: "gift.fill"
        }
    }

    var color: String {
        switch self {
        case .food: "FF6B6B"
        case .transport: "54A0FF"
        case .shopping: "A55EEA"
        case .bills: "01A3A4"
        case .entertainment: "FF9F43"
        case .health: "FF6348"
        case .education: "2ED573"
        case .personalCare: "E056A0"
        case .home: "5F27CD"
        case .travel: "3498DB"
        case .gifts: "FFD700"
        case .subscriptions: "9B59B6"
        case .income: "00E676"
        case .savings: "00D2FF"
        case .other: "64748B"
        case .housing: "5F27CD"
        case .utilities: "01A3A4"
        case .salary: "00E676"
        case .freelance: "6C5CE7"
        case .gift: "FFD700"
        }
    }

    var resolvedCategory: TransactionCategory {
        switch self {
        case .housing: .home
        case .utilities: .bills
        case .salary, .freelance: .income
        case .gift: .gifts
        default: self
        }
    }

    static var expenseCategories: [TransactionCategory] {
        [.food, .transport, .shopping, .bills, .entertainment, .health, .education, .personalCare, .home, .travel, .gifts, .subscriptions, .other]
    }

    static var incomeCategories: [TransactionCategory] {
        [.income, .gifts, .savings, .other]
    }
}

@Model
class Transaction {
    var amount: Double
    var category: String
    var note: String
    var date: Date
    var type: String
    var moodEmoji: String

    init(
        amount: Double,
        category: TransactionCategory,
        note: String = "",
        type: TransactionType,
        moodEmoji: String = ""
    ) {
        self.amount = amount
        self.category = category.rawValue
        self.note = note
        self.date = Date()
        self.type = type.rawValue
        self.moodEmoji = moodEmoji
    }

    var transactionType: TransactionType {
        TransactionType(rawValue: type) ?? .expense
    }

    var transactionCategory: TransactionCategory {
        TransactionCategory(rawValue: category) ?? .other
    }
}
