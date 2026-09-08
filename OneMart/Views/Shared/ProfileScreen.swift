import SwiftUI
import UIKit

/// Full-screen profile overlay presented over the tab shell (matching the
/// prototype's `showProfile` behaviour), with a close button rather than a tab.
///
/// Sub-sections are real pushes on a `NavigationStack`, which is also how the
/// wallet deep-link works: when `appState.profileInitialSection == .wallet`
/// (Home's wallet card, or `AppState.openWallet()`), the Wallet screen is
/// pre-pushed onto the path so the user lands straight on it and can still
/// navigate back to the profile root.
struct ProfileScreen: View {
    @EnvironmentObject private var appState: AppState

    private enum Route: Hashable {
        case wallet
        case orders
        case favorites
        case addresses
        case editProfile
        case notifications
        case privacy
        case help
    }

    @State private var path: [Route] = []
    @State private var showsLogoutConfirmation = false
    @State private var showsTopUp = false

    private var user: UserProfile? { appState.currentUser }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    identityHeader
                    walletCard
                    menuList
                    logOutButton
                    footer
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.closeProfile()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .accessibilityLabel("Close profile")
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .wallet: WalletSectionView(showsTopUp: $showsTopUp)
                case .orders: OrderHistoryView()
                case .favorites: FavoritesView()
                case .addresses: SavedAddressesView()
                case .editProfile: EditProfileView()
                case .notifications: NotificationSettingsView()
                case .privacy: PrivacySecurityView()
                case .help: HelpSupportView()
                }
            }
        }
        .onAppear {
            if appState.profileInitialSection == .wallet && path.isEmpty {
                path = [.wallet]
            }
        }
        .sheet(isPresented: $showsTopUp) {
            WalletTopUpView()
        }
        .confirmationDialog("Log out?", isPresented: $showsLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                Task { await appState.logOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your account.")
        }
    }

    // MARK: - Header

    private var identityHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                if let photoData = user?.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColor.coral, AppColor.amber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                    Text(initials)
                        .font(AppFont.rounded(30, weight: .bold))
                        .foregroundStyle(AppColor.onAccent)
                }
            }
            .appShadow(.card)

            Text(user?.name ?? "Guest")
                .appTextStyle(AppTextStyle.title2)

            VStack(spacing: 2) {
                if let email = user?.email {
                    Text(email)
                        .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                }
                if let phone = user?.phone {
                    Text(phone)
                        .appTextStyle(AppTextStyle.footnote, color: AppColor.textTertiary)
                }
                if let memberSince = user?.memberSince {
                    Text("Member since \(memberSince, format: .dateTime.month(.wide).year())")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                        .padding(.top, AppSpacing.xxs)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
    }

    private var initials: String {
        let name = user?.name ?? "OneMart"
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    // MARK: - Wallet summary

    private var walletCard: some View {
        Button {
            path.append(.wallet)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Label("OneMart Wallet", systemImage: "wallet.pass.fill")
                        .font(AppTextStyle.subheadline)
                        .foregroundStyle(AppColor.onAccent.opacity(0.9))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.onAccent.opacity(0.8))
                }
                Text(AppFormat.pesoPrecise(appState.walletBalance))
                    .font(AppFont.rounded(30, weight: .bold))
                    .foregroundStyle(AppColor.onAccent)
                Text("\(appState.walletTransactions.count) recent transactions")
                    .font(AppTextStyle.caption)
                    .foregroundStyle(AppColor.onAccent.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(
                LinearGradient(
                    colors: [AppColor.coral, AppColor.amber],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppRadius.lg)
            )
            .appShadow(.card)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Menu

    private var menuList: some View {
        VStack(spacing: AppSpacing.xs) {
            menuRow(
                icon: "person.crop.circle.fill",
                tint: AppColor.coral,
                title: "Edit Profile",
                subtitle: "Photo, name, phone, email"
            ) { path.append(.editProfile) }

            menuRow(
                icon: "wallet.pass.fill",
                tint: AppColor.coral,
                title: "Wallet & Top Up",
                subtitle: "\(AppFormat.pesoPrecise(appState.walletBalance)) balance"
            ) { path.append(.wallet) }

            menuRow(
                icon: "shippingbox.fill",
                tint: AppColor.amber,
                title: "Order History",
                subtitle: "\(appState.activityFeed.count) orders across all services"
            ) { path.append(.orders) }

            menuRow(
                icon: "heart.fill",
                tint: AppColor.coral,
                title: "Saved Favorites",
                subtitle: "\(appState.favoriteCount) saved"
            ) { path.append(.favorites) }

            menuRow(
                icon: "mappin.circle.fill",
                tint: AppColor.jade,
                title: "Saved Addresses",
                subtitle: "\(user?.savedAddresses.count ?? 0) addresses"
            ) { path.append(.addresses) }

            menuRow(
                icon: "bell.fill",
                tint: AppColor.amber,
                title: "Notifications",
                subtitle: "Manage alerts"
            ) { path.append(.notifications) }

            menuRow(
                icon: "lock.shield.fill",
                tint: AppColor.jade,
                title: "Privacy & Security",
                subtitle: "Change password, 2FA"
            ) { path.append(.privacy) }

            menuRow(
                icon: "questionmark.circle.fill",
                tint: AppColor.textSecondary,
                title: "Help & Support",
                subtitle: "FAQs, chat support"
            ) { path.append(.help) }
        }
    }

    private func menuRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                    Text(subtitle)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(AppSpacing.sm)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(.subtle)
        }
        .buttonStyle(.pressable)
    }

    private var logOutButton: some View {
        Button {
            showsLogoutConfirmation = true
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Log Out")
                    .font(AppTextStyle.buttonLabel)
            }
            .foregroundStyle(AppColor.error)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColor.error.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColor.error.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.pressable)
        .padding(.top, AppSpacing.xs)
    }

    private var footer: some View {
        Text("OneMart v1.0 · All-in-One Digital Ecosystem")
            .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            .padding(.top, AppSpacing.xs)
            .padding(.bottom, AppSpacing.lg)
    }
}

