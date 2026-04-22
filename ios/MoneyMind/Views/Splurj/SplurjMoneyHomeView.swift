import SwiftUI

// MARK: - Splurj Money Home — v2
//
// The actual Home tab per Claude Design: contextual greeting, mascot
// hero, saved-this-month card, state-of-mind card, quest card. The
// terrarium (Today/Collection + command bar) lives on the Hub tab.
//
// All surface data is passed in — the host queries SwiftData and
// HealthKit and threads through real values.

struct SplurjMoneyHomeView: View {
    var variant: SplurjVariant = .her
    var personality: SplurjPersonality? = .builder
    var stage: SlimeStage = .leafy
    var level: Int = 7
    var xpProgress: Double = 0.68
    var equippedCosmetics: Set<CosmeticID> = []

    var name: String = "friend"
    var savedThisMonth: Double = 0
    var monthDeltaPercent: Int = 0
    var streak: Int = 0
    var currencySymbol: String = "$"

    var hrvText: String = "--"
    var hrvState: HRVState = .steady

    var questTitle: String = ""
    var questSubtitle: String = ""
    var questXP: Int = 0

    var onOpenProfile: () -> Void = {}
    var onOpenQuest: () -> Void = {}

    enum HRVState: String, Sendable {
        case steady, alert, low

        var statusLabel: String {
            switch self {
            case .steady: "Calm \u{00B7} HRV steady"
            case .alert:  "Alert \u{00B7} HRV climbing"
            case .low:    "Low HRV \u{00B7} rest up"
            }
        }

        var chipLabel: String {
            switch self {
            case .steady: "SAFE TO SPEND"
            case .alert:  "PAUSE FIRST"
            case .low:    "REST UP"
            }
        }

        var chipColor: Color {
            switch self {
            case .steady: Theme.glow
            case .alert:  Theme.honey
            case .low:    Theme.danger
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    headerRow
                    mascotHero
                    savedCard
                    stateOfMindCard
                    if !questTitle.isEmpty {
                        questCard
                    }
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(dateTimeLine, color: Theme.textMuted, tracking: 2.0)
                greetingText
            }
            Spacer()
            avatarButton
        }
    }

    private var greetingText: some View {
        (
            Text(hourGreeting)
            + Text(", ")
            + Text(name).foregroundStyle(Theme.textPrimary)
            + Text(". ")
            + Text(mascotStateLine).foregroundStyle(Theme.textSecondary)
        )
        .font(.system(size: 24, weight: .heavy, design: .rounded))
        .foregroundStyle(Theme.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var avatarButton: some View {
        Button(action: onOpenProfile) {
            SplurjTopBarAvatar(
                variant: variant,
                level: level,
                xpProgress: xpProgress,
                stateDotColor: hrvState == .steady ? Theme.glow : Theme.honey
            ) {
                SplurjMascotPlaceholder(variant: variant)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile")
    }

    // MARK: - Mascot hero

    private var mascotHero: some View {
        HStack {
            Spacer()
            SplurjMascot(
                variant: variant,
                stage: stage,
                personality: personality,
                cosmetics: equippedCosmetics,
                size: 220
            )
            Spacer()
        }
        .frame(height: 240)
        .background(
            RadialGradient(
                colors: [Theme.glow.opacity(0.22), .clear],
                center: UnitPoint(x: 0.5, y: 0.78),
                startRadius: 0, endRadius: 220
            )
        )
    }

    // MARK: - Saved this month

    private var savedCard: some View {
        VStack(spacing: 8) {
            Kicker("Saved this month", color: Theme.textMuted, tracking: 2.0)
            Text(formattedSaved)
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(Theme.glow)
                .shadow(color: Theme.glow.opacity(0.35), radius: 16)
                .monospacedDigit()
            deltaChip
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var formattedSaved: String {
        "\(currencySymbol)\(Int(savedThisMonth.rounded()))"
    }

    private var deltaChip: some View {
        let deltaSign = monthDeltaPercent >= 0 ? "\u{2191}" : "\u{2193}"
        let deltaText = "\(deltaSign) \(abs(monthDeltaPercent))% vs last month \u{00B7} \(streak) days streak"
        return Text(deltaText)
            .font(.system(size: 11, weight: .heavy, design: .monospaced))
            .tracking(0.6)
            .foregroundStyle(monthDeltaPercent >= 0 ? Theme.glow : Theme.honey)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (monthDeltaPercent >= 0 ? Theme.glow : Theme.honey).opacity(0.14),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    (monthDeltaPercent >= 0 ? Theme.glow : Theme.honey).opacity(0.4),
                    lineWidth: 1
                )
            )
    }

    // MARK: - State of mind

    private var stateOfMindCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.glow)
                .frame(width: 34, height: 34)
                .background(Theme.glow.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Kicker("State of mind", color: Theme.textMuted, tracking: 1.6)
                    Spacer()
                    Text(hrvState.chipLabel)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(1.0)
                        .foregroundStyle(hrvState.chipColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(hrvState.chipColor.opacity(0.15), in: Capsule())
                        .overlay(Capsule().strokeBorder(hrvState.chipColor.opacity(0.4), lineWidth: 1))
                }
                Text(hrvState.statusLabel)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                HStack(alignment: .bottom) {
                    MiniSparkline(values: [0.32, 0.41, 0.38, 0.52, 0.61, 0.58, 0.69, 0.72, 0.68])
                        .stroke(
                            hrvState.chipColor,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )
                        .frame(height: 28)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(hrvText)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .monospacedDigit()
                        Text("24H RMSSD")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Quest

    private var questCard: some View {
        Button(action: onOpenQuest) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.honey.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.honey)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("QUEST")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(Theme.honey)
                        Text("\u{00B7}")
                            .foregroundStyle(Theme.textMuted)
                        Text("+\(questXP) XP")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .tracking(1.0)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text(questTitle)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    if !questSubtitle.isEmpty {
                        Text(questSubtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Theme.honey.opacity(0.10), Theme.cardTint],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.honey.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time-of-day helpers

    private var dateTimeLine: String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        let day = df.string(from: Date()).uppercased()
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        let time = tf.string(from: Date())
        return "\(day) \u{00B7} \(time)"
    }

    private var hourGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default:      return "Late night"
        }
    }

    private var mascotStateLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10:  return "Splurji\u{2019}s stretching."
        case 10..<17: return "Splurji\u{2019}s watching."
        case 17..<22: return "Splurji\u{2019}s curled up."
        default:      return "Splurji\u{2019}s dreaming."
        }
    }
}

// MARK: - Mini sparkline
//
// Lightweight Shape for the HRV line. No Charts import — keeps the view
// cheap and flicker-free on scroll.

struct MiniSparkline: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        let stepX = rect.width / CGFloat(values.count - 1)
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = max(0.0001, maxV - minV)
        for (i, v) in values.enumerated() {
            let x = rect.minX + CGFloat(i) * stepX
            let normalized = (v - minV) / range
            let y = rect.maxY - CGFloat(normalized) * rect.height
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else      { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }
}

#if DEBUG
#Preview("Splurj Money Home") {
    SplurjMoneyHomeView(
        name: "Maya",
        savedThisMonth: 427,
        monthDeltaPercent: 18,
        streak: 23,
        hrvText: "68ms",
        hrvState: .steady,
        questTitle: "Skip the 10pm scroll-shop",
        questSubtitle: "Your top splurge window. Hold the line.",
        questXP: 20
    )
}
#endif
