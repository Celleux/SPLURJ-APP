import SwiftUI

struct EvolveCardView: View {
    let card: Achievement
    let essenceAvailable: Int
    let onEvolve: () -> Void

    private var currentRarity: CardRarity? {
        CardRarity(rawValue: card.rarity)
    }

    private var essenceCost: Int {
        guard let rarity = currentRarity else { return 999 }
        switch rarity {
        case .common: return 15
        case .uncommon: return 30
        case .rare: return 60
        case .epic: return 100
        case .legendary: return 999
        }
    }

    private var canEvolve: Bool {
        !card.isMaxEvolved
        && currentRarity != .legendary
        && essenceAvailable >= essenceCost
    }

    private var isMaxed: Bool {
        card.isMaxEvolved || currentRarity == .legendary
    }

    private var nextName: String {
        GachaEngine.nextRarityName(from: card.rarity)
    }

    private var nextColor: Color {
        GachaEngine.nextRarity(from: card.rarity)?.color ?? Theme.textMuted
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.gold)
                Text("Evolve")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            if isMaxed {
                Text("This card is at maximum evolution")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textMuted)
            } else {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Current")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                        Text(card.rarity)
                            .font(Typography.headingSmall)
                            .foregroundStyle(currentRarity?.color ?? .white)
                    }

                    Image(systemName: "arrow.right")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.accent)

                    VStack(spacing: 4) {
                        Text("Evolved")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                        Text(nextName)
                            .font(Typography.headingSmall)
                            .foregroundStyle(nextColor)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.gold)
                    Text("\(essenceCost) Essence")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                    Text("(You have: \(essenceAvailable))")
                        .font(Typography.bodySmall)
                        .foregroundStyle(essenceAvailable >= essenceCost ? Theme.accent : Theme.textMuted)
                }

                Button {
                    onEvolve()
                } label: {
                    Text("EVOLVE")
                        .font(Typography.headingSmall)
                        .foregroundStyle(canEvolve ? Theme.background : Theme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canEvolve ? Theme.accent : Theme.surface, in: .rect(cornerRadius: 12))
                }
                .disabled(!canEvolve)
            }
        }
        .padding(16)
        .splurjCard(.interactive)
    }
}
