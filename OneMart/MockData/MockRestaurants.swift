import Foundation

/// Food & Groceries fixtures — Metro Manila neighbourhoods, ₱ pricing, and a
/// full multi-section menu on **every** restaurant, so the Food tab's
/// restaurant-detail screen has real content to render whichever card the user
/// taps (the grocery store's "menu" is its aisles).
///
/// Everything is `static let` so ids stay stable for the whole session — the
/// favourites sets in `AppState` store these ids.
enum MockRestaurants {

    // MARK: - Menus

    private static let inasalMenu: [MenuSection] = [
        MenuSection(title: "Inasal Favorites", items: [
            MenuItem(
                name: "Chicken Inasal Paa",
                description: "Charcoal-grilled chicken leg quarter basted in annatto oil, served with java rice",
                imageName: "flame.fill",
                price: 189,
                isBestSeller: true,
                calories: 620
            ),
            MenuItem(
                name: "Chicken Inasal Pecho",
                description: "Grilled breast portion, extra juicy, with atchara and soy-calamansi dip",
                imageName: "flame.fill",
                price: 205,
                isBestSeller: true,
                calories: 590
            ),
            MenuItem(
                name: "Pork BBQ Skewers (3 pcs)",
                description: "Sweet-savoury marinated pork, grilled over coals",
                imageName: "flame",
                price: 145,
                isSpicy: false,
                calories: 480
            )
        ]),
        MenuSection(title: "Rice Meals", items: [
            MenuItem(
                name: "Sisig Rice Bowl",
                description: "Sizzling pork sisig over garlic rice, topped with a runny egg",
                imageName: "fork.knife",
                price: 179,
                isSpicy: true,
                calories: 710
            ),
            MenuItem(
                name: "Bicol Express Rice Bowl",
                description: "Pork belly simmered in coconut milk and siling labuyo",
                imageName: "fork.knife",
                price: 169,
                isSpicy: true,
                calories: 650
            ),
            MenuItem(
                name: "Extra Java Rice",
                description: "Annatto-butter rice, unlimited-style serving",
                imageName: "cart.fill",
                price: 45,
                calories: 280
            )
        ]),
        MenuSection(title: "Soups & Sides", items: [
            MenuItem(
                name: "Chicken Tinola",
                description: "Ginger broth with green papaya and dahon ng sili",
                imageName: "cup.and.saucer.fill",
                price: 155,
                calories: 320
            ),
            MenuItem(
                name: "Lumpiang Shanghai (6 pcs)",
                description: "Crispy pork spring rolls with sweet chilli sauce",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 120,
                calories: 410
            )
        ]),
        MenuSection(title: "Drinks & Dessert", items: [
            MenuItem(
                name: "Sago't Gulaman",
                description: "Iced brown-sugar drink with tapioca pearls and jelly",
                imageName: "cup.and.saucer.fill",
                price: 65,
                calories: 190
            ),
            MenuItem(
                name: "Halo-Halo Espesyal",
                description: "Shaved ice, leche flan, ube halaya, and pinipig",
                imageName: "birthday.cake.fill",
                price: 135,
                isBestSeller: true,
                calories: 440
            )
        ])
    ]

    private static let coffeeMenu: [MenuSection] = [
        MenuSection(title: "Kape Barako Bar", items: [
            MenuItem(
                name: "Barako Cold Brew",
                description: "18-hour cold brew from Batangas Liberica beans",
                imageName: "cup.and.saucer.fill",
                price: 155,
                isBestSeller: true,
                calories: 15
            ),
            MenuItem(
                name: "Spanish Latte",
                description: "Double shot with condensed milk over ice",
                imageName: "cup.and.saucer.fill",
                price: 165,
                calories: 240
            ),
            MenuItem(
                name: "Ube Cheesecake Latte",
                description: "Ube halaya syrup, espresso, and salted cheese foam",
                imageName: "cup.and.saucer.fill",
                price: 185,
                calories: 320
            )
        ]),
        MenuSection(title: "Pastries", items: [
            MenuItem(
                name: "Ensaymada Grande",
                description: "Buttery brioche with edam cheese and sugar dust",
                imageName: "birthday.cake.fill",
                price: 110,
                calories: 380
            ),
            MenuItem(
                name: "Pandesal Basket (6 pcs)",
                description: "Freshly baked, served warm with kesong puti",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 95,
                calories: 420
            )
        ])
    ]

