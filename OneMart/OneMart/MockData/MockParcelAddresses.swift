import Foundation

/// Logistics ("Send") fixtures — pickup/drop-off address book plus one parcel
/// that is already in flight so the tracking timeline has something real to
/// render.
enum MockParcelAddresses {
    static let pickupSuggestions: [Address] = [
        Address(
            label: "Home",
            fullAddress: "123 Mabini St, Malate, Manila 1004",
            contactName: "Maria Santos",
            contactPhone: "+63 917 123 4567"
        ),
        Address(
            label: "Work",
            fullAddress: "27F Ayala North Exchange, Ayala Ave, Makati CBD",
            contactName: "Maria Santos",
            contactPhone: "+63 917 123 4567"
        ),
        Address(
            label: "Shop — Divisoria",
            fullAddress: "Stall 214, 168 Mall, Recto Ave, Manila",
            contactName: "Tindahan ni Aling Rosa",
            contactPhone: "+63 922 884 1120"
        )
    ]

    static let dropoffSuggestions: [Address] = [
        Address(
            label: "Parents",
            fullAddress: "45 Sampaguita Rd, Project 6, Quezon City",
            contactName: "Rosalinda Santos",
            contactPhone: "+63 918 442 0091"
        ),
        Address(
            label: "Kuya Ben",
            fullAddress: "Blk 7 Lot 12, Greenwoods Exec Village, Pasig City",
            contactName: "Benjie Santos",
            contactPhone: "+63 995 220 7781"
        ),
        Address(
            label: "Cebu Branch",
            fullAddress: "Unit 5, Banilad Town Centre, Cebu City",
            contactName: "Liza Ferrer",
            contactPhone: "+63 932 118 5540"
        )
    ]

    /// A parcel currently in transit — powers the "Track your parcel" card.
    static let activeParcel = Parcel(
        trackingCode: "OM-4471-8823",
        pickupAddress: pickupSuggestions[0],
        dropoffAddress: dropoffSuggestions[1],
        size: .medium,
        weightKg: 3.2,
        itemDescription: "Documents and a pair of sneakers",
        fare: 165,
        requestedAt: MockDate.hoursAgo(6),
        status: .inTransit,
        timeline: [
            ParcelTimelineEvent(
                status: .pickedUp,
                timestamp: MockDate.hoursAgo(6),
                note: "Rider collected the parcel in Malate",
                isCompleted: true
            ),
            ParcelTimelineEvent(
                status: .inTransit,
                timestamp: MockDate.hoursAgo(4),
                note: "At the Mandaluyong sorting hub",
                isCompleted: true
            ),
            ParcelTimelineEvent(
                status: .outForDelivery,
                timestamp: MockDate.hoursAgo(1),
                note: "Rider assigned for Pasig deliveries",
                isCompleted: false
            ),
            ParcelTimelineEvent(
                status: .delivered,
                timestamp: MockDate.hoursFromNow(1.5),
                note: "Estimated hand-off to Benjie Santos",
                isCompleted: false
            )
        ]
    )

    /// Indicative pricing per size, used by the Send flow's fare estimate.
    static let fareBySize: [ParcelSize: Double] = [
        .small: 95,
        .medium: 165,
        .large: 260,
        .freight: 780
    ]

    static func estimatedFare(for size: ParcelSize) -> Double {
        fareBySize[size] ?? 95
    }
}
