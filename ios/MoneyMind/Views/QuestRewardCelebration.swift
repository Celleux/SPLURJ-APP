import SwiftUI
import SwiftData

struct QuestRewardCelebration: View {
    let reward: QuestReward
    var questName: String = "Quest"
    var onOpenVault: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [UserProfile]
    @Query private var quizResults: [QuizResult]

    private var userLevel: Int { CharacterStage.level(from: profiles.first?.xpPoints ?? 0) }
    private var archetypeName: String { (quizResults.first?.personality ?? .builder).rawValue }

    @State private var phase: CelebrationPhase = .anticipation
    @State private var canDismiss: Bool = false

    @State private var titleOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.5
    @State private var subtitleOpacity: Double = 0
    @State private var dotsPulsing: Bool = false

    @State private var xpCounter: Int = 0
    @State private var xpFontSize: CGFloat = 18
    @State private var xpScale: CGFloat = 1.0
    @State private var orbsActive: Bool = false
    @State private var radialPulse: Bool = false

    @State private var showCard: Bool = false
    @State private var showEssence: Bool = false
    @State private var showBoss: Bool = false
    @State private var showStreak: Bool = false
    @State private var cardBounce: Bool = false
    @State private var essenceFly: Bool = false
    @State private var swordSlash: Bool = false
    @State private var damageFloat: Bool = false
    @State private var flameActive: Bool = false
    @State private var streakCount: Int = 0

    @State private var showLevelUp: Bool = false
    @State private var levelUpScale: CGFloat = 0.3
    @State private var goldBurst: Bool = false
    @State private var screenShake: CGFloat = 0

    @State private var showConfetti: Bool = false
    @State private var showCardZoom: Bool = false
    @State private var cardZoomScale: CGFloat = 1.0

    @State private var showShare: Bool = false
    @State private var showVaultPrompt: Bool = false
    @State private var showStreakCards: Bool = false
    @State private var showDoubleXP: Bool = false

    @State private var dimOverlay: Double = 0

    private enum CelebrationPhase {
        case anticipation, buildUp, reveal, celebration, social
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Color.black.opacity(dimOverlay).ignoresSafeArea()

            if radialPulse {
                radialPulseView
            }

            if goldBurst {
                goldBurstView
            }

            ConfettiCanvasView(
                active: showConfetti,
                colors: [Theme.accent, Theme.gold, .white, Theme.lavender, Theme.axisEmotional],
                particleCount: reduceMotion ? 0 : 50
            )
            .drawingGroup()

            if showLevelUp {
                ScreenFlashView(color: Theme.gold, duration: 0.3, trigger: showLevelUp)
            }

