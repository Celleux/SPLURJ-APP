import Foundation

nonisolated enum PGSIQuestions: Sendable {
    static let questions: [String] = [
        "Have you bet more than you could really afford to lose?",
        "Have you needed to gamble with larger amounts of money to get the same feeling of excitement?",
        "When you gambled, did you go back another day to try to win back the money you lost?",
        "Have you borrowed money or sold anything to get money to gamble?",
        "Have you felt that you might have a problem with gambling?",
        "Has gambling caused you any health problems, including stress or anxiety?",
        "Have people criticized your betting or told you that you had a gambling problem?",
        "Has your gambling caused any financial problems for you or your household?",
        "Have you felt guilty about the way you gamble or what happens when you gamble?"
    ]

    static let answerOptions: [(label: String, value: Int)] = [
        ("Never", 0),
        ("Sometimes", 1),
        ("Most of the time", 2),
        ("Almost always", 3)
    ]

    static func riskLevel(for score: Int) -> (label: String, color: String) {
        switch score {
        case 0: return ("Non-problem", "green")
        case 1...2: return ("Low risk", "teal")
        case 3...7: return ("Moderate risk", "gold")
        default: return ("Problem gambling", "red")
        }
    }
}
