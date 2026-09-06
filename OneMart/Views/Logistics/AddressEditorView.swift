import SwiftUI

/// Editor for one end of a parcel's journey.
///
/// This is the fix for the "addresses are hardcoded" bug: pickup **and**
/// drop-off both open this sheet, either seeded from the address book or blank
/// for a brand-new address, and whatever comes back is a real `Address` value
/// that flows through the review step and onto the tracking screen. Nothing on
/// the Send tab is read-only.
struct AddressEditorView: View {
    let title: String
    let tint: Color
    /// Address-book entries offered as a starting point. Picking one fills the
    /// form; the user can still edit every field afterwards.
    let suggestions: [Address]
    let initialAddress: Address?
    let onSave: (Address) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var fullAddress = ""
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var didSeed = false

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
                    if !suggestions.isEmpty {
                        suggestionSection
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Address details")
                            .appTextStyle(AppTextStyle.headline)

                        AppTextField(
                            label: "Label",
                            placeholder: "Home, Office, Kuya Ben…",
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

                        AppTextField(
                            label: "Contact person (optional)",
                            placeholder: "Who's handing over or receiving?",
                            text: $contactName,
                            icon: "person.fill",
                            autocapitalization: .words
                        )

                        AppTextField(
                            label: "Contact number (optional)",
                            placeholder: "+63 9XX XXX XXXX",
                            text: $contactPhone,
                            icon: "phone.fill",
                            keyboardType: .phonePad
                        )
                    }

                    if !canSave {
                        InlineBanner(
                            kind: .info,
                            message: "Give the address a short label and a full street address so the rider can find it."
                        )
                    }

                    PrimaryButton(
                        title: "Use This Address",
                        systemImage: "checkmark",
                        tint: tint,
                        isEnabled: canSave,
                        action: save
                    )
                }
                .padding(AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(title)
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
            .onAppear(perform: seedIfNeeded)
        }
    }

    // MARK: - Suggestions

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Saved addresses")
                .appTextStyle(AppTextStyle.headline)
            Text("Tap one to start from it — you can still change every field.")
                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)

            ForEach(suggestions) { suggestion in
                Button {
                    fill(from: suggestion)
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(width: 32, height: 32)
                            .background(tint.opacity(0.14), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.label)
                                .appTextStyle(AppTextStyle.bodyEmphasis)
                            Text(suggestion.fullAddress)
                                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppColor.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.pressable)
            }
        }
    }

    // MARK: - Actions

    private func seedIfNeeded() {
        guard !didSeed else { return }
        didSeed = true
        if let initialAddress {
            fill(from: initialAddress)
        }
    }

    private func fill(from address: Address) {
        label = address.label
        fullAddress = address.fullAddress
        contactName = address.contactName ?? ""
        contactPhone = address.contactPhone ?? ""
    }

    private func save() {
        guard canSave else { return }
        let name = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(
            Address(
                label: trimmedLabel,
                fullAddress: trimmedAddress,
                contactName: name.isEmpty ? nil : name,
                contactPhone: phone.isEmpty ? nil : phone
            )
        )
        dismiss()
    }
}

#Preview {
    AddressEditorView(
        title: "Pickup address",
        tint: AppColor.jade,
        suggestions: MockParcelAddresses.pickupSuggestions,
        initialAddress: MockParcelAddresses.pickupSuggestions[0]
    ) { _ in }
}
