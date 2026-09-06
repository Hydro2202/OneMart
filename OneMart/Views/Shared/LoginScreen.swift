import SwiftUI

/// Email + password sign-in.
///
/// Only the demo credentials succeed (`AppState.logIn` owns that rule), so a
/// failed attempt shows a real inline error rather than pretending to work.
/// The social buttons and "Forgot password?" are intentionally visual-only —
/// there is no backend behind this prototype.
struct LoginScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var email = ""
    @State private var password = ""
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var authError: String?
    @State private var isSigningIn = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                header

                VStack(spacing: AppSpacing.md) {
                    if let authError {
                        InlineBanner(kind: .error, message: authError)
                            .transition(.opacity)
                    }

                    AppTextField(
                        label: "Email",
                        placeholder: "you@email.com",
                        text: $email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never,
                        error: emailError
                    )
                    .onChange(of: email) { _ in clearErrors() }

                    AppTextField(
                        label: "Password",
                        placeholder: "••••••••",
                        text: $password,
                        icon: "lock.fill",
                        isSecure: true,
                        textContentType: .password,
                        autocapitalization: .never,
                        error: passwordError,
                        onSubmit: attemptLogin
                    )
                    .onChange(of: password) { _ in clearErrors() }

                    HStack {
                        Spacer()
                        Button("Forgot password?") {}
                            .font(AppTextStyle.subheadline)
                            .foregroundStyle(AppColor.coral)
                    }

                    PrimaryButton(
                        title: isSigningIn ? "Signing in…" : "Log In",
                        systemImage: "arrow.right",
                        isLoading: isSigningIn,
                        action: attemptLogin
                    )

                    divider

                    socialButtons

                    InlineBanner(kind: .info, message: "Demo account — user@gmail.com / password123")

                    signUpLink
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: authError)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Image("OneMartLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 210)
                .padding(.top, AppSpacing.lg)

            Text("Sign in to your account")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AppSpacing.md)
        .background(
            LinearGradient(
                colors: [AppColor.coral.opacity(0.12), AppColor.backgroundPrimary.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var divider: some View {
        HStack(spacing: AppSpacing.sm) {
            Rectangle()
                .fill(AppColor.borderSubtle)
                .frame(height: 1)
            Text("or continue with")
                .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                .fixedSize()
            Rectangle()
                .fill(AppColor.borderSubtle)
                .frame(height: 1)
        }
    }

    private var socialButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            socialButton(title: "Google", icon: "g.circle.fill")
            socialButton(title: "Facebook", icon: "f.circle.fill")
        }
    }

    private func socialButton(title: String, icon: String) -> some View {
        Button {
            // Visual only — no OAuth in the prototype.
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(AppTextStyle.subheadline)
            }
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColor.borderSubtle, lineWidth: 1.5)
            )
        }
        .buttonStyle(.pressable)
    }

    private var signUpLink: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("Don't have an account?")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
            Button("Sign Up") {
                withAnimation(AppMotion.easeStandard) {
                    appState.phase = .signup
                }
            }
            .font(AppTextStyle.subheadline)
            .foregroundStyle(AppColor.coral)
        }
        .padding(.top, AppSpacing.xxs)
    }

    // MARK: - Actions

    private func clearErrors() {
        guard authError != nil || emailError != nil || passwordError != nil else { return }
        authError = nil
        emailError = nil
        passwordError = nil
    }

    private func attemptLogin() {
        emailError = nil
        passwordError = nil
        authError = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            emailError = "Email is required"
        } else if !AppState.isPlausibleEmail(trimmedEmail) {
            emailError = "Enter a valid email address"
        }
        if password.isEmpty {
            passwordError = "Password is required"
        }
        guard emailError == nil, passwordError == nil else { return }

        isSigningIn = true
        Task { @MainActor in
            // Brief pause so the button's loading state is legible.
            try? await Task.sleep(nanoseconds: 600_000_000)
            let succeeded = appState.logIn(email: trimmedEmail, password: password)
            isSigningIn = false
            if !succeeded {
                authError = "Invalid email or password. Try user@gmail.com / password123"
            }
        }
    }
}

#Preview {
    LoginScreen()
        .environmentObject(AppState())
}
