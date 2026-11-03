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
    // TEMPORARY: flip this back to `false` to reconnect to Supabase. While
    // `true`, the app ignores the real credentials below and runs fully
    // offline — auth, wallet, and orders all use on-device local storage
    // (`LocalAuthStore`) instead of the network. Nothing else needs to
    // change; every Supabase call in the app already checks
    // `SupabaseConfig.isConfigured` and falls back automatically.
    private static let temporarilyDisabled = true

    static let url = URL(string: "https://hwwyjwuesuexicjjydwb.supabase.co")!
    static let anonKey = "sb_publishable_B2JQ95cPNq5nbWkjzdJeag_CHWor5qC"

    /// False on a fresh clone until this file (or a gitignored copy) has a
    /// real project URL. Auth then uses `LocalAuthStore` instead of DNS-failing
    /// against the placeholder hostname.
    static var isConfigured: Bool {
        if temporarilyDisabled { return false }
        guard let host = url.host, !host.isEmpty else { return false }
        return !host.contains("YOUR-PROJECT-REF")
            && anonKey != "YOUR-ANON-PUBLIC-KEY"
            && !anonKey.isEmpty
    }
}

