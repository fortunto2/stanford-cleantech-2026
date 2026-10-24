import CrewKit
import Foundation

extension CrewResponse {
    /// A close fire to the NW and one AirNow monitor, so every element of every tab shows.
    static let preview: CrewResponse = {
        let json = """
        {"place":{"name":"Fresno, California","lat":36.74773,"lon":-119.77237},"date":"2026-10-24",
         "shift":{"start":7,"end":17},
         "dispatch":{"sensor":"launch","bearing_deg":333,"distance_km":32,"detections_50km":1,
                     "reason":"VIIRS fire 32 km NW: sample PM2.5 toward it, outside the fire's TFR, and report"},
         "alerts":[{"event":"Red Flag Warning","onset":"2026-10-24T06:00","ends":"2026-10-24T20:00"}],
         "plan":{"jurisdiction":"US-CA",
          "hours":[
           {"time":"2026-10-24T07:00","metrics":{"us_aqi_pm25":95,"temp_f":48.4}},
           {"time":"2026-10-24T08:00","metrics":{"us_aqi_pm25":158,"temp_f":52.1}},
           {"time":"2026-10-24T09:00","metrics":{"us_aqi_pm25":212,"temp_f":61.0}},
           {"time":"2026-10-24T10:00","metrics":{"us_aqi_pm25":130,"temp_f":70.2}},
           {"time":"2026-10-24T11:00","metrics":{"us_aqi_pm25":88,"temp_f":79.7}},
           {"time":"2026-10-24T12:00","metrics":{"us_aqi_pm25":42,"temp_f":84.9}}],
          "actions":[
           {"time":"2026-10-24T08:00","rule":"smoke-n95","cite":"Cal/OSHA T8 §5141.1",
            "text":"AQI 158: N95s available to every worker"},
           {"time":"2026-10-24T12:00","rule":"heat-shade","cite":"Cal/OSHA T8 §3395",
            "text":"84°F: shade up, water at hand"}],
          "peak_aqi":212,"peak_temp_f":84.9,
          "bms":{"threshold_aqi":101,"recirculate_at":"2026-10-24T08:00","resume_at":"2026-10-24T11:00","peak_aqi":212,
                 "reason":"outdoor AQI reaches 101 at 08:00: close outside air, recirculate through MERV 13+"},
          "confidence":{"level":"sensor-confirmed",
           "fire":{"nearest_km":32,"direction":"NW","within_50km":1},
           "ground":{"time":"2026-10-24T06:00","pm25":61,"stations":3,"nearest":"Fresno-Foundry Park","nearest_km":4.1,
                     "nearest_lat":36.785,"nearest_lon":-119.70},
           "notes":["AirNow monitor Fresno-Foundry Park, 4 km away, agrees with the model."]}}}
        """
        // A literal in our own source; failing here is a programming error.
        return try! CrewResponse.decode(Data(json.utf8)) // swiftlint:disable:this force_try
    }()
}

struct PreviewCrewService: CrewService {
    func plan(place: String, date: String, shift: String) async throws -> CrewResponse { .preview }
    func sendReport(_ report: ReportRequest) async throws -> ReportReceipt { throw CrewServiceError.notLive }
    func reports(place: String, date: String) async throws -> [Report] { Report.previews }
    func handle(_ request: HandleRequest) async throws -> HandleReceipt { HandleReceipt(status: "handled") }
    func complaint(report id: String) async throws -> ComplaintDraft {
        ComplaintDraft(complaint: "Hazard: outdoor work without [protection].", fileAt: nil, rules: nil)
    }

    func places(matching text: String) async throws -> [PlaceSuggestion] {
        [PlaceSuggestion(name: "Fresno", detail: "Fresno, California", lat: 36.74773, lon: -119.77237)]
    }
}

extension Report {
    static let previews: [Report] = {
        let now = Date.now
        let iso = { (minutesAgo: Double) in
            ISO8601DateFormatter().string(from: now.addingTimeInterval(-minutesAgo * 60))
        }
        let evidence = Evidence(
            hour: nil, metrics: nil,
            fire: CrewResponse.preview.plan.confidence?.fire,
            ground: CrewResponse.preview.plan.confidence?.ground
        )
        return [
            Report(id: "3", createdAt: iso(18), kind: .smoke, note: "east block", status: "open", evidence: evidence),
            Report(id: "2", createdAt: iso(70), kind: .noShade, note: nil, status: "handled",
                   handledAt: iso(52), handledNote: "Canopy up"),
        ]
    }()
}
