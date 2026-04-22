import SwiftUI

// MARK: - Splurj Profile — v2 (canonical port of explorations/v2-profile.jsx)
//
// Segmented sheet: Journey · Stats · Settings.
//   Journey  — hero (avatar/name/track/LV+XP bar) + timeline spine of events
//   Stats    — 2×2 KPI grid + TOP SPLURGE TRIGGERS bar chart + share cards
//   Settings — SPLURJI section (Appearance / Notifications / Privacy / Health)
//              + ACCOUNT section (Subscription / Help / Sign out)

struct SplurjProfileView: View {
    var variant: SplurjVariant = .her
    var personality: SplurjPersonality? = .empath
    var stage: SlimeStage = .leafy
    var level: Int = 7
    var xpProgress: Double = 0.62
    var xpPoints: Int = 1240
    var trackLabel: String = "Stress Shield"
    var name: String = "you"
    var streak: Int = 23
    var longestStreak: Int = 31
    var totalSaved: Int = 2847
    var pactsWon: Int = 8
    var splurgeFreeDays: Int = 23
    var earnedBadges: Set<BadgeID> = []
    var equippedCosmetics: Set<CosmeticID> = []
    var journey: [JourneyEvent] = []
    var triggers: [TriggerRow] = []
    var subscriptionStatus: String = "Free plan"
    var notificationsOnCount: Int = 0
    var appleHealthConnected: Bool = false
    var unreadNotificationCount: Int = 0
    var pgsiDueThisMonth: Bool = false
    var onDismiss: (() -> Void)? = nil
    var onOpenNotifications: () -> Void = {}
    var onOpenPGSI: () -> Void = {}
    var onOpenMoneyWrapped: () -> Void = {}
    var onOpenVibeAnalytics: () -> Void = {}
    var onOpenBadgeGallery: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onOpenHealthSettings: () -> Void = {}
    var onOpenPaywall: () -> Void = {}
    var onOpenHelp: () -> Void = {}
    var onSignOut: () -> Void = {}

    @State private var segment: ProfileSegment = .journey
    @State private var activeShare: ShareTemplate? = nil
    @State private var shareImage: UIImage? = nil
    @State private var isSharePresented = false

    enum ShareTemplate: String, Identifiable {
        case streak, levelUp, savings
        var id: String { rawValue }
    }

    nonisolated enum ProfileSegment: String, CaseIterable, Identifiable, Sendable {
        case journey, stats, settings
        var id: String { rawValue }
        var title: String {
            switch self {
            case .journey:  "Journey"
            case .stats:    "Stats"
            case .settings: "Settings"
            }
        }
    }

    struct JourneyEvent: Identifiable, Hashable {
        let id: String
        let when: String           // "Today", "Yesterday", "Last Fri", "Nov 3"
        let title: String          // "Skipped the 10pm scroll"
        let xp: String             // "+20" or "—"
        let tone: Tone             // glow / honey / sky / muted
        let hero: Bool             // larger dot + glow (level-up moments)
        enum Tone: Hashable { case glow, honey, sky, muted }
    }

    struct TriggerRow: Identifiable, Hashable {
        let id: String
        let label: String
        let pct: Int
        let tone: Tone
        enum Tone: Hashable { case danger, honey, petal, sky }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                segmented
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        switch segment {
                        case .journey:  journeyBody
                        case .stats:    statsBody
                        case .settings: settingsBody
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
        .sheet(isPresented: $isSharePresented, onDismiss: {
            shareImage = nil
            activeShare = nil
        }) {
            if let shareImage {
                ShareSheetView(items: [shareImage])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Theme.cardTintHi, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(ProfileSegment.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { segment = s }
                } label: {
                    Text(s.title)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(segment == s ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(segment == s ? AnyShapeStyle(Theme.cardTintHi) : AnyShapeStyle(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Journey

    private var journeyBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            journeyHero
            Text("YOUR JOURNEY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
            journeyTimeline
        }
    }

    private var journeyHero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.glow.opacity(0.7), Color(hex: 0x4A8F3A)],
                            center: UnitPoint(x: 0.35, y: 0.3),
                            startRadius: 0, endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(Circle().strokeBorder(Theme.glow.opacity(0.35), lineWidth: 2))
                SplurjMascot(variant: variant, stage: stage, personality: personality, cosmetics: equippedCosmetics, size: 64)
                    .offset(y: 4)
                    .clipShape(Circle())
            }
            .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(stageName(stage)) \u{00B7} \(trackLabel) track")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 8) {
                    Text("LV \(String(format: "%02d", level)) \u{00B7} \(formatted(xpPoints)) XP")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(Theme.honey)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(Theme.honey).frame(width: geo.size.width * xpProgress)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 100)
                }
                .padding(.top, 3)
            }
        }
    }

