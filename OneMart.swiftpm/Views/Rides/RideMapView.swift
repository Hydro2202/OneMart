import SwiftUI

/// A stylised, non-interactive map for the Rides tab.
///
/// There is no MapKit here on purpose — the prototype has no real coordinates,
/// and a hand-drawn street grid keeps the screen on-brand and offline. The
/// vehicle glyph rides the same `Path` the route is stroked with, so the dot
/// and the line can never drift apart.
struct RideMapView: View {
    var isMoving: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    private let horizontalStreets: [CGFloat] = [0.16, 0.42, 0.70, 0.94]
    private let verticalStreets: [CGFloat] = [0.16, 0.32, 0.47, 0.65, 0.81, 0.93]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let route = routePath(in: size)

            ZStack {
                AppColor.jade.opacity(0.10)

                streets(in: size)
                blocks(in: size)

                route
                    .stroke(AppColor.coral.opacity(0.18), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                route
                    .stroke(AppColor.coral, style: StrokeStyle(lineWidth: 4, lineCap: .round))

                pickupPin(in: size)
                dropoffPin(in: size)

                vehicleDot
                    .modifier(FollowPath(progress: progress, path: route))
            }
            .onAppear { startAnimating() }
            .onChange(of: isMoving) { _ in startAnimating() }
        }
        .frame(height: 190)
        .clipped()
        .accessibilityElement()
        .accessibilityLabel("Map showing the route from your pickup point to your destination")
    }

    // MARK: - Pieces

    private func streets(in size: CGSize) -> some View {
        ZStack {
            ForEach(horizontalStreets.indices, id: \.self) { index in
                Rectangle()
                    .fill(AppColor.backgroundPrimary.opacity(0.9))
                    .frame(width: size.width, height: 11)
                    .position(x: size.width / 2, y: size.height * horizontalStreets[index])
            }
            ForEach(verticalStreets.indices, id: \.self) { index in
                Rectangle()
                    .fill(AppColor.backgroundPrimary.opacity(0.9))
                    .frame(width: 9, height: size.height)
                    .position(x: size.width * verticalStreets[index], y: size.height / 2)
            }
        }
    }

    /// City blocks between the streets — purely decorative.
    private func blocks(in size: CGSize) -> some View {
        let spots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.21, 0.24, 0.09, 0.14),
            (0.36, 0.24, 0.08, 0.14),
            (0.53, 0.24, 0.09, 0.14),
            (0.70, 0.26, 0.08, 0.10),
            (0.21, 0.53, 0.09, 0.13),
            (0.53, 0.52, 0.09, 0.14),
            (0.86, 0.50, 0.07, 0.15),
            (0.36, 0.79, 0.08, 0.11),
            (0.70, 0.80, 0.09, 0.10)
        ]

        return ZStack {
            ForEach(spots.indices, id: \.self) { index in
                let spot = spots[index]
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColor.jade.opacity(0.16))
                    .frame(width: size.width * spot.2, height: size.height * spot.3)
                    .position(x: size.width * spot.0, y: size.height * spot.1)
            }
        }
    }

    private func pickupPin(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(AppColor.jade.opacity(0.25))
                .frame(width: 26, height: 26)
            Circle()
                .fill(AppColor.jade)
                .frame(width: 14, height: 14)
            Circle()
                .fill(AppColor.onAccent)
                .frame(width: 6, height: 6)
        }
        .position(routeStart(in: size))
    }

    private func dropoffPin(in size: CGSize) -> some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(AppColor.coral)
            .background(Circle().fill(AppColor.backgroundPrimary).frame(width: 20, height: 20))
            .position(routeEnd(in: size))
    }

    private var vehicleDot: some View {
        ZStack {
            Circle()
                .fill(AppColor.coral.opacity(0.22))
                .frame(width: 30, height: 30)
            Circle()
                .fill(AppColor.coral)
                .frame(width: 16, height: 16)
        }
    }

    // MARK: - Geometry

    private func routeStart(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.14, y: size.height * 0.88)
    }

    private func routeEnd(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.78, y: size.height * 0.22)
    }

    private func routePath(in size: CGSize) -> Path {
        var path = Path()
        let start = routeStart(in: size)
        let end = routeEnd(in: size)
        path.move(to: start)
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.34, y: size.height * 0.70),
            control: CGPoint(x: size.width * 0.14, y: size.height * 0.70)
        )
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.47, y: size.height * 0.44),
            control: CGPoint(x: size.width * 0.47, y: size.height * 0.70)
        )
        path.addQuadCurve(
            to: end,
            control: CGPoint(x: size.width * 0.47, y: size.height * 0.22)
        )
        return path
    }

    private func startAnimating() {
        progress = 0
        guard isMoving, !reduceMotion else {
            progress = 1
            return
        }
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            progress = 1
        }
    }
}

/// Positions a view along a `Path`, animating `progress` from 0 to 1.
///
/// `AnimatableModifier` (rather than plain `.position`) is what lets SwiftUI
/// interpolate the *parameter* and re-derive the point every frame, which is
/// how the dot follows the curve instead of cutting across it.
private struct FollowPath: AnimatableModifier {
    var progress: CGFloat
    let path: Path

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.position(point(at: progress))
    }

    private func point(at fraction: CGFloat) -> CGPoint {
        let clamped = min(max(fraction, 0.0001), 0.9999)
        return path.trimmedPath(from: 0, to: clamped).currentPoint ?? .zero
    }
}

#Preview {
    RideMapView()
        .background(AppColor.backgroundPrimary)
}
