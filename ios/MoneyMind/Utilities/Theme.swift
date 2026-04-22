import SwiftUI

typealias Typography = Theme.Typography

nonisolated enum Theme {

    // MARK: - Night Terrarium (Splurj mascot-first palette)
    //
    // Green-dominant deep moss backgrounds, amber honey for CTAs, green glow for
    // primary actions (active tab, progress, "on track"), petal/sky for gendered
    // variant accents. Matches the prototype in explorations/v2-shell.jsx.

    static let background = Color(hex: 0x0B1614)    // deep moss — app background
    static let bgDeep = Color(hex: 0x050C0B)        // status bar / below-content
    static let surface = Color(hex: 0x1E1E22)
    static let elevated = Color(hex: 0x262630)
    static let modal = Color(hex: 0x303040)

    // MARK: - Primary green (glow) — active tabs, progress, "on track"

    static let glow = Color(hex: 0x7EC552)
    static let glowDeep = Color(hex: 0x4A8F3A)
    static let glowSoft = Color(hex: 0x7EC552, opacity: 0.18)

    // MARK: - CTA gold (honey) — primary buttons, level badges, hero kickers
    //
    // Kept in both .accent (legacy alias) and .honey (new name) to avoid churn.

    static let accent = Color(hex: 0xE8B94E)
    static let accentDim = Color(hex: 0xB8871E)
    static let accentGlow = Color(hex: 0xE8B94E, opacity: 0.15)
    static let accentBright = Color(hex: 0xFFE899)
    static let honey = accent

    // MARK: - Variant accents (mascot gender tints)

    static let petal = Color(hex: 0xFFBCD9)         // Her
    static let sky = Color(hex: 0x8DB8E8)           // Him

    // MARK: - Button Contrast Colors

    static let buttonTextOnAccent = Color(hex: 0x1A1208)
    static let iconOnAccent = Color(hex: 0x1A1208)

    // MARK: - Secondary Accent (TEAL — health, growth, breathing exercises)

    static let accentSecondary = Color(hex: 0x4ECDC4)
    static let accentSecondaryDim = Color(hex: 0x3BADA5)

    // MARK: - Tertiary Accent (INDIGO — AI coach, premium features)

    static let accentTertiary = Color(hex: 0x6366F1)

    // MARK: - Gold (badges, streaks, premium) — alias of honey

    static let gold = accent
    static let goldDim = Color(hex: 0xE8B94E, opacity: 0.12)

    // MARK: - Semantic (desaturated, NOT gambling-associated)

    static let success = glow
    static let warning = Color(hex: 0xF0A030)
    static let danger = Color(hex: 0xE87C5A)        // Night Terrarium alert orange-red
    static let calm = sky

    // MARK: - Text (off-white with green cast — matches v2 `fg`)

    static let textPrimary = Color(hex: 0xE6F3E0)   // Night Terrarium off-white
    static let textSecondary = Color(hex: 0xE6F3E0, opacity: 0.55)
    static let textMuted = Color(hex: 0xE6F3E0, opacity: 0.32)
    static let textDisabled = Color(hex: 0xE6F3E0, opacity: 0.18)

    // MARK: - Elevation System

    static let elevation0 = Color(hex: 0x0F0F12)
    static let elevation1 = Color(hex: 0x1A1A1F)
    static let elevation2 = Color(hex: 0x242428)
    static let elevation3 = Color(hex: 0x2C2C33)

    // MARK: - Borders & Dividers

    static let border = Color(hex: 0xE6F3E0, opacity: 0.10)         // hairline on terrarium
    static let borderHi = Color(hex: 0xE6F3E0, opacity: 0.18)       // emphasized hairline
    static let borderAccent = Color(hex: 0xE8B94E, opacity: 0.2)
    static let divider = Color(hex: 0xE6F3E0, opacity: 0.06)

    // MARK: - Card tints (alpha overlays over terrarium bg)

    static let cardTint = Color.white.opacity(0.04)
    static let cardTintHi = Color.white.opacity(0.07)

    // MARK: - Feature Colors (DNA axes, quest chains, emotional triggers)

    static let axisEmotional = Color(hex: 0x60A5FA)
    static let axisRisk = Color(hex: 0xFB923C)
    static let axisSocial = Color(hex: 0xF472B6)
    static let bossRed = Color(hex: 0xF87171)
    static let lavender = Color(hex: 0xA78BFA)
    static let celebrationYellow = Color(hex: 0xF5C542)
    static let amber = Color(hex: 0xD97706)
    static let dangerLight = Color(hex: 0xEF4444)
    static let amberBright = Color(hex: 0xFBBF24)
    static let ghostRed = Color(hex: 0xFF5252)

    // MARK: - Games Neon Accents

    static let neonGold = Color(hex: 0xE8B94E)
    static let neonBlue = Color(hex: 0x00B4FF)
    static let neonPurple = Color(hex: 0x6366F1)
    static let neonRed = Color(hex: 0xFF4466)
    static let neonPink = Color(hex: 0xFF6EB4)
    static let neonEmerald = Color(hex: 0xE8B94E)

    static let legendaryGradient = AngularGradient(
        colors: [Color(hex: 0xE8B94E), Color(hex: 0xC49A3A), Color(hex: 0xE8B94E), Color(hex: 0xF0D078), Color(hex: 0xE8B94E)],
        center: .center
    )

    static func glowColor(_ color: Color, radius: CGFloat = 8) -> some View {
        color.opacity(0.4).blur(radius: radius)
    }

    // MARK: - Glass Material

    static let glass = Color(hex: 0xE5E5E7, opacity: 0.05)
    static let glassBorder = Color(hex: 0xE5E5E7, opacity: 0.08)
    static let glassHighlight = Color(hex: 0xE5E5E7, opacity: 0.12)

    // MARK: - Legacy Aliases (backward-compatible)

    static let card = elevated
    static let cardSurface = elevated
    static let secondary = accent
    static let accentGreen = accent
    static let teal = accentSecondary
    static let emergency = danger
    static let tabBarBg = background
    static let unselectedTab = textMuted

    // MARK: - Gradients

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xE8B94E), Color(hex: 0xB8871E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Primary CTA gradient (3-stop honey — per prototype `PrimaryButton`)

    static let primaryCtaGradient = LinearGradient(
        colors: [Color(hex: 0xFFE899), Color(hex: 0xE8B94E), Color(hex: 0xB8871E)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - SOS gradient (Night Terrarium danger)

    static let sosGradient = LinearGradient(
        colors: [Color(hex: 0x9EE26E), Color(hex: 0x4A8F3A)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let premiumGradient = LinearGradient(
        colors: [Color(hex: 0xE8B94E), Color(hex: 0xB8871E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xE8B94E), Color(hex: 0xB8871E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x262630), Color(hex: 0x141416)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let tealGradient = LinearGradient(
        colors: [Color(hex: 0x4ECDC4), Color(hex: 0x3BADA5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let indigoGradient = LinearGradient(
        colors: [Color(hex: 0x6366F1), Color(hex: 0x4F46E5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(hex: 0x4ECDC4), Color(hex: 0x3BADA5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let meshBackground = MeshGradient(
        width: 3, height: 3,
        points: [
            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
            [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
        ],
        colors: [
            .black, Color(hex: 0x141416), .black,
            Color(hex: 0xD4A843).opacity(0.04), Color(hex: 0x141416), Color(hex: 0xD4A843).opacity(0.02),
            .black, Color(hex: 0xE8B94E).opacity(0.03), .black
        ]
    )

    // MARK: - Typography

    enum Typography {
        static let displayLarge: Font = .system(size: 34, weight: .bold, design: .rounded)
        static let displayMedium: Font = .system(size: 28, weight: .bold, design: .rounded)
        static let displaySmall: Font = .system(size: 22, weight: .bold, design: .rounded)

        static let headingLarge: Font = .system(size: 20, weight: .semibold, design: .rounded)
        static let headingMedium: Font = .system(size: 17, weight: .semibold, design: .rounded)
        static let headingSmall: Font = .system(size: 15, weight: .semibold, design: .rounded)

        static let bodyLarge: Font = .system(size: 17, design: .default)
        static let bodyMedium: Font = .system(size: 15, design: .default)
        static let bodySmall: Font = .system(size: 13, design: .default)

        static let labelLarge: Font = .system(size: 15, weight: .semibold)
        static let labelMedium: Font = .system(size: 13, weight: .semibold)
        static let labelSmall: Font = .system(size: 11, weight: .semibold)

        static let moneyHero: Font = .system(size: 48, weight: .bold, design: .monospaced)
        static let moneyLarge: Font = .system(size: 34, weight: .bold, design: .monospaced)
        static let moneyMedium: Font = .system(size: 20, weight: .bold, design: .monospaced)
        static let moneySmall: Font = .system(size: 15, weight: .bold, design: .monospaced)
    }

    static func headingFont(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static let numericSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    static let amountXL: Font = Typography.moneyHero
    static let amountLG: Font = Typography.moneyLarge

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 4
        static let xxs: CGFloat = 8
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let xxxl: CGFloat = 48
        static let xxxxl: CGFloat = 64
    }

    // MARK: - Corner Radii

    enum Radius {
        static let pill: CGFloat = 8
        static let button: CGFloat = 12
        static let card: CGFloat = 16
        static let modal: CGFloat = 20
    }

    // MARK: - Animation

    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springDefault = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.75)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.5)
    static let springStagger = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let staggerDelay: Double = 0.08
    static let fadeIn = Animation.easeOut(duration: 0.2)
    static let colorTransition = Animation.easeOut(duration: 0.2)

    static func stagger(_ index: Int) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08)
    }

    static func staggerDelay(_ index: Int) -> Animation {
        springStagger.delay(Double(index) * 0.08)
    }
}

// MARK: - Color Hex Init

extension Color {
    nonisolated init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - 5-Tier Card System

enum CardStyle {
    case hero
    case elevated
    case outlined
    case subtle
    case interactive
}

struct SplurjCard: ViewModifier {
    let style: CardStyle
    let accent: Color

    init(style: CardStyle, accent: Color = Theme.accent) {
        self.style = style
        self.accent = accent
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .hero: 20
        case .elevated, .interactive: 16
        case .outlined: 14
        case .subtle: 12
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .hero:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Theme.elevated, Theme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        case .elevated, .interactive:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.elevated)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.04), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        case .outlined:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.clear)
        case .subtle:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.surface.opacity(0.5))
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .hero:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), accent.opacity(0.3), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .elevated, .interactive:
            EmptyView()
        case .outlined:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Theme.border, lineWidth: 1)
        case .subtle:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch style {
        case .hero: accent.opacity(0.08)
        case .elevated, .interactive: Color.black.opacity(0.2)
        case .outlined, .subtle: Color.clear
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero: 20
        case .elevated, .interactive: 8
        case .outlined, .subtle: 0
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .hero: 8
        case .elevated, .interactive: 4
        case .outlined, .subtle: 0
        }
    }

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderView)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
            .modifier(HeroExtraShadow(isHero: style == .hero))
            .shadow(color: .black.opacity(style == .hero ? 0.25 : 0), radius: 12, y: 4)
    }
}

private struct HeroExtraShadow: ViewModifier {
    let isHero: Bool
    func body(content: Content) -> some View {
        if isHero {
            content.shadow(color: .black.opacity(0.3), radius: 16, y: 6)
        } else {
            content
        }
    }
}

extension View {
    func splurjCard(_ style: CardStyle = .elevated, accent: Color = Theme.accent) -> some View {
        modifier(SplurjCard(style: style, accent: accent))
    }

    @available(*, deprecated, renamed: "splurjCard")
    func glassCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        modifier(SplurjCard(style: .elevated))
    }

    @available(*, deprecated, renamed: "splurjCard")
    func glassCard(cornerRadius: CGFloat = Theme.Radius.card, accentGlow: Color?) -> some View {
        modifier(SplurjCard(style: accentGlow != nil ? .hero : .elevated, accent: accentGlow ?? Theme.accent))
    }
}

// MARK: - Neon Glow Modifier

struct NeonGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let pulses: Bool
    @State private var pulseRadius: CGFloat = 10
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let effectiveRadius = pulses && !reduceMotion ? pulseRadius : radius
        content
            .shadow(color: color.opacity(0.4), radius: effectiveRadius)
            .shadow(color: color.opacity(0.2), radius: effectiveRadius * 1.5)
            .onAppear {
                guard pulses, !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseRadius = 30
                }
            }
    }
}

