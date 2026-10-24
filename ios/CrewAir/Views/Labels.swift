import CrewKit
import SwiftUI

/// User-facing names for domain values, localized here so CrewKit stays language-free.
extension ReportKind {
    var label: String {
        switch self {
        case .smoke: String(localized: "Smoke or haze")
        case .ash: String(localized: "Ash falling")
        case .symptoms: String(localized: "Someone feels sick")
        case .noN95: String(localized: "No N95s here")
        case .noShade: String(localized: "No shade or water")
        case .noWater: String(localized: "No water")
        case .other: String(localized: "Something else")
        }
    }

    /// Short form for a report row.
    var short: String {
        switch self {
        case .smoke: String(localized: "Smoke")
        case .ash: String(localized: "Ash")
        case .symptoms: String(localized: "Feels sick")
        case .noN95: String(localized: "No N95s")
        case .noShade: String(localized: "No shade")
        case .noWater: String(localized: "No water")
        case .other: String(localized: "Other")
        }
    }

    /// The four big buttons, in the order of the design.
    static let primary: [ReportKind] = [.smoke, .symptoms, .noShade, .noN95]

    var fill: Color {
        switch self {
        case .smoke: Theme.color(.unhealthy)
        case .symptoms: Theme.sick
        case .noShade, .noWater: Theme.heat
        case .noN95: Theme.calm
        case .ash, .other: Theme.card
        }
    }

    var ink: Color { self == .smoke ? .white : Theme.ink }
}

extension AQIBand {
    var title: String {
        switch self {
        case .good: String(localized: "good")
        case .moderate: String(localized: "moderate")
        case .sensitive: String(localized: "unhealthy for sensitive groups")
        case .unhealthy: String(localized: "unhealthy")
        case .veryUnhealthy: String(localized: "very unhealthy")
        case .hazardous: String(localized: "hazardous")
        }
    }
}

extension Report {
    /// "Smoke · east block · 10:05 AM"
    var headline: String {
        [kind.short, note.flatMap { $0.isEmpty ? nil : $0 }, Clock.time(createdAt)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// Waiting / Fixed / Not sent, as in the design.
struct StatusPill: View {
    let report: Report

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if report.isHandled {
                Text("Fixed \(report.handledAt.map(Clock.time) ?? "")").pill(fill: Theme.ok, ink: Theme.okInk)
            } else if report.isUnsent {
                Text("Not sent").pill(fill: Theme.neutralPill, ink: Theme.inkSecondary)
            } else {
                let minutes = ReportClock.minutesWaiting(since: report.createdAt, now: context.date) ?? 0
                Text("Waiting · \(minutes) min").pill(fill: Theme.heat, ink: Theme.waitingInk)
            }
        }
    }
}
