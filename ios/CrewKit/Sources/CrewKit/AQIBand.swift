/// The six EPA AQI categories. Upper bounds are inclusive: 50 is still Good, 51 is Moderate.
public enum AQIBand: Int, CaseIterable, Sendable, Comparable {
    case good, moderate, sensitive, unhealthy, veryUnhealthy, hazardous

    public init(aqi: Int) {
        switch aqi {
        case ...50: self = .good
        case 51...100: self = .moderate
        case 101...150: self = .sensitive
        case 151...200: self = .unhealthy
        case 201...300: self = .veryUnhealthy
        default: self = .hazardous
        }
    }

    public var label: String {
        switch self {
        case .good: "Good"
        case .moderate: "Moderate"
        case .sensitive: "Unhealthy for sensitive groups"
        case .unhealthy: "Unhealthy"
        case .veryUnhealthy: "Very unhealthy"
        case .hazardous: "Hazardous"
        }
    }

    public static func < (lhs: AQIBand, rhs: AQIBand) -> Bool { lhs.rawValue < rhs.rawValue }
}
