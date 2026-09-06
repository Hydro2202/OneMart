import SwiftUI

// MARK: - Navigation phases

/// The four top-level phases of the app. Mirrors the prototype's
/// `"splash" | "login" | "signup" | "app"` state machine.
enum AppPhase: Hashable {
    case splash
    case login
    case signup
    case main
}

/// The five tabs of the main shell.
///
/// Note the deliberate label mismatch on `.logistics`: the module is called
/// "Logistics" everywhere in the data layer, but the tab bar says **Send**,
/// which is what the product brief and the prototype both use.
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case food
    case rides
    case logistics
    case market

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "Home"
        case .food: return "Food"
        case .rides: return "Rides"
        case .logistics: return "Send"
        case .market: return "Market"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .food: return "fork.knife"
        case .rides: return "car"
        case .logistics: return "shippingbox"
        case .market: return "bag"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .food: return "fork.knife"
        case .rides: return "car.fill"
        case .logistics: return "shippingbox.fill"
        case .market: return "bag.fill"
        }
    }

    /// The data-layer module this tab represents (Home is a cross-module hub,
    /// so it has none).
    var module: ServiceModule? {
        switch self {
        case .home: return nil
        case .food: return .food
        case .rides: return .rides
        case .logistics: return .logistics
        case .market: return .shop
        }
    }
}

/// Which section Profile opens on. Home's wallet card deep-links straight to
/// `.wallet`; every other entry point lands on `.main`.
enum ProfileEntrySection: Hashable {
    case main
    case wallet
}

/// Identifies one of the app's two independent carts.
///
/// Food and Shop carts are kept **strictly separate** — a deliberate product
/// requirement, not an implementation detail. `AppState` refuses to put a
/// `.shop` item in the food cart and vice-versa.
enum CartKind: String, CaseIterable, Identifiable {
    case food
    case shop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: return "Food Cart"
        case .shop: return "Shop Cart"
        }
    }

    var emptyMessage: String {
        switch self {
        case .food: return "Add dishes from any restaurant to start an order."
        case .shop: return "Browse the Shop tab and add items you like."
        }
    }

    var module: ServiceModule {
        switch self {
        case .food: return .food
        case .shop: return .shop
        }
    }
}

/// Why a wallet payment failed, so the UI can react (e.g. offer a top-up)
/// instead of silently clamping the balance — the prototype's bug.
enum WalletPaymentError: Error, Equatable {
    case insufficientFunds(shortfall: Double)
    case invalidAmount
}

// MARK: - AppState

/// The single source of truth for the whole app.
///
/// Injected once at the root with `@StateObject` and read everywhere else with
/// `@EnvironmentObject`. iOS 16 is the deployment target, so this is a classic
/// `ObservableObject` rather than an `@Observable` macro type.
final class AppState: ObservableObject {

    // MARK: Navigation

    @Published var phase: AppPhase = .splash
    @Published var activeTab: AppTab = .home
    @Published var showProfile: Bool = false
    @Published var profileInitialSection: ProfileEntrySection = .main

    // MARK: Session

    @Published private(set) var currentUser: UserProfile?

    // MARK: Carts (kept separate on purpose)

    @Published private(set) var foodCart: [CartItem] = []
    @Published private(set) var shopCart: [CartItem] = []

    // MARK: Favorites

    @Published private(set) var favoriteRestaurantIDs: Set<UUID> = []
    @Published private(set) var favoriteProductIDs: Set<UUID> = []
    @Published private(set) var favoriteListingIDs: Set<UUID> = []

    // MARK: Wallet

    @Published private(set) var walletBalance: Double = MockWallet.seedBalance
    @Published private(set) var walletTransactions: [WalletTransaction] = MockWallet.transactions

    // MARK: Messaging

    @Published var messageThreads: [MessageThread] = MockMessages.threads

    // MARK: Community listings
    //
    // Owned here rather than read straight off `MockListings` so a listing the
    // user posts from the Community tab survives tab switches (a tab body is
    // rebuilt every time `activeTab` changes) and so favourites can resolve
    // against user-created listings too.
    @Published private(set) var communityListings: [MarketplaceListing] = MockListings.all

    // MARK: Orders placed this session
    //
    // Seeded empty; checkout across Food, Shop, Rides, and Send appends here so
    // Home's activity feed shows what the user actually did, mixed in with the
    // `MockOrders` history.
    @Published private(set) var placedOrders: [Order] = []

    // MARK: - Derived cart values

    var foodCartCount: Int { foodCart.reduce(0) { $0 + $1.quantity } }
    var shopCartCount: Int { shopCart.reduce(0) { $0 + $1.quantity } }

