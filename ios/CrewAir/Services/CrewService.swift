import CrewKit
import Foundation

/// The backend at airsignal.app, behind a protocol so previews and tests run offline.
protocol CrewService: Sendable {
    func plan(place: String, date: String, shift: String) async throws -> CrewResponse
    func sendReport(_ report: ReportRequest) async throws -> ReportReceipt
    func reports(place: String, date: String) async throws -> [Report]
}

enum CrewServiceError: LocalizedError {
    case notLive
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .notLive: "The reports endpoint is not live yet."
        case .http(let code): "Server answered \(code)."
        }
    }
}

struct LiveCrewService: CrewService {
    var base = URL(string: "https://airsignal.app/api")!

    func plan(place: String, date: String, shift: String) async throws -> CrewResponse {
        let url = base.appending(path: "crew").appending(queryItems: [
            URLQueryItem(name: "place", value: place),
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "shift", value: shift),
        ])
        return try CrewResponse.decode(try await get(url))
    }

    func sendReport(_ report: ReportRequest) async throws -> ReportReceipt {
        var request = URLRequest(url: base.appending(path: "crew/report"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(report)
        let (data, response) = try await URLSession.shared.data(for: request)
        try check(response)
        return try JSONDecoder().decode(ReportReceipt.self, from: data)
    }

    func reports(place: String, date: String) async throws -> [Report] {
        let url = base.appending(path: "crew/reports").appending(queryItems: [
            URLQueryItem(name: "place", value: place),
            URLQueryItem(name: "date", value: date),
        ])
        return try JSONDecoder().decode(ReportList.self, from: try await get(url)).reports
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        try check(response)
        return data
    }

    private func check(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 404 || http.statusCode == 405 { throw CrewServiceError.notLive }
        guard (200 ..< 300).contains(http.statusCode) else { throw CrewServiceError.http(http.statusCode) }
    }
}
