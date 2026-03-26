import SwiftUI
import SwiftData

struct VaultGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(filter: #Predicate<ScratchCard> { $0.scratchedAt == nil },
           sort: \ScratchCard.earnedAt)
    private var pendingCards: [ScratchCard]

    @Query(filter: #Predicate<Achievement> { $0.typeRaw == "card" }) private var collection: [Achievement]
    @Query private var gachaStates: [GachaState]

    @State private var showCollection: Bool = false
    @State private var showConfetti: Bool = false
    @State private var showLootOpening: Bool = false
    @State private var lootCard: CardDefinition?
    @State private var currentScratchIndex: Int = 0
    @State private var cardTransition: Bool = false
    @State private var criticalBonus: CriticalScratchBonus?
    @State private var showCriticalBonus: Bool = false
    @State private var showQuestPrompt: Bool = false
    @State private var xpBonusText: String?
    @State private var showXPBonus: Bool = false
    @State private var showSetComplete: Bool = false
    @State private var completedSetName: String = ""
    @State private var splurjiMood: SplurjiMood = .thinking

    private var gachaState: GachaState? { gachaStates.first }

    private var collectionProgress: Double {
        guard CardDatabase.totalCards > 0 else { return 0 }
        return Double(collection.count) / Double(CardDatabase.totalCards)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        SplurjiCharacterView(mood: splurjiMood, size: 50)
                            .padding(.trailing, 16)
                    }
                    statsBar
                    scratchArea
                    collectionButton
                    RecentPullsSection(collection: Array(collection))
                }
                .padding(.vertical)
            }

            if showConfetti {
                VaultConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            if showCriticalBonus, let bonus = criticalBonus {
                criticalBonusOverlay(bonus)
            }

            if showXPBonus, let text = xpBonusText {
                xpBonusFloater(text)
            }
        }
        .navigationTitle("The Vault")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
            }
        }
        .sheet(isPresented: $showCollection) {
            CardCollectionView()
        }
        .fullScreenCover(isPresented: $showLootOpening) {
            if let card = lootCard {
                CardLootOpeningView(card: card) {
                    showLootOpening = false
                    lootCard = nil
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showQuestPrompt {
                questNavigationPrompt
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("Set Complete!", isPresented: $showSetComplete) {
            Button("Awesome!") {}
        } message: {
            Text("You completed \(completedSetName)! +500 XP and 200 Essence awarded.")
        }
    }

    private var statsBar: some View {
        HStack(spacing: 8) {
            VaultStat(
                label: "Collected",
                value: "\(collection.count)/\(CardDatabase.totalCards)",
                color: Theme.accent,
                icon: "rectangle.stack.fill"
            )
            VaultStat(
                label: "Pending",
                value: "\(pendingCards.count)",
                color: pendingCards.isEmpty ? Theme.textMuted : Theme.neonGold,
                icon: "sparkles.rectangle.stack"
            )
            VaultStat(
                label: "Essence",
                value: "\(gachaState?.totalEssence ?? 0)",
                color: Theme.gold,
                icon: "diamond.fill"
            )
            VaultStat(
                label: "Pity",
                value: "\(gachaState?.pullsSinceLastLegendary ?? 0)/50",
                color: Theme.neonPurple,
                icon: "star.circle"
            )
        }
        .padding(.horizontal)
    }

    private var scratchArea: some View {
        Group {
            if !pendingCards.isEmpty {
                VStack(spacing: 16) {
                    fannedCardStack
                    cardCountLabel
                }
                .padding(.vertical, 12)
            } else {
                emptyState
            }
        }
    }

    private var fannedCardStack: some View {
        ZStack {
            let visibleCount = min(pendingCards.count, 4)
            ForEach((0..<visibleCount).reversed(), id: \.self) { index in
                if index == 0 {
                    ScratchCardView(scratchCard: pendingCards[0]) { revealed in
                        handleReveal(scratchCard: pendingCards[0], revealed: revealed)
                    }
                    .id(pendingCards[0].id)
                    .zIndex(10)
                    .opacity(cardTransition ? 0 : 1)
                    .scaleEffect(cardTransition ? 0.9 : 1.0)
                    .holographicSheen(isActive: !cardTransition)
                } else {
                    let card = pendingCards[index]
                    let offsetY = CGFloat(index) * 5
                    let scale = 1.0 - CGFloat(index) * 0.03
                    let rarityColor = CardRarity(rawValue: card.cardRarity)?.color ?? Theme.textMuted
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Theme.elevated, Theme.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(rarityColor.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: 280, height: 400)
                        .scaleEffect(scale)
                        .offset(y: offsetY)
                        .zIndex(Double(visibleCount - index))
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: 420)
    }

    private var cardCountLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "rectangle.stack")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
            Text("\(pendingCards.count) card\(pendingCards.count == 1 ? "" : "s") remaining")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(Typography.displayLarge)
                .foregroundStyle(Theme.textMuted)
            Text("No scratch cards")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textSecondary)
            Text("Complete quests to earn scratch cards")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    private var collectionButton: some View {
        Button { showCollection = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(Theme.accent)
                Text("View Collection")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surface)
                        .frame(width: 60, height: 6)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: 60 * collectionProgress, height: 6)
                }

                Text("\(collection.count)/\(CardDatabase.totalCards)")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Image(systemName: "chevron.right")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(16)
            .splurjCard(.elevated)
        }
        .padding(.horizontal)
    }

    private func handleReveal(scratchCard: ScratchCard, revealed: CardDefinition) {
        scratchCard.scratchedAt = Date()
        let rewardManager = CrossGameRewardManager(modelContext: modelContext)
        var isNewCard = false

        if let existing = collection.first(where: { $0.cardID == revealed.id }) {
            existing.duplicateCount += 1
            let essenceReward: Int
            switch revealed.rarity {
            case .common: essenceReward = 5
            case .uncommon: essenceReward = 10
            case .rare: essenceReward = 25
            case .epic: essenceReward = 50
            case .legendary: essenceReward = 100
            }
            if let state = gachaState {
                state.totalEssence += essenceReward
            }
        } else {
            isNewCard = true
            let newCard = Achievement.card(
                cardID: revealed.id,
                rarity: revealed.rarity.rawValue,
                setName: revealed.set.rawValue
            )
            modelContext.insert(newCard)

            let xp = rewardManager.awardNewCardXP()
            showXPBonusFloater("+\(xp) XP New Card!")
        }

        if isNewCard {
            checkSetCompletion(setName: revealed.set.rawValue, rewardManager: rewardManager)
        }

        if let bonus = rewardManager.rollCriticalScratch() {
            criticalBonus = bonus
            if case .bonusEssence(let amount) = bonus {
                if let state = gachaState {
                    state.totalEssence += amount
                }
            }
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCriticalBonus = true
                }
                SplurjHaptics.epicReveal()
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut(duration: 0.3)) {
                    showCriticalBonus = false
                }
                criticalBonus = nil
            }
        }

        if revealed.rarity == .epic || revealed.rarity == .legendary {
            if reduceMotion {
                showConfetti = true
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    showConfetti = false
                }
            } else {
                lootCard = revealed
                Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    showLootOpening = true
                }
            }
        } else if revealed.rarity == .rare {
            showConfetti = true
            Task {
                try? await Task.sleep(for: .seconds(3))
                showConfetti = false
            }
        }

        if pendingCards.count <= 1 {
            showQuestPromptIfAvailable(rewardManager: rewardManager)
        }
    }

    private func checkSetCompletion(setName: String, rewardManager: CrossGameRewardManager) {
        let setCards = collection.filter { $0.setName == setName }
        guard let cardSet = CardSet(rawValue: setName) else { return }
        let setDefinitions = CardDatabase.cards(forSet: cardSet)
        let uniqueCollectedIDs = Set(setCards.map(\.cardID))
        let allDefinitionIDs = Set(setDefinitions.map(\.id))

        let newlyComplete = allDefinitionIDs.subtracting(uniqueCollectedIDs).count <= 1
        guard newlyComplete else { return }

        _ = rewardManager.awardSetCompletionXP(setName: setName)
        if let state = gachaState {
            state.totalEssence += 200
        }
        completedSetName = setName
        Task {
            try? await Task.sleep(for: .seconds(1))
            showSetComplete = true
        }
    }

    private func showXPBonusFloater(_ text: String) {
        xpBonusText = text
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showXPBonus = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) {
                showXPBonus = false
            }
            xpBonusText = nil
        }
    }

    private func showQuestPromptIfAvailable(rewardManager: CrossGameRewardManager) {
        let questCount = rewardManager.availableQuestCount()
        guard questCount > 0 else { return }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showQuestPrompt = true
            }
        }
    }

    private func criticalBonusOverlay(_ bonus: CriticalScratchBonus) -> some View {
        VStack(spacing: 8) {
            Image(systemName: bonus.icon)
                .font(Typography.displayMedium)
                .foregroundStyle(bonus.color)
                .shadow(color: bonus.color.opacity(0.6), radius: 16)

            Text("CRITICAL SCRATCH!")
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.neonGold)
                .tracking(2)

            Text(bonus.label)
                .font(Typography.headingMedium)
                .foregroundStyle(.white)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [bonus.color.opacity(0.6), bonus.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: bonus.color.opacity(0.3), radius: 20)
        )
        .transition(.scale(scale: 0.5).combined(with: .opacity))
    }

    private func xpBonusFloater(_ text: String) -> some View {
        Text(text)
            .font(Typography.headingSmall)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.accent.opacity(0.15), in: Capsule())
            .offset(y: showXPBonus ? -60 : 0)
            .opacity(showXPBonus ? 1 : 0)
            .transition(.opacity)
    }

    private var questNavigationPrompt: some View {
        VStack(spacing: 12) {
            let questCount = CrossGameRewardManager(modelContext: modelContext).availableQuestCount()
            Text("\(questCount) quest\(questCount == 1 ? "" : "s") available today")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)

            Text("Want to earn more cards?")
                .font(Typography.headingSmall)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                NavigationLink(destination: QuestHubView()) {
                    Text("View Quests")
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 12))
                }

                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showQuestPrompt = false
                    }
                } label: {
                    Text("Keep Scratching")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surface, in: .rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.border, lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.elevated)
                .shadow(color: .black.opacity(0.4), radius: 20, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct VaultStat: View {
    let label: String
    let value: String
    let color: Color
    var icon: String = ""

    var body: some View {
        VStack(spacing: 4) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(Typography.labelSmall)
                    .foregroundStyle(color.opacity(0.6))
            }
            Text(value)
                .font(Typography.headingLarge)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .splurjCard(.elevated)
    }
}