struct HolographicSheenModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content.overlay {
                TimelineView(.animation(minimumInterval: 1.0 / 10.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let angle = Angle.degrees((t / 3.0).truncatingRemainder(dividingBy: 1.0) * 360)
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(
                            AngularGradient(
                                colors: [
                                    Theme.neonGold.opacity(0.1),
                                    Theme.accentTertiary.opacity(0.1),
                                    Theme.neonPurple.opacity(0.1),
                                    Theme.neonBlue.opacity(0.1),
                                    Theme.neonGold.opacity(0.1)
                                ],
                                center: .center,
                                startAngle: angle,
                                endAngle: angle + .degrees(360)
                            )
                        )
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
            }
            .drawingGroup()
        } else {
            content
        }
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 20, pulses: Bool = false) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius, pulses: pulses))
    }

    func holographicSheen(isActive: Bool = true) -> some View {
        modifier(HolographicSheenModifier(isActive: isActive))
    }

    func depthPop(intensity: CGFloat = 1.0) -> some View {
        self
            .shadow(color: .black.opacity(0.3 * intensity), radius: 8 * intensity, y: 4 * intensity)
            .shadow(color: .black.opacity(0.15 * intensity), radius: 2 * intensity, y: 1 * intensity)
    }
}

// MARK: - 5-Tier Button System

