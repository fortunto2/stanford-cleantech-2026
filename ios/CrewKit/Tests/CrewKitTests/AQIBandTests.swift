import CrewKit
import Testing

@Suite struct AQIBandTests {
    @Test(arguments: [
        (0, AQIBand.good), (50, .good), (51, .moderate), (100, .moderate), (101, .sensitive),
        (150, .sensitive), (151, .unhealthy), (200, .unhealthy), (201, .veryUnhealthy),
        (300, .veryUnhealthy), (301, .hazardous), (500, .hazardous),
    ])
    func boundaries(aqi: Int, band: AQIBand) {
        #expect(AQIBand(aqi: aqi) == band)
    }
}
