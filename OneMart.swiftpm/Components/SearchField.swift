import SwiftUI

/// The one search input used by Food, Shop, and Community.
///
/// It is a **real** `TextField` bound to the caller's state, not a decorative
/// bar: every screen that shows it filters its list from the same binding as
/// the user types. The clear button appears only when there is something to
/// clear.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var tint: Color = AppColor.coral

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isFocused ? tint : AppColor.textTertiary)

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(AppTextStyle.callout)
                .foregroundStyle(AppColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .frame(height: 44)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(isFocused ? tint : AppColor.borderSubtle, lineWidth: isFocused ? 1.6 : 1)
        )
        .animation(AppMotion.easeStandard, value: isFocused)
        .animation(AppMotion.easeStandard, value: text.isEmpty)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        SearchField(placeholder: "Search restaurants…", text: .constant(""))
        SearchField(placeholder: "Search listings…", text: .constant("guitar"), tint: AppColor.jade)
    }
    .padding(AppSpacing.md)
    .background(AppColor.backgroundPrimary)
}
