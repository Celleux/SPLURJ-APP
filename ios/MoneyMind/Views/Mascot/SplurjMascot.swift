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
    var size: CGFloat = 160
    var onTap: (() -> Void)? = nil

    @State private var tapped = false
    @State private var blinkAmount: Double = 0

    var body: some View {
        ZStack {
            mascotArt
                .splurjBreathing(period: mood.breathPeriod)
                .splurjIdleSway()
                .splurjTapSquash(trigger: $tapped)
                .saturation(mood.saturation)
                .overlay(sleepingDecoration)
                .overlay(SparkleBurstOverlay(fire: $tapped))

            BlinkTimer { blinkAmount = $0 }
        }
        .frame(width: size, height: size)
        // Scale the 160×160 canvas to the requested size.
        .scaleEffect(size / 160)
        .frame(width: size, height: size)
        .onTapGesture {
            onTap?()
            tapped = true
        }
        .drawingGroup()
        .accessibilityElement()
        .accessibilityLabel("Splurj, stage \(stage.name), mood \(String(describing: mood))")
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var mascotArt: some View {
        switch variant {
        case .her:
            SlimeHerStage(stage: stage)
        case .him, .neutral:
            // Chunk 3 fills these in. For now fall back to Her silhouette
            // so screens don't crash during iterative build-out.
            SlimeHerStage(stage: stage)
        }
    }

    @ViewBuilder
    private var sleepingDecoration: some View {
        if mood == .sleeping {
            SleepingZs()
        }
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
                .frame(width: size, height: size)
                .scaleEffect(size / 160)
                .frame(width: size, height: size)
            } else {
                SplurjMascot(variant: variant, stage: stage, mood: mood, size: size)
            }
        }
        .onChange(of: stage) { oldValue, _ in
            previousStage = oldValue
        }
    }
}