    private static let kbbqMenu: [MenuSection] = [
        MenuSection(title: "Samgyeopsal Sets", items: [
            MenuItem(
                name: "Unli Samgyeopsal Set A",
                description: "Pork belly, beef bulgogi, and 6 banchan — good for 2",
                imageName: "flame.fill",
                price: 799,
                isBestSeller: true,
                calories: 1_150
            ),
            MenuItem(
                name: "Spicy Chadolbaegi",
                description: "Thin-sliced beef brisket in gochujang marinade",
                imageName: "flame.fill",
                price: 545,
                isSpicy: true,
                calories: 680
            ),
            MenuItem(
                name: "Cheese Buldak Platter",
                description: "Fire chicken smothered in melted mozzarella",
                imageName: "fish.fill",
                price: 620,
                isSpicy: true,
                calories: 890
            )
        ]),
        MenuSection(title: "Rice & Noodles", items: [
            MenuItem(
                name: "Bibimbap Bowl",
                description: "Rice, seasoned vegetables, egg, and gochujang",
                imageName: "fork.knife",
                price: 385,
                calories: 620
            ),
            MenuItem(
                name: "Japchae",
                description: "Sweet-potato glass noodles with beef and vegetables",
                imageName: "fork.knife",
                price: 340,
                calories: 540
            ),
            MenuItem(
                name: "Kimchi Sinigang Ramyun",
                description: "Korean-Pinoy fusion — ramyun in sour kimchi broth",
                imageName: "cup.and.saucer.fill",
                price: 295,
                isSpicy: true,
                calories: 610
            )
        ]),
        MenuSection(title: "Sides & Drinks", items: [
            MenuItem(
                name: "Egg Roll (Gyeran Mari)",
                description: "Rolled omelette with spring onion",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 165,
                calories: 240
            ),
            MenuItem(
                name: "Peach Soju",
                description: "Chilled bottle, 360ml",
                imageName: "cup.and.saucer.fill",
                price: 220,
                calories: 320
            )
        ])
    ]

    private static let burgerMenu: [MenuSection] = [
        MenuSection(title: "Burgers", items: [
            MenuItem(
                name: "Bayan Quarter Pounder",
                description: "Quarter-pound patty, double cheese, house burger sauce",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 165,
                isBestSeller: true,
                calories: 720
            ),
            MenuItem(
                name: "Sisig Burger",
                description: "Crispy pork sisig patty with calamansi mayo",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 189,
                isSpicy: true,
                calories: 810
            ),
            MenuItem(
                name: "Chicken Fillet Sandwich",
                description: "Buttermilk-fried fillet, pickles, coleslaw",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 155,
                calories: 640
            )
        ]),
        MenuSection(title: "Sides", items: [
            MenuItem(
                name: "Cheesy Fries (Large)",
                description: "Hand-cut fries under a blanket of cheese sauce",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 95,
                isBestSeller: true,
                calories: 520
            ),
            MenuItem(
                name: "Onion Rings (8 pcs)",
                description: "Beer-battered, served with garlic aioli",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 89,
                calories: 430
            )
        ]),
        MenuSection(title: "Drinks & Dessert", items: [
            MenuItem(
                name: "Iced Tea (Bottomless)",
                description: "House-brewed lemon iced tea",
                imageName: "cup.and.saucer.fill",
                price: 55,
                calories: 120
            ),
            MenuItem(
                name: "Ube Soft Serve",
                description: "Swirled cone with pinipig topping",
                imageName: "birthday.cake.fill",
                price: 65,
                calories: 260
            )
        ])
    ]

