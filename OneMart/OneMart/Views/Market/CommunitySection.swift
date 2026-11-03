import SwiftUI
import UIKit

/// The **Community** half of the Market tab — the neighbour-to-neighbour board.
///
/// Two things that were missing before live here: a search field that really
/// filters listings by title on every keystroke (via
/// `AppState.listings(in:matching:)`), and cards that actually open a full
/// `ListingDetailView` when tapped. Listings come from `AppState`, not straight
/// from MockData, so anything posted through the Sell flow shows up at the top
/// immediately.
struct CommunitySection: View {
    @Binding var searchText: String
    @Binding var category: ListingCategory

    @EnvironmentObject private var appState: AppState

    private var listings: [MarketplaceListing] {
        appState.listings(in: category, matching: searchText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SearchField(placeholder: "Search nearby listings…", text: $searchText, tint: AppColor.jade)
                .padding(.horizontal, AppSpacing.md)

            FilterChipRow(
                categories: ListingCategory.allCases,
                selection: $category,
                title: { $0.rawValue },
                icon: { $0.icon },
                tint: AppColor.jade
            )

            SectionHeader(
                title: "Near you",
                subtitle: listings.isEmpty ? nil : "\(listings.count) listing\(listings.count == 1 ? "" : "s") within 20 km"
            )
            .padding(.horizontal, AppSpacing.md)

            if listings.isEmpty {
                EmptyResultsView(
                    icon: "magnifyingglass",
                    title: "No listings found",
                    message: searchText.isEmpty
                        ? "Nothing in \(category.rawValue) near you yet. Try another category — or post the first one."
                        : "Nothing matched \"\(searchText)\". Try a shorter search."
                )
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.sm),
                        GridItem(.flexible(), spacing: AppSpacing.sm)
                    ],
                    spacing: AppSpacing.sm
                ) {
                    ForEach(listings) { listing in
                        NavigationLink(value: MarketRoute.listing(listing)) {
                            ListingCard(listing: listing)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}

// MARK: - Listing card

/// Grid cell for a community listing. Tapping it pushes the detail page; the
/// heart is the only nested control.
struct ListingCard: View {
    let listing: MarketplaceListing

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFavorite: Bool { appState.isFavoriteListing(listing.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            ZStack(alignment: .topTrailing) {
                if let data = listing.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 104)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .clipped()
                } else if let assetName = listing.photoAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 104)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [AppColor.jade.opacity(0.20), AppColor.jade.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    .overlay(
                        // Real photo swap point: a seller's own upload (above) covers
                        // this for new listings; these mock ones never got a real photo.
                        Image(systemName: listing.imageName)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppColor.jade)
                    )
                }

                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                        appState.toggleFavoriteListing(listing.id)
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
                .padding(AppSpacing.xxs)
                .accessibilityLabel(isFavorite ? "Remove \(listing.title) from favorites" : "Add \(listing.title) to favorites")
            }

            Text(listing.isFree ? "Free" : AppFormat.peso(listing.price))
                .appTextStyle(AppTextStyle.subheadline, color: AppColor.jade)

            Text(listing.title)
                .appTextStyle(AppTextStyle.footnote)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .topLeading)

            TagPill(text: listing.condition.rawValue, tint: AppColor.amber)

            Text(String(format: "%.1f km · %@", listing.distanceKm, AppFormat.relative(listing.postedAt)))
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .lineLimit(1)
        }
        .padding(AppSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            CommunitySection(searchText: .constant(""), category: .constant(.all))
        }
        .background(AppColor.backgroundPrimary)
    }
    .environmentObject(AppState.previewSignedIn)
}
