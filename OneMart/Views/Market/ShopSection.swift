import SwiftUI

/// The **Shop** half of the Market tab: a live flash-deal banner, category
/// chips, and the product grid.
///
/// The countdown is genuinely live — `TimelineView(.periodic)` re-renders every
/// second against the products' real `flashDealEndsAt` dates, so it ticks down
/// and eventually reads "Sale ended" instead of showing a frozen string.
/// Every product card pushes a full `ProductDetailView`.
struct ShopSection: View {
    @Binding var searchText: String
    @Binding var category: ShopCategory

    @EnvironmentObject private var appState: AppState

    private var products: [Product] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return MockProducts.products(in: category).filter { product in
            guard !trimmed.isEmpty else { return true }
            return product.name.localizedCaseInsensitiveContains(trimmed)
                || product.merchant.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var flashDeals: [Product] {
        MockProducts.flashDeals
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            SearchField(placeholder: "Search products or stores…", text: $searchText)
                .padding(.horizontal, AppSpacing.md)

            if searchText.isEmpty && category == .all {
                flashDealSection
            }

            FilterChipRow(
                categories: ShopCategory.allCases,
                selection: $category,
                title: { $0.rawValue },
                tint: AppColor.coral
            )

            productGrid
        }
    }

    // MARK: - Flash deals

    private var flashDealSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            flashBanner
                .padding(.horizontal, AppSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ForEach(flashDeals) { product in
                        NavigationLink(value: MarketRoute.product(product)) {
                            ProductCard(product: product, showsStock: true)
                                .frame(width: 168)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 2)
            }
        }
    }

    private var flashBanner: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [AppColor.amber, AppColor.coral],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppColor.onAccent.opacity(0.16))
                .frame(width: 108, height: 108)
                .offset(x: 26, y: -34)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Flash Sale")
                        .font(AppTextStyle.title2)
                }
                .foregroundStyle(AppColor.onAccent)

                Text("Up to 70% off · while stocks last")
                    .font(AppTextStyle.footnote)
                    .foregroundStyle(AppColor.onAccent.opacity(0.92))

                countdown
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.card)
    }

    /// Ticks once a second off the earliest real `flashDealEndsAt` in MockData.
    @ViewBuilder
    private var countdown: some View {
        if let endsAt = MockProducts.nextFlashDealEnd {
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                let remaining = endsAt.timeIntervalSince(context.date)
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .bold))
                    Text(remaining > 0 ? "Ends in \(AppFormat.countdown(until: endsAt, from: context.date))" : "Sale ended")
                        .font(AppTextStyle.badge)
                        .monospacedDigit()
                }
                .foregroundStyle(AppColor.coral)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColor.onAccent, in: Capsule())
                .accessibilityLabel(remaining > 0 ? "Flash sale ends in \(Int(remaining) / 3600) hours" : "Flash sale ended")
            }
            .padding(.top, AppSpacing.xxs)
        }
    }

    // MARK: - Grid

    private var productGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(
                title: category == .all ? "Recommended for you" : category.rawValue,
                subtitle: products.isEmpty ? nil : "\(products.count) item\(products.count == 1 ? "" : "s") · escrow protected"
            )
            .padding(.horizontal, AppSpacing.md)

            if products.isEmpty {
                EmptyResultsView(
                    icon: "bag",
                    title: "No products found",
                    message: searchText.isEmpty
                        ? "Nothing in \(category.rawValue) right now. Try another category."
                        : "Nothing matched \"\(searchText)\"."
                )
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.sm),
                        GridItem(.flexible(), spacing: AppSpacing.sm)
                    ],
                    spacing: AppSpacing.sm
                ) {
                    ForEach(products) { product in
                        NavigationLink(value: MarketRoute.product(product)) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}

// MARK: - Product card

/// Grid cell for a product. The whole cell navigates; the heart is the only
/// nested control.
struct ProductCard: View {
    let product: Product
    var showsStock: Bool = false

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFavorite: Bool { appState.isFavoriteProduct(product.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            imageArea

            Text(product.name)
                .appTextStyle(AppTextStyle.footnote)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .topLeading)

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                Text(AppFormat.peso(product.price))
                    .appTextStyle(AppTextStyle.subheadline, color: AppColor.coral)
                if let original = product.originalPrice {
                    Text(AppFormat.peso(original))
                        .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                        .strikethrough()
                }
            }

            if product.isEscrowProtected {
                TagPill(text: "Escrow Protected", icon: "lock.shield.fill", tint: AppColor.jade)
            }

            HStack(spacing: AppSpacing.xxs) {
                RatingLabel(rating: product.rating)
                Text("· \(AppFormat.compactCount(product.unitsSold)) sold")
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                Spacer(minLength: 0)
            }

            if showsStock, let stock = product.stockRemaining {
                stockBar(stock)
            }
        }
        .padding(AppSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
    }

    private var imageArea: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppColor.jade.opacity(0.18), AppColor.jade.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 104)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .overlay(
                Image(systemName: product.imageName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppColor.jade)
            )

            HStack(alignment: .top) {
                if let discount = product.discountPercent {
                    TagPill(text: "-\(discount)%", tint: AppColor.coral, isFilled: true)
                }

                Spacer(minLength: 0)

                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                        appState.toggleFavoriteProduct(product.id)
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isFavorite ? AppColor.coral : AppColor.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(AppColor.backgroundSecondary, in: Circle())
                        .appShadow(.subtle)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(isFavorite ? "Remove \(product.name) from favorites" : "Add \(product.name) to favorites")
            }
            .padding(AppSpacing.xxs)
        }
    }

    private func stockBar(_ stock: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.borderSubtle)
                    Capsule()
                        .fill(AppColor.amber)
                        .frame(width: proxy.size.width * min(1, Double(stock) / 60))
                }
            }
            .frame(height: 5)

            Text("\(stock) left")
                .appTextStyle(AppTextStyle.caption2, color: AppColor.amber)
        }
        .padding(.top, 2)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ShopSection(searchText: .constant(""), category: .constant(.all))
        }
        .background(AppColor.backgroundPrimary)
    }
    .environmentObject(AppState.previewSignedIn)
}
