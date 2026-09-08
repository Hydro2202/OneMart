import Foundation

struct SavedAddress: Identifiable, Hashable {
    let id: UUID
    let label: String
    let fullAddress: String
    let icon: String
    let isDefault: Bool

    init(
        id: UUID = UUID(),
        label: String,
        fullAddress: String,
        icon: String = "mappin.circle.fill",
        isDefault: Bool = false
    ) {
        self.id = id
        self.label = label
        self.fullAddress = fullAddress
        self.icon = icon
        self.isDefault = isDefault
    }
}

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    let name: String
    let photoName: String
    /// A photo picked from the user's library via Edit Profile, if any —
    /// takes priority over `photoName` (the SF Symbol fallback) wherever the
    /// avatar is rendered.
    let photoData: Data?
    let phone: String
    let email: String
    let walletBalance: Double
    let memberSince: Date
    /// `var` — AppState's address CRUD (add/edit/delete/set-default) mutates
    /// this array in place on a local copy of the profile before writing it
    /// back to `currentUser`.
    var savedAddresses: [SavedAddress]

    init(
        id: UUID = UUID(),
        name: String,
        photoName: String,
        photoData: Data? = nil,
        phone: String,
        email: String,
        walletBalance: Double,
        memberSince: Date,
        savedAddresses: [SavedAddress]
    ) {
        self.id = id
        self.name = name
        self.photoName = photoName
        self.photoData = photoData
        self.phone = phone
        self.email = email
        self.walletBalance = walletBalance
        self.memberSince = memberSince
        self.savedAddresses = savedAddresses
    }
}
