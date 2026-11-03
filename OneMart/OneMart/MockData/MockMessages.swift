import Foundation

/// Seed conversations for the Community/Market messaging feature. Both threads
/// point at real `MockListings` entries so tapping through from a listing finds
/// an existing conversation instead of starting a duplicate.
enum MockMessages {
    private static let switchListing = MockListings.all[4]   // Nintendo Switch OLED
    private static let tableListing = MockListings.all[1]    // Narra Dining Table

    static let threads: [MessageThread] = [
        MessageThread(
            listingID: switchListing.id,
            listingTitle: switchListing.title,
            listingImageName: switchListing.imageName,
            listingPrice: switchListing.price,
            sellerName: switchListing.sellerName,
            sellerPhotoName: switchListing.sellerPhotoName,
            messages: [
                ChatMessage(
                    text: "Hi! Is the Switch OLED still available?",
                    isFromCurrentUser: true,
                    sentAt: MockDate.hoursAgo(5)
                ),
                ChatMessage(
                    text: "Yes po, still available! All three game carts are included.",
                    isFromCurrentUser: false,
                    sentAt: MockDate.hoursAgo(4)
                ),
                ChatMessage(
                    text: "Great. Would you take ₱15,000 if I pick it up this weekend?",
                    isFromCurrentUser: true,
                    sentAt: MockDate.hoursAgo(4)
                ),
                ChatMessage(
                    text: "Let's meet halfway at ₱15,400 and I'll throw in a screen protector. Trinoma on Saturday?",
                    isFromCurrentUser: false,
                    sentAt: MockDate.minutesAgo(38)
                )
            ],
            unreadCount: 1
        ),
        MessageThread(
            listingID: tableListing.id,
            listingTitle: tableListing.title,
            listingImageName: tableListing.imageName,
            listingPrice: tableListing.price,
            sellerName: tableListing.sellerName,
            sellerPhotoName: tableListing.sellerPhotoName,
            messages: [
                ChatMessage(
                    text: "Good evening! Can the narra table be delivered to Pasig?",
                    isFromCurrentUser: true,
                    sentAt: MockDate.daysAgo(1)
                ),
                ChatMessage(
                    text: "Hi! I can't deliver, but you can book a OneMart Send freight rider from my place in Antipolo.",
                    isFromCurrentUser: false,
                    sentAt: MockDate.hoursAgo(20)
                )
            ]
        )
    ]
}
