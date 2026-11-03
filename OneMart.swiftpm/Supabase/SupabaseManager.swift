import Foundation
import Supabase

/// The single shared Supabase client for the whole app. Every repository/
/// service type reads through `SupabaseManager.client` instead of
/// constructing its own — one client, one auth session, one realtime socket.
enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
}
