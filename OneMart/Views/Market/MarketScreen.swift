import SwiftUI

/// Market tab — **Shop** (curated e-commerce with escrow) and **Community**
/// (peer-to-peer listings from neighbours), behind one segmented control.
///
/// The two halves keep their own search text and category filter, held here so
/// switching segments never throws a filter away. Everything a card can open —
/// a product page, a listing page — is a real push on the surrounding
/// `NavigationStack`, routed through `MarketRoute`.
struct MarketScreen: View {
    enum Segment: String, CaseIterable, Identifiable {
        case shop = "Shop"
        case community = "Community"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .shop: return "bag.fill"
            case .community: return "person.2.fill"
            }
        }

        var tint: Color {
            switch self {
            case .shop: return AppColor.coral
            case .community: return AppColor.jade
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var segment: Segment = .shop
    @State private var shopSearch = ""
    @State private var shopCategory: ShopCategory = .all
    @State private var communitySearch = ""
    @State private var communityCategory: ListingCategory = .all
    @State private var showsCreateListing = false

    var body: some View {
        VStack(spacing: 0) {
            AppShellHeader(
                title: "Market",
                subtitle: segment == .shop
                    ? "Official stores, escrow protected"
                    : "Buy and sell with neighbours",
                cart: .shop,
                showsMessages: true
            )

            segmentedControl
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xs)

            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        switch segment {
                        case .shop:
                            ShopSection(searchText: $shopSearch, category: $shopCategory)
                        case .community:
                            CommunitySection(searchText: $communitySearch, category: $communityCategory)
                        }
                    }
                    .padding(.bottom, segment == .community ? 88 : AppSpacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)

                if segment == .community {
                    sellButton
                        .padding(.trailing, AppSpacing.md)
                        .padding(.bottom, AppSpacing.md)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: segment)
        .navigationDestination(for: MarketRoute.self) { route in
            switch route {
            case .product(let product):
                ProductDetailView(product: product)
            case .listing(let listing):
                ListingDetailView(listing: listing)
            }
        }
        // A genuine full-screen presentation, not a cramped detent sheet — the
        // create-listing form needs the whole canvas.
        .fullScreenCover(isPresented: $showsCreateListing) {
            CreateListingView()
        }
    }

    // MARK: - Segmented control

    private var segmentedControl: some View {
        HStack(spacing: AppSpacing.xxs) {
            ForEach(Segment.allCases) { candidate in
                let isSelected = segment == candidate
                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                        segment = candidate
                    }
                } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: candidate.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(candidate.rawValue)
                            .font(AppTextStyle.buttonLabel)
                    }
                    .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        isSelected ? candidate.tint : Color.clear,
                        in: RoundedRectangle(cornerRadius: AppRadius.sm)
                    )
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(AppSpacing.xxs)
        .background(AppColor.backgroundTertiary, in: RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Sell FAB

    private var sellButton: some View {
        Button {
            showsCreateListing = true
        } label: {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                Text("Sell")
                    .font(AppTextStyle.buttonLabel)
            }
            .foregroundStyle(AppColor.onAccent)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 50)
            .background(AppColor.jade, in: Capsule())
            .shadow(color: AppColor.jade.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Sell something — create a new listing")
    }
}

// MARK: - Routing

/// The pushable destinations inside the Market tab.
enum MarketRoute: Hashable {
    case product(Product)
    case listing(MarketplaceListing)
}

/// Wrapper so a message-thread id can drive `.sheet(item:)`.
struct ThreadRoute: Identifiable {
    let id: UUID
}

#Preview {
    NavigationStack {
        MarketScreen()
    }
    .environmentObject(AppState.previewSignedIn)
}
