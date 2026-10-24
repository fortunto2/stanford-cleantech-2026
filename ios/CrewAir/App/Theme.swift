import CrewKit
import SwiftUI

/// Every colour, size and spacing in the app. A redesign is a change to this file.
///
/// Colour belongs to the data: the chrome stays near-neutral so the only saturated things on
/// screen are measurements (EPA bands, the fire marker).
enum Theme {
    // MARK: Chrome
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let accent = Color.primary
    static let separator = Color(.separator)

    // MARK: Data
    static let fire = Color(red: 1.0, green: 0.27, blue: 0.0)
    static let monitor = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let warning = Color(red: 0.85, green: 0.2, blue: 0.1)

    /// Official EPA AQI colours.
    static func color(_ band: AQIBand) -> Color {
        switch band {
        case .good: Color(red: 0, green: 228 / 255, blue: 0)
        case .moderate: Color(red: 1, green: 1, blue: 0)
        case .sensitive: Color(red: 1, green: 126 / 255, blue: 0)
        case .unhealthy: Color(red: 1, green: 0, blue: 0)
        case .veryUnhealthy: Color(red: 143 / 255, green: 63 / 255, blue: 151 / 255)
        case .hazardous: Color(red: 126 / 255, green: 0, blue: 35 / 255)
        }
    }

    /// Text that stays legible on a band colour.
    static func onColor(_ band: AQIBand) -> Color {
        band <= .sensitive ? .black : .white
    }

    // MARK: Sky view
    static let skyPlaceholder = Color(white: 0.06)
    static let skyHorizon = Color.white.opacity(0.5)
    static let skyLabelBackground = Color.black.opacity(0.6)

    // MARK: Spacing (4-pt scale)
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let s: CGFloat = 6
        static let m: CGFloat = 12
    }

    enum Size {
        static let hourCellWidth: CGFloat = 52
        static let reportButtonHeight: CGFloat = 64
    }
}
