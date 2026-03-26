import SwiftUI
import SwiftData

struct CardCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager
    @Query(filter: #Predicate<Achievement> { $0.typeRaw == "card" }) private var collection: [Achievement]
    @Query private var profiles: [UserProfile]
    @Query private var quizResults: [QuizResult]

    private var userLevel: Int { CharacterStage.level(from: profiles.first?.xpPoints ?? 0) }
    private var archetypeName: String { (quizResults.first?.personality ?? .builder).rawValue }
    @State private var selectedSet: CardSet?
    @State private var selectedCard: CardDefinition?
    @State private var sortMode: CollectionSortMode = .bySet
    @State private var showPaywall: Bool = false

    private let freeRarities: Set<CardRarity> = [.common, .uncommon]

    private var displayedCards: [CardDefinition] {
        let base: [CardDefinition]
        if let set = selectedSet {
            base = CardDatabase.cards(forSet: set)
        } else {
            base = CardDatabase.allCards
        }

        switch sortMode {
        case .bySet:
            return base
        case .byRarity:
            let order: [CardRarity] = [.legendary, .epic, .rare, .uncommon, .common]
            return base.sorted { order.firstIndex(of: $0.rarity)! < order.firstIndex(of: $1.rarity)! }
        case .byNewest:
            return base.sorted { card1, card2 in
                let date1 = collectedInfo(card1.id)?.obtainedAt ?? .distantPast
                let date2 = collectedInfo(card2.id)?.obtainedAt ?? .distantPast
                return date1 > date2
            }
        case .byDuplicates:
            return base.sorted { card1, card2 in
                let dup1 = collectedInfo(card1.id)?.duplicateCount ?? -1
                let dup2 = collectedInfo(card2.id)?.duplicateCount ?? -1
                return dup1 > dup2
            }
        }
    }

    private func isCollected(_ cardID: String) -> Bool {
        collection.contains { $0.cardID == cardID }
    }

    private func collectedInfo(_ cardID: String) -> Achievement? {
        collection.first { $0.cardID == cardID }
    }

    private func collectedCountForSet(_ set: CardSet) -> Int {
        collection.filter { $0.setName == set.rawValue }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    setProgressRings
                    sortPicker
                    progressBar
                    completedSetShareBanner
                    cardGrid
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card, collectedInfo: collectedInfo(card.id))
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var setProgressRings: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                setRingButton(label: "All", icon: "rectangle.stack.fill", color: Theme.accent, count: collection.count, total: CardDatabase.totalCards, isSelected: selectedSet == nil) {
                    selectedSet = nil
                }

                ForEach(CardSet.allCases, id: \.self) { set in
                    let count = collectedCountForSet(set)
                    let total = set.totalCards
                    let isComplete = count >= total
                    setRingButton(label: set.rawValue.components(separatedBy: " ").first ?? "", icon: set.icon, color: set.accentColor, count: count, total: total, isSelected: selectedSet == set, isComplete: isComplete) {
                        selectedSet = set
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
    }

    private func setRingButton(label: String, icon: String, color: Color, count: Int, total: Int, isSelected: Bool, isComplete: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Theme.elevated, lineWidth: 3)
                        .frame(width: 52, height: 52)

                    Circle()
                        .trim(from: 0, to: total > 0 ? CGFloat(count) / CGFloat(total) : 0)
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))

                    if isComplete {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 48, height: 48)
                            Image(systemName: "checkmark")
                                .font(Typography.headingLarge)
                                .foregroundStyle(Theme.background)
                        }
                    } else {
                        Image(systemName: icon)
                            .font(Typography.bodyLarge)
                            .foregroundStyle(isSelected ? color : Theme.textSecondary)
                    }
                }

                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? color : Theme.textMuted)
                    .lineLimit(1)

                Text("\(count)/\(total)")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var sortPicker: some View {
        Picker("Sort", selection: $sortMode) {
            ForEach(CollectionSortMode.allCases, id: \.self) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            SectionHeader(icon: "chart.bar.fill", title: "Collection Progress", actionLabel: "\(collection.count)/\(CardDatabase.totalCards)")
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surface)
                        .frame(height: 8)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(
                            width: geo.size.width * CGFloat(collection.count) / CGFloat(max(CardDatabase.totalCards, 1)),
                            height: 8
                        )
                        .shadow(color: Theme.accent.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var completedSetShareBanner: some View {
        let completedSets = CardSet.allCases.filter { set in
            collectedCountForSet(set) >= set.totalCards
        }
        if !completedSets.isEmpty {
            VStack(spacing: 8) {
                ForEach(completedSets, id: \.self) { set in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(Typography.headingMedium)
                            .foregroundStyle(set.accentColor)
                        Text("\(set.rawValue) Complete!")
                            .font(Typography.labelMedium)
                            .foregroundStyle(.white)
                        Spacer()
                        ShareAchievementButton(
                            type: .collection(collected: set.totalCards, total: set.totalCards, setName: set.rawValue),
                            level: userLevel,
                            archetypeName: archetypeName,
                            style: .icon
                        )
                    }
                    .padding(12)
                    .splurjCard(.elevated)
                }
            }
            .padding(.horizontal)
        }
    }

    private var cardGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 16) {
            ForEach(Array(displayedCards.enumerated()), id: \.element.id) { index, card in
                let collected = isCollected(card.id)
                let info = collectedInfo(card.id)

                let isGated = !premiumManager.hasFullAccess && !freeRarities.contains(card.rarity) && collected

                Button {
                    if isGated {
                        showPaywall = true
                    } else if collected {
                        selectedCard = card
                    }
                } label: {
                    cardCell(card: card, collected: collected, info: info)
                        .overlay {
                            if isGated {
                                ZStack {
                                    Color.black.opacity(0.5)
                                    VStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Theme.gold)
                                        Text("PRO")
                                            .font(Typography.labelSmall)
                                            .foregroundStyle(Theme.gold)
                                    }
                                }
                                .clipShape(.rect(cornerRadius: 12))
                            }
                        }
                }
                .buttonStyle(.plain)
                .staggerIn(index: index)
            }
        }
        .padding(.horizontal)
    }

    private func cardCell(card: CardDefinition, collected: Bool, info: Achievement?) -> some View {
        ZStack {
            if collected {
                CardArtView(card: card)
                    .frame(height: 210)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surface)
                    .frame(height: 210)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.border.opacity(0.3), lineWidth: 0.5)
                    )
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: card.set.icon)
                                .font(Typography.displayMedium)
                                .foregroundStyle(Theme.textMuted.opacity(0.15))

                            ZStack {
                                Circle()
                                    .fill(Theme.elevated)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "questionmark")
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.textMuted)
                            }

                            Text(card.rarity.label)
                                .font(Typography.labelSmall)
                                .foregroundStyle(card.rarity.color.opacity(0.5))

                            Image(systemName: "lock.fill")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textMuted.opacity(0.5))
                        }
                    }
            }

            if let info, info.isNew {
                VStack {
                    HStack {
                        Spacer()
                        newBadge(color: card.rarity.color)
                    }
                    Spacer()
                }
            }

            if let info, info.evolutionLevel > 0 {
                VStack {
                    HStack {
                        Text("Evo +\(info.evolutionLevel)")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.background)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.gold, in: .capsule)
                            .padding(6)
                        Spacer()
                    }
                    Spacer()
                }
            }

            if let info, info.duplicateCount > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("x\(info.duplicateCount + 1)")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.surface.opacity(0.9), in: .capsule)
                            .padding(6)
                    }
                }
            }
        }
    }

    private func newBadge(color: Color) -> some View {
        Text("NEW")
            .font(Typography.labelSmall)
            .foregroundStyle(Theme.background)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: .capsule)
            .padding(6)
    }
}

enum CollectionSortMode: String, CaseIterable {
    case bySet
    case byRarity
    case byNewest
    case byDuplicates

    var label: String {
        switch self {
        case .bySet: return "Set"
        case .byRarity: return "Rarity"
        case .byNewest: return "Newest"
        case .byDuplicates: return "Dupes"
        }
    }
}

extension CardDefinition: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    nonisolated public static func == (lhs: CardDefinition, rhs: CardDefinition) -> Bool {
        lhs.id == rhs.id
    }
}
