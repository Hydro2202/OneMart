import SwiftUI

/// Add/edit sheet for one saved address. Used for both flows — passing
/// `existingAddress` switches the title, seeds the fields, and preserves the
/// original id (and default flag) so `onSave` can tell `AppState` whether to
/// add a new address or replace one that's already there.
struct SavedAddressFormView: View {
    let existingAddress: SavedAddress?
    let onSave: (SavedAddress) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var fullAddress = ""
    @State private var icon = "mappin.circle.fill"
    @State private var isDefault = false

    private static let iconChoices = [
        "house.fill", "briefcase.fill", "building.2.fill",
        "person.2.fill", "graduationcap.fill", "mappin.circle.fill"
    ]

    private var isEditing: Bool { existingAddress != nil }

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAddress: String {
        fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedLabel.isEmpty && trimmedAddress.count >= 6
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    iconPicker

                    AppTextField(
                        label: "Label",
                        placeholder: "Home, Office, Condo…",
                        text: $label,
                        icon: "tag.fill",
                        autocapitalization: .words
                    )

                    AppTextField(
                        label: "Full address",
                        placeholder: "Unit / street / barangay / city",
                        text: $fullAddress,
                        icon: "mappin.and.ellipse",
                        autocapitalization: .words
                    )

                    Toggle(isOn: $isDefault) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set as default")
                                .appTextStyle(AppTextStyle.bodyEmphasis)
                            Text("Used automatically for delivery and pickup.")
                                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                        }
                    }
                    .tint(AppColor.jade)
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))

                    if !canSave {
                        InlineBanner(
                            kind: .info,
                            message: "Give the address a short label and a full street address."
                        )
                    }

                    PrimaryButton(
                        title: isEditing ? "Save Changes" : "Add Address",
                        systemImage: "checkmark",
                        tint: AppColor.jade,
                        isEnabled: canSave,
                        action: save
                    )
                }
                .padding(AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Address" : "Add Address")
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
            .onAppear(perform: seed)
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("ICON")
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .tracking(0.8)

            HStack(spacing: AppSpacing.xs) {
                ForEach(Self.iconChoices, id: \.self) { candidate in
                    let isSelected = icon == candidate
                    Button {
                        icon = candidate
                    } label: {
                        Image(systemName: candidate)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.jade)
                            .frame(width: 40, height: 40)
                            .background(isSelected ? AppColor.jade : AppColor.jade.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
    }

    private func seed() {
        guard let existingAddress else { return }
        label = existingAddress.label
        fullAddress = existingAddress.fullAddress
        icon = existingAddress.icon
        isDefault = existingAddress.isDefault
    }

    private func save() {
        guard canSave else { return }
        onSave(
            SavedAddress(
                id: existingAddress?.id ?? UUID(),
                label: trimmedLabel,
                fullAddress: trimmedAddress,
                icon: icon,
                isDefault: isDefault
            )
        )
        dismiss()
    }
}

#Preview {
    SavedAddressFormView(existingAddress: nil) { _ in }
}
