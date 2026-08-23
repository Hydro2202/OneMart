import SwiftUI

// MARK: - Colors
//
// All colors are backed by adaptive Color Assets (see Resources/Assets.xcassets)
// so views never hardcode hex values and Dark Mode is handled automatically.
enum AppColor {
    // Brand
    static let coral = Color("CoralPrimary")       // primary accent — CTAs, active states
    static let jade = Color("JadeSecondary")        // secondary accent — marketplace / trust / escrow
    static let amber = Color("AmberTertiary")       // tertiary — deals, badges, notifications

    // Surfaces
    static let backgroundPrimary = Color("BackgroundPrimary")     // screen background
    static let backgroundSecondary = Color("BackgroundSecondary") // cards, surfaces
    static let backgroundTertiary = Color("BackgroundTertiary")   // grouped / inset surfaces

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")

    // Structure
    static let borderSubtle = Color("BorderSubtle")

    // Semantic
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
    static let error = Color("ErrorColor")

    // Convenience — text color that always sits well on a coral/jade/amber fill
    static let onAccent = Color.white
}

// MARK: - Typography
//
// SF Pro Rounded for headings/labels (friendly, approachable), standard SF Pro
// for dense body/list text. Centralized type-scale — never ad-hoc font sizes in views.
enum AppFont {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func standard(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

enum AppTextStyle {
    // Rounded — headings & UI chrome
    static let largeTitle = AppFont.rounded(34, weight: .bold)
    static let title = AppFont.rounded(24, weight: .bold)
    static let title2 = AppFont.rounded(20, weight: .semibold)
    static let headline = AppFont.rounded(17, weight: .semibold)
    static let subheadline = AppFont.rounded(15, weight: .medium)
    static let buttonLabel = AppFont.rounded(16, weight: .semibold)
    static let badge = AppFont.rounded(12, weight: .bold)

    // Standard — dense body / list text
    static let body = AppFont.standard(16, weight: .regular)
    static let bodyEmphasis = AppFont.standard(16, weight: .semibold)
    static let callout = AppFont.standard(15, weight: .regular)
    static let footnote = AppFont.standard(13, weight: .regular)
    static let caption = AppFont.standard(12, weight: .regular)
    static let caption2 = AppFont.standard(11, weight: .medium)
}

// Applies a text style + primary color together, and supports Dynamic Type via
// relative scaling from the .body text style baseline.
struct TextStyleModifier: ViewModifier {
    let font: Font
    let color: Color
    let relativeTo: Font.TextStyle

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
}

extension View {
    func appTextStyle(_ font: Font, color: Color = AppColor.textPrimary, relativeTo: Font.TextStyle = .body) -> some View {
        modifier(TextStyleModifier(font: font, color: color, relativeTo: relativeTo))
    }
}

// MARK: - Spacing
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum AppRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let pill: CGFloat = 999
}

// MARK: - Shadows
//
// Soft, layered shadows for a tactile, non-flat feel.
struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = AppShadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
    static let elevated = AppShadow(color: Color.black.opacity(0.14), radius: 24, x: 0, y: 10)
    static let subtle = AppShadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
}

extension View {
    func appShadow(_ shadow: AppShadow = .card) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Motion
//
// Central place for spring/animation curves so interactions feel consistent,
// plus a Reduce Motion aware helper.
enum AppMotion {
    static let springBouncy = Animation.spring(response: 0.45, dampingFraction: 0.68, blendDuration: 0.2)
    static let springSnappy = Animation.spring(response: 0.32, dampingFraction: 0.8, blendDuration: 0.1)
    static let easeStandard = Animation.easeInOut(duration: 0.28)

    /// Returns a simple fade/duration-only animation when Reduce Motion is enabled,
    /// otherwise the supplied spring/curve.
    static func adaptive(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : animation
    }
}

// MARK: - Press Feedback
//
// Reusable "press down" scale effect for tactile buttons/cards, respecting Reduce Motion.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppMotion.adaptive(AppMotion.springSnappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}
