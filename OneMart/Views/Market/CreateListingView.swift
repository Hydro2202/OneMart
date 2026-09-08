import SwiftUI

/// The Sell flow, presented as a **`.fullScreenCover`** from the Community
/// tab's floating button.
///
/// It used to be a short, non-expandable sheet you couldn't comfortably type
/// in; it now owns the whole screen, keyboard and all. Posting builds a real
/// `MarketplaceListing` and hands it to `AppState.postListing(_:)`, which
/// prepends it to the Community board — the new listing is visible the moment
/// the cover dismisses.
struct CreateListingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priceText = ""
    @State private var isFree = false
    @State private var category: ListingCategory = .electronics
    @State private var condition: ListingCondition = .likeNew
    @State private var locationName = "Pasig City"
    @State private var descriptionText = ""
    @State private var isDeliveryAvailable = true
    @State private var didPost = false

    /// Categories a seller can actually choose (`.all` is a filter, not a home
    /// for a listing).
    private var selectableCategories: [ListingCategory] {
        ListingCategory.allCases.filter { $0 != .all }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var price: Double {
        guard !isFree else { return 0 }
        let digits = priceText.filter { $0.isNumber || $0 == "." }
        return Double(digits) ?? 0
    }

    private var canPost: Bool {
        trimmedTitle.count >= 3 && (isFree || price > 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.backgroundPrimary.ignoresSafeArea()

                if didPost {
                    successState
                } else {
                    form
                }
            }
            .navigationTitle(didPost ? "Listing Posted" : "Create Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                photoPlaceholder

                AppTextField(
                    label: "Title",
                    placeholder: "e.g. iPhone 13 Pro, 256GB, Graphite",
                    text: $title,
                    icon: "tag.fill",
                    autocapitalization: .sentences
                )

                priceSection
                chipSection(
                    title: "Category",
                    options: selectableCategories.indices.map { index in
                        let candidate = selectableCategories[index]
                        return ChipOption(
                            index: index,
                            title: candidate.rawValue,
                            icon: candidate.icon,
                            isSelected: candidate == category
                        )
                    }
                ) { index in
                    category = selectableCategories[index]
                }

                chipSection(
                    title: "Condition",
                    options: ListingCondition.allCases.indices.map { index in
                        let candidate = ListingCondition.allCases[index]
                        return ChipOption(
                            index: index,
                            title: candidate.rawValue,
                            isSelected: candidate == condition
                        )
                    }
                ) { index in
                    condition = ListingCondition.allCases[index]
                }

                AppTextField(
                    label: "Location",
                    placeholder: "City or barangay",
                    text: $locationName,
                    icon: "mappin.and.ellipse",
                    autocapitalization: .words
                )

                descriptionSection

                Toggle(isOn: $isDeliveryAvailable) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offer delivery")
                            .appTextStyle(AppTextStyle.bodyEmphasis)
                        Text("Buyers can book a OneMart Send rider instead of meeting up.")
                            .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    }
                }
                .tint(AppColor.jade)
                .padding(AppSpacing.sm)
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))

                if !canPost {
                    InlineBanner(
                        kind: .info,
                        message: "Add a title of at least 3 characters and a price (or mark it free) to post."
                    )
                }

                PrimaryButton(
                    title: "Post Listing",
                    systemImage: "paperplane.fill",
                    tint: AppColor.jade,
                    isEnabled: canPost,
                    action: post
                )
            }
            .padding(AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // Real photo picker goes here: replace this placeholder with a PhotosPicker
    // (see EditProfileView.swift for the pattern) once sellers can attach real photos.
    private var photoPlaceholder: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(AppColor.jade)
            Text("Tap to add photos")
                .appTextStyle(AppTextStyle.subheadline, color: AppColor.textSecondary)
            Text("Up to 8 photos · the first one is your cover")
                .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .background(AppColor.jade.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColor.jade.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        )
        .accessibilityLabel("Add photos. Photo picking is not wired up in this prototype.")
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            AppTextField(
                label: "Price (₱)",
                placeholder: isFree ? "Free" : "e.g. 15000",
                text: $priceText,
                icon: "banknote.fill",
                keyboardType: .numberPad
            )
            .disabled(isFree)
            .opacity(isFree ? 0.5 : 1)

            Toggle(isOn: $isFree.animation(AppMotion.easeStandard)) {
                Text("Give it away for free")
                    .appTextStyle(AppTextStyle.callout)
            }
            .tint(AppColor.jade)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("DESCRIPTION")
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .tracking(0.8)

            TextEditor(text: $descriptionText)
                .font(AppTextStyle.body)
                .foregroundStyle(AppColor.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(AppSpacing.xs)
                .frame(height: 108)
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColor.borderSubtle, lineWidth: 1.5)
                )
                .overlay(alignment: .topLeading) {
                    if descriptionText.isEmpty {
                        Text("Condition, specs, and why you're selling…")
                            .appTextStyle(AppTextStyle.body, color: AppColor.textTertiary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.sm)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    /// One selectable chip in a `chipSection`.
    private struct ChipOption: Identifiable {
        let index: Int
        let title: String
        var icon: String?
        let isSelected: Bool

        var id: Int { index }
    }

    /// A labelled, horizontally scrolling row of selectable chips. The closure
    /// receives the tapped option's index in its source collection.
    private func chipSection(
        title: String,
        options: [ChipOption],
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(title.uppercased())
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .tracking(0.8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(options) { option in
                        FilterChip(
                            title: option.title,
                            icon: option.icon,
                            isSelected: option.isSelected,
                            tint: AppColor.jade
                        ) {
                            onSelect(option.index)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Success

    private var successState: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.jade.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColor.jade)
            }

            Text("Listing posted!")
                .appTextStyle(AppTextStyle.title)

            Text("\"\(trimmedTitle)\" is now visible to buyers near \(locationName).")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            HStack(alignment: .top, spacing: AppSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.jade)
                Text("Payments are escrow-protected — buyers pay through OneMart and funds are released once the hand-off is confirmed.")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.jade)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.sm)
            .background(AppColor.jade.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.md))
            .padding(.horizontal, AppSpacing.md)

            PrimaryButton(title: "Done", tint: AppColor.jade) { dismiss() }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Post

    private func post() {
        guard canPost else { return }

        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let seller = appState.currentUser

        let listing = MarketplaceListing(
            title: trimmedTitle,
            imageName: category.icon,
            price: price,
            isFree: isFree,
            condition: condition,
            category: category,
            locationName: locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            distanceKm: 0,
            postedAt: Date(),
            sellerName: seller?.name ?? "You",
            sellerPhotoName: seller?.photoName ?? "person.crop.circle.fill",
            sellerRating: 5.0,
            sellerListingsCount: 1,
            description: trimmedDescription.isEmpty
                ? "Posted from OneMart. Message me for more details."
                : trimmedDescription,
            isDeliveryAvailable: isDeliveryAvailable
        )

        appState.postListing(listing)

        withAnimation(AppMotion.springBouncy) {
            didPost = true
        }
    }
}

#Preview {
    CreateListingView()
        .environmentObject(AppState.previewSignedIn)
}
