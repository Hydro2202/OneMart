import Foundation
import Supabase

/// Thin wrapper around `SupabaseManager.client.auth` + the `profiles` /
/// `saved_addresses` tables — everything `AppState` needs to turn a
/// Supabase session into the app's `UserProfile`.
///
/// NOTE: written against the documented supabase-swift v2 API surface
/// without a Swift toolchain available to compile it (see the project's
/// README for why). If a method name below doesn't quite match what Xcode
/// resolves, it's almost certainly a same-shaped sibling in the SDK —
/// straightforward to correct once this is actually built.
enum AuthRepository {

    enum SignUpOutcome {
        /// Session came back immediately — the project has email
        /// confirmation turned off (or it's already confirmed some other way).
        case signedIn
        /// Account was created, but Supabase Auth is waiting on an email
        /// confirmation link before it'll issue a session.
        case needsEmailConfirmation
    }

    // MARK: - Sign up / in / out

    static func signUp(name: String, email: String, phone: String, password: String) async throws -> SignUpOutcome {
        let response = try await SupabaseManager.client.auth.signUp(
            email: email,
            password: password,
            data: [
                "name": .string(name),
                "phone": .string(phone)
            ]
        )
        return response.session != nil ? .signedIn : .needsEmailConfirmation
    }

    static func signIn(email: String, password: String) async throws {
        try await SupabaseManager.client.auth.signIn(email: email, password: password)
    }

    static func signOut() async throws {
        try await SupabaseManager.client.auth.signOut()
    }

    /// Whether a still-valid session already exists — checked once at launch
    /// (from `SplashScreen`) so a returning user skips straight past Login.
    static func hasValidSession() async -> Bool {
        (try? await SupabaseManager.client.auth.session) != nil
    }

    // MARK: - Profile

    /// Fetches the signed-in user's `profiles` row + `saved_addresses`, and
    /// combines them into the app's `UserProfile`. Throws if there's no
    /// active session, or if the `profiles` row doesn't exist yet (the
    /// `on_auth_user_created` trigger creates it synchronously on sign-up, so
    /// this should only fail if the migration wasn't applied).
    static func fetchCurrentProfile() async throws -> UserProfile {
        let session = try await SupabaseManager.client.auth.session
        let userID = session.user.id

        async let profileTask: ProfileRow = SupabaseManager.client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value

        async let addressesTask: [SavedAddressRow] = SupabaseManager.client
            .from("saved_addresses")
            .select()
            .eq("user_id", value: userID)
            .order("created_at")
            .execute()
            .value

        var profile = try await profileTask
        let addresses = try await addressesTask

        // `profiles` has no `email` column (Supabase Auth already owns that,
        // in `auth.users`) — stitch it in from the session instead of
        // duplicating it in the database.
        profile = ProfileRow(
            id: profile.id,
            name: profile.name,
            phone: profile.phone,
            photoPath: profile.photoPath,
            memberSince: profile.memberSince,
            walletBalance: profile.walletBalance,
            email: session.user.email
        )

        return profile.toUserProfile(addresses: addresses.map { $0.toSavedAddress() })
    }
}
