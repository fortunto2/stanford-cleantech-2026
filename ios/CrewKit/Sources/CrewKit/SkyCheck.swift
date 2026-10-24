import Foundation

/// Reply of `POST /api/sky-check`: a vision model's read of a sky photo, next to the forecast.
public struct SkyCheckResult: Codable, Sendable, Equatable {
    public enum Call: String, Codable, Sendable {
        case yes, no, unsure
    }

    public let verdict: String
    public let smokeCall: Call
    public let skyVisible: Bool
    /// 0…1 scores.
    public let smoke: Double
    public let plume: Double?
    public let ash: Double?
    public let visibility: SkyVisibility?
    public let model: SkyForecast?
    public let looksWorseThanModel: Bool?

    enum CodingKeys: String, CodingKey {
        case verdict, smoke, plume, ash, visibility, model
        case smokeCall = "smoke_call"
        case skyVisible = "sky_visible"
        case looksWorseThanModel = "looks_worse_than_model"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        verdict = try c.decode(String.self, forKey: .verdict)
        smokeCall = (try? c.decode(Call.self, forKey: .smokeCall)) ?? .unsure
        skyVisible = try c.decodeIfPresent(Bool.self, forKey: .skyVisible) ?? true
        smoke = try c.decodeIfPresent(Double.self, forKey: .smoke) ?? 0
        plume = try c.decodeIfPresent(Double.self, forKey: .plume)
        ash = try c.decodeIfPresent(Double.self, forKey: .ash)
        visibility = try? c.decodeIfPresent(SkyVisibility.self, forKey: .visibility)
        model = try? c.decodeIfPresent(SkyForecast.self, forKey: .model)
        looksWorseThanModel = try c.decodeIfPresent(Bool.self, forKey: .looksWorseThanModel)
    }

    /// Whether this result is worth sending to the crew lead as a smoke report.
    public var shouldReport: Bool { smokeCall == .yes || looksWorseThanModel == true }
}

/// Visibility estimated from the photo, with the EPA/CDC AQI range it implies.
public struct SkyVisibility: Codable, Sendable, Equatable {
    public let label: String
    public let category: String
    public let aqiRange: [Int]?
    public let confidence: Double?
    /// The model's visibility estimate tested unreliable; show it only when trusted.
    public let trusted: Bool

    enum CodingKeys: String, CodingKey {
        case label, category, confidence, trusted
        case aqiRange = "aqi_range"
    }
}

/// The forecast the photo is checked against.
public struct SkyForecast: Codable, Sendable, Equatable {
    public let aqi: Int?
    public let place: String?
}

/// Where to cut a portrait camera frame so only the sky and a strip of horizon leave the phone.
public enum SkyCrop {
    /// Fraction of the image height to keep from the top, or nil to keep the whole frame.
    /// `horizon` is the horizon's height as a fraction from the top; a margin of ground stays in
    /// so the model sees the ridge line. A horizon near the top or off the frame keeps everything.
    public static func keepFraction(horizon: Double, margin: Double = 0.12) -> Double? {
        guard horizon.isFinite, horizon > 0.2, horizon < 1 else { return nil }
        return min(1, horizon + margin)
    }

    /// Pixel size with the long side capped, aspect kept.
    public static func fitted(width: Double, height: Double, longSide: Double = 768) -> (Double, Double) {
        let scale = min(1, longSide / max(width, height))
        return ((width * scale).rounded(), (height * scale).rounded())
    }
}
