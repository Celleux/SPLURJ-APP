import Foundation

nonisolated struct CardDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    let tip: String
    let set: CardSet
    let rarity: CardRarity
}

enum CardDatabase {
    static let totalCards: Int = allCards.count

    static func card(byID id: String) -> CardDefinition? {
        allCards.first { $0.id == id }
    }

    static func cards(forSet set: CardSet) -> [CardDefinition] {
        allCards.filter { $0.set == set }
    }

    static func cards(forRarity rarity: CardRarity) -> [CardDefinition] {
        allCards.filter { $0.rarity == rarity }
    }

    static let allCards: [CardDefinition] = saversGuild + compoundInterest + budgetWarriors + debtSlayers + impulseDefenders

    // MARK: - The Savers Guild

    private static let saversGuild: [CardDefinition] = [
        CardDefinition(id: "SG-001", name: "Penny Guardian", tip: "Every cent saved is a cent earned", set: .saversGuild, rarity: .common),
        CardDefinition(id: "SG-002", name: "Piggy Bank Knight", tip: "Start small, dream big", set: .saversGuild, rarity: .common),
        CardDefinition(id: "SG-003", name: "Coupon Collector", tip: "Smart shopping is a superpower", set: .saversGuild, rarity: .common),
        CardDefinition(id: "SG-004", name: "Thrift Finder", tip: "One person's trash is another's treasure", set: .saversGuild, rarity: .common),
        CardDefinition(id: "SG-005", name: "Budget Sentinel", tip: "A budget is telling your money where to go", set: .saversGuild, rarity: .uncommon),
        CardDefinition(id: "SG-006", name: "Savings Streak Mage", tip: "Consistency beats intensity every time", set: .saversGuild, rarity: .uncommon),
        CardDefinition(id: "SG-007", name: "The Comparison Shopper", tip: "Never pay full price when patience pays", set: .saversGuild, rarity: .uncommon),
        CardDefinition(id: "SG-008", name: "Emergency Fund Shield", tip: "3-6 months expenses = financial armor", set: .saversGuild, rarity: .rare),
        CardDefinition(id: "SG-009", name: "The Automator", tip: "Set it and forget it: automate your savings", set: .saversGuild, rarity: .rare),
        CardDefinition(id: "SG-010", name: "The Compound Oracle", tip: "Time + patience = exponential growth", set: .saversGuild, rarity: .epic),
        CardDefinition(id: "SG-011", name: "The Vault Master", tip: "Master of savings, guardian of wealth", set: .saversGuild, rarity: .legendary),
    ]

    // MARK: - Masters of Compound Interest

    private static let compoundInterest: [CardDefinition] = [
        CardDefinition(id: "CI-001", name: "Interest Seedling", tip: "$1 today could be $10 in 30 years", set: .compoundInterest, rarity: .common),
        CardDefinition(id: "CI-002", name: "The Rule of 72", tip: "Divide 72 by your rate = years to double", set: .compoundInterest, rarity: .common),
        CardDefinition(id: "CI-003", name: "Dividend Drop", tip: "Let your money make money while you sleep", set: .compoundInterest, rarity: .common),
        CardDefinition(id: "CI-004", name: "The Patient Investor", tip: "Time in the market beats timing the market", set: .compoundInterest, rarity: .common),
        CardDefinition(id: "CI-005", name: "Compounding Clock", tip: "Start now. The best time was yesterday", set: .compoundInterest, rarity: .uncommon),
        CardDefinition(id: "CI-006", name: "Reinvestment Engine", tip: "Roll returns back in and watch them grow", set: .compoundInterest, rarity: .uncommon),
        CardDefinition(id: "CI-007", name: "Dollar Cost Warrior", tip: "Buy regularly, ignore the noise", set: .compoundInterest, rarity: .uncommon),
        CardDefinition(id: "CI-008", name: "The Snowball Effect", tip: "Small gains stack into avalanches", set: .compoundInterest, rarity: .rare),
        CardDefinition(id: "CI-009", name: "Index Fund Sage", tip: "Why pick needles when you can buy the haystack?", set: .compoundInterest, rarity: .rare),
        CardDefinition(id: "CI-010", name: "Generational Wealth Architect", tip: "Build wealth that outlives you", set: .compoundInterest, rarity: .epic),
        CardDefinition(id: "CI-011", name: "The Eighth Wonder", tip: "Compound interest: the 8th wonder of the world", set: .compoundInterest, rarity: .legendary),
    ]

    // MARK: - Budget Warriors

