import SwiftUI

/// Checkout payment selector, shared by Food, Rides, Send, and Market.
///
/// Checkout only ever offers two of the four `PaymentMethod` cases — Cash on
/// Delivery and the OneMart Wallet — so the picker constrains itself to
/// `PaymentMethodPicker.checkoutOptions` rather than iterating `allCases`.
///
/// The wallet row shows the live balance and, when it can't cover `amountDue`,
/// warns inline and offers a Top Up shortcut. Callers decide whether their
/// confirm button is enabled with `appState.canPay(with:amount:)`.
struct PaymentMethodPicker: View {
    /// The only methods valid at checkout.
    static let checkoutOptions: [PaymentMethod] = [.cashOnDelivery, .oneMartWallet]

    @Binding var selection: PaymentMethod
    let amountDue: Double
    /// Invoked when the user taps "Top Up" on the insufficient-balance warning.
    /// Defaults to deep-linking Profile's wallet section — pass your own when
    /// the picker sits inside a sheet, so the sheet can be dismissed first.
    var onTopUp: (() -> Void)?

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var walletCovers: Bool { appState.hasSufficientBalance(for: amountDue) }
    private var walletIsShort: Bool { selection == .oneMartWallet && !walletCovers }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Payment Method")
                .appTextStyle(AppTextStyle.headline)

            ForEach(Self.checkoutOptions) { method in
                optionRow(method)
            }

            if walletIsShort {
                shortfallWarning
            }
        }
        .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: selection)
        .animation(AppMotion.easeStandard, value: walletIsShort)
    }

    private func optionRow(_ method: PaymentMethod) -> some View {
        let isSelected = selection == method
        return Button {
            selection = method
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: method.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColor.coral : AppColor.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        (isSelected ? AppColor.coral : AppColor.textTertiary).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: AppRadius.sm)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.rawValue)
                        .appTextStyle(AppTextStyle.bodyEmphasis)
                    Text(subtitle(for: method))
                        .appTextStyle(AppTextStyle.caption, color: subtitleColor(for: method))
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColor.coral : AppColor.borderSubtle, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppColor.coral)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
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

    private func subtitle(for method: PaymentMethod) -> String {
        switch method {
        case .cashOnDelivery:
            return "Pay the rider when your order arrives"
        case .oneMartWallet:
            return "Balance \(AppFormat.pesoPrecise(appState.walletBalance))"
        default:
            return method.rawValue
        }
    }

    private func subtitleColor(for method: PaymentMethod) -> Color {
        if method == .oneMartWallet && !walletCovers { return AppColor.error }
        return AppColor.textSecondary
    }

    private var shortfallWarning: some View {
        HStack(alignment: .center, spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.error)

            Text("You're \(AppFormat.pesoPrecise(appState.shortfall(for: amountDue))) short. Top up to pay with your wallet.")
                .appTextStyle(AppTextStyle.caption, color: AppColor.error)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                if let onTopUp {
                    onTopUp()
                } else {
                    appState.openWallet()
                }
            } label: {
                Text("Top Up")
                    .font(AppTextStyle.badge)
                    .foregroundStyle(AppColor.onAccent)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColor.coral, in: Capsule())
            }
            .buttonStyle(.pressable)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.error.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        .transition(.opacity)
    }
}

extension AppState {
    /// Whether the chosen checkout method can actually settle `amount` right
    /// now. Cash on Delivery always can; the wallet needs the balance.
    func canPay(with method: PaymentMethod, amount: Double) -> Bool {
        method == .oneMartWallet ? hasSufficientBalance(for: amount) : true
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        PaymentMethodPicker(selection: .constant(.oneMartWallet), amountDue: 480)
        PaymentMethodPicker(selection: .constant(.oneMartWallet), amountDue: 9_999)
    }
    .padding(AppSpacing.md)
    .background(AppColor.backgroundPrimary)
    .environmentObject(AppState.previewSignedIn)
}
