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
                .padding(.bottom, AppTabBar.height)

            AppTabBar()
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

#Preview {
    RootTabView()
        .environmentObject(AppState.previewSignedIn)
}
