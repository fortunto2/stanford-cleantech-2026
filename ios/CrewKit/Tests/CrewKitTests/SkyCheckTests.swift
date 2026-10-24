import CrewKit
import Foundation
import Testing

@Suite struct SkyCheckTests {
    @Test func decodesRecordedSmokeAnswer() throws {
        let url = try #require(
            Bundle.module.url(forResource: "sky-check-smoke", withExtension: "json", subdirectory: "Fixtures")
        )
        let r = try JSONDecoder().decode(SkyCheckResult.self, from: Data(contentsOf: url))
        #expect(r.smokeCall == .yes)
        #expect(r.skyVisible)
        #expect(r.smoke > 0.9)
        #expect(r.looksWorseThanModel == true)
        #expect(r.model?.aqi == 41)
        #expect(r.visibility?.trusted == false)
        #expect(r.shouldReport)
    }

    @Test func toleratesNullsAndUnknownCall() throws {
        let json = #"{"verdict":"?","smoke_call":"maybe","sky_visible":false,"smoke":0.4,"#
            + #""visibility":null,"model":null,"#
            + #""looks_worse_than_model":null}"#
        let r = try JSONDecoder().decode(SkyCheckResult.self, from: Data(json.utf8))
        #expect(r.smokeCall == .unsure)
        #expect(r.model == nil)
        #expect(!r.shouldReport)
    }

    @Test func cropKeepsSkyAndAStripOfGround() {
        #expect(SkyCrop.keepFraction(horizon: 0.5) == 0.62)
        #expect(SkyCrop.keepFraction(horizon: 0.95) == 1)
        #expect(SkyCrop.keepFraction(horizon: 0.1) == nil)
        #expect(SkyCrop.keepFraction(horizon: 1.4) == nil)
    }

    @Test func fitsLongSide() {
        #expect(SkyCrop.fitted(width: 3024, height: 4032) == (576, 768))
        #expect(SkyCrop.fitted(width: 640, height: 480) == (640, 480))
    }
}
