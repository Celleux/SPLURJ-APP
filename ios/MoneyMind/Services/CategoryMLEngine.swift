import Foundation
import SwiftData

@Observable
class CategoryMLEngine {
    private static let builtInMappings: [String: TransactionCategory] = [
        "starbucks": .food,
        "mcdonald": .food,
        "mcdonalds": .food,
        "burger king": .food,
        "wendy": .food,
        "wendys": .food,
        "chipotle": .food,
        "subway": .food,
        "dunkin": .food,
        "dominos": .food,
        "pizza hut": .food,
        "taco bell": .food,
        "chick-fil-a": .food,
        "panera": .food,
        "panda express": .food,
        "five guys": .food,
        "popeyes": .food,
        "kfc": .food,
        "doordash": .food,
        "grubhub": .food,
        "ubereats": .food,
        "uber eats": .food,
        "instacart": .food,
        "whole foods": .food,
        "trader joe": .food,
        "kroger": .food,
        "safeway": .food,
        "costco": .shopping,
        "walmart": .shopping,
        "target": .shopping,
        "amazon": .shopping,
        "best buy": .shopping,
        "ikea": .home,
        "home depot": .home,
        "lowes": .home,
        "uber": .transport,
        "lyft": .transport,
        "gas station": .transport,
        "shell": .transport,
        "chevron": .transport,
        "exxon": .transport,
        "bp": .transport,
        "parking": .transport,
        "metro": .transport,
        "netflix": .subscriptions,
        "spotify": .subscriptions,
        "hulu": .subscriptions,
        "disney+": .subscriptions,
        "disney plus": .subscriptions,
        "apple music": .subscriptions,
        "youtube premium": .subscriptions,
        "hbo": .subscriptions,
        "paramount": .subscriptions,
        "peacock": .subscriptions,
        "apple tv": .subscriptions,
        "icloud": .subscriptions,
        "dropbox": .subscriptions,
        "gym": .health,
        "planet fitness": .health,
        "equinox": .health,
        "pharmacy": .health,
        "cvs": .health,
        "walgreens": .health,
        "doctor": .health,
        "dentist": .health,
        "hospital": .health,
        "cinema": .entertainment,
        "movie": .entertainment,
        "concert": .entertainment,
        "amc": .entertainment,
        "regal": .entertainment,
        "steam": .entertainment,
        "playstation": .entertainment,
        "xbox": .entertainment,
        "nintendo": .entertainment,
        "electric": .bills,
        "water bill": .bills,
        "internet": .bills,
        "phone bill": .bills,
        "rent": .bills,
        "mortgage": .bills,
        "insurance": .bills,
        "comcast": .bills,
        "verizon": .bills,
        "at&t": .bills,
        "t-mobile": .bills,
        "udemy": .education,
        "coursera": .education,
        "tuition": .education,
        "textbook": .education,
        "skillshare": .education,
        "airline": .travel,
        "hotel": .travel,
        "airbnb": .travel,
        "booking.com": .travel,
        "expedia": .travel,
        "flight": .travel,
        "sephora": .personalCare,
        "ulta": .personalCare,
        "salon": .personalCare,
        "barber": .personalCare,
        "haircut": .personalCare,
        "spa": .personalCare,
    ]

    func suggestCategories(
        note: String,
        amount: Double?,
        date: Date,
        recentCategories: [TransactionCategory],
        userMappings: [MerchantCategoryMapping]
    ) -> [TransactionCategory] {
        var scored: [TransactionCategory: Double] = [:]
        let lowered = note.lowercased().trimmingCharacters(in: .whitespaces)

        if !lowered.isEmpty {
            for mapping in userMappings {
                if lowered.contains(mapping.merchantKeyword) {
                    scored[mapping.category, default: 0] += 10
                }
            }

            for (keyword, cat) in Self.builtInMappings {
                if lowered.contains(keyword) {
                    scored[cat, default: 0] += 8
                }
            }
        }

        if let amt = amount, amt > 0 {
            let amountSuggestions = amountHeuristic(amt)
            for (cat, weight) in amountSuggestions {
                scored[cat, default: 0] += weight
            }
        }

        let timeSuggestions = timeOfDayHeuristic(date)
        for (cat, weight) in timeSuggestions {
            scored[cat, default: 0] += weight
        }

        let daySuggestions = dayOfWeekHeuristic(date)
        for (cat, weight) in daySuggestions {
            scored[cat, default: 0] += weight
        }

        for (i, cat) in recentCategories.prefix(5).enumerated() {
            scored[cat, default: 0] += Double(3 - i) * 0.5
        }

        let sorted = scored
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        return Array(sorted)
    }

    func matchMerchant(
        note: String,
        userMappings: [MerchantCategoryMapping]
    ) -> TransactionCategory? {
        let lowered = note.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lowered.isEmpty else { return nil }

        for mapping in userMappings {
            if lowered.contains(mapping.merchantKeyword) {
                return mapping.category
            }
        }

        for (keyword, cat) in Self.builtInMappings {
            if lowered.contains(keyword) {
                return cat
            }
        }
        return nil
    }

    func learnMapping(
        merchantKeyword: String,
        category: TransactionCategory,
        context: ModelContext
    ) {
        let lowered = merchantKeyword.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lowered.isEmpty else { return }

        let descriptor = FetchDescriptor<MerchantCategoryMapping>(
            predicate: #Predicate { $0.merchantKeyword == lowered }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.categoryRawValue = category.rawValue
        } else {
            let mapping = MerchantCategoryMapping(
                merchantKeyword: lowered,
                category: category,
                isUserDefined: true
            )
            context.insert(mapping)
        }
    }

    func applyCategoryRetroactively(
        merchantKeyword: String,
        newCategory: TransactionCategory,
        context: ModelContext
    ) {
        let lowered = merchantKeyword.lowercased()
        guard !lowered.isEmpty else { return }

        let descriptor = FetchDescriptor<Transaction>()
        guard let transactions = try? context.fetch(descriptor) else { return }

        for transaction in transactions {
            let txNote = transaction.note.lowercased()
            if txNote.contains(lowered) {
                transaction.category = newCategory.rawValue
            }
        }
    }

    private func amountHeuristic(_ amount: Double) -> [(TransactionCategory, Double)] {
        switch amount {
        case 0..<8:
            return [(.food, 3), (.transport, 1)]
        case 8..<20:
            return [(.food, 2), (.entertainment, 1.5), (.personalCare, 1)]
        case 20..<60:
            return [(.shopping, 2), (.entertainment, 1.5), (.health, 1)]
        case 60..<150:
            return [(.shopping, 2), (.bills, 1.5), (.subscriptions, 1)]
        case 150..<500:
            return [(.bills, 2.5), (.travel, 1.5), (.shopping, 1)]
        default:
            return [(.bills, 3), (.travel, 2), (.home, 1)]
        }
    }

    private func timeOfDayHeuristic(_ date: Date) -> [(TransactionCategory, Double)] {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<10:
            return [(.food, 2), (.transport, 1)]
        case 10..<14:
            return [(.food, 1.5), (.shopping, 1)]
        case 14..<18:
            return [(.shopping, 1.5), (.personalCare, 1)]
        case 18..<22:
            return [(.entertainment, 1.5), (.food, 1)]
        default:
            return [(.entertainment, 1)]
        }
    }

    private func dayOfWeekHeuristic(_ date: Date) -> [(TransactionCategory, Double)] {
        let weekday = Calendar.current.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend {
            return [(.entertainment, 1.5), (.food, 1), (.shopping, 0.5)]
        } else {
            return [(.food, 1), (.transport, 0.5)]
        }
    }
}
