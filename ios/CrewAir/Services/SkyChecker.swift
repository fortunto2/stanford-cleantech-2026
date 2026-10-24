import CrewKit
import Foundation

/// Decides from a sky photo whether smoke is visible. The photo is already prepared: faces
/// blacked out, cropped to the sky, at most 768 px on the long side.
protocol SkyChecker: Sendable {
    func check(jpeg: Data, place: String) async throws -> SkyCheckResult
}

/// Jev at airsignal.app. A raw `image/jpeg` body, not multipart: Astro's origin check refuses a
/// multipart POST that carries no Origin header, which is every app request.
struct LiveSkyChecker: SkyChecker {
    var endpoint = URL(string: "https://airsignal.app/api/sky-check")!

    private struct Failure: Decodable { let error: String }

    func check(jpeg: Data, place: String) async throws -> SkyCheckResult {
        var request = URLRequest(url: endpoint.appending(queryItems: [URLQueryItem(name: "place", value: place)]))
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = jpeg
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
            if let failure = try? JSONDecoder().decode(Failure.self, from: data) {
                throw SkyCheckError.server(failure.error)
            }
            throw CrewServiceError.http(http.statusCode)
        }
        return try JSONDecoder().decode(SkyCheckResult.self, from: data)
    }
}

enum SkyCheckError: LocalizedError {
    case server(String)
    case noImage

    var errorDescription: String? {
        switch self {
        case .server(let message): message
        case .noImage: String(localized: "Could not read that photo.")
        }
    }
}

/// Offline stand-in for previews.
struct StubSkyChecker: SkyChecker {
    func check(jpeg: Data, place: String) async throws -> SkyCheckResult {
        let json = #"{"verdict":"Smoke or haze in the air.","smoke_call":"yes","sky_visible":true,"smoke":0.9,"#
            + #""model":{"aqi":41,"place":"Fresno"},"looks_worse_than_model":true}"#
        return try JSONDecoder().decode(SkyCheckResult.self, from: Data(json.utf8))
    }
}
