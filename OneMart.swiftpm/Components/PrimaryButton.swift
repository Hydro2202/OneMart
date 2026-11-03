import SwiftUI

/// Full-width brand CTA. Used for Log In, Create Account, Confirm Top-Up,
/// Place Order — anywhere the screen has one obvious next action.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = AppColor.coral
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppColor.onAccent)
                }
                Text(title)
                    .font(AppTextStyle.buttonLabel)
                if let systemImage, !isLoading {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundStyle(AppColor.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(tint.opacity(isEnabled ? 1 : 0.45), in: RoundedRectangle(cornerRadius: AppRadius.md))
            .shadow(color: tint.opacity(isEnabled ? 0.32 : 0), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled || isLoading)
    }
}

/// Quieter secondary action that sits next to a `PrimaryButton`.
struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(AppTextStyle.buttonLabel)
            }
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColor.borderSubtle, lineWidth: 1.5)
            )
        }
        .buttonStyle(.pressable)
    }
}

/// Inline error/warning banner shared by the auth screens and checkout.
struct InlineBanner: View {
    enum Kind {
        case error
        case info
        case success

        var tint: Color {
            switch self {
            case .error: return AppColor.error
            case .info: return AppColor.jade
            case .success: return AppColor.success
            }
        }

        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "lightbulb.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }

    let kind: Kind
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Image(systemName: kind.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(kind.tint)
            Text(message)
                .appTextStyle(AppTextStyle.footnote, color: kind.tint)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(kind.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .stroke(kind.tint.opacity(0.28), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        PrimaryButton(title: "Log In", systemImage: "arrow.right") {}
        PrimaryButton(title: "Signing in…", isLoading: true) {}
        SecondaryButton(title: "Cancel") {}
        InlineBanner(kind: .error, message: "Invalid email or password.")
        InlineBanner(kind: .info, message: "Demo: user@gmail.com / password123")
    }
    .padding(AppSpacing.md)
    .background(AppColor.backgroundPrimary)
}
