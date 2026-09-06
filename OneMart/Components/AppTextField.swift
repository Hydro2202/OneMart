import SwiftUI
import UIKit

/// The one text input used by every form in the app (login, sign up, top-up).
///
/// Wraps a `TextField`/`SecureField` in the project's card surface, and handles
/// the uppercase label, leading glyph, secure-entry reveal toggle, and the
/// inline error message + error-tinted border.
struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var error: String?
    var onSubmit: (() -> Void)?

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    private var showsError: Bool { !(error ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label.uppercased())
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .tracking(0.8)

            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: 18)
                }

                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .focused($isFocused)
                .font(AppTextStyle.body)
                .foregroundStyle(AppColor.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isSecure || keyboardType == .emailAddress)
                .submitLabel(onSubmit == nil ? .return : .go)
                .onSubmit { onSubmit?() }

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 52)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(AppMotion.easeStandard, value: showsError)
            .animation(AppMotion.easeStandard, value: isFocused)

            if let error, !error.isEmpty {
                Text(error)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.error)
                    .padding(.leading, AppSpacing.xxs)
                    .transition(.opacity)
            }
        }
    }

    private var borderColor: Color {
        if showsError { return AppColor.error }
        return isFocused ? AppColor.coral : AppColor.borderSubtle
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        AppTextField(
            label: "Email",
            placeholder: "you@email.com",
            text: .constant("maria@gmail.com"),
            icon: "envelope.fill",
            keyboardType: .emailAddress,
            autocapitalization: .never
        )
        AppTextField(
            label: "Password",
            placeholder: "••••••••",
            text: .constant("hunter2"),
            icon: "lock.fill",
            isSecure: true,
            error: "Password must be at least 8 characters"
        )
    }
    .padding(AppSpacing.md)
    .background(AppColor.backgroundPrimary)
}
