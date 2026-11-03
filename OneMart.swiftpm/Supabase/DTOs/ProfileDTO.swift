import Foundation

/// Mirrors a row in `public.profiles`. Decoded straight off PostgREST
/// responses — property names are camelCase for Swift, `CodingKeys` map back
/// to the table's snake_case columns.
struct ProfileRow: Codable {
    let id: UUID
    let name: String
    let phone: String
    let photoPath: String?
    let memberSince: Date
    let walletBalance: Double
    let email: String?  // not a real column — filled in from the auth session, see ProfileRepository

    enum CodingKeys: String, CodingKey {
        case id, name, phone
        case photoPath = "photo_path"
        case memberSince = "member_since"
        case walletBalance = "wallet_balance"
        case email
    }
}

/// Mirrors a row in `public.saved_addresses`.
struct SavedAddressRow: Codable {
    let id: UUID
    let userId: UUID
    let label: String
    let fullAddress: String
    let icon: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, icon
        case userId = "user_id"
        case fullAddress = "full_address"
        case isDefault = "is_default"
    }
}

/// What gets sent back up when adding/editing an address — no `userId`
/// (RLS/`auth.uid()` supplies that server-side via a default we don't have
/// yet, so the repository fills it in explicitly instead) and no server-only
/// columns.
struct SavedAddressUpsert: Encodable {
    let id: UUID
    let userId: UUID
    let label: String
    let fullAddress: String
    let icon: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, icon
        case userId = "user_id"
        case fullAddress = "full_address"
        case isDefault = "is_default"
    }
}

extension ProfileRow {
    /// Combines this row with its addresses into the app's `UserProfile`.
    /// `photoData` stays nil here — Storage-backed avatar download is wired
    /// up in the Wallet/Profile phase, not this Auth phase.
    func toUserProfile(addresses: [SavedAddress]) -> UserProfile {
        UserProfile(
            id: id,
            name: name,
            photoName: "person.crop.circle.fill",
            photoData: nil,
            phone: phone,
            email: email ?? "",
            walletBalance: walletBalance,
            memberSince: memberSince,
            savedAddresses: addresses
        )
    }
}

extension SavedAddressRow {
    func toSavedAddress() -> SavedAddress {
        SavedAddress(id: id, label: label, fullAddress: fullAddress, icon: icon, isDefault: isDefault)
    }
}
