import SwiftUI

/// Rides tab — pick a destination, pick a vehicle, watch the fare and ETA move
/// with both, then book.
///
/// The booking sequence is driven by `RideSearchState`: `idle` → `searching`
/// (animated ripple while a driver is matched) → `driverFound(Driver)`. Money
/// only moves on the final confirm, which runs through the same
/// `PaymentMethodPicker` (Cash on Delivery vs. OneMart Wallet) as every other
/// checkout in the app and settles through `AppState.payFromWallet`.
struct RidesScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pickup: Address = MockParcelAddresses.pickupSuggestions[0]
    @State private var destination: RideDestination = RideDestination.all[0]
    @State private var vehicleType: VehicleType = .motorcycle
    @State private var searchState: RideSearchState = .idle
    @State private var paymentSelection: PaymentMethod = .cashOnDelivery
    @State private var errorMessage: String?
    @State private var bookedRide: BookedRide?

    @State private var showsDestinationPicker = false
    @State private var showsPickupPicker = false
    @State private var showsTopUp = false

    /// Snapshot of a confirmed booking, kept so the receipt survives a reset of
    /// the search state.
    private struct BookedRide: Identifiable {
        let id = UUID()
        let driver: Driver
        let fare: Double
        let method: PaymentMethod
        let destination: String
    }

    private var option: RideOption {
        MockRideOptions.all.first { $0.vehicleType == vehicleType } ?? MockRideOptions.all[0]
    }

    private var fare: Double { destination.fare(for: option) }
    private var tripMinutes: Int { destination.tripMinutes(for: vehicleType) }

    private var canConfirm: Bool {
        appState.canPay(with: paymentSelection, amount: fare)
    }

    var body: some View {
        VStack(spacing: 0) {
            AppShellHeader(title: "Rides", subtitle: "Moto and car, booked in seconds")

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    RideMapView(isMoving: bookedRide == nil)
                        .background(AppColor.jade.opacity(0.08))

                    routeCard
                        .padding(.horizontal, AppSpacing.md)
                        .offset(y: -AppSpacing.lg)
                        .padding(.bottom, -AppSpacing.lg)

                    if let bookedRide {
                        bookedCard(bookedRide)
                            .padding(.horizontal, AppSpacing.md)
                    } else {
                        vehiclePicker
                            .padding(.horizontal, AppSpacing.md)

                        fareCard
                            .padding(.horizontal, AppSpacing.md)

                        stateSection
                            .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .animation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion), value: searchState)
        .animation(AppMotion.easeStandard, value: bookedRide?.id)
        .sheet(isPresented: $showsDestinationPicker) {
            AddressPickSheet(
                title: "Where to?",
                options: RideDestination.all.map { AddressOption($0.address, subtitle: $0.subtitle) },
                selectedID: destination.id
            ) { address in
                if let match = RideDestination.all.first(where: { $0.address.id == address.id }) {
                    destination = match
                    resetSearch()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsPickupPicker) {
            AddressPickSheet(
                title: "Pick-up point",
                options: MockParcelAddresses.pickupSuggestions.map { AddressOption($0, subtitle: $0.fullAddress) },
                selectedID: pickup.id
            ) { address in
                pickup = address
                resetSearch()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showsTopUp) {
            WalletTopUpView()
        }
    }

    // MARK: - Route

    private var routeCard: some View {
        VStack(spacing: AppSpacing.xs) {
            routeRow(
                icon: "location.fill",
                tint: AppColor.jade,
                label: "PICKUP",
                value: pickup.fullAddress,
                action: { showsPickupPicker = true }
            )

            HStack(spacing: AppSpacing.sm) {
                Rectangle()
                    .fill(AppColor.borderSubtle)
                    .frame(width: 1, height: 14)
                    .padding(.leading, 17)
                Rectangle()
                    .fill(AppColor.borderSubtle)
                    .frame(height: 1)
            }

            routeRow(
                icon: "mappin.circle.fill",
                tint: AppColor.coral,
                label: "DROP-OFF",
                value: destination.address.label,
                detail: destination.address.fullAddress,
                action: { showsDestinationPicker = true }
            )
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.card)
    }

    private func routeRow(
        icon: String,
        tint: Color,
        label: String,
        value: String,
        detail: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                        .tracking(0.8)
                    Text(value)
                        .appTextStyle(AppTextStyle.callout)
                        .lineLimit(1)
                    if let detail {
                        Text(detail)
                            .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(label.capitalized): \(value). Tap to change.")
    }

    // MARK: - Vehicle

    private var vehiclePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: "Choose a ride")

            ForEach(MockRideOptions.all) { rideOption in
                let isSelected = rideOption.vehicleType == vehicleType
                Button {
                    withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                        vehicleType = rideOption.vehicleType
                        resetSearch()
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: rideOption.vehicleType.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? AppColor.coral : AppColor.textSecondary)
                            .frame(width: 46, height: 46)
                            .background(
                                (isSelected ? AppColor.coral : AppColor.textTertiary).opacity(0.14),
                                in: RoundedRectangle(cornerRadius: AppRadius.sm)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rideOption.vehicleType.rawValue)
                                .appTextStyle(AppTextStyle.bodyEmphasis)
                            Text(rideOption.vehicleType.subtitle)
                                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                            Text("\(rideOption.etaMinutes) min to reach you · \(destination.tripMinutes(for: rideOption.vehicleType)) min trip")
                                .appTextStyle(AppTextStyle.caption2, color: AppColor.jade)
                        }

                        Spacer(minLength: 0)

                        Text(AppFormat.peso(destination.fare(for: rideOption)))
                            .appTextStyle(AppTextStyle.title2, color: isSelected ? AppColor.coral : AppColor.textPrimary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(isSelected ? AppColor.coral : AppColor.borderSubtle, lineWidth: isSelected ? 1.8 : 1)
                    )
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
    }

    // MARK: - Fare

    private var fareCard: some View {
        HStack(spacing: 0) {
            fareCell(label: "Estimated fare", value: AppFormat.peso(fare), tint: AppColor.coral, isLarge: true)
            Rectangle().fill(AppColor.borderSubtle).frame(width: 1, height: 36)
            fareCell(label: "Distance", value: String(format: "%.1f km", destination.distanceKm), tint: AppColor.textPrimary)
            Rectangle().fill(AppColor.borderSubtle).frame(width: 1, height: 36)
            fareCell(label: "Trip time", value: "\(tripMinutes) min", tint: AppColor.jade)
        }
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private func fareCell(label: String, value: String, tint: Color, isLarge: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            Text(value)
                .font(isLarge ? AppTextStyle.title2 : AppTextStyle.subheadline)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Search / driver states

    @ViewBuilder
    private var stateSection: some View {
        switch searchState {
        case .idle:
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                PaymentMethodPicker(selection: $paymentSelection, amountDue: fare) {
                    showsTopUp = true
                }

                if let errorMessage {
                    InlineBanner(kind: .error, message: errorMessage)
                }

                PrimaryButton(
                    title: "Find a Ride · \(AppFormat.peso(fare))",
                    systemImage: "magnifyingglass",
                    isEnabled: canConfirm,
                    action: findRide
                )
            }

        case .searching:
            searchingCard

        case .driverFound(let driver):
            driverFoundCard(driver)
        }
    }

    private var searchingCard: some View {
        VStack(spacing: AppSpacing.sm) {
            PulsingBeacon()

            Text("Finding your driver…")
                .appTextStyle(AppTextStyle.title2)

            Text("3 \(vehicleType.rawValue.lowercased()) drivers nearby · usually under \(option.etaMinutes) minutes")
                .appTextStyle(AppTextStyle.footnote, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)

            SecondaryButton(title: "Cancel") { resetSearch() }
                .frame(maxWidth: 220)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private func driverFoundCard(_ driver: Driver) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Driver found!")
                    .font(AppTextStyle.subheadline)
                Spacer(minLength: 0)
                Text("\(driver.etaMinutes) min away")
                    .font(AppTextStyle.subheadline)
            }
            .foregroundStyle(AppColor.onAccent)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.jade)

            VStack(spacing: AppSpacing.sm) {
                DriverRow(driver: driver)

                HStack(spacing: 0) {
                    detailCell(label: "Plate", value: driver.plateNumber)
                    Rectangle().fill(AppColor.borderSubtle).frame(width: 1, height: 30)
                    detailCell(label: "Vehicle", value: driver.vehicleModel)
                    Rectangle().fill(AppColor.borderSubtle).frame(width: 1, height: 30)
                    detailCell(label: "Fare", value: AppFormat.peso(fare), tint: AppColor.coral)
                }
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.backgroundTertiary, in: RoundedRectangle(cornerRadius: AppRadius.sm))

                PaymentMethodPicker(selection: $paymentSelection, amountDue: fare) {
                    showsTopUp = true
                }

                if let errorMessage {
                    InlineBanner(kind: .error, message: errorMessage)
                }

                PrimaryButton(
                    title: paymentSelection == .cashOnDelivery
                        ? "Confirm Ride · Pay \(AppFormat.peso(fare)) Cash"
                        : "Confirm & Pay \(AppFormat.peso(fare))",
                    systemImage: "checkmark",
                    isEnabled: canConfirm
                ) {
                    confirmBooking(with: driver)
                }

                SecondaryButton(title: "Cancel Ride") { resetSearch() }
            }
            .padding(AppSpacing.sm)
        }
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColor.jade, lineWidth: 1.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.card)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func bookedCard(_ ride: BookedRide) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.success.opacity(0.14))
                    .frame(width: 88, height: 88)
                Image(systemName: "car.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppColor.success)
            }

            Text("\(ride.driver.name) is on the way")
                .appTextStyle(AppTextStyle.title2)
                .multilineTextAlignment(.center)

            Text("\(ride.driver.vehicleModel) · \(ride.driver.plateNumber) · arriving in \(ride.driver.etaMinutes) min")
                .appTextStyle(AppTextStyle.footnote, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)

            Text(ride.method == .cashOnDelivery
                 ? "Pay \(AppFormat.pesoPrecise(ride.fare)) in cash at \(ride.destination)."
                 : "\(AppFormat.pesoPrecise(ride.fare)) paid from your wallet. Balance \(AppFormat.pesoPrecise(appState.walletBalance)).")
                .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)

            SecondaryButton(title: "Book Another Ride", systemImage: "arrow.counterclockwise") {
                bookedRide = nil
                resetSearch()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.card)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private func detailCell(label: String, value: String, tint: Color = AppColor.textPrimary) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            Text(value)
                .appTextStyle(AppTextStyle.caption, color: tint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func findRide() {
        errorMessage = nil
        searchState = .searching

        let matchedDriver = MockRideOptions.driver(for: vehicleType)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            // Ignore a match that lands after the user cancelled.
            guard searchState == .searching else { return }
            withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                searchState = .driverFound(matchedDriver)
            }
        }
    }

    private func confirmBooking(with driver: Driver) {
        errorMessage = nil

        if paymentSelection == .oneMartWallet {
            let paid = appState.payFromWallet(
                amount: fare,
                title: "Ride to \(destination.address.label)",
                subtitle: "\(pickup.label) → \(destination.address.label) · \(vehicleType.rawValue)",
                module: .rides
            )
            guard paid else {
                errorMessage = "Not enough wallet balance — you're \(AppFormat.pesoPrecise(appState.shortfall(for: fare))) short. Top up or switch to Cash."
                return
            }
        }

        appState.recordOrder(
            Order(
                module: .rides,
                title: "Ride to \(destination.address.label)",
                subtitle: "\(pickup.label) → \(destination.address.label) · \(vehicleType.rawValue)",
                imageName: vehicleType.icon,
                status: .onTheWay,
                total: fare,
                placedAt: Date()
            )
        )

        bookedRide = BookedRide(
            driver: driver,
            fare: fare,
            method: paymentSelection,
            destination: destination.address.label
        )
        searchState = .idle
    }

    private func resetSearch() {
        searchState = .idle
        errorMessage = nil
    }
}

