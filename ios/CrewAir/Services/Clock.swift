import CrewKit
import Foundation

/// Times as a crew in California reads them: Pacific wall-clock, in the phone's language.
enum Clock {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        c.locale = .current
        return c
    }()

    /// Whether this locale writes hours 0–23.
    static let uses24Hour: Bool =
        (DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "").contains("H")

    /// "7 AM" / "7" for hour-of-day 7.
    static func hour(_ h: Int) -> String {
        guard let date = calendar.date(bySettingHour: h % 24, minute: 0, second: 0, of: .now) else { return "\(h)" }
        var style = Date.FormatStyle(date: .omitted, time: .omitted).hour(.defaultDigits(amPM: .abbreviated))
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// The bare number on a 12- or 24-hour dial: 15 → "3" or "15".
    static func dial(_ h: Int) -> String {
        if uses24Hour { return "\(h)" }
        let twelve = h % 12
        return "\(twelve == 0 ? 12 : twelve)"
    }

    /// "PM" for 15, empty on a 24-hour locale.
    static func meridiem(_ h: Int) -> String {
        uses24Hour ? "" : (h % 24 < 12 ? calendar.amSymbol : calendar.pmSymbol)
    }

    /// "08:00" → "8:00".
    static func short(_ clock: String) -> String {
        clock.hasPrefix("0") ? String(clock.dropFirst()) : clock
    }

    /// A server timestamp as local time, "10:05 AM".
    static func time(_ iso: String) -> String {
        guard let date = ReportClock.date(iso) else { return "" }
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// "Sunday" for "2026-10-25".
    static func weekday(_ day: String) -> String {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
        else { return day }
        var style = Date.FormatStyle().weekday(.wide)
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }
}
