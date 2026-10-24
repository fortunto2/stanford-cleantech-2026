import SwiftUI

enum PrivacyLink {
    static let url = URL(string: "https://airsignal.app/crew/privacy")
}

/// Said before every report leaves the phone: where it goes, what is in it, what is not.
struct SendDisclosure: View {
    let placeName: String
    let sendsLocation: Bool
    var dark = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            line(String(localized: "Goes to"), destination + " " + String(localized: """
            The crew lead sees it, and anyone with the link. Nothing goes to an agency, union or \
            employer system unless someone forwards it.
            """))
            line(String(localized: "Sent"), String(localized: """
            kind, note, time, this hour's forecast, nearest satellite fire, nearest monitor.
            """))
            if sendsLocation {
                line(String(localized: "Also"), String(localized: """
                your location (~100 m) and which way the camera faced.
                """))
            }
            line(String(localized: "Not sent"), String(localized: """
            your name, phone, email. Photos are not attached to reports.
            """))
            if let url = PrivacyLink.url {
                Link(String(localized: "Privacy"), destination: url)
                    .font(Theme.Font.chip).underline()
                    .foregroundStyle(dark ? Theme.skyInk : Theme.ink)
            }
        }
        .padding(Theme.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dark ? Theme.skyStroke.opacity(0.5) : Theme.card, in: .rect(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .contain)
    }

    /// "the Fresno page for today", or for a coordinate the server named "near Barstow",
    /// "the page for the area near Barstow, today".
    private var destination: String {
        if placeName.hasPrefix("near ") {
            let town = String(placeName.dropFirst(5))
            return String(localized: "the page for the area near \(town), today.")
        }
        return String(localized: "the \(placeName) page for today.")
    }

    private func line(_ label: String, _ text: String) -> some View {
        (Text(label + ": ").bold() + Text(text))
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(dark ? Theme.skyInkSecondary : Theme.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Under the sky-check buttons: where the photo goes.
struct SkyCheckDisclosure: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            Text("""
            This photo goes once to TypeSafe's vision model for analysis and is not stored by us. \
            Faces are blacked out on your phone first.
            """)
            if let url = PrivacyLink.url {
                Link(String(localized: "Privacy"), destination: url).underline()
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(Theme.skyInkSecondary)
    }
}
