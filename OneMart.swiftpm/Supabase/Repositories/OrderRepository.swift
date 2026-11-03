import Foundation
import Supabase

enum OrderRepository {
    struct OrderRow: Codable {
        let id: UUID
        let userId: UUID
        let module: String
        let title: String
        let subtitle: String
        let imageName: String
        let status: String
        let total: Double
        let placedAt: Date

        enum CodingKeys: String, CodingKey {
            case id, module, title, subtitle, status, total
            case userId = "user_id"
            case imageName = "image_name"
            case placedAt = "placed_at"
        }

        func toOrder() -> Order? {
            guard let module = ServiceModule(rawValue: module),
                  let status = OrderStatus(rawValue: status) else { return nil }
            return Order(
                id: id,
                module: module,
                title: title,
                subtitle: subtitle,
                imageName: imageName,
                status: status,
                total: total,
                placedAt: placedAt
            )
        }
    }

    static func fetchOrders() async throws -> [Order] {
        let rows: [OrderRow] = try await SupabaseManager.client
            .from("orders")
            .select()
            .order("placed_at", ascending: false)
            .execute()
            .value
        return rows.compactMap { $0.toOrder() }
    }

    static func insert(_ order: Order) async throws {
        let session = try await SupabaseManager.client.auth.session
        let row = OrderRow(
            id: order.id,
            userId: session.user.id,
            module: order.module.rawValue,
            title: order.title,
            subtitle: order.subtitle,
            imageName: order.imageName,
            status: order.status.rawValue,
            total: order.total,
            placedAt: order.placedAt
        )
        try await SupabaseManager.client
            .from("orders")
            .insert(row)
            .execute()
    }
}
