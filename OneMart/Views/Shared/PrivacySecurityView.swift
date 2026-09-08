import SwiftUI

/// Real content, not a stub: a working (mocked) change-password form, a 2FA
/// toggle, a login-activity list, and written data-handling copy specific to
/// what OneMart actually does (unified wallet, escrow).
struct PrivacySecurityView: View {
    @State private var isTwoFactorOn = false
    @State private var showsChangePassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                securitySection
                dataSection
                loginActivitySection
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsChangePassword) {
            ChangePasswordView()
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Account Security")

            Button {
                showsChangePassword = true
            } label: {
                settingsRow(icon: "key.fill", tint: AppColor.jade, title: "Change Password", subtitle: "Last changed 3 months ago", showsChevron: true)
            }
            .buttonStyle(.pressable)

            Toggle(isOn: $isTwoFactorOn) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.jade)
                        .frame(width: 38, height: 38)
                        .background(AppColor.jade.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Two-Factor Authentication").appTextStyle(AppTextStyle.bodyEmphasis)
                        Text(isTwoFactorOn
                             ? "Enabled — a code is sent to your phone on new sign-ins"
                             : "Add a second layer of protection to your account")
                            .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tint(AppColor.jade)
            .padding(AppSpacing.sm)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(.subtle)
        }
    }

    // MARK: - Data & privacy

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Your Data")

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                policyRow(
                    icon: "wallet.pass.fill",
                    title: "Wallet & Payments",
                    body: "Your OneMart Wallet balance and transaction history are visible only to you. Cash on Delivery orders never share your card or bank details with riders or merchants."
                )
                Divider().overlay(AppColor.borderSubtle)
                policyRow(
                    icon: "lock.shield.fill",
                    title: "Escrow Protection",
                    body: "Payments for Shop and Community purchases are held by OneMart and only released to the seller once you confirm the item arrived as described."
                )
                Divider().overlay(AppColor.borderSubtle)
                policyRow(
                    icon: "mappin.and.ellipse",
                    title: "Location & Addresses",
                    body: "Saved addresses are used to estimate delivery fees and ETAs across Food, Rides, and Send, and are never shared with other users directly — sellers and drivers only see the address for an order they're fulfilling."
                )
                Divider().overlay(AppColor.borderSubtle)
                policyRow(
                    icon: "person.2.fill",
                    title: "What Sellers & Buyers See",
                    body: "In Community chats, the other party sees your display name and photo, not your phone number or email, unless you choose to share them."
                )
            }
            .padding(AppSpacing.sm)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(.subtle)
        }
    }

    // MARK: - Login activity

    private var loginActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Where You're Signed In")

            VStack(spacing: 0) {
                sessionRow(device: "This iPhone", detail: "Manila, Philippines · Active now", isCurrent: true)
                Divider().overlay(AppColor.borderSubtle)
                sessionRow(device: "iPad Air", detail: "Manila, Philippines · 4 days ago", isCurrent: false)
            }
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(.subtle)
        }
    }

    // MARK: - Rows

    private func settingsRow(icon: String, tint: Color, title: String, subtitle: String, showsChevron: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).appTextStyle(AppTextStyle.bodyEmphasis)
                Text(subtitle)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .contentShape(Rectangle())
    }

    private func policyRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.jade)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).appTextStyle(AppTextStyle.bodyEmphasis)
                Text(body)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sessionRow(device: String, detail: String, isCurrent: Bool) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: device.contains("iPad") ? "ipad" : "iphone")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(device).appTextStyle(AppTextStyle.bodyEmphasis)
                Text(detail).appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
            }

            Spacer(minLength: 0)

            if isCurrent {
                TagPill(text: "This Device", tint: AppColor.jade)
            }
        }
        .padding(AppSpacing.sm)
    }
}

/// Mocked change-password form — validates like a real one (current password
/// required, new password ≥ 8 characters, confirmation must match) but
/// doesn't call any backend.
private struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var didSave = false

    private var canSave: Bool {
        !current.isEmpty && new.count >= 8 && new == confirm
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    AppTextField(label: "Current password", placeholder: "••••••••", text: $current, icon: "lock.fill", isSecure: true)
                    AppTextField(label: "New password", placeholder: "At least 8 characters", text: $new, icon: "lock.fill", isSecure: true)
                    AppTextField(
                        label: "Confirm new password",
                        placeholder: "Re-enter new password",
                        text: $confirm,
                        icon: "lock.fill",
                        isSecure: true,
                        error: !confirm.isEmpty && confirm != new ? "Passwords don't match" : nil
                    )

                    if didSave {
                        InlineBanner(kind: .success, message: "Password updated.")
                    }

                    PrimaryButton(title: "Update Password", systemImage: "checkmark", tint: AppColor.jade, isEnabled: canSave) {
                        withAnimation(AppMotion.easeStandard) { didSave = true }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 700_000_000)
                            dismiss()
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .accessibilityLabel("Cancel")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySecurityView()
    }
    .environmentObject(AppState.previewSignedIn)
}
