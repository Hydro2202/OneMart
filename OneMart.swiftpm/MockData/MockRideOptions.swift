import Foundation

/// Rides fixtures — the two vehicle tiers offered on a typical Metro Manila
/// hop, plus the drivers the "finding your driver" animation settles on.
enum MockRideOptions {
    static let all: [RideOption] = [
        RideOption(vehicleType: .motorcycle, etaMinutes: 4, fare: 120, capacity: 1),
        RideOption(vehicleType: .car, etaMinutes: 9, fare: 285, capacity: 4)
    ]

    static let drivers: [Driver] = [
        Driver(
            name: "Ariel Bautista",
            photoName: "person.crop.circle.fill",
            rating: 4.92,
            vehicleType: .motorcycle,
            vehicleModel: "Honda Click 160",
            plateNumber: "NBX 4821",
            etaMinutes: 4
        ),
        Driver(
            name: "Roderick Salazar",
            photoName: "person.crop.circle.fill",
            rating: 4.88,
            vehicleType: .car,
            vehicleModel: "Toyota Vios · Silver",
            plateNumber: "CAB 7734",
            etaMinutes: 9
        ),
        Driver(
            name: "Melvin Aguilar",
            photoName: "person.crop.circle.fill",
            rating: 4.97,
            vehicleType: .motorcycle,
            vehicleModel: "Yamaha Mio i125",
            plateNumber: "MJP 1290",
            etaMinutes: 3
        )
    ]

    /// Popular saved destinations shown as quick-pick chips on the Rides tab.
    static let popularDestinations: [Address] = [
        Address(label: "BGC High Street", fullAddress: "9th Ave cor. 28th St, Taguig City"),
        Address(label: "NAIA Terminal 3", fullAddress: "Andrews Ave, Pasay City"),
        Address(label: "Ayala Triangle", fullAddress: "Makati Ave, Makati CBD"),
        Address(label: "Trinoma", fullAddress: "EDSA cor. North Ave, Quezon City")
    ]

    static func driver(for vehicleType: VehicleType) -> Driver {
        drivers.first { $0.vehicleType == vehicleType } ?? drivers[0]
    }
}
