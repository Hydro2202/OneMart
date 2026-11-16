import Foundation

// Copy this file to `GeminiConfig.swift` (same folder) and paste in a real
// key from https://aistudio.google.com/apikey.
//
// `GeminiConfig.swift` is gitignored on purpose — same reasoning as
// `SupabaseConfig.swift`: every developer/machine keeps their own key out of
// source control instead of it being baked into a shared commit. This one
// matters even more than the Supabase publishable key: GitHub's push
// protection will actively block a commit containing a real key here, and a
// key bound to a GCP service account can carry broader permissions than a
// plain Gemini API key, so treat it like a password, not a public value.
//
// With the placeholder below, `isConfigured` is false and Community chat
// uses `AutoReplyEngine`'s local keyword-based replies only.
enum GeminiConfig {
    static let apiKey = "YOUR-GEMINI-API-KEY"

    /// `generateContent` model ids, tried in order until one answers.
    /// (`gemini-2.0-flash` was shut down by Google on June 1, 2026.)
    static let models = [
        "gemini-2.5-flash-lite",
        "gemini-2.5-flash",
        "gemini-3.5-flash-lite"
    ]

    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR-GEMINI-API-KEY"
    }

    static func endpoint(for model: String) -> URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
    }
}
