import Foundation

/// How the user funds a wallet top-up.
///
/// This is deliberately a *separate* type from `PaymentMethod`: `PaymentMethod`
/// is the coarse ledger-level classification recorded on a `WalletTransaction`
/// (and the thing offered at checkout), while `TopUpMethod` is the richer set of
/// Philippine cash-in rails the top-up flow actually presents. Each case maps
/// down onto a `PaymentMethod` via `ledgerPaymentMethod` when the transaction is
/// written, and keeps its own `displayName` for the receipt copy so no detail is
/// lost in the mapping.
enum TopUpMethod: String, CaseIterable, Identifiable {
    case gcash = "GCash"
    case payMaya = "PayMaya"
    case goTyme = "GoTyme"
    case bankTransfer = "Bank Transfer"
    case creditCard = "Credit Card"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .gcash: return "qrcode"
        case .payMaya: return "qrcode"
        case .goTyme: return "qrcode"
        case .bankTransfer: return "building.columns.fill"
        case .creditCard: return "creditcard.fill"
        }
    }

    /// Which UI the top-up sheet shows once this method is chosen.
    var flow: TopUpFlow {
        switch self {
        case .gcash, .payMaya, .goTyme: return .qrCode
        case .bankTransfer: return .bankForm
        case .creditCard: return .cardForm
        }
    }

    var flowHint: String {
        switch self {
        case .gcash, .payMaya, .goTyme: return "QR Code"
        case .bankTransfer: return "View Account"
        case .creditCard: return "Enter Details"
        }
    }

    /// The ledger-level payment method recorded on the resulting
    /// `WalletTransaction`. E-wallet rails all settle as `.gcash` (the app's
    /// generic "scan-to-pay e-wallet" bucket); bank + card settle as `.card`.
    var ledgerPaymentMethod: PaymentMethod {
        switch self {
        case .gcash, .payMaya, .goTyme: return .gcash
        case .bankTransfer, .creditCard: return .card
        }
    }
}

enum TopUpFlow: Hashable {
    case qrCode
    case bankForm
    case cardForm
}
