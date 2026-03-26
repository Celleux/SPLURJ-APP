import Foundation
import SwiftData

@Model
class PGSIAssessment {
    var date: Date
    var answers: [Int]
    var totalScore: Int

    init(answers: [Int] = Array(repeating: 0, count: 9)) {
        self.date = Date()
        self.answers = answers
        self.totalScore = answers.reduce(0, +)
    }
}
