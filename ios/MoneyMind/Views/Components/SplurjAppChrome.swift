import SwiftUI

// MARK: - Splurj mascot variant (model-layer seam)
//
// Stored at UserProfile.splurj later. Drives pronouns, copy tone,
// mascot accent tint on the avatar, and future reward visuals.
// Per the handoff spec the variant and the CharacterStage are orthogonal.

nonisolated enum SplurjVariant: String, CaseIterable, Identifiable, Codable, Sendable {
    case her, him, neutral

    var id: String { rawValue }

    /// Display label used on the onboarding Choose screen — no pronoun sublabels.
    var label: String {
        switch self {
        case .her: "Her"
        case .him: "Him"
        case .neutral: "Neutral"
        }
    }

    /// The accent color that tints the avatar ring, the Choose-card glow,
    /// and variant chips throughout the UI.
    var accent: Color {
        switch self {
        case .her: Theme.petal
        case .him: Theme.sky
        case .neutral: Theme.glow
        }
    }
}

// MARK: - Top bar
//
// Faithful port of v2-shell.jsx `TopBar`: display title on the left, a
// 46pt avatar with a gold progress ring, mascot cutout, honey level badge
// and a state dot on the right. Caller injects the mascot rendering so
// this component doesn't couple to any one SVG — Chunk 2 will inject the
// real Slime; Chunk 1 tests/previews inject a placeholder circle.

struct SplurjTopBar<Mascot: View>: View {
    let title: String
    var variant: SplurjVariant = .her
    var level: Int
    var xpProgress: Double = 0.68            // 0–1, fills the gold ring
    var stateDotColor: Color = Theme.glow    // green = calm, honey = alert, orange = at risk
    var onAvatarTap: (() -> Void)? = nil
    @ViewBuilder var mascot: () -> Mascot

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .tracking(-0.44)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Spacer()

            if let tap = onAvatarTap {
                Button(action: tap) { avatar }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open profile")
            } else {
                avatar
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var avatar: some View {
        SplurjTopBarAvatar(
            variant: variant,
            level: level,
            xpProgress: xpProgress,
            stateDotColor: stateDotColor,
            mascot: mascot
        )
    }
}

// MARK: - Reusable avatar (mascot ring + level badge + state dot)
//
// Extracted so the money-home header can drop in the same avatar next to
// the multi-line greeting, without needing the full SplurjTopBar chrome.

struct SplurjTopBarAvatar<Mascot: View>: View {
    var variant: SplurjVariant = .her
    var level: Int
    var xpProgress: Double = 0.68
    var stateDotColor: Color = Theme.glow
    @ViewBuilder var mascot: () -> Mascot

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                // Track
                Circle()
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 2)

                // Progress arc — gold, rotated so it starts at 12 o'clock
                Circle()
                    .trim(from: 0, to: max(0.0, min(1.0, xpProgress)))
                    .stroke(Theme.honey, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Mascot cutout
                Circle()
                    .fill(variant.accent.opacity(0.18))
                    .padding(5)
                    .overlay {
                        mascot()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, -4)
                    }
                    .clipShape(Circle().inset(by: 5))
            }
            .frame(width: 46, height: 46)

            // Level badge
            Text("\(level)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0x1A1208))
                .padding(.horizontal, 4)
                .frame(minWidth: 18, minHeight: 18)
                .background(Theme.honey, in: .capsule)
                .overlay(Capsule().strokeBorder(Theme.background, lineWidth: 2))
                .offset(x: 4, y: 14)

            // State dot
            Circle()
                .fill(stateDotColor)
                .frame(width: 11, height: 11)
                .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
                .shadow(color: stateDotColor, radius: 4)
                .offset(x: 2, y: -2)
        }
        .frame(width: 46, height: 46)
    }
}

// MARK: - Bottom nav
//
// Five-tab custom nav matching v2-shell.jsx `BottomNav`. Active tab gets
// a gold 36×3 pill at the top edge + a glow behind the icon; label stays
// bright. Inactive tabs are textMuted @ 32% alpha. Background is a
// gradient that reads as frosted glass on top of the terrarium.
//
// This is a standalone view — it is NOT yet wired into ContentView's
// TabView. Chunk 5 (Home + tabs) will replace the native bottom bar with
// this custom one.

nonisolated enum SplurjTab: String, CaseIterable, Identifiable, Sendable {
    case home, wallet, pacts, coach, hub, profile

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:    "HOME"
        case .wallet:  "WALLET"
        case .pacts:   "PACTS"
        case .coach:   "COACH"
        case .hub:     "HUB"
        case .profile: "ME"
        }
    }

    var navIcon: SplurjNavIcon {
        switch self {
        case .home:    .home
        case .wallet:  .wallet
        case .pacts:   .pacts
        case .coach:   .coach
        case .hub:     .hub
        case .profile: .profile
        }
    }
}

struct SplurjBottomNav: View {
    @Binding var active: SplurjTab
    var onChange: ((SplurjTab) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SplurjTab.allCases) { tab in
                item(tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [
                    Theme.background.opacity(0),
                    Theme.background.opacity(0.92),
                    Theme.background.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
        }
        .background(.ultraThinMaterial)
    }

    private func item(_ tab: SplurjTab) -> some View {
        let isActive = tab == active
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                active = tab
            }
            onChange?(tab)
        } label: {
            VStack(spacing: 3) {
                // Active pill at top
                Capsule()
                    .fill(Theme.glow)
                    .frame(width: isActive ? 36 : 0, height: 3)
                    .shadow(color: isActive ? Theme.glow : .clear, radius: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)

                SplurjNavIconView(
                    icon: tab.navIcon,
                    size: 22,
                    color: isActive ? Theme.textPrimary : Theme.textMuted
                )
                .shadow(color: isActive ? Theme.glow.opacity(0.67) : .clear, radius: 6)
                .frame(height: 22)

                Text(tab.label)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.38)
                    .foregroundStyle(isActive ? Theme.textPrimary : Theme.textMuted)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isActive)
    }
}

// MARK: - Mascot placeholder
//
// Temporary avatar for SplurjTopBar until Chunk 2 lands the real Slime.
// Paint-by-variant circle with a tiny silhouette dot so screens don't
// look empty in the interim.

struct SplurjMascotPlaceholder: View {
    var variant: SplurjVariant = .her

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [variant.accent.opacity(0.9), variant.accent.opacity(0.5)],
                    center: .init(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: 28
                )
            )
            .overlay(
                Circle()
                    .fill(Theme.background.opacity(0.9))
                    .frame(width: 4, height: 4)
                    .offset(x: -4, y: 2),
                alignment: .center
            )
            .overlay(
                Circle()
                    .fill(Theme.background.opacity(0.9))
                    .frame(width: 4, height: 4)
                    .offset(x: 4, y: 2),
                alignment: .center
            )
    }
}
