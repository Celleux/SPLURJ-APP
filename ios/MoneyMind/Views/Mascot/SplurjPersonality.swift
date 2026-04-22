import SwiftUI

// MARK: - Splurj personality (5 DNA archetypes)
//
// One of five colors that tints the mascot's inner glow, cheek blush, and
// crown facets. SILHOUETTE NEVER CHANGES — personality is strictly a
// color overlay on top of the variant's Slime body.
//
// Sourced from components/splurji.jsx `PERSONALITY` map. Stored at the
// model layer as `UserProfile.moneyPersonalityKey` (existing in repo) and
// decoded into this enum at render time.

nonisolated enum SplurjPersonality: String, CaseIterable, Identifiable, Codable, Sendable {
    case builder, empath, hustler, minimalist, generous

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .builder:    "The Builder"
        case .empath:     "The Empath"
        case .hustler:    "The Hustler"
        case .minimalist: "The Minimalist"
        case .generous:   "The Generous"
        }
    }

    /// Accent used for the aura ring and cheek highlight.
    var accent: Color {
        switch self {
        case .builder:    Color(hex: 0xE8B94E)   // honey
        case .empath:     Color(hex: 0x4ECDC4)   // teal
        case .hustler:    Color(hex: 0x6366F1)   // indigo
        case .minimalist: Color(hex: 0xE5E5E7)   // silver
        case .generous:   Color(hex: 0xF08389)   // coral
        }
    }

    /// Slightly deeper shade used for strokes / inner shadow of the aura.
    var deep: Color {
        switch self {
        case .builder:    Color(hex: 0xB8892E)
        case .empath:     Color(hex: 0x2A8F89)
        case .hustler:    Color(hex: 0x3F3FB5)
        case .minimalist: Color(hex: 0x8E8E93)
        case .generous:   Color(hex: 0xB5545B)
        }
    }

    /// Soft glow the aura fades into.
    var glowFill: Color { accent.opacity(0.45) }
}

// MARK: - Aura overlay
//
// Drop this behind the mascot to produce the "Bloom+" aura ring described
// in components/splurji.jsx. Intensity scales with SlimeStage.aura so
// Seedling shows nothing and Bonsai radiates a bright halo.

struct PersonalityAuraOverlay: View {
    let personality: SplurjPersonality
    let stage: SlimeStage

    var body: some View {
        let intensity = stage.aura
        ZStack {
            if intensity > 0 {
                // Outer halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                personality.accent.opacity(0.0),
                                personality.accent.opacity(0.18 * intensity),
                                personality.accent.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 50 * intensity,
                            endRadius: 90 * intensity
                        )
                    )
                    .frame(width: 220, height: 220)

                // Inner warm glow (bottom)
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                personality.accent.opacity(0.22 * intensity),
                                .clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.75),
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 180, height: 120)
                    .offset(y: 20)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Cheek tint overlay
//
// Replaces the default pink blush circles with the personality accent.
// Only applied when personality is set AND variant is Her (Him and
// Neutral don't have blush by design, so the overlay would be invisible).

struct PersonalityCheekTint: View {
    let personality: SplurjPersonality

    var body: some View {
        ZStack {
            Circle()
                .fill(personality.accent.opacity(0.55))
                .frame(width: 13, height: 7)
                .offset(x: -20, y: 8)
            Circle()
                .fill(personality.accent.opacity(0.55))
                .frame(width: 13, height: 7)
                .offset(x: 20, y: 8)
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