    private static let lutongBahayMenu: [MenuSection] = [
        MenuSection(title: "Ulam by the Kilo", items: [
            MenuItem(
                name: "Chicken Adobo (1 kilo)",
                description: "Slow-braised in soy, vinegar, and plenty of garlic",
                imageName: "fork.knife",
                price: 420,
                isBestSeller: true,
                calories: 1_240
            ),
            MenuItem(
                name: "Kare-Kare (1 kilo)",
                description: "Oxtail and vegetables in peanut sauce, with bagoong",
                imageName: "fork.knife",
                price: 680,
                calories: 1_480
            ),
            MenuItem(
                name: "Ginataang Gulay (1 kilo)",
                description: "Squash, string beans, and malunggay in coconut milk",
                imageName: "leaf.fill",
                price: 310,
                calories: 720
            )
        ]),
        MenuSection(title: "Solo Meals", items: [
            MenuItem(
                name: "Tapsilog",
                description: "Beef tapa, garlic rice, and a sunny-side-up egg",
                imageName: "fork.knife",
                price: 135,
                isBestSeller: true,
                calories: 690
            ),
            MenuItem(
                name: "Pinakbet Rice Bowl",
                description: "Vegetable stew with a side of steamed rice",
                imageName: "leaf.fill",
                price: 115,
                calories: 480
            )
        ]),
        MenuSection(title: "Merienda", items: [
            MenuItem(
                name: "Palabok Bilao (Small)",
                description: "Rice noodles with shrimp sauce, chicharon, and egg",
                imageName: "takeoutbag.and.cup.and.straw.fill",
                price: 350,
                calories: 980
            ),
            MenuItem(
                name: "Buko Pandan",
                description: "Young coconut and pandan jelly in sweet cream",
                imageName: "birthday.cake.fill",
                price: 85,
                calories: 310
            )
        ])
    ]

    private static let groceryMenu: [MenuSection] = [
        MenuSection(title: "Fresh Produce", items: [
            MenuItem(
                name: "Saba Bananas (1 kilo)",
                description: "Wet-market fresh, picked this morning",
                imageName: "leaf.fill",
                price: 75,
                calories: 890
            ),
            MenuItem(
                name: "Tomatoes (½ kilo)",
                description: "Firm and ripe, ideal for sinigang",
                imageName: "leaf.fill",
                price: 48,
                calories: 90
            ),
            MenuItem(
                name: "Calamansi (¼ kilo)",
                description: "Juicy, thin-skinned, about 25 pieces",
                imageName: "leaf.fill",
                price: 35,
                calories: 40
            )
        ]),
        MenuSection(title: "Meat & Seafood", items: [
            MenuItem(
                name: "Pork Liempo (1 kilo)",
                description: "Skin-on belly, sliced for grilling",
                imageName: "cart.fill",
                price: 340,
                isBestSeller: true,
                calories: 2_600
            ),
            MenuItem(
                name: "Bangus, Deboned (2 pcs)",
                description: "Milkfish, cleaned and butterflied",
                imageName: "fish.fill",
                price: 280,
                calories: 620
            )
        ]),
        MenuSection(title: "Pantry Staples", items: [
            MenuItem(
                name: "Jasmine Rice (5 kilo)",
                description: "Premium fragrant rice, resealable sack",
                imageName: "cart.fill",
                price: 315,
                isBestSeller: true,
                calories: 18_000
            ),
            MenuItem(
                name: "Instant Noodles (12-pack)",
                description: "Assorted flavours, family pack",
                imageName: "cart.fill",
                price: 145,
                calories: 4_200
            ),
            MenuItem(
                name: "Coconut Vinegar 1L",
                description: "Naturally fermented, for adobo and paksiw",
                imageName: "cart.fill",
                price: 62,
                calories: 30
            )
        ]),
        MenuSection(title: "Household", items: [
            MenuItem(
                name: "Laundry Powder 1.5kg",
                description: "Fabric-safe, with a fresh sampaguita scent",
                imageName: "cart.fill",
                price: 189,
                calories: nil
            ),
            MenuItem(
                name: "Dishwashing Liquid 500ml",
                description: "Calamansi scent, cuts through grease",
                imageName: "cart.fill",
                price: 98,
                calories: nil
            )
        ])
    ]

