import SwiftUI

/// The five verticals unified inside OneMart. Used to tag orders, wallet
/// transactions, and the mixed "recent activity" feed on Home so a single
/// list can represent content from every module.
enum ServiceModule: String, Codable, CaseIterable, Identifiable {
    case food
    case rides
    case logistics
    case shop
    case community

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food: return "Food & Groceries"
        case .rides: return "Rides"
        case .logistics: return "Logistics"
        case .shop: return "Shop"
        case .community: return "Community"
        }
    }

    var shortName: String {
        switch self {
        case .food: return "Food"
        case .rides: return "Rides"
        case .logistics: return "Logistics"
        case .shop: return "Shop"
        case .community: return "Marketplace"
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .rides: return "car.fill"
        case .logistics: return "shippingbox.fill"
        case .shop: return "bag.fill"
        case .community: return "person.2.fill"
        }
    }

    /// Each module's accent, drawn from the shared brand palette rather than
    /// a bespoke color, so the whole app still reads as one system.
    var tintColor: Color {
        switch self {
        case .food: return AppColor.coral
        case .rides: return AppColor.coral
        case .logistics: return AppColor.amber
        case .shop: return AppColor.jade
        case .community: return AppColor.jade
        }
    }
}
