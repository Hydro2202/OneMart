import Foundation

// Real project values for the "OneMart" Supabase project.
//
// This file is GITIGNORED on purpose — the committed template is
// `SupabaseConfig.example.swift` next to it. The publishable key is safe to
// ship inside a client app (it's meant to be public and every table is
// protected by Row Level Security) — never put the `service_role` / secret
// key here or anywhere in this app.
enum SupabaseConfig {
    // Flip this to `true` to run fully offline again — auth, wallet, and
    // orders then use on-device storage (`LocalAuthStore`) instead of the
    // network. Nothing else needs to change; every Supabase call in the app
    // already checks `SupabaseConfig.isConfigured` and falls back
    // automatically.
    private static let temporarilyDisabled = false

    static let url = URL(string: "https://ybmwtzgazahuqpsqklst.supabase.co")!
    static let anonKey = "sb_publishable_i0Kkm9gL2h0IMXt601dwkA_1l9POPpc"

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