    var foodCartTotal: Double { foodCart.reduce(0) { $0 + $1.lineTotal } }
    var shopCartTotal: Double { shopCart.reduce(0) { $0 + $1.lineTotal } }

    func items(in kind: CartKind) -> [CartItem] {
        switch kind {
        case .food: return foodCart
        case .shop: return shopCart
        }
    }

    func count(in kind: CartKind) -> Int {
        switch kind {
        case .food: return foodCartCount
        case .shop: return shopCartCount
        }
    }

    func total(in kind: CartKind) -> Double {
        switch kind {
        case .food: return foodCartTotal
        case .shop: return shopCartTotal
        }
    }

    // MARK: - Cart mutation

    /// Adds a menu item to the **food** cart, merging with an existing line for
    /// the same dish from the same restaurant.
    func addToFoodCart(_ item: MenuItem, from restaurantName: String, quantity: Int = 1) {
        guard quantity > 0 else { return }
        let existingIndex = foodCart.firstIndex { line in
            if case .food(let existing, let name) = line.source {
                return existing.id == item.id && name == restaurantName
            }
            return false
        }
        if let existingIndex {
            foodCart[existingIndex].quantity += quantity
        } else {
            foodCart.append(
                CartItem(source: .food(item: item, restaurantName: restaurantName), quantity: quantity)
            )
        }
    }

    /// Adds a product to the **shop** cart, merging with an existing line for
    /// the same product.
    func addToShopCart(_ product: Product, quantity: Int = 1) {
        guard quantity > 0 else { return }
        let existingIndex = shopCart.firstIndex { line in
            if case .shop(let existing) = line.source {
                return existing.id == product.id
            }
            return false
        }
        if let existingIndex {
            shopCart[existingIndex].quantity += quantity
        } else {
            shopCart.append(CartItem(source: .shop(product: product), quantity: quantity))
        }
    }

    func increment(_ item: CartItem, in kind: CartKind) {
        mutateCart(kind) { cart in
            guard let index = cart.firstIndex(where: { $0.id == item.id }) else { return }
            cart[index].quantity += 1
        }
    }

    /// Decrementing past 1 removes the line entirely; removing the *last* line
    /// simply empties the cart (it must never crash or hide the cart entry point).
    func decrement(_ item: CartItem, in kind: CartKind) {
        mutateCart(kind) { cart in
            guard let index = cart.firstIndex(where: { $0.id == item.id }) else { return }
            if cart[index].quantity > 1 {
                cart[index].quantity -= 1
            } else {
                cart.remove(at: index)
            }
        }
    }

    func remove(_ item: CartItem, in kind: CartKind) {
        mutateCart(kind) { cart in
            cart.removeAll { $0.id == item.id }
        }
    }

    func remove(atOffsets offsets: IndexSet, in kind: CartKind) {
        mutateCart(kind) { cart in
            cart.remove(atOffsets: offsets)
        }
    }

    func clearCart(_ kind: CartKind) {
        mutateCart(kind) { cart in
            cart.removeAll()
        }
    }

    private func mutateCart(_ kind: CartKind, _ body: (inout [CartItem]) -> Void) {
        switch kind {
        case .food: body(&foodCart)
        case .shop: body(&shopCart)
        }
    }

    // MARK: - Favorites

    func toggleFavoriteRestaurant(_ id: UUID) {
        if favoriteRestaurantIDs.contains(id) {
            favoriteRestaurantIDs.remove(id)
        } else {
            favoriteRestaurantIDs.insert(id)
        }
    }

    func toggleFavoriteProduct(_ id: UUID) {
        if favoriteProductIDs.contains(id) {
            favoriteProductIDs.remove(id)
        } else {
            favoriteProductIDs.insert(id)
        }
    }

    func toggleFavoriteListing(_ id: UUID) {
        if favoriteListingIDs.contains(id) {
            favoriteListingIDs.remove(id)
        } else {
            favoriteListingIDs.insert(id)
        }
    }

    func isFavoriteRestaurant(_ id: UUID) -> Bool { favoriteRestaurantIDs.contains(id) }
    func isFavoriteProduct(_ id: UUID) -> Bool { favoriteProductIDs.contains(id) }
    func isFavoriteListing(_ id: UUID) -> Bool { favoriteListingIDs.contains(id) }

    var favoriteCount: Int {
        favoriteRestaurantIDs.count + favoriteProductIDs.count + favoriteListingIDs.count
    }

    /// Resolves the favourite id sets against MockData for display on Profile.
    var favoriteRestaurants: [Restaurant] {
        MockRestaurants.all.filter { favoriteRestaurantIDs.contains($0.id) }
    }

