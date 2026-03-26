import SwiftUI

struct ZoneBanner: View {
    let zone: QuestZone

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.rawValue.uppercased())
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accent)
                    .tracking(2)

                Text("Levels \(zone.levelRange.lowerBound)-\(zone.levelRange.upperBound)")
                    .font(Typography.displaySmall)
                    .foregroundStyle(.white)

                Text(zone.themeDescription)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: zone.sfSymbol)
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.5), Theme.accent.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 4) {
                Text("View Map")
                    .font(Typography.labelSmall)
                Image(systemName: "map.fill")
                    .font(Typography.labelSmall)
            }
            .foregroundStyle(Theme.textMuted)
            .padding(.trailing, 16)
            .padding(.bottom, 8)
        }
    }
}
