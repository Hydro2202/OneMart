import SwiftUI

/// Home — the cross-module hub.
///
/// Everything here is a jumping-off point into a real destination: the promo
/// hero and the quick-actions grid switch `AppState.activeTab`, the wallet card
/// has two working entry points (deep-link into Profile's Wallet section, and
/// the Top Up sheet straight from here), and the activity feed is the merged
/// cross-module order list — this session's own orders first, then the seeded
/// history — with every row tagged by the module it came from.
struct HomeScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showsTopUp = false
    @State private var promoIndex = 0

    private var firstName: String {
        let name = appState.currentUser?.name ?? "there"
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "Magandang umaga"
        case 12..<18: return "Magandang hapon"
        default: return "Magandang gabi"
        }
    }

    private var deliveryAddressLine: String {
        guard let address = appState.currentUser?.savedAddresses.first(where: { $0.isDefault })
            ?? appState.currentUser?.savedAddresses.first else {
            return "Set your delivery address"
        }
        return "Deliver to \(address.label) · \(address.fullAddress)"
    }

    var body: some View {
        VStack(spacing: 0) {
            AppShellHeader(
                title: "\(greeting), \(firstName)!",
                subtitle: deliveryAddressLine,
                showsNotificationBell: true
            )

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    walletCard
                    promoCarousel
                    quickActions
                    activeOrdersSection
                    activitySection
                    nearbySection
                }
                .padding(.vertical, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showsTopUp) {
            WalletTopUpView()
        }
    }

    // MARK: - Wallet

    private var walletCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Entry point 1 — deep-link into Profile's Wallet section.
            Button {
                appState.openWallet()
            } label: {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack {
                        Label("OneMart Wallet", systemImage: "wallet.pass.fill")
                            .font(AppTextStyle.subheadline)
                            .foregroundStyle(AppColor.onAccent.opacity(0.92))
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Verified")
                                .font(AppTextStyle.caption2)
                        }
                        .foregroundStyle(AppColor.onAccent)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 3)
                        .background(AppColor.onAccent.opacity(0.22), in: Capsule())

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColor.onAccent.opacity(0.85))
                    }

                    Text(AppFormat.pesoPrecise(appState.walletBalance))
                        .font(AppFont.rounded(32, weight: .bold))
                        .foregroundStyle(AppColor.onAccent)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("OneMart Wallet balance \(AppFormat.pesoPrecise(appState.walletBalance)). Opens your wallet.")

            HStack(spacing: AppSpacing.xs) {
                // Entry point 2 — top up directly from Home, no detour through
                // Profile.
                Button {
                    showsTopUp = true
                } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "plus.circle.fill")
                        Text("Top Up")
                            .font(AppTextStyle.subheadline)
                    }
                    .foregroundStyle(AppColor.coral)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.onAccent, in: Capsule())
                }
                .buttonStyle(.pressable)

                Button {
                    appState.openWallet()
                } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "list.bullet")
                        Text("History")
                            .font(AppTextStyle.subheadline)
                    }
                    .foregroundStyle(AppColor.onAccent)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.onAccent.opacity(0.22), in: Capsule())
                }
                .buttonStyle(.pressable)

                Spacer(minLength: 0)
            }
        }
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
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Promos

    private var promoCarousel: some View {
        VStack(spacing: AppSpacing.xs) {
            TabView(selection: $promoIndex) {
                ForEach(HomePromo.all.indices, id: \.self) { index in
                    let promo = HomePromo.all[index]
                    Button {
                        appState.activeTab = promo.tab
                    } label: {
                        promoCard(promo)
                    }
                    .buttonStyle(.pressable)
                    .padding(.horizontal, AppSpacing.md)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 132)

            HStack(spacing: 6) {
                ForEach(HomePromo.all.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == promoIndex ? AppColor.coral : AppColor.borderSubtle)
                        .frame(width: index == promoIndex ? 18 : 6, height: 6)
                }
            }
            .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: promoIndex)
            .accessibilityHidden(true)
        }
    }

    private func promoCard(_ promo: HomePromo) -> some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: promo.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppColor.onAccent.opacity(0.18))
                .frame(width: 96, height: 96)
                .offset(x: 28, y: -30)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                TagPill(text: promo.tag, tint: AppColor.onAccent.opacity(0.28), isFilled: true)

                Text(promo.title)
                    .font(AppTextStyle.title2)
                    .foregroundStyle(AppColor.onAccent)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(promo.subtitle)
                    .font(AppTextStyle.footnote)
                    .foregroundStyle(AppColor.onAccent.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 124)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(promo.title). \(promo.subtitle). Opens \(promo.tab.label).")
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "What do you need today?")
                .padding(.horizontal, AppSpacing.md)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 4),
                spacing: AppSpacing.sm
            ) {
                ForEach(HomeQuickAction.all) { action in
                    Button {
                        // The Wallet tile has no tab of its own — it opens the
                        // wallet section of Profile instead.
                        if action.tab == .home {
                            appState.openWallet()
                        } else {
                            appState.activeTab = action.tab
                        }
                    } label: {
                        VStack(spacing: AppSpacing.xxs) {
                            Image(systemName: action.icon)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(action.tint)
                                .frame(width: 56, height: 56)
                                .background(action.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .stroke(action.tint.opacity(0.18), lineWidth: 1)
                                )
                            Text(action.label)
                                .appTextStyle(AppTextStyle.caption2, color: AppColor.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(height: 28, alignment: .top)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(
                        action.tab == .home
                            ? "\(action.label). Opens your OneMart Wallet."
                            : "\(action.label). Opens the \(action.tab.label) tab."
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Active orders

    @ViewBuilder
    private var activeOrdersSection: some View {
        let active = appState.activeOrders
        if !active.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SectionHeader(title: "Happening now", subtitle: "\(active.count) order\(active.count == 1 ? "" : "s") in progress")
                    .padding(.horizontal, AppSpacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        ForEach(active.prefix(4)) { order in
                            Button {
                                appState.activeTab = AppTab.tab(for: order.module)
                            } label: {
                                activeOrderCard(order)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func activeOrderCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: order.imageName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(order.module.tintColor)
                    .frame(width: 32, height: 32)
                    .background(order.module.tintColor.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                TagPill(text: order.status.rawValue, tint: order.status.tintColor)
                Spacer(minLength: 0)
            }

            Text(order.title)
                .appTextStyle(AppTextStyle.subheadline)
                .lineLimit(1)

            Text(order.subtitle)
                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                .lineLimit(1)

            Text(AppFormat.orderTimestamp(order.placedAt))
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
        }
        .padding(AppSpacing.sm)
        .frame(width: 230, alignment: .leading)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Recent activity", subtitle: "Across every OneMart service") {
                Button("See all") { appState.openProfile() }
                    .font(AppTextStyle.subheadline)
                    .foregroundStyle(AppColor.coral)
            }
            .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.xs) {
                ForEach(appState.activityFeed.prefix(5)) { order in
                    OrderRow(order: order)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Nearby

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Popular near you", subtitle: "Top-rated kitchens in your area") {
                Button("Browse Food") { appState.activeTab = .food }
                    .font(AppTextStyle.subheadline)
                    .foregroundStyle(AppColor.coral)
            }
            .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ForEach(MockRestaurants.all.prefix(5)) { restaurant in
                        Button {
                            appState.activeTab = .food
                        } label: {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                ZStack {
                                    LinearGradient(
                                        colors: [AppColor.coral.opacity(0.22), AppColor.amber.opacity(0.16)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(width: 158, height: 88)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                                    // Real photo swap point: replace with the restaurant's real cover photo once available.
                                    Image(systemName: restaurant.imageName)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(AppColor.coral)
                                }

                                Text(restaurant.name)
                                    .appTextStyle(AppTextStyle.subheadline)
                                    .lineLimit(1)

                                HStack(spacing: AppSpacing.xxs) {
                                    RatingLabel(rating: restaurant.rating)
                                    Text("· \(restaurant.etaLabel)")
                                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                                }
                            }
                            .frame(width: 158, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 2)
            }
        }
    }

}

// MARK: - Home-only presentation data

/// Promo cards for the hero carousel. Presentation-only — these are marketing
/// slots, not a data-layer concept, so they live with the screen that shows
/// them rather than in `Models`.
struct HomePromo: Identifiable {
    let id = UUID()
    let tag: String
    let title: String
    let subtitle: String
    let tab: AppTab
    let colors: [Color]

    static let all: [HomePromo] = [
        HomePromo(
            tag: "Food",
            title: "Free delivery all day",
            subtitle: "On food orders over ₱200",
            tab: .food,
            colors: [AppColor.coral, AppColor.amber]
        ),
        HomePromo(
            tag: "Rides",
            title: "50% off your next ride",
            subtitle: "Book a moto before 9PM tonight",
            tab: .rides,
            colors: [AppColor.jade, AppColor.coral]
        ),
        HomePromo(
            tag: "Market",
            title: "Flash sale: up to 70% off",
            subtitle: "Selected electronics and beauty",
            tab: .market,
            colors: [AppColor.amber, AppColor.jade]
        ),
        HomePromo(
            tag: "Send",
            title: "Same-day parcels from ₱95",
            subtitle: "Anywhere in Metro Manila",
            tab: .logistics,
            colors: [AppColor.amber, AppColor.coral]
        )
    ]
}

/// One tile in the quick-actions grid.
struct HomeQuickAction: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let tab: AppTab
    let tint: Color

    static let all: [HomeQuickAction] = [
        HomeQuickAction(label: "Order Food", icon: "fork.knife", tab: .food, tint: AppColor.coral),
        HomeQuickAction(label: "Book a Ride", icon: "car.fill", tab: .rides, tint: AppColor.coral),
        HomeQuickAction(label: "Send Parcel", icon: "shippingbox.fill", tab: .logistics, tint: AppColor.amber),
        HomeQuickAction(label: "Shop Deals", icon: "bag.fill", tab: .market, tint: AppColor.jade),
        HomeQuickAction(label: "Groceries", icon: "cart.fill", tab: .food, tint: AppColor.coral),
        HomeQuickAction(label: "Community", icon: "person.2.fill", tab: .market, tint: AppColor.jade),
        HomeQuickAction(label: "Freight", icon: "truck.box.fill", tab: .logistics, tint: AppColor.amber),
        HomeQuickAction(label: "Wallet", icon: "wallet.pass.fill", tab: .home, tint: AppColor.jade)
    ]
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .environmentObject(AppState.previewSignedIn)
}
