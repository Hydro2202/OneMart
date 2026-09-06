import SwiftUI

/// Full page for a community listing — the fix for "tapping a listing did
/// nothing".
///
/// Shows the image, the price (or "Free"), the condition badge, the full
/// description, distance and posted time, and the seller with their rating and
/// listing count. **Message Seller** goes through `AppState.openThread(for:)`,
/// which either reuses the existing conversation for this listing or starts a
/// real one seeded with the buyer's opening question — so the thread also
/// appears in the Messages list behind the header icon.
struct ListingDetailView: View {
    let listing: MarketplaceListing

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var openedThread: ThreadRoute?

    private var isFavorite: Bool { appState.isFavoriteListing(listing.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                imageArea
                titleBlock
                descriptionBlock
                sellerCard
                safetyNote
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Listing Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                        appState.toggleFavoriteListing(listing.id)
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
            actionBar
        }
        .sheet(item: $openedThread) { route in
            NavigationStack {
                MessageThreadView(threadID: route.id)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { openedThread = nil }
                                .font(AppTextStyle.subheadline)
                                .foregroundStyle(AppColor.coral)
                        }
                    }
            }
        }
    }

    // MARK: - Image

    private var imageArea: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppColor.jade.opacity(0.24), AppColor.jade.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 240)

            Image(systemName: listing.imageName)
                .font(.system(size: 88, weight: .semibold))
                .foregroundStyle(AppColor.jade)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: AppSpacing.xxs) {
                TagPill(text: listing.condition.rawValue, tint: AppColor.amber, isFilled: true)
                TagPill(text: listing.category.rawValue, icon: listing.category.icon, tint: AppColor.jade, isFilled: true)
            }
            .padding(AppSpacing.md)
        }
        .frame(height: 240)
        .clipped()
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(listing.isFree ? "Free" : AppFormat.peso(listing.price))
                .font(AppTextStyle.largeTitle)
                .foregroundStyle(AppColor.jade)

            Text(listing.title)
                .appTextStyle(AppTextStyle.title2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.sm) {
                Label(String(format: "%.1f km away", listing.distanceKm), systemImage: "mappin.and.ellipse")
                    .font(AppTextStyle.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Label(AppFormat.relative(listing.postedAt), systemImage: "clock")
                    .font(AppTextStyle.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: 0)
            }

            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
                Text(listing.locationName)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)

                if listing.isDeliveryAvailable {
                    TagPill(text: "Delivery available", icon: "bicycle", tint: AppColor.jade)
                } else {
                    TagPill(text: "Meet-up / pick-up only", icon: "figure.walk", tint: AppColor.textTertiary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Description")
            Text(listing.description)
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Seller

    private var sellerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Seller")

            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppColor.jade.opacity(0.16))
                        .frame(width: 52, height: 52)
                    Image(systemName: listing.sellerPhotoName)
                        .font(.system(size: 30))
                        .foregroundStyle(AppColor.jade)
                }
                .overlay(Circle().stroke(AppColor.jade, lineWidth: 2))

                VStack(alignment: .leading, spacing: 3) {
                    Text(listing.sellerName)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                    RatingLabel(rating: listing.sellerRating)
                    Text("\(listing.sellerListingsCount) listing\(listing.sellerListingsCount == 1 ? "" : "s") · \(listing.locationName)")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                TagPill(text: "Verified", icon: "checkmark.seal.fill", tint: AppColor.jade)
            }
            .padding(AppSpacing.sm)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(.subtle)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.jade)
            VStack(alignment: .leading, spacing: 2) {
                Text("Meet safely, pay safely")
                    .appTextStyle(AppTextStyle.subheadline, color: AppColor.jade)
                Text("Agree on a public meet-up spot, or pay through OneMart so the money is held in escrow until the item is in your hands.")
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

    // MARK: - Actions

    private var actionBar: some View {
        VStack(spacing: AppSpacing.xs) {
            PrimaryButton(
                title: hasExistingThread ? "Open Conversation" : "Message Seller",
                systemImage: "bubble.left.fill",
                tint: AppColor.jade,
                action: messageSeller
            )

            if listing.isDeliveryAvailable {
                SecondaryButton(title: "Arrange OneMart Delivery", systemImage: "shippingbox.fill") {
                    appState.activeTab = .logistics
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
        .padding(.bottom, AppSpacing.xs)
        .background(.ultraThinMaterial)
    }

    private var hasExistingThread: Bool {
        appState.messageThreads.contains { $0.listingID == listing.id }
    }

    private func messageSeller() {
        // `openThread(for:)` reuses the existing conversation when there is one,
        // so tapping twice never creates a duplicate thread.
        let threadID = appState.openThread(for: listing)
        openedThread = ThreadRoute(id: threadID)
    }
}

#Preview {
    NavigationStack {
        ListingDetailView(listing: MockListings.all[0])
    }
    .environmentObject(AppState.previewSignedIn)
}
