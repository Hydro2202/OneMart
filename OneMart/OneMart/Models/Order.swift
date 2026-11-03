import SwiftUI

enum OrderStatus: String, Codable, CaseIterable {
    case placed = "Placed"
    case preparing = "Preparing"
    case onTheWay = "On the Way"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var tintColor: Color {
        switch self {
        case .placed, .preparing, .onTheWay: return AppColor.amber
        case .completed: return AppColor.jade
        case .cancelled: return AppColor.textTertiary
        }
    }
}

/// A single unified order — the backbone of the cross-module "recent activity"
/// feed on Home and the order-history list on Profile. Every order is tagged
/// with the module it came from.
struct Order: Identifiable, Hashable {
    let id: UUID
    let module: ServiceModule
    let title: String
    let subtitle: String
    let imageName: String
    let status: OrderStatus
    let total: Double
    let placedAt: Date

    init(
        id: UUID = UUID(),
        module: ServiceModule,
        title: String,
        subtitle: String,
        imageName: String,
        status: OrderStatus,
        total: Double,
        placedAt: Date
    ) {
        self.id = id
        self.module = module
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.status = status
        self.total = total
        self.placedAt = placedAt
    }
}
