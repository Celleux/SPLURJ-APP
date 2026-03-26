import SwiftUI

nonisolated struct FinancialDNA: Codable, Equatable, Sendable {
    var spendingAxis: Double
    var emotionalAxis: Double
    var riskAxis: Double
    var socialAxis: Double

    var primaryArchetype: FinancialArchetype {
        let scores = archetypeScores
        return scores.max(by: { $0.1 < $1.1 })?.0 ?? .guardian
    }

    var secondaryArchetype: FinancialArchetype {
        let sorted = archetypeScores.sorted { $0.1 > $1.1 }
        return sorted.count > 1 ? sorted[1].0 : .guardian
    }

    var superpower: String {
        let axes = [
            (spendingAxis > 0.5 ? "Discovery" : "Discipline", abs(spendingAxis - 0.5) * 2),
            (emotionalAxis > 0.5 ? "Logic" : "Intuition", abs(emotionalAxis - 0.5) * 2),
            (riskAxis > 0.5 ? "Courage" : "Caution", abs(riskAxis - 0.5) * 2),
            (socialAxis > 0.5 ? "Generosity" : "Independence", abs(socialAxis - 0.5) * 2)
        ]
        return axes.max(by: { $0.1 < $1.1 })?.0 ?? "Balance"
    }

    var vulnerability: String {
        let vulns: [(String, Double)] = [
            ("Impulse spending under stress", spendingAxis * (1.0 - emotionalAxis)),
            ("Analysis paralysis", emotionalAxis * (1.0 - riskAxis)),
            ("Over-lending to others", socialAxis * (1.0 - emotionalAxis)),
            ("Avoiding financial reality", (1.0 - emotionalAxis) * (1.0 - riskAxis)),
            ("Risk without safety net", riskAxis * spendingAxis),
        ]
        return vulns.max(by: { $0.1 < $1.1 })?.0 ?? "None detected"
    }

    private var archetypeScores: [(FinancialArchetype, Double)] {
        [
            (.guardian, (1.0 - spendingAxis) * 0.4 + (1.0 - riskAxis) * 0.3 + emotionalAxis * 0.15 + (1.0 - socialAxis) * 0.15),
            (.strategist, emotionalAxis * 0.35 + (1.0 - riskAxis) * 0.25 + (1.0 - spendingAxis) * 0.2 + (1.0 - socialAxis) * 0.2),
            (.adventurer, spendingAxis * 0.3 + riskAxis * 0.3 + (1.0 - emotionalAxis) * 0.2 + socialAxis * 0.2),
            (.empath, socialAxis * 0.35 + (1.0 - emotionalAxis) * 0.25 + (1.0 - riskAxis) * 0.2 + spendingAxis * 0.2),
            (.visionary, riskAxis * 0.35 + emotionalAxis * 0.25 + spendingAxis * 0.2 + (1.0 - socialAxis) * 0.2),
        ]
    }

    static let `default` = FinancialDNA(spendingAxis: 0.5, emotionalAxis: 0.5, riskAxis: 0.5, socialAxis: 0.5)
}

nonisolated enum FinancialArchetype: String, Codable, CaseIterable, Sendable {
    case guardian = "The Guardian"
    case strategist = "The Strategist"
    case adventurer = "The Adventurer"
    case empath = "The Empath"
    case visionary = "The Visionary"

    var icon: String {
        switch self {
        case .guardian: "shield.lefthalf.filled"
        case .strategist: "brain.head.profile.fill"
        case .adventurer: "flame.fill"
        case .empath: "heart.circle.fill"
        case .visionary: "scope"
        }
    }

    var color: Color {
        switch self {
        case .guardian: Theme.accent
        case .strategist: Theme.axisEmotional
        case .adventurer: Theme.axisRisk
        case .empath: Theme.axisSocial
        case .visionary: Theme.lavender
        }
    }

    var secondaryColor: Color {
        switch self {
        case .guardian: Theme.accentDim
        case .strategist: Color(hex: 0x3B82F6)
        case .adventurer: Color(hex: 0xF59E0B)
        case .empath: Color(hex: 0xEC4899)
        case .visionary: Color(hex: 0x8B5CF6)
        }
    }

    var tagline: String {
        switch self {
        case .guardian: "Your money is safe with you."
        case .strategist: "You don't spend. You optimize."
        case .adventurer: "Life is the ROI."
        case .empath: "You invest in people."
        case .visionary: "You bet on tomorrow."
        }
    }

    var description: String {
        switch self {
        case .guardian:
            "You protect what's yours with fierce discipline. Your savings account is your armor, and every dollar saved is a brick in your fortress. You don't panic-buy, you panic-save. The world feels safer when your emergency fund is full. Your challenge isn't saving — it's letting yourself enjoy what you've built."
        case .strategist:
            "You see money as a system to be optimized. Where others see a purchase, you see an equation: cost-per-use, opportunity cost, compound interest over 30 years. Spreadsheets calm you. Budget apps are your meditation. Your challenge isn't tracking — it's trusting your gut when the numbers aren't clear."
        case .adventurer:
            "Money is fuel for living. You'd rather have a passport full of stamps than a savings account full of zeros. You're the friend who finds the $5 street food that tastes like a $50 dinner. You're resourceful, not reckless — but your bank account might disagree. Your challenge is building a safety net without feeling caged."
        case .empath:
            "You feel other people's needs before your own. The friend who always picks up the tab, loans without asking, gives gifts that hit different. Your generosity builds bonds that money can't buy — but sometimes it drains the account that keeps you safe. Your challenge is protecting your own oxygen mask first."
        case .visionary:
            "You don't save for rainy days — you invest in sunny ones. Side hustles, stocks, crypto, that business idea at 2am. You see money as potential energy waiting to be converted into something bigger. Your challenge is balancing the portfolio of dreams with the reality of rent."
        }
    }

    var strengths: [String] {
        switch self {
        case .guardian: ["Emergency fund builder", "Impulse resistant", "Long-term thinker", "Debt-free mindset"]
        case .strategist: ["Data-driven decisions", "Budget mastery", "Pattern recognition", "Optimization genius"]
        case .adventurer: ["Resourceful spending", "Experience-rich life", "Negotiation skills", "Opportunity radar"]
        case .empath: ["Deep relationships", "Community builder", "Generous spirit", "Trust magnet"]
        case .visionary: ["Income growth", "Risk intelligence", "Entrepreneurial drive", "Wealth building"]
        }
    }

    var blindSpots: [String] {
        switch self {
        case .guardian: ["Money hoarding anxiety", "Guilt when spending on joy", "Missing investment growth"]
        case .strategist: ["Analysis paralysis", "Ignoring emotional needs", "Delayed gratification burnout"]
        case .adventurer: ["Safety net gaps", "Subscription creep", "YOLO regret cycles"]
        case .empath: ["Over-lending", "Resentment from unreciprocated giving", "Saying yes when broke"]
        case .visionary: ["All eggs in one basket", "Neglecting basics for bets", "Shiny object syndrome"]
        }
    }

    var preferredQuestCategories: [String] {
        switch self {
        case .guardian: ["spendingDefense", "financialLiteracy"]
        case .strategist: ["financialLiteracy", "moneyRecovery"]
        case .adventurer: ["incomeEarning", "moneyRecovery"]
        case .empath: ["socialQuests", "generosity"]
        case .visionary: ["incomeEarning", "financialLiteracy"]
        }
    }
}
