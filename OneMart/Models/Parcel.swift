import Foundation

/// A courier/logistics job — named `Parcel` rather than `Package` to avoid
/// any ambiguity with Swift's own package-manifest vocabulary.
struct Parcel: Identifiable, Hashable {
    let id: UUID
    let trackingCode: String
    let pickupAddress: Address
    let dropoffAddress: Address
    let size: ParcelSize
    let isBulkyFreight: Bool
    let weightKg: Double
    let itemDescription: String
    let fare: Double
    let requestedAt: Date
    let status: ParcelStatus
    let timeline: [ParcelTimelineEvent]

    init(
        id: UUID = UUID(),
        trackingCode: String,
        pickupAddress: Address,
        dropoffAddress: Address,
        size: ParcelSize,
        isBulkyFreight: Bool = false,
        weightKg: Double,
        itemDescription: String,
        fare: Double,
        requestedAt: Date,
        status: ParcelStatus,
        timeline: [ParcelTimelineEvent]
    ) {
        self.id = id
        self.trackingCode = trackingCode
        self.pickupAddress = pickupAddress
        self.dropoffAddress = dropoffAddress
        self.size = size
        self.isBulkyFreight = isBulkyFreight
        self.weightKg = weightKg
        self.itemDescription = itemDescription
        self.fare = fare
        self.requestedAt = requestedAt
        self.status = status
        self.timeline = timeline
    }
}

enum ParcelSize: String, Codable, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case freight = "Bulky / Freight"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .small: return "Fits a shoebox, up to 2 kg"
        case .medium: return "Fits a backpack, up to 8 kg"
        case .large: return "Fits a balikbayan box, up to 20 kg"
        case .freight: return "Furniture, appliances, or multi-item cargo"
        }
    }

    var icon: String {
        switch self {
        case .small: return "shippingbox"
        case .medium: return "shippingbox.fill"
        case .large: return "cube.box.fill"
        case .freight: return "truck.box.fill"
        }
    }
}

/// Steps of the multi-step "send a package" flow.
enum LogisticsStep: Int, CaseIterable {
    case pickup
    case dropoff
    case itemDetails
    case review

    var title: String {
        switch self {
        case .pickup: return "Pickup"
        case .dropoff: return "Drop-off"
        case .itemDetails: return "Item Details"
        case .review: return "Review"
        }
    }
}

enum ParcelStatus: String, Codable, CaseIterable {
    case pickedUp = "Picked Up"
    case inTransit = "In Transit"
    case outForDelivery = "Out for Delivery"
    case delivered = "Delivered"

    var icon: String {
        switch self {
        case .pickedUp: return "shippingbox.fill"
        case .inTransit: return "arrow.triangle.swap"
        case .outForDelivery: return "bicycle"
        case .delivered: return "checkmark.circle.fill"
        }
    }
}

struct ParcelTimelineEvent: Identifiable, Hashable {
    let id: UUID
    let status: ParcelStatus
    let timestamp: Date
    let note: String
    let isCompleted: Bool

    init(
        id: UUID = UUID(),
        status: ParcelStatus,
        timestamp: Date,
        note: String,
        isCompleted: Bool
    ) {
        self.id = id
        self.status = status
        self.timestamp = timestamp
        self.note = note
        self.isCompleted = isCompleted
    }
}

struct Address: Identifiable, Hashable {
    let id: UUID
    let label: String
    let fullAddress: String
    let contactName: String?
    let contactPhone: String?

    init(
        id: UUID = UUID(),
        label: String,
        fullAddress: String,
        contactName: String? = nil,
        contactPhone: String? = nil
    ) {
        self.id = id
        self.label = label
        self.fullAddress = fullAddress
        self.contactName = contactName
        self.contactPhone = contactPhone
    }
}
