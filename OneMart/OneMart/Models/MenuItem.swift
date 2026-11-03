import Foundation

struct MenuItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let imageName: String
    let price: Double
    let isBestSeller: Bool
    let isSpicy: Bool
    let calories: Int?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        imageName: String,
        price: Double,
        isBestSeller: Bool = false,
        isSpicy: Bool = false,
        calories: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
        self.price = price
        self.isBestSeller = isBestSeller
        self.isSpicy = isSpicy
        self.calories = calories
    }
}
