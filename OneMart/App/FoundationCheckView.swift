import SwiftUI

/// TEMPORARY placeholder root view — exists only so the project builds and
/// the Theme + Models foundation can be visually verified. This gets
/// replaced by `RootTabView` (the 5-tab shell) once we start building Home.
struct FoundationCheckView: View {
    private let sampleOrders = [
        Order(module: .food, title: "Mang Inasal - Paypay Branch", subtitle: "2 items", imageName: "fork.knife", status: .onTheWay, total: 245, placedAt: .now),
        Order(module: .rides, title: "Ride to BGC", subtitle: "Motorcycle • 12 min", imageName: "car.fill", status: .completed, total: 89, placedAt: .now),
        Order(module: .logistics, title: "Parcel to Cebu City", subtitle: "Medium box • 3.2 kg", imageName: "shippingbox.fill", status: .preparing, total: 180, placedAt: .now)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("OneMart")
                    .appTextStyle(AppTextStyle.largeTitle)
                Text("Foundation check — Theme + Models")
                    .appTextStyle(AppTextStyle.subheadline, color: AppColor.textSecondary)

                colorSwatches
                typeScale
                orderCards
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }

    private var colorSwatches: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Palette").appTextStyle(AppTextStyle.headline)
            HStack(spacing: AppSpacing.sm) {
                swatch("Coral", AppColor.coral)
                swatch("Jade", AppColor.jade)
                swatch("Amber", AppColor.amber)
            }
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(color)
                .frame(height: 56)
                .appShadow(.card)
            Text(name).appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var typeScale: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("Type Scale").appTextStyle(AppTextStyle.headline)
            Text("Large Title").appTextStyle(AppTextStyle.largeTitle)
            Text("Title").appTextStyle(AppTextStyle.title)
            Text("Headline").appTextStyle(AppTextStyle.headline)
            Text("Body — dense list text uses standard SF Pro").appTextStyle(AppTextStyle.body)
            Text("Caption").appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
        }
    }

    private var orderCards: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Sample unified activity (Order model)").appTextStyle(AppTextStyle.headline)
            ForEach(sampleOrders) { order in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: order.imageName)
                        .foregroundStyle(order.module.tintColor)
                        .frame(width: 36, height: 36)
                        .background(order.module.tintColor.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.title).appTextStyle(AppTextStyle.bodyEmphasis)
                        Text(order.subtitle).appTextStyle(AppTextStyle.caption, color: AppColor.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("₱\(order.total, specifier: "%.0f")").appTextStyle(AppTextStyle.bodyEmphasis)
                        Text(order.status.rawValue).appTextStyle(AppTextStyle.caption2, color: order.status.tintColor)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColor.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.md))
                .appShadow(.subtle)
            }
        }
    }
}

#Preview {
    FoundationCheckView()
}
