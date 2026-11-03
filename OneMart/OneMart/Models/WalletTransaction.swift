import SwiftUI

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case oneMartWallet = "OneMart Wallet"
    case gcash = "GCash"
    case card = "Credit / Debit Card"
    case cashOnDelivery = "Cash on Delivery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .oneMartWallet: return "wallet.pass.fill"
        case .gcash: return "qrcode"
        case .card: return "creditcard.fill"
        case .cashOnDelivery: return "banknote.fill"
        }
    }
}

enum WalletTransactionType: String, Codable {
    case payment = "Payment"
    case topUp = "Top Up"
    case refund = "Refund"
    case cashback = "Cashback"

    /// Top ups, refunds, and cashback add to the balance; payments subtract.
    var isCredit: Bool {
        self != .payment
    }
}

/// One row in the wallet's transaction history. `module` is nil for wallet-level
/// events (top ups) that don't originate from a specific vertical.
struct WalletTransaction: Identifiable, Hashable {
    let id: UUID
    let module: ServiceModule?
    let type: WalletTransactionType
    let title: String
    let subtitle: String
    let amount: Double
    let date: Date
    let paymentMethod: PaymentMethod

    init(
        id: UUID = UUID(),
        module: ServiceModule?,
        type: WalletTransactionType,
        title: String,
        subtitle: String,
        amount: Double,
        date: Date,
        paymentMethod: PaymentMethod
    ) {
        self.id = id
        self.module = module
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.date = date
        self.paymentMethod = paymentMethod
    }

    /// Signed amount for display — negative for spend, positive for money in.
    var signedAmount: Double {
        type.isCredit ? amount : -amount
    }
}
