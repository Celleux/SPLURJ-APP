import Foundation
import SwiftData

@Model
class QuizResult {
    var answer1: String
    var answer2: String
    var answer3: String
    var answer4: String
    var answer5: String
    var personalityType: String
    var createdAt: Date

    init(answers: [String]) {
        self.answer1 = answers.count > 0 ? answers[0] : ""
        self.answer2 = answers.count > 1 ? answers[1] : ""
        self.answer3 = answers.count > 2 ? answers[2] : ""
        self.answer4 = answers.count > 3 ? answers[3] : ""
        self.answer5 = answers.count > 4 ? answers[4] : ""
        self.createdAt = Date()
        self.personalityType = QuizResult.computePersonality(answers: answers).rawValue
    }

    var personality: MoneyPersonality {
        MoneyPersonality(rawValue: personalityType) ?? .builder
    }

    static func computePersonality(answers: [String]) -> MoneyPersonality {
        var scores: [MoneyPersonality: Int] = [:]
        for p in MoneyPersonality.allCases { scores[p] = 0 }

        let mapping: [[String: MoneyPersonality]] = [
            ["Save it all": .saver, "Spend on something fun": .hustler, "Invest it": .builder, "Share it with others": .generous],
            ["Budget planning": .saver, "Shopping therapy": .hustler, "Working on a side hustle": .builder, "Free activities with friends": .minimalist],
            ["Secure": .saver, "Free": .minimalist, "Powerful": .builder, "Anxious": .generous],
            ["Always saves": .saver, "Treats everyone": .generous, "Invests in experiences": .minimalist, "Finds the best deals": .hustler],
            ["Patience": .saver, "Generosity": .generous, "Risk-taking": .hustler, "Discipline": .builder]
        ]

        for (i, answer) in answers.enumerated() where i < mapping.count {
            if let personality = mapping[i][answer] {
                scores[personality, default: 0] += 1
            }
        }

        let sorted = scores.sorted { $0.value > $1.value }
        return sorted.first?.key ?? .builder
    }
}