    var favoriteProducts: [Product] {
        MockProducts.all.filter { favoriteProductIDs.contains($0.id) }
    }

    var favoriteListings: [MarketplaceListing] {
        communityListings.filter { favoriteListingIDs.contains($0.id) }
    }

    // MARK: - Community listings

    /// Prepends a listing the user just created so it appears at the top of the
    /// Community board immediately.
    func postListing(_ listing: MarketplaceListing) {
        communityListings.insert(listing, at: 0)
    }

    func listings(in category: ListingCategory, matching query: String = "") -> [MarketplaceListing] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return communityListings.filter { listing in
            let matchesCategory = category == .all || listing.category == category
            let matchesQuery = trimmed.isEmpty
                || listing.title.localizedCaseInsensitiveContains(trimmed)
            return matchesCategory && matchesQuery
        }
    }

    // MARK: - Orders

    /// Records an order placed in this session (checkout, ride booking, parcel
    /// booking) so it shows up in Home's activity feed.
    func recordOrder(_ order: Order) {
        placedOrders.insert(order, at: 0)
    }

    /// This session's orders merged with the seeded history, newest first.
    var activityFeed: [Order] {
        (placedOrders + MockOrders.all).sorted { $0.placedAt > $1.placedAt }
    }

    /// Still-running orders across every module — Home's "track this" strip.
    var activeOrders: [Order] {
        activityFeed.filter { $0.status == .placed || $0.status == .preparing || $0.status == .onTheWay }
    }

    // MARK: - Wallet

    func hasSufficientBalance(for amount: Double) -> Bool {
        walletBalance >= amount
    }

    func shortfall(for amount: Double) -> Double {
        max(0, amount - walletBalance)
    }

    /// Spends from the wallet.
    ///
    /// Returns `false` **without touching the balance** when funds are short —
    /// the prototype silently clamped the balance to 0, which quietly lost
    /// money and hid the failure from the user. Insufficient balance is a real,
    /// reportable outcome here so the UI can show an error and offer a top-up.
    @discardableResult
    func payFromWallet(
        amount: Double,
        title: String = "OneMart payment",
        subtitle: String = "Paid with OneMart Wallet",
        module: ServiceModule? = nil
    ) -> Bool {
        guard amount > 0 else { return false }
        guard walletBalance >= amount else { return false }

        walletBalance -= amount
        walletTransactions.insert(
            WalletTransaction(
                module: module,
                type: .payment,
                title: title,
                subtitle: subtitle,
                amount: amount,
                date: Date(),
                paymentMethod: .oneMartWallet
            ),
            at: 0
        )
        return true
    }

    /// Throwing variant for callers that want to know *why* a payment failed.
    func chargeWallet(
        amount: Double,
        title: String = "OneMart payment",
        subtitle: String = "Paid with OneMart Wallet",
        module: ServiceModule? = nil
    ) throws {
        guard amount > 0 else { throw WalletPaymentError.invalidAmount }
        guard walletBalance >= amount else {
            throw WalletPaymentError.insufficientFunds(shortfall: shortfall(for: amount))
        }
        _ = payFromWallet(amount: amount, title: title, subtitle: subtitle, module: module)
    }

    /// Credits the wallet and records the top-up.
    func topUpWallet(amount: Double, method: PaymentMethod) {
        topUpWallet(amount: amount, methodLabel: method.rawValue, ledgerMethod: method)
    }

    /// Convenience overload for the richer cash-in rails offered by the top-up
    /// sheet (PayMaya / GoTyme / bank transfer …), which map down onto the
    /// coarser ledger-level `PaymentMethod`.
    func topUpWallet(amount: Double, method: TopUpMethod) {
        topUpWallet(
            amount: amount,
            methodLabel: method.displayName,
            ledgerMethod: method.ledgerPaymentMethod
        )
    }

    private func topUpWallet(amount: Double, methodLabel: String, ledgerMethod: PaymentMethod) {
        guard amount > 0 else { return }
        walletBalance += amount
        walletTransactions.insert(
            WalletTransaction(
                module: nil,
                type: .topUp,
                title: "Wallet Top-Up",
                subtitle: "via \(methodLabel)",
                amount: amount,
                date: Date(),
                paymentMethod: ledgerMethod
            ),
            at: 0
        )
    }

    /// Opens Profile directly on the Wallet section (used by Home's wallet card
    /// and by Profile's own wallet row).
    func openWallet() {
        profileInitialSection = .wallet
        showProfile = true
    }

    func openProfile() {
        profileInitialSection = .main
        showProfile = true
    }

    func closeProfile() {
        showProfile = false
        profileInitialSection = .main
    }

    // MARK: - Messaging

    /// Finds the thread for a listing, or starts one seeded with the buyer's
    /// opening question. Returns the thread id either way.
    @discardableResult
    func openThread(for listing: MarketplaceListing) -> UUID {
        if let existing = messageThreads.first(where: { $0.listingID == listing.id }) {
            return existing.id
        }
        let thread = MessageThread(
            listingID: listing.id,
            listingTitle: listing.title,
            listingImageName: listing.imageName,
            listingPrice: listing.price,
            sellerName: listing.sellerName,
            sellerPhotoName: listing.sellerPhotoName,
            messages: [
                ChatMessage(
                    text: "Hi! Is the \"\(listing.title)\" still available?",
                    isFromCurrentUser: true
                )
            ]
        )
        messageThreads.insert(thread, at: 0)
        return thread.id
    }

    func sendMessage(_ text: String, in threadID: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = messageThreads.firstIndex(where: { $0.id == threadID }) else { return }
        messageThreads[index].messages.append(
            ChatMessage(text: trimmed, isFromCurrentUser: true)
        )
    }

    /// Appends a canned seller reply — the mock "the other side is typing"
    /// behaviour from the prototype.
    func appendCannedReply(in threadID: UUID) {
        guard let index = messageThreads.firstIndex(where: { $0.id == threadID }),
              let reply = MockMessages.cannedReplies.randomElement() else { return }
        messageThreads[index].messages.append(
            ChatMessage(text: reply, isFromCurrentUser: false)
        )
    }

    func markThreadRead(_ threadID: UUID) {
        guard let index = messageThreads.firstIndex(where: { $0.id == threadID }) else { return }
        messageThreads[index].unreadCount = 0
    }

    var unreadMessageCount: Int {
        messageThreads.reduce(0) { $0 + $1.unreadCount }
    }

    var sortedThreads: [MessageThread] {
        messageThreads.sorted { $0.lastActivity > $1.lastActivity }
    }

    // MARK: - Auth

    /// Accepts only the demo credentials (email compared case-insensitively).
    /// Any other input returns `false` so Login can show a real inline error.
    @discardableResult
    func logIn(email: String, password: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.lowercased() == MockUser.demoEmail.lowercased(),
              password == MockUser.demoPassword else {
            return false
        }
        currentUser = MockUser.demo
        activeTab = .home
        phase = .main
        return true
    }

    /// Real (client-side) validation: every field required, plausible email,
    /// at least 8 characters, and matching confirmation. Logs the new user in
    /// on success.
    @discardableResult
    func signUp(name: String, email: String, phone: String, password: String, confirmPassword: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty,
              AppState.isPlausibleEmail(trimmedEmail),
              AppState.isPlausiblePhone(trimmedPhone),
              password.count >= 8,
              password == confirmPassword else {
            return false
        }

        currentUser = MockUser.newAccount(name: trimmedName, email: trimmedEmail, phone: trimmedPhone)
        activeTab = .home
        phase = .main
        return true
    }

    /// Resets every piece of session state back to logged-out defaults.
    func logOut() {
        currentUser = nil
        phase = .login
        activeTab = .home
        showProfile = false
        profileInitialSection = .main
        foodCart.removeAll()
        shopCart.removeAll()
        favoriteRestaurantIDs.removeAll()
        favoriteProductIDs.removeAll()
        favoriteListingIDs.removeAll()
        walletBalance = MockWallet.seedBalance
        walletTransactions = MockWallet.transactions
        messageThreads = MockMessages.threads
        communityListings = MockListings.all
        placedOrders.removeAll()
    }

    // MARK: - Validation helpers

    static func isPlausibleEmail(_ email: String) -> Bool {
        // Deliberately simple: one @, a dot in the domain, no whitespace.
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains("."),
              !parts[1].hasPrefix("."),
              !parts[1].hasSuffix("."),
              email.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return false
        }
        return true
    }

    static func isPlausiblePhone(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 7 && digits.count <= 15
    }
}

// MARK: - Preview support

extension AppState {
    /// A signed-in state with a couple of cart items, used by `#Preview`s.
    static var previewSignedIn: AppState {
        let state = AppState()
        _ = state.logIn(email: MockUser.demoEmail, password: MockUser.demoPassword)
        if let restaurant = MockRestaurants.all.first,
           let item = restaurant.menu.first?.items.first {
            state.addToFoodCart(item, from: restaurant.name, quantity: 2)
        }
        if let product = MockProducts.all.first {
            state.addToShopCart(product)
        }
        if let restaurant = MockRestaurants.all.first {
            state.toggleFavoriteRestaurant(restaurant.id)
        }
        if let product = MockProducts.all.last {
            state.toggleFavoriteProduct(product.id)
        }
        return state
    }
}
