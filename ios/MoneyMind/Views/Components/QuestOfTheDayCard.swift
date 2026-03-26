import SwiftUI
import SwiftData

struct QuestOfTheDayCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var playerProfiles: [PlayerProfile]
    @Query private var dailySlots: [DailyQuestSlot]

    @State private var sparkle = false
    @State private var cachedLuckyQuest: QuestDefinition?
    @State private var cachedAllComplete: Bool = false
    @State private var hasLoaded: Bool = false

    private var player: PlayerProfile? { playerProfiles.first }

    private var questStreak: Int {
        player?.questStreak ?? 0
    }

    var body: some View {
        Group {
            if cachedAllComplete && !dailySlots.isEmpty {
                completedCard
            } else if let quest = cachedLuckyQuest {
                questCard(quest)
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            let engine = QuestEngine(modelContext: modelContext)
            cachedLuckyQuest = engine.luckyQuestForToday()
            cachedAllComplete = engine.allDailyQuestsComplete()
        }
    }

    private func questCard(_ quest: QuestDefinition) -> some View {
        NavigationLink(value: "questHub") {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(quest.category.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(quest.category.color.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                    Image(systemName: quest.category.icon)
                        .font(Typography.headingLarge)
                        .foregroundStyle(quest.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Quest of the Day")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.gold)
                            .tracking(1)
                            .textCase(.uppercase)

                        Image(systemName: "sparkles")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.gold)
                            .symbolEffect(.pulse, isActive: sparkle)
                    }

                    Text(quest.title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(Typography.labelSmall)
                            Text("+\(quest.baseXP) XP")
                                .font(Typography.labelSmall)
                        }
                        .foregroundStyle(Theme.gold)

                        Text(quest.difficulty.rawValue)
                            .font(Typography.labelSmall)
                            .foregroundStyle(quest.difficulty.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(quest.difficulty.color.opacity(0.15))
                            )

                        if !quest.estimatedImpact.isEmpty {
                            Text(quest.estimatedImpact)
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Theme.gold.opacity(0.3), Theme.gold.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: Theme.gold.opacity(0.08), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .onAppear { sparkle = true }
    }

    private var completedCard: some View {
        NavigationLink(value: "questHub") {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("All Quests Complete")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)

                    HStack(spacing: 6) {
                        if questStreak > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(Typography.labelSmall)
                                Text("\(questStreak) day streak")
                                    .font(Typography.labelSmall)
                            }
                            .foregroundStyle(Theme.axisRisk)
                        }

                        Text("Come back tomorrow")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(14)
            .splurjCard(.hero)
        }
        .buttonStyle(.plain)
    }
}
