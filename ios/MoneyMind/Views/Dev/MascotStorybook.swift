#if DEBUG
import SwiftUI

// MARK: - Mascot storybook (debug-only)
//
// Renders every permutation of the mascot so designers / Claude Code can
// spot-check fidelity. Reachable via Profile → Settings → "Mascot storybook"
// when the app is compiled in DEBUG.
//
// Chunk 2: shows Her × 6 stages × all moods + evolution preview.
// Chunk 3: extended to Him + Neutral + personality tints (3×6×5 = 90).

struct MascotStorybookView: View {
    @State private var selectedVariant: SplurjVariant = .her
    @State private var evolutionStage: SlimeStage = .seedling

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    Kicker("Stages · Her")
                    stageGrid(variant: .her)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Kicker("Moods · Leafy · Her", color: Theme.petal)
                    moodStrip(variant: .her, stage: .leafy)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Kicker("Evolution preview", color: Theme.glow)
                    evolutionPlayer
                }

                VStack(alignment: .leading, spacing: 12) {
                    Kicker("Variant seam (Chunks 3 fills Him & Neutral)", color: Theme.sky)
                    variantComparisonRow
                }

                Spacer(minLength: 80)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Mascot storybook")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Splurj mascot review")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Every permutation rendered natively in SwiftUI. Compare against Splurji Mascot Review.html side-by-side.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Stage grid

    private func stageGrid(variant: SplurjVariant) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(SlimeStage.allCases) { stage in
                stageCard(variant: variant, stage: stage)
            }
        }
    }

    private func stageCard(variant: SplurjVariant, stage: SlimeStage) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            colors: [Theme.glow.opacity(0.22), .clear],
                            center: .init(x: 0.5, y: 0.8),
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
                SplurjMascot(variant: variant, stage: stage, size: 130)
            }
            .frame(height: 160)

            Text("STAGE \(String(format: "%02d", stage.rawValue))")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(Theme.glow.opacity(0.7))
            Text(stage.name)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Mood strip

    private func moodStrip(variant: SplurjVariant, stage: SlimeStage) -> some View {
        let moods: [(label: String, mood: SlimeMood)] = [
            ("happy", .happy),
            ("alert", .alert),
            ("sleeping", .sleeping),
            ("sad", .sad),
            ("celebrating", .celebrating),
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<moods.count, id: \.self) { i in
                    VStack(spacing: 8) {
                        SplurjMascot(variant: variant, stage: stage, mood: moods[i].mood, size: 110)
                            .frame(width: 130, height: 130)
                            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.border, lineWidth: 1)
                            )
                        Text(moods[i].label.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Evolution player

    private var evolutionPlayer: some View {
        VStack(spacing: 14) {
            SplurjMascotWithEvolution(stage: $evolutionStage, variant: selectedVariant, size: 180)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))

            HStack(spacing: 10) {
                Button {
                    if let next = SlimeStage(rawValue: min(6, evolutionStage.rawValue + 1)) {
                        evolutionStage = next
                    }
                } label: {
                    Label("Level up", systemImage: "arrow.up.right.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.buttonTextOnAccent)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.honey, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    evolutionStage = .seedling
                } label: {
                    Text("Reset")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.cardTintHi, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Variant comparison

    private var variantComparisonRow: some View {
        HStack(spacing: 14) {
            ForEach(SplurjVariant.allCases) { variant in
                VStack(spacing: 8) {
                    SplurjMascot(variant: variant, stage: .leafy, size: 110)
                        .frame(width: 130, height: 130)
                        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18).strokeBorder(variant.accent.opacity(0.4), lineWidth: 1)
                        )
                    Text(variant.label.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.8)
                        .foregroundStyle(variant.accent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview("Mascot storybook") {
    NavigationStack {
        MascotStorybookView()
    }
    .preferredColorScheme(.dark)
}
#endif
