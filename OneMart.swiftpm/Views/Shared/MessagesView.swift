import SwiftUI

/// Conversation list for the Community/Market messaging feature — the screen
/// behind the message icon in the Market tab's header.
///
/// Deliberately has **no** `NavigationStack` of its own so it can be pushed
/// inside an existing stack. Use `MessagesSheet` when presenting it modally.
struct MessagesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.messageThreads.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xs) {
                        ForEach(appState.sortedThreads) { thread in
                            NavigationLink {
                                MessageThreadView(threadID: thread.id)
                            } label: {
                                MessageThreadRow(thread: thread)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 42))
                .foregroundStyle(AppColor.textTertiary.opacity(0.6))
            Text("No messages yet")
                .appTextStyle(AppTextStyle.title2)
            Text("Tap \"Message Seller\" on any Community listing to start a conversation.")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Modal wrapper: `MessagesView` in its own stack with a close button.
struct MessagesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MessagesView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .accessibilityLabel("Close messages")
                    }
                }
        }
    }
}

/// One row in the conversation list.
struct MessageThreadRow: View {
    let thread: MessageThread

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(thread.sellerName)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let last = thread.lastMessage {
                        Text(AppFormat.relative(last.sentAt))
                            .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                    }
                }

                if let listingTitle = thread.listingTitle {
                    Text(listingTitle)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.jade)
                        .lineLimit(1)
                }

                Text(thread.previewText)
                    .appTextStyle(AppTextStyle.footnote, color: AppColor.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            if thread.unreadCount > 0 {
                Text("\(thread.unreadCount)")
                    .font(AppTextStyle.badge)
                    .foregroundStyle(AppColor.onAccent)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(AppColor.coral, in: Circle())
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(AppColor.jade.opacity(0.16))
                .frame(width: 48, height: 48)
            if let imageName = thread.listingImageName {
                Image(systemName: imageName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.jade)
            } else {
                Text(thread.sellerInitials)
                    .appTextStyle(AppTextStyle.subheadline, color: AppColor.jade)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessagesView()
    }
    .environmentObject(AppState.previewSignedIn)
}
