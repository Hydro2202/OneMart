import Foundation

/// A fixture profile for SwiftUI Previews and `AppState.previewSignedIn`
/// only — real sign-in/sign-up now goes through `AuthRepository` against
/// Supabase Auth, not this file. Kept around purely so canvas previews don't
/// need network access (or a live project) just to render a signed-in state.
///
/// Note on image fields across all MockData: `photoName`/`*ImageName` values
/// are SF Symbol names, used as a placeholder fallback wherever a real photo
/// (from Supabase Storage, once catalog data is seeded) isn't available yet.
enum MockUser {
    static let demo = UserProfile(
        name: "Maria Santos",
        photoName: "person.crop.circle.fill",
        phone: "+63 917 123 4567",
        email: "maria.santos@example.com",
        walletBalance: MockWallet.seedBalance,
        memberSince: MockDate.monthsAgo(18),
        savedAddresses: [
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
    )
}
