import Foundation

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case all = "All"
    case filipino = "Filipino"
    case fastFood = "Fast Food"
    case coffee = "Coffee & Tea"
    case desserts = "Desserts"
    case grocery = "Grocery"
    case healthy = "Healthy"
    case koreanJapanese = "Korean & Japanese"
    case streetFood = "Street Food"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .filipino: return "flame.fill"
        case .fastFood: return "takeoutbag.and.cup.and.straw.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .desserts: return "birthday.cake.fill"
        case .grocery: return "cart.fill"
        case .healthy: return "leaf.fill"
        case .koreanJapanese: return "fish.fill"
        case .streetFood: return "flame"
        }
    }
}

struct Restaurant: Identifiable, Hashable {
    let id: UUID
    let name: String
    let imageName: String
    /// Name of an asset-catalog image to use as the real cover photo instead
    /// of the `imageName` SF Symbol fallback, when one has been curated for
    /// this restaurant. `nil` means "no photo yet, show the symbol."
    let photoAssetName: String?
    let categories: [FoodCategory]
    let neighborhood: String
    let rating: Double
    let ratingCount: Int
    let etaMinutesRange: ClosedRange<Int>
    let deliveryFee: Double
    let isPromoted: Bool
    let priceLevel: Int // 1...3 (₱, ₱₱, ₱₱₱)
    let distanceKm: Double
    let isGroceryStore: Bool
    let tagline: String
    let menu: [MenuSection]

    init(
        id: UUID = UUID(),
        name: String,
        imageName: String,
        photoAssetName: String? = nil,
        categories: [FoodCategory],
        neighborhood: String,
        rating: Double,
        ratingCount: Int,
        etaMinutesRange: ClosedRange<Int>,
        deliveryFee: Double,
        isPromoted: Bool = false,
        priceLevel: Int = 2,
        distanceKm: Double,
        isGroceryStore: Bool = false,
        tagline: String,
        menu: [MenuSection] = []
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.photoAssetName = photoAssetName
        self.categories = categories
        self.neighborhood = neighborhood
        self.rating = rating
        self.ratingCount = ratingCount
        self.etaMinutesRange = etaMinutesRange
        self.deliveryFee = deliveryFee
        self.isPromoted = isPromoted
        self.priceLevel = priceLevel
        self.distanceKm = distanceKm
        self.isGroceryStore = isGroceryStore
        self.tagline = tagline
        self.menu = menu
    }

    var etaLabel: String {
        "\(etaMinutesRange.lowerBound)-\(etaMinutesRange.upperBound) min"
    }

    var priceLevelLabel: String {
        String(repeating: "₱", count: max(1, min(priceLevel, 3)))
    }
}

/// Groups menu items the way a real restaurant menu is organized
/// (e.g. "Rice Meals", "Beverages") for the menu-grid detail screen.
struct MenuSection: Identifiable, Hashable {
    let id: UUID
    let title: String
    let items: [MenuItem]

    init(id: UUID = UUID(), title: String, items: [MenuItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}
