import Foundation

/// Where and which way a library photo was taken, from its EXIF/GPS properties.
public struct PhotoOrigin: Sendable, Equatable {
    public let lat: Double?
    public let lon: Double?
    /// The camera's heading, degrees from north (`GPSImgDirection`).
    public let headingDeg: Double?
    /// `DateTimeOriginal` as written by the camera: local time, "2026:10:24 10:05:12".
    public let takenAt: String?

    public init(lat: Double?, lon: Double?, headingDeg: Double?, takenAt: String?) {
        self.lat = lat
        self.lon = lon
        self.headingDeg = headingDeg
        self.takenAt = takenAt
    }

    public var hasPosition: Bool { lat != nil && lon != nil }
    public var isEmpty: Bool { !hasPosition && headingDeg == nil && takenAt == nil }

    /// Reads the dictionaries ImageIO returns: `{GPS}` and `{Exif}` as plain string keys.
    /// South and West references make the coordinate negative.
    public init(gps: [String: Any]?, exif: [String: Any]?) {
        func number(_ key: String) -> Double? {
            (gps?[key] as? NSNumber)?.doubleValue ?? (gps?[key] as? Double)
        }
        if let lat = number("Latitude"), let lon = number("Longitude") {
            self.lat = (gps?["LatitudeRef"] as? String)?.uppercased() == "S" ? -lat : lat
            self.lon = (gps?["LongitudeRef"] as? String)?.uppercased() == "W" ? -lon : lon
        } else {
            self.lat = nil
            self.lon = nil
        }
        headingDeg = number("ImgDirection").map(Compass.normalized)
        takenAt = exif?["DateTimeOriginal"] as? String
    }

    /// "10:05" out of "2026:10:24 10:05:12".
    public var takenClock: String? {
        guard let takenAt, let space = takenAt.firstIndex(of: " ") else { return nil }
        return String(takenAt[takenAt.index(after: space)...].prefix(5))
    }
}

extension Compass {
    /// The 8-point name for a heading: 182 → "S".
    public static func point(for degrees: Double) -> String {
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return points[Int((normalized(degrees) + 22.5) / 45) % 8]
    }
}
