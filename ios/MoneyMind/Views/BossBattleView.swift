import SwiftUI
import SwiftData

struct BossBattleView: View {
    let player: PlayerProfile
    let zone: QuestZone
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shaking: Bool = false
    @State private var attackFlash: Bool = false
    @State private var showDefeatOverlay: Bool = false
    @State private var bossBreathing: Bool = false
    @State private var glowPulsing: Bool = false

    private var damagePercent: CGFloat {
        CGFloat(player.currentBossDamageDealt) / CGFloat(max(1, zone.bossHP))
    }

    private var remainingHP: Int {
        max(0, zone.bossHP - player.currentBossDamageDealt)
    }

    private var canDefeat: Bool {
        player.currentBossDamageDealt >= zone.bossHP
    }

    private var hpFraction: CGFloat {
        max(0, 1.0 - damagePercent)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Color(hex: 0x1A0A0A)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.bossRed.opacity(canDefeat ? 0.08 : 0.04), .clear],
                center: .center, startRadius: 50, endRadius: 400
            )
            .offset(y: -60)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header.padding(.top, 16)
                Spacer()
                bossNameSection
                bossIconSection.padding(.top, 8)
                Spacer().frame(height: 36)
                hpBarSection.padding(.horizontal, 40)
                Spacer().frame(height: 20)
                objectiveSection.padding(.horizontal, 40)
                Spacer().frame(height: 12)
                damageInfoSection.padding(.horizontal, 40)
                Spacer()

                if canDefeat {
                    finalBlowButton
                        .padding(.horizontal, 40)
                        .padding(.bottom, 48)
                } else {
                    questsNeededHint.padding(.bottom, 48)
                }
            }

            if showDefeatOverlay {
                defeatOverlay
                    .transition(.opacity)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            bossBreathing = true
            glowPulsing = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(zone.rawValue)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1)
                Text("Zone Boss")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.bossRed)
                    .tracking(1.5)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Boss Name

    private var bossNameSection: some View {
        VStack(spacing: 6) {
            Text(zone.bossName.uppercased())
                .font(Typography.displayMedium)
                .foregroundStyle(Theme.bossRed)
                .tracking(3)
                .neonGlow(color: Theme.neonRed, radius: 20, pulses: hpFraction < 0.25)
                .multilineTextAlignment(.center)
            Text("Level \(zone.levelRange.upperBound) Guardian")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Boss Icon

    private var bossIconSection: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.bossRed.opacity(0.25), .clear], center: .center, startRadius: 30, endRadius: 130))
                .frame(width: 260, height: 260)
                .scaleEffect(glowPulsing ? 1.1 : 0.9)
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulsing)

            Image(systemName: bossIcon)
                .font(Typography.displayLarge)
                .foregroundStyle(
                    LinearGradient(colors: [Theme.bossRed, Color(hex: 0x991B1B)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Theme.bossRed.opacity(0.6), radius: 30)
                .offset(x: shaking ? -5 : 5)
                .scaleEffect(reduceMotion ? 1.0 : (bossBreathing ? 1.02 : 0.98))
                .animation(reduceMotion ? nil : .easeInOut(duration: 3).repeatForever(autoreverses: true), value: bossBreathing)
                .animation(.easeInOut(duration: 0.06).repeatCount(8, autoreverses: true), value: shaking)
                .opacity(attackFlash ? 0.3 : 1.0)

            if damagePercent >= 0.5 {
                crackOverlay.opacity(min(1.0, Double(damagePercent - 0.5) * 4.0))
            }
        }
    }

    private var crackOverlay: some View {
        ZStack {
            Image(systemName: "bolt.fill")
                .font(Typography.displayMedium)
                .foregroundStyle(Theme.bossRed.opacity(0.3))
                .rotationEffect(.degrees(-30))
                .offset(x: 15, y: -10)
            if damagePercent >= 0.75 {
                Image(systemName: "bolt.fill")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.bossRed.opacity(0.4))
                    .rotationEffect(.degrees(45))
                    .offset(x: -20, y: 15)
            }
        }
    }

    // MARK: - HP Bar

    private var hpBarSection: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(Typography.labelSmall)
                        .foregroundStyle(hpBarColors.first ?? Theme.bossRed)
                    Text("HP")
                        .font(Typography.labelSmall)
                        .foregroundStyle(hpBarColors.first ?? Theme.bossRed)
                }
                Spacer()
                Text("\(remainingHP) / \(zone.bossHP)")
                    .font(Typography.moneySmall)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Boss HP: \(remainingHP) of \(zone.bossHP)")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.elevated)
                        .frame(height: 24)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: hpBarColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * hpFraction, height: 24)
                        .animation(.spring(response: 0.8), value: damagePercent)
                        .shadow(color: hpBarColors.first?.opacity(0.4) ?? .clear, radius: 8)
                }
            }
            .frame(height: 24)

            HStack {
                Text("Damage dealt: \(player.currentBossDamageDealt)")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Text(canDefeat ? "Ready to defeat" : "\(remainingHP) HP remaining")
                    .font(Typography.labelSmall)
                    .foregroundStyle(canDefeat ? Theme.gold : (hpBarColors.first?.opacity(0.7) ?? .clear))
            }
        }
    }

    // MARK: - Objective

    private var objectiveSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.bossRed.opacity(0.7))
                Text("Objective")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.bossRed.opacity(0.7))
                    .tracking(1)
            }
            Text(zone.bossDescription)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Damage Info

    private var damageInfoSection: some View {
        VStack(spacing: 4) {
            Text("Every quest you complete deals damage to this boss")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Text("Defeat the boss to unlock the next zone")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Quests Needed Hint

    private var questsNeededHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.circle.fill")
                .font(Typography.labelLarge)
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("Complete quests to deal damage")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Capsule().fill(Theme.surface))
    }

    // MARK: - Final Blow Button

    private var finalBlowButton: some View {
        Button {
            deliverFinalBlow()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(Typography.headingLarge)
                Text("DELIVER FINAL BLOW")
                    .font(Typography.headingMedium)
            }
            .foregroundStyle(Theme.buttonTextOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [Theme.gold, Theme.axisRisk], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.gold.opacity(0.5), radius: 20)
        }
        .symbolEffect(.bounce, isActive: canDefeat)
    }

    // MARK: - Actions

    private func deliverFinalBlow() {
        SplurjHaptics.bossDefeated()
        shaking = true
        attackFlash = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { attackFlash = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { attackFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { attackFlash = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            shaking = false
            let engine = QuestEngine(modelContext: modelContext)
            let success = engine.defeatBoss(player: player, zone: zone)
            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showDefeatOverlay = true
                    }
                }
            }
        }
    }

    // MARK: - Defeat Overlay

    private var defeatOverlay: some View {
        ZStack {
            Theme.background.opacity(0.95).ignoresSafeArea()

            ConfettiCanvasView(
                active: showDefeatOverlay,
                colors: [Theme.accent, Theme.gold, .white, Theme.neonPurple, Theme.axisRisk],
                particleCount: reduceMotion ? 0 : 50
            )
            .drawingGroup()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "trophy.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.gold)
                    .symbolEffect(.bounce, value: showDefeatOverlay)
                    .shadow(color: Theme.gold.opacity(0.4), radius: 20)
                    .holographicSheen(isActive: !reduceMotion)

                Text("BOSS DEFEATED")
                    .font(Typography.displayMedium)
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.gold, Theme.axisRisk], startPoint: .leading, endPoint: .trailing)
                    )
                    .neonGlow(color: Theme.neonGold, radius: 30)

                Text("You defeated \(zone.bossName)")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)

                lootSection

                zoneProgressSection

                Spacer()

                Button {
                    SplurjHaptics.cardTap()
                    CeremonyOverlayManager.shared.dismiss()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isFinalBoss
                            ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.axisRisk], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Theme.accent)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
        .sensoryFeedback(.success, trigger: showDefeatOverlay)
    }

    private var lootSection: some View {
        VStack(spacing: 10) {
            lootRow(icon: "star.fill", title: "+500 XP", subtitle: "Boss defeat bonus", color: Theme.gold)
            lootRow(icon: "creditcard.fill", title: "3 Scratch Cards", subtitle: "Boss loot drop", color: Theme.accent)
            lootRow(icon: "diamond.fill", title: "+100 Essence", subtitle: "Rare boss materials", color: Theme.neonPurple)
            lootRow(icon: "shield.checkered", title: "Boss Slayer Badge", subtitle: "Defeated \(zone.bossName)", color: Theme.neonRed)
        }
        .padding(.horizontal, 32)
    }

    private func lootRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Parallax3DCard(maxRotation: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: icon).font(Typography.headingLarge).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Typography.headingSmall).foregroundStyle(.white)
                    Text(subtitle).font(Typography.labelSmall).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 0.5))
            )
        }
    }

    @ViewBuilder
    private var zoneProgressSection: some View {
        if let next = nextZone {
            VStack(spacing: 8) {
                Text("NEW ZONE UNLOCKED")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accent)
                    .tracking(3)
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.accent.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: next.sfSymbol).font(Typography.headingLarge).foregroundStyle(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.rawValue).font(Typography.headingMedium).foregroundStyle(.white)
                        Text("Levels \(next.levelRange.lowerBound)-\(next.levelRange.upperBound)")
                            .font(Typography.bodySmall).foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                )
                .depthPop(intensity: 0.8)
            }
            .padding(.horizontal, 32)
        } else {
            VStack(spacing: 8) {
                Text("ALL ZONES COMPLETE")
                    .font(Typography.labelSmall).foregroundStyle(Theme.gold).tracking(3)
                Text("You have achieved financial mastery")
                    .font(Typography.bodyMedium).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private var bossIcon: String {
        switch zone {
        case .awakening: return "eye.trianglebadge.exclamationmark.fill"
        case .budgetForge: return "flame.circle.fill"
        case .savingsCitadel: return "building.columns.circle.fill"
        case .incomeFrontier: return "lizard.fill"
        case .legacy: return "crown.fill"
        }
    }

    private var hpBarColors: [Color] {
        if hpFraction > 0.5 { return [Theme.bossRed, Color(hex: 0xDC2626)] }
        if hpFraction > 0.25 { return [Theme.axisRisk, Color(hex: 0xF59E0B)] }
        return [Theme.accent, Theme.accentDim]
    }

    private var isFinalBoss: Bool { zone == .legacy }

    private var nextZone: QuestZone? {
        let all = QuestZone.allCases
        guard let idx = all.firstIndex(of: zone), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
}