enum ButtonVariant {
    case primary
    case secondary
    case tertiary
    case ghost
    case destructive
}

enum ButtonSize {
    case large
    case medium
    case small

    var height: CGFloat {
        switch self {
        case .large: 56
        case .medium: 48
        case .small: 36
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .large: 16
        case .medium: 14
        case .small: 10
        }
    }

    var hPadding: CGFloat {
        switch self {
        case .large: 24
        case .medium: 20
        case .small: 14
        }
    }

    var font: Font {
        switch self {
        case .large: Typography.labelLarge
        case .medium, .small: Typography.labelMedium
        }
    }
}

struct SplurjButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    let size: ButtonSize

    init(variant: ButtonVariant = .primary, size: ButtonSize = .large) {
        self.variant = variant
        self.size = size
    }

    private func textColor(pressed: Bool) -> Color {
        switch variant {
        case .primary: Theme.buttonTextOnAccent
        case .destructive: .white
        case .secondary: Theme.accentBright
        case .tertiary: Theme.accentBright
        case .ghost: Theme.textPrimary
        }
    }

    @ViewBuilder
    private func bgView(pressed: Bool) -> some View {
        switch variant {
        case .primary:
            LinearGradient(
                colors: pressed ? [Theme.accentDim, Theme.accentDim] : [Theme.accent, Theme.accentDim],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color(hex: 0x1A1A1F)
        case .tertiary:
            pressed ? Theme.accent.opacity(0.08) : Color.clear
        case .ghost:
            pressed ? Color.white.opacity(0.05) : Color.clear
        case .destructive:
            LinearGradient(
                colors: pressed ? [Theme.danger.opacity(0.85), Theme.danger.opacity(0.7)] : [Theme.danger, Theme.danger.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private func borderView(pressed: Bool) -> some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder((pressed ? Theme.accentDim : Theme.accentBright).opacity(0.3), lineWidth: 1.5)
        case .tertiary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(Theme.accentBright.opacity(0.3), lineWidth: 1)
        default:
            EmptyView()
        }
    }

    private func shadowColor(pressed: Bool) -> Color {
        guard !pressed else { return .clear }
        switch variant {
        case .primary: return Theme.accent.opacity(0.25)
        case .destructive: return Theme.danger.opacity(0.2)
        default: return Color.clear
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(size.font)
            .foregroundStyle(textColor(pressed: pressed))
            .frame(height: size.height)
            .padding(.horizontal, size.hPadding)
            .background(bgView(pressed: pressed))
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(borderView(pressed: pressed))
            .overlay(alignment: .top) {
                if variant == .primary || variant == .destructive {
                    LinearGradient(
                        colors: [Color.white.opacity(pressed ? 0.08 : 0.15), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                    .allowsHitTesting(false)
                }
            }
            .shadow(color: shadowColor(pressed: pressed), radius: pressed ? 2 : 6, y: pressed ? 1 : 3)
            .shadow(color: variant == .primary ? Theme.accent.opacity(pressed ? 0.1 : 0.4) : .clear, radius: pressed ? 4 : 12, y: pressed ? 2 : 6)
            .scaleEffect(pressed ? 0.97 : 1.0)
            .brightness(pressed ? -0.03 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
            .onChange(of: pressed) { _, isPressed in
                if isPressed {
                    HapticManager.buttonTap()
                }
            }
    }
}

// MARK: - Elevation Card System

enum ElevationLevel: Int {
    case level1 = 1
    case level2 = 2
    case level3 = 3
}

struct MMElevatedCard: ViewModifier {
    let level: ElevationLevel
    let cornerRadius: CGFloat

    init(level: ElevationLevel = .level1, cornerRadius: CGFloat = 16) {
        self.level = level
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        switch level {
        case .level1:
            content
                .background(Theme.elevation1, in: RoundedRectangle(cornerRadius: cornerRadius))
        case .level2:
            content
                .background(Theme.elevation2, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
        case .level3:
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .background(Theme.elevation3, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 16, y: 8)
        }
    }
}

extension View {
    func mmElevated(_ level: ElevationLevel = .level1, cornerRadius: CGFloat = 16) -> some View {
        modifier(MMElevatedCard(level: level, cornerRadius: cornerRadius))
    }
}

// MARK: - Card Press Animation

struct CardPressModifier: ViewModifier {
    @State private var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Parallax Tilt for Collectible Cards

struct ParallaxTiltModifier: ViewModifier {
    @State private var dragOffset: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(Double(dragOffset.width) / 8),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-dragOffset.height) / 8),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}

// MARK: - Gold Glow for Premium Cards

struct PremiumGoldGlow: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content
                .shadow(color: Theme.accent.opacity(0.15), radius: 20)
        } else {
            content
        }
    }
}

extension View {
    func cardPress() -> some View {
        modifier(CardPressModifier())
    }

    func parallaxTilt() -> some View {
        modifier(ParallaxTiltModifier())
    }

    func premiumGlow(_ isActive: Bool = true) -> some View {
        modifier(PremiumGoldGlow(isActive: isActive))
    }
}
