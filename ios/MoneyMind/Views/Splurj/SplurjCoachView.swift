import SwiftUI

// MARK: - Splurj Coach — v2 (canonical port of explorations/v2-coach.jsx)
//
// Three-group layout:
//   RIGHT NOW      — one-tap intercepts for the next 5 minutes (SOS tools)
//   PLAN AHEAD     — build guardrails while clear-headed (rules, plans)
//   REFLECT & GROW — weekly review, money story, AI post-mortem
//
// Each tool tile fires a closure the host wires to a fullScreenCover of
// the matching production view (UrgeSurfView, HALTCheckView, etc).

struct SplurjCoachView: View {
    var variant: SplurjVariant = .her
    var level: Int = 7
    var equippedCosmetics: Set<CosmeticID> = []
    var isAllClear: Bool = true
    var hrv: String = "68ms"

    var onOpenSOS: () -> Void = {}
    var onUrgeSurf: () -> Void = {}
    var onHALT: () -> Void = {}
    var onCoolDown: () -> Void = {}
    var onIfThen: () -> Void = {}
    var onOneSec: () -> Void = {}
    var onACT: () -> Void = {}
    var onAICoach: () -> Void = {}
    var onDNSBlocking: () -> Void = {}
    var onDraftPact: () -> Void = {}
    var onOpenProfile: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    SplurjTopBar(
                        title: "Coach",
                        variant: variant,
                        level: level,
                        stateDotColor: isAllClear ? Theme.glow : Theme.honey,
                        onAvatarTap: onOpenProfile
                    ) {
                        SplurjMascotPlaceholder(variant: variant)
                    }

                    VStack(alignment: .leading, spacing: 22) {
                        rightNowGroup
                        planAheadGroup
                        reflectGrowGroup
                    }
                    .padding(.horizontal, 22)

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - RIGHT NOW

    private var rightNowGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            groupHeader(
                icon: "exclamationmark.circle.fill",
                label: "Right now",
                caption: "One-tap intercepts for the next 5 minutes",
                color: Theme.danger
            )

            coachTool(
                featured: true,
                kicker: "RECOMMENDED \u{00B7} 60s",
                kickerColor: Theme.danger,
                title: "Pause & Breathe",
                sub: "HRV says stress is climbing. Box-breathe with Splurji before you tap Buy.",
                icon: "lungs.fill",
                action: onUrgeSurf
            )

            coachTool(
                kicker: "HALT \u{00B7} 20s",
                kickerColor: Theme.honey,
                title: "HALT Check",
                sub: "Hungry \u{00B7} Angry \u{00B7} Lonely \u{00B7} Tired? Pick one, get a redirect.",
                icon: "hand.raised.fill",
                action: onHALT
            )

