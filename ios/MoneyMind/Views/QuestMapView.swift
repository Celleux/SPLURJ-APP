import SwiftUI
import SwiftData

struct QuestMapView: View {
    let player: PlayerProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedZone: QuestZone?
    @State private var appeared: Bool = false
    @State private var particlePhase: Bool = false

    private var zones: [QuestZone] {
        QuestZone.allCases.reversed()
    }

    private var defeatedZones: Set<String> {
        Set(player.bossesDefeated)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(zones.enumerated()), id: \.element) { index, zone in
                            let state = zoneState(zone)

                            ZoneMapNode(
                                zone: zone,
                                state: state,
                                questsCompleted: questsCompletedInZone(zone),
                                totalQuests: totalQuestsInZone(zone),
                                bossDamage: bossDamageForZone(zone),
                                isSelected: selectedZone == zone,
                                particlePhase: particlePhase
                            )
                            .id(zone)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedZone = selectedZone == zone ? nil : zone
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            .padding(.horizontal, 20)

                            if index < zones.count - 1 {
                                PathConnector(
                                    isCompleted: zoneState(zone) == .cleared
                                )
                            }
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 80)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(player.currentQuestZone, anchor: .center)
                        }
                    }
                    withAnimation { appeared = true }
                    particlePhase = true
                }
            }

            VStack {
                mapHeader
                Spacer()
            }
        }
    }

    // MARK: - Header

    private var mapHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("QUEST MAP")
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
                    .tracking(3)
                Text("Level \(player.level)")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [Theme.background, Theme.background.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Zone State

    enum ZoneNodeState {
        case cleared
        case current
        case locked
    }

    func zoneState(_ zone: QuestZone) -> ZoneNodeState {
        if defeatedZones.contains(zone.rawValue) {
            return .cleared
        }
        if zone == player.currentQuestZone {
            return .current
        }
        if zone.levelRange.lowerBound <= player.level {
            return .current
        }
        return .locked
    }

    private func questsCompletedInZone(_ zone: QuestZone) -> Int {
        let zoneQuests = QuestDataManager.shared.quests(forZone: zone)
        let engine = QuestEngine(modelContext: modelContext)
        return zoneQuests.filter { engine.isQuestCompleted($0.id) }.count
    }

    private func totalQuestsInZone(_ zone: QuestZone) -> Int {
        QuestDataManager.shared.quests(forZone: zone).count
    }

    private func bossDamageForZone(_ zone: QuestZone) -> Int {
        if zone == player.currentQuestZone {
            return player.currentBossDamageDealt
        }
        if defeatedZones.contains(zone.rawValue) {
            return zone.bossHP
        }
        return 0
    }
}

// MARK: - Zone Map Node

struct ZoneMapNode: View {
    let zone: QuestZone
    let state: QuestMapView.ZoneNodeState
    let questsCompleted: Int
    let totalQuests: Int
    let bossDamage: Int
    let isSelected: Bool
    let particlePhase: Bool

    @State private var glowPulsing: Bool = false

    private var isLocked: Bool { state == .locked }
    private var isCleared: Bool { state == .cleared }
    private var isCurrent: Bool { state == .current }

    private var zoneAccentColor: Color {
        switch zone {
        case .awakening: return Theme.axisEmotional
        case .budgetForge: return Theme.lavender
        case .savingsCitadel: return Theme.accent
        case .incomeFrontier: return Theme.gold
        case .legacy: return Theme.celebrationYellow
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            mainCard
            if isSelected && !isLocked {
                expandedDetails
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(isLocked ? 0.4 : 1.0)
        .onAppear { glowPulsing = true }
    }

    private var mainCard: some View {
        HStack(spacing: 16) {
            zoneIcon
            zoneInfo
            Spacer()
            stateIndicator
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: zone.gradientColors.map { $0.opacity(isLocked ? 0.3 : 1.0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.surface.opacity(0.6))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isCurrent ? zoneAccentColor.opacity(0.6) :
                    isCleared ? Theme.gold.opacity(0.4) :
                    Theme.border.opacity(0.3),
                    lineWidth: isCurrent ? 1.5 : 0.5
                )
        )
        .shadow(
            color: isCurrent ? zoneAccentColor.opacity(0.2) : .clear,
            radius: isCurrent ? 16 : 0
        )
    }

    private var zoneIcon: some View {
        ZStack {
            if isCurrent {
                Circle()
                    .fill(zoneAccentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .scaleEffect(glowPulsing ? 1.15 : 0.95)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulsing)
            }

            Circle()
                .fill(
                    isCleared ? Theme.gold.opacity(0.2) :
                    isCurrent ? zoneAccentColor.opacity(0.2) :
                    Theme.elevated.opacity(0.5)
                )
                .frame(width: 56, height: 56)

            Circle()
                .stroke(
                    isCleared ? Theme.gold.opacity(0.5) :
                    isCurrent ? zoneAccentColor.opacity(0.4) :
                    Theme.border,
                    lineWidth: 1.5
                )
                .frame(width: 56, height: 56)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.textMuted)
            } else {
                Image(systemName: zone.sfSymbol)
                    .font(Typography.displaySmall)
                    .foregroundStyle(
                        isCleared ? Theme.gold :
                        zoneAccentColor
                    )
            }
        }
    }

