import Foundation
import SwiftData

@Observable
class GachaEngine {
    private(set) var pullsSinceLastEpic: Int = 0
    private(set) var pullsSinceLastLegendary: Int = 0
    private(set) var totalPulls: Int = 0
    private(set) var totalEssence: Int = 0

    private let legendaryHardPity = 50
    private let legendarySoftPityStart = 35
    private let epicHardPity = 20
    private let epicSoftPityStart = 15

    func syncFromState(_ state: GachaState) {
        pullsSinceLastEpic = state.pullsSinceLastEpic
        pullsSinceLastLegendary = state.pullsSinceLastLegendary
        totalPulls = state.totalPulls
        totalEssence = state.totalEssence
    }

    func saveToState(_ state: GachaState) {
        state.pullsSinceLastEpic = pullsSinceLastEpic
        state.pullsSinceLastLegendary = pullsSinceLastLegendary
        state.totalPulls = totalPulls
        state.totalEssence = totalEssence
    }

    func pull() -> CardDefinition {
        let rarity = determineRarity()
        return selectCard(rarity: rarity)
    }

    func essenceReward(for rarity: CardRarity) -> Int {
        switch rarity {
        case .common: return 5
        case .uncommon: return 10
        case .rare: return 25
        case .epic: return 50
        case .legendary: return 100
        }
    }

    func addEssence(_ amount: Int) {
        totalEssence += amount
    }

    func resetLegendaryPity() {
        pullsSinceLastLegendary = 0
        pullsSinceLastEpic = 0
    }

    func resetEpicPity() {
        pullsSinceLastEpic = 0
    }

    func spendEssence(_ amount: Int) -> Bool {
        guard totalEssence >= amount else { return false }
        totalEssence -= amount
        return true
    }

    func evolutionCost(for rarity: CardRarity) -> Int {
        switch rarity {
        case .common: return 15
        case .uncommon: return 30
        case .rare: return 60
        case .epic: return 100
        case .legendary: return 999
        }
    }

    static func nextRarity(from current: String) -> CardRarity? {
        switch current {
        case "Common": return .uncommon
        case "Uncommon": return .rare
        case "Rare": return .epic
        case "Epic": return .legendary
        default: return nil
        }
    }

    static func nextRarityName(from current: String) -> String {
        nextRarity(from: current)?.rawValue ?? "MAX"
    }

    private func determineRarity() -> CardRarity {
        pullsSinceLastLegendary += 1
        pullsSinceLastEpic += 1
        totalPulls += 1

        if pullsSinceLastLegendary >= legendaryHardPity {
            pullsSinceLastLegendary = 0
            pullsSinceLastEpic = 0
            return .legendary
        }

        if pullsSinceLastEpic >= epicHardPity {
            pullsSinceLastEpic = 0
            return .epic
        }

        var legendaryBoost: Double = 0
        if pullsSinceLastLegendary > legendarySoftPityStart {
            let pullsIntoPity = Double(pullsSinceLastLegendary - legendarySoftPityStart)
            let maxPityPulls = Double(legendaryHardPity - legendarySoftPityStart)
            legendaryBoost = 0.30 * (pullsIntoPity / maxPityPulls)
        }

        var epicBoost: Double = 0
        if pullsSinceLastEpic > epicSoftPityStart {
            let pullsIntoPity = Double(pullsSinceLastEpic - epicSoftPityStart)
            let maxPityPulls = Double(epicHardPity - epicSoftPityStart)
            epicBoost = 0.20 * (pullsIntoPity / maxPityPulls)
        }

        let adjustedLegendary = min(0.02 + legendaryBoost, 0.50)
        let adjustedEpic = min(0.08 + epicBoost, 0.40)

        let roll = Double.random(in: 0...1)

        if roll < adjustedLegendary {
            pullsSinceLastLegendary = 0
            pullsSinceLastEpic = 0
            return .legendary
        } else if roll < adjustedLegendary + adjustedEpic {
            pullsSinceLastEpic = 0
            return .epic
        } else if roll < adjustedLegendary + adjustedEpic + 0.15 {
            return .rare
        } else if roll < adjustedLegendary + adjustedEpic + 0.15 + 0.30 {
            return .uncommon
        } else {
            return .common
        }
    }

    private func selectCard(rarity: CardRarity) -> CardDefinition {
        let pool = CardDatabase.cards(forRarity: rarity)
        return pool.randomElement() ?? CardDatabase.allCards[0]
    }
}
