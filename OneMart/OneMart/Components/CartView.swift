import SwiftUI

/// One cart screen, parameterised over *which* cart it shows.
///
/// Food and Shop each own an independent cart (`CartKind`), but the screen —
/// line items with steppers, per-line removal, the order summary, the payment
/// step, and the confirmation — is identical, so it lives here once instead of
/// being duplicated per tab. Present it as a `.sheet` from either tab's cart
/// icon. Removing the last line simply shows the empty state; the cart entry
/// point itself never disappears.
struct CartView: View {
    let kind: CartKind

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var paymentSelection: PaymentMethod = .cashOnDelivery
    @State private var errorMessage: String?
    @State private var isPlacingOrder = false
    @State private var placedOrder: PlacedOrderSummary?

    /// Captured at confirm time so the receipt still reads correctly after the
    /// cart has been emptied.
    private struct PlacedOrderSummary: Identifiable {
        let id = UUID()
        let total: Double
        let itemCount: Int
        let method: PaymentMethod
    }

    private var items: [CartItem] { appState.items(in: kind) }
    private var subtotal: Double { appState.total(in: kind) }

    /// Food charges a flat rider fee; Shop ships free above ₱1,000.
    private var deliveryFee: Double {
        guard !items.isEmpty else { return 0 }
        switch kind {
        case .food: return 39
        case .shop: return subtotal >= 1_000 ? 0 : 58
        }
    }

    private var total: Double { subtotal + deliveryFee }

    private var canConfirm: Bool {
        !items.isEmpty && appState.canPay(with: paymentSelection, amount: total)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.backgroundPrimary.ignoresSafeArea()

                if let placedOrder {
                    successState(placedOrder)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else if items.isEmpty {
                    emptyState
                        .transition(.opacity)
                } else {
                    cartContent
                }
            }
            .navigationTitle(placedOrder == nil ? kind.title : "Order Confirmed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .accessibilityLabel("Close cart")
                }
            }
            .animation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion), value: items.count)
            .animation(AppMotion.easeStandard, value: placedOrder?.id)
        }
    }

    // MARK: - Cart content

    private var cartContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(items) { item in
                        CartLineRow(
                            item: item,
                            onIncrement: { appState.increment(item, in: kind) },
                            onDecrement: { appState.decrement(item, in: kind) },
                            onRemove: { appState.remove(item, in: kind) }
                        )
                    }
                }

                summaryCard

                PaymentMethodPicker(selection: $paymentSelection, amountDue: total) {
                    // Close the cart first, then deep-link into the wallet —
                    // presenting the profile cover while this sheet is still
                    // on screen would be dropped by UIKit.
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        appState.openWallet()
                    }
                }

                if let errorMessage {
                    InlineBanner(kind: .error, message: errorMessage)
                }
            }
            .padding(AppSpacing.md)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            confirmBar
        }
    }

    private var summaryCard: some View {
        VStack(spacing: AppSpacing.xs) {
            summaryRow(label: "Subtotal", value: AppFormat.pesoPrecise(subtotal))
            summaryRow(
                label: kind == .food ? "Delivery fee" : "Shipping",
                value: deliveryFee == 0 ? "Free" : AppFormat.pesoPrecise(deliveryFee),
                valueColor: deliveryFee == 0 ? AppColor.success : AppColor.textPrimary
            )
            Divider().overlay(AppColor.borderSubtle)
            HStack {
                Text("Total")
                    .appTextStyle(AppTextStyle.headline)
                Spacer()
                Text(AppFormat.pesoPrecise(total))
                    .appTextStyle(AppTextStyle.title2, color: AppColor.coral)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private func summaryRow(label: String, value: String, valueColor: Color = AppColor.textPrimary) -> some View {
        HStack {
            Text(label)
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
            Spacer()
            Text(value)
                .appTextStyle(AppTextStyle.bodyEmphasis, color: valueColor)
        }
    }

    private var confirmBar: some View {
        VStack(spacing: AppSpacing.xs) {
            PrimaryButton(
                title: paymentSelection == .cashOnDelivery
                    ? "Place Order · \(AppFormat.peso(total))"
                    : "Pay \(AppFormat.peso(total)) with Wallet",
                systemImage: "checkmark",
                isLoading: isPlacingOrder,
                isEnabled: canConfirm,
                action: confirmOrder
            )
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty & success states

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: kind == .food ? "takeoutbag.and.cup.and.straw.fill" : "bag.fill")
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(AppColor.textTertiary.opacity(0.6))
            Text("Your \(kind == .food ? "food" : "shop") cart is empty")
                .appTextStyle(AppTextStyle.title2)
            Text(kind.emptyMessage)
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
            SecondaryButton(title: "Keep Browsing") { dismiss() }
                .frame(maxWidth: 240)
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.xl)
    }

    private func successState(_ summary: PlacedOrderSummary) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.success.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColor.success)
            }

            Text("Order Confirmed!")
                .appTextStyle(AppTextStyle.title)

            Text("\(summary.itemCount) item\(summary.itemCount == 1 ? "" : "s") · \(AppFormat.pesoPrecise(summary.total))")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)

            Text(summary.method == .cashOnDelivery
                 ? "Pay \(AppFormat.pesoPrecise(summary.total)) in cash when your order arrives."
                 : "Paid from your OneMart Wallet. New balance \(AppFormat.pesoPrecise(appState.walletBalance)).")
                .appTextStyle(AppTextStyle.footnote, color: AppColor.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            PrimaryButton(title: "Done") { dismiss() }
                .padding(.top, AppSpacing.md)
                .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.lg)
    }

    // MARK: - Checkout

    private func confirmOrder() {
        guard !items.isEmpty else { return }
        errorMessage = nil

        let summary = PlacedOrderSummary(
            total: total,
            itemCount: appState.count(in: kind),
            method: paymentSelection
        )

        if paymentSelection == .oneMartWallet {
            let paid = appState.payFromWallet(
                amount: total,
                title: kind == .food ? "Food order" : "Shop order",
                subtitle: "\(summary.itemCount) item\(summary.itemCount == 1 ? "" : "s") · OneMart Wallet",
                module: kind.module
            )
            guard paid else {
                errorMessage = "Not enough wallet balance — you're \(AppFormat.pesoPrecise(appState.shortfall(for: total))) short. Top up or switch to Cash on Delivery."
                return
            }
        }

        // Record it before clearing, so the receipt lines can be built from the
        // items that were actually bought.
        appState.recordOrder(
            Order(
                module: kind.module,
                title: items.first?.subtitle ?? (kind == .food ? "Food order" : "Shop order"),
                subtitle: orderSubtitle,
                imageName: items.first?.imageName ?? (kind == .food ? "fork.knife" : "bag.fill"),
                status: kind == .food ? .preparing : .placed,
                total: total,
                placedAt: Date()
            )
        )

        appState.clearCart(kind)
        placedOrder = summary
    }

    /// "Chicken Inasal Paa × 2" for a single line, "3 items · Cash on Delivery"
    /// once the order spans several.
    private var orderSubtitle: String {
        if items.count == 1, let only = items.first {
            return "\(only.name) × \(only.quantity)"
        }
        let count = appState.count(in: kind)
        return "\(count) item\(count == 1 ? "" : "s") · \(paymentSelection.rawValue)"
    }
}

