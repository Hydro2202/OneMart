import SwiftUI
import PhotosUI
import UIKit

/// Lets the signed-in user change their avatar (via the real system photo
/// picker — no custom camera roll UI, `PhotosPicker` hands back the picked
/// image directly), name, email, and phone. Saves through
/// `AppState.updateProfile(name:email:phone:)` / `updateProfilePhoto(_:)`.
struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var photoData: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var didSave = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && AppState.isPlausibleEmail(email)
            && AppState.isPlausiblePhone(phone)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                photoPicker

                AppTextField(
                    label: "Full name",
                    placeholder: "Juan Dela Cruz",
                    text: $name,
                    icon: "person.fill",
                    autocapitalization: .words
                )

                AppTextField(
                    label: "Email",
                    placeholder: "you@email.com",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )

                AppTextField(
                    label: "Phone number",
                    placeholder: "+63 9XX XXX XXXX",
                    text: $phone,
                    icon: "phone.fill",
                    keyboardType: .phonePad
                )

                if let errorMessage {
                    InlineBanner(kind: .error, message: errorMessage)
                }

                if didSave {
                    InlineBanner(kind: .success, message: "Profile updated.")
                }

                PrimaryButton(title: "Save Changes", systemImage: "checkmark", isEnabled: canSave, action: save)
            }
            .padding(AppSpacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: seed)
        .onChange(of: pickerItem) { newItem in
            // iOS 16 target: the single-parameter `onChange(of:perform:)`
            // overload, not the two-parameter (oldValue, newValue) one added in iOS 17.
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { photoData = data }
                }
            }
        }
    }

    // MARK: - Photo

    private var photoPicker: some View {
        HStack(spacing: AppSpacing.md) {
            avatar

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Change Photo", systemImage: "photo.on.rectangle")
                        .font(AppTextStyle.subheadline)
                        .foregroundStyle(AppColor.coral)
                }

                if photoData != nil {
                    Button {
                        photoData = nil
                        pickerItem = nil
                    } label: {
                        Text("Remove Photo")
                            .font(AppTextStyle.footnote)
                            .foregroundStyle(AppColor.error)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
        } else {
            // Fallback avatar while no photo has been picked — an SF Symbol
            // stand-in, same convention as the rest of the app's mock imagery.
            ZStack {
                Circle()
                    .fill(AppColor.coral.opacity(0.14))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.coral)
            }
        }
    }

    // MARK: - Actions

    private func seed() {
        guard let user = appState.currentUser else { return }
        name = user.name
        email = user.email
        phone = user.phone
        photoData = user.photoData
    }

    private func save() {
        errorMessage = nil
        didSave = false

        guard appState.updateProfile(name: name, email: email, phone: phone) else {
            errorMessage = "Enter your name, a valid email, and a valid phone number."
            return
        }
        appState.updateProfilePhoto(photoData)

        withAnimation(AppMotion.easeStandard) { didSave = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
    .environmentObject(AppState.previewSignedIn)
}
