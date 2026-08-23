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
    let phone: String
    let email: String
    let walletBalance: Double
    let memberSince: Date
    let savedAddresses: [SavedAddress]

    init(
        id: UUID = UUID(),
        name: String,
        photoName: String,
        phone: String,
        email: String,
        walletBalance: Double,
        memberSince: Date,
        savedAddresses: [SavedAddress]
    ) {
        self.id = id
        self.name = name
        self.photoName = photoName
        self.phone = phone
        self.email = email
        self.walletBalance = walletBalance
        self.memberSince = memberSince
        self.savedAddresses = savedAddresses
    }
}
