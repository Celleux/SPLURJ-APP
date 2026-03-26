import SwiftUI
import SwiftData

struct WeeklyQuestStack: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DailyQuestSlot> { $0.cadence == "weekly" },
           sort: \DailyQuestSlot.offeredDate, order: .reverse)
    private var allWeeklySlots: [DailyQuestSlot]

    @State private var expandedQuestID: String?
    @State private var showRewardCelebration: Bool = false
    @State private var lastReward: QuestReward?
    @State private var completedQuestIDs: Set<String> = []

    private var currentWeekSlots: [DailyQuestSlot] {
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        let daysBack = (weekday + 5) % 7
        let monday = Calendar.current.date(byAdding: .day, value: -daysBack, to: today) ?? today
        return allWeeklySlots.filter { $0.offeredDate >= monday }
    }

    private var weeklyQuests: [(slot: DailyQuestSlot, quest: QuestDefinition)] {
        currentWeekSlots.compactMap { slot in
            guard let quest = QuestDataManager.shared.quest(byID: slot.questID) else { return nil }
            return (slot, quest)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.axisEmotional)
                Text("This Week's Quests")
                    .font(Typography.headingSmall)
                    .foregroundStyle(.white)
                Spacer()
                Text("Resets Monday")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("This Week's Quests. Resets Monday.")

            if weeklyQuests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textMuted)
                    Text("Weekly quests refresh on Monday")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.surface)
                )
                .padding(.horizontal, 16)
                .accessibilityLabel("No weekly quests available. Weekly quests refresh on Monday.")
            } else {
                let activeQuests = weeklyQuests.filter { item in
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
                        isLucky: false,
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
