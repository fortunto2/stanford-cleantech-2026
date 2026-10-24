import CrewKit
import Foundation
import Testing

private func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Suite struct DecodingTests {
    @Test func decodesRecordedFresnoResponse() throws {
        let r = try CrewResponse.decode(fixture("crew-fresno"))
        #expect(r.place.name == "Fresno, California")
        #expect(r.shift == Shift(start: 7, end: 17))
        #expect(r.shift.query == "07-17")
        #expect(r.plan.jurisdiction == "US-CA")
        #expect(r.plan.hours.count == 10)
        #expect(r.plan.hours[0].clock == "07:00")
        #expect(r.plan.hours[0].metrics.usAqiPm25 == 95)
        #expect(r.plan.hours[0].metrics.tempFFloor == 48)
        #expect(r.plan.peakAqi == 109)
        #expect(r.plan.bms?.recirculateAt == "2026-10-24T08:00")
        let c = try #require(r.plan.confidence)
        #expect(c.level == .sensorConfirmed)
        #expect(c.fire?.direction == "NW")
        #expect(c.fire?.bearing == 315)
        #expect(c.fire?.isClose == false)
        #expect(c.ground?.nearest == "Fresno-Foundry Park")
        #expect(c.notes.count == 1)
    }

    @Test func decodesActionsAndNullGround() throws {
        let r = try CrewResponse.decode(fixture("crew-palm-springs"))
        #expect(r.plan.confidence?.ground == nil)
        #expect(r.plan.confidence?.level == .modelOnly)
        #expect(r.plan.bms?.recirculateAt == nil)
        let heat = try #require(r.plan.actions.first { $0.rule == "heat-shade" })
        #expect(heat.citation == "Cal/OSHA T8 §3395")
        #expect(heat.clock == "12:00")
        // The planner's own line has an empty cite, which reads as none.
        #expect(r.plan.actions.first { $0.rule == "plan" }?.citation == nil)
    }

    @Test func tempIsFlooredNotRounded() throws {
        let json = Data(#"{"temp_f": 79.7}"#.utf8)
        let m = try JSONDecoder().decode(Metrics.self, from: json)
        #expect(m.tempFFloor == 79)
    }

    @Test func fireAcceptsBooleanWithin50km() throws {
        let json = Data(#"{"nearest_km": 12, "direction": "se", "within_50km": true}"#.utf8)
        let f = try JSONDecoder().decode(Fire.self, from: json)
        #expect(f.isClose)
        #expect(f.bearing == 135)
    }

    @Test func reportsRoundTrip() throws {
        let body = ReportRequest(place: "Fresno", date: "2026-10-24", shift: "07-17", kind: .noN95, note: "")
        let encoded = try JSONEncoder().encode(body)
        let dict = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(dict["kind"] as? String == "no_n95")

        let list = #"{"reports":[{"id":7,"created_at":"2026-10-24T09:12:00Z","kind":"smoke","note":null,"#
            + #""status":"open","handled_at":null}]}"#
        let r = try JSONDecoder().decode(ReportList.self, from: Data(list.utf8))
        #expect(r.reports.first?.id == "7")
        #expect(r.reports.first?.isOpen == true)
    }
}
