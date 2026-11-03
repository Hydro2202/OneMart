import Foundation

/// Configuration for the optional AI seller auto-reply in Community chat.
///
/// By default every seller reply comes from `AutoReplyEngine`'s local,
/// offline, keyword-aware fallback — no key, no network, no setup. Paste a
/// real Gemini API key below to upgrade every reply to a real AI-generated
/// one instead, using the listing's own details as context.
///
/// Get a free key at https://aistudio.google.com/apikey — the Gemini API
/// free tier is enough for a school project.
///
/// Same rule as `SupabaseConfig`'s anon key: this ships inside the app
/// bundle, so only ever put a client-safe key here, never a billing-account
/// secret meant to stay server-side.
enum GeminiConfig {
    /// Paste a real key here to turn on real Gemini replies.
    ///
    /// This is a modern "Auth key" (the `AQ.` prefix Google AI Studio now
    /// issues by default, replacing the older `AIzaSy...` format) — it's
    /// sent the same way, as a `key` query parameter (and, for extra
    /// compatibility, as an `x-goog-api-key` header too) against the native
    /// `generativelanguage.googleapis.com` endpoint. See `AutoReplyEngine`.
    static let apiKey = "AQ.Ab8RN6JjvirjNwIIVr-p8wYA57qeQvV3Z_iXrHEo3iSbVyc-Gw"

    /// `generateContent` model id. Flash is fast and cheap enough for a
    /// one-line chat reply.
    static let model = "gemini-2.0-flash"

    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR-GEMINI-API-KEY"
    }

    static var endpoint: URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
    }
}
