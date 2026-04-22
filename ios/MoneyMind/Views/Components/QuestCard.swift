import SwiftUI
import PhosphorSwift

struct QuestCard: View {
    let quest: QuestDefinition
    let isLucky: Bool
    let isExpanded: Bool
    let progress: QuestProgress?
    let onTap: () -> Void
    let onComplete: () -> Void
    var onArchive: (() -> Void)?
    var appearIndex: Int = 0

    @State private var showCompletionAnimation: Bool = false
    @State private var showArchiveConfirmation: Bool = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showRewardTooltip: Bool = false
    @State private var appeared: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentStep: Int { progress?.currentStepIndex ?? 0 }
    private var completions: [String: Bool] { progress?.stepCompletions ?? [:] }
    private var completedStepCount: Int {
        quest.steps.count > 1 ? completions.filter(\.value).count : 0
    }
    private var isSingleStep: Bool { quest.steps.count <= 1 }
    private var swipeThreshold: CGFloat { 120 }
    private var swipeProgress: CGFloat { min(1, max(0, swipeOffset / swipeThreshold)) }

    var body: some View {
        ZStack {
            if isSingleStep && swipeOffset > 0 {
                swipeRevealBackground
            }

            mainCard
                .offset(x: isSingleStep ? swipeOffset : 0)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 60)
                .animation(
                    reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(Double(appearIndex) * 0.05),
                    value: appeared
                )
        }
        .onAppear {
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(questAccessibilityLabel)
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
        .accessibilityAction(named: "Complete quest") {
            if isSingleStep { onComplete() }
        }
    }

    // MARK: - Swipe Reveal Background

