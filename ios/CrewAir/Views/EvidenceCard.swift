import CrewKit
import SwiftUI

/// "Facing S 182° · toward the fire", "Taken at 36.711, -119.777 · facing S 182° · 10:05".
enum OriginText {
    static func facing(_ degrees: Double) -> String {
        String(localized: "Facing \(Compass.point(for: degrees)) \(Int(degrees.rounded()))°")
    }

    static func coordinate(_ lat: Double, _ lon: Double) -> String {
        String(format: "%.3f, %.3f", lat, lon)
    }

    static func taken(_ origin: CheckOrigin) -> String? {
        var parts: [String] = []
        if let lat = origin.input.lat, let lon = origin.input.lon {
            parts.append(String(localized: "Taken at \(coordinate(lat, lon))"))
        }
        if let heading = origin.headingDeg { parts.append(facing(heading)) }
        if let clock = origin.takenClock { parts.append(clock) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// A report's `evidence.from` as one line.
    static func report(_ from: ReportOrigin) -> String? {
        var parts: [String] = []
        if let facing = from.facing {
            parts.append(Self.facing(facing.headingDeg))
            if facing.towardFire == true { parts.append(String(localized: "toward the fire")) }
        }
        if let position = from.position { parts.append(coordinate(position.lat, position.lon)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// The image a worker forwards: the sky as sent (faces painted over) with what the satellites,
/// the monitor and the forecast said at that moment.
struct EvidenceCard: View {
    let photo: UIImage
    let result: SkyCheckResult
    let response: CrewResponse?
    let headingDeg: Double?
    let takenClock: String?

    private static let width: CGFloat = 360

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(uiImage: photo).resizable().scaledToFill()
                .frame(width: Self.width, height: Self.width * 0.75).clipped()
            VStack(alignment: .leading, spacing: 6) {
                Text(header).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.skyAccent)
                Text(result.verdict).font(.system(size: 20, weight: .heavy))
                Text(skyLine).font(.system(size: 15, weight: .semibold))
                ForEach(lines, id: \.self) { Text($0).font(.system(size: 13)) }
                Text("Crew Air · airsignal.app/crew")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.skyInkSecondary)
                    .padding(.top, 6)
            }
            .foregroundStyle(Theme.skyInk)
            .padding(16)
            .frame(width: Self.width, alignment: .leading)
            .background(Theme.skyPlaceholder)
        }
        .frame(width: Self.width)
        .environment(\.colorScheme, .dark)
    }

    private var header: String {
        let place = response?.place.name ?? result.model?.place ?? ""
        let time = takenClock ?? Date.now.formatted(date: .omitted, time: .shortened)
        return "\(place) · \(time)"
    }

    private var skyLine: String {
        let smoke = Int((result.smoke * 100).rounded())
        if let aqi = result.model?.aqi {
            return String(localized: "Forecast AQI \(aqi) · Your sky: smoke \(smoke)%")
        }
        return String(localized: "Your sky: smoke \(smoke)%")
    }

    private var lines: [String] {
        var out: [String] = []
        let confidence = response?.plan.confidence
        if let fire = confidence?.fire {
            out.append(String(localized: "Satellite fire \(Int(fire.nearestKm)) km \(fire.direction)"))
        }
        if let ground = confidence?.ground {
            out.append(String(localized: "AirNow \(ground.nearest): \(String(format: "%.1f", ground.pm25)) µg/m³"))
        }
        if let headingDeg {
            var facing = OriginText.facing(headingDeg)
            if let bearing = confidence?.fire?.bearing, abs(Compass.delta(from: headingDeg, to: bearing)) <= 45 {
                facing += " · " + String(localized: "toward the fire")
            }
            out.append(facing)
        }
        return out
    }
}
