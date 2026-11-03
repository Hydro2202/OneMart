import Foundation

/// Seed state for the OneMart Wallet — the balance every fresh session (and
/// every log out) resets to, plus a believable transaction history spanning all
/// five modules so the wallet never looks empty.
enum MockWallet {
    /// Matches the prototype's starting balance exactly.
    static let seedBalance: Double = 1_240.50

    /// `let`, not a computed property, so the ids stay stable for the session.
    static let transactions: [WalletTransaction] = [
        WalletTransaction(
            module: .food,
            type: .payment,
            title: "Lola Nena's Inasal Grill",
            subtitle: "Chicken Inasal Paa × 2",
            amount: 285,
            date: MockDate.hoursAgo(3),
            paymentMethod: .oneMartWallet
        ),
        WalletTransaction(
            module: nil,
            type: .topUp,
            title: "Wallet Top-Up",
            subtitle: "via GCash",
            amount: 1_000,
            date: MockDate.hoursAgo(9),
            paymentMethod: .gcash
        ),
        WalletTransaction(
            module: .rides,
            type: .payment,
            title: "Ride to BGC",
            subtitle: "Makati CBD → Taguig · Moto",
            amount: 120,
            date: MockDate.daysAgo(1),
            paymentMethod: .oneMartWallet
        ),
        WalletTransaction(
            module: .shop,
            type: .cashback,
            title: "Cashback",
            subtitle: "Flash Deal · 5% back",
            amount: 110,
            date: MockDate.daysAgo(2),
            paymentMethod: .oneMartWallet
        ),
        WalletTransaction(
            module: .logistics,
            type: .payment,
            title: "Same-Day Parcel",
            subtitle: "Mandaluyong → Pasig",
            amount: 80,
            date: MockDate.daysAgo(3),
            paymentMethod: .oneMartWallet
        ),
        WalletTransaction(
            module: .community,
            type: .refund,
            title: "Refund · Escrow Released",
            subtitle: "Seller cancelled meet-up",
            amount: 450,
            date: MockDate.daysAgo(5),
            paymentMethod: .oneMartWallet
        )
    ]
}