    private var journeyTimeline: some View {
        VStack(spacing: 0) {
            if journey.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.textMuted)
                    Text("Your first moments will land here.")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Log a win or finish a pact to start the thread.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ZStack(alignment: .topLeading) {
                    LinearGradient(
                        colors: [Theme.glow.opacity(0.26), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(width: 2)
                    .padding(.leading, 10)

                    VStack(spacing: 0) {
                        ForEach(journey) { ev in
                            journeyRow(ev)
                        }
                    }
                }
            }
        }
    }

    private func journeyRow(_ ev: JourneyEvent) -> some View {
        let color = toneColor(ev.tone)
        return HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(Theme.background, lineWidth: 3))
                .shadow(color: ev.hero ? color : .clear, radius: 12)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(ev.title)
                        .font(.system(size: 13.5, weight: ev.hero ? .black : .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(ev.xp)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                }
                Text(ev.when)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.vertical, 8)
    }

    private func toneColor(_ tone: JourneyEvent.Tone) -> Color {
        switch tone {
        case .glow:  Theme.glow
        case .honey: Theme.honey
        case .sky:   Theme.sky
        case .muted: Theme.textMuted
        }
    }

    // MARK: - Stats

    private var statsBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
            LazyVGrid(columns: cols, spacing: 8) {
                statCard(label: "TOTAL SAVED", value: "$\(formatted(totalSaved))", color: Theme.glow)
                statCard(label: "PACTS WON",    value: "\(pactsWon)",                color: Theme.honey)
                statCard(label: "BEST STREAK",  value: "\(longestStreak)", unit: "d", color: Theme.glow)
                statCard(label: "SPLURGE-FREE DAYS", value: "\(splurgeFreeDays)",      color: Theme.sky)
            }

            Text("TOP SPLURGE TRIGGERS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
                .padding(.top, 4)

            VStack(spacing: 10) {
                if triggers.isEmpty {
                    Text("Splurji\u{2019}s still learning your patterns.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(triggers) { row in
                        triggerRow(row)
                    }
                }
            }
            .padding(14)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))

            shareRow
                .padding(.top, 4)
        }
    }

    private func statCard(label: String, value: String, unit: String = "", color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
    }

    private func triggerRow(_ row: TriggerRow) -> some View {
        let color = triggerColor(row.tone)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(row.pct)%")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(row.pct) / 100)
                }
            }
            .frame(height: 5)
        }
    }

    private func triggerColor(_ tone: TriggerRow.Tone) -> Color {
        switch tone {
        case .danger: Theme.danger
        case .honey:  Theme.honey
        case .petal:  Theme.petal
        case .sky:    Theme.sky
        }
    }

    private var shareRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHARE A WIN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
            HStack(spacing: 8) {
                shareButton(.streak,  title: "Streak",  systemImage: "flame.fill",     color: Theme.honey)
                shareButton(.levelUp, title: "Level up", systemImage: "sparkles",       color: Theme.glow)
                shareButton(.savings, title: "Savings",  systemImage: "dollarsign.circle.fill", color: Theme.sky)
            }
        }
    }

    private func shareButton(_ template: ShareTemplate, title: String, systemImage: String, color: Color) -> some View {
        Button {
            Task { await generateAndShare(template) }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func generateAndShare(_ template: ShareTemplate) async {
        activeShare = template
        let card: AnyView
        switch template {
        case .streak:
            card = AnyView(ShareCardStreak(variant: variant, days: streak, username: "@\(name)", size: .story))
        case .levelUp:
            card = AnyView(ShareCardLevelUp(variant: variant, level: level, size: .story))
        case .savings:
            card = AnyView(ShareCardSavings(variant: variant, amount: totalSaved, size: .story))
        }
        let image = SplurjShareRenderer.render(card, size: .story)
        if let image {
            shareImage = image
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isSharePresented = true
        }
    }

    // MARK: - Settings

    private var settingsBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECOVERY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
                .padding(.top, 4)
            settingsRow(
                icon: "bell.fill",
                label: "Notifications",
                value: unreadNotificationCount > 0 ? "\(unreadNotificationCount) new" : nil,
                onTap: onOpenNotifications
            )
            settingsRow(
                icon: "heart.text.square.fill",
                label: "Recovery check-in",
                value: pgsiDueThisMonth ? "Due" : "Monthly",
                highlight: pgsiDueThisMonth,
                onTap: onOpenPGSI
            )
            settingsRow(
                icon: "face.smiling.inverse",
                label: "Vibe insights",
                value: nil,
                onTap: onOpenVibeAnalytics
            )
            settingsRow(
                icon: "rosette",
                label: "Badges",
                value: earnedBadges.isEmpty ? nil : "\(earnedBadges.count) earned",
                onTap: onOpenBadgeGallery
            )

            Text("SPLURJI")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
                .padding(.top, 14)
            settingsRow(icon: "sparkles",         label: "Appearance",          value: "Night terrarium", onTap: onOpenSettings)
            settingsRow(icon: "heart.fill",       label: "Apple Health",        value: appleHealthConnected ? "Connected" : "Not connected", onTap: onOpenHealthSettings)
            settingsRow(icon: "gift.fill",        label: "Money Wrapped",       value: nil, onTap: onOpenMoneyWrapped)

            Text("ACCOUNT")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
                .padding(.top, 14)
            settingsRow(icon: "star.fill",        label: "Splurji+ subscription", value: subscriptionStatus, onTap: onOpenPaywall)
            settingsRow(icon: "bubble.left.fill", label: "Help & feedback",       value: nil, onTap: onOpenHelp)
            settingsRow(icon: "arrow.right.square.fill", label: "Sign out",       value: nil, danger: true, onTap: onSignOut)
        }
    }

    private func settingsRow(
        icon: String,
        label: String,
        value: String?,
        highlight: Bool = false,
        danger: Bool = false,
        onTap: @escaping () -> Void = {}
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(danger ? Theme.danger : (highlight ? Theme.honey : Theme.textSecondary))
                    .frame(width: 30, height: 30)
                    .background(Theme.cardTintHi, in: RoundedRectangle(cornerRadius: 9))
                Text(label)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(danger ? Theme.danger : Theme.textPrimary)
                Spacer()
                if let value {
                    Text(value)
                        .font(.system(size: 11.5, weight: highlight ? .heavy : .regular))
                        .foregroundStyle(highlight ? Theme.honey : Theme.textSecondary)
                }
                if !danger {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(13)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(highlight ? Theme.honey.opacity(0.4) : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func stageName(_ s: SlimeStage) -> String {
        switch s {
        case .seedling:  "Seedling"
        case .sprout:    "Sprout"
        case .grass:     "Grass"
        case .leafy:     "Leafy Cap"
        case .flowering: "Flowering"
        case .bonsai:    "Bonsai"
        }
    }

    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

#if DEBUG
#Preview("Profile · journey") {
    SplurjProfileView(
        name: "Maya",
        streak: 23,
        longestStreak: 31,
        totalSaved: 2847,
        pactsWon: 8,
        splurgeFreeDays: 23,
        journey: [
            .init(id: "1", when: "Today",     title: "Skipped the 10pm scroll", xp: "+20",  tone: .glow,  hero: false),
            .init(id: "2", when: "Yesterday", title: "Pact day 18 with Sam",    xp: "+40",  tone: .honey, hero: false),
            .init(id: "3", when: "Mon",       title: "Leveled up \u{00B7} Leafy Cap", xp: "+120", tone: .glow, hero: true),
        ],
        triggers: [
            .init(id: "t1", label: "Late-night boredom", pct: 42, tone: .danger),
            .init(id: "t2", label: "Payday rewards",     pct: 28, tone: .honey),
            .init(id: "t3", label: "Argument aftermath", pct: 18, tone: .petal),
            .init(id: "t4", label: "FOMO scroll",        pct: 12, tone: .sky),
        ]
    )
}
#endif
