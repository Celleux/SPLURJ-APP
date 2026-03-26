import Foundation
import SwiftData

@Model
class MerchantCategoryMapping {
    var merchantKeyword: String
    var categoryRawValue: String
    var isUserDefined: Bool
    var createdAt: Date

    init(merchantKeyword: String, category: TransactionCategory, isUserDefined: Bool = false) {
        self.merchantKeyword = merchantKeyword.lowercased().trimmingCharacters(in: .whitespaces)
        self.categoryRawValue = category.rawValue
        self.isUserDefined = isUserDefined
        self.createdAt = Date()
    }

    var category: TransactionCategory {
        TransactionCategory(rawValue: categoryRawValue) ?? .other
    }
}
