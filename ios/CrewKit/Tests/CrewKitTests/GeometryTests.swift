import CrewKit
import Testing

@Suite struct CompassTests {
    @Test(arguments: [
        ("N", 0.0), ("NE", 45), ("E", 90), ("SE", 135), ("S", 180), ("SW", 225), ("W", 270), ("NW", 315), ("nw", 315),
    ])
    func eightPoints(direction: String, degrees: Double) {
        #expect(Compass.bearing(for: direction) == degrees)
    }

    @Test func unknownIsNil() {
        #expect(Compass.bearing(for: "NNW") == nil)
        #expect(Compass.bearing(for: "") == nil)
    }

    @Test func deltaWrapsAroundNorth() {
        #expect(Compass.delta(from: 350, to: 10) == 20)
        #expect(Compass.delta(from: 10, to: 350) == -20)
    }

    @Test func greatCircleBearingDueEast() {
        let b = Compass.bearing(fromLat: 0, lon: 0, toLat: 0, lon: 1)
        #expect(abs(b - 90) < 1e-9)
    }
}

@Suite struct HorizonProjectionTests {
    let p = HorizonProjection(heading: 300, horizontalFOV: 60, width: 400, height: 800)

    @Test func headingIsCentre() throws {
        #expect(abs(try #require(p.x(for: 300)) - 200) < 1e-9)
    }

    @Test func halfFieldIsRightEdge() throws {
        #expect(abs(try #require(p.x(for: 330)) - 400) < 1e-9)
        #expect(abs(try #require(p.x(for: 270)) - 0) < 1e-9)
    }

    @Test func wrapsAcrossNorth() throws {
        let q = HorizonProjection(heading: 350, horizontalFOV: 60, width: 400, height: 800)
        let x = try #require(q.x(for: 20))
        #expect(abs(x - 400) < 1e-9)
    }

    @Test func behindIsNil() {
        #expect(p.x(for: 120) == nil)
        #expect(p.x(for: 30) == nil) // 90° right
    }

    @Test func pitchUpMovesHorizonDown() {
        #expect(p.horizonY == 400)
        let up = HorizonProjection(heading: 0, pitch: 10, horizontalFOV: 60, width: 400, height: 800)
        #expect(up.horizonY > 400)
    }

    @Test func viewFieldIsNarrowerThanLens() {
        // A 4:3 buffer, portrait, on a 9:19.5 screen: the short side, then cropped.
        let across = HorizonProjection.fieldAcrossView(
            lensFOV: 70, bufferWidth: 3024, bufferHeight: 4032, viewWidth: 393, viewHeight: 852
        )
        #expect(across > 30 && across < 50)
        // Same aspect as the buffer, landscape lens figure across the long side: unchanged.
        let same = HorizonProjection.fieldAcrossView(
            lensFOV: 70, bufferWidth: 4032, bufferHeight: 3024, viewWidth: 400, viewHeight: 300
        )
        #expect(abs(same - 70) < 1e-9)
    }
}
