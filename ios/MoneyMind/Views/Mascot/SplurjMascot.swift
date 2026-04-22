import SwiftUI

// MARK: - Unified mascot entry point
//
// `SplurjMascot` is the one view the rest of the app uses to render the
// Splurj creature. It composes:
//   - the stage art for the given variant (Her/Him/Neutral — Chunk 2
//     ships Her only; Chunks 3 wires Him + Neutral)
//   - breathing + idle sway
//   - optional blink + tap squash + mood-dependent treatments
//   - optional personality tint overlay (aura + cheek glow)
//
// Each piece respects accessibilityReduceMotion internally. Callers only
// provide the logical state (stage, mood, variant) — no timing knobs.

struct SplurjMascot: View {
    var variant: SplurjVariant = .her
    var stage: SlimeStage = .leafy
    var mood: SlimeMood = .happy
    var personality: SplurjPersonality? = nil
    var size: CGFloat = 160
    var onTap: (() -> Void)? = nil

    @State private var tapped = false

    var body: some View {
        ZStack {
            // Personality aura sits BEHIND the mascot so body reads clean.
            if let personality {
                PersonalityAuraOverlay(personality: personality, stage: stage)
            }

            mascotArt
                .splurjBreathing(period: mood.breathPeriod)
                .splurjIdleSway()
                .splurjTapSquash(trigger: $tapped)
                .saturation(mood.saturation)
                .overlay(sleepingDecoration)
                .overlay(SparkleBurstOverlay(fire: $tapped))

            // Blush tint only applies to Her (the only variant with a
            // default pink blush to override).
            if let personality, variant == .her {
                PersonalityCheekTint(personality: personality)
            }
        }
        .frame(width: 160, height: 160)
        .scaleEffect(size / 160)
        .frame(width: size, height: size)
        .onTapGesture {
            onTap?()
            tapped = true
        }
        .drawingGroup()
        .accessibilityElement()
        .accessibilityLabel(Self.a11yLabel(variant: variant, stage: stage, mood: mood, personality: personality))
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var mascotArt: some View {
        switch variant {
        case .her:     SlimeHerStage(stage)
        case .him:     SlimeHimStage(stage)
        case .neutral: SlimeNeutralStage(stage)
        }
    }

    @ViewBuilder
    private var sleepingDecoration: some View {
        if mood == .sleeping {
            SleepingZs()
        }
    }

    private static func a11yLabel(variant: SplurjVariant, stage: SlimeStage, mood: SlimeMood, personality: SplurjPersonality?) -> String {
        var parts = ["Splurj", variant.label, stage.name]
        if let personality { parts.append(personality.displayName) }
        parts.append("feeling \(String(describing: mood))")
        return parts.joined(separator: ", ")
    }
}

// MARK: - Stage transition wrapper
//
// Drops in where a mascot is rendered and tracks stage changes. When the
// stage advances, plays the EvolutionCeremony for 900ms before revealing
// the new stable mascot.

struct SplurjMascotWithEvolution: View {
    @Binding var stage: SlimeStage
    var variant: SplurjVariant = .her
    var mood: SlimeMood = .happy
    var personality: SplurjPersonality? = nil
    var size: CGFloat = 160

    @State private var previousStage: SlimeStage?

    var body: some View {
        ZStack {
            if let previousStage {
                EvolutionCeremony(
                    oldStage: previousStage,
                    newStage: stage,
                    variant: variant
                ) {
                    self.previousStage = nil
                }
                .frame(width: 160, height: 160)
                .scaleEffect(size / 160)
                .frame(width: size, height: size)
            } else {
                SplurjMascot(
                    variant: variant,
                    stage: stage,
                    mood: mood,
                    personality: personality,
                    size: size
                )
            }
        }
        .onChange(of: stage) { oldValue, _ in
            previousStage = oldValue
        }
    }
}
