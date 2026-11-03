import SwiftUI

/// A parcel's status card + timeline.
///
/// Used twice on the Send tab: once for the parcel the user has just booked,
/// and once for `MockParcelAddresses.activeParcel`, the one already in flight.
/// The timeline animates in — the progress rail grows to the last completed
/// event and the rows stagger in behind it — so the screen reads as *live*
/// rather than as a static list.
struct ParcelTrackingCard: View {
    let parcel: Parcel
    var accent: Color = AppColor.amber
    /// Set for the freshly booked parcel so the timeline replays on appear.
    var animatesOnAppear: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            header
            Divider().overlay(AppColor.borderSubtle)
            ParcelTimeline(events: parcel.timeline, accent: accent, animatesOnAppear: animatesOnAppear)
        }
        .padding(AppSpacing.md)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: parcel.size.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 46, height: 46)
                    .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 3) {
                    Text(parcel.trackingCode)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                    Text(parcel.itemDescription)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                        .lineLimit(2)
                    TagPill(text: parcel.status.rawValue, icon: parcel.status.icon, tint: accent)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(AppFormat.peso(parcel.fare))
                        .appTextStyle(AppTextStyle.subheadline, color: accent)
                    Text(String(format: "%.1f kg · %@", parcel.weightKg, parcel.size.rawValue))
                        .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                }
            }

            routeLine
        }
    }

    private var routeLine: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            VStack(spacing: 2) {
                Circle().fill(AppColor.jade).frame(width: 8, height: 8)
                Rectangle().fill(AppColor.borderSubtle).frame(width: 1, height: 22)
                Circle().fill(AppColor.coral).frame(width: 8, height: 8)
            }
            .padding(.top, 5)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                addressLine(parcel.pickupAddress)
                addressLine(parcel.dropoffAddress)
            }

            Spacer(minLength: 0)
        }
    }

    private func addressLine(_ address: Address) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(address.label)
                .appTextStyle(AppTextStyle.caption, color: AppColor.textPrimary)
            Text(address.fullAddress)
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
                .lineLimit(1)
        }
    }
}

/// The vertical status rail: one row per `ParcelTimelineEvent`, each carrying
/// its own node and the connector down to the next one, so the rail can never
/// fall out of sync with the rows.
///
/// Completed steps get a filled node and a coloured connector; the first
/// pending step is badged "Now". Rows stagger in on appear (and skip straight
/// to their final state when Reduce Motion is on).
struct ParcelTimeline: View {
    let events: [ParcelTimelineEvent]
    var accent: Color = AppColor.amber
    var animatesOnAppear: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedCount = 0

    var body: some View {
        VStack(spacing: 0) {
            ForEach(events.indices, id: \.self) { index in
                row(events[index], at: index, isRevealed: index < revealedCount)
            }
        }
        .onAppear(perform: reveal)
    }

    private func row(_ event: ParcelTimelineEvent, at index: Int, isRevealed: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(spacing: 0) {
                node(event)
                if index < events.count - 1 {
                    Capsule()
                        .fill(connectorIsFilled(after: index) ? accent : AppColor.borderSubtle)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)
                }
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(event.status.rawValue)
                        .appTextStyle(
                            AppTextStyle.callout,
                            color: event.isCompleted ? AppColor.textPrimary : AppColor.textSecondary
                        )
                    if isCurrent(event) {
                        TagPill(text: "Now", tint: accent)
                    }
                }
                Text(event.note)
                    .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(AppFormat.orderTimestamp(event.timestamp))
                    .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
            }
            .padding(.bottom, index < events.count - 1 ? AppSpacing.sm : 0)

            Spacer(minLength: 0)
        }
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.status.rawValue). \(event.note). \(AppFormat.orderTimestamp(event.timestamp))")
    }

    private func node(_ event: ParcelTimelineEvent) -> some View {
        ZStack {
            Circle()
                .stroke(
                    isCurrent(event) ? accent : AppColor.borderSubtle,
                    lineWidth: isCurrent(event) ? 2 : 1
                )
                .frame(width: 24, height: 24)

            Circle()
                .fill(event.isCompleted ? accent : AppColor.backgroundTertiary)
                .frame(width: 18, height: 18)

            if event.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(AppColor.onAccent)
            }
        }
        .frame(width: 24, height: 26)
    }

    /// A connector is coloured only when the step *below* it is also done.
    private func connectorIsFilled(after index: Int) -> Bool {
        guard index + 1 < events.count else { return false }
        return events[index].isCompleted && events[index + 1].isCompleted
    }

    /// The first not-yet-completed step is "Now" — where the parcel is headed.
    private func isCurrent(_ event: ParcelTimelineEvent) -> Bool {
        guard let firstPending = events.first(where: { !$0.isCompleted }) else { return false }
        return firstPending.id == event.id
    }

    private func reveal() {
        guard animatesOnAppear, !reduceMotion else {
            revealedCount = events.count
            return
        }

        revealedCount = 0
        Task { @MainActor in
            for index in events.indices {
                try? await Task.sleep(nanoseconds: 160_000_000)
                withAnimation(AppMotion.springSnappy) {
                    revealedCount = index + 1
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        ParcelTrackingCard(parcel: MockParcelAddresses.activeParcel)
            .padding(AppSpacing.md)
    }
    .background(AppColor.backgroundPrimary)
}