    private static let budgetWarriors: [CardDefinition] = [
        CardDefinition(id: "BW-001", name: "The Envelope Method", tip: "Cash in envelopes = spending limits that work", set: .budgetWarriors, rarity: .common),
        CardDefinition(id: "BW-002", name: "Subscription Slayer", tip: "Audit subscriptions monthly. Cancel ruthlessly.", set: .budgetWarriors, rarity: .common),
        CardDefinition(id: "BW-003", name: "Meal Prep Champion", tip: "Cook once, eat all week, save hundreds", set: .budgetWarriors, rarity: .common),
        CardDefinition(id: "BW-004", name: "The 24-Hour Rule", tip: "Wait 24 hours before any impulse buy", set: .budgetWarriors, rarity: .common),
        CardDefinition(id: "BW-005", name: "Zero-Based Budgeter", tip: "Every dollar gets a job. No idle money.", set: .budgetWarriors, rarity: .uncommon),
        CardDefinition(id: "BW-006", name: "The No-Spend Warrior", tip: "No-spend days are power moves", set: .budgetWarriors, rarity: .uncommon),
        CardDefinition(id: "BW-007", name: "Needs vs Wants Filter", tip: "Ask: will this matter in 30 days?", set: .budgetWarriors, rarity: .uncommon),
        CardDefinition(id: "BW-008", name: "The 50/30/20 Master", tip: "50% needs, 30% wants, 20% savings", set: .budgetWarriors, rarity: .rare),
        CardDefinition(id: "BW-009", name: "Cash Flow Commander", tip: "Know exactly where every dollar goes", set: .budgetWarriors, rarity: .rare),
        CardDefinition(id: "BW-010", name: "The Frugal Innovator", tip: "Frugality is creative, not restrictive", set: .budgetWarriors, rarity: .epic),
        CardDefinition(id: "BW-011", name: "The Budget Grandmaster", tip: "Complete financial control is true freedom", set: .budgetWarriors, rarity: .legendary),
    ]

    // MARK: - Debt Slayers

    private static let debtSlayers: [CardDefinition] = [
        CardDefinition(id: "DS-001", name: "Minimum Payment Trap", tip: "Minimum payments maximize bank profits, not yours", set: .debtSlayers, rarity: .common),
        CardDefinition(id: "DS-002", name: "The Snowball Starter", tip: "Pay off smallest debt first for momentum", set: .debtSlayers, rarity: .common),
        CardDefinition(id: "DS-003", name: "Credit Score Scout", tip: "Know your score. Check it monthly. Guard it.", set: .debtSlayers, rarity: .common),
        CardDefinition(id: "DS-004", name: "Interest Rate Hunter", tip: "Lower your rates or refinance aggressively", set: .debtSlayers, rarity: .common),
        CardDefinition(id: "DS-005", name: "The Avalanche Method", tip: "Highest interest first = mathematically optimal", set: .debtSlayers, rarity: .uncommon),
        CardDefinition(id: "DS-006", name: "Debt Consolidator", tip: "One payment, one rate, one plan", set: .debtSlayers, rarity: .uncommon),
        CardDefinition(id: "DS-007", name: "The Balance Transfer", tip: "0% APR windows are tactical weapons", set: .debtSlayers, rarity: .uncommon),
        CardDefinition(id: "DS-008", name: "Debt-Free Declaration", tip: "The day you owe nothing is the day you're free", set: .debtSlayers, rarity: .rare),
        CardDefinition(id: "DS-009", name: "The Negotiator", tip: "Call and negotiate. Most lenders will deal.", set: .debtSlayers, rarity: .rare),
        CardDefinition(id: "DS-010", name: "Financial Freedom Fighter", tip: "Debt-free living is the ultimate flex", set: .debtSlayers, rarity: .epic),
        CardDefinition(id: "DS-011", name: "The Debt Destroyer", tip: "Conquered every debt, emerged invincible", set: .debtSlayers, rarity: .legendary),
    ]

    // MARK: - Impulse Defenders

    private static let impulseDefenders: [CardDefinition] = [
        CardDefinition(id: "ID-001", name: "The Pause Button", tip: "Take 3 deep breaths before any purchase", set: .impulseDefenders, rarity: .common),
        CardDefinition(id: "ID-002", name: "Cart Abandoner", tip: "Fill the cart. Close the app. Feel the power.", set: .impulseDefenders, rarity: .common),
        CardDefinition(id: "ID-003", name: "The Unsubscriber", tip: "Unsubscribe from every marketing email", set: .impulseDefenders, rarity: .common),
        CardDefinition(id: "ID-004", name: "Window Shopping Shield", tip: "Look, don't touch. Dopamine is free.", set: .impulseDefenders, rarity: .common),
        CardDefinition(id: "ID-005", name: "The HALT Check", tip: "Hungry? Angry? Lonely? Tired? Don't buy.", set: .impulseDefenders, rarity: .uncommon),
        CardDefinition(id: "ID-006", name: "Wish List Warden", tip: "Add to list, not to cart. Revisit in 30 days.", set: .impulseDefenders, rarity: .uncommon),
        CardDefinition(id: "ID-007", name: "The Dopamine Detective", tip: "Identify your triggers. Disarm them.", set: .impulseDefenders, rarity: .uncommon),
        CardDefinition(id: "ID-008", name: "Impulse Resistance Master", tip: "Every resisted impulse is money saved", set: .impulseDefenders, rarity: .rare),
        CardDefinition(id: "ID-009", name: "The Mindful Spender", tip: "Spend with intention, not emotion", set: .impulseDefenders, rarity: .rare),
        CardDefinition(id: "ID-010", name: "The Craving Crusher", tip: "Turn cravings into savings. Every. Single. Time.", set: .impulseDefenders, rarity: .epic),
        CardDefinition(id: "ID-011", name: "The Impulse Sovereign", tip: "Absolute mastery over spending urges", set: .impulseDefenders, rarity: .legendary),
    ]
}
