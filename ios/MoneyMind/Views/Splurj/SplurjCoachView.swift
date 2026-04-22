import SwiftUI

// MARK: - Splurj Coach — v2
//
// Emergency-first triage screen. Three zones: HRV status cards at the
// top, AI money coach hero, and impulse-control grid. Port of the spirit
// of v2-coach + states.jsx EmptyCoach (the "all clear" variant).

struct SplurjCoachView: View {
    var variant: SplurjVariant = .her
    var level: Int = 7
    var isAllClear: Bool = true
    var hrv: String = "68ms"
    var onOpenSOS: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    SplurjTopBar(title: "Coach", variant: variant, level: level) {
                        SplurjMascotPlaceholder(variant: variant)
                    }
                    Group {
                        if isAllClear {
                            allClearBody
                        } else {
                            aiAndToolsBody
                        }
                    }
                    .padding(.horizontal, 22)
                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - All-clear body

    private var allClearBody: some View {
        VStack(spacing: 22) {
            // Hero mascot + tagline
            VStack(spacing: 14) {
                SplurjMascot(variant: variant, stage: .sprout, size: 160)
                    .padding(.top, 10)
                Kicker("All clear · 0 alerts", color: Theme.glow)
                Text(tagline)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("HRV\u{2019}s steady, no spending windows open, no pacts under pressure. Take the win. Check back this evening.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }

            VStack(spacing: 10) {
                PrimaryCtaButton(title: "Plan tomorrow") { }
                GhostLinkButton(title: "Open the archive") { }
            }

            // Status cards
            HStack(spacing: 8) {
                statusCard(label: "HRV", value: hrv, color: Theme.glow)
                statusCard(label: "BUDGETS", value: "OK", color: Theme.glow)
                statusCard(label: "PACTS", value: "3/3", color: Theme.glow)
            }
        }
    }

    private var tagline: String {
        switch variant {
        case .her:     "Splurj is content."
        case .him:     "Splurj is chill."
        case .neutral: "Splurj\u{2019}s calm."
        }
    }

    private func statusCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Theme.textMuted)
            Text(value)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - AI coach + tools body (engaged state)

    private var aiAndToolsBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            emergencyRow
            aiCoachHero
            impulseGrid
        }
    }

    private var emergencyRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker("Right now", color: Theme.danger)
            HStack(spacing: 10) {
                emergencyTile(title: "SOS", systemImage: "exclamationmark.shield.fill", tint: Theme.danger, action: onOpenSOS)
                emergencyTile(title: "Pause &\nBreathe", systemImage: "wind", tint: Theme.accentSecondary, action: {})
                emergencyTile(title: "HALT\nCheck", systemImage: "hand.raised.fill", tint: Theme.honey, action: {})
            }
        }
    }

    private func emergencyTile(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                Text(title)
                    .font(.system(size: 11.5, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var aiCoachHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker("Reflect & grow", color: Theme.accentSecondary)
            Button { } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.accentDim)
                            .frame(width: 56, height: 56)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.honey)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AI Money Coach")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Talk through what you\u{2019}re feeling")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Theme.cardTintHi, Theme.cardTint],
                        startPoint: .top, endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 22)
                )
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.borderHi, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var impulseGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker("Plan ahead", color: Theme.glow)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                toolTile(icon: "timer", title: "Cool Down", sub: "Wait it out with a countdown timer")
                toolTile(icon: "lightbulb.fill", title: "If-Then Plan", sub: "Pre-set your response to triggers")
                toolTile(icon: "lungs.fill", title: "1-Second Rule", sub: "Pause before tempting apps")
                toolTile(icon: "figure.mind.and.body", title: "Exercises", sub: "CBT & ACT techniques")
            }
        }
    }

    private func toolTile(icon: String, title: String, sub: String) -> some View {
        Button { } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0x1A1208))
                    .frame(width: 40, height: 40)
                    .background(Theme.honey, in: RoundedRectangle(cornerRadius: 10))
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
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
            // Top warning stripe
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
                Kicker("Spike detected · 11:23 pm", color: Theme.danger, tracking: 1.5)
                (Text("Before you tap Buy at ") + Text(merchantName).foregroundStyle(Theme.honey) + Text("\u{2026}"))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(copy)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 90)

            // Breathing rings + mascot
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .strokeBorder(Theme.glow.opacity(0.3 + Double(i) * 0.2), lineWidth: CGFloat(2 - i) * 0.3 + 1)
                        .scaleEffect(0.7 + 0.3 * CGFloat(i))
                }
                SplurjMascot(variant: variant, stage: .leafy, mood: .alert, size: 180)
            }
            .frame(width: 280, height: 280)
            .padding(.top, 28)
            .overlay(alignment: .bottom) {
                Kicker("Inhale · 4", color: Theme.glow, tracking: 2.2)
                    .offset(y: 20)
            }

            Spacer(minLength: 20)

            // Transaction preview
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.cardTintHi)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.textPrimary)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(merchantName) · Cart pending")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("$\(cartAmount).00 · checkout intercepted")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("$\(cartAmount)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.danger)
            }
            .padding(14)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 22)

            // Actions
            VStack(spacing: 8) {
                Button(action: onBreathe) {
                    Text("Breathe with Splurj · 60s")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x0B1614))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.sosGradient, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Theme.glow.opacity(0.27), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                Button(action: onHold) {
                    Text("Send it to 48h hold")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button(action: onProceedAnyway) {
                    Text("Buy anyway · Splurj won\u{2019}t judge")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .underline()
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
        }
    }

    private var copy: String {
        switch variant {
        case .her:     "Splurj felt the spike. One minute with her, before the checkout."
        case .him:     "Splurj saw that coming. Give him 60 seconds."
        case .neutral: "Splurj flagged it. One breath before you commit."
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
                        .background(Color.white.opacity(0.06), in: Circle())
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 58)
                .padding(.trailing, 22)
            }
            Spacer()
        }
    }
}

// MARK: - In-app banner (top-of-screen notification)

struct SplurjInAppBanner: View {
    var variant: SplurjVariant = .her
    var title: String
    var body: String
    var color: Color = Theme.honey

    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.background)
                .frame(width: 40, height: 40)
                .overlay(
                    SplurjMascotPlaceholder(variant: variant)
                        .padding(4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(0.33), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 1) {
                Kicker("Splurj", color: color, tracking: 2.0)
                Text(title)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(body)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [color.opacity(0.12), color.opacity(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(color.opacity(0.33), lineWidth: 1))
        .shadow(color: color.opacity(0.15), radius: 18, y: 6)
    }
}

#if DEBUG
#Preview("Splurj Coach") {
    SplurjCoachView(isAllClear: true)
}

#Preview("Splurj Coach · engaged") {
    SplurjCoachView(isAllClear: false)
}

#Preview("SOS intercept") {
    SplurjSOSView()
}

#Preview("In-app banner") {
    VStack {
        SplurjInAppBanner(
            title: "Splurj flinched.",
            body: "It\u{2019}s 11:23pm — her least favorite hour for your cart.",
            color: Theme.danger
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
}
#endif