// MARK: - Wallet section

/// Balance, Top Up entry point, and the transaction ledger.
private struct WalletSectionView: View {
    @Binding var showsTopUp: Bool
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("CURRENT BALANCE")
                        .font(AppTextStyle.caption2)
                        .tracking(1)
                        .foregroundStyle(AppColor.onAccent.opacity(0.75))
                    Text(AppFormat.pesoPrecise(appState.walletBalance))
                        .font(AppFont.rounded(34, weight: .bold))
                        .foregroundStyle(AppColor.onAccent)
                    HStack(spacing: AppSpacing.xxs) {
                        Circle()
                            .fill(AppColor.success)
                            .frame(width: 7, height: 7)
                        Text("Verified · Escrow Protected")
                            .font(AppTextStyle.caption)
                            .foregroundStyle(AppColor.onAccent.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .background(
                    LinearGradient(
                        colors: [AppColor.coral, AppColor.amber],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppRadius.lg)
                )
                .appShadow(.card)

                PrimaryButton(title: "Top Up", systemImage: "plus") {
                    showsTopUp = true
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Recent Transactions")
                        .appTextStyle(AppTextStyle.headline)

                    if appState.walletTransactions.isEmpty {
                        Text("No transactions yet.")
                            .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                    } else {
                        ForEach(appState.walletTransactions) { transaction in
                            WalletTransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("OneMart Wallet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One row in the wallet ledger — shared shape for payments, top-ups, refunds.
struct WalletTransactionRow: View {
    let transaction: WalletTransaction

    private var tint: Color {
        transaction.type.isCredit ? AppColor.success : (transaction.module?.tintColor ?? AppColor.coral)
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: transaction.module?.icon ?? transaction.paymentMethod.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .appTextStyle(AppTextStyle.bodyEmphasis)
                    .lineLimit(1)
                Text(transaction.subtitle)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .lineLimit(1)
                Text(AppFormat.orderTimestamp(transaction.date))
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(AppFormat.signedPeso(transaction.signedAmount))
                    .appTextStyle(AppTextStyle.subheadline, color: transaction.type.isCredit ? AppColor.success : AppColor.textPrimary)
                Text(transaction.type.rawValue)
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }
}

// MARK: - Order history

private struct OrderHistoryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var filter: ServiceModule?

    /// This session's own orders (a ride just booked, a parcel just sent)
    /// merged with the seeded history — same source Home's activity feed
    /// uses, so an order placed on one screen reliably shows up on the other.
    private var orders: [Order] {
        appState.activityFeed.filter { filter == nil || $0.module == filter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                filterRow

                if orders.isEmpty {
                    EmptyResultsView(
                        icon: "shippingbox",
                        title: "No orders here",
                        message: "You don't have any \(filterLabel(filter).lowercased()) orders yet."
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.xs) {
                        ForEach(orders) { order in
                            OrderRow(order: order)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                FilterChip(title: "All", isSelected: filter == nil) { filter = nil }
                ForEach(ServiceModule.allCases) { module in
                    FilterChip(title: filterLabel(module), isSelected: filter == module) { filter = module }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 2)
        }
    }

    /// "Send" for `.logistics` to match the tab bar; every other module's
    /// own `shortName` otherwise. `nil` means "All".
    private func filterLabel(_ module: ServiceModule?) -> String {
        guard let module else { return "All" }
        return module == .logistics ? "Send" : module.shortName
    }
}

/// Cross-module order row, reused by Home's activity feed.
struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: order.imageName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(order.module.tintColor)
                .frame(width: 44, height: 44)
                .background(order.module.tintColor.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(order.title)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                        .lineLimit(1)
                    Text(order.module.shortName)
                        .font(AppTextStyle.caption2)
                        .foregroundStyle(order.module.tintColor)
                        .padding(.horizontal, AppSpacing.xxs)
                        .padding(.vertical, 2)
                        .background(order.module.tintColor.opacity(0.14), in: Capsule())
                }
                Text(order.subtitle)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .lineLimit(1)
                Text(AppFormat.orderTimestamp(order.placedAt))
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(AppFormat.peso(order.total))
                    .appTextStyle(AppTextStyle.subheadline)
                Text(order.status.rawValue)
                    .appTextStyle(AppTextStyle.caption2, color: order.status.tintColor)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }
}

// MARK: - Favorites

/// Resolves the favourite id sets in `AppState` against MockData so the user
/// sees the real restaurants / products / listings they hearted.
private struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if appState.favoriteCount == 0 {
                    emptyState
                } else {
                    if !appState.favoriteRestaurants.isEmpty {
                        section(title: "Restaurants") {
                            ForEach(appState.favoriteRestaurants) { restaurant in
                                favoriteRow(
                                    icon: restaurant.imageName,
                                    tint: AppColor.coral,
                                    title: restaurant.name,
                                    subtitle: "\(restaurant.neighborhood) · \(restaurant.etaLabel)",
                                    moduleLabel: "Food"
                                ) {
                                    appState.toggleFavoriteRestaurant(restaurant.id)
                                }
                            }
                        }
                    }

                    if !appState.favoriteProducts.isEmpty {
                        section(title: "Shop") {
                            ForEach(appState.favoriteProducts) { product in
                                favoriteRow(
                                    icon: product.imageName,
                                    tint: AppColor.jade,
                                    title: product.name,
                                    subtitle: "\(product.merchant.name) · \(AppFormat.peso(product.price))",
                                    moduleLabel: "Shop"
                                ) {
                                    appState.toggleFavoriteProduct(product.id)
                                }
                            }
                        }
                    }

                    if !appState.favoriteListings.isEmpty {
                        section(title: "Community") {
                            ForEach(appState.favoriteListings) { listing in
                                favoriteRow(
                                    icon: listing.imageName,
                                    tint: AppColor.jade,
                                    title: listing.title,
                                    subtitle: "\(listing.locationName) · \(listing.isFree ? "Free" : AppFormat.peso(listing.price))",
                                    moduleLabel: "Marketplace"
                                ) {
                                    appState.toggleFavoriteListing(listing.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Saved Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "heart")
                .font(.system(size: 42))
                .foregroundStyle(AppColor.textTertiary.opacity(0.6))
            Text("No favorites yet")
                .appTextStyle(AppTextStyle.title2)
            Text("Tap the heart on restaurants, products, and listings to save them here.")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .appTextStyle(AppTextStyle.headline)
            content()
        }
    }

    private func favoriteRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        moduleLabel: String,
        onUnfavorite: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .appTextStyle(AppTextStyle.bodyEmphasis)
                    .lineLimit(1)
                Text(subtitle)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .lineLimit(1)
                Text(moduleLabel)
                    .font(AppTextStyle.caption2)
                    .foregroundStyle(tint)
                    .padding(.horizontal, AppSpacing.xxs)
                    .padding(.vertical, 2)
                    .background(tint.opacity(0.14), in: Capsule())
            }

            Spacer(minLength: 0)

            Button(action: onUnfavorite) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.coral)
                    .frame(width: 34, height: 34)
                    .background(AppColor.coral.opacity(0.14), in: Circle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Remove \(title) from favorites")
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }
}

// MARK: - Saved addresses

private struct SavedAddressesView: View {
    @EnvironmentObject private var appState: AppState

    @State private var editingAddress: SavedAddress?
    @State private var showsAddSheet = false
    @State private var pendingDeleteID: UUID?

    private var addresses: [SavedAddress] {
        appState.currentUser?.savedAddresses ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xs) {
                if addresses.isEmpty {
                    EmptyResultsView(
                        icon: "mappin.slash",
                        title: "No saved addresses yet",
                        message: "Add your home, work, or any place you order to often."
                    )
                }

                ForEach(addresses) { address in
                    addressRow(address)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Saved Addresses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showsAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColor.coral)
                }
                .accessibilityLabel("Add address")
            }
        }
        .sheet(isPresented: $showsAddSheet) {
            SavedAddressFormView(existingAddress: nil) { address in
                appState.addAddress(address)
            }
        }
        .sheet(item: $editingAddress) { address in
            SavedAddressFormView(existingAddress: address) { updated in
                appState.updateAddress(updated)
            }
        }
        .confirmationDialog(
            "Delete this address?",
            isPresented: Binding(
                get: { pendingDeleteID != nil },
                set: { if !$0 { pendingDeleteID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pendingDeleteID {
                    appState.deleteAddress(pendingDeleteID)
                }
                pendingDeleteID = nil
            }
            Button("Cancel", role: .cancel) { pendingDeleteID = nil }
        }
    }

    private func addressRow(_ address: SavedAddress) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: address.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.jade)
                .frame(width: 38, height: 38)
                .background(AppColor.jade.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(address.label)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                    if address.isDefault {
                        Text("Default")
                            .font(AppTextStyle.caption2)
                            .foregroundStyle(AppColor.jade)
                            .padding(.horizontal, AppSpacing.xxs)
                            .padding(.vertical, 2)
                            .background(AppColor.jade.opacity(0.14), in: Capsule())
                    }
                }
                Text(address.fullAddress)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Menu {
                Button {
                    editingAddress = address
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                if !address.isDefault {
                    Button {
                        appState.setDefaultAddress(address.id)
                    } label: {
                        Label("Set as Default", systemImage: "checkmark.seal")
                    }
                }
                Button(role: .destructive) {
                    pendingDeleteID = address.id
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options for \(address.label)")
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }
}

#Preview {
    ProfileScreen()
        .environmentObject(AppState.previewSignedIn)
}
