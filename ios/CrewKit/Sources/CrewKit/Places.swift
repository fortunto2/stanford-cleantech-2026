import Foundation

/// One suggestion from `GET /api/crew/places?q=`: "Fresno" — "Fresno, California".
public struct PlaceSuggestion: Codable, Sendable, Equatable, Identifiable, Hashable {
    public let name: String
    public let detail: String?
    public let lat: Double
    public let lon: Double

    public init(name: String, detail: String?, lat: Double, lon: Double) {
        self.name = name
        self.detail = detail
        self.lat = lat
        self.lon = lon
    }

    public var id: String { "\(name)|\(lat)|\(lon)" }
    /// What the API takes as `place`.
    public var query: String { PlaceQuery.coordinate(lat, lon) }
}

public struct PlaceList: Codable, Sendable, Equatable {
    public let places: [PlaceSuggestion]
}

public enum PlaceQuery {
    /// `place=<lat>,<lon>` as the API takes it. Four decimals is ~10 m: finer than any forecast
    /// cell, coarse enough to keep the URL short.
    public static func coordinate(_ lat: Double, _ lon: Double) -> String {
        String(format: "%.4f,%.4f", lat, lon)
    }

    /// Whether a stored place is a coordinate rather than a name.
    public static func isCoordinate(_ place: String) -> Bool {
        let parts = place.split(separator: ",")
        return parts.count == 2 && parts.allSatisfy { Double($0.trimmingCharacters(in: .whitespaces)) != nil }
    }
}
