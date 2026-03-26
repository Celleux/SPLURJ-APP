import SwiftUI
import SwiftData

struct CardDetailView: View {
    let card: CardDefinition
    let collectedInfo: Achievement?
    @Environment(\.dismiss) private var dismiss
    @Query private var gachaStates: [GachaState]
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var showEvolveSuccess: Bool = false

    private var gachaState: GachaState? { gachaStates.first }
    private var essenceAvailable: Int { gachaState?.totalEssence ?? 0 }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)

                    CardArtView(card: card)
                        .frame(width: 260, height: 370)
                        .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
                        .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    rotationY = value.translation.width / 10
                                    rotationX = -value.translation.height / 10
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        rotationX = 0
                                        rotationY = 0
                                    }
                                }
                        )
                        .shadow(color: card.rarity.color.opacity(0.3), radius: 24)

                    VStack(spacing: 8) {
                        Text(card.name)
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textPrimary)

                        HStack(spacing: 6) {
                            Text(card.rarity.label)
                            Text(card.rarity.rawValue)
                        }
                        .font(Typography.headingSmall)
                        .foregroundStyle(card.rarity.color)

                        Text(card.set.rawValue)
                            .font(Typography.bodySmall)
                            .foregroundStyle(card.set.accentColor.opacity(0.7))

                        Text("\"\(card.tip)\"")
                            .font(Typography.bodyMedium)
                            .italic()
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)

                        if let info = collectedInfo {
                            HStack(spacing: 16) {
                                if info.duplicateCount > 0 {
                                    Label("x\(info.duplicateCount + 1)", systemImage: "square.stack.fill")
                                        .font(Typography.bodySmall)
                                        .foregroundStyle(Theme.textMuted)
                                }
                                if info.evolutionLevel > 0 {
                                    Label("Evo +\(info.evolutionLevel)", systemImage: "sparkles")
                                        .font(Typography.bodySmall)
                                        .foregroundStyle(Theme.gold)
                                }
                                Label(info.obtainedAt.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                                    .font(Typography.bodySmall)
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .padding(.top, 8)
                        }
                    }

                    if let info = collectedInfo {
                        EvolveCardView(card: info, essenceAvailable: essenceAvailable) {
                            evolveCard(info)
                        }
                        .padding(.horizontal, 20)
                    }

                    if showEvolveSuccess {
                        Text("Evolution successful")
                            .font(Typography.labelMedium)
                            .foregroundStyle(Theme.accent)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Button("Close") { dismiss() }
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.accent)
                        .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            if let info = collectedInfo, info.isNew {
                info.isNew = false
            }
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func evolveCard(_ info: Achievement) {
        guard let currentRarity = CardRarity(rawValue: info.rarity),
              let state = gachaState else { return }

        let cost: Int
        switch currentRarity {
        case .common: cost = 15
        case .uncommon: cost = 30
        case .rare: cost = 60
        case .epic: cost = 100
        case .legendary: return
        }

        guard state.totalEssence >= cost else { return }
        guard let nextRarity = GachaEngine.nextRarity(from: info.rarity) else { return }

        state.totalEssence -= cost
        info.rarity = nextRarity.rawValue
        info.evolutionLevel += 1

        let rewardManager = CrossGameRewardManager(modelContext: modelContext)
        _ = rewardManager.awardEvolutionXP(evolutionLevel: info.evolutionLevel)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showEvolveSuccess = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showEvolveSuccess = false }
        }
    }
}
