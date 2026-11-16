import SwiftUI

/// Tracking detail for a single Food, Rides, or Shop order — the fix for the
/// active-order strip saying "Tap to track" but only switching tabs.
///
/// Shows the order (module, title, items/route, total) and a vertical status
/// timeline: Placed → Preparing → On the Way → Completed, worded per module so
/// a ride reads "Finding your driver" rather than "Preparing". A cancelled
/// order gets its own terminal state instead of a timeline.
///
/// Presented as a sheet (it wraps itself in a `NavigationStack` with a "Done"
/// button), from `ActiveOrderBar` and from each tab's `ActiveOrderBanner`.
struct OrderTrackingSheet: View {
    let order: Order

    @Environment(\.dismiss) private var dismiss

    private var tint: Color { order.module.tintColor }

    /// The normal progression — `.cancelled` is a terminal state, not a step.
    private var steps: [OrderStatus] {
        OrderStatus.allCases.filter { $0 != .cancelled }
    }

    private var currentIndex: Int {
        steps.firstIndex(of: order.status) ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    headerCard

                    if order.status == .cancelled {
                        cancelledCard
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            SectionHeader(title: "Order status", subtitle: statusSummary)
                            timeline
                        }
                    }
                }
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Track \(order.module.shortName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTextStyle.subheadline)
                        .foregroundStyle(AppColor.coral)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(tint.opacity(0.16))
                        .frame(width: 52, height: 52)
                    Image(systemName: order.imageName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    TagPill(text: order.module.displayName, icon: order.module.icon, tint: tint)
                    Text(order.title)
                        .appTextStyle(AppTextStyle.headline)
                        .lineLimit(2)
                    Text(order.subtitle)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(AppColor.borderSubtle)
                .frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Placed")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                    Text(AppFormat.orderTimestamp(order.placedAt))
                        .appTextStyle(AppTextStyle.footnote, color: AppColor.textSecondary)
                }

                Spacer(minLength: AppSpacing.xs)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                    Text(AppFormat.peso(order.total))
                        .font(AppTextStyle.title2)
                        .foregroundStyle(tint)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    // MARK: - Timeline

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                timelineRow(step: step, index: index)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private func timelineRow(step: OrderStatus, index: Int) -> some View {
        let isReached = index <= currentIndex
        let isCurrent = index == currentIndex && order.status != .completed
        let isLast = index == steps.count - 1
        let nextReached = index + 1 <= currentIndex

        return HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isReached ? tint : AppColor.backgroundTertiary)
                        .frame(width: 26, height: 26)
                    Circle()
                        .stroke(isReached ? tint : AppColor.borderSubtle, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    Image(systemName: isReached && !isCurrent ? "checkmark" : stepIcon(step))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isReached ? AppColor.onAccent : AppColor.textTertiary)
                }

                if !isLast {
                    Rectangle()
                        .fill(nextReached ? tint : AppColor.borderSubtle)
                        .frame(width: 2, height: 34)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(stepTitle(step))
                        .appTextStyle(
                            AppTextStyle.bodyEmphasis,
                            color: isReached ? AppColor.textPrimary : AppColor.textTertiary
                        )
                    if isCurrent {
                        TagPill(text: "Now", tint: tint)
                    }
                }
                Text(stepDetail(step))
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 3)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stepTitle(step)), \(isCurrent ? "current step" : (isReached ? "done" : "pending"))")
    }

    // MARK: - Cancelled

    private var cancelledCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.error)
            VStack(alignment: .leading, spacing: 2) {
                Text("Order cancelled")
                    .appTextStyle(AppTextStyle.headline, color: AppColor.error)
                Text("This order was cancelled and won't be fulfilled. Any wallet payment is refunded to your OneMart Wallet.")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(AppColor.error.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColor.error.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Per-module wording

    private var statusSummary: String {
        order.status == .completed ? "All done" : "Currently: \(stepTitle(order.status))"
    }

    private func stepIcon(_ step: OrderStatus) -> String {
        switch step {
        case .placed: return "doc.text.fill"
        case .preparing: return order.module == .rides ? "magnifyingglass" : "clock.fill"
        case .onTheWay: return order.module.icon
        case .completed: return "flag.fill"
        case .cancelled: return "xmark"
        }
    }

    private func stepTitle(_ step: OrderStatus) -> String {
        switch (order.module, step) {
        case (.rides, .placed): return "Ride booked"
        case (.rides, .preparing): return "Finding your driver"
        case (.rides, .onTheWay): return "On the way"
        case (.rides, .completed): return "Arrived"
        case (.food, .preparing): return "Preparing your food"
        case (.food, .onTheWay): return "Rider on the way"
        case (_, .placed): return "Order placed"
        case (_, .preparing): return "Packing your order"
        case (_, .onTheWay): return "Out for delivery"
        case (_, .completed): return "Delivered"
        case (_, .cancelled): return "Cancelled"
        }
    }

    private func stepDetail(_ step: OrderStatus) -> String {
        switch (order.module, step) {
        case (.rides, .placed): return "Your booking is confirmed."
        case (.rides, .preparing): return "Matching you with a nearby driver."
        case (.rides, .onTheWay): return "Your driver is heading to you."
        case (.rides, .completed): return "You've reached your destination."
        case (.food, .placed): return "The restaurant received your order."
        case (.food, .preparing): return "The kitchen is cooking your order."
        case (.food, .onTheWay): return "Your rider picked up the food."
        case (.food, .completed): return "Enjoy your meal!"
        case (_, .placed): return "The store received your order."
        case (_, .preparing): return "Your items are being packed."
        case (_, .onTheWay): return "Your package is on its way to you."
        case (_, .completed): return "Your order has arrived."
        case (_, .cancelled): return "This order was cancelled."
        }
    }
}

/// Tappable rows a tab shows near its top while that module has in-progress
/// orders — one row per active order (e.g. two Food orders from two
/// different restaurants show as two rows), each opening `OrderTrackingSheet`
/// for that specific order. Renders nothing when the module has no active
/// order.
struct ActiveOrderBanner: View {
    let module: ServiceModule
    /// Outer padding lives inside the banner so a module with no active order
    /// leaves no stray gap in the host screen's layout.
    var horizontalPadding: CGFloat = AppSpacing.md
    var bottomPadding: CGFloat = 0

    @EnvironmentObject private var appState: AppState
    @State private var trackingOrder: Order?

    /// Every active order for this module, newest first.
    private var orders: [Order] {
        appState.activeOrders.filter { $0.module == module }
    }

    var body: some View {
        if !orders.isEmpty {
            VStack(spacing: AppSpacing.xs) {
                ForEach(orders) { order in
                    row(for: order)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, bottomPadding)
            .animation(AppMotion.easeStandard, value: orders.map(\.id))
            .sheet(item: $trackingOrder) { tracked in
                OrderTrackingSheet(order: tracked)
            }
        }
    }

    private func row(for order: Order) -> some View {
        Button {
            trackingOrder = order
        } label: {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(module.tintColor.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: order.imageName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(module.tintColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(order.status.rawValue)
                        .font(AppFont.rounded(12, weight: .bold))
                        .foregroundStyle(module.tintColor)
                    Text(order.title)
                        .appTextStyle(AppTextStyle.footnote)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.xs)

                Text("Track")
                    .font(AppTextStyle.badge)
                    .foregroundStyle(module.tintColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(module.tintColor.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(module.tintColor.opacity(0.25), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(module.shortName) order \(order.status.rawValue.lowercased()): \(order.title). Tap to track.")
    }
}

#Preview {
    OrderTrackingSheet(order: MockOrders.all[0])
        .environmentObject(AppState.previewSignedIn)
}
