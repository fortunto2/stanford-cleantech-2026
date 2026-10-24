import CrewKit
import SwiftUI

/// Every colour, size and spacing in the app. A redesign is a change to this file.
///
/// Warm paper ground, near-black ink, heavy type. Colour belongs to the data: the only
/// saturated fills are measurements (EPA bands) and the four report kinds.
enum Theme {
    // MARK: Ground and ink
    static let ground = hex(0xFFF9F2)
    static let card = Color.white
    static let ink = hex(0x1A1410)
    static let inkSecondary = hex(0x6B5E55)
    static let inkTertiary = hex(0x9A8E85)
    static let field = Color.white
    static let fieldOnCard = hex(0xFFF3E6)

    // MARK: Tiles and pills
    static let heat = hex(0xFFE7A3)
    static let heatInk = hex(0x6B4E00)
    static let calm = hex(0xCFE3FF)
    static let calmInk = hex(0x1C3F7A)
    static let sick = hex(0xFFE0D6)
    static let sickInk = hex(0x8A2A16)
    static let ok = hex(0xDDF5E6)
    static let okInk = hex(0x1E7A45)
    static let okSolid = hex(0x1B7F38)
    static let waitingInk = hex(0x7A4A00)
    static let neutralPill = hex(0xEDE6DF)

    // MARK: Escalate (dark)
    static let night = hex(0x1A1410)
    static let nightCard = hex(0x2A211B)
    static let nightInk = hex(0xFFF9F2)
    static let nightInkSecondary = hex(0xC9BDB3)
    static let nightInkTertiary = hex(0xA99C92)
    static let nightAccent = hex(0xFFB08F)

    // MARK: Sky (dark, over the camera)
    static let skyPlaceholder = hex(0x1B1F22)
    static let skyPanel = hex(0x14181D).opacity(0.93)
    static let skyChip = hex(0x1B1F22).opacity(0.8)
    static let skyInk = hex(0xF1F3F4)
    static let skyInkSecondary = hex(0xB9C1C7)
    static let skyHorizon = hex(0xF1F3F4).opacity(0.55)
    static let skyStroke = hex(0x2E353B)
    static let fire = hex(0xB5532E)
    static let monitorInk = hex(0x14181D)
    static let skyAccent = hex(0xE08A62)

    // MARK: EPA bands, bright
    static func color(_ band: AQIBand) -> Color {
        switch band {
        case .good: hex(0x2BA84A)
        case .moderate: hex(0xF5C400)
        case .sensitive: hex(0xFF9A1F)
        case .unhealthy: hex(0xE8402A)
        case .veryUnhealthy: hex(0x8F3F97)
        case .hazardous: hex(0x7E0023)
        }
    }

    /// Text on a band colour. Ink on the three light bands (≥ 4.5:1). White on the dark three:
    /// 6:1 and up on purple and maroon, 4.0:1 on red, which is only ever used for bold text
    /// of 19 pt or more (large text, where 3:1 is the bar).
    static func onColor(_ band: AQIBand) -> Color {
        band <= .sensitive ? ink : .white
    }

    // MARK: Type
    enum Font {
        static let title = SwiftUI.Font.system(size: 30, weight: .heavy)
        static let subtitle = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let hero = SwiftUI.Font.system(size: 84, weight: .heavy)
        static let heroUnit = SwiftUI.Font.system(size: 20, weight: .bold)
        static let heroLead = SwiftUI.Font.system(size: 19, weight: .bold)
        static let heroSentence = SwiftUI.Font.system(size: 26, weight: .heavy)
        static let tileValue = SwiftUI.Font.system(size: 40, weight: .heavy)
        static let tileLabel = SwiftUI.Font.system(size: 14, weight: .bold)
        static let tileNote = SwiftUI.Font.system(size: 14, weight: .semibold)
        static let button = SwiftUI.Font.system(size: 18, weight: .heavy)
        static let kind = SwiftUI.Font.system(size: 19, weight: .bold)
        static let row = SwiftUI.Font.system(size: 16, weight: .bold)
        static let pill = SwiftUI.Font.system(size: 14, weight: .bold)
        static let chip = SwiftUI.Font.system(size: 13, weight: .bold)
        static let caption = SwiftUI.Font.system(size: 13, weight: .semibold)
        static let field = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let countdown = SwiftUI.Font.system(size: 32, weight: .heavy)
        static let evidence = SwiftUI.Font.system(size: 20, weight: .heavy)
        static let cardTitle = SwiftUI.Font.system(size: 24, weight: .heavy)
        static let mono = SwiftUI.Font.system(size: 12, weight: .medium, design: .monospaced)
    }

    // MARK: Spacing
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 22
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let chart: CGFloat = 8
        static let panel: CGFloat = 16
        static let field: CGFloat = 16
        static let button: CGFloat = 18
        static let tile: CGFloat = 24
        static let hero: CGFloat = 28
    }

    enum Size {
        static let button: CGFloat = 60
        static let field: CGFloat = 52
        static let kindButton: CGFloat = 92
        static let chart: CGFloat = 96
        static let selectedBorder: CGFloat = 3
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension View {
    /// Liquid Glass on iOS 26, a thin material below (from reelcam).
    @ViewBuilder
    func glass<S: Shape>(_ shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(interactive ? Glass.regular.interactive() : Glass.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    /// A full-width dark primary button label.
    func primaryButton(fill: Color = Theme.ink, ink: Color = Theme.ground) -> some View {
        font(Theme.Font.button)
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.button)
            .background(fill, in: .rect(cornerRadius: Theme.Radius.button + 2))
    }

    func pill(fill: Color, ink: Color) -> some View {
        font(Theme.Font.pill)
            .foregroundStyle(ink)
            .padding(.horizontal, Theme.Space.m).padding(.vertical, 6)
            .background(fill, in: .capsule)
    }
}
