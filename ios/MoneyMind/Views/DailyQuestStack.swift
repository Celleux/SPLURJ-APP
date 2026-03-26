import SwiftUI
import SwiftData

struct DailyQuestStack: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DailyQuestSlot> { $0.cadence == "daily" },
           sort: \DailyQuestSlot.offeredDate, order: .reverse)
    private var allDailySlots: [DailyQuestSlot]

    @State private var expandedQuestID: String?
    @State private var showRewardCelebration: Bool = false
    @State private var lastReward: QuestReward?
    @State private var completedQuestIDs: Set<String> = []

    private var todaysSlots: [DailyQuestSlot] {
        let today = Calendar.current.startOfDay(for: Date())
        return allDailySlots.filter { $0.offeredDate >= today }
    }

    private var todaysQuests: [(slot: DailyQuestSlot, quest: QuestDefinition)] {
        todaysSlots.compactMap { slot in
            guard let quest = QuestDataManager.shared.quest(byID: slot.questID) else { return nil }
            return (slot, quest)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(Theme.gold)
                Text("Today's Quests")
                    .font(Typography.headingSmall)
                    .foregroundStyle(.white)
                Spacer()
                Text("Resets at midnight")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today's Quests. Resets at midnight.")

            if todaysQuests.isEmpty {
                AllQuestsCompleteCard()
                    .padding(.horizontal, 16)
            } else {
                let activeQuests = todaysQuests.filter { item in
                    let engine = QuestEngine(modelContext: modelContext)
                    let progress = engine.questProgress(for: item.quest.id)
                    let isCompleted = progress?.questStatus == .completed || progress?.questStatus == .claimed
                    return !isCompleted && !completedQuestIDs.contains(item.quest.id)
                }

                ForEach(activeQuests, id: \.quest.id) { item in
                    let engine = QuestEngine(modelContext: modelContext)
                    let progress = engine.questProgress(for: item.quest.id)

                    QuestCard(
                        quest: item.quest,
                        isLucky: item.slot.isLuckyQuest,
                        isExpanded: expandedQuestID == item.quest.id,
                        progress: progress,
                        onTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                expandedQuestID = expandedQuestID == item.quest.id ? nil : item.quest.id
                            }
                        },
                        onComplete: {
                            completeQuest(item.quest.id)
                        },
                        onArchive: {
                            archiveQuest(item.quest.id)
                        }
                    )
                    .padding(.horizontal, 16)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }

                let completedCount = todaysQuests.filter { item in
                    let engine = QuestEngine(modelContext: modelContext)
                    return engine.isQuestCompleted(item.quest.id)
                }.count

                if completedCount == todaysQuests.count && !todaysQuests.isEmpty {
                    AllQuestsCompleteCard()
                        .padding(.horizontal, 16)
                }
            }
        }
        .fullScreenCover(isPresented: $showRewardCelebration) {
            if let reward = lastReward {
                QuestRewardCelebration(reward: reward)
            }
        }
    }

    private func completeQuest(_ questID: String) {
        let engine = QuestEngine(modelContext: modelContext)
        let playerDescriptor = FetchDescriptor<PlayerProfile>()
        guard let player = try? modelContext.fetch(playerDescriptor).first else { return }

        let quest = QuestDatabase.quest(byID: questID)

        if let quest, quest.steps.count > 1 {
            let allDone = engine.advanceQuestStep(questID)
            if !allDone {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                return
            }
        }

        let reward = engine.completeQuest(questID, player: player)
        lastReward = reward

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            expandedQuestID = nil
            completedQuestIDs.insert(questID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showRewardCelebration = true
        }
    }

    private func archiveQuest(_ questID: String) {
        let engine = QuestEngine(modelContext: modelContext)
        let player = engine.getOrCreatePlayer()
        engine.archiveQuest(questID, player: player)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            expandedQuestID = nil
            completedQuestIDs.insert(questID)
        }
    }
}
