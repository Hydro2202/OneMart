import SwiftUI

/// Logistics tab — labelled **Send** in the tab bar.
///
/// A four-step booking flow driven by `LogisticsStep`
/// (pickup → drop-off → item details → review) with a progress indicator,
/// then a live tracking timeline once the parcel is booked.
///
/// Both addresses are **fully editable**: each opens `AddressEditorView`, where
/// the user can start from the address book or type a brand-new address, and
/// the values entered flow all the way through review, payment, and the
/// tracking screen. Nothing on this tab is hardcoded.
struct LogisticsScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Which end of the journey the address editor is open for.
    private enum ParcelEnd: String, Identifiable {
        case pickup
        case dropoff

        var id: String { rawValue }
    }

    @State private var step: LogisticsStep = .pickup
    @State private var pickup: Address?
    @State private var dropoff: Address?
    @State private var size: ParcelSize = .medium
    @State private var weightKg: Double = 3
    @State private var itemDescription = ""
    @State private var paymentSelection: PaymentMethod = .cashOnDelivery
    @State private var errorMessage: String?
    @State private var bookedParcel: Parcel?
    @State private var editingEnd: ParcelEnd?
    @State private var showsTopUp = false

    // MARK: - Pricing

    private static let insuranceFee: Double = 20
    private static let overweightRatePerKg: Double = 18

    /// Weight included in each tier's base fare, from `ParcelSize.detail`.
    private var includedWeight: Double {
        switch size {
        case .small: return 2
        case .medium: return 8
        case .large: return 20
        case .freight: return 100
        }
    }

    private var baseFare: Double { MockParcelAddresses.estimatedFare(for: size) }

    private var overweightFee: Double {
        (max(0, weightKg - includedWeight) * Self.overweightRatePerKg).rounded()
    }

    private var total: Double { baseFare + overweightFee + Self.insuranceFee }

    // MARK: - Step validation

    private var canAdvance: Bool {
        switch step {
        case .pickup:
            return pickup != nil
        case .dropoff:
            return dropoff != nil && dropoff?.fullAddress != pickup?.fullAddress
        case .itemDetails:
            return itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
        case .review:
            return appState.canPay(with: paymentSelection, amount: total)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppShellHeader(
                title: "Send",
                subtitle: bookedParcel == nil
                    ? "Same-day parcels and bulky freight"
                    : "Tracking your delivery"
            )

            if bookedParcel == nil {
                progressIndicator
            }

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if let bookedParcel {
                        trackingContent(bookedParcel)
                    } else {
                        stepContent
                    }
                }
                .padding(AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: step)
        .animation(AppMotion.easeStandard, value: bookedParcel?.id)
        .onAppear(perform: consumeDeliveryDraftIfNeeded)
        .sheet(item: $editingEnd) { end in
            AddressEditorView(
                title: end == .pickup ? "Pickup address" : "Drop-off address",
                tint: end == .pickup ? AppColor.jade : AppColor.coral,
                suggestions: end == .pickup
                    ? MockParcelAddresses.pickupSuggestions
                    : MockParcelAddresses.dropoffSuggestions,
                initialAddress: end == .pickup ? pickup : dropoff
            ) { address in
                if end == .pickup {
                    pickup = address
                } else {
                    dropoff = address
                }
            }
        }
        .sheet(isPresented: $showsTopUp) {
            WalletTopUpView()
        }
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        VStack(spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xxs) {
                ForEach(LogisticsStep.allCases, id: \.rawValue) { candidate in
                    Capsule()
                        .fill(candidate.rawValue <= step.rawValue ? AppColor.amber : AppColor.borderSubtle)
                        .frame(height: 5)
                }
            }

            HStack(spacing: AppSpacing.xxs) {
                ForEach(LogisticsStep.allCases, id: \.rawValue) { candidate in
                    Text(candidate.title)
                        .font(AppTextStyle.caption2)
                        .foregroundStyle(candidate.rawValue <= step.rawValue ? AppColor.amber : AppColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step.rawValue + 1) of \(LogisticsStep.allCases.count): \(step.title)")
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .pickup:
            addressStep(
                end: .pickup,
                title: "Where should we pick up?",
                subtitle: "Tap the card to choose a saved address or type a new one.",
                address: pickup,
                icon: "arrow.up.circle.fill",
                tint: AppColor.jade
            )

            if let activeParcel = inFlightParcel {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SectionHeader(title: "Already on its way", subtitle: "Your parcel in flight right now")
                    ParcelTrackingCard(parcel: activeParcel, animatesOnAppear: false)
                }
            }

            stepButtons()

        case .dropoff:
            addressStep(
                end: .dropoff,
                title: "Where is it going?",
                subtitle: "The recipient's address and contact details.",
                address: dropoff,
                icon: "arrow.down.circle.fill",
                tint: AppColor.coral
            )

            if dropoff != nil, dropoff?.fullAddress == pickup?.fullAddress {
                InlineBanner(kind: .error, message: "Pickup and drop-off can't be the same address.")
            }

            routePreview

            stepButtons()

        case .itemDetails:
            itemDetailsStep
            stepButtons()

        case .review:
            reviewStep
            stepButtons()
        }
    }

    private func addressStep(
        end: ParcelEnd,
        title: String,
        subtitle: String,
        address: Address?,
        icon: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeader(title: title, subtitle: subtitle)

            Button {
                editingEnd = end
            } label: {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 44, height: 44)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 3) {
                        if let address {
                            Text(address.label)
                                .appTextStyle(AppTextStyle.bodyEmphasis)
                            Text(address.fullAddress)
                                .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                                .multilineTextAlignment(.leading)
                            if let contact = address.contactName {
                                Text([contact, address.contactPhone].compactMap { $0 }.joined(separator: " · "))
                                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                            }
                        } else {
                            Text("Add an address")
                                .appTextStyle(AppTextStyle.bodyEmphasis, color: AppColor.textSecondary)
                            Text("Pick from your address book or enter a new one")
                                .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: address == nil ? "plus.circle.fill" : "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .padding(AppSpacing.sm)
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(address == nil ? AppColor.borderSubtle : tint, lineWidth: address == nil ? 1 : 1.6)
                )
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(address == nil ? "Add \(end.rawValue) address" : "Edit \(end.rawValue) address, currently \(address?.fullAddress ?? "")")

            // Quick picks so the common case is one tap, while the editor stays
            // available for anything else.
            let suggestions = end == .pickup
                ? MockParcelAddresses.pickupSuggestions
                : MockParcelAddresses.dropoffSuggestions

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(suggestions) { suggestion in
                        FilterChip(
                            title: suggestion.label,
                            icon: "bookmark.fill",
                            isSelected: address?.fullAddress == suggestion.fullAddress,
                            tint: tint
                        ) {
                            if end == .pickup {
                                pickup = suggestion
                            } else {
                                dropoff = suggestion
                            }
                        }
                    }

                    FilterChip(title: "New address", icon: "plus", isSelected: false, tint: tint) {
                        editingEnd = end
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var routePreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.amber)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pickup?.label ?? "Pickup") → \(dropoff?.label ?? "Drop-off")")
                        .appTextStyle(AppTextStyle.callout)
                    Text("Distance-based pricing · same-day within Metro Manila")
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.sm)
            .background(AppColor.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
    }

    private var itemDetailsStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SectionHeader(title: "What are you sending?", subtitle: "Pick the size that fits your item.")

                ForEach(ParcelSize.allCases) { candidate in
                    let isSelected = size == candidate
                    Button {
                        withAnimation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion)) {
                            size = candidate
                            weightKg = min(weightKg, defaultWeight(for: candidate))
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: candidate.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isSelected ? AppColor.amber : AppColor.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(
                                    (isSelected ? AppColor.amber : AppColor.textTertiary).opacity(0.14),
                                    in: RoundedRectangle(cornerRadius: AppRadius.sm)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.rawValue)
                                    .appTextStyle(AppTextStyle.bodyEmphasis)
                                Text(candidate.detail)
                                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Text("from \(AppFormat.peso(MockParcelAddresses.estimatedFare(for: candidate)))")
                                .appTextStyle(AppTextStyle.caption, color: AppColor.amber)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(isSelected ? AppColor.amber : AppColor.borderSubtle, lineWidth: isSelected ? 1.8 : 1)
                        )
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }

            weightControl

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                AppTextField(
                    label: "What's inside?",
                    placeholder: "Documents, a pair of sneakers…",
                    text: $itemDescription,
                    icon: "shippingbox.fill"
                )
                Text("Riders need a short description for handling and insurance.")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
            }
        }
    }

    private var weightControl: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("Approximate weight")
                    .appTextStyle(AppTextStyle.headline)
                Spacer()
                Text(String(format: "%.1f kg", weightKg))
                    .appTextStyle(AppTextStyle.subheadline, color: AppColor.amber)
                    .monospacedDigit()
            }

            Slider(value: $weightKg, in: 0.5...50, step: 0.5)
                .tint(AppColor.amber)
                .accessibilityLabel("Approximate weight in kilograms")

            if overweightFee > 0 {
                Text("\(String(format: "%.1f", weightKg - includedWeight)) kg over the \(size.rawValue) allowance · +\(AppFormat.peso(overweightFee))")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.warning)
            } else {
                Text("Within the \(size.rawValue) allowance of \(String(format: "%.0f", includedWeight)) kg.")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textTertiary)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SectionHeader(title: "Review your booking", subtitle: "Tap any row to change it.")

                VStack(spacing: 0) {
                    reviewRow(
                        icon: "arrow.up.circle.fill",
                        tint: AppColor.jade,
                        label: "Pickup",
                        value: pickup?.label ?? "—",
                        detail: pickup?.fullAddress
                    ) { step = .pickup }

                    Divider().overlay(AppColor.borderSubtle)

                    reviewRow(
                        icon: "arrow.down.circle.fill",
                        tint: AppColor.coral,
                        label: "Drop-off",
                        value: dropoff?.label ?? "—",
                        detail: dropoff?.fullAddress
                    ) { step = .dropoff }

                    Divider().overlay(AppColor.borderSubtle)

                    reviewRow(
                        icon: size.icon,
                        tint: AppColor.amber,
                        label: "Parcel",
                        value: "\(size.rawValue) · \(String(format: "%.1f", weightKg)) kg",
                        detail: itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    ) { step = .itemDetails }
                }
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                .appShadow(.subtle)
            }

            fareBreakdown

            PaymentMethodPicker(selection: $paymentSelection, amountDue: total) {
                showsTopUp = true
            }

            if let errorMessage {
                InlineBanner(kind: .error, message: errorMessage)
            }
        }
    }

    private func reviewRow(
        icon: String,
        tint: Color,
        label: String,
        value: String,
        detail: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                        .tracking(0.8)
                    Text(value)
                        .appTextStyle(AppTextStyle.callout)
                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(label): \(value). Tap to edit.")
    }

    private var fareBreakdown: some View {
        VStack(spacing: AppSpacing.xs) {
            fareRow(label: "\(size.rawValue) delivery fee", value: AppFormat.pesoPrecise(baseFare))
            if overweightFee > 0 {
                fareRow(label: "Overweight surcharge", value: AppFormat.pesoPrecise(overweightFee))
            }
            fareRow(label: "Parcel insurance", value: AppFormat.pesoPrecise(Self.insuranceFee))
            Divider().overlay(AppColor.borderSubtle)
            HStack {
                Text("Total")
                    .appTextStyle(AppTextStyle.headline)
                Spacer()
                Text(AppFormat.pesoPrecise(total))
                    .appTextStyle(AppTextStyle.title2, color: AppColor.amber)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private func fareRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
            Spacer()
            Text(value)
                .appTextStyle(AppTextStyle.bodyEmphasis)
        }
    }

    // MARK: - Step buttons

    @ViewBuilder
    private func stepButtons() -> some View {
        HStack(spacing: AppSpacing.sm) {
            if step != .pickup {
                SecondaryButton(title: "Back", systemImage: "chevron.left") {
                    goBack()
                }
            }

            if step == .review {
                PrimaryButton(
                    title: paymentSelection == .cashOnDelivery
                        ? "Book · Pay \(AppFormat.peso(total)) Cash"
                        : "Book & Pay \(AppFormat.peso(total))",
                    systemImage: "checkmark",
                    tint: AppColor.amber,
                    isEnabled: canAdvance,
                    action: confirmBooking
                )
            } else {
                PrimaryButton(
                    title: "Continue",
                    systemImage: "chevron.right",
                    tint: AppColor.amber,
                    isEnabled: canAdvance,
                    action: goNext
                )
            }
        }
        .padding(.top, AppSpacing.xxs)
    }

    // MARK: - Tracking

    @ViewBuilder
    private func trackingContent(_ parcel: Parcel) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColor.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Booking confirmed!")
                    .appTextStyle(AppTextStyle.headline, color: AppColor.success)
                Text("Tracking ID \(parcel.trackingCode) · \(paymentSelection == .cashOnDelivery ? "pay the rider in cash" : "paid from your wallet")")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.success.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.md))

        ParcelTrackingCard(parcel: parcel)

        riderCard

        if let activeParcel = inFlightParcel {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SectionHeader(title: "Your other parcel", subtitle: "Still in transit")
                ParcelTrackingCard(parcel: activeParcel, animatesOnAppear: false)
            }
        }

        SecondaryButton(title: "Send Another Package", systemImage: "plus") {
            resetFlow()
        }
    }

    private var riderCard: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(AppColor.amber)
                .frame(width: 48, height: 48)
                .background(AppColor.amber.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Mark Dizon")
                    .appTextStyle(AppTextStyle.bodyEmphasis)
                Text("Your rider · Honda TMX 125")
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                RatingLabel(rating: 4.8)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    /// The seeded in-flight parcel, hidden once it would duplicate the parcel
    /// the user just booked.
    private var inFlightParcel: Parcel? {
        let parcel = MockParcelAddresses.activeParcel
        return parcel.trackingCode == bookedParcel?.trackingCode ? nil : parcel
    }

    // MARK: - Actions

    /// Picks up the pickup-address draft "Arrange OneMart Delivery" leaves on
    /// `AppState` (from a Community listing) and clears it immediately after,
    /// so it only ever applies once and a later, unrelated visit to Send
    /// starts clean.
    private func consumeDeliveryDraftIfNeeded() {
        guard pickup == nil, let draft = appState.deliveryDraftPickup else { return }
        pickup = draft
        appState.deliveryDraftPickup = nil
    }

    private func goNext() {
        guard canAdvance,
              let next = LogisticsStep(rawValue: step.rawValue + 1) else { return }
        errorMessage = nil
        step = next
    }

    private func goBack() {
        guard let previous = LogisticsStep(rawValue: step.rawValue - 1) else { return }
        errorMessage = nil
        step = previous
    }

    private func confirmBooking() {
        guard let pickup, let dropoff else { return }
        errorMessage = nil

        if paymentSelection == .oneMartWallet {
            let paid = appState.payFromWallet(
                amount: total,
                title: "Parcel to \(dropoff.label)",
                subtitle: "\(pickup.label) → \(dropoff.label) · \(size.rawValue)",
                module: .logistics
            )
            guard paid else {
                errorMessage = "Not enough wallet balance — you're \(AppFormat.pesoPrecise(appState.shortfall(for: total))) short. Top up or switch to Cash on Delivery."
                return
            }
        }

        let now = Date()
        let trackingCode = "OM-\(Int.random(in: 1_000...9_999))-\(Int.random(in: 1_000...9_999))"
        let description = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let parcel = Parcel(
            trackingCode: trackingCode,
            pickupAddress: pickup,
            dropoffAddress: dropoff,
            size: size,
            isBulkyFreight: size == .freight,
            weightKg: weightKg,
            itemDescription: description,
            fare: total,
            requestedAt: now,
            status: .pickedUp,
            timeline: makeTimeline(from: now, pickup: pickup, dropoff: dropoff)
        )

        appState.recordOrder(
            Order(
                module: .logistics,
                title: "Same-Day Parcel · \(trackingCode)",
                subtitle: "\(pickup.label) → \(dropoff.label)",
                imageName: size.icon,
                status: .onTheWay,
                total: total,
                placedAt: now
            )
        )

        bookedParcel = parcel
    }

    private func makeTimeline(from now: Date, pickup: Address, dropoff: Address) -> [ParcelTimelineEvent] {
        [
            ParcelTimelineEvent(
                status: .pickedUp,
                timestamp: now,
                note: "Rider assigned and heading to \(pickup.label)",
                isCompleted: true
            ),
            ParcelTimelineEvent(
                status: .inTransit,
                timestamp: now.addingTimeInterval(30 * 60),
                note: "On the way to the sorting hub",
                isCompleted: false
            ),
            ParcelTimelineEvent(
                status: .outForDelivery,
                timestamp: now.addingTimeInterval(85 * 60),
                note: "Out for delivery around \(dropoff.label)",
                isCompleted: false
            ),
            ParcelTimelineEvent(
                status: .delivered,
                timestamp: now.addingTimeInterval(140 * 60),
                note: "Estimated hand-off to \(dropoff.contactName ?? dropoff.label)",
                isCompleted: false
            )
        ]
    }

    private func resetFlow() {
        bookedParcel = nil
        step = .pickup
        pickup = nil
        dropoff = nil
        size = .medium
        weightKg = 3
        itemDescription = ""
        paymentSelection = .cashOnDelivery
        errorMessage = nil
    }

    private func defaultWeight(for size: ParcelSize) -> Double {
        switch size {
        case .small: return 2
        case .medium: return 8
        case .large: return 20
        case .freight: return 50
        }
    }
}

#Preview {
    NavigationStack {
        LogisticsScreen()
    }
    .environmentObject(AppState.previewSignedIn)
}
