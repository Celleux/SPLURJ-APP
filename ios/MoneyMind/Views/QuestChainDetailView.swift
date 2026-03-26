import SwiftUI
import SwiftData

struct QuestChainDetailView: View {
    let chainID: String
    let chainName: String
    let chainIcon: String
    let chainColor: Color

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var expandedQuestID: String?
    @State private var showRewardCelebration: Bool = false
    @State private var lastReward: QuestReward?
    @State private var shimmerOffset: CGFloat = -200
    @State private var showChainArchiveConfirmation: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var chainQuests: [QuestDefinition] {
        QuestDataManager.shared.quests(forChain: chainID)
    }

    private var engine: QuestEngine {
        QuestEngine(modelContext: modelContext)
    }

    private var completedCount: Int {
        chainQuests.filter { engine.isQuestCompleted($0.id) }.count
    }

    private var isChainComplete: Bool {
        completedCount >= chainQuests.count && !chainQuests.isEmpty
    }

    private var currentQuestIndex: Int {
        chainQuests.firstIndex { !engine.isQuestCompleted($0.id) } ?? chainQuests.count
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, chainColor.opacity(0.08), Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection

                        progressSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)

                        timelineSection

                        if isChainComplete {
                            epicRewardCard
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 32)
                        } else {
                            epicRewardPreview
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 32)
                        }

                        Spacer(minLength: 60)
                    }
                }
                .onAppear {
                    if currentQuestIndex < chainQuests.count {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo("quest_\(currentQuestIndex)", anchor: .center)
                            }
                        }
                    }
                }
            }

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.displayMedium)
                            .foregroundStyle(Theme.textMuted)
                            .background(Circle().fill(Theme.background.opacity(0.6)).frame(width: 32, height: 32))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showRewardCelebration) {
            if let reward = lastReward {
                QuestRewardCelebration(reward: reward)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 52)

            ZStack {
                Circle()
                    .fill(chainColor.opacity(0.12))
                    .frame(width: 80, height: 80)

                Circle()
                    .stroke(chainColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: chainIcon)
                    .font(Typography.displayMedium)
                    .foregroundStyle(chainColor)
            }

            Text(chainName)
                .font(Typography.displaySmall)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("\(chainQuests.count)-quest story arc")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(completedCount) of \(chainQuests.count) complete")
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                Spacer()
                if isChainComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(Typography.labelSmall)
                        Text("CHAIN COMPLETE")
                            .font(Typography.labelSmall)
                            .tracking(1)
                    }
                    .foregroundStyle(Theme.gold)
                } else {
                    Text("\(Int(Double(completedCount) / Double(max(1, chainQuests.count)) * 100))%")
                        .font(Typography.moneySmall)
                        .foregroundStyle(chainColor)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Theme.elevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [chainColor, chainColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * (Double(completedCount) / Double(max(1, chainQuests.count))),
                            height: 8
                        )
                        .animation(.spring(response: 0.6), value: completedCount)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(chainQuests.enumerated()), id: \.element.id) { index, quest in
                let isCompleted = engine.isQuestCompleted(quest.id)
                let isCurrent = index == currentQuestIndex
                let isLocked = index > currentQuestIndex
                let isBoss = index == chainQuests.count - 1

                HStack(alignment: .top, spacing: 16) {
                    timelineConnector(
                        index: index,
                        total: chainQuests.count,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isBoss: isBoss
                    )

                    questNode(
                        quest: quest,
                        index: index,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isLocked: isLocked,
                        isBoss: isBoss
                    )
                }
                .id("quest_\(index)")
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Timeline Connector

    private func timelineConnector(index: Int, total: Int, isCompleted: Bool, isCurrent: Bool, isBoss: Bool) -> some View {
        VStack(spacing: 0) {
            if index > 0 {
                Rectangle()
                    .fill(isCompleted ? Theme.accent : Theme.elevated)
                    .frame(width: 2, height: 12)
            } else {
                Spacer().frame(height: 12)
            }

            ZStack {
                if isBoss {
                    Circle()
                        .fill(isCompleted ? Theme.gold : Theme.bossRed.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Circle()
                        .stroke(isCompleted ? Theme.gold : Theme.bossRed.opacity(0.4), lineWidth: 2)
                        .frame(width: 36, height: 36)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.bossRed)
                    }
                } else if isCompleted {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(Typography.labelMedium)
                        .foregroundStyle(.white)
                } else if isCurrent {
                    Circle()
                        .fill(chainColor.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Circle()
                        .stroke(chainColor, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    Circle()
                        .fill(chainColor)
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(Theme.elevated)
                        .frame(width: 28, height: 28)

                    Image(systemName: "lock.fill")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            if index < total - 1 {
                Rectangle()
                    .fill(isCompleted ? Theme.accent : Theme.elevated)
                    .frame(width: 2)
                    .frame(minHeight: 40)
            }
        }
        .frame(width: 36)
    }

    // MARK: - Quest Node

    @ViewBuilder
    private func questNode(quest: QuestDefinition, index: Int, isCompleted: Bool, isCurrent: Bool, isLocked: Bool, isBoss: Bool) -> some View {
        if isCompleted {
            completedNode(quest: quest, isBoss: isBoss)
        } else if isCurrent {
            currentNode(quest: quest, isBoss: isBoss)
        } else {
            lockedNode(quest: quest, index: index, isBoss: isBoss)
        }
    }

    private func completedNode(quest: QuestDefinition, isBoss: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(quest.title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .strikethrough(color: Theme.accent.opacity(0.5))

                Text(quest.difficulty.rawValue)
                    .font(Typography.labelSmall)
                    .foregroundStyle(quest.difficulty.color.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(quest.difficulty.color.opacity(0.08)))
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accent)
                Text("Completed")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 8)
    }

    private func currentNode(quest: QuestDefinition, isBoss: Bool) -> some View {
        let isExpanded = expandedQuestID == quest.id

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if isBoss {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(Typography.labelSmall)
                        Text("BOSS QUEST")
                            .font(Typography.labelSmall)
                            .tracking(1.5)
                    }
                    .foregroundStyle(Theme.bossRed)
                }

                Text(quest.title)
                    .font(Typography.headingSmall)
                    .foregroundStyle(.white)

                Text(quest.subtitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 8) {
                    Text(quest.difficulty.rawValue)
                        .font(Typography.labelSmall)
                        .foregroundStyle(quest.difficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(quest.difficulty.color.opacity(0.15)))

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(Typography.labelSmall)
                        Text("+\(quest.baseXP) XP")
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(Theme.gold)

                    if !quest.estimatedTime.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(Typography.labelSmall)
                            Text(quest.estimatedTime)
                                .font(Typography.labelSmall)
                        }
                        .foregroundStyle(Theme.textMuted)
                    }
                }

                if isExpanded {
                    expandedContent(quest: quest)
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        expandedQuestID = isExpanded ? nil : quest.id
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Collapse" : "View Details")
                            .font(Typography.labelMedium)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(chainColor)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isBoss
                                ? AnyShapeStyle(LinearGradient(colors: [Theme.bossRed.opacity(0.5), Theme.bossRed.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(chainColor.opacity(0.3)),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: isBoss ? Theme.bossRed.opacity(0.15) : chainColor.opacity(0.1), radius: 12)
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func expandedContent(quest: QuestDefinition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().background(Theme.elevated)

            Text(quest.description)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)

            if quest.steps.count > 1 {
                let progress = engine.questProgress(for: quest.id)
                let currentStep = progress?.currentStepIndex ?? 0
                let completions = progress?.stepCompletions ?? [:]

                VStack(spacing: 6) {
                    ForEach(Array(quest.steps.enumerated()), id: \.element.id) { idx, step in
                        QuestStepRow(
                            step: step,
                            stepNumber: idx + 1,
                            isCompleted: completions[step.id] == true,
                            isCurrent: idx == currentStep
                        )
                    }
                }
            }

            HStack(spacing: 12) {
                RewardChip(icon: "star.fill", text: "+\(quest.baseXP) XP", color: Theme.gold)

                if quest.scratchCardChance >= 1.0 {
                    RewardChip(icon: "creditcard.fill", text: "Card", color: Theme.accent)
                } else if quest.scratchCardChance > 0 {
                    RewardChip(icon: "creditcard.fill", text: "\(Int(quest.scratchCardChance * 100))%", color: Theme.accent.opacity(0.7))
                }

                if quest.essenceReward > 0 {
                    RewardChip(icon: "diamond.fill", text: "+\(quest.essenceReward)", color: Theme.lavender)
                }

                Spacer()
            }

            Button {
                completeCurrentQuest(quest)
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.headingMedium)
                    Text("Complete Quest")
                        .font(Typography.headingSmall)
                }
                .foregroundStyle(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 4)
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: completedCount)

            if showChainArchiveConfirmation {
                VStack(spacing: 8) {
                    Text("That's okay \u{2014} you tried, and that took courage.")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showChainArchiveConfirmation = false
                            }
                        } label: {
                            Text("Keep Quest")
                                .font(Typography.labelMedium)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Button {
                            archiveCurrentQuest(quest)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .font(Typography.labelSmall)
                                Text("Archive (+15 XP)")
                                    .font(Typography.labelMedium)
                            }
                            .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showChainArchiveConfirmation = true
                    }
                } label: {
                    Text("Not for me right now")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.top, 4)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func lockedNode(quest: QuestDefinition, index: Int, isBoss: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(quest.title)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textDisabled)

            if isBoss {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(Typography.labelSmall)
                    Text("Boss Quest")
                        .font(Typography.labelSmall)
                }
                .foregroundStyle(Theme.bossRed.opacity(0.4))
            } else {
                Text("Complete previous quest first")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }

            Text(quest.difficulty.rawValue)
                .font(Typography.labelSmall)
                .foregroundStyle(quest.difficulty.color.opacity(0.4))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(quest.difficulty.color.opacity(0.05)))
        }
        .padding(.vertical, 8)
        .padding(.bottom, 8)
        .opacity(0.6)
    }

    // MARK: - Epic Reward Card (Completed)

    private var epicRewardCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Theme.gold.opacity(0.15), Theme.gold.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.gold.opacity(0.4), lineWidth: 1)

                VStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.gold)

                    Text("CHAIN COMPLETE")
                        .font(Typography.headingMedium)
                        .tracking(2)
                        .foregroundStyle(Theme.gold)

                    Text("Epic Card Earned")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Epic Reward Preview (Locked)

    private var epicRewardPreview: some View {
        VStack(spacing: 10) {
            Divider().background(Theme.elevated)
                .padding(.bottom, 8)

            HStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(Typography.labelSmall)
                Text("CHAIN REWARD")
                    .font(Typography.labelSmall)
                    .tracking(1.5)
            }
            .foregroundStyle(chainColor.opacity(0.6))

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surface)
                    .frame(height: 80)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(chainColor.opacity(0.2), lineWidth: 0.5)
                    .frame(height: 80)

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(chainColor.opacity(0.1))
                            .frame(width: 52, height: 52)

                        Image(systemName: "sparkles")
                            .font(Typography.displaySmall)
                            .foregroundStyle(chainColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Epic Card")
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white)

                        Text("Complete all \(chainQuests.count) quests to unlock")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.horizontal, 16)

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.clear, chainColor.opacity(0.05), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 80)
                    .offset(x: shimmerOffset)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onAppear {
                        if !reduceMotion {
                            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                                shimmerOffset = 400
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Actions

    private func completeCurrentQuest(_ quest: QuestDefinition) {
        let questEngine = QuestEngine(modelContext: modelContext)
        let player = questEngine.getOrCreatePlayer()

        let allDone = questEngine.advanceQuestStep(quest.id)
        if allDone {
            let reward = questEngine.completeQuest(quest.id, player: player)
            lastReward = reward
            expandedQuestID = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRewardCelebration = true
            }
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func archiveCurrentQuest(_ quest: QuestDefinition) {
        let questEngine = QuestEngine(modelContext: modelContext)
        let player = questEngine.getOrCreatePlayer()
        questEngine.archiveQuest(quest.id, player: player)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            expandedQuestID = nil
            showChainArchiveConfirmation = false
        }
    }
}
