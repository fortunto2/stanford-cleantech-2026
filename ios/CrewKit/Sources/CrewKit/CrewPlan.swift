import Foundation

/// The response of `GET /api/crew`: one place, one day, one shift, and what to do in it.
public struct CrewResponse: Codable, Sendable, Equatable {
    public let place: Place
    public let date: String
    public let shift: Shift
    public let plan: CrewPlan

    public static func decode(_ data: Data) throws -> CrewResponse {
        try JSONDecoder().decode(CrewResponse.self, from: data)
    }
}

public struct Place: Codable, Sendable, Equatable {
    public let name: String
    public let lat: Double
    public let lon: Double
}

/// Shift bounds as whole hours, local time: 7 and 17 for "07-17".
public struct Shift: Codable, Sendable, Equatable {
    public let start: Int
    public let end: Int

    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }

    /// The query form the API takes: "07-17".
    public var query: String { String(format: "%02d-%02d", start, end) }
}

public struct CrewPlan: Codable, Sendable, Equatable {
    public let jurisdiction: String
    public let hours: [Hour]
    public let actions: [Action]
    public let peakAqi: Int?
    public let peakTempF: Double?
    public let bms: BMS?
    public let confidence: Confidence?

    enum CodingKeys: String, CodingKey {
        case jurisdiction, hours, actions, bms, confidence
        case peakAqi = "peak_aqi"
        case peakTempF = "peak_temp_f"
    }
}

public struct Hour: Codable, Sendable, Equatable, Identifiable {
    /// Local wall-clock time, "2026-10-24T07:00" (no zone, the place's own).
    public let time: String
    public let metrics: Metrics

    public var id: String { time }
    /// "07:00" out of "2026-10-24T07:00".
    public var clock: String { Hour.clock(time) }

    static func clock(_ time: String) -> String {
        guard let t = time.firstIndex(of: "T") else { return time }
        return String(time[time.index(after: t)...].prefix(5))
    }
}

public struct Metrics: Codable, Sendable, Equatable {
    public let usAqiPm25: Int?
    public let pm25NowcastUgm3: Double?
    public let pm25Ugm3: Double?
    public let tempF: Double?
    public let tempC: Double?

    /// Whole degrees, floored: 79.7 °F reads as 79, never rounds up past a threshold.
    public var tempFFloor: Int? { tempF.map { Int($0.rounded(.down)) } }

    enum CodingKeys: String, CodingKey {
        case usAqiPm25 = "us_aqi_pm25"
        case pm25NowcastUgm3 = "pm25_nowcast_ugm3"
        case pm25Ugm3 = "pm25_ugm3"
        case tempF = "temp_f"
        case tempC = "temp_c"
    }
}

/// One instruction from the rulebook. `cite` is empty for the planner's own lines
/// ("Heavy work in clear hours"), which have `rule == "plan"`.
public struct Action: Codable, Sendable, Equatable, Identifiable {
    public let time: String
    public let rule: String
    public let cite: String?
    public let text: String

    public var id: String { time + rule }
    public var clock: String { Hour.clock(time) }
    public var citation: String? { cite.flatMap { $0.isEmpty ? nil : $0 } }
}

/// Building management: when to close outside air and recirculate through MERV 13+.
public struct BMS: Codable, Sendable, Equatable {
    public let thresholdAqi: Int
    public let recirculateAt: String?
    public let resumeAt: String?
    public let peakAqi: Int?
    public let reason: String

    enum CodingKeys: String, CodingKey {
        case reason
        case thresholdAqi = "threshold_aqi"
        case recirculateAt = "recirculate_at"
        case resumeAt = "resume_at"
        case peakAqi = "peak_aqi"
    }
}

public struct Confidence: Codable, Sendable, Equatable {
    public enum Level: String, Codable, Sendable {
        case sensorConfirmed = "sensor-confirmed"
        case modelAdjusted = "model-adjusted"
        case modelOnly = "model-only"
    }

    public let level: Level
    public let fire: Fire?
    public let ground: Ground?
    public let notes: [String]
}

public struct Fire: Codable, Sendable, Equatable {
    public let nearestKm: Double
    /// 8-point compass: "N", "NE", … "NW".
    public let direction: String
    /// Count of active fires within 50 km (the API sends 0, not false).
    public let within50km: Int

    enum CodingKeys: String, CodingKey {
        case direction
        case nearestKm = "nearest_km"
        case within50km = "within_50km"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nearestKm = try c.decode(Double.self, forKey: .nearestKm)
        direction = try c.decode(String.self, forKey: .direction)
        // Tolerate a boolean as well as a count.
        if let n = try? c.decode(Int.self, forKey: .within50km) {
            within50km = n
        } else {
            within50km = (try c.decodeIfPresent(Bool.self, forKey: .within50km) ?? false) ? 1 : 0
        }
    }

    public init(nearestKm: Double, direction: String, within50km: Int) {
        self.nearestKm = nearestKm
        self.direction = direction
        self.within50km = within50km
    }

    public var isClose: Bool { within50km > 0 }
    public var bearing: Double? { Compass.bearing(for: direction) }
}

/// The nearest AirNow monitor checked against the model.
public struct Ground: Codable, Sendable, Equatable {
    public let time: String
    public let pm25: Double
    public let stations: Int
    public let nearest: String
    public let nearestKm: Double
    public let modelPm25: Double?
    public let divergence: Double?
    public let factor: Double?
    /// Not in the contract yet: the monitor's position, so it can be pinned in the sky view.
    public let nearestLat: Double?
    public let nearestLon: Double?

    enum CodingKeys: String, CodingKey {
        case time, pm25, stations, nearest, divergence, factor
        case nearestKm = "nearest_km"
        case modelPm25 = "model_pm25"
        case nearestLat = "nearest_lat"
        case nearestLon = "nearest_lon"
    }
}