    private var zoneInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(zone.rawValue.uppercased())
                .font(Typography.labelSmall)
                .foregroundStyle(
                    isCleared ? Theme.gold :
                    isCurrent ? zoneAccentColor :
                    Theme.textMuted
                )
                .tracking(1.5)

            Text("Levels \(zone.levelRange.lowerBound)–\(zone.levelRange.upperBound)")
                .font(Typography.headingLarge)
                .foregroundStyle(isLocked ? Theme.textMuted : .white)

            if isCurrent {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 6, height: 6)
                    Text("YOU ARE HERE")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)
                }
            } else if isCleared {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.labelSmall)
                    Text("CLEARED")
                        .font(Typography.labelSmall)
                        .tracking(1)
                }
                .foregroundStyle(Theme.gold)
            } else {
                Text("Reach Level \(zone.levelRange.lowerBound) to unlock")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private var stateIndicator: some View {
        VStack(spacing: 4) {
            if isCleared {
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.gold.opacity(0.2))
                    Image(systemName: "checkmark")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.gold)
                }
            } else if isCurrent {
                Image(systemName: "chevron.down")
                    .font(Typography.headingSmall)
                    .foregroundStyle(zoneAccentColor.opacity(0.6))
                    .rotationEffect(.degrees(isSelected ? 180 : 0))
            } else {
                Image(systemName: "lock.circle")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textDisabled)
            }
        }
    }

    private var expandedDetails: some View {
        VStack(spacing: 14) {
            Text(zone.themeDescription)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                statPill(
                    icon: "scroll.fill",
                    label: "Quests",
                    value: "\(questsCompleted)/\(totalQuests)"
                )

                statPill(
                    icon: "heart.fill",
                    label: "Boss HP",
                    value: isCleared ? "Defeated" : "\(max(0, zone.bossHP - bossDamage))/\(zone.bossHP)"
                )
            }

            if !isCleared {
                let progress = totalQuests > 0 ? Double(questsCompleted) / Double(totalQuests) : 0
                VStack(spacing: 6) {
                    HStack {
                        Text("Zone Progress")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(zoneAccentColor)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.elevated)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(zoneAccentColor)
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: bossIcon)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(isCleared ? Theme.textMuted : Theme.bossRed)
                Text(zone.bossName)
                    .font(Typography.labelMedium)
                    .foregroundStyle(isCleared ? Theme.textMuted : .white)
                    .strikethrough(isCleared, color: Theme.gold)
                Spacer()
                if isCleared {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.gold.opacity(0.5))
                }
            }
        }
        .padding(18)
        .padding(.top, 0)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 18,
                topTrailingRadius: 0
            )
            .fill(Theme.surface.opacity(0.8))
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 18,
                topTrailingRadius: 0
            )
            .stroke(Theme.border.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func statPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(Typography.bodySmall)
                .foregroundStyle(zoneAccentColor.opacity(0.7))

            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                    .tracking(0.5)
                Text(value)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.elevated.opacity(0.8))
        )
    }

    private var bossIcon: String {
        switch zone {
        case .awakening: return "eye.trianglebadge.exclamationmark.fill"
        case .budgetForge: return "flame.circle.fill"
        case .savingsCitadel: return "building.columns.circle.fill"
        case .incomeFrontier: return "lizard.fill"
        case .legacy: return "crown.fill"
        }
    }
}

// MARK: - Path Connector

struct PathConnector: View {
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { _ in
                Circle()
                    .fill(isCompleted ? Theme.accent : Theme.textMuted.opacity(0.3))
                    .frame(width: isCompleted ? 5 : 4, height: isCompleted ? 5 : 4)
            }
        }
        .frame(height: 32)
    }
}

// MARK: - Fileprivate Zone State Extension