// MARK: - Line row

/// A single cart line: thumbnail glyph, name/subtitle, price, a quantity
/// stepper (whose "minus" becomes a trash glyph at quantity 1), and an explicit
/// remove button.
private struct CartLineRow: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Real photo swap point: replace with the dish/product's real photo once available.
            Image(systemName: item.imageName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(item.module.tintColor)
                .frame(width: 52, height: 52)
                .background(item.module.tintColor.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .appTextStyle(AppTextStyle.bodyEmphasis)
                    .lineLimit(2)
                Text(item.subtitle)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .lineLimit(1)
                Text(AppFormat.pesoPrecise(item.lineTotal))
                    .appTextStyle(AppTextStyle.subheadline, color: AppColor.coral)
            }

            Spacer(minLength: 0)

            VStack(spacing: AppSpacing.xs) {
                stepper
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(item.name)")
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private var stepper: some View {
        HStack(spacing: AppSpacing.xs) {
            stepperButton(icon: item.quantity > 1 ? "minus" : "trash", action: onDecrement)
            Text("\(item.quantity)")
                .appTextStyle(AppTextStyle.subheadline)
                .frame(minWidth: 18)
                .contentTransition(.identity)
            stepperButton(icon: "plus", action: onIncrement)
        }
        .padding(.horizontal, AppSpacing.xxs)
        .padding(.vertical, AppSpacing.xxs)
        .background(AppColor.backgroundTertiary, in: Capsule())
    }

    private func stepperButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.onAccent)
                .frame(width: 24, height: 24)
                .background(AppColor.coral, in: Circle())
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    CartView(kind: .food)
        .environmentObject(AppState.previewSignedIn)
}
