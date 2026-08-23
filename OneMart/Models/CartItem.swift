import Foundation

/// The unified cart can hold items from Food, Shop, and Logistics at once —
/// this enum is what makes a single `CartItem` polymorphic across modules.
enum CartItemSource: Hashable {
    case food(item: MenuItem, restaurantName: String)
    case shop(product: Product)
    case logistics(parcel: Parcel)
}

struct CartItem: Identifiable, Hashable {
    let id: UUID
    let source: CartItemSource
    var quantity: Int

    init(id: UUID = UUID(), source: CartItemSource, quantity: Int = 1) {
        self.id = id
        self.source = source
        self.quantity = quantity
    }

    var module: ServiceModule {
        switch source {
        case .food: return .food
        case .shop: return .shop
        case .logistics: return .logistics
        }
    }

    var name: String {
        switch source {
        case .food(let item, _): return item.name
        case .shop(let product): return product.name
        case .logistics(let parcel): return "Parcel to \(parcel.dropoffAddress.label)"
        }
    }

    var imageName: String {
        switch source {
        case .food(let item, _): return item.imageName
        case .shop(let product): return product.imageName
        case .logistics(let parcel): return parcel.size.icon
        }
    }

    var subtitle: String {
        switch source {
        case .food(_, let restaurantName): return restaurantName
        case .shop(let product): return product.merchant.name
        case .logistics(let parcel): return parcel.itemDescription
        }
    }

    var unitPrice: Double {
        switch source {
        case .food(let item, _): return item.price
        case .shop(let product): return product.price
        case .logistics(let parcel): return parcel.fare
        }
    }

    var lineTotal: Double {
        unitPrice * Double(quantity)
    }
}