            mainContent
                .offset(x: screenShake)
        }
        .onTapGesture {
            if canDismiss { dismiss() }
        }
        .onAppear {
            AppReviewManager.shared.recordQuestCompletion()
            if reduceMotion {
                startReducedSequence()
            } else {
                startFullSequence()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 16) {
            Spacer()

            anticipationSection
            buildUpSection
            revealSection
            celebrationSection
            socialSection

            Spacer()

            if reward.streakBonusCards > 0 && showStreakCards {
                streakBonusSection
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            if reward.hasDoubleXP && showDoubleXP {
                doubleXPBadge
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            if reward.scratchCard && showVaultPrompt && canDismiss {
                vaultPrompt
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if canDismiss {
                dismissButton
                    .transition(.opacity)
            }

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Phase 1: Anticipation

    private var anticipationSection: some View {
        VStack(spacing: 8) {
            if titleOpacity > 0 {
                Image(systemName: "checkmark.seal.fill")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.bounce, value: titleOpacity > 0.5)
                    .opacity(titleOpacity)
                    .scaleEffect(titleScale)

                Text("QUEST COMPLETE")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.accent)
                    .tracking(4)
                    .opacity(subtitleOpacity)
            }

            if dotsPulsing {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Theme.accent.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .scaleEffect(dotsPulsing ? 1.3 : 0.7)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.15),
                                value: dotsPulsing
                            )
                    }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Phase 2: Build-Up

    private var buildUpSection: some View {
        Group {
            if xpCounter > 0 {
                VStack(spacing: 4) {
                    Text("+\(xpCounter)")
                        .font(.system(size: xpFontSize, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.gold, Theme.amberBright],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText(value: Double(xpCounter)))
                        .neonGlow(color: Theme.neonGold, radius: 16)
                        .scaleEffect(xpScale)

                    Text("EXPERIENCE POINTS")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(2)

                    if reward.isLucky {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(Typography.labelSmall)
                            Text("LUCKY QUEST BONUS")
                                .font(Typography.labelSmall)
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 4)
                    }
                }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
    }

    // MARK: - Phase 3: Reveal

    private var revealSection: some View {
        VStack(spacing: 12) {
            if reward.scratchCard && showCard {
                scratchCardReward
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            if reward.essence > 0 && showEssence {
                essenceReward
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            if reward.bossDamage > 0 && showBoss {
                bossDamageReward
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            if showStreak {
                streakReward
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
    }

    // MARK: - Phase 4: Celebration

    private var celebrationSection: some View {
        VStack(spacing: 10) {
            if showCardZoom && reward.scratchCard {
                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(Typography.displayLarge)
                        .foregroundStyle(Theme.accent)
                        .scaleEffect(cardZoomScale)
                        .neonGlow(color: Theme.neonEmerald, radius: 20)
                        .depthPop(intensity: 1.5)

                    Text("A card awaits in The Vault")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.accent)
                }
                .transition(.scale.combined(with: .opacity))
            }

            if reward.didLevelUp && showLevelUp {
                levelUpSection
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
    }

    // MARK: - Phase 5: Social

    private var socialSection: some View {
        Group {
            if reward.tiktokMoment != nil && showShare {
                shareCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Reward Items

    private var scratchCardReward: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: "creditcard.fill")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.accent)
                    .offset(y: cardBounce ? 0 : -30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: cardBounce)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Scratch Card Earned")
                    .font(Typography.headingMedium)
                    .foregroundStyle(.white)
                Text("Head to The Vault to reveal it")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Theme.accent.opacity(0.2), radius: 12)
        )
        .padding(.horizontal, 32)
    }

    private var essenceReward: some View {
        HStack(spacing: 10) {
            Image(systemName: "diamond.fill")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.lavender)
                .offset(y: essenceFly ? 0 : 20)
                .opacity(essenceFly ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: essenceFly)

            Text("+\(reward.essence) Essence")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.lavender)
        }
    }

    private var bossDamageReward: some View {
        HStack(spacing: 10) {
            ZStack {
                Image(systemName: "bolt.fill")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.bossRed)
                    .rotationEffect(.degrees(swordSlash ? 0 : -45))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: swordSlash)

                if damageFloat {
                    Text("-\(reward.bossDamage)")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.bossRed)
                        .offset(y: damageFloat ? -25 : 0)
                        .opacity(damageFloat ? 0.6 : 1)
                        .animation(.easeOut(duration: 1.0), value: damageFloat)
                }
            }

            Text("-\(reward.bossDamage) Boss HP")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.bossRed)
        }
    }

    private var streakReward: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(Typography.displaySmall)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.axisRisk, Theme.bossRed],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .symbolEffect(.bounce, value: flameActive)

