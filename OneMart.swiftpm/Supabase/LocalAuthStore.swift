import Foundation

/// In-device accounts used when `SupabaseConfig` still has the placeholder
/// URL from a fresh clone. Signup/login then work without a live project.
enum LocalAuthStore {
    enum AuthError: LocalizedError {
        case emailTaken
        case invalidCredentials
        case noSession

        var errorDescription: String? {
            switch self {
            case .emailTaken: return "An account with this email already exists."
            case .invalidCredentials: return "Invalid email or password."
            case .noSession: return "No signed-in session."
            }
        }
    }

    private static let accountsKey = "onemart.local.accounts"
    private static let sessionEmailKey = "onemart.local.sessionEmail"

    private struct Account: Codable {
        var id: UUID
        var name: String
        var email: String
        var phone: String
        var password: String
        var memberSince: Date
    }

    static func signUp(name: String, email: String, phone: String, password: String) throws {
        var accounts = loadAccounts()
        let key = email.lowercased()
        if accounts[key] != nil {
            throw AuthError.emailTaken
        }
        accounts[key] = Account(
            id: UUID(),
            name: name,
            email: email,
            phone: phone,
            password: password,
            memberSince: Date()
        )
        saveAccounts(accounts)
        UserDefaults.standard.set(key, forKey: sessionEmailKey)
    }

    static func signIn(email: String, password: String) throws {
        let key = email.lowercased()
        if key == "user@gmail.com", password == "password123" {
            UserDefaults.standard.set(key, forKey: sessionEmailKey)
            return
        }
        guard let account = loadAccounts()[key], account.password == password else {
            throw AuthError.invalidCredentials
        }
        UserDefaults.standard.set(key, forKey: sessionEmailKey)
    }

    static func signOut() {
        UserDefaults.standard.removeObject(forKey: sessionEmailKey)
    }

    static func hasValidSession() -> Bool {
        sessionEmail() != nil
    }

    static func currentProfile() throws -> UserProfile {
        guard let email = sessionEmail() else { throw AuthError.noSession }
        if email == "user@gmail.com" {
            return MockUser.demo
        }
        guard let account = loadAccounts()[email] else { throw AuthError.noSession }
        return UserProfile(
            id: account.id,
            name: account.name,
            photoName: "person.crop.circle.fill",
            phone: account.phone,
            email: account.email,
            walletBalance: 0,
            memberSince: account.memberSince,
            savedAddresses: MockUser.demo.savedAddresses
        )
    }

    private static func sessionEmail() -> String? {
        UserDefaults.standard.string(forKey: sessionEmailKey)
    }

    private static func loadAccounts() -> [String: Account] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let decoded = try? JSONDecoder().decode([String: Account].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func saveAccounts(_ accounts: [String: Account]) {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }
}
