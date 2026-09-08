import SwiftUI

/// One restaurant's page: hero, vitals, a chip row over its `MenuSection`s, and
/// the menu itself.
///
/// Adding a dish calls `AppState.addToFoodCart(_:from:)` — the real cart, not a
/// local copy — and plays a short bounce + "Added" confirmation so the tap
/// feels like it landed. Once anything is in the food cart a bar docks to the
/// bottom that opens the shared `CartView`, where quantities, removal, and the
/// Cash on Delivery / OneMart Wallet checkout live.
struct RestaurantDetailView: View {
    let restaurant: Restaurant

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `nil` means the "Popular" pseudo-section (every best seller on the menu).
    @State private var selectedSectionID: UUID?
    @State private var showsCart = false
    /// Id of the menu item that was just added, so only that row bounces.
    @State private var recentlyAddedItemID: UUID?

    /// Set when `add(_:)` finds the food cart holds items from a *different*
    /// restaurant — holds everything the confirmation dialog and its actions
    /// need until the user answers.
    @State private var showsRestaurantSwitchConfirm = false
    @State private var pendingItem: MenuItem?
    @State private var conflictingRestaurantName: String?

    private var isFavorite: Bool { appState.isFavoriteRestaurant(restaurant.id) }

    private var bestSellers: [MenuItem] {
        restaurant.menu.flatMap(\.items).filter(\.isBestSeller)
    }

    private var visibleItems: [MenuItem] {
        guard let selectedSectionID else { return bestSellers }
        return restaurant.menu.first { $0.id == selectedSectionID }?.items ?? []
    }

