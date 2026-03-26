import SwiftUI
import SwiftData

struct BadgeGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Achievement> { $0.typeRaw == "badge" }) private var badges: [Achievement]
    @State private var selectedCategory: BadgeCategory = .money
    @State private var selectedBadgeName: String?

    private func badgesForCategory(_ category: BadgeCategory) -> [Achievement] {
        badges.filter { $0.category == category.rawValue }
    }

    private var selectedBadge: Achievement? {
        guard let name = selectedBadgeName else { return nil }
        return badges.first { $0.name == name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "medal.fill", title: "Badges", actionLabel: "\(badges.filter(\.isEarned).count)/\(badges.count)")

            Picker("Category", selection: $selectedCategory) {
                ForEach(BadgeCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)

            let categoryBadges = badgesForCategory(selectedCategory)
            if categoryBadges.isEmpty {
                Text("No badges in this category yet")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(Array(categoryBadges.enumerated()), id: \.element.name) { index, badge in
                        BadgeCellView(badge: badge) {
                            if badge.isEarned {
                                selectedBadgeName = badge.name
                            }
                        }
                        .staggerIn(index: index)
                    }
                }
            }
        }
        .padding(20)
        .splurjCard(.elevated)
        .sheet(isPresented: Binding(
            get: { selectedBadgeName != nil },
            set: { if !$0 { selectedBadgeName = nil } }
        )) {
            if let badge = selectedBadge {
                BadgeDetailSheetView(badge: badge)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            seedBadgesIfNeeded()
        }
    }

    private func seedBadgesIfNeeded() {
        guard badges.isEmpty else { return }
        for info in BadgeDefinition.all {
            let badge = Achievement.badge(name: info.name, category: info.category, badgeDescription: info.description, iconName: info.icon)
            modelContext.insert(badge)
        }
    }
}

private struct BadgeCellView: View {
    let badge: Achievement
    let action: () -> Void

    private var badgeColor: Color {
        switch badge.category {
        case "Money": Theme.accentGreen
        case "Streak": .orange
        case "Skill": Theme.teal
        default: Theme.textSecondary
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(badge.isEarned ? badgeColor.opacity(0.15) : Theme.textSecondary.opacity(0.05))
                        .frame(width: 52, height: 52)

                    if badge.isEarned {
                        Circle()
                            .fill(badgeColor.opacity(0.08))
                            .frame(width: 64, height: 64)
                    }

                    Image(systemName: badge.iconName)
                        .font(Typography.headingLarge)
                        .foregroundStyle(badge.isEarned ? badgeColor : Theme.textSecondary.opacity(0.25))

                    if !badge.isEarned {
                        Image(systemName: "lock.fill")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary.opacity(0.4))
                            .offset(x: 16, y: 16)
                    }
                }

                Text(badge.name)
                    .font(Typography.labelSmall)
                    .foregroundStyle(badge.isEarned ? Theme.textPrimary : Theme.textSecondary.opacity(0.4))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(badge.name), \(badge.isEarned ? "earned" : "locked")")
    }
}

private struct BadgeDetailSheetView: View {
    let badge: Achievement

    private var badgeColor: Color {
        switch badge.category {
        case "Money": Theme.accentGreen
        case "Streak": .orange
        case "Skill": Theme.teal
        default: Theme.textSecondary
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(badgeColor.opacity(0.06))
                    .frame(width: 104, height: 104)
                Image(systemName: badge.iconName)
                    .font(Typography.displayMedium)
                    .foregroundStyle(badgeColor)
            }

            Text(badge.name)
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text(badge.achievementDescription)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            if let date = badge.dateEarned {
                Label("Earned \(date, format: .dateTime.month(.wide).day().year())", systemImage: "calendar")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(badge.category)
                .font(Typography.labelSmall)
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(badgeColor.opacity(0.12), in: .capsule)

            ShareLink(
                item: "I earned the \"\(badge.name)\" badge on Splurj! \(badge.achievementDescription)",
                subject: Text("Splurj Badge"),
                message: Text("Check out my achievement!")
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                        .font(Typography.bodyMedium)
                }
                .foregroundStyle(badgeColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(badgeColor.opacity(0.1), in: .rect(cornerRadius: 12))
            }
            .buttonStyle(SplurjButtonStyle(variant: .secondary, size: .medium))
        }
        .padding(24)
    }
}
