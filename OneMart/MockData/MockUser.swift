import Foundation

/// The single demo account the prototype signs in with.
///
/// Note on image fields across all MockData: no photo assets ship with this
/// prototype (only `OneMartLogo`), so every `*ImageName` / `*PhotoName` /
/// `logoName` string holds an **SF Symbol** name and views render it with
/// `Image(systemName:)`.
enum MockUser {
    static let demoEmail = "user@gmail.com"
    static let demoPassword = "password123"

    static let savedAddresses: [SavedAddress] = [
        SavedAddress(
            label: "Home",
            fullAddress: "123 Mabini St, Malate, Manila 1004",
            icon: "house.fill",
            isDefault: true
        ),
        SavedAddress(
            label: "Work",
            fullAddress: "27F Ayala North Exchange, Ayala Ave, Makati CBD",
            icon: "briefcase.fill"
        ),
        SavedAddress(
            label: "Parents",
            fullAddress: "45 Sampaguita Rd, Project 6, Quezon City",
            icon: "person.2.fill"
        )
    ]

    static let demo = UserProfile(
        name: "Maria Santos",
        photoName: "person.crop.circle.fill",
        phone: "+63 917 123 4567",
        email: demoEmail,
        walletBalance: MockWallet.seedBalance,
        memberSince: MockDate.monthsAgo(18),
        savedAddresses: savedAddresses
    )

    /// Builds a profile for someone who just completed the Sign Up form.
    static func newAccount(name: String, email: String, phone: String) -> UserProfile {
        UserProfile(
            name: name,
            photoName: "person.crop.circle.fill",
            phone: phone,
            email: email,
            walletBalance: MockWallet.seedBalance,
            memberSince: Date(),
            savedAddresses: []
        )
    }
}