    private var visibleSectionTitle: String {
        guard let selectedSectionID else { return "Popular" }
        return restaurant.menu.first { $0.id == selectedSectionID }?.title ?? "Menu"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                hero
                vitals

                if restaurant.menu.isEmpty {
                    EmptyResultsView(
                        icon: "fork.knife",
                        title: "Menu coming soon",
                        message: "\(restaurant.name) hasn't published its menu on OneMart yet."
                    )
                } else {
                    sectionChips
                    menuList
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                        appState.toggleFavoriteRestaurant(restaurant.id)
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isFavorite ? AppColor.coral : AppColor.textSecondary)
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if appState.foodCartCount > 0 {
                cartBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(
            AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion),
            value: appState.foodCartCount
        )
        .sheet(isPresented: $showsCart) {
            CartView(kind: .food)
        }
        .confirmationDialog(
            "Start a new order?",
            isPresented: $showsRestaurantSwitchConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Items & Add", role: .destructive) {
                if let pendingItem {
                    appState.replaceFoodCart(with: pendingItem, from: restaurant.name)
                    flashAdded(pendingItem.id)
                }
                pendingItem = nil
                conflictingRestaurantName = nil
            }
            Button("Cancel", role: .cancel) {
                pendingItem = nil
                conflictingRestaurantName = nil
            }
        } message: {
            Text("Your cart has items from \(conflictingRestaurantName ?? "another restaurant"). Adding from \(restaurant.name) will remove them.")
        }
        .onAppear {
            // Land on "Popular" when the restaurant has best sellers, otherwise
            // on its first real section so the page is never empty.
            if bestSellers.isEmpty {
                selectedSectionID = restaurant.menu.first?.id
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [AppColor.coral, AppColor.amber],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 168)

            // Real photo swap point: replace with the restaurant's real cover photo once available.
            Image(systemName: restaurant.imageName)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(AppColor.onAccent.opacity(0.28))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, AppSpacing.lg)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xxs) {
                    if restaurant.isPromoted {
                        TagPill(text: "Promoted", icon: "megaphone.fill", tint: AppColor.amber, isFilled: true)
                    }
                    if restaurant.deliveryFee == 0 {
                        TagPill(text: "Free Delivery", icon: "bicycle", tint: AppColor.jade, isFilled: true)
                    }
                }

                Text(restaurant.name)
                    .font(AppTextStyle.title)
                    .foregroundStyle(AppColor.onAccent)
                    .lineLimit(2)

                Text(restaurant.tagline)
                    .font(AppTextStyle.footnote)
                    .foregroundStyle(AppColor.onAccent.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(AppSpacing.md)
        }
        .frame(height: 168)
        .clipped()
    }

    // MARK: - Vitals

    private var vitals: some View {
        HStack(spacing: 0) {
            vital(
                value: String(format: "%.1f", restaurant.rating),
                label: "\(AppFormat.compactCount(restaurant.ratingCount)) ratings",
                icon: "star.fill",
                tint: AppColor.amber
            )
            divider
            vital(
                value: restaurant.etaLabel,
                label: String(format: "%.1f km away", restaurant.distanceKm),
                icon: "clock.fill",
                tint: AppColor.coral
            )
            divider
            vital(
                value: restaurant.deliveryFee == 0 ? "Free" : AppFormat.peso(restaurant.deliveryFee),
                label: "Delivery · \(restaurant.priceLevelLabel)",
                icon: "bicycle",
                tint: AppColor.jade
            )
        }
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .padding(.horizontal, AppSpacing.md)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.borderSubtle)
            .frame(width: 1, height: 34)
    }

    private func vital(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .appTextStyle(AppTextStyle.subheadline)
            }
            Text(label)
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Menu

    private var sectionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                if !bestSellers.isEmpty {
                    FilterChip(
                        title: "Popular",
                        icon: "hand.thumbsup.fill",
                        isSelected: selectedSectionID == nil
                    ) {
                        withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                            selectedSectionID = nil
                        }
                    }
                }

                ForEach(restaurant.menu) { section in
                    FilterChip(
                        title: section.title,
                        isSelected: selectedSectionID == section.id
                    ) {
                        withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                            selectedSectionID = section.id
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var menuList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(
                title: visibleSectionTitle,
                subtitle: "\(visibleItems.count) item\(visibleItems.count == 1 ? "" : "s")"
            )
            .padding(.horizontal, AppSpacing.md)

            LazyVStack(spacing: AppSpacing.xs) {
                ForEach(visibleItems) { item in
                    MenuItemRow(
                        item: item,
                        quantityInCart: quantityInCart(for: item),
                        didJustAdd: recentlyAddedItemID == item.id,
                        onAdd: { add(item) },
                        onRemove: { removeOne(item) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Bottom cart bar

    private var cartBar: some View {
        Button {
            showsCart = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Text("\(appState.foodCartCount)")
                    .font(AppTextStyle.badge)
                    .foregroundStyle(AppColor.coral)
                    .frame(minWidth: 26, minHeight: 26)
                    .background(AppColor.onAccent, in: Capsule())

                Text("View Cart")
                    .font(AppTextStyle.buttonLabel)
                    .foregroundStyle(AppColor.onAccent)

                Spacer(minLength: 0)

                Text(AppFormat.peso(appState.foodCartTotal))
                    .font(AppTextStyle.buttonLabel)
                    .foregroundStyle(AppColor.onAccent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.onAccent.opacity(0.9))
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 56)
            .background(AppColor.coral, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .shadow(color: AppColor.coral.opacity(0.34), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.pressable)
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
        .accessibilityLabel("View food cart, \(appState.foodCartCount) items, \(AppFormat.peso(appState.foodCartTotal))")
    }

    // MARK: - Cart plumbing

    private func quantityInCart(for item: MenuItem) -> Int {
        appState.foodCart.reduce(0) { total, line in
            if case .food(let existing, let name) = line.source,
               existing.id == item.id, name == restaurant.name {
                return total + line.quantity
            }
            return total
        }
    }

    /// Adding a dish from a *different* restaurant than what's already in the
    /// cart would silently mix two orders together, so this asks first —
    /// the food cart can only ever hold one restaurant at a time.
    private func add(_ item: MenuItem) {
        if let conflict = appState.conflictingRestaurantName(for: restaurant.name) {
            pendingItem = item
            conflictingRestaurantName = conflict
            showsRestaurantSwitchConfirm = true
            return
        }
        appState.addToFoodCart(item, from: restaurant.name)
        flashAdded(item.id)
    }

    /// Bounces the row and shows the "Added" pill for a beat, without
    /// cancelling a newer flash if the user taps again quickly.
    private func flashAdded(_ itemID: UUID) {
        withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
            recentlyAddedItemID = itemID
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if recentlyAddedItemID == itemID {
                withAnimation(AppMotion.easeStandard) { recentlyAddedItemID = nil }
            }
        }
    }

    private func removeOne(_ item: MenuItem) {
        guard let line = appState.foodCart.first(where: { line in
            if case .food(let existing, let name) = line.source {
                return existing.id == item.id && name == restaurant.name
            }
            return false
        }) else { return }

        withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
            appState.decrement(line, in: .food)
        }
    }
}

// MARK: - Menu item row

/// A dish: glyph, name, description, price, and either a "+" button or a
/// stepper once it is in the cart. The whole row scales briefly on add.
private struct MenuItemRow: View {
    let item: MenuItem
    let quantityInCart: Int
    let didJustAdd: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            // Real photo swap point: replace with the dish's real photo once available.
            Image(systemName: item.imageName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColor.coral)
                .frame(width: 76, height: 68)
                .background(AppColor.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(item.name)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                        .lineLimit(2)
                    if item.isSpicy {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColor.error)
                            .accessibilityLabel("Spicy")
                    }
                }

                if item.isBestSeller {
                    TagPill(text: "Best Seller", icon: "hand.thumbsup.fill", tint: AppColor.amber)
                }

                Text(item.description)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AppSpacing.xs) {
                    Text(AppFormat.peso(item.price))
                        .appTextStyle(AppTextStyle.subheadline, color: AppColor.coral)
                    if let calories = item.calories {
                        Text("· \(calories) kcal")
                            .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                    }
                    Spacer(minLength: 0)
                    control
                }
                .padding(.top, 2)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(didJustAdd ? AppColor.success : Color.clear, lineWidth: 1.6)
        )
        .appShadow(.subtle)
        .scaleEffect(didJustAdd && !reduceMotion ? 1.02 : 1)
        .animation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion), value: didJustAdd)
        .overlay(alignment: .topTrailing) {
            if didJustAdd {
                TagPill(text: "Added", icon: "checkmark", tint: AppColor.success, isFilled: true)
                    .padding(AppSpacing.xs)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var control: some View {
        if quantityInCart == 0 {
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.onAccent)
                    .frame(width: 32, height: 32)
                    .background(AppColor.coral, in: RoundedRectangle(cornerRadius: AppRadius.sm))
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Add \(item.name) to cart")
        } else {
            HStack(spacing: AppSpacing.xs) {
                stepperButton(icon: quantityInCart > 1 ? "minus" : "trash", action: onRemove)
                    .accessibilityLabel(quantityInCart > 1 ? "Remove one \(item.name)" : "Remove \(item.name) from cart")

                Text("\(quantityInCart)")
                    .appTextStyle(AppTextStyle.subheadline)
                    .frame(minWidth: 18)
                    .monospacedDigit()

                stepperButton(icon: "plus", action: onAdd)
                    .accessibilityLabel("Add another \(item.name)")
            }
            .padding(.horizontal, AppSpacing.xxs)
            .padding(.vertical, AppSpacing.xxs)
            .background(AppColor.backgroundTertiary, in: Capsule())
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func stepperButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.onAccent)
                .frame(width: 26, height: 26)
                .background(AppColor.coral, in: Circle())
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurant: MockRestaurants.lolaNenas)
    }
    .environmentObject(AppState.previewSignedIn)
}