            coachTool(
                kicker: "SOS \u{00B7} EMERGENCY",
                kickerColor: Theme.danger,
                title: "Crisis help",
                sub: "Full intercept screen with grounding + hotline options.",
                icon: "shield.fill",
                action: onOpenSOS
            )
        }
    }

    // MARK: - PLAN AHEAD

    private var planAheadGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            groupHeader(
                icon: "calendar",
                label: "Plan ahead",
                caption: "Build guardrails while you\u{2019}re clear-headed",
                color: Theme.sky
            )

            coachTool(
                kicker: "SET RULE",
                kickerColor: Theme.sky,
                title: "Evening lockdown",
                sub: "Auto-mute shopping apps 10pm\u{2013}8am. Splurji greets you instead.",
                icon: "lock.fill",
                action: onDNSBlocking
            )

            coachTool(
                kicker: "IF-THEN \u{00B7} 2 MIN",
                kickerColor: Theme.sky,
                title: "Pre-set your response",
                sub: "Draft one line: when X happens, I\u{2019}ll do Y instead.",
                icon: "lightbulb.fill",
                action: onIfThen
            )

            coachTool(
                kicker: "COOLING OFF \u{00B7} 48h",
                kickerColor: Theme.sky,
                title: "Hold a purchase",
                sub: "Park it for 48 hours. Splurji will ask how you feel then.",
                icon: "timer",
                action: onCoolDown
            )

            coachTool(
                kicker: "1-SEC RULE",
                kickerColor: Theme.sky,
                title: "Breathe before the tap",
                sub: "A single breath guide \u{2014} inhale, pause, proceed.",
                icon: "wind",
                action: onOneSec
            )

            coachTool(
                kicker: "AI COACH",
                kickerColor: Theme.sky,
                title: "Draft a friend pact",
                sub: "Team up with someone you trust. AI drafts the terms, you both sign.",
                icon: "person.2.fill",
                action: onDraftPact
            )
        }
    }

    // MARK: - REFLECT & GROW

    private var reflectGrowGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            groupHeader(
                icon: "star.fill",
                label: "Reflect & grow",
                caption: "What Splurji\u{2019}s noticing about you",
                color: Theme.glow
            )

            coachTool(
                kicker: "READY \u{00B7} 4 MIN",
                kickerColor: Theme.glow,
                title: "Your week, unpacked",
                sub: "3 wins, 1 pattern, 1 thing to try. Splurji narrates.",
                icon: "doc.text.fill",
                action: onACT
            )

            coachTool(
                kicker: "MONEY STORY",
                kickerColor: Theme.glow,
                title: "Talk to your coach",
                sub: "Chat through what you\u{2019}re feeling. No judgment.",
                icon: "bubble.left.and.bubble.right.fill",
                action: onAICoach
            )
        }
    }

    // MARK: - Components

    private func groupHeader(icon: String, label: String, caption: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border, lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                Text(caption)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private func coachTool(
        featured: Bool = false,
        kicker: String,
        kickerColor: Color,
        title: String,
        sub: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: featured ? 22 : 18, weight: .semibold))
                    .foregroundStyle(kickerColor)
                    .frame(width: featured ? 52 : 40, height: featured ? 52 : 40)
                    .background(kickerColor.opacity(0.12), in: RoundedRectangle(cornerRadius: featured ? 16 : 12))
                    .overlay(RoundedRectangle(cornerRadius: featured ? 16 : 12).strokeBorder(kickerColor.opacity(0.28), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(kicker)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundStyle(kickerColor)
                    Text(title)
                        .font(.system(size: featured ? 15 : 13.5, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(featured ? 16 : 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SOS intercept (full-screen deep-link)
//
// Port of ScreenSOS in states.jsx. Triggered by notification tap or the
// CoachEngine when a spike is detected. Shows the mascot breathing with
// the user, cart preview, and 3 stacked actions.

struct SplurjSOSView: View {
    var variant: SplurjVariant = .her
    var merchantName: String = "ASOS"
    var cartAmount: Int = 89
    var onBreathe: () -> Void = {}
    var onHold: () -> Void = {}
    var onProceedAnyway: () -> Void = {}
    var onDismiss: () -> Void = {}

    @State private var ringPhase: Double = 0

    var body: some View {
        ZStack {
            background
            content
            dismissButton
        }
        .ignoresSafeArea()
    }

    private var background: some View {
        ZStack {
            Color(hex: 0x1A0F0A)
            RadialGradient(
                colors: [Color(hex: 0xE87C5A).opacity(0.25), .clear],
                center: UnitPoint(x: 0.5, y: 0.6),
                startRadius: 0,
                endRadius: 300
            )
            RadialGradient(
                colors: [Theme.glow.opacity(0.25), .clear],
                center: UnitPoint(x: 0.5, y: 0.9),
                startRadius: 0,
                endRadius: 350
            )
            VStack {
                Rectangle()
                    .fill(Theme.danger.opacity(0.7))
                    .frame(height: 3)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Kicker("Spike detected \u{00B7} 11:23 pm", color: Theme.danger, tracking: 1.5)
                (Text("Before you tap Buy at ") + Text(merchantName).foregroundStyle(Theme.honey) + Text("\u{2026}"))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Splurji felt the spike. One minute with her, before the checkout.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 80)

            Spacer(minLength: 16)

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Theme.glow.opacity(0.45 - Double(i) * 0.12), lineWidth: 1.5)
                        .frame(width: 220 + CGFloat(i) * 32, height: 220 + CGFloat(i) * 32)
                }
                SplurjMascot(variant: variant, stage: .leafy, size: 170)
            }
            .padding(.vertical, 10)

            Text("INHALE \u{00B7} 4")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(Theme.glow)

            Spacer(minLength: 16)

            cartRow
                .padding(.horizontal, 22)

            actions
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 30)
        }
    }

    private var cartRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.honey)
                .frame(width: 36, height: 36)
                .background(Theme.honey.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(merchantName) \u{00B7} Cart pending")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text("$\(cartAmount).00 \u{00B7} checkout intercepted")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("$\(cartAmount)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.danger)
        }
        .padding(12)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
    }

    private var actions: some View {
        VStack(spacing: 8) {
            PrimaryCtaButton(title: "Breathe with Splurji \u{00B7} 60s", action: onBreathe)
            Button(action: onHold) {
                Text("Send it to 48h hold")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.cardTintHi, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Button(action: onProceedAnyway) {
                Text("Buy anyway \u{00B7} Splurji won\u{2019}t judge")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                    .underline()
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var dismissButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
            }
            .padding(.top, 52)
            .padding(.trailing, 22)
            Spacer()
        }
    }
}

#if DEBUG
#Preview("Coach · all clear") {
    SplurjCoachView(isAllClear: true)
}
#Preview("Coach · engaged") {
    SplurjCoachView(isAllClear: false, hrv: "42ms")
}
#Preview("SOS intercept") {
    SplurjSOSView()
}
#endif
