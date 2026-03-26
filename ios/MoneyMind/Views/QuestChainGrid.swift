import SwiftUI
import SwiftData

struct QuestChainGrid: View {
    @Environment(\.modelContext) private var modelContext

    private let chains: [(id: String, name: String, icon: String, color: Color)] = [
        ("chain_savers_guild", "The Saver's Journey", "banknote.fill", Theme.accent),
        ("chain_compound", "The Compound Path", "chart.line.uptrend.xyaxis", Theme.celebrationYellow),
        ("chain_budget_warriors", "The Budget Battle", "shield.lefthalf.filled", Theme.axisEmotional),
        ("chain_debt_slayers", "Debt Freedom Road", "bolt.circle.fill", Theme.lavender),
        ("chain_impulse_defenders", "Impulse Mastery", "hand.raised.fill", Theme.axisRisk),
    ]

    @State private var selectedChain: ChainInfo?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(Theme.lavender)
                Text("Quest Chains")
                    .font(Typography.headingSmall)
                    .foregroundStyle(.white)
                Spacer()
                Text("5 story arcs")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 20)

            let topRow = Array(chains.prefix(4))
            let bottomRow = Array(chains.suffix(1))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(topRow, id: \.id) { chain in
                    ChainCard(
                        chainID: chain.id,
                        name: chain.name,
                        icon: chain.icon,
                        accentColor: chain.color,
                        modelContext: modelContext
                    )
                    .onTapGesture {
                        selectedChain = ChainInfo(
                            id: chain.id,
                            name: chain.name,
                            icon: chain.icon,
                            color: chain.color
                        )
                    }
                }
            }
            .padding(.horizontal, 16)

            if let last = bottomRow.first {
                ChainCard(
                    chainID: last.id,
                    name: last.name,
                    icon: last.icon,
                    accentColor: last.color,
                    modelContext: modelContext
                )
                .frame(maxWidth: .infinity)
                .frame(width: UIScreen.main.bounds.width / 2 - 22)
                .onTapGesture {
                    selectedChain = ChainInfo(
                        id: last.id,
                        name: last.name,
                        icon: last.icon,
                        color: last.color
                    )
                }
            }
        }
        .fullScreenCover(item: $selectedChain) { chain in
            QuestChainDetailView(
                chainID: chain.id,
                chainName: chain.name,
                chainIcon: chain.icon,
                chainColor: chain.color
            )
        }
    }
}

struct ChainInfo: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

private struct ChainCard: View {
    let chainID: String
    let name: String
    let icon: String
    let accentColor: Color
    let modelContext: ModelContext

    private var progress: (completed: Int, total: Int) {
        let engine = QuestEngine(modelContext: modelContext)
        return engine.chainProgress(chainID: chainID)
    }

    private var progressFraction: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }

    private var isComplete: Bool {
        progress.completed >= progress.total && progress.total > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(Typography.headingMedium)
                        .foregroundStyle(accentColor)
                }

                Spacer()

                if isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.gold)
                }
            }

            Text(name)
                .font(Typography.labelMedium)
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            if isComplete {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(Typography.labelSmall)
                    Text("COMPLETED")
                        .font(Typography.labelSmall)
                        .tracking(1)
                }
                .foregroundStyle(Theme.gold)
            } else {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.elevated)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(accentColor)
                                .frame(width: geo.size.width * progressFraction, height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(progress.completed)/\(progress.total)")
                            .font(Typography.labelSmall)
                            .foregroundStyle(accentColor)
                        Spacer()
                        if progress.completed == 0 {
                            Text("Start")
                                .font(Typography.labelSmall)
                                .foregroundStyle(accentColor)
                        } else {
                            Text("In Progress")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isComplete ? accentColor.opacity(0.4) : Theme.elevated.opacity(0.5),
                            lineWidth: isComplete ? 1 : 0.5
                        )
                )
        )
        .shadow(color: isComplete ? accentColor.opacity(0.2) : .clear, radius: isComplete ? 8 : 0)
        .contentShape(Rectangle())
    }
}
