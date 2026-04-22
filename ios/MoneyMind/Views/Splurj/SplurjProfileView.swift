import SwiftUI

// MARK: - Splurj Profile — v2
//
// Replaces the 13-section legacy profile sheet with a tighter, mascot-
// first dashboard: hero with big mascot + level ring, stats, journey
// milestones, settings.

struct SplurjProfileView: View {
    var variant: SplurjVariant = .her
    var personality: SplurjPersonality? = .empath
    var stage: SlimeStage = .leafy
    var level: Int = 14
    var xpProgress: Double = 0.62
    var streak: Int = 23
    var totalSaved: Int = 247
    var purchasesResisted: Int = 38
    var earnedBadges: Set<BadgeID> = [.streak7, .save100, .pactFirst, .onboard]
    var equippedCosmetics: Set<CosmeticID> = []
    var onChangeVariant: () -> Void = {}
    var onEditPersonality: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let onDismiss {
                        closeBar(onDismiss: onDismiss)
                    }
                    heroCard
                    statsGrid
                    badgesStrip
                    journeyPreview
                    settingsLinks
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
            }
        }
    }

    private var badgesStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Kicker("Badges \u{00B7} \(earnedBadges.count) / \(BadgeID.allCases.count)",
                       color: Theme.textMuted)
                Spacer()
                Text("See all")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.honey)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BadgeID.allCases) { id in
                        VStack(spacing: 4) {
                            SplurjBadge(id: id, size: 64, locked: !earnedBadges.contains(id))
                            Text(id.name)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                                .frame(width: 76)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
    }

    private func closeBar(onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x0F2820), Color(hex: 0x0A1612)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RadialGradient(
                        colors: [variant.accent.opacity(0.28), .clear],
                        center: UnitPoint(x: 0.5, y: 0.8),
                        startRadius: 0, endRadius: 160
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Theme.borderHi, lineWidth: 1))

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: xpProgress)
                        .stroke(Theme.honey, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    SplurjMascot(
                        variant: variant,
                        stage: stage,
                        personality: personality,
                        cosmetics: equippedCosmetics,
                        size: 170
                    )
                }
                .frame(width: 200, height: 200)

                HStack(spacing: 10) {
                    Pill("LEVEL \(level)", color: Theme.honey)
                    Pill(stage.name.uppercased(), color: Theme.glow)
                    if let personality {
                        Pill(personality.displayName.uppercased(), color: personality.accent)
                    }
                }

                HStack(spacing: 8) {
                    Button(action: onChangeVariant) {
                        pillButton("Change Splurj", icon: "figure")
                    }
                    .buttonStyle(.plain)
                    Button(action: onEditPersonality) {
                        pillButton("Re-take DNA", icon: "wand.and.stars")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 22)
        }
    }

    private func pillButton(_ label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .heavy))
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.cardTintHi, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            statTile(label: "STREAK", value: "\(streak)d", color: Theme.honey)
            statTile(label: "SAVED", value: "$\(totalSaved)", color: Theme.glow)
            statTile(label: "RESISTED", value: "\(purchasesResisted)", color: variant.accent)
        }
    }

    private func statTile(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(Theme.textMuted)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
    }

    private var journeyPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Kicker("Journey", color: Theme.textMuted)
                Spacer()
                Text("See all")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.honey)
            }
            HStack(spacing: 8) {
                ForEach(SlimeStage.allCases) { s in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(s.rawValue <= stage.rawValue ? variant.accent : Color.white.opacity(0.08))
                            .frame(width: 10, height: 10)
                            .shadow(color: s == stage ? variant.accent : .clear, radius: 4)
                        Text("\(s.rawValue)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(s.rawValue <= stage.rawValue ? Theme.textPrimary : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        }
    }

    private var settingsLinks: some View {
        VStack(spacing: 8) {
            settingsLink(icon: "gearshape.fill", title: "Settings", action: onOpenSettings)
            settingsLink(icon: "bell.fill", title: "Notifications") { }
            settingsLink(icon: "creditcard.fill", title: "Bank connection") { }
            settingsLink(icon: "heart.fill", title: "Apple Health") { }
            settingsLink(icon: "trash.fill", title: "Delete data", tint: Theme.danger) { }
        }
    }

    private func settingsLink(icon: String, title: String, tint: Color = Theme.textPrimary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(12)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Profile sheet") {
    SplurjProfileView(onDismiss: {})
}
#endif
