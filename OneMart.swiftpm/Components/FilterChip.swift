import SwiftUI

/// A single pill in a horizontal filter row (food categories, shop categories,
/// listing categories, menu sections).
///
/// The tint is a parameter rather than a constant because Shop/Community lead
/// with jade while Food leads with coral — same component, module accent.
struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    var tint: Color = AppColor.coral
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(AppTextStyle.subheadline)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? tint : AppColor.backgroundSecondary, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AppColor.borderSubtle, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Horizontally scrolling row of `FilterChip`s over any `CaseIterable`
/// category enum, so the three category filters in the app stay identical.
struct FilterChipRow<Category: Identifiable & Hashable>: View {
    let categories: [Category]
    @Binding var selection: Category
    let title: (Category) -> String
    var icon: (Category) -> String? = { _ in nil }
    var tint: Color = AppColor.coral

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(categories) { category in
                    FilterChip(
                        title: title(category),
                        icon: icon(category),
                        isSelected: selection == category,
                        tint: tint
                    ) {
                        withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                            selection = category
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xxs)
        }
    }
}

/// Small tinted label — "Promoted", "Best Seller", "Escrow Protected",
/// "Like New", a module name on an activity row.
struct TagPill: View {
    let text: String
    var icon: String?
    var tint: Color = AppColor.coral
    /// Filled pills sit on imagery; tinted pills sit on card surfaces.
    var isFilled: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(AppTextStyle.caption2)
        }
        .foregroundStyle(isFilled ? AppColor.onAccent : tint)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 3)
        .background(isFilled ? tint : tint.opacity(0.15), in: Capsule())
    }
}

/// Star + numeric rating, used on restaurant, product, listing, and driver
/// cards so ratings read the same everywhere.
struct RatingLabel: View {
    let rating: Double
    var count: Int?
    var decimals: Int = 1

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColor.amber)
            Text(String(format: "%.\(decimals)f", rating))
                .appTextStyle(AppTextStyle.caption, color: AppColor.textPrimary)
            if let count {
                Text("(\(AppFormat.compactCount(count)))")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rated \(String(format: "%.1f", rating)) out of 5")
    }
}

/// The section heading used down the length of every tab.
struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appTextStyle(AppTextStyle.headline)
                if let subtitle {
                    Text(subtitle)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Shared "nothing matched your filters" state for the searchable lists.
struct EmptyResultsView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(AppColor.textTertiary.opacity(0.6))
            Text(title)
                .appTextStyle(AppTextStyle.title2)
            Text(message)
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.md)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.md) {
        FilterChipRow(
            categories: FoodCategory.allCases,
            selection: .constant(.filipino),
            title: { $0.rawValue },
            icon: { $0.icon }
        )
        HStack {
            TagPill(text: "Promoted", icon: "megaphone.fill", tint: AppColor.amber)
            TagPill(text: "Escrow Protected", icon: "lock.shield.fill", tint: AppColor.jade)
            TagPill(text: "-42%", tint: AppColor.coral, isFilled: true)
        }
        .padding(.horizontal, AppSpacing.md)
        RatingLabel(rating: 4.8, count: 2412)
            .padding(.horizontal, AppSpacing.md)
        SectionHeader(title: "Recent activity", subtitle: "Across every module")
            .padding(.horizontal, AppSpacing.md)
        EmptyResultsView(icon: "magnifyingglass", title: "No results", message: "Try a different search or category.")
    }
    .background(AppColor.backgroundPrimary)
}
