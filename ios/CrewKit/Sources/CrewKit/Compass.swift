import Foundation

public enum Compass {
    private static let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

    /// Degrees clockwise from true north for an 8-point compass string ("NW" → 315).
    /// Case-insensitive; nil for anything that is not one of the eight.
    public static func bearing(for direction: String) -> Double? {
        let key = direction.trimmingCharacters(in: .whitespaces).uppercased()
        return points.firstIndex(of: key).map { Double($0) * 45 }
    }

    /// Initial great-circle bearing from one point to another, degrees from true north.
    public static func bearing(
        fromLat lat1: Double, lon lon1: Double, toLat lat2: Double, lon lon2: Double
    ) -> Double {
        let phi1 = lat1 * .pi / 180, phi2 = lat2 * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let y = sin(dLon) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLon)
        return normalized(atan2(y, x) * 180 / .pi)
    }

    /// Into 0..<360.
    public static func normalized(_ degrees: Double) -> Double {
        let r = degrees.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// Signed difference `to − from`, in −180..<180.
    public static func delta(from: Double, to: Double) -> Double {
        let d = normalized(to - from)
        return d >= 180 ? d - 360 : d
    }
}
