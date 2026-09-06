import SwiftUI

/// Ordinary e-commerce style registration (Shopee/Lazada-shaped): name, email,
/// mobile, password + confirmation, and a Terms & Privacy checkbox.
///
/// Validation runs client-side with per-field inline errors; on success
/// `AppState.signUp` creates the profile and drops the user straight into the
/// app, after a short "Account Created!" confirmation.
struct SignUpScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false

    @State private var nameError: String?
    @State private var emailError: String?
    @State private var phoneError: String?
    @State private var passwordError: String?
    @State private var confirmError: String?
    @State private var termsError: String?

    @State private var isSubmitting = false
    @State private var didSucceed = false

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            if didSucceed {
                successState
                    .transition(.opacity)
            } else {
                form
                    .transition(.opacity)
            }
        }
        .animation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion), value: didSucceed)
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                header

                VStack(spacing: AppSpacing.sm) {
                    AppTextField(
                        label: "Full Name",
                        placeholder: "Maria Santos",
                        text: $name,
                        icon: "person.fill",
                        textContentType: .name,
                        autocapitalization: .words,
                        error: nameError
                    )
                    .onChange(of: name) { _ in nameError = nil }

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
                    .onChange(of: email) { _ in emailError = nil }

                    AppTextField(
                        label: "Mobile Number",
                        placeholder: "+63 917 000 0000",
                        text: $phone,
                        icon: "phone.fill",
                        keyboardType: .phonePad,
                        textContentType: .telephoneNumber,
                        autocapitalization: .never,
                        error: phoneError
                    )
                    .onChange(of: phone) { _ in phoneError = nil }

                    AppTextField(
                        label: "Password",
                        placeholder: "At least 8 characters",
                        text: $password,
                        icon: "lock.fill",
                        isSecure: true,
                        textContentType: .newPassword,
                        autocapitalization: .never,
                        error: passwordError
                    )
                    .onChange(of: password) { _ in passwordError = nil }

                    AppTextField(
                        label: "Confirm Password",
                        placeholder: "Repeat password",
                        text: $confirmPassword,
                        icon: "lock.rotation",
                        isSecure: true,
                        textContentType: .newPassword,
                        autocapitalization: .never,
                        error: confirmError,
                        onSubmit: attemptSignUp
                    )
                    .onChange(of: confirmPassword) { _ in confirmError = nil }

                    termsCheckbox

                    PrimaryButton(
                        title: isSubmitting ? "Creating account…" : "Create Account",
                        systemImage: "arrow.right",
                        isLoading: isSubmitting,
                        action: attemptSignUp
                    )
                    .padding(.top, AppSpacing.xxs)

                    loginLink
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: AppSpacing.xxs) {
            Image("OneMartLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180)
                .padding(.top, AppSpacing.md)

            Text("Create your account")
                .appTextStyle(AppTextStyle.title2)
            Text("One account for food, rides, parcels, and shopping")
                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AppSpacing.sm)
        .background(
            LinearGradient(
                colors: [AppColor.coral.opacity(0.12), AppColor.backgroundPrimary.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var termsCheckbox: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Button {
                agreedToTerms.toggle()
                termsError = nil
            } label: {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(agreedToTerms ? AppColor.coral : Color.clear)
                            .frame(width: 22, height: 22)
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                agreedToTerms ? AppColor.coral : (termsError == nil ? AppColor.borderSubtle : AppColor.error),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)
                        if agreedToTerms {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(AppColor.onAccent)
                        }
                    }

                    (
                        Text("I agree to OneMart's ")
                            .foregroundColor(AppColor.textSecondary)
                        + Text("Terms of Service")
                            .foregroundColor(AppColor.coral)
                        + Text(" and ")
                            .foregroundColor(AppColor.textSecondary)
                        + Text("Privacy Policy")
                            .foregroundColor(AppColor.coral)
                    )
                    .font(AppTextStyle.footnote)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.pressable)
            .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: agreedToTerms)

            if let termsError {
                Text(termsError)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.error)
                    .padding(.leading, 34)
            }
        }
        .padding(.top, AppSpacing.xxs)
    }

    private var loginLink: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("Already have an account?")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
            Button("Log In") {
                withAnimation(AppMotion.easeStandard) {
                    appState.phase = .login
                }
            }
            .font(AppTextStyle.subheadline)
            .foregroundStyle(AppColor.coral)
        }
        .padding(.top, AppSpacing.xxs)
    }

    // MARK: - Success

    private var successState: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.success.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColor.success)
            }
            Text("Account Created!")
                .appTextStyle(AppTextStyle.title)
            Text("Welcome to OneMart, \(firstName)! Taking you to the app…")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            ProgressView()
                .tint(AppColor.coral)
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.lg)
    }

    private var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    // MARK: - Validation & submit

    private func validate() -> Bool {
        nameError = nil
        emailError = nil
        phoneError = nil
        passwordError = nil
        confirmError = nil
        termsError = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty { nameError = "Full name is required" }

        if trimmedEmail.isEmpty {
            emailError = "Email is required"
        } else if !AppState.isPlausibleEmail(trimmedEmail) {
            emailError = "Enter a valid email address"
        }

        if trimmedPhone.isEmpty {
            phoneError = "Mobile number is required"
        } else if !AppState.isPlausiblePhone(trimmedPhone) {
            phoneError = "Enter a valid mobile number"
        }

        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        }

        if confirmPassword.isEmpty {
            confirmError = "Please confirm your password"
        } else if confirmPassword != password {
            confirmError = "Passwords do not match"
        }

        if !agreedToTerms {
            termsError = "You must agree to the Terms & Privacy Policy"
        }

        return nameError == nil && emailError == nil && phoneError == nil
            && passwordError == nil && confirmError == nil && termsError == nil
    }

    private func attemptSignUp() {
        guard validate() else { return }

        isSubmitting = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            isSubmitting = false
            didSucceed = true

            // Hold the "Account Created!" confirmation on screen for a beat,
            // then hand off to AppState — which moves the app to `.main` and
            // tears this screen down.
            try? await Task.sleep(nanoseconds: 1_200_000_000)

            let created = appState.signUp(
                name: name,
                email: email,
                phone: phone,
                password: password,
                confirmPassword: confirmPassword
            )
            if !created {
                // Belt-and-braces: local validation already covers these cases.
                didSucceed = false
                emailError = "We couldn't create that account. Check your details."
            }
        }
    }
}

#Preview {
    SignUpScreen()
        .environmentObject(AppState())
}