    private var swipeRevealBackground: some View {
        HStack {
            HStack(spacing: 8) {
                PhIcon.checkCircleFill
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                    .scaleEffect(swipeProgress > 0.8 ? 1.2 : 0.8)
                    .opacity(Double(swipeProgress))

                if swipeProgress > 0.5 {
                    Text("Complete")
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }
            }
            .padding(.leading, 20)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    // MARK: - Main Card

    private var mainCard: some View {
        ZStack {
            VStack(spacing: 0) {
                collapsedHeader
                    .padding(16)

                if isExpanded {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.surface)

                    HStack(spacing: 0) {
                        difficultyStrip
                        Spacer()
                    }
                }
            )
            .overlay(cardBorder)

            if isLucky && !reduceMotion {
                luckyGlowBorder
            }

            if showCompletionAnimation {
                QuestCompleteCheckmark(xpEarned: quest.baseXP) {
                    showCompletionAnimation = false
                    onComplete()
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: isLucky ? Theme.gold.opacity(0.25) : .clear, radius: isLucky ? 12 : 0)
        .neonGlow(
            color: quest.archetype == .bossBattle ? Theme.neonPurple : .clear,
            radius: quest.archetype == .bossBattle ? 14 : 0,
            pulses: quest.archetype == .bossBattle
        )
        .holographicSheen(isActive: quest.chainID != nil && !reduceMotion)
        .contentShape(Rectangle())
        .simultaneousGesture(swipeGesture)
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.5, perform: {}) { pressing in
            withAnimation(.spring(response: 0.3)) {
                showRewardTooltip = pressing
            }
        }
        .overlay(alignment: .top) {
            if showRewardTooltip {
                rewardTooltip
                    .offset(y: -70)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isExpanded)
    }

    // MARK: - Difficulty Strip

    private var difficultyStrip: some View {
        Group {
            if quest.difficulty == .legendary && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 10.0)) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Theme.gold, Theme.axisRisk, Theme.gold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4)
                        .shadow(color: Theme.gold.opacity(0.5), radius: 4)
                }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(quest.difficulty.color)
                    .frame(width: 4)
            }
        }
    }

    // MARK: - Card Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isLucky
                ? AnyShapeStyle(Theme.gold.opacity(0.4))
                : AnyShapeStyle(Theme.elevated.opacity(0.5)),
                lineWidth: isLucky ? 1.5 : 0.5
            )
    }

    // MARK: - Lucky Glow Border

    private var luckyGlowBorder: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let angle = (elapsed / 3.0).truncatingRemainder(dividingBy: 1.0) * 360

            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.gold.opacity(0.5),
                            Theme.gold.opacity(0.1),
                            Theme.gold.opacity(0.3),
                            Theme.gold.opacity(0.1),
                            Theme.gold.opacity(0.5)
                        ],
                        center: .center,
                        startAngle: .degrees(angle),
                        endAngle: .degrees(angle + 360)
                    ),
                    lineWidth: 2
                )
                .shadow(color: Theme.gold.opacity(0.3), radius: 8)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard isSingleStep else { return }
                let translation = max(0, value.translation.width)
                swipeOffset = translation
            }
            .onEnded { value in
                guard isSingleStep else { return }
                if swipeOffset >= swipeThreshold {
                    SplurjHaptics.swipeComplete()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeOffset = UIScreen.main.bounds.width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        swipeOffset = 0
                    }
                }
            }
    }

    // MARK: - Reward Tooltip

    private var rewardTooltip: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                PhIcon.starFill
                    .frame(width: 12, height: 12)
                Text("+\(quest.baseXP) XP")
                    .font(Typography.labelSmall)
            }
            .foregroundStyle(Theme.gold)

            if quest.scratchCardChance > 0 {
                HStack(spacing: 3) {
                    PhIcon.creditCardFill
                        .frame(width: 12, height: 12)
                    Text("\(Int(quest.scratchCardChance * 100))%")
                        .font(Typography.labelSmall)
                }
                .foregroundStyle(Theme.accent)
            }

            if quest.essenceReward > 0 {
                HStack(spacing: 3) {
                    PhIcon.diamondFill
                        .frame(width: 12, height: 12)
                    Text("+\(quest.essenceReward)")
                        .font(Typography.labelSmall)
                }
                .foregroundStyle(Theme.lavender)
            }

            HStack(spacing: 3) {
                PhIcon.lightningFill
                    .frame(width: 12, height: 12)
                Text("\(quest.baseXP / 10) dmg")
                    .font(Typography.labelSmall)
            }
            .foregroundStyle(Theme.bossRed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.elevated, lineWidth: 0.5)
        )
    }

    // MARK: - Collapsed Header

    private var collapsedHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(quest.category.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Circle()
                    .stroke(quest.category.color.opacity(0.4), lineWidth: 2)
                    .frame(width: 48, height: 48)

                Image(systemName: quest.category.icon)
                    .font(Typography.headingLarge)
                    .foregroundStyle(quest.category.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(quest.title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if isLucky {
                        PhIcon.sparkleFill
                            .frame(width: 14, height: 14)
                            .foregroundStyle(Theme.gold)
                    }
                }

                Text(quest.subtitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(quest.difficulty.rawValue)
                        .font(Typography.labelSmall)
                        .foregroundStyle(quest.difficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(quest.difficulty.color.opacity(0.15))
                        )

                    HStack(spacing: 2) {
                        PhIcon.starFill
                            .frame(width: 12, height: 12)
                        Text("+\(quest.baseXP) XP")
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(Theme.gold)

                    if !quest.estimatedImpact.isEmpty {
                        Text(quest.estimatedImpact)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.accent)
                    }

                    HStack(spacing: 2) {
                        PhIcon.clock
                            .frame(width: 12, height: 12)
                        Text(quest.estimatedTime)
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(Theme.textMuted)
                }

                if quest.steps.count > 1 {
                    stepIndicatorDots
                        .padding(.top, 2)
                }
            }

            Spacer()

            if isSingleStep && !isExpanded {
                PhIcon.caretRight
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Theme.textMuted.opacity(0.5))
                    .accessibilityHidden(true)
            } else {
                PhIcon.caretDown
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Theme.textMuted)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Step Indicator Dots

    private var stepIndicatorDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<quest.steps.count, id: \.self) { i in
                Circle()
                    .fill(
                        i < completedStepCount
                        ? Theme.accent
                        : i == currentStep
                        ? Theme.accent.opacity(0.5)
                        : Theme.elevated
                    )
                    .frame(width: 5, height: 5)
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            Divider().background(Theme.elevated)

            Text(quest.description)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 16)

            if quest.steps.count > 1 {
                VStack(spacing: 8) {
                    ForEach(Array(quest.steps.enumerated()), id: \.element.id) { index, step in
                        QuestStepRow(
                            step: step,
                            stepNumber: index + 1,
                            isCompleted: completions[step.id] == true,
                            isCurrent: index == currentStep
                        )
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 16) {
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
            .padding(.horizontal, 16)

            Button {
                triggerCompletion()
            } label: {
                HStack {
                    PhIcon.sealCheckFill
                        .frame(width: 22, height: 22)
                    Text(quest.steps.count > 1 && currentStep < quest.steps.count - 1 ? "Complete Step" : "Complete Quest")
                        .font(Typography.headingMedium)
                }
                .foregroundStyle(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)
            }
            .accessibilityLabel(quest.steps.count > 1 && currentStep < quest.steps.count - 1 ? "Complete current step" : "Complete quest for \(quest.baseXP) XP")
            .padding(.horizontal, 16)

            if onArchive != nil {
                if showArchiveConfirmation {
                    VStack(spacing: 8) {
                        Text("That\u{2019}s okay \u{2014} you tried, and that took courage.")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showArchiveConfirmation = false
                                }
                            } label: {
                                Text("Keep Quest")
                                    .font(Typography.labelMedium)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Button {
                                onArchive?()
                            } label: {
                                HStack(spacing: 4) {
                                    PhIcon.leafFill
                                        .frame(width: 12, height: 12)
                                    Text("Archive (+15 XP)")
                                        .font(Typography.labelMedium)
                                }
                                .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showArchiveConfirmation = true
                        }
                    } label: {
                        Text("Not for me right now")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.top, 4)
                    .accessibilityLabel("Archive this quest. You'll earn 15 XP for financial wisdom.")
                }
            }

            Spacer().frame(height: 16)
        }
    }

    // MARK: - Completion

    private func triggerCompletion() {
        if quest.steps.count > 1 && currentStep < quest.steps.count - 1 {
            SplurjHaptics.stepComplete()
            onComplete()
        } else {
            showCompletionAnimation = true
        }
    }

    // MARK: - Accessibility

    private var questAccessibilityLabel: String {
        var label = "\(quest.title). \(quest.difficulty.rawValue) difficulty. \(quest.baseXP) XP."
        if isLucky {
            label += " Lucky quest with bonus rewards."
        }
        if quest.steps.count > 1 {
            label += " Step \(currentStep + 1) of \(quest.steps.count)."
        }
        if isSingleStep {
            label += " Swipe right to complete."
        }
        return label
    }
}
