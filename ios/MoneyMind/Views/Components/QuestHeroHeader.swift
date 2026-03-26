import SwiftUI

struct QuestHeroHeader: View {
    let player: PlayerProfile
    @State private var xpAnimating: Bool = false
    @State private var avatarGlow: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: player.currentQuestZone.gradientColors + [player.currentQuestZone.gradientColors.first ?? Theme.accent],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 72, height: 72)
                        .blur(radius: avatarGlow ? 6 : 2)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 2).repeatForever(), value: avatarGlow)

                    Image(systemName: avatarIcon(stage: player.avatarStage))
                        .font(Typography.displayMedium)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent, Theme.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .background(Theme.elevated)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(player.activeTitle)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)
                        .textCase(.uppercase)

                    Text("Level \(player.level)")
                        .font(Typography.displaySmall)
                        .foregroundStyle(.white)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.elevated)
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.accent.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * player.xpProgressFraction, height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.3), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(x: xpAnimating ? geo.size.width : -geo.size.width)
                                        .animation(reduceMotion ? nil : .linear(duration: 2).repeatForever(autoreverses: false), value: xpAnimating)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Text("\(player.xpProgressInCurrentLevel) / \(player.xpForCurrentLevel) XP")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 12)
                }

                Spacer()

                VStack(spacing: 2) {
                    Image(systemName: player.questStreak > 0 ? "flame.fill" : "flame")
                        .font(Typography.displaySmall)
                        .foregroundStyle(player.questStreak > 0 ? Theme.axisRisk : Theme.textMuted)
                        .symbolEffect(.pulse, isActive: player.questStreak >= 7 && !reduceMotion)

                    Text("\(player.questStreak)")
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)

                    Text("streak")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .onAppear {
            if !reduceMotion {
                xpAnimating = true
                avatarGlow = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(player.level), \(player.activeTitle). \(player.xpProgressInCurrentLevel) of \(player.xpForCurrentLevel) XP. \(player.questStreak) day streak.")
    }

    private func avatarIcon(stage: Int) -> String {
        switch stage {
        case 0: return "shield.fill"
        case 1: return "bolt.shield.fill"
        case 2: return "building.columns.fill"
        case 3: return "crown.fill"
        default: return "star.fill"
        }
    }
}