// MARK: - Destination

/// A `MockRideOptions.popularDestinations` address plus the trip distance,
/// which is what turns the flat per-vehicle base fare into a fare that responds
/// to where the user is actually going.
struct RideDestination: Identifiable, Hashable {
    let address: Address
    let distanceKm: Double

    var id: UUID { address.id }

    /// Base fare covers a ~6 km hop; everything else scales off that.
    func fare(for option: RideOption) -> Double {
        (option.fare * (0.5 + distanceKm / 12.4)).rounded()
    }

    func tripMinutes(for vehicleType: VehicleType) -> Int {
        let averageSpeed: Double = vehicleType == .motorcycle ? 22 : 16
        return max(4, Int((distanceKm / averageSpeed * 60).rounded()))
    }

    var subtitle: String {
        String(format: "%.1f km · %@", distanceKm, address.fullAddress)
    }

    static let all: [RideDestination] = {
        let distances: [Double] = [6.2, 12.6, 3.8, 9.3]
        return MockRideOptions.popularDestinations.enumerated().map { index, address in
            RideDestination(address: address, distanceKm: distances[index % distances.count])
        }
    }()
}

// MARK: - Small shared pieces

/// Concentric pulsing rings — the "matching you with a driver" beacon.
struct PulsingBeacon: View {
    var tint: Color = AppColor.coral
    var icon: String = "magnifyingglass"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(tint.opacity(0.28))
                    .frame(width: 64, height: 64)
                    .scaleEffect(isAnimating ? 1.9 : 1)
                    .opacity(isAnimating ? 0 : 0.6)
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.9),
                        value: isAnimating
                    )
            }

            Circle()
                .fill(tint)
                .frame(width: 64, height: 64)

            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColor.onAccent)
        }
        .frame(width: 96, height: 96)
        .onAppear { isAnimating = true }
        .accessibilityHidden(true)
    }
}

