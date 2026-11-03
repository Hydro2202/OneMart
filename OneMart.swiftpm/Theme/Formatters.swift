import Foundation

/// Centralised display formatting so no view hand-rolls a "₱" string.
enum AppFormat {

    private static let pesoWhole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let pesoDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// "₱1,240" — for prices and totals in dense list rows.
    static func peso(_ amount: Double) -> String {
        let number = NSNumber(value: amount)
        return "₱" + (pesoWhole.string(from: number) ?? String(format: "%.0f", amount))
    }

    /// "₱1,240.50" — for the wallet balance and receipts, where centavos matter.
    static func pesoPrecise(_ amount: Double) -> String {
        let number = NSNumber(value: amount)
        return "₱" + (pesoDecimal.string(from: number) ?? String(format: "%.2f", amount))
    }

    /// Signed amount for a wallet transaction row: "+₱1,000.00" / "−₱285.00".
    static func signedPeso(_ amount: Double) -> String {
        amount >= 0 ? "+" + pesoPrecise(amount) : "−" + pesoPrecise(abs(amount))
    }

    /// "12.4k sold" style compaction for large counts.
    static func compactCount(_ value: Int) -> String {
        switch value {
        case 1_000_000...:
            return String(format: "%.1fM", Double(value) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fk", Double(value) / 1_000)
        default:
            return "\(value)"
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// "2h ago", "3d ago" — used by activity feeds and message previews.
    static func relative(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// "Today, 2:30 PM" / "Yesterday, 9:15 AM" / "Sep 3, 2:30 PM".
    static func orderTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = timeOnly.string(from: date)
        if calendar.isDateInToday(date) { return "Today, \(time)" }
        if calendar.isDateInYesterday(date) { return "Yesterday, \(time)" }
        return "\(shortDate.string(from: date)), \(time)"
    }

    static func time(_ date: Date) -> String {
        timeOnly.string(from: date)
    }

    /// "04:12:30" countdown used by the live flash-deal timer.
    static func countdown(until endDate: Date, from now: Date = Date()) -> String {
        let remaining = max(0, Int(endDate.timeIntervalSince(now)))
        let hours = remaining / 3_600
        let minutes = (remaining % 3_600) / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
