import Foundation

// Copy this file to `SupabaseConfig.swift` (same folder) and fill in your
// project's values from Supabase Dashboard → Project Settings → API.
//
// `SupabaseConfig.swift` is gitignored on purpose — every developer/machine
// points at their own project instead of a value baked into source control.
// The anon key is safe to embed in a client app (it's meant to be public and
// is constrained by Row Level Security) — never put the `service_role` key
// here or anywhere in this app.
enum SupabaseConfig {
    static let url = URL(string: "https://YOUR-PROJECT-REF.supabase.co")!
    static let anonKey = "YOUR-ANON-PUBLIC-KEY"

    /// False on a fresh clone until this file (or a gitignored copy) has a
    /// real project URL. Auth then uses `LocalAuthStore` instead of DNS-failing
    /// against the placeholder hostname.
    static var isConfigured: Bool {
        guard let host = url.host, !host.isEmpty else { return false }
        return !host.contains("YOUR-PROJECT-REF")
            && anonKey != "YOUR-ANON-PUBLIC-KEY"
            && !anonKey.isEmpty
    }
}
