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

    /// Which tab a module's orders/content belong to — the reverse of
    /// `module`. Shared by Home's activity feed and the cross-tab active-order
    /// tracking bar so both jump to the same place for the same order.
    static func tab(for module: ServiceModule) -> AppTab {
        switch module {
        case .food: return .food
        case .rides: return .rides
        case .logistics: return .logistics
        case .shop, .community: return .market
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
///
/// Pinned to the main actor: every `@Published` property here drives SwiftUI,
/// and `async` methods below (auth, wallet sync, order sync) used to run
/// their bodies off the main thread, tripping "Publishing changes from
/// background threads is not allowed" and making UI updates (like leaving
/// the splash screen) unreliable/delayed. `@MainActor` keeps all of that
/// state mutation on the main thread automatically.
@MainActor
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

    @Published private(set) var walletBalance: Double = 0
    @Published private(set) var walletTransactions: [WalletTransaction] = []

    // MARK: Messaging

    @Published var messageThreads: [MessageThread] = []

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

    /// The restaurant currently occupying the food cart, if any. The food
    /// cart can only ever hold dishes from one restaurant at a time.
    var foodCartRestaurantName: String? {
        for line in foodCart {
            if case .food(_, let name) = line.source { return name }
        }
        return nil
    }

    /// Returns the name of the restaurant already in the food cart when it
    /// differs from `restaurantName` — the signal a caller uses to confirm
    /// with the user before switching restaurants. `nil` means it's safe to
    /// add straight away (empty cart, or same restaurant).
    func conflictingRestaurantName(for restaurantName: String) -> String? {
        guard let existing = foodCartRestaurantName, existing != restaurantName else { return nil }
        return existing
    }

    /// Adds a menu item to the **food** cart, merging with an existing line for
    /// the same dish from the same restaurant.
    ///
    /// Does **not** guard against mixing restaurants itself — callers must
    /// check `conflictingRestaurantName(for:)` first and route through
    /// `replaceFoodCart(with:from:quantity:)` when the user confirms a switch.
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

    /// Empties the food cart and adds this item — the food cart can only ever
    /// hold dishes from one restaurant, so switching restaurants clears
    /// whatever was there. Only call this after the user has confirmed the
    /// switch (see `conflictingRestaurantName(for:)`).
    func replaceFoodCart(with item: MenuItem, from restaurantName: String, quantity: Int = 1) {
        foodCart.removeAll()
        addToFoodCart(item, from: restaurantName, quantity: quantity)
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

    // MARK: - Saved addresses

    /// Appends a new saved address. If it's marked default (or it's the
    /// user's very first address), every other address is un-defaulted so
    /// exactly one stays default.
    func addAddress(_ address: SavedAddress) {
        guard var user = currentUser else { return }
        var addresses = user.savedAddresses
        let shouldBeDefault = address.isDefault || addresses.isEmpty
        if shouldBeDefault {
            addresses = addresses.map { existing in
                SavedAddress(id: existing.id, label: existing.label, fullAddress: existing.fullAddress, icon: existing.icon, isDefault: false)
            }
        }
        addresses.append(
            SavedAddress(id: address.id, label: address.label, fullAddress: address.fullAddress, icon: address.icon, isDefault: shouldBeDefault)
        )
        user.savedAddresses = addresses
        currentUser = user
    }

    /// Replaces the address with a matching id. If the edited address is now
    /// marked default, every other address is un-defaulted.
    func updateAddress(_ address: SavedAddress) {
        guard var user = currentUser else { return }
        var addresses = user.savedAddresses
        guard addresses.contains(where: { $0.id == address.id }) else { return }
        addresses = addresses.map { existing in
            guard existing.id == address.id else {
                return address.isDefault
                    ? SavedAddress(id: existing.id, label: existing.label, fullAddress: existing.fullAddress, icon: existing.icon, isDefault: false)
                    : existing
            }
            return address
        }
        user.savedAddresses = addresses
        currentUser = user
    }

    /// Removes an address. If it was the default and others remain, the first
    /// remaining address becomes the new default so there's always one set
    /// whenever the list isn't empty.
    func deleteAddress(_ id: UUID) {
        guard var user = currentUser else { return }
        var addresses = user.savedAddresses
        let wasDefault = addresses.first(where: { $0.id == id })?.isDefault ?? false
        addresses.removeAll { $0.id == id }
        if wasDefault, let firstIndex = addresses.indices.first {
            let first = addresses[firstIndex]
            addresses[firstIndex] = SavedAddress(id: first.id, label: first.label, fullAddress: first.fullAddress, icon: first.icon, isDefault: true)
        }
        user.savedAddresses = addresses
        currentUser = user
    }

    /// Marks one address default and every other address not-default.
    func setDefaultAddress(_ id: UUID) {
        guard var user = currentUser else { return }
        user.savedAddresses = user.savedAddresses.map { existing in
            SavedAddress(id: existing.id, label: existing.label, fullAddress: existing.fullAddress, icon: existing.icon, isDefault: existing.id == id)
        }
        currentUser = user
    }

    // MARK: - Profile editing

    /// Updates the editable basics from the Edit Profile screen. Trims input
    /// and requires a non-empty name and a plausible email/phone, same rules
    /// as Sign Up.
    @discardableResult
    func updateProfile(name: String, email: String, phone: String) -> Bool {
        guard var user = currentUser else { return false }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty,
              AppState.isPlausibleEmail(trimmedEmail),
              AppState.isPlausiblePhone(trimmedPhone) else {
            return false
        }

        user = UserProfile(
            id: user.id,
            name: trimmedName,
            photoName: user.photoName,
            photoData: user.photoData,
            phone: trimmedPhone,
            email: trimmedEmail,
            walletBalance: user.walletBalance,
            memberSince: user.memberSince,
            savedAddresses: user.savedAddresses
        )
        currentUser = user
        return true
    }

    /// Replaces the profile photo with image data picked from the system
    /// photo library. Pass `nil` to fall back to the initials/symbol avatar.
    func updateProfilePhoto(_ data: Data?) {
        guard var user = currentUser else { return }
        user = UserProfile(
            id: user.id,
            name: user.name,
            photoName: user.photoName,
            photoData: data,
            phone: user.phone,
            email: user.email,
            walletBalance: user.walletBalance,
            memberSince: user.memberSince,
            savedAddresses: user.savedAddresses
        )
        currentUser = user
    }

    // MARK: - Notifications

    @Published private(set) var notifications: [AppNotification] = []
    @Published var notificationPreferences = NotificationPreferences()

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var sortedNotifications: [AppNotification] {
        notifications.sorted { $0.date > $1.date }
    }

    func markNotificationRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
    }

    func markAllNotificationsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
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

    func listing(id: UUID) -> MarketplaceListing? {
        communityListings.first { $0.id == id }
    }

    /// Set by "Arrange OneMart Delivery" on a listing's detail page.
    /// `LogisticsScreen` reads and clears this on appear to pre-fill the
    /// pickup address with where the item actually is, so the buyer only has
    /// to fill in where it's going — the whole point of the button.
    @Published var deliveryDraftPickup: Address?

    /// Seeds a Send booking from a community listing and jumps to the Send
    /// tab. The listing has no street address, only `locationName`, so the
    /// pickup starts as a labeled draft the buyer can still edit or replace
    /// before booking — `AddressEditorView` never treats `initialAddress` as
    /// final.
    func arrangeDelivery(for listing: MarketplaceListing) {
        deliveryDraftPickup = Address(
            label: "\(listing.sellerName)'s listing",
            fullAddress: listing.locationName,
            contactName: listing.sellerName
        )
        activeTab = .logistics
    }

    // MARK: - Orders

    /// Records an order placed in this session (checkout, ride booking, parcel
    /// booking) so it shows up in Home's activity feed.
    func recordOrder(_ order: Order) {
        placedOrders.insert(order, at: 0)
        guard SupabaseConfig.isConfigured else { return }
        Task {
            try? await OrderRepository.insert(order)
        }
    }

    /// This account's own orders only — a fresh signup has an empty feed.
    var activityFeed: [Order] {
        placedOrders.sorted { $0.placedAt > $1.placedAt }
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
        persistWalletPayment(amount: amount, title: title, subtitle: subtitle, module: module)
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
        persistWalletTopUp(amount: amount, methodLabel: methodLabel, ledgerMethod: ledgerMethod)
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

    /// Generates and appends the seller's reply to whatever the buyer just
    /// sent, via `AutoReplyEngine` — a real Gemini-generated reply once
    /// `GeminiConfig.isConfigured`, otherwise a keyword-aware local reply that
    /// still answers using the listing's own title/price/condition. Either
    /// way this replaces the old fully-random canned reply, so the seller's
    /// side of the conversation actually responds to what was asked.
    func respondToBuyer(_ buyerMessage: String, in threadID: UUID) async {
        guard let index = messageThreads.firstIndex(where: { $0.id == threadID }) else { return }
        let thread = messageThreads[index]

        let matchedListing = thread.listingID.flatMap { listing(id: $0) }
        let context = AutoReplyEngine.ListingContext(
            title: matchedListing?.title ?? thread.listingTitle ?? "this item",
            price: matchedListing?.price ?? thread.listingPrice ?? 0,
            isFree: matchedListing?.isFree ?? (thread.listingPrice == 0),
            condition: matchedListing?.condition.rawValue ?? "Good",
            description: matchedListing?.description ?? "",
            sellerName: thread.sellerName
        )

        let reply = await AutoReplyEngine.reply(to: buyerMessage, listing: context)

        // The thread may have been removed, or the index may have shifted,
        // while the reply was being generated — re-resolve by id rather than
        // trusting the captured index.
        guard let freshIndex = messageThreads.firstIndex(where: { $0.id == threadID }) else { return }
        messageThreads[freshIndex].messages.append(
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

    enum AuthValidationError: LocalizedError {
        case missingName
        case invalidEmail
        case invalidPhone
        case weakPassword
        case passwordMismatch

        var errorDescription: String? {
            switch self {
            case .missingName: return "Full name is required."
            case .invalidEmail: return "Enter a valid email address."
            case .invalidPhone: return "Enter a valid mobile number."
            case .weakPassword: return "Password must be at least 8 characters."
            case .passwordMismatch: return "Passwords do not match."
            }
        }
    }

    /// Signs in against real Supabase Auth and loads the resulting profile.
    /// Throws whatever Supabase Auth throws (invalid credentials, network
    /// error, …) — callers show `error.localizedDescription` directly rather
    /// than a canned message, since that's the actual reason it failed.
    func logIn(email: String, password: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        try await AuthRepository.signIn(email: trimmedEmail, password: password)
        try await loadAuthenticatedUser()
        activeTab = .home
        phase = .main
    }

    /// Client-side validation first (every field required, plausible email,
    /// at least 8 characters, matching confirmation — cheap, immediate, no
    /// round trip), then the real Supabase Auth sign-up.
    ///
    /// Deliberately does **not** flip `phase`/`activeTab` itself, even on
    /// `.signedIn` — `currentUser` is loaded and ready, but SignUpScreen
    /// holds its "Account Created!" confirmation on screen for a beat first
    /// and switches phase itself once that beat is over. (`logIn` above
    /// flips phase immediately instead, since Login has no equivalent
    /// on-screen confirmation to hold for.)
    @discardableResult
    func signUp(name: String, email: String, phone: String, password: String, confirmPassword: String) async throws -> AuthRepository.SignUpOutcome {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { throw AuthValidationError.missingName }
        guard AppState.isPlausibleEmail(trimmedEmail) else { throw AuthValidationError.invalidEmail }
        guard AppState.isPlausiblePhone(trimmedPhone) else { throw AuthValidationError.invalidPhone }
        guard password.count >= 8 else { throw AuthValidationError.weakPassword }
        guard password == confirmPassword else { throw AuthValidationError.passwordMismatch }

        let outcome = try await AuthRepository.signUp(name: trimmedName, email: trimmedEmail, phone: trimmedPhone, password: password)
        if outcome == .signedIn {
            try await loadAuthenticatedUser()
        }
        return outcome
    }

    /// Completes the phase switch `signUp(...)` deliberately held back —
    /// called by SignUpScreen once its success confirmation has been on
    /// screen for a beat.
    func enterAppAfterSignUp() {
        activeTab = .home
        phase = .main
    }

    /// Called once from `SplashScreen` at launch — skips Login entirely when
    /// a still-valid Supabase session already exists.
    func restoreSessionIfAvailable() async {
        guard await AuthRepository.hasValidSession() else {
            phase = .login
            return
        }
        do {
            try await loadAuthenticatedUser()
            phase = .main
        } catch {
            // Session existed but the profile fetch failed (migration not
            // applied yet, row deleted, network hiccup) — fall back to
            // Login rather than presenting a signed-in shell with no profile.
            phase = .login
        }
    }

    /// Resets every piece of session state back to logged-out defaults.
    func logOut() async {
        try? await AuthRepository.signOut()
        currentUser = nil
        phase = .login
        activeTab = .home
        showProfile = false
        profileInitialSection = .main
        resetPersonalData(keepingCatalog: true)
        notificationPreferences = NotificationPreferences()
    }

    /// Catalog (food, shop, rides, send, community listings) stays mocked /
    /// browsable. Everything that belongs to *this user* starts empty.
    private func resetPersonalData(keepingCatalog: Bool) {
        foodCart.removeAll()
        shopCart.removeAll()
        favoriteRestaurantIDs.removeAll()
        favoriteProductIDs.removeAll()
        favoriteListingIDs.removeAll()
        walletBalance = 0
        walletTransactions = []
        messageThreads = []
        placedOrders.removeAll()
        notifications = []
        if !keepingCatalog {
            communityListings = MockListings.all
        }
    }

    private func loadAuthenticatedUser() async throws {
        let user = try await AuthRepository.fetchCurrentProfile()
        currentUser = user
        resetPersonalData(keepingCatalog: true)
        communityListings = MockListings.all
        walletBalance = user.walletBalance

        guard SupabaseConfig.isConfigured else { return }
        if let transactions = try? await WalletRepository.fetchTransactions() {
            walletTransactions = transactions
        }
        if let orders = try? await OrderRepository.fetchOrders() {
            placedOrders = orders
        }
    }

    private func persistWalletPayment(amount: Double, title: String, subtitle: String, module: ServiceModule?) {
        guard SupabaseConfig.isConfigured else { return }
        Task {
            _ = try? await WalletRepository.pay(
                amount: amount,
                title: title,
                subtitle: subtitle,
                module: module
            )
        }
    }

    private func persistWalletTopUp(amount: Double, methodLabel: String, ledgerMethod: PaymentMethod) {
        guard SupabaseConfig.isConfigured else { return }
        Task {
            try? await WalletRepository.topUp(
                amount: amount,
                paymentMethod: ledgerMethod.rawValue,
                methodLabel: methodLabel
            )
        }
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
    ///
    /// Deliberately bypasses `logIn(email:password:)` entirely — that now
    /// makes a real network call to Supabase, and a canvas preview should
    /// never depend on network access (or a live project) just to render.
    /// `MockUser.demo` lives on purely as this preview fixture now that real
    /// auth has replaced the old hardcoded-credentials login.
    static var previewSignedIn: AppState {
        let state = AppState()
        state.currentUser = MockUser.demo
        state.walletBalance = MockWallet.seedBalance
        state.walletTransactions = MockWallet.transactions
        state.messageThreads = MockMessages.threads
        state.notifications = MockNotifications.all
        state.activeTab = .home
        state.phase = .main
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
