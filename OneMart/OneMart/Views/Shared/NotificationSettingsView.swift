import SwiftUI

/// Real, working notification preferences — five independent toggles bound
/// straight to `AppState.notificationPreferences`, so they persist for the
/// rest of the session (not just while this screen is on screen).
struct NotificationSettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Choose what OneMart can notify you about. You can change these any time.")
                        .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                }

                toggleRow(
                    icon: "shippingbox.fill",
                    tint: AppColor.amber,
                    title: "Order Updates",
                    subtitle: "Preparing, on the way, delivered — for Food and Send",
                    isOn: Binding(
                        get: { appState.notificationPreferences.orderUpdates },
                        set: { appState.notificationPreferences.orderUpdates = $0 }
                    )
                )

                toggleRow(
                    icon: "car.fill",
                    tint: AppColor.coral,
                    title: "Ride Updates",
                    subtitle: "Driver found, arriving, trip started",
                    isOn: Binding(
                        get: { appState.notificationPreferences.rideAndDeliveryUpdates },
                        set: { appState.notificationPreferences.rideAndDeliveryUpdates = $0 }
                    )
                )

                toggleRow(
                    icon: "bolt.fill",
                    tint: AppColor.amber,
                    title: "Promotions & Deals",
                    subtitle: "Flash sales, vouchers, and free-delivery days",
                    isOn: Binding(
                        get: { appState.notificationPreferences.promotionsAndDeals },
                        set: { appState.notificationPreferences.promotionsAndDeals = $0 }
                    )
                )

                toggleRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    tint: AppColor.jade,
                    title: "Chat Messages",
                    subtitle: "New messages from Marketplace sellers and buyers",
                    isOn: Binding(
                        get: { appState.notificationPreferences.chatMessages },
                        set: { appState.notificationPreferences.chatMessages = $0 }
                    )
                )

                toggleRow(
                    icon: "wallet.pass.fill",
                    tint: AppColor.jade,
                    title: "Wallet Activity",
                    subtitle: "Top-ups, payments, and refunds",
                    isOn: Binding(
                        get: { appState.notificationPreferences.walletActivity },
                        set: { appState.notificationPreferences.walletActivity = $0 }
                    )
                )
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleRow(icon: String, tint: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                    Text(subtitle)
                        .appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(AppColor.coral)
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environmentObject(AppState.previewSignedIn)
}
