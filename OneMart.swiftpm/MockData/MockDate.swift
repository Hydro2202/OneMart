import Foundation

/// Small relative-date helpers so every mock fixture reads as "just now-ish"
/// no matter when the app is launched. Anything time-sensitive in the UI
/// (flash-deal countdowns, "2h ago" stamps) stays believable because the dates
/// are always computed relative to `Date()`.
enum MockDate {
    static func minutesAgo(_ minutes: Int) -> Date {
        Date().addingTimeInterval(-Double(minutes) * 60)
    }

    static func hoursAgo(_ hours: Int) -> Date {
        Date().addingTimeInterval(-Double(hours) * 3_600)
    }

    static func daysAgo(_ days: Int) -> Date {
        Date().addingTimeInterval(-Double(days) * 86_400)
    }

    static func monthsAgo(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
    }

    /// Used for flash-deal end times so the countdown on Shop is a *real*,
    /// live-ticking value rather than a hardcoded string.
    static func hoursFromNow(_ hours: Double) -> Date {
        Date().addingTimeInterval(hours * 3_600)
    }
}
