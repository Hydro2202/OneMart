import Foundation

enum ListingCondition: String, Codable, CaseIterable, Identifiable {
    case brandNew = "Brand New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"

    var id: String { rawValue }
}

enum ListingCategory: String, Codable, CaseIterable, Identifiable {
    case all = "All"
    case electronics = "Electronics"
    case furniture = "Furniture"
    case vehicles = "Vehicles"
    case fashion = "Fashion"
    case hobbies = "Hobbies"
    case freeStuff = "Free Stuff"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .electronics: return "laptopcomputer"
        case .furniture: return "chair.lounge.fill"
        case .vehicles: return "car.side.fill"
        case .fashion: return "tshirt.fill"
        case .hobbies: return "gamecontroller.fill"
        case .freeStuff: return "gift.fill"
        }
    }
}

/// Peer-to-peer listing for the Community (Facebook Marketplace-style) board.
struct MarketplaceListing: Identifiable, Hashable {
    let id: UUID
    let title: String
    let imageName: String
    /// A photo picked from the seller's library via the Sell flow's
    /// `PhotosPicker`, if any — takes priority over everything else below
    /// wherever the listing's photo is rendered.
    let photoData: Data?
    /// Asset-catalog image curated for a mock listing (never set by the Sell
    /// flow) — takes priority over `imageName` (the SF Symbol fallback) but
    /// not over a real `photoData` upload. `nil` means no curated photo.
    let photoAssetName: String?
    let price: Double
    let isFree: Bool
    let condition: ListingCondition
    let category: ListingCategory
    let locationName: String
    let distanceKm: Double
    let postedAt: Date
    /// The account that posted this listing. Compared against
    /// `AppState.currentUser?.id` so a seller viewing their own listing sees
    /// listing-management actions instead of a "Message Seller" button that
    /// would otherwise let them message themselves.
    let sellerID: UUID
    let sellerName: String
    let sellerPhotoName: String
    let sellerRating: Double
    let sellerListingsCount: Int
    let description: String
    let isDeliveryAvailable: Bool

    init(
        id: UUID = UUID(),
        title: String,
        imageName: String,
        photoData: Data? = nil,
        photoAssetName: String? = nil,
        price: Double,
        isFree: Bool = false,
        condition: ListingCondition,
        category: ListingCategory,
        locationName: String,
        distanceKm: Double,
        postedAt: Date,
        sellerID: UUID,
        sellerName: String,
        sellerPhotoName: String,
        sellerRating: Double,
        sellerListingsCount: Int,
        description: String,
        isDeliveryAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.photoData = photoData
        self.photoAssetName = photoAssetName
        self.price = price
        self.isFree = isFree
        self.condition = condition
        self.category = category
        self.locationName = locationName
        self.distanceKm = distanceKm
        self.postedAt = postedAt
        self.sellerID = sellerID
        self.sellerName = sellerName
        self.sellerPhotoName = sellerPhotoName
        self.sellerRating = sellerRating
        self.sellerListingsCount = sellerListingsCount
        self.description = description
        self.isDeliveryAvailable = isDeliveryAvailable
    }
}
