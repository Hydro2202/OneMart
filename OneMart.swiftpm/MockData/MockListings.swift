import Foundation

/// Community (peer-to-peer marketplace) fixtures — the Facebook-Marketplace-style
/// board. Sellers are ordinary people, prices are negotiable-feeling, and
/// distances are short enough to make "meet-up" believable.
enum MockListings {
    static let all: [MarketplaceListing] = [
        MarketplaceListing(
            title: "iPhone 13 128GB — Midnight, complete set",
            imageName: "iphone",
            photoAssetName: "listing_iphone",
            price: 24_500,
            condition: .likeNew,
            category: .electronics,
            locationName: "Pasig City",
            distanceKm: 2.3,
            postedAt: MockDate.hoursAgo(5),
            sellerID: UUID(uuidString: "9D1F2A10-0001-4B1A-9C10-000000000001")!,
            sellerName: "Ramon Dela Cruz",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.9,
            sellerListingsCount: 14,
            description: "Bought Nov 2023, battery health 92%. Complete with box, cable, and a clear case. Meet up at SM Megamall or ship via OneMart Logistics.",
            isDeliveryAvailable: true
        ),
        MarketplaceListing(
            title: "Narra Dining Table (6-seater)",
            imageName: "table.furniture.fill",
            photoAssetName: "listing_diningTable",
            price: 8_900,
            condition: .good,
            category: .furniture,
            locationName: "Antipolo, Rizal",
            distanceKm: 12.8,
            postedAt: MockDate.daysAgo(1),
            sellerID: UUID(uuidString: "9D1F2A10-0002-4B1A-9C10-000000000002")!,
            sellerName: "Grace Villanueva",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.7,
            sellerListingsCount: 6,
            description: "Solid narra, minor scratches on one leg. Chairs included. Buyer arranges pick-up — freight booking available through OneMart Send.",
            isDeliveryAvailable: false
        ),
        MarketplaceListing(
            title: "Honda Click 125i (2021) — registered until 2026",
            imageName: "bicycle",
            photoAssetName: "listing_motorcycle",
            price: 62_000,
            condition: .good,
            category: .vehicles,
            locationName: "Caloocan City",
            distanceKm: 9.1,
            postedAt: MockDate.daysAgo(2),
            sellerID: UUID(uuidString: "9D1F2A10-0003-4B1A-9C10-000000000003")!,
            sellerName: "Jomar Reyes",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.8,
            sellerListingsCount: 3,
            description: "18,000 km, all-original, casa-maintained. OR/CR clean and under my name. Test drive welcome in Bagong Barrio.",
            isDeliveryAvailable: false
        ),
        MarketplaceListing(
            title: "Uniqlo & Zara bundle — 8 pcs, size M",
            imageName: "tshirt.fill",
            photoAssetName: "listing_clothesBundle",
            price: 950,
            condition: .likeNew,
            category: .fashion,
            locationName: "Marikina City",
            distanceKm: 4.6,
            postedAt: MockDate.hoursAgo(20),
            sellerID: UUID(uuidString: "9D1F2A10-0004-4B1A-9C10-000000000004")!,
            sellerName: "Aira Mendoza",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 5.0,
            sellerListingsCount: 41,
            description: "Preloved bundle, all washed and pressed. No stains or tears. COD within Marikina or courier nationwide.",
            isDeliveryAvailable: true
        ),
        MarketplaceListing(
            title: "Nintendo Switch OLED + 3 games",
            imageName: "gamecontroller.fill",
            photoAssetName: "listing_switch",
            price: 15_800,
            condition: .good,
            category: .hobbies,
            locationName: "Quezon City",
            distanceKm: 6.4,
            postedAt: MockDate.daysAgo(3),
            sellerID: UUID(uuidString: "9D1F2A10-0005-4B1A-9C10-000000000005")!,
            sellerName: "Kevin Tan",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.6,
            sellerListingsCount: 22,
            description: "Includes Zelda, Mario Kart 8, and Animal Crossing carts. Joy-Cons have no drift. Escrow through OneMart is fine with me.",
            isDeliveryAvailable: true
        ),
        MarketplaceListing(
            title: "Free moving boxes (approx. 20 pcs)",
            imageName: "shippingbox.fill",
            photoAssetName: "listing_movingBoxes",
            price: 0,
            isFree: true,
            condition: .fair,
            category: .freeStuff,
            locationName: "Mandaluyong City",
            distanceKm: 3.2,
            postedAt: MockDate.hoursAgo(2),
            sellerID: UUID(uuidString: "9D1F2A10-0006-4B1A-9C10-000000000006")!,
            sellerName: "Bea Fernandez",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.9,
            sellerListingsCount: 2,
            description: "Just moved in. Sturdy double-wall boxes, some tape residue. First come, first served — pick up any time before Sunday.",
            isDeliveryAvailable: false
        ),
        MarketplaceListing(
            title: "Acoustic guitar — Fender CD-60S with case",
            imageName: "guitars.fill",
            photoAssetName: "listing_guitar",
            price: 6_400,
            condition: .likeNew,
            category: .hobbies,
            locationName: "Las Piñas City",
            distanceKm: 15.7,
            postedAt: MockDate.daysAgo(4),
            sellerID: UUID(uuidString: "9D1F2A10-0007-4B1A-9C10-000000000007")!,
            sellerName: "Miguel Ocampo",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.8,
            sellerListingsCount: 9,
            description: "Barely played, fresh strings installed last month. Hard case and clip-on tuner included.",
            isDeliveryAvailable: true
        ),
        MarketplaceListing(
            title: "Office swivel chair — ergonomic mesh",
            imageName: "chair.lounge.fill",
            photoAssetName: "listing_officeChair",
            price: 2_200,
            condition: .good,
            category: .furniture,
            locationName: "Makati City",
            distanceKm: 1.8,
            postedAt: MockDate.hoursAgo(30),
            sellerID: UUID(uuidString: "9D1F2A10-0008-4B1A-9C10-000000000008")!,
            sellerName: "Paolo Bautista",
            sellerPhotoName: "person.crop.circle.fill",
            sellerRating: 4.5,
            sellerListingsCount: 11,
            description: "WFH setup upgrade — selling my old chair. Height and tilt lock both work perfectly.",
            isDeliveryAvailable: true
        )
    ]

    static func listings(in category: ListingCategory) -> [MarketplaceListing] {
        guard category != .all else { return all }
        return all.filter { $0.category == category }
    }

    static func listing(id: UUID) -> MarketplaceListing? {
        all.first { $0.id == id }
    }
}
