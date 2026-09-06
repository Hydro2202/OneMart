import SwiftUI

/// Food & Groceries tab.
///
/// Search + category chips filter the restaurant list **live** (both are real
/// filters, not decoration), and every card pushes a full
/// `RestaurantDetailView` with that restaurant's multi-section menu.
///
/// The cart entry point is the shared `AppShellHeader`'s cart icon — always
/// visible, badged only when the food cart has something in it — which presents
/// `CartView(kind: .food)`, where quantity edits, removal, and the
/// COD/wallet checkout all live.
struct FoodScreen: View {
    @EnvironmentObject private var appState: AppState

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory = .all

    private var restaurants: [Restaurant] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return MockRestaurants.restaurants(in: selectedCategory).filter { restaurant in
            guard !trimmed.isEmpty else { return true }
            return restaurant.name.localizedCaseInsensitiveContains(trimmed)
                || restaurant.tagline.localizedCaseInsensitiveContains(trimmed)
                || restaurant.neighborhood.localizedCaseInsensitiveContains(trimmed)
                || restaurant.menu.contains { section in
                    section.items.contains { $0.name.localizedCaseInsensitiveContains(trimmed) }
                }
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
                title: "Food & Groceries",
                subtitle: deliveryAddressLine,
                cart: .food
            )

            SearchField(placeholder: "Search restaurants or dishes…", text: $searchText)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xs)

            FilterChipRow(
                categories: FoodCategory.allCases,
                selection: $selectedCategory,
                title: { $0.rawValue },
                icon: { $0.icon }
            )

            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    if restaurants.isEmpty {
                        EmptyResultsView(
                            icon: "fork.knife",
                            title: "No restaurants found",
                            message: searchText.isEmpty
                                ? "Nothing in this category delivers to you right now. Try another one."
                                : "Nothing matched \"\(searchText)\". Try a different search or category."
                        )
                    } else {
                        if selectedCategory == .all && searchText.isEmpty {
                            promotedRail
                        }

                        ForEach(restaurants) { restaurant in
                            NavigationLink(value: restaurant) {
                                RestaurantCard(restaurant: restaurant)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: Restaurant.self) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
        }
    }

    // MARK: - Promoted rail

    private var promotedRail: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Promoted near you", subtitle: "Partner deals in your area")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ForEach(MockRestaurants.promoted) { restaurant in
                        NavigationLink(value: restaurant) {
                            PromotedRestaurantCard(restaurant: restaurant)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, AppSpacing.xxs)
    }
}

// MARK: - Restaurant card

/// Full-width restaurant card: cover glyph, favourite toggle, name, rating,
/// ETA, and fee. Tapping anywhere opens the detail screen — the heart is the
/// only nested control, and it stops the row's navigation.
struct RestaurantCard: View {
    let restaurant: Restaurant

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFavorite: Bool { appState.isFavoriteRestaurant(restaurant.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            cover

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(restaurant.name)
                        .appTextStyle(AppTextStyle.headline)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(restaurant.priceLevelLabel)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                }

                Text(restaurant.tagline)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    RatingLabel(rating: restaurant.rating, count: restaurant.ratingCount)

                    Label(restaurant.etaLabel, systemImage: "clock")
                        .font(AppTextStyle.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    Label(
                        restaurant.deliveryFee == 0 ? "Free" : AppFormat.peso(restaurant.deliveryFee),
                        systemImage: "bicycle"
                    )
                    .font(AppTextStyle.caption)
                    .foregroundStyle(restaurant.deliveryFee == 0 ? AppColor.success : AppColor.textSecondary)

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, AppSpacing.xxs)
        }
        .padding(AppSpacing.xs)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
    }

    private var cover: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppColor.coral.opacity(0.22), AppColor.amber.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 118)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .overlay(
                Image(systemName: restaurant.imageName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppColor.coral)
            )

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    if restaurant.isPromoted {
                        TagPill(text: "Promoted", icon: "megaphone.fill", tint: AppColor.amber, isFilled: true)
                    }
                    if restaurant.isGroceryStore {
                        TagPill(text: "Grocery", icon: "cart.fill", tint: AppColor.jade, isFilled: true)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                        appState.toggleFavoriteRestaurant(restaurant.id)
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isFavorite ? AppColor.coral : AppColor.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColor.backgroundSecondary, in: Circle())
                        .appShadow(.subtle)
                        .scaleEffect(isFavorite && !reduceMotion ? 1.08 : 1)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(isFavorite ? "Remove \(restaurant.name) from favorites" : "Add \(restaurant.name) to favorites")
            }
            .padding(AppSpacing.xs)
        }
    }
}

/// Compact card for the horizontal "Promoted near you" rail.
private struct PromotedRestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [AppColor.coral, AppColor.amber],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                Image(systemName: restaurant.imageName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColor.onAccent.opacity(0.9))
                    .padding(AppSpacing.xs)
            }

            Text(restaurant.name)
                .appTextStyle(AppTextStyle.subheadline)
                .lineLimit(1)

            Text("\(restaurant.etaLabel) · \(restaurant.neighborhood)")
                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 200, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        FoodScreen()
    }
    .environmentObject(AppState.previewSignedIn)
}
