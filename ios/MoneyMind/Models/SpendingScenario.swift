import SwiftUI

nonisolated enum DNAAxis: Sendable {
    case spending, emotional, risk, social
}

nonisolated enum SwipeDirection: Sendable {
    case left, right
}

struct SpendingScenario: Identifiable {
    let id: Int
    let text: String
    let icon: String
    let axis: DNAAxis
    let axisLabel: String
    let axisColor: Color
    let leftLabel: String
    let rightLabel: String
    let leftShort: String
    let rightShort: String

    static let all: [SpendingScenario] = [
        SpendingScenario(
            id: 0,
            text: "Your friend invites you on a last-minute weekend trip. $300.",
            icon: "airplane.departure",
            axis: .spending,
            axisLabel: "Spending Style",
            axisColor: Theme.accent,
            leftLabel: "I'd love to but I'll pass",
            rightLabel: "Life's too short. I'm in.",
            leftShort: "PASS",
            rightShort: "I'M IN"
        ),
        SpendingScenario(
            id: 1,
            text: "You're having a bad day. Your comfort purchase is calling.",
            icon: "cart.fill",
            axis: .emotional,
            axisLabel: "Money Emotions",
            axisColor: Color(hex: 0x60A5FA),
            leftLabel: "I'll journal about it instead",
            rightLabel: "I deserve this. Add to cart.",
            leftShort: "RESIST",
            rightShort: "TREAT"
        ),
        SpendingScenario(
            id: 2,
            text: "A side hustle opportunity appears. It requires $500 upfront.",
            icon: "lightbulb.fill",
            axis: .risk,
            axisLabel: "Risk Profile",
            axisColor: Color(hex: 0xFB923C),
            leftLabel: "Too risky right now",
            rightLabel: "Could be worth 10x. Let's go.",
            leftShort: "TOO RISKY",
            rightShort: "LET'S GO"
        ),
        SpendingScenario(
            id: 3,
            text: "Your friend is $200 short on rent this month.",
            icon: "person.2.fill",
            axis: .social,
            axisLabel: "Social Money",
            axisColor: Color(hex: 0xF472B6),
            leftLabel: "I sympathize but I can't risk it",
            rightLabel: "Already sending it.",
            leftShort: "CAN'T",
            rightShort: "SENT"
        ),
        SpendingScenario(
            id: 4,
            text: "You get a $1,000 bonus at work.",
            icon: "banknote.fill",
            axis: .spending,
            axisLabel: "Spending Style",
            axisColor: Theme.accent,
            leftLabel: "Straight to savings.",
            rightLabel: "New phone + nice dinner.",
            leftShort: "SAVE",
            rightShort: "SPEND"
        ),
        SpendingScenario(
            id: 5,
            text: "Your partner wants to merge finances.",
            icon: "heart.text.clipboard.fill",
            axis: .social,
            axisLabel: "Social Money",
            axisColor: Color(hex: 0xF472B6),
            leftLabel: "My money is my business",
            rightLabel: "Let's build something together",
            leftShort: "MINE",
            rightShort: "OURS"
        ),
        SpendingScenario(
            id: 6,
            text: "A stock you follow just dropped 40%.",
            icon: "chart.line.downtrend.xyaxis",
            axis: .risk,
            axisLabel: "Risk Profile",
            axisColor: Color(hex: 0xFB923C),
            leftLabel: "Sell everything. Cut losses.",
            rightLabel: "Buy the dip. I've done the research.",
            leftShort: "SELL",
            rightShort: "BUY"
        ),
        SpendingScenario(
            id: 7,
            text: "You just realized you spent $400 on food delivery this month.",
            icon: "takeoutbag.and.cup.and.straw.fill",
            axis: .emotional,
            axisLabel: "Money Emotions",
            axisColor: Color(hex: 0x60A5FA),
            leftLabel: "Time for a spreadsheet",
            rightLabel: "That's who I am right now.",
            leftShort: "SYSTEM",
            rightShort: "ACCEPT"
        ),
    ]
}
