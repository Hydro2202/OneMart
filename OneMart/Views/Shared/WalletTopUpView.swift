import SwiftUI

/// Wallet cash-in flow, shared by **both** entry points: Home's wallet card and
/// Profile's Wallet section. It owns no navigation of its own beyond its three
/// internal steps, so either caller can present it as a `.sheet` and get the
/// same behaviour.
///
/// Steps: choose amount + method → pay (QR placeholder for the e-wallet rails,
/// a form for bank/card) → success. Confirming calls
/// `AppState.topUpWallet(amount:method:)`, so the balance and the transaction
/// list update everywhere at once.
struct WalletTopUpView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Step: Equatable {
        case selectAmount
        case pay
        case success
    }

    private static let presetAmounts: [Double] = [500, 1_000, 2_000, 5_000]

    @State private var step: Step = .selectAmount
    @State private var amount: Double = 500
    @State private var customAmount = ""
    @State private var method: TopUpMethod = .gcash

    // Form fields (mock — nothing is validated against a real processor).
    @State private var bankName = ""
    @State private var bankAccount = ""
    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""
    @State private var cardHolder = ""

    @State private var toppedUpAmount: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        balanceCard

                        switch step {
                        case .selectAmount: selectStep
                        case .pay: payStep
                        case .success: successStep
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Top Up Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step == .pay {
                        Button("Back") {
                            withAnimation(AppMotion.easeStandard) { step = .selectAmount }
                        }
                        .foregroundStyle(AppColor.coral)
                    }
                }
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
            .animation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion), value: step)
        }
    }

    // MARK: - Balance

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("CURRENT BALANCE")
                .font(AppTextStyle.caption2)
                .tracking(1)
                .foregroundStyle(AppColor.onAccent.opacity(0.75))
            Text(AppFormat.pesoPrecise(appState.walletBalance))
                .font(AppFont.rounded(30, weight: .bold))
                .foregroundStyle(AppColor.onAccent)
            HStack(spacing: AppSpacing.xxs) {
                Circle()
                    .fill(AppColor.success)
                    .frame(width: 7, height: 7)
                Text("Verified · Escrow Protected")
                    .font(AppTextStyle.caption)
                    .foregroundStyle(AppColor.onAccent.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [AppColor.coral, AppColor.amber],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppRadius.lg)
        )
        .appShadow(.card)
    }

    // MARK: - Step 1 — amount + method

    private var selectStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Select Amount")
                    .appTextStyle(AppTextStyle.headline)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: AppSpacing.xs),
                                    GridItem(.flexible(), spacing: AppSpacing.xs)],
                          spacing: AppSpacing.xs) {
                    ForEach(Self.presetAmounts, id: \.self) { preset in
                        amountButton(preset)
                    }
                }

                AppTextField(
                    label: "Other amount",
                    placeholder: "Enter an amount",
                    text: $customAmount,
                    icon: "pesosign.circle.fill",
                    keyboardType: .numberPad
                )
                .onChange(of: customAmount) { newValue in
                    if let parsed = Double(newValue.filter({ $0.isNumber })), parsed > 0 {
                        amount = parsed
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Payment Method")
                    .appTextStyle(AppTextStyle.headline)

                ForEach(TopUpMethod.allCases) { option in
                    methodRow(option)
                }
            }

            PrimaryButton(
                title: "Continue · \(AppFormat.peso(amount))",
                systemImage: "arrow.right",
                isEnabled: amount > 0
            ) {
                withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
                    step = .pay
                }
            }
        }
    }

    private func amountButton(_ preset: Double) -> some View {
        let isSelected = amount == preset
        return Button {
            amount = preset
            customAmount = ""
        } label: {
            Text(AppFormat.peso(preset))
                .font(AppTextStyle.buttonLabel)
                .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    isSelected ? AppColor.coral : AppColor.backgroundSecondary,
                    in: RoundedRectangle(cornerRadius: AppRadius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(isSelected ? AppColor.coral : AppColor.borderSubtle, lineWidth: 1.5)
                )
        }
        .buttonStyle(.pressable)
    }

    private func methodRow(_ option: TopUpMethod) -> some View {
        let isSelected = method == option
        return Button {
            method = option
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: option.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(
                        isSelected ? AppColor.onAccent.opacity(0.2) : AppColor.backgroundTertiary,
                        in: RoundedRectangle(cornerRadius: AppRadius.sm)
                    )

                Text(option.displayName)
                    .font(AppTextStyle.bodyEmphasis)
                    .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textPrimary)

                Spacer(minLength: 0)

                Text(option.flowHint)
                    .font(AppTextStyle.caption)
                    .foregroundStyle(isSelected ? AppColor.onAccent.opacity(0.8) : AppColor.textTertiary)
            }
            .padding(AppSpacing.sm)
            .background(
                isSelected ? AppColor.coral : AppColor.backgroundSecondary,
                in: RoundedRectangle(cornerRadius: AppRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? AppColor.coral : AppColor.borderSubtle, lineWidth: 1.5)
            )
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Step 2 — pay

    private var payStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Pay via \(method.displayName)")
                    .appTextStyle(AppTextStyle.headline)
                Spacer()
                Button("Change") {
                    withAnimation(AppMotion.easeStandard) { step = .selectAmount }
                }
                .font(AppTextStyle.subheadline)
                .foregroundStyle(AppColor.coral)
            }

            switch method.flow {
            case .qrCode: qrPane
            case .bankForm: bankForm
            case .cardForm: cardForm
            }

            amountDueRow

            PrimaryButton(
                title: method.flow == .qrCode ? "I've Paid · Simulate Payment" : "Confirm Top-Up \(AppFormat.peso(amount))",
                systemImage: "checkmark"
            ) {
                completeTopUp()
            }
        }
    }

    private var qrPane: some View {
        VStack(spacing: AppSpacing.sm) {
            QRPlaceholder()
                .frame(width: 200, height: 200)
                .padding(AppSpacing.md)
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(AppColor.borderSubtle, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                )

            Text("Scan with the \(method.displayName) app")
                .appTextStyle(AppTextStyle.footnote, color: AppColor.textSecondary)
            Text("Sample QR — this prototype does not process real payments.")
                .appTextStyle(AppTextStyle.caption2, color: AppColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var bankForm: some View {
        VStack(spacing: AppSpacing.sm) {
            AppTextField(
                label: "Bank",
                placeholder: "BDO, BPI, UnionBank…",
                text: $bankName,
                icon: "building.columns.fill",
                autocapitalization: .words
            )
            AppTextField(
                label: "Account Number",
                placeholder: "1234 5678 9012",
                text: $bankAccount,
                icon: "number",
                keyboardType: .numberPad
            )
        }
    }

    private var cardForm: some View {
        VStack(spacing: AppSpacing.sm) {
            AppTextField(
                label: "Name on Card",
                placeholder: "Maria Santos",
                text: $cardHolder,
                icon: "person.fill",
                textContentType: .name,
                autocapitalization: .words
            )
            AppTextField(
                label: "Card Number",
                placeholder: "1234 5678 9012 3456",
                text: $cardNumber,
                icon: "creditcard.fill",
                keyboardType: .numberPad,
                textContentType: .creditCardNumber
            )
            HStack(spacing: AppSpacing.sm) {
                AppTextField(
                    label: "Expiry",
                    placeholder: "MM/YY",
                    text: $cardExpiry,
                    keyboardType: .numbersAndPunctuation
                )
                AppTextField(
                    label: "CVV",
                    placeholder: "123",
                    text: $cardCVV,
                    isSecure: true,
                    keyboardType: .numberPad
                )
            }
        }
    }

    private var amountDueRow: some View {
        HStack {
            Text("Amount to pay")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
            Spacer()
            Text(AppFormat.pesoPrecise(amount))
                .appTextStyle(AppTextStyle.title2, color: AppColor.coral)
        }
        .padding(AppSpacing.md)
        .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow(.subtle)
    }

    // MARK: - Step 3 — success

    private var successStep: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.success.opacity(0.14))
                    .frame(width: 92, height: 92)
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(AppColor.success)
            }
            .padding(.top, AppSpacing.md)

            Text("Top-Up Successful!")
                .appTextStyle(AppTextStyle.title)
            Text("\(AppFormat.pesoPrecise(toppedUpAmount)) added via \(method.displayName).")
                .appTextStyle(AppTextStyle.callout, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Text("New balance \(AppFormat.pesoPrecise(appState.walletBalance))")
                .appTextStyle(AppTextStyle.headline, color: AppColor.coral)
                .padding(.top, AppSpacing.xxs)

            VStack(spacing: AppSpacing.xs) {
                PrimaryButton(title: "Done") { dismiss() }
                SecondaryButton(title: "Top Up Again") {
                    withAnimation(AppMotion.easeStandard) {
                        step = .selectAmount
                    }
                }
            }
            .padding(.top, AppSpacing.md)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func completeTopUp() {
        guard amount > 0 else { return }
        appState.topUpWallet(amount: amount, method: method)
        toppedUpAmount = amount
        withAnimation(AppMotion.adaptive(AppMotion.springBouncy, reduceMotion: reduceMotion)) {
            step = .success
        }
    }
}

/// A decorative stand-in for a scannable QR code: three finder squares plus a
/// deterministic module pattern. Never encodes anything real.
struct QRPlaceholder: View {
    private let modules = 21

    var body: some View {
        GeometryReader { proxy in
            let cell = min(proxy.size.width, proxy.size.height) / CGFloat(modules)
            ZStack(alignment: .topLeading) {
                ForEach(0..<modules, id: \.self) { row in
                    ForEach(0..<modules, id: \.self) { column in
                        if isFilled(row: row, column: column) {
                            Rectangle()
                                .fill(AppColor.textPrimary.opacity(0.85))
                                .frame(width: cell, height: cell)
                                .offset(x: CGFloat(column) * cell, y: CGFloat(row) * cell)
                        }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func isFilled(row: Int, column: Int) -> Bool {
        if isFinderPattern(row: row, column: column) { return true }
        if isInsideFinderArea(row: row, column: column) { return false }
        return (row * 7 + column * 13 + row * column) % 5 < 2
    }

    private func isInsideFinderArea(row: Int, column: Int) -> Bool {
        let inTop = row < 8
        let inLeft = column < 8
        let inRight = column >= modules - 8
        let inBottom = row >= modules - 8
        return (inTop && inLeft) || (inTop && inRight) || (inBottom && inLeft)
    }

    private func isFinderPattern(row: Int, column: Int) -> Bool {
        let origins = [(0, 0), (0, modules - 7), (modules - 7, 0)]
        for origin in origins {
            let localRow = row - origin.0
            let localColumn = column - origin.1
            guard (0..<7).contains(localRow), (0..<7).contains(localColumn) else { continue }
            let isBorder = localRow == 0 || localRow == 6 || localColumn == 0 || localColumn == 6
            let isCore = (2...4).contains(localRow) && (2...4).contains(localColumn)
            if isBorder || isCore { return true }
        }
        return false
    }
}

#Preview {
    WalletTopUpView()
        .environmentObject(AppState.previewSignedIn)
}
