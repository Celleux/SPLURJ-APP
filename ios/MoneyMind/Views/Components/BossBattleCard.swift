import SwiftUI

struct BossBattleCard: View {
    let zone: QuestZone
    let damageDealt: Int
    let onFight: () -> Void

    private var damagePercent: CGFloat {
        CGFloat(damageDealt) / CGFloat(max(1, zone.bossHP))
    }

    private var canFight: Bool {
        damageDealt >= zone.bossHP
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.bossRed)
                Text("Zone Boss")
                    .font(Typography.headingSmall)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.bossRed.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: bossIcon(for: zone))
                        .font(Typography.displayLarge)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.bossRed, Color(hex: 0x991B1B)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.bossRed.opacity(0.5), radius: 20)
                }

                VStack(spacing: 4) {
                    Text(zone.bossName.uppercased())
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.bossRed)
                        .tracking(2)

                    Text(zone.rawValue)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 6) {
                    HStack {
                        Text("HP")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.bossRed)
                        Spacer()
                        Text("\(max(0, zone.bossHP - damageDealt)) / \(zone.bossHP)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.elevated)
                                .frame(height: 16)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: hpColors(percent: 1.0 - damagePercent),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * max(0, 1.0 - damagePercent), height: 16)
                                .animation(.spring(response: 0.6), value: damagePercent)
                        }
                    }
                    .frame(height: 16)
                }
                .padding(.horizontal, 24)

                Text("Objective: \(zone.bossDescription)")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !canFight {
                    Text("Complete quests to deal damage")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    Button {
                        onFight()
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("DELIVER FINAL BLOW")
                                .font(Typography.headingMedium)
                        }
                        .foregroundStyle(Theme.buttonTextOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Theme.gold, Theme.axisRisk],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Theme.gold.opacity(0.5), radius: 16)
                    }
                    .padding(.horizontal, 24)
                    .sensoryFeedback(.impact(weight: .heavy), trigger: UUID())
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.bossRed.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 16)
        }
    }

    private func bossIcon(for zone: QuestZone) -> String {
        switch zone {
        case .awakening: return "eye.trianglebadge.exclamationmark.fill"
        case .budgetForge: return "flame.circle.fill"
        case .savingsCitadel: return "building.columns.circle.fill"
        case .incomeFrontier: return "lizard.fill"
        case .legacy: return "crown.fill"
        }
    }

    private func hpColors(percent: CGFloat) -> [Color] {
        if percent > 0.5 { return [Theme.bossRed, Color(hex: 0xDC2626)] }
        if percent > 0.25 { return [Theme.axisRisk, Color(hex: 0xF59E0B)] }
        return [Theme.accent, Theme.accentDim]
    }
}
