import Foundation

struct Merchant: Identifiable, Hashable {
    let id: UUID
    let name: String
    let logoName: String
    let isOfficialStore: Bool
    let rating: Double
    let responseRate: Int // percentage

    init(
        id: UUID = UUID(),
        name: String,
        logoName: String,
        isOfficialStore: Bool = false,
        rating: Double,
        responseRate: Int
    ) {
        self.id = id
        self.name = name
        self.logoName = logoName
        self.isOfficialStore = isOfficialStore
        self.rating = rating
        self.responseRate = responseRate
    }
}

struct Product: Identifiable, Hashable {
    let id: UUID
    let name: String
    let imageName: String
    let merchant: Merchant
    let price: Double
    let originalPrice: Double?
    let unitsSold: Int
    let rating: Double
    let isFlashDeal: Bool
    let flashDealEndsAt: Date?
    let stockRemaining: Int?
    let isEscrowProtected: Bool
    let category: ShopCategory

    init(
        id: UUID = UUID(),
        name: String,
        imageName: String,
        merchant: Merchant,
        price: Double,
        originalPrice: Double? = nil,
        unitsSold: Int,
        rating: Double,
        isFlashDeal: Bool = false,
        flashDealEndsAt: Date? = nil,
        stockRemaining: Int? = nil,
        isEscrowProtected: Bool = true,
        category: ShopCategory
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.merchant = merchant
        self.price = price
        self.originalPrice = originalPrice
        self.unitsSold = unitsSold
        self.rating = rating
        self.isFlashDeal = isFlashDeal
        self.flashDealEndsAt = flashDealEndsAt
        self.stockRemaining = stockRemaining
        self.isEscrowProtected = isEscrowProtected
        self.category = category
    }

    /// Discount percentage vs. original price, rounded for badge display.
    var discountPercent: Int? {
        guard let originalPrice, originalPrice > price else { return nil }
        return Int(((originalPrice - price) / originalPrice * 100).rounded())
    }
}

enum ShopCategory: String, Codable, CaseIterable, Identifiable {
    case all = "All"
    case electronics = "Electronics"
    case fashion = "Fashion"
    case home = "Home & Living"
    case beauty = "Beauty"
    case groceries = "Groceries"
    case gadgetsAccessories = "Accessories"

    var id: String { rawValue }
}
