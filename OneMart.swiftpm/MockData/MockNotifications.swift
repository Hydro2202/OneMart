import Foundation

/// Seeds the notification inbox behind Home's bell icon.
enum MockNotifications {
    static let all: [AppNotification] = [
        AppNotification(
            module: .food,
            icon: "bicycle",
            title: "Your order is on the way",
            message: "Lola Nena's Inasal Grill's rider is 8 minutes from your address.",
            date: MockDate.minutesAgo(6),
            isRead: false
        ),
        AppNotification(
            module: .shop,
            icon: "bolt.fill",
            title: "Flash sale starts in 1 hour",
            message: "Up to 70% off electronics and beauty — set a reminder so you don't miss it.",
            date: MockDate.minutesAgo(40),
            isRead: false
        ),
        AppNotification(
            module: .community,
            icon: "bubble.left.and.bubble.right.fill",
            title: "New message from Kevin Tan",
            message: "\"Is the Nintendo Switch OLED still available?\"",
            date: MockDate.hoursAgo(2),
            isRead: false
        ),
        AppNotification(
            module: .logistics,
            icon: "shippingbox.fill",
            title: "Parcel out for delivery",
            message: "OM-4471-8823 is out for delivery and should arrive within the hour.",
            date: MockDate.hoursAgo(5),
            isRead: true
        ),
        AppNotification(
            module: .rides,
            icon: "star.fill",
            title: "Rate your last ride",
            message: "How was your trip to Ortigas with Rico? Tap to leave a rating.",
            date: MockDate.daysAgo(1),
            isRead: true
        ),
        AppNotification(
            module: nil,
            icon: "wallet.pass.fill",
            title: "Welcome to OneMart",
            message: "One wallet, one login, five services. Top up your wallet to get started.",
            date: MockDate.daysAgo(3),
            isRead: true
        )
    ]
}
