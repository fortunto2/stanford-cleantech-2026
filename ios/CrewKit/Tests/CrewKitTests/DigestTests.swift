@testable import CrewKit
import Foundation
import Testing

private func hours(_ aqi: [Int], temps: [Double]? = nil, from start: Int = 7) -> [Hour] {
    let json = aqi.enumerated().map { i, a in
        let t = temps?[i] ?? 60
        let time = String(format: "2026-10-24T%02d:00", start + i)
        return #"{"time":"\#(time)","metrics":{"us_aqi_pm25":\#(a),"temp_f":\#(t)}}"#
    }.joined(separator: ",")
    return try! JSONDecoder().decode([Hour].self, from: Data("[\(json)]".utf8)) // swiftlint:disable:this force_try
}

@Suite struct DigestTests {
    @Test func cleanestWindowContainsTheBestHour() {
        // 7..16; the best is 15 (58), 14 is within 10, 13 is not.
        let w = PlanDigest.cleanestWindow(hours([95, 103, 109, 108, 96, 83, 73, 66, 61, 58]))
        #expect(w == 14 ... 17)
    }

    @Test func flatDayIsTheWholeShift() {
        #expect(PlanDigest.cleanestWindow(hours([9, 9, 10, 12])) == 7 ... 11)
    }

    @Test func noAqiNoWindow() {
        #expect(PlanDigest.cleanestWindow([]) == nil)
    }

    @Test func digestOfRecordedPlan() throws {
        let url = try #require(
            Bundle.module.url(forResource: "crew-palm-springs", withExtension: "json", subdirectory: "Fixtures")
        )
        let plan = try CrewResponse.decode(Data(contentsOf: url)).plan
        let d = PlanDigest(plan: plan)
        #expect(d.peakTempF == 83)
        #expect(d.shadeFrom == "12:00")
        #expect(d.smokeAction == nil)
        #expect(d.peakBand == .good)
    }

    @Test func sentenceDropsTheMeasurement() throws {
        let json = #"{"time":"2026-10-24T08:00","rule":"smoke-n95","cite":"x","#
            + #""text":"AQI 158: hand out N95s, tell the crew"}"#
        let a = try JSONDecoder().decode(Action.self, from: Data(json.utf8))
        #expect(a.sentence == "Hand out N95s, tell the crew")
    }
}

@Suite struct ReportClockTests {
    let now = ISO8601DateFormatter().date(from: "2026-10-24T17:30:00Z")!

    @Test func parsesFractionalSeconds() {
        #expect(ReportClock.date("2026-10-24T17:12:00.123Z") != nil)
        #expect(ReportClock.date("2026-10-24T17:12:00Z") != nil)
    }

    @Test func countdown() {
        #expect(ReportClock.minutesWaiting(since: "2026-10-24T17:12:00.000Z", now: now) == 18)
        #expect(ReportClock.minutesUntilEscalation(since: "2026-10-24T17:12:00.000Z", now: now) == 12)
        #expect(ReportClock.minutesUntilEscalation(since: "2026-10-24T16:00:00Z", now: now) == 0)
    }

    @Test func decodesLiveReportWithEvidence() throws {
        let json = """
        {"reports":[{"id":3,"site":"fresno-california","date":"2026-10-24","created_at":"2026-10-24T17:12:00.000Z",
        "kind":"smoke","note":"east block","sender":"ab","status":"handled","handled_at":"2026-10-24T17:30:00.000Z",
        "handled_note":"N95s out","evidence":{"place":{"name":"Fresno","lat":1,"lon":2},"hour":"2026-10-24T10:00",
        "metrics":{"us_aqi_pm25":42},"confidence":"model-only","fire":{"nearest_km":32,"direction":"S","within_50km":1},
        "ground":null}}]}
        """
        let r = try #require(try JSONDecoder().decode(ReportList.self, from: Data(json.utf8)).reports.first)
        #expect(r.isHandled)
        #expect(r.handledNote == "N95s out")
        #expect(r.evidence?.metrics?.usAqiPm25 == 42)
        #expect(r.evidence?.fire?.nearestKm == 32)
        #expect(r.evidence?.ground == nil)
    }

    @Test func handleBodyShape() throws {
        let body = HandleRequest(place: "Fresno", date: "2026-10-24", id: 3, note: "done")
        let dict = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any])
        #expect(dict["action"] as? String == "handle")
        #expect(dict["id"] as? Int == 3)
    }
}
