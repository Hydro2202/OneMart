import SwiftUI

/// The persistent header used at the top of every tab.
///
/// It carries the shell-level controls that don't belong to any one tab: the
/// profile entry point, the messages entry point, and the cart. It presents the
/// cart and messages sheets **itself**, so a tab body only has to place the
/// header — no wiring required.
///
/// Cart rule (a specific product fix): when a cart is configured the icon is
/// **always** visible, whether the cart is empty or not. Only the badge is
/// conditional on the item count.
struct AppShellHeader: View {
    let title: String
    var subtitle: String?
    /// Which cart this tab's cart icon opens. `nil` hides the cart icon
    /// entirely (Home, Rides, Send) — it is never hidden because a cart is empty.
    var cart: CartKind?
    var showsMessages: Bool = false
    var showsProfile: Bool = true

    @EnvironmentObject private var appState: AppState
    @State private var presentedCart: CartKind?
    @State private var showsMessagesSheet = false

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appTextStyle(AppTextStyle.title)
                if let subtitle {
                    Text(subtitle)
                        .appTextStyle(AppTextStyle.footnote, color: AppColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if showsMessages {
                iconButton(
                    systemName: "bubble.left.and.bubble.right.fill",
                    badge: appState.unreadMessageCount,
                    accessibilityLabel: "Messages"
                ) {
                    showsMessagesSheet = true
                }
            }

            if let cart {
                iconButton(
                    systemName: "cart.fill",
                    badge: appState.count(in: cart),
                    accessibilityLabel: "\(cart.title), \(appState.count(in: cart)) items"
                ) {
                    presentedCart = cart
                }
            }

            if showsProfile {
                Button {
                    appState.openProfile()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.coral, AppColor.amber],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)
                        Text(initials)
                            .font(AppTextStyle.badge)
                            .foregroundStyle(AppColor.onAccent)
                    }
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Profile")
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .sheet(item: $presentedCart) { kind in
            CartView(kind: kind)
        }
        .sheet(isPresented: $showsMessagesSheet) {
            MessagesSheet()
        }
    }

    private var initials: String {
        let name = appState.currentUser?.name ?? "OneMart"
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    private func iconButton(
        systemName: String,
        badge: Int,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(AppColor.backgroundSecondary, in: Circle())
                    .overlay(Circle().stroke(AppColor.borderSubtle, lineWidth: 1))

                // Only the badge is conditional — the icon itself always shows.
                if badge > 0 {
                    CountBadge(count: badge)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Small coral count badge, shared by the header icons and the tab bar.
struct CountBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(AppFont.rounded(10, weight: .bold))
            .foregroundStyle(AppColor.onAccent)
            .padding(.horizontal, count > 9 ? 4 : 0)
            .frame(minWidth: 17, minHeight: 17)
            .background(AppColor.coral, in: Capsule())
            .overlay(Capsule().stroke(AppColor.backgroundPrimary, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        AppShellHeader(title: "Food", subtitle: "Deliver to Home · Malate, Manila", cart: .food)
        AppShellHeader(title: "Community", cart: .shop, showsMessages: true)
        AppShellHeader(title: "Rides")
        Spacer()
    }
    .background(AppColor.backgroundPrimary)
    .environmentObject(AppState.previewSignedIn)
}
