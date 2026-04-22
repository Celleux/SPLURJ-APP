import SwiftUI

// MARK: - Unified mascot entry point
//
// `SplurjMascot` is the one view the rest of the app uses to render the
// Splurj creature. It composes:
//   - the stage art for the given variant (Her/Him/Neutral)
//   - breathing + idle sway + tap-squash
//   - optional personality tint overlay (aura + cheek glow)
//   - optional equipped cosmetics, layered by slot
//
// Each piece respects accessibilityReduceMotion internally. Callers only
// provide the logical state (stage, mood, variant, cosmetics) — no
// timing knobs.

struct SplurjMascot: View {
    var variant: SplurjVariant = .her
    var stage: SlimeStage = .leafy
    var mood: SlimeMood = .happy
    var personality: SplurjPersonality? = nil
    var cosmetics: Set<CosmeticID> = []
    var size: CGFloat = 160
    var onTap: (() -> Void)? = nil

    @State private var tapped = false

    var body: some View {
        ZStack {
            // Background cosmetics (moon, stars, stones, stump, mushroom)
            cosmeticsAt(.bg)

            // Personality aura sits BEHIND the mascot so body reads clean.
            if let personality {
                PersonalityAuraOverlay(personality: personality, stage: stage)
            }

            // Base cosmetics (lotus at feet)
            cosmeticsAt(.base)

            // Mascot body + breath-locked overlays
            ZStack {
                mascotArt
                    .overlay(sleepingDecoration)
                    .overlay(SparkleBurstOverlay(fire: $tapped))

                // Body / neck / face / head cosmetics ride the breath with the mascot
                cosmeticsAt(.body)
                cosmeticsAt(.neck)
                cosmeticsAt(.face)
                cosmeticsAt(.head)
            }
            .splurjBreathing(period: mood.breathPeriod)
            .splurjIdleSway()
            .splurjTapSquash(trigger: $tapped)
            .saturation(mood.saturation)

            // Cheek tint only applies to Her (she's the only variant with
            // default pink blush to override).
            if let personality, variant == .her {
                PersonalityCheekTint(personality: personality)
            }

            // Orbit cosmetics loop around outside the mascot
            cosmeticsAt(.orbit)
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

    @ViewBuilder
    private func cosmeticsAt(_ slot: CosmeticSlot) -> some View {
        let ids = cosmetics
            .filter { $0.slot == slot }
            .sorted { $0.rawValue < $1.rawValue }
        switch slot {
        case .bg:
            if let primary = ids.first {
                SplurjCosmeticView(id: primary, size: 136)
                    .offset(y: -12)
                    .opacity(0.82)
            }
        case .base:
            ForEach(ids, id: \.self) { id in
                SplurjCosmeticView(id: id, size: 108)
                    .offset(y: 48)
            }
        case .body:
            ForEach(ids, id: \.self) { id in
                SplurjCosmeticView(id: id, size: 56)
                    .offset(y: 12)
            }
        case .neck:
            ForEach(ids, id: \.self) { id in
                SplurjCosmeticView(id: id, size: 56)
                    .offset(y: -2)
            }
        case .face:
            ForEach(ids, id: \.self) { id in
                SplurjCosmeticView(id: id, size: 50)
                    .offset(y: -6)
            }
        case .head:
            ForEach(ids, id: \.self) { id in
                SplurjCosmeticView(id: id, size: 44)
                    .offset(y: -52)
            }
        case .orbit:
            OrbitCosmetics(ids: ids)
        }
    }

    private static func a11yLabel(variant: SplurjVariant, stage: SlimeStage, mood: SlimeMood, personality: SplurjPersonality?) -> String {
        var parts = ["Splurj", variant.label, stage.name]
        if let personality { parts.append(personality.displayName) }
        parts.append("feeling \(String(describing: mood))")
        return parts.joined(separator: ", ")
    }
}

// MARK: - Orbit cosmetics
//
// Rotates each equipped orbit-slot cosmetic around the mascot on a
// slow TimelineView. Items are spaced evenly around the circle.

private struct OrbitCosmetics: View {
    let ids: [CosmeticID]
    var radius: CGFloat = 88
    var period: Double = 9
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { _ in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate / period
                let count = ids.count
                ZStack {
                    ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                        let phase = Double(index) / Double(max(1, count))
                        let angle = (t + phase) * 2 * .pi
                        SplurjCosmeticView(id: id, size: 28)
                            .offset(
                                x: CGFloat(cos(angle)) * radius,
                                y: CGFloat(sin(angle)) * radius
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
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
    var cosmetics: Set<CosmeticID> = []
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
                    cosmetics: cosmetics,
                    size: size
                )
            }
        }
        .onChange(of: stage) { oldValue, _ in
            previousStage = oldValue
        }
    }
}
