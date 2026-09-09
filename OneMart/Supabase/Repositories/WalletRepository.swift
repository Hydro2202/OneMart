import Foundation
import Supabase

enum WalletRepository {
    struct TransactionRow: Decodable {
        let id: UUID
        let module: String?
        let type: String
        let title: String
        let subtitle: String
        let amount: Double
        let paymentMethod: String
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id, module, type, title, subtitle, amount
            case paymentMethod = "payment_method"
            case createdAt = "created_at"
        }

        func toWalletTransaction() -> WalletTransaction {
            WalletTransaction(
                id: id,
                module: module.flatMap(ServiceModule.init(rawValue:)),
                type: WalletTransactionType(rawValue: type) ?? .payment,
                title: title,
                subtitle: subtitle,
                amount: amount,
                date: createdAt,
                paymentMethod: PaymentMethod(rawValue: paymentMethod) ?? .oneMartWallet
            )
        }
    }

    private struct PayParams: Encodable {
        let p_amount: Double
        let p_title: String
        let p_subtitle: String
        let p_module: String?
    }

    private struct TopUpParams: Encodable {
        let p_amount: Double
        let p_payment_method: String
        let p_method_label: String
    }

    static func fetchTransactions() async throws -> [WalletTransaction] {
        let rows: [TransactionRow] = try await SupabaseManager.client
            .from("wallet_transactions")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toWalletTransaction() }
    }

    static func pay(amount: Double, title: String, subtitle: String, module: ServiceModule?) async throws -> Bool {
        try await SupabaseManager.client
            .rpc(
                "pay_from_wallet",
                params: PayParams(
                    p_amount: amount,
                    p_title: title,
                    p_subtitle: subtitle,
                    p_module: module?.rawValue
                )
            )
            .execute()
            .value
    }

    static func topUp(amount: Double, paymentMethod: String, methodLabel: String) async throws {
        try await SupabaseManager.client
            .rpc(
                "top_up_wallet",
                params: TopUpParams(
                    p_amount: amount,
                    p_payment_method: paymentMethod,
                    p_method_label: methodLabel
                )
            )
            .execute()
    }
}
