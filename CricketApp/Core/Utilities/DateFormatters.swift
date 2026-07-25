import Foundation

// MARK: - Date Formatting

/// Date formatting helpers for Cricket.com.au requests and screen labels.
enum DateFormatters {
    private static var userTimeZone: TimeZone { .current }
    private static var userLocale: Locale { .current }

    static func cricketAustraliaDateString(from date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func dayTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = userLocale
        formatter.timeZone = userTimeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func shortTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = userLocale
        formatter.timeZone = userTimeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Human-readable kickoff label that avoids same-day confusion for late-night fixtures.
    static func scheduleLabel(for startDate: Date, fixtureDate: Date?, isLive: Bool = false) -> String {
        if isLive, startDate <= .now {
            return startedLabel(for: startDate)
        }

        let calendar = Calendar.current
        let time = shortTime(for: startDate)

        if calendar.isDateInToday(startDate) {
            return time
        }

        if let fixtureDate, calendar.isDate(startDate, inSameDayAs: fixtureDate) {
            return time
        }

        if calendar.isDateInTomorrow(startDate) {
            let hour = calendar.component(.hour, from: startDate)
            if hour < 6 {
                return "Tonight, \(time)"
            }
            return "Tomorrow, \(time)"
        }

        return "\(dayTitle(for: startDate)), \(time)"
    }

    static func startedLabel(for startDate: Date) -> String {
        "Started \(shortTime(for: startDate))"
    }

    static func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = userLocale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
