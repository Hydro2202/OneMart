import SwiftUI

/// Full product page — the fix for "tapping a product did nothing".
///
/// Everything the grid cell only hinted at lives here: a full-bleed image area,
/// the discount badge with the struck-through original price, the merchant and
/// its credentials, the Escrow Protected badge plus what escrow actually means,
/// a quantity stepper, and an Add to Cart button that puts the chosen quantity
/// into `AppState.shopCart` via `addToShopCart(_:quantity:)`. Checkout then runs
/// through the shared `CartView` (Cash on Delivery vs. OneMart Wallet).
struct ProductDetailView: View {
    let product: Product

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var quantity = 1
    @State private var didAddToCart = false
    @State private var showsCart = false

    private var isFavorite: Bool { appState.isFavoriteProduct(product.id) }

    private var quantityInCart: Int {
        appState.shopCart.reduce(0) { total, line in
            if case .shop(let existing) = line.source, existing.id == product.id {
                return total + line.quantity
            }
            return total
        }
    }

    private var lineTotal: Double { product.price * Double(quantity) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                imageArea
                priceBlock
                merchantCard
                escrowNote
                specs
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                        appState.toggleFavoriteProduct(product.id)
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
            addToCartBar
        }
        .sheet(isPresented: $showsCart) {
            CartView(kind: .shop)
        }
    }

    // MARK: - Image

    private var imageArea: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppColor.jade.opacity(0.22), AppColor.jade.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 248)

            // Real photo swap point: replace with the product's real photo (or photo carousel) once available.
            Image(systemName: product.imageName)
                .font(.system(size: 92, weight: .semibold))
                .foregroundStyle(AppColor.jade)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if product.isFlashDeal {
                    TagPill(text: "Flash Deal", icon: "bolt.fill", tint: AppColor.amber, isFilled: true)
                }
                if let stock = product.stockRemaining {
                    TagPill(text: "\(stock) left in stock", tint: AppColor.coral, isFilled: true)
                }
            }
            .padding(AppSpacing.md)
        }
        .frame(height: 248)
        .clipped()
    }

    // MARK: - Price + title

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    if let discount = product.discountPercent, let original = product.originalPrice {
                        HStack(spacing: AppSpacing.xs) {
                            TagPill(text: "-\(discount)%", tint: AppColor.coral, isFilled: true)
                            Text(AppFormat.peso(original))
                                .appTextStyle(AppTextStyle.footnote, color: AppColor.textTertiary)
                                .strikethrough()
                        }
                    }

                    Text(AppFormat.peso(product.price))
                        .font(AppTextStyle.largeTitle)
                        .foregroundStyle(AppColor.coral)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    RatingLabel(rating: product.rating)
                    Text("\(AppFormat.compactCount(product.unitsSold)) sold")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                }
            }

            Text(product.name)
                .appTextStyle(AppTextStyle.title2)
                .fixedSize(horizontal: false, vertical: true)

            if let flashDealEndsAt = product.flashDealEndsAt, product.isFlashDeal {
                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    let remaining = flashDealEndsAt.timeIntervalSince(context.date)
                    Label(
                        remaining > 0
                            ? "Deal price ends in \(AppFormat.countdown(until: flashDealEndsAt, from: context.date))"
                            : "This deal has ended",
                        systemImage: "timer"
                    )
                    .font(AppTextStyle.caption)
                    .monospacedDigit()
                    .foregroundStyle(AppColor.amber)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Merchant

    private var merchantCard: some View {
        HStack(spacing: AppSpacing.sm) {
            // Real photo swap point: replace with the merchant's real logo once available.
            Image(systemName: product.merchant.logoName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.jade)
                .frame(width: 44, height: 44)
                .background(AppColor.jade.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(product.merchant.name)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                        .lineLimit(1)
                    if product.merchant.isOfficialStore {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColor.jade)
                            .accessibilityLabel("Official store")
                    }
                }
                Text("\(product.merchant.isOfficialStore ? "Official Store" : "Verified Seller") · \(product.merchant.responseRate)% response rate")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                RatingLabel(rating: product.merchant.rating)
            }

            Spacer(minLength: 0)

            if product.isEscrowProtected {
                TagPill(text: "Escrow", icon: "lock.shield.fill", tint: AppColor.jade)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .padding(.horizontal, AppSpacing.md)
    }

    @ViewBuilder
    private var escrowNote: some View {
        if product.isEscrowProtected {
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.jade)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Escrow Protected")
                        .appTextStyle(AppTextStyle.subheadline, color: AppColor.jade)
                    Text("Your payment is held by OneMart and only released to the seller once you confirm the item arrived as described.")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.sm)
            .background(AppColor.jade.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColor.jade.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var specs: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Details")

            VStack(spacing: 0) {
                specRow(label: "Category", value: product.category.rawValue)
                Divider().overlay(AppColor.borderSubtle)
                specRow(label: "Sold", value: "\(AppFormat.compactCount(product.unitsSold)) units")
                Divider().overlay(AppColor.borderSubtle)
                specRow(label: "Rating", value: String(format: "%.1f out of 5", product.rating))
                if let stock = product.stockRemaining {
                    Divider().overlay(AppColor.borderSubtle)
                    specRow(label: "Stock remaining", value: "\(stock)")
                }
                Divider().overlay(AppColor.borderSubtle)
                specRow(label: "Ships from", value: product.merchant.name)
            }
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(.subtle)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
            Spacer()
            Text(value)
                .appTextStyle(AppTextStyle.callout)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Add to cart

    private var addToCartBar: some View {
        VStack(spacing: AppSpacing.xs) {
            if didAddToCart {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Added to cart")
                        .font(AppTextStyle.buttonLabel)
                }
                .foregroundStyle(AppColor.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColor.success, in: RoundedRectangle(cornerRadius: AppRadius.md))
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                HStack(spacing: AppSpacing.sm) {
                    quantityStepper

                    Button(action: addToCart) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 15, weight: .bold))
                            Text("Add · \(AppFormat.peso(lineTotal))")
                                .font(AppTextStyle.buttonLabel)
                                .lineLimit(1)
                        }
                        .foregroundStyle(AppColor.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppColor.coral, in: RoundedRectangle(cornerRadius: AppRadius.md))
                        .shadow(color: AppColor.coral.opacity(0.32), radius: 16, x: 0, y: 8)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Add \(quantity) \(product.name) to cart, \(AppFormat.peso(lineTotal))")
                }
            }

            if quantityInCart > 0 {
                Button {
                    showsCart = true
                } label: {
                    Text("View Cart · \(quantityInCart) of this item")
                        .font(AppTextStyle.subheadline)
                        .foregroundStyle(AppColor.coral)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColor.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm))
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
        .padding(.bottom, AppSpacing.xs)
        .background(.ultraThinMaterial)
        .animation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion), value: didAddToCart)
        .animation(AppMotion.springSnappy, value: quantityInCart)
    }

    private var quantityStepper: some View {
        HStack(spacing: AppSpacing.xs) {
            stepperButton(icon: "minus", isEnabled: quantity > 1) {
                quantity = max(1, quantity - 1)
            }
            Text("\(quantity)")
                .appTextStyle(AppTextStyle.headline)
                .monospacedDigit()
                .frame(minWidth: 22)
            stepperButton(icon: "plus", isEnabled: quantity < maximumQuantity) {
                quantity = min(maximumQuantity, quantity + 1)
            }
        }
        .padding(.horizontal, AppSpacing.xs)
        .frame(height: 54)
        .background(AppColor.backgroundTertiary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quantity: \(quantity)")
    }

    /// Never let the user add more than the seller actually has.
    private var maximumQuantity: Int {
        min(product.stockRemaining ?? 99, 99)
    }

    private func stepperButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isEnabled ? AppColor.onAccent : AppColor.onAccent.opacity(0.5))
                .frame(width: 32, height: 32)
                .background(AppColor.coral.opacity(isEnabled ? 1 : 0.4), in: Circle())
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled)
        .accessibilityLabel(icon == "plus" ? "Increase quantity" : "Decrease quantity")
    }

    private func addToCart() {
        appState.addToShopCart(product, quantity: quantity)
        withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
            didAddToCart = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(AppMotion.easeStandard) {
                didAddToCart = false
                quantity = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: MockProducts.all[0])
    }
    .environmentObject(AppState.previewSignedIn)
}