    // MARK: - Restaurants

    static let lolaNenas = Restaurant(
        name: "Lola Nena's Inasal Grill",
        imageName: "flame.fill",
        photoAssetName: "rest_lolaNenas",
        categories: [.filipino, .streetFood],
        neighborhood: "Poblacion, Makati",
        rating: 4.8,
        ratingCount: 2_412,
        etaMinutesRange: 20...30,
        deliveryFee: 39,
        isPromoted: true,
        priceLevel: 2,
        distanceKm: 1.4,
        tagline: "Charcoal-grilled inasal, unli java rice",
        menu: inasalMenu
    )

    static let kapeKalye = Restaurant(
        name: "Kape Kalye Coffee Bar",
        imageName: "cup.and.saucer.fill",
        photoAssetName: "rest_kapeKalye",
        categories: [.coffee, .desserts],
        neighborhood: "Katipunan, Quezon City",
        rating: 4.7,
        ratingCount: 1_180,
        etaMinutesRange: 15...25,
        deliveryFee: 29,
        priceLevel: 2,
        distanceKm: 2.1,
        tagline: "Single-origin barako, baked fresh daily",
        menu: coffeeMenu
    )

    static let titaBaby = Restaurant(
        name: "Tita Baby's Lutong Bahay",
        imageName: "fork.knife",
        photoAssetName: "rest_titaBaby",
        categories: [.filipino, .healthy],
        neighborhood: "San Juan City",
        rating: 4.6,
        ratingCount: 864,
        etaMinutesRange: 25...40,
        deliveryFee: 45,
        priceLevel: 1,
        distanceKm: 3.6,
        tagline: "Home-cooked ulam, packed by the kilo",
        menu: lutongBahayMenu
    )

    static let seoulSarap = Restaurant(
        name: "Seoul Sarap KBBQ",
        imageName: "fish.fill",
        photoAssetName: "rest_seoulSarap",
        categories: [.koreanJapanese],
        neighborhood: "BGC, Taguig",
        rating: 4.9,
        ratingCount: 3_051,
        etaMinutesRange: 30...45,
        deliveryFee: 59,
        isPromoted: true,
        priceLevel: 3,
        distanceKm: 5.2,
        tagline: "Samgyeopsal sets and Korean-Pinoy fusion",
        menu: kbbqMenu
    )

    static let jollyBurger = Restaurant(
        name: "Burger Bayan Express",
        imageName: "takeoutbag.and.cup.and.straw.fill",
        photoAssetName: "rest_jollyBurger",
        categories: [.fastFood],
        neighborhood: "España, Manila",
        rating: 4.4,
        ratingCount: 5_782,
        etaMinutesRange: 15...25,
        deliveryFee: 25,
        priceLevel: 1,
        distanceKm: 0.9,
        tagline: "Cheesy quarter-pounders and fries, 24/7",
        menu: burgerMenu
    )

    static let superSarap = Restaurant(
        name: "SuperSarap Palengke Mart",
        imageName: "cart.fill",
        photoAssetName: "rest_superSarap",
        categories: [.grocery, .healthy],
        neighborhood: "Mandaluyong City",
        rating: 4.5,
        ratingCount: 1_923,
        etaMinutesRange: 40...60,
        deliveryFee: 49,
        priceLevel: 2,
        distanceKm: 4.4,
        isGroceryStore: true,
        tagline: "Wet-market fresh, delivered same day",
        menu: groceryMenu
    )

    static let all: [Restaurant] = [
        lolaNenas, kapeKalye, seoulSarap, jollyBurger, titaBaby, superSarap
    ]

    static let promoted: [Restaurant] = all.filter { $0.isPromoted }

    static func restaurants(in category: FoodCategory) -> [Restaurant] {
        guard category != .all else { return all }
        return all.filter { $0.categories.contains(category) }
    }

    static func restaurant(id: UUID) -> Restaurant? {
        all.first { $0.id == id }
    }
}
