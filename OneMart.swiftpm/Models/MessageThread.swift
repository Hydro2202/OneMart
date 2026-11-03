import Foundation

/// A single chat bubble inside a `MessageThread`.
///
/// `isFromCurrentUser` (rather than a sender id) is all the prototype needs to
/// decide bubble alignment/tint — there is no real account system behind this.
struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let text: String
    let isFromCurrentUser: Bool
    let sentAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        isFromCurrentUser: Bool,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isFromCurrentUser = isFromCurrentUser
        self.sentAt = sentAt
    }
}

/// A buyer ↔ seller conversation from the Community (marketplace) tab.
///
/// Threads are always *about* something — normally a `MarketplaceListing` — so
/// the listing context is carried inline (title / image / price) rather than
/// forcing every consumer to re-resolve the listing by id. The optional
/// `listingID` is still kept so a thread can be matched back to a listing when
/// the user taps "Message Seller" on one they've already contacted.
struct MessageThread: Identifiable, Hashable {
    let id: UUID
    let listingID: UUID?
    let listingTitle: String?
    let listingImageName: String?
    let listingPrice: Double?
    let sellerName: String
    /// SF Symbol name standing in for the seller's avatar (no photo assets ship
    /// with the prototype).
    let sellerPhotoName: String
    var messages: [ChatMessage]
    /// Unread count shown as a badge in the conversation list.
    var unreadCount: Int

    init(
        id: UUID = UUID(),
        listingID: UUID? = nil,
        listingTitle: String? = nil,
        listingImageName: String? = nil,
        listingPrice: Double? = nil,
        sellerName: String,
        sellerPhotoName: String = "person.crop.circle.fill",
        messages: [ChatMessage] = [],
        unreadCount: Int = 0
    ) {
        self.id = id
        self.listingID = listingID
        self.listingTitle = listingTitle
        self.listingImageName = listingImageName
        self.listingPrice = listingPrice
        self.sellerName = sellerName
        self.sellerPhotoName = sellerPhotoName
        self.messages = messages
        self.unreadCount = unreadCount
    }

    var lastMessage: ChatMessage? { messages.last }

    /// Timestamp used to sort the conversation list (falls back to the distant
    /// past for an empty thread so it sinks to the bottom).
    var lastActivity: Date { messages.last?.sentAt ?? .distantPast }

    var previewText: String { messages.last?.text ?? "No messages yet" }

    /// Initials fallback for the avatar circle.
    var sellerInitials: String {
        let parts = sellerName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}
