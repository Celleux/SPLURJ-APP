import SwiftUI
import SwiftData

struct NotificationCenterView: View {
    @Query(
        filter: #Predicate<InAppNotification> { !$0.isDismissed },
        sort: \InAppNotification.timestamp,
        order: .reverse
    ) private var notifications: [InAppNotification]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var onNavigate: (NotificationDeepLink) -> Void = { _ in }

    private var todayNotifications: [InAppNotification] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return notifications.filter { $0.timestamp >= startOfDay }
    }

    private var earlierNotifications: [InAppNotification] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return notifications.filter { $0.timestamp < startOfDay }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !notifications.isEmpty {
                        Menu {
                            Button("Mark All as Read", systemImage: "checkmark.circle") {
                                markAllRead()
                            }
                            Button("Clear All", systemImage: "trash", role: .destructive) {
                                clearAll()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(Typography.bodyLarge)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.2)) {
                    appeared = true
                }
                markVisibleAsRead()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 80)

            ZStack {
                Circle()
                    .fill(Theme.accentGreen.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.accentGreen)
            }
            .offset(y: appeared ? 0 : -8)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: appeared)

            Text("All Caught Up!")
                .font(Typography.displaySmall)
                .foregroundStyle(Theme.textPrimary)

            Text("No new notifications.\nKeep up the great work!")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var notificationsList: some View {
        VStack(spacing: 20) {
            if !todayNotifications.isEmpty {
                notificationSection(title: "Today", items: todayNotifications)
            }

            if !earlierNotifications.isEmpty {
                notificationSection(title: "Earlier", items: earlierNotifications)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }

    private func notificationSection(title: String, items: [InAppNotification]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textMuted)
                .padding(.leading, 4)

            ForEach(Array(items.enumerated()), id: \.element.persistentModelID) { index, notification in
                NotificationRow(notification: notification) {
                    handleTap(notification)
                } onDismiss: {
                    dismissNotification(notification)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.04),
                    value: appeared
                )
            }
        }
    }

    private func handleTap(_ notification: InAppNotification) {
        notification.isRead = true
        let link = notification.deepLink
        if link != .none {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onNavigate(link)
            }
        }
    }

    private func dismissNotification(_ notification: InAppNotification) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            notification.isDismissed = true
        }
    }

    private func markAllRead() {
        for notification in notifications {
            notification.isRead = true
        }
    }

    private func markVisibleAsRead() {
        for notification in todayNotifications {
            notification.isRead = true
        }
    }

    private func clearAll() {
        withAnimation(.spring(response: 0.35)) {
            for notification in notifications {
                notification.isDismissed = true
            }
        }
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: InAppNotification
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDelete = false

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                Image(systemName: "trash.fill")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white)
                    .frame(width: 60)
            }
            .frame(maxHeight: .infinity)
            .background(Theme.danger.opacity(0.8), in: .rect(cornerRadius: 16))
            .opacity(showDelete ? 1 : 0)

            Button {
                onTap()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(notification.type.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: notification.type.icon)
                            .font(Typography.headingLarge)
                            .foregroundStyle(notification.type.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(notification.title)
                                .font(Typography.headingSmall)
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)

                            if !notification.isRead {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 7, height: 7)
                            }
                        }

                        Text(notification.body)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(notification.relativeTime)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)

                        if notification.deepLink != .none {
                            Image(systemName: "chevron.right")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textMuted.opacity(0.5))
                        }
                    }
                }
                .padding(14)
                .background(
                    notification.isRead
                        ? Theme.card
                        : Theme.card.opacity(0.9),
                    in: .rect(cornerRadius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            notification.isRead
                                ? Theme.border.opacity(0.5)
                                : notification.type.color.opacity(0.15),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                            showDelete = offset < -30
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -60 {
                            withAnimation(.spring(response: 0.3)) {
                                offset = -400
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDismiss()
                            }
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
            )
        }
        .clipShape(.rect(cornerRadius: 16))
        .sensoryFeedback(.impact(weight: .light), trigger: showDelete)
    }
}
