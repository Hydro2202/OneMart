import Foundation

/// Toggle state for Profile > Notifications. Session-local (like the rest of
/// this prototype's settings) rather than persisted to disk.
struct NotificationPreferences: Hashable {
    var orderUpdates = true
    var promotionsAndDeals = true
    var chatMessages = true
    var rideAndDeliveryUpdates = true
    var walletActivity = true
}
