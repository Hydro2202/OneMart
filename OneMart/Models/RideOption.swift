import Foundation

enum VehicleType: String, Codable, CaseIterable, Identifiable {
    case motorcycle = "Moto"
    case car = "Car"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .motorcycle: return "bicycle" // stand-in glyph; a custom moto icon would live in Assets
        case .car: return "car.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .motorcycle: return "Fast & affordable, 1 passenger"
        case .car: return "Comfortable, up to 4 seats"
        }
    }
}

struct RideOption: Identifiable, Hashable {
    let id: UUID
    let vehicleType: VehicleType
    let etaMinutes: Int
    let fare: Double
    let capacity: Int

    init(
        id: UUID = UUID(),
        vehicleType: VehicleType,
        etaMinutes: Int,
        fare: Double,
        capacity: Int
    ) {
        self.id = id
        self.vehicleType = vehicleType
        self.etaMinutes = etaMinutes
        self.fare = fare
        self.capacity = capacity
    }
}

/// Drives the animated "finding your driver" → "driver found" sequence on the Rides tab.
enum RideSearchState: Equatable {
    case idle
    case searching
    case driverFound(Driver)
}

struct Driver: Identifiable, Hashable {
    let id: UUID
    let name: String
    let photoName: String
    let rating: Double
    let vehicleType: VehicleType
    let vehicleModel: String
    let plateNumber: String
    let etaMinutes: Int

    init(
        id: UUID = UUID(),
        name: String,
        photoName: String,
        rating: Double,
        vehicleType: VehicleType,
        vehicleModel: String,
        plateNumber: String,
        etaMinutes: Int
    ) {
        self.id = id
        self.name = name
        self.photoName = photoName
        self.rating = rating
        self.vehicleType = vehicleType
        self.vehicleModel = vehicleModel
        self.plateNumber = plateNumber
        self.etaMinutes = etaMinutes
    }
}
