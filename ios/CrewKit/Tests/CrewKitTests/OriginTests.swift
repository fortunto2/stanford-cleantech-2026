import CrewKit
import Foundation
import Testing

@Suite struct OriginTests {
    @Test func exifSouthWestIsNegative() {
        let o = PhotoOrigin(
            gps: ["Latitude": 36.71, "LatitudeRef": "N", "Longitude": 119.78, "LongitudeRef": "W",
                  "ImgDirection": 182.4],
            exif: ["DateTimeOriginal": "2026:10:24 10:05:12"]
        )
        #expect(o.lat == 36.71)
        #expect(o.lon == -119.78)
        #expect(o.headingDeg == 182.4)
        #expect(o.takenClock == "10:05")
        #expect(o.hasPosition)
    }

    @Test func noGPSIsEmpty() {
        let o = PhotoOrigin(gps: nil, exif: nil)
        #expect(o.isEmpty)
        #expect(o.takenClock == nil)
    }

    @Test func compassPoints() {
        #expect(Compass.point(for: 182) == "S")
        #expect(Compass.point(for: 350) == "N")
        #expect(Compass.point(for: 300) == "NW")
    }

    @Test func requestCarriesOriginAndSky() throws {
        let body = ReportRequest(
            place: "Barstow", date: "2026-10-24", shift: "07-17", kind: .smoke, note: "",
            origin: .init(lat: 34.9, lon: -117.02, accuracyM: 12, headingDeg: 182),
            sky: SkySummary(smoke: 0.97, smokeCall: "yes", verdict: "Smoke")
        )
        let dict = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any])
        #expect(dict["heading_deg"] as? Double == 182)
        #expect(dict["accuracy_m"] as? Double == 12)
        #expect((dict["sky"] as? [String: Any])?["smoke_call"] as? String == "yes")
        // Without an origin the keys are absent, not null.
        let bare = ReportRequest(place: "Barstow", date: "2026-10-24", shift: "07-17", kind: .smoke, note: "")
        let bareDict = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(bare)) as? [String: Any])
        #expect(bareDict["lat"] == nil)
    }

    @Test func decodesLiveFrom() throws {
        let json = """
        {"where":{"lat":34.9,"lon":-117.02,"accuracy_m":12},
         "facing":{"heading_deg":182,"compass":"S","toward_fire":true},
         "sky":{"smoke":0.97,"smoke_call":"yes","verdict":"Smoke or haze in the air."}}
        """
        let o = try JSONDecoder().decode(ReportOrigin.self, from: Data(json.utf8))
        #expect(o.position?.lat == 34.9)
        #expect(o.facing?.compass == "S")
        #expect(o.facing?.towardFire == true)
        #expect(o.sky?.smokeCall == "yes")
    }
}
