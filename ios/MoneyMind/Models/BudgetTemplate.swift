import SwiftUI

nonisolated enum BudgetTemplateType: String, CaseIterable, Identifiable, Sendable {
    case fiftyThirtyTwenty = "50/30/20 Rule"
    case zeroBased = "Zero-Based"
    case envelope = "Envelope Method"
    case payYourselfFirst = "Pay Yourself First"
    case custom = "Custom"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .fiftyThirtyTwenty: "Needs 50% · Wants 30% · Savings 20%"
        case .zeroBased: "Every dollar gets a job"
        case .envelope: "Spend only what's in the envelope"
        case .payYourselfFirst: "Save first, budget the rest"
        case .custom: "Build your own from scratch"
        }
    }

    var description: String {
        switch self {
        case .fiftyThirtyTwenty:
            "The classic balanced approach. Split your income into three buckets: 50% for needs, 30% for wants, and 20% for savings."
        case .zeroBased:
            "Assign every single dollar to a category until nothing is left unassigned. Total control over your money."
        case .envelope:
            "Allocate fixed amounts to digital envelopes. When an envelope is empty, spending in that category stops."
        case .payYourselfFirst:
            "Set your savings target first, then distribute the remaining income across spending categories."
        case .custom:
            "Start with a blank slate. Add your own categories and set amounts that work for your lifestyle."
        }
    }

    var icon: String {
        switch self {
        case .fiftyThirtyTwenty: "chart.pie.fill"
        case .zeroBased: "equal.circle.fill"
        case .envelope: "envelope.fill"
        case .payYourselfFirst: "banknote.fill"
        case .custom: "slider.horizontal.3"
        }
    }

    var secondaryIcon: String {
        switch self {
        case .fiftyThirtyTwenty: "percent"
        case .zeroBased: "checkmark.circle.fill"
        case .envelope: "lock.fill"
        case .payYourselfFirst: "arrow.up.circle.fill"
        case .custom: "pencil"
        }
    }

    var accentColor: Color {
        switch self {
        case .fiftyThirtyTwenty: Color(hex: 0x6C5CE7)
        case .zeroBased: Color(hex: 0x00D2FF)
        case .envelope: Color(hex: 0xFF9100)
        case .payYourselfFirst: Color(hex: 0x00E676)
        case .custom: Color(hex: 0xA55EEA)
        }
    }

    var recommendedPersonality: MoneyPersonality {
        switch self {
        case .fiftyThirtyTwenty: .saver
        case .zeroBased: .builder
        case .envelope: .minimalist
        case .payYourselfFirst: .hustler
        case .custom: .generous
        }
    }

    var defaultCategories: [(name: String, icon: String, colorHex: String, percentage: Double)] {
        switch self {
        case .fiftyThirtyTwenty:
            [
                ("Housing", "house.fill", "5F27CD", 25),
                ("Food", "fork.knife", "FF6B6B", 15),
                ("Transport", "car.fill", "54A0FF", 10),
                ("Entertainment", "tv.fill", "FF9F43", 15),
                ("Shopping", "bag.fill", "A55EEA", 10),
                ("Personal Care", "sparkles", "E056A0", 5),
                ("Savings", "banknote.fill", "00E676", 20),
            ]
        case .zeroBased:
            [
                ("Housing", "house.fill", "5F27CD", 30),
                ("Food", "fork.knife", "FF6B6B", 15),
                ("Transport", "car.fill", "54A0FF", 10),
                ("Bills", "doc.text.fill", "01A3A4", 10),
                ("Entertainment", "tv.fill", "FF9F43", 5),
                ("Shopping", "bag.fill", "A55EEA", 5),
                ("Health", "heart.fill", "FF6348", 5),
                ("Savings", "banknote.fill", "00E676", 15),
                ("Other", "ellipsis.circle.fill", "64748B", 5),
            ]
        case .envelope:
            [
                ("Groceries", "cart.fill", "FF6B6B", 15),
                ("Dining Out", "fork.knife", "FF9F43", 10),
                ("Transport", "car.fill", "54A0FF", 10),
                ("Entertainment", "tv.fill", "A55EEA", 8),
                ("Shopping", "bag.fill", "E056A0", 7),
                ("Personal", "sparkles", "FFD700", 5),
                ("Bills", "doc.text.fill", "01A3A4", 25),
                ("Savings", "banknote.fill", "00E676", 20),
            ]
        case .payYourselfFirst:
            [
                ("Savings", "banknote.fill", "00E676", 25),
                ("Housing", "house.fill", "5F27CD", 25),
                ("Food", "fork.knife", "FF6B6B", 15),
                ("Transport", "car.fill", "54A0FF", 10),
                ("Bills", "doc.text.fill", "01A3A4", 10),
                ("Entertainment", "tv.fill", "FF9F43", 8),
                ("Other", "ellipsis.circle.fill", "64748B", 7),
            ]
        case .custom:
            [
                ("Category 1", "folder.fill", "6C5CE7", 25),
                ("Category 2", "folder.fill", "00D2FF", 25),
                ("Category 3", "folder.fill", "FF6B6B", 25),
                ("Category 4", "folder.fill", "00E676", 25),
            ]
        }
    }
}

struct BudgetAllocation: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var amount: Double
    var percentage: Double
}
