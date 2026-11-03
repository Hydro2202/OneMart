import Foundation

/// Cross-module order history — the single feed behind Home's "recent activity"
/// section and Profile's order-history list. Every `ServiceModule` is
/// represented so the unified-app story reads clearly at a glance.
enum MockOrders {
    static let all: [Order] = [
        Order(
            module: .food,
            title: "Lola Nena's Inasal Grill",
            subtitle: "Chicken Inasal Paa × 2",
            imageName: "flame.fill",
            status: .onTheWay,
            total: 285,
            placedAt: MockDate.minutesAgo(24)
        ),
        Order(
            module: .rides,
            title: "Ride to BGC",
            subtitle: "Makati CBD → 9th Ave, Taguig · Moto",
            imageName: "car.fill",
            status: .completed,
            total: 120,
            placedAt: MockDate.daysAgo(1)
        ),
        Order(
            module: .logistics,
            title: "Same-Day Parcel · OM-4471-8823",
            subtitle: "Malate, Manila → Pasig City",
            imageName: "shippingbox.fill",
            status: .onTheWay,
            total: 165,
            placedAt: MockDate.hoursAgo(6)
        ),
        Order(
            module: .food,
            title: "Kape Kalye Coffee Bar",
            subtitle: "Barako Cold Brew × 1, Ensaymada × 1",
            imageName: "cup.and.saucer.fill",
            status: .completed,
            total: 265,
            placedAt: MockDate.daysAgo(2)
        ),
        Order(
            module: .shop,
            title: "TechHaus PH",
            subtitle: "Wireless Noise-Cancelling Earbuds Pro",
            imageName: "headphones",
            status: .preparing,
            total: 1_899,
            placedAt: MockDate.daysAgo(3)
        ),
        Order(
            module: .community,
            title: "Nintendo Switch OLED + 3 games",
            subtitle: "Meet-up with Kevin Tan · Escrow held",
            imageName: "gamecontroller.fill",
            status: .placed,
            total: 15_800,
            placedAt: MockDate.daysAgo(4)
        ),
        Order(
            module: .rides,
            title: "Ride to Ortigas",
            subtitle: "Quezon City → Ortigas Center · Car",
            imageName: "car.fill",
            status: .completed,
            total: 285,
            placedAt: MockDate.daysAgo(6)
        ),
        Order(
            module: .shop,
            title: "Manila Threads",
            subtitle: "Everyday Canvas Tote — Sampaguita Print",
            imageName: "bag.fill",
            status: .cancelled,
            total: 349,
            placedAt: MockDate.daysAgo(9)
        )
    ]

    /// Newest first — what both the activity feed and the history list want.
    static var recent: [Order] {
        all.sorted { $0.placedAt > $1.placedAt }
    }

    /// Still-running orders, for Home's "track your order" strip.
    static var active: [Order] {
        recent.filter { $0.status == .placed || $0.status == .preparing || $0.status == .onTheWay }
    }

    static func orders(for module: ServiceModule) -> [Order] {
        recent.filter { $0.module == module }
    }
}
