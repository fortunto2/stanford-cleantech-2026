import Foundation

/// The few numbers the Plan screen leads with, derived from the hours and actions.
public struct PlanDigest: Sendable, Equatable {
    public let peakAqi: Int?
    public let peakBand: AQIBand?
    /// The smoke rule that fires first in the shift, if any.
    public let smokeAction: Action?
    public let peakTempF: Int?
    /// First hour at or above the Cal/OSHA §3395 shade trigger (80 °F), "12:00".
    public let shadeFrom: String?
    /// The cleanest stretch of the shift as whole hours: start inclusive, end exclusive.
    public let cleanestWindow: ClosedRange<Int>?

    public static let shadeTriggerF = 80

    public init(plan: CrewPlan) {
        let aqis = plan.hours.compactMap(\.metrics.usAqiPm25)
        peakAqi = plan.peakAqi ?? aqis.max()
        peakBand = peakAqi.map(AQIBand.init(aqi:))
        smokeAction = plan.actions.first { $0.rule.hasPrefix("smoke") }
        let temps = plan.hours.compactMap(\.metrics.tempFFloor)
        peakTempF = temps.max()
        shadeFrom = plan.hours.first { ($0.metrics.tempFFloor ?? 0) >= Self.shadeTriggerF }?.clock
        cleanestWindow = Self.cleanestWindow(plan.hours)
    }

    /// The longest run of consecutive hours within 10 AQI of the shift's best hour, containing it.
    /// Returned as hour-of-day bounds, the end being the hour the run stops (exclusive).
    static func cleanestWindow(_ hours: [Hour]) -> ClosedRange<Int>? {
        let values = hours.map(\.metrics.usAqiPm25)
        guard let best = values.compactMap({ $0 }).min(),
              let bestIndex = values.firstIndex(of: best) else { return nil }
        let isClean = { (i: Int) in (values[i] ?? .max) <= best + 10 }
        var lo = bestIndex, hi = bestIndex
        while lo > 0, isClean(lo - 1) { lo -= 1 }
        while hi < values.count - 1, isClean(hi + 1) { hi += 1 }
        guard let start = hours[lo].hourOfDay, let end = hours[hi].hourOfDay else { return nil }
        return start ... (end + 1)
    }
}

extension Hour {
    /// 7 for "2026-10-24T07:00".
    public var hourOfDay: Int? { Int(clock.prefix(2)) }
}

extension Action {
    /// The instruction without its leading measurement: "AQI 158: hand out N95s" → "Hand out N95s".
    public var sentence: String {
        guard let colon = text.range(of: ": ") else { return text }
        let rest = text[colon.upperBound...]
        return rest.prefix(1).uppercased() + rest.dropFirst()
    }
}
