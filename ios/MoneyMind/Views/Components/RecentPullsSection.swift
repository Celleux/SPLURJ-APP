import SwiftUI
import SwiftData

struct RecentPullsSection: View {
    let collection: [Achievement]

    private var recentCards: [Achievement] {
        collection
            .sorted { $0.obtainedAt > $1.obtainedAt }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        if !recentCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Pulls")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentCards, id: \.id) { collected in
                            if let card = CardDatabase.card(byID: collected.cardID) {
                                VStack(spacing: 6) {
                                    CardArtView(card: card)
                                        .frame(width: 100, height: 145)

                                    if collected.isNew {
                                        Text("NEW")
                                            .font(Typography.labelSmall)
                                            .foregroundStyle(Theme.background)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(card.rarity.color, in: .capsule)
                                    }
                                }
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
            }
        }
    }
}
