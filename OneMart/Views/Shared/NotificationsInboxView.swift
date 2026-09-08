import SwiftUI

/// The list behind Home's bell icon — what the badge count on that bell
/// actually refers to. Distinct from Profile > Notifications, which holds the
/// on/off toggles for *whether* these get generated at all.
struct NotificationsInboxView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if appState.sortedNotifications.isEmpty {
                    EmptyResultsView(
                        icon: "bell.slash",
                        title: "No notifications yet",
                        message: "Updates about your orders, rides, deals, and messages will show up here."
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.xs) {
                        ForEach(appState.sortedNotifications) { notification in
                            NotificationRow(notification: notification)
                                .onTapGesture {
                                    appState.markNotificationRead(notification.id)
                                }
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if appState.unreadNotificationCount > 0 {
                        Button("Mark All Read") {
                            appState.markAllNotificationsRead()
                        }
                        .font(AppTextStyle.footnote)
                        .foregroundStyle(AppColor.coral)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .accessibilityLabel("Close notifications")
                }
            }
        }
    }
}

private struct NotificationRow: View {
    let notification: AppNotification

    private var tint: Color { notification.module?.tintColor ?? AppColor.coral }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: notification.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                if !notification.isRead {
                    Circle()
                        .fill(AppColor.coral)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(AppColor.backgroundPrimary, lineWidth: 1.5))
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .appTextStyle(notification.isRead ? AppTextStyle.bodyEmphasis : AppTextStyle.headline)
                Text(notification.message)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(AppFormat.relative(notification.date))
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NotificationsInboxView()
        .environmentObject(AppState.previewSignedIn)
}
