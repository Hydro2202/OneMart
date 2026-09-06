import Foundation

/// Shop (e-commerce) fixtures. Flash-deal products carry a **real**
/// `flashDealEndsAt` a few hours in the future so the Shop tab's countdown can
/// tick live off `Date()` instead of showing a canned string.
enum MockProducts {

    // MARK: - Merchants

    static let techHaus = Merchant(
        name: "TechHaus PH",
        logoName: "laptopcomputer",
        isOfficialStore: true,
        rating: 4.9,
        responseRate: 98
    )

    static let manilaThreads = Merchant(
        name: "Manila Threads",
        logoName: "tshirt.fill",
        rating: 4.6,
        responseRate: 91
    )

    static let bahayHome = Merchant(
        name: "Bahay & Home Depot",
        logoName: "house.fill",
        isOfficialStore: true,
        rating: 4.7,
        responseRate: 95
    )

    static let glowUpBeauty = Merchant(
        name: "GlowUp Beauty MNL",
        logoName: "sparkles",
        rating: 4.8,
        responseRate: 93
    )

    static let sariSariExpress = Merchant(
        name: "Sari-Sari Express",
        logoName: "cart.fill",
        rating: 4.5,
        responseRate: 88
    )

    static let allMerchants: [Merchant] = [
        techHaus, manilaThreads, bahayHome, glowUpBeauty, sariSariExpress
    ]

    // MARK: - Products

    static let all: [Product] = [
        Product(
            name: "Wireless Noise-Cancelling Earbuds Pro",
            imageName: "headphones",
            merchant: techHaus,
            price: 1_899,
            originalPrice: 3_499,
            unitsSold: 12_400,
            rating: 4.8,
            isFlashDeal: true,
            flashDealEndsAt: MockDate.hoursFromNow(4.5),
            stockRemaining: 23,
            category: .electronics
        ),
        Product(
            name: "65W GaN Fast Charger (3-Port)",
            imageName: "bolt.fill",
            merchant: techHaus,
            price: 749,
            originalPrice: 1_290,
            unitsSold: 8_930,
            rating: 4.7,
            isFlashDeal: true,
            flashDealEndsAt: MockDate.hoursFromNow(2.25),
            stockRemaining: 8,
            category: .gadgetsAccessories
        ),
        Product(
            name: "Barong Tagalog Slim Fit (Piña-Jusi)",
            imageName: "tshirt.fill",
            merchant: manilaThreads,
            price: 2_450,
            originalPrice: 3_200,
            unitsSold: 1_204,
            rating: 4.9,
            category: .fashion
        ),
        Product(
            name: "Rattan Accent Chair — Cebu Made",
            imageName: "chair.lounge.fill",
            merchant: bahayHome,
            price: 4_899,
            unitsSold: 342,
            rating: 4.6,
            category: .home
        ),
        Product(
            name: "Calamansi Brightening Serum 30ml",
            imageName: "drop.fill",
            merchant: glowUpBeauty,
            price: 585,
            originalPrice: 890,
            unitsSold: 22_180,
            rating: 4.8,
            isFlashDeal: true,
            flashDealEndsAt: MockDate.hoursFromNow(7.75),
            stockRemaining: 41,
            category: .beauty
        ),
        Product(
            name: "Adobo Starter Pack (Pantry Bundle)",
            imageName: "cart.fill",
            merchant: sariSariExpress,
            price: 429,
            unitsSold: 5_610,
            rating: 4.5,
            category: .groceries
        ),
        Product(
            name: "Smart LED Ceiling Fan 52\"",
            imageName: "wind",
            merchant: bahayHome,
            price: 3_299,
            originalPrice: 4_150,
            unitsSold: 780,
            rating: 4.4,
            category: .home
        ),
        Product(
            name: "Everyday Canvas Tote — Sampaguita Print",
            imageName: "bag.fill",
            merchant: manilaThreads,
            price: 349,
            unitsSold: 9_120,
            rating: 4.7,
            isEscrowProtected: true,
            category: .fashion
        ),
        Product(
            name: "Portable Blender 500ml (USB-C)",
            imageName: "cup.and.saucer.fill",
            merchant: techHaus,
            price: 899,
            originalPrice: 1_499,
            unitsSold: 3_045,
            rating: 4.3,
            category: .home
        )
    ]

    static let flashDeals: [Product] = all.filter { $0.isFlashDeal }

    /// Earliest end time across live flash deals — drives the single header
    /// countdown on the Shop tab.
    static var nextFlashDealEnd: Date? {
        flashDeals.compactMap { $0.flashDealEndsAt }.min()
    }

    static func products(in category: ShopCategory) -> [Product] {
        guard category != .all else { return all }
        return all.filter { $0.category == category }
    }

    static func product(id: UUID) -> Product? {
        all.first { $0.id == id }
    }
}
