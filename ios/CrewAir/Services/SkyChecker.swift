import Foundation

/// What gets sent to the vision model: the sky only, cropped above the horizon line, so no
/// faces or plates leave the phone.
struct SkyCheckRequest: Sendable {
    let skyCropJPEG: Data?
    let heading: Double
    let place: String
}

struct SkyVerdict: Sendable, Equatable {
    let summary: String
    let smokeVisible: Bool?
}

/// Decides from a sky photo whether smoke is visible. Will be a vision decision model.
protocol SkyChecker: Sendable {
    func check(_ request: SkyCheckRequest) async throws -> SkyVerdict
}

struct StubSkyChecker: SkyChecker {
    func check(_ request: SkyCheckRequest) async throws -> SkyVerdict {
        try await Task.sleep(for: .milliseconds(600))
        return SkyVerdict(summary: "Sky check is not wired yet: the vision model comes next.", smokeVisible: nil)
    }
}
