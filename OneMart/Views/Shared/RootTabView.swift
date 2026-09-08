import SwiftUI

/// The five-tab shell of the signed-in app.
///
/// A custom tab bar rather than `TabView`, for two reasons the brief calls out:
/// the sliding active-indicator animation, and cart badges that read straight
/// from `AppState`. Profile is a full-screen cover over the whole shell — it is
/// not a tab — matching the prototype's `showProfile` overlay.
struct RootTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.backgroundPrimary.ignoresSafeArea()

            tabContent
                .padding(.bottom, AppTabBar.height + (appState.activeOrders.isEmpty ? 0 : ActiveOrderBar.height))

            VStack(spacing: 0) {
                ActiveOrderBar()
                AppTabBar()
            }
        }
        .fullScreenCover(isPresented: $appState.showProfile) {
            ProfileScreen()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appState.activeTab {
        case .home:
            NavigationStack { HomeScreen() }
        case .food:
            NavigationStack { FoodScreen() }
        case .rides:
            NavigationStack { RidesScreen() }
        case .logistics:
            NavigationStack { LogisticsScreen() }
        case .market:
            NavigationStack { MarketScreen() }
        }
    }
}

/// Custom tab bar with a spring-animated sliding indicator and live cart badges.
struct AppTabBar: View {
    static let height: CGFloat = 64

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tabs: [AppTab] { AppTab.allCases }

    private var activeIndex: Int {
        tabs.firstIndex(of: appState.activeTab) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            indicator
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    tabButton(tab)
                }
            }
            .frame(height: AppTabBar.height - 3)
        }
        .background(
            AppColor.backgroundSecondary
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.borderSubtle)
                .frame(height: 1)
        }
        .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: appState.activeTab)
    }

    private var indicator: some View {
        GeometryReader { proxy in
            let itemWidth = proxy.size.width / CGFloat(tabs.count)
            let indicatorWidth = itemWidth * 0.42
            Capsule()
                .fill(AppColor.coral)
                .frame(width: indicatorWidth, height: 3)
                .offset(x: itemWidth * CGFloat(activeIndex) + (itemWidth - indicatorWidth) / 2)
        }
        .frame(height: 3)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isActive = appState.activeTab == tab
        let badge = badgeCount(for: tab)

        return Button {
            guard appState.activeTab != tab else { return }
            appState.activeTab = tab
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isActive ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? AppColor.coral : AppColor.textTertiary)
                        .frame(width: 30, height: 26)
                        .scaleEffect(isActive && !reduceMotion ? 1.08 : 1)

                    if badge > 0 {
                        CountBadge(count: badge)
                            .offset(x: 10, y: -6)
                    }
                }

                Text(tab.label)
                    .font(AppFont.rounded(10, weight: isActive ? .bold : .medium))
                    .foregroundStyle(isActive ? AppColor.coral : AppColor.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    /// Only Food and Market carry cart badges — and only when non-empty.
    private func badgeCount(for tab: AppTab) -> Int {
        switch tab {
        case .food: return appState.foodCartCount
        case .market: return appState.shopCartCount
        default: return 0
        }
    }
}

/// Docked strip that surfaces the most recent in-progress order — food,
/// rides, or a parcel — above the tab bar on **every** tab, not just Home.
/// This is what makes "your order is being prepared / on the way" visible no
/// matter which tab the user wanders off to.
struct ActiveOrderBar: View {
    static let height: CGFloat = 52

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    private var activeOrders: [Order] { appState.activeOrders }

    var body: some View {
        if let order = activeOrders.first {
            Button {
                appState.activeTab = AppTab.tab(for: order.module)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(order.module.tintColor.opacity(0.35))
                            .frame(width: 10, height: 10)
                            .scaleEffect(isPulsing ? 1.8 : 1)
                            .opacity(isPulsing ? 0 : 1)
                            .animation(
                                reduceMotion ? nil : .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                        Circle()
                            .fill(order.module.tintColor)
                            .frame(width: 8, height: 8)
                    }
                    .frame(width: 18)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(order.module.shortName) · \(order.status.rawValue)")
                            .font(AppFont.rounded(12, weight: .bold))
                            .foregroundStyle(order.module.tintColor)
                        Text(order.title)
                            .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AppSpacing.xs)

                    if activeOrders.count > 1 {
                        Text("+\(activeOrders.count - 1) more")
                            .font(AppTextStyle.caption2)
                            .foregroundStyle(AppColor.textTertiary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColor.textTertiary)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: Self.height)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .background(AppColor.backgroundSecondary)
            .overlay(alignment: .top) {
                Rectangle().fill(AppColor.borderSubtle).frame(height: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(order.module.shortName) order \(order.status.rawValue.lowercased()): \(order.title). Tap to track.")
            .onAppear { isPulsing = true }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState.previewSignedIn)
}
