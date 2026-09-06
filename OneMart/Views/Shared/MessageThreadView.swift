import SwiftUI

/// A single buyer ↔ seller conversation.
///
/// Reads its thread out of `AppState` by id (rather than holding a copy) so
/// sent messages and canned replies stay in sync with the rest of the app.
/// Sending appends locally and schedules a mock reply — there is no network.
struct MessageThreadView: View {
    let threadID: UUID

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    private var thread: MessageThread? {
        appState.messageThreads.first { $0.id == threadID }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let thread {
                if thread.listingTitle != nil {
                    listingHeader(thread)
                }
                messageList(thread)
            } else {
                Spacer()
                Text("This conversation is no longer available.")
                    .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                Spacer()
            }

            composer
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(thread?.sellerName ?? "Message")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appState.markThreadRead(threadID) }
    }

    // MARK: - Header

    private func listingHeader(_ thread: MessageThread) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: thread.listingImageName ?? "tag.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.jade)
                .frame(width: 44, height: 44)
                .background(AppColor.jade.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(thread.listingTitle ?? "")
                    .appTextStyle(AppTextStyle.subheadline)
                    .lineLimit(1)
                if let price = thread.listingPrice {
                    Text(price == 0 ? "Free" : AppFormat.peso(price))
                        .appTextStyle(AppTextStyle.caption, color: AppColor.jade)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColor.borderSubtle)
                .frame(height: 1)
        }
    }

    // MARK: - Messages

    private func messageList(_ thread: MessageThread) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.xs) {
                    ForEach(thread.messages) { message in
                        bubble(message)
                            .id(message.id)
                    }
                }
                .padding(AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { scrollToLast(proxy, thread: thread) }
            .onChange(of: thread.messages.count) { _ in
                withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                    scrollToLast(proxy, thread: thread)
                }
            }
        }
    }

    private func scrollToLast(_ proxy: ScrollViewProxy, thread: MessageThread) {
        guard let last = thread.messages.last else { return }
        proxy.scrollTo(last.id, anchor: .bottom)
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 48) }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .appTextStyle(
                        AppTextStyle.callout,
                        color: message.isFromCurrentUser ? AppColor.onAccent : AppColor.textPrimary
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        message.isFromCurrentUser ? AppColor.coral : AppColor.backgroundSecondary,
                        in: RoundedRectangle(cornerRadius: AppRadius.md)
                    )

                Text(AppFormat.time(message.sentAt))
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            }

            if !message.isFromCurrentUser { Spacer(minLength: 48) }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(spacing: AppSpacing.xs) {
            TextField("Type a message…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .font(AppTextStyle.body)
                .foregroundStyle(AppColor.textPrimary)
                .focused($isComposerFocused)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.onAccent)
                    .frame(width: 42, height: 42)
                    .background(canSend ? AppColor.coral : AppColor.textTertiary.opacity(0.4), in: Circle())
            }
            .buttonStyle(.pressable)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        guard canSend else { return }
        let text = draft
        draft = ""
        appState.sendMessage(text, in: threadID)

        // Mock "seller is replying" behaviour so the thread feels alive.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            appState.appendCannedReply(in: threadID)
        }
    }
}

#Preview {
    NavigationStack {
        // AppState seeds its threads from MockMessages, so this id resolves.
        MessageThreadView(threadID: MockMessages.threads[0].id)
    }
    .environmentObject(AppState.previewSignedIn)
}