            Text("Quest Streak")
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textSecondary)

            Text("\(streakCount)")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.axisRisk)
                .contentTransition(.numericText(value: Double(streakCount)))
        }
    }

    // MARK: - Level Up

    private var levelUpSection: some View {
        VStack(spacing: 10) {
            Text("LEVEL UP")
                .font(Typography.displayMedium)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.gold, Theme.axisRisk, Theme.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Theme.gold.opacity(0.6), radius: 30)
                .scaleEffect(levelUpScale)

            Text("Level \(reward.newLevel)")
                .font(Typography.displaySmall)
                .foregroundStyle(.white)

            if let newZone = zoneChangedTo {
                VStack(spacing: 4) {
                    Text("NEW ZONE UNLOCKED")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                        .tracking(2)

                    HStack(spacing: 8) {
                        Image(systemName: newZone.sfSymbol)
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.accent)
                        Text(newZone.rawValue)
                            .font(Typography.headingMedium)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var zoneChangedTo: QuestZone? {
        guard reward.didLevelUp else { return nil }
        let previousLevel = reward.newLevel - 1
        let oldZone = QuestZone.zone(forLevel: max(1, previousLevel))
        let newZone = QuestZone.zone(forLevel: reward.newLevel)
        return oldZone != newZone ? newZone : nil
    }

    // MARK: - Share Card

    @ViewBuilder
    private var shareCard: some View {
        VStack(spacing: 12) {
            Text(reward.tiktokMoment ?? "")
                .font(Typography.bodySmall)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            ShareAchievementButton(
                type: .quest(name: questName),
                level: userLevel,
                archetypeName: archetypeName,
                style: .compact
            )
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 32)
    }

    // MARK: - Dismiss

    private var streakBonusSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.neonGold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak Bonus!")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.neonGold)
                Text("+\(reward.streakBonusCards) bonus scratch card\(reward.streakBonusCards == 1 ? "" : "s")")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var doubleXPBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.neonGold)
            Text("2x XP Active")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.neonGold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.neonGold.opacity(0.15), in: Capsule())
    }

    private var vaultPrompt: some View {
        VStack(spacing: 10) {
            Text("You earned a scratch card")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onOpenVault?()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(Typography.bodySmall)
                        Text("Open Vault")
                            .font(Typography.headingSmall)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.accentGradient, in: Capsule())
                }

                Button {
                    withAnimation {
                        showVaultPrompt = false
                    }
                } label: {
                    Text("Later")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.surface, in: Capsule())
                        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.elevated)
                .shadow(color: .black.opacity(0.3), radius: 12)
        )
        .padding(.horizontal, 32)
    }

    private var dismissButton: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Text("Tap anywhere to dismiss")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Radial Pulse

    private var radialPulseView: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Theme.accent.opacity(0.15), Theme.accent.opacity(0), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 250
                )
            )
            .frame(width: 500, height: 500)
            .scaleEffect(radialPulse ? 1.3 : 0.5)
            .opacity(radialPulse ? 0 : 0.8)
            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: radialPulse)
            .allowsHitTesting(false)
    }

    private var goldBurstView: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Theme.gold.opacity(0.5), Theme.gold.opacity(0), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
            )
            .frame(width: 600, height: 600)
            .scaleEffect(1.2)
            .opacity(goldBurst ? 0 : 1)
            .animation(.easeOut(duration: 1.2), value: goldBurst)
            .allowsHitTesting(false)
    }

    // MARK: - Full Animation Sequence

    private func startFullSequence() {
        // Phase 1: Anticipation (0-0.8s)
        SplurjHaptics.bossDamage()

        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            dimOverlay = 0.7
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            titleOpacity = 1
            titleScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            subtitleOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dotsPulsing = true
        }

        // Phase 2: Build-Up (0.8-2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dotsPulsing = false
            radialPulse = true
            animateXPCounter(target: reward.xp, duration: 0.8)
        }

        // Phase 3: Reveal (2.0-3.0s)
        var delay: Double = 2.0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                xpScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    xpScale = 1.0
                }
            }
        }

        delay += 0.3

        if reward.scratchCard {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SplurjHaptics.rewardItemReveal()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showCard = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
                cardBounce = true
            }
            delay += 0.3
        }

        if reward.essence > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SplurjHaptics.rewardItemReveal()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showEssence = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
                essenceFly = true
            }
            delay += 0.3
        }

        if reward.bossDamage > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SplurjHaptics.bossDamage()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showBoss = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
                swordSlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
                damageFloat = true
            }
            delay += 0.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            SplurjHaptics.streakIncrement()
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
            showStreak = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                streakCount = 1
                flameActive.toggle()
            }
        }
        delay += 0.4

        // Phase 4: Celebration (3.0-4.0s)
        if reward.scratchCard {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showCardZoom = true
                    cardZoomScale = 1.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        cardZoomScale = 1.0
                    }
                }
            }
            delay += 0.5
        }

        if reward.didLevelUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SplurjHaptics.levelUp()
                goldBurst = true

                withAnimation(.easeInOut(duration: 0.06).repeatCount(6, autoreverses: true)) {
                    screenShake = 3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    screenShake = 0
                }
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                showLevelUp = true
                levelUpScale = 1.0
            }
            delay += 0.7
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            showConfetti = true
        }

        // Streak bonus cards
        if reward.streakBonusCards > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SplurjHaptics.rewardItemReveal()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showStreakCards = true
            }
            delay += 0.3
        }

        // Double XP indicator
        if reward.hasDoubleXP {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showDoubleXP = true
            }
            delay += 0.2
        }

        // Phase 5: Social
        delay += 0.5

        if reward.tiktokMoment != nil {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showShare = true
            }
            delay += 0.5
        }

        // Vault prompt
        if reward.scratchCard && onOpenVault != nil {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                showVaultPrompt = true
            }
            delay += 0.3
        }

        withAnimation(.easeOut(duration: 0.3).delay(delay + 0.2)) {
            canDismiss = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 1.0) {
            AppReviewManager.shared.requestReviewAfterDelay(seconds: 0.5)
        }
    }

    // MARK: - Reduced Motion

    private func startReducedSequence() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dimOverlay = 0.7
        titleOpacity = 1
        titleScale = 1.0
        subtitleOpacity = 1
        xpCounter = reward.xp
        xpFontSize = 32

        if reward.scratchCard { showCard = true; cardBounce = true }
        if reward.essence > 0 { showEssence = true; essenceFly = true }
        if reward.bossDamage > 0 { showBoss = true; swordSlash = true }
        if reward.didLevelUp {
            showLevelUp = true
            levelUpScale = 1.0
        }
        showStreak = true
        streakCount = 1
        if reward.streakBonusCards > 0 { showStreakCards = true }
        if reward.hasDoubleXP { showDoubleXP = true }
        if reward.tiktokMoment != nil { showShare = true }
        if reward.scratchCard && onOpenVault != nil { showVaultPrompt = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            canDismiss = true
        }
    }

    // MARK: - XP Counter

    private func animateXPCounter(target: Int, duration: Double) {
        let steps = 30
        let interval = duration / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.linear(duration: interval)) {
                    xpCounter = Int(Double(target) * Double(i) / Double(steps))
                    xpFontSize = 18 + CGFloat(i) / CGFloat(steps) * 42
                }
                if i % 4 == 0 {
                    SplurjHaptics.coinCollect()
                }
            }
        }
    }
}