/// Driver identity row, shared by the driver-found card and any driver list.
struct DriverRow: View {
    let driver: Driver

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: driver.photoName)
                .font(.system(size: 30))
                .foregroundStyle(AppColor.jade)
                .frame(width: 52, height: 52)
                .background(AppColor.jade.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(driver.name)
                    .appTextStyle(AppTextStyle.bodyEmphasis)
                RatingLabel(rating: driver.rating, decimals: 2)
                Text(driver.vehicleModel)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }
}

/// One row in an `AddressPickSheet`: the address plus the secondary line to
/// show beneath it.
struct AddressOption: Identifiable {
    let address: Address
    let subtitle: String

    var id: UUID { address.id }

    init(_ address: Address, subtitle: String) {
        self.address = address
        self.subtitle = subtitle
    }
}

/// Reusable address chooser used by Rides (pickup + destination).
struct AddressPickSheet: View {
    let title: String
    let options: [AddressOption]
    let selectedID: UUID?
    let onSelect: (Address) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(options) { option in
                        let address = option.address
                        let subtitle = option.subtitle
                        Button {
                            onSelect(address)
                            dismiss()
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: address.id == selectedID ? "mappin.circle.fill" : "mappin.circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(address.id == selectedID ? AppColor.coral : AppColor.textTertiary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(address.label)
                                        .appTextStyle(AppTextStyle.bodyEmphasis)
                                    Text(subtitle)
                                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer(minLength: 0)

                                if address.id == selectedID {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(AppColor.coral)
                                }
                            }
                            .padding(AppSpacing.sm)
                            .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(address.id == selectedID ? AppColor.coral : AppColor.borderSubtle, lineWidth: address.id == selectedID ? 1.6 : 1)
                            )
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RidesScreen()
    }
    .environmentObject(AppState.previewSignedIn)
}
