import Foundation

/// Configuration for the optional AI seller auto-reply in Community chat.
///
/// When a real key is set below, every seller reply is a real Gemini reply
/// built from the listing's own details. If every model request fails
/// (offline, quota, bad key), `AutoReplyEngine` falls back automatically to
/// its local, keyword-aware reply — the chat never breaks.
///
/// This file is GITIGNORED on purpose (it holds a real key). The committed
/// template is `GeminiConfig.example.swift` next to it — keep both files'
/// structure identical so a fresh clone compiles after copying the template.
enum GeminiConfig {
    /// Google AI Studio key for the "OneMart" project. Sent both as a `key`
    /// query parameter and as an `x-goog-api-key` header (see
    /// `AutoReplyEngine`) for compatibility with the newer "AQ." key format.
    static let apiKey = "AQ.Ab8RN6ISH_G9aoxvR85VYMJTCNcOZW6ubpo6-QrGnv8QVywwyA"

    /// `generateContent` model ids, tried in order until one answers.
    /// (`gemini-2.0-flash`, the old default, was shut down by Google on
    /// June 1, 2026 — every request to it now fails.) Lite/Flash models are
    /// fast and cheap enough for a one-line chat reply and are on the free
    /// tier.
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
