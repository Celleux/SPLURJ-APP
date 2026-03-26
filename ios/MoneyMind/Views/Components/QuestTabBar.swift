import SwiftUI

enum QuestHubTab: String, CaseIterable {
    case dailies = "Daily"
    case weekly = "Weekly"
    case chains = "Chains"
    case boss = "Boss"
}

struct QuestTabBar: View {
    @Binding var selectedTab: QuestHubTab
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(QuestHubTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .heavy : .medium))
                            .foregroundStyle(selectedTab == tab ? .white : Theme.textMuted)

                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.accent)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "questTabIndicator", in: namespace)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
