import SwiftUI

struct FinancialDNACardView: View {
    let dna: FinancialDNA

    private var archetype: FinancialArchetype { dna.primaryArchetype }
    private var secondary: FinancialArchetype { dna.secondaryArchetype }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text("FINANCIAL DNA")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                    .tracking(3)
                Spacer()
            }

            DNARadarShape(dna: dna, animated: true)
                .frame(width: 140, height: 140)

            VStack(spacing: 6) {
                Image(systemName: archetype.icon)
                    .font(Typography.displaySmall)
                    .foregroundStyle(archetype.color)

                Text(archetype.rawValue.uppercased())
                    .font(Typography.headingLarge)
                    .foregroundStyle(.white)
                    .tracking(3)

                if secondary != archetype {
                    Text("with \(secondary.rawValue) tendencies")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Text(archetype.tagline)
                    .font(Typography.labelMedium)
                    .foregroundStyle(archetype.color)
                    .padding(.top, 2)
            }

            HStack(spacing: 16) {
                axisMini("SPD", value: dna.spendingAxis, color: Theme.accent)
                axisMini("EMO", value: dna.emotionalAxis, color: Theme.axisEmotional)
                axisMini("RSK", value: dna.riskAxis, color: Theme.axisRisk)
                axisMini("SOC", value: dna.socialAxis, color: Theme.axisSocial)
            }

            Text("Discover yours at splurj.app")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Theme.surface, Theme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(archetype.color.opacity(0.2), lineWidth: 1)
        )
    }

    private func axisMini(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .tracking(1)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.elevated)
                    .frame(width: 6, height: 32)

                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 6, height: 32 * max(0.08, value))
            }

            Text("\(Int(value * 100))")
                .font(Typography.labelSmall)
                .foregroundStyle(color)
        }
    }
}
