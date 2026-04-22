import SwiftUI
import SwiftData

// MARK: - Splurj Home (Hub) — v2
//
// The mascot's room. Segmented Today / Collection. Player command bar
// always on: feed · water · breathe · bed. Port of v2-hub.jsx.

struct SplurjHomeView: View {
    var variant: SplurjVariant = .her
    var personality: SplurjPersonality? = .builder
    var stage: SlimeStage = .leafy
    var level: Int = 7
    var onTabChange: ((SplurjTab) -> Void)? = nil

    @State private var segment: HomeSegment = .today
    @State private var mascotMood: SlimeMood = .happy
    @State private var needsFed: Double = 0.82
    @State private var needsHydrated: Double = 0.64
    @State private var needsRested: Double = 0.91
    @State private var cmdActive: CommandAction? = .breathe
    @State private var mascotTapCount: Int = 0

    nonisolated enum HomeSegment: String, CaseIterable, Identifiable, Sendable {
        case today, collection
        var id: String { rawValue }
        var title: String { self == .today ? "Today" : "Collection" }
    }

    nonisolated enum CommandAction: String, Sendable {
        case feed, water, breathe, bed
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    SplurjTopBar(
                        title: "Hub",
                        variant: variant,
                        level: level,
                        stateDotColor: Theme.glow
                    ) {
                        SplurjMascotPlaceholder(variant: variant)
                    }

                    segmentPicker
                        .padding(.horizontal, 22)

                    Group {
                        switch segment {
                        case .today:
                            todayContent
                        case .collection:
                            collectionContent
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer(minLength: 120)
                }
                .padding(.top, 8)
            }

            VStack(spacing: 0) {
                commandBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Segment picker

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            ForEach(HomeSegment.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        segment = s
                    }
                } label: {
                    Text(s.title)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(segment == s ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            segment == s
                            ? AnyShapeStyle(Theme.cardTintHi)
                            : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: segment == s ? .black.opacity(0.25) : .clear, radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Today

    private var todayContent: some View {
        VStack(spacing: 14) {
            terrariumCard
            needsRow
            unlocksSection
        }
    }

    private var terrariumCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x0F2820), Color(hex: 0x0A1612)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RadialGradient(
                        colors: [Theme.glow.opacity(0.35), .clear],
                        center: UnitPoint(x: 0.5, y: 0.9),
                        startRadius: 0, endRadius: 200
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    // Glass edge
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.07), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: 30)
                        .clipShape(
                            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, bottomLeading: 0, bottomTrailing: 0, topTrailing: 20))
                        )
                }

            FireflyField(points: [
                (40, 60, 1.0), (280, 80, 0.7), (60, 180, 0.8), (260, 200, 0.6)
            ])

            // Stump
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x6B4024), Color(hex: 0x3A2510)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 22)
                .shadow(color: .black.opacity(0.5), radius: 6, y: 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 18)

            // Mascot on stump
            SplurjMascot(variant: variant, stage: stage, mood: mascotMood, personality: personality, size: 200) {
                mascotTapCount += 1
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 24)

            VStack {
                HStack {
                    levelChip
                    Spacer()
                    Pill(weatherChipText, color: Theme.glow)
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(height: 260)
    }

    private var weatherChipText: String {
        switch mascotMood {
        case .alert: "\u{26A0} HIGH STRESS"
        case .sleeping: "\u{1F319} TUCKED IN"
        case .sad: "\u{1F327} DAMPER DAY"
        case .celebrating: "\u{2728} JUBILANT"
        default: "\u{2728} MOSSY NIGHT"
        }
    }

    private var levelChip: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LEVEL \(String(format: "%02d", level)) · \(stage.name.uppercased())")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(Theme.textMuted)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.08))
                .frame(width: 90, height: 4)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.honey)
                        .frame(width: 58.5, height: 4)
                        .shadow(color: Theme.honey, radius: 3)
                }
        }
    }

    private var needsRow: some View {
        HStack(spacing: 8) {
            NeedBar(label: "FED", value: needsFed, color: Theme.honey, systemImage: "leaf.fill")
            NeedBar(label: "HYDRATED", value: needsHydrated, color: Theme.sky, systemImage: "drop.fill")
            NeedBar(label: "RESTED", value: needsRested, color: Theme.glow, systemImage: "moon.fill")
        }
    }

    private var unlocksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Kicker("Available now", tracking: 1.4, color: Theme.textMuted)
                Spacer()
                Text("3 unlocks")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(spacing: 8) {
                unlockRow(emoji: "\u{1F33E}", title: "Plant a wildflower", sub: "3-min box breathing · +15 XP", color: Theme.glow)
                unlockRow(emoji: "\u{1F48E}", title: "Dew-drop meditation", sub: "5 min · calms HRV swings", color: Theme.sky)
                unlockRow(emoji: "\u{1F390}", title: "Wind-chime (new)", sub: "Earned from Sam pact · cosmetic", color: Theme.honey)
            }
        }
    }

    private func unlockRow(emoji: String, title: String, sub: String, color: Color) -> some View {
        Button { } label: {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 18))
                    .frame(width: 38, height: 38)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(color.opacity(0.27), lineWidth: 1))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(12)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Collection

    private var collectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Kicker("Evolution stages", tracking: 1.4, color: Theme.textMuted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(SlimeStage.allCases) { s in
                    stageCard(s)
                }
            }

            Kicker("Cosmetics · 7 / 24", tracking: 1.4, color: Theme.textMuted)
                .padding(.top, 6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(0..<12, id: \.self) { i in
                    cosmeticTile(i)
                }
            }
        }
    }

    private func stageCard(_ s: SlimeStage) -> some View {
        let unlocked = s.rawValue <= stage.rawValue
        return VStack(spacing: 4) {
            SplurjMascot(variant: variant, stage: s, personality: personality, size: 64)
                .frame(width: 64, height: 64)
            Text("LV \(String(format: "%02d", s.rawValue * 3))")
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(Theme.textMuted)
            Text(s.name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            if !unlocked {
                Text("\u{1F512} locked")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textMuted)
            } else if s == stage {
                Pill("NOW", color: Theme.glow)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(unlocked ? Theme.glow.opacity(0.35) : Theme.border, lineWidth: 1)
        )
        .opacity(unlocked ? 1.0 : 0.35)
    }

    private func cosmeticTile(_ i: Int) -> some View {
        let items = ["\u{1F33A}", "\u{1F344}", "\u{1F390}", "\u{2B50}", "\u{1F319}", "\u{1FAA8}", "\u{1F98B}"]
        let isLocked = i >= items.count
        return Text(isLocked ? "\u{1F512}" : items[i])
            .font(.system(size: 20))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(isLocked ? Color.white.opacity(0.02) : Theme.cardTint, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
            .opacity(isLocked ? 0.3 : 1.0)
    }

    // MARK: - Command bar

    private var commandBar: some View {
        HStack(spacing: 0) {
            commandButton(.feed, icon: "leaf.fill", label: "FEED")
            commandButton(.water, icon: "drop.fill", label: "WATER")
            commandButton(.breathe, icon: "wind", label: "BREATHE")
            commandButton(.bed, icon: "moon.fill", label: "BED")
        }
        .padding(8)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.borderHi, lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 12, y: 12)
    }

    private func commandButton(_ action: CommandAction, icon: String, label: String) -> some View {
        let isActive = cmdActive == action
        return Button {
            triggerCommand(action)
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isActive ? Theme.glow.opacity(0.18) : Theme.cardTintHi)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(isActive ? Theme.glow : Theme.border, lineWidth: 1)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isActive ? Theme.glow : Theme.textSecondary)
                }
                Text(label)
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(isActive ? Theme.glow : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isActive)
    }

    private func triggerCommand(_ action: CommandAction) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            cmdActive = action
        }
        switch action {
        case .feed:     needsFed = min(1.0, needsFed + 0.15); mascotMood = .celebrating
        case .water:    needsHydrated = min(1.0, needsHydrated + 0.15); mascotMood = .happy
        case .breathe:  mascotMood = .alert
        case .bed:      needsRested = min(1.0, needsRested + 0.15); mascotMood = .sleeping
        }
        // Revert to happy after a beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { mascotMood = .happy }
        }
    }
}

// MARK: - Need bar

private struct NeedBar: View {
    let label: String
    let value: Double
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(color)
            }
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: CGFloat(value) * 84, height: 5)
                        .shadow(color: color.opacity(0.67), radius: 3)
                }
            Text("\(Int(value * 100))%")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }
}

#if DEBUG
#Preview("Splurj Home") {
    SplurjHomeView()
}
#endif
