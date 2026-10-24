import CrewKit
import Foundation

/// The backend at airsignal.app, behind a protocol so previews and tests run offline.
protocol CrewService: Sendable {
    func plan(place: String, date: String, shift: String) async throws -> CrewResponse
    func sendReport(_ report: ReportRequest) async throws -> ReportReceipt
    func reports(place: String, date: String) async throws -> [Report]
    func handle(_ request: HandleRequest) async throws -> HandleReceipt
    func places(matching text: String) async throws -> [PlaceSuggestion]
    func complaint(report id: String) async throws -> ComplaintDraft
}

enum CrewServiceError: LocalizedError {
    case notLive
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .notLive: String(localized: "The reports server is not reachable.")
        case .http(let code): String(localized: "Server answered \(code).")
        }
    }
}

struct LiveCrewService: CrewService {
    var base = URL(string: "https://airsignal.app/api")!

    /// No local HTTP cache: a plan read hours ago must not stand in for today's, and reports are live.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    func plan(place: String, date: String, shift: String) async throws -> CrewResponse {
        let url = base.appending(path: "crew").appending(queryItems: [
            URLQueryItem(name: "place", value: place),
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "shift", value: shift),
        ])
        return try CrewResponse.decode(try await get(url))
    }

    func sendReport(_ report: ReportRequest) async throws -> ReportReceipt {
        try JSONDecoder().decode(ReportReceipt.self, from: try await post(report))
    }

    func handle(_ request: HandleRequest) async throws -> HandleReceipt {
        try JSONDecoder().decode(HandleReceipt.self, from: try await post(request))
    }

    func places(matching text: String) async throws -> [PlaceSuggestion] {
        let url = base.appending(path: "crew/places").appending(queryItems: [URLQueryItem(name: "q", value: text)])
        return try JSONDecoder().decode(PlaceList.self, from: try await get(url)).places
    }

    func complaint(report id: String) async throws -> ComplaintDraft {
        let url = base.appending(path: "crew/complaint").appending(queryItems: [URLQueryItem(name: "report", value: id)])
        return try JSONDecoder().decode(ComplaintDraft.self, from: try await get(url))
    }

    private func post(_ body: some Encodable) async throws -> Data {
        var request = URLRequest(url: base.appending(path: "crew/report"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await Self.session.data(for: request)
        try check(response)
        return data
    }

    func reports(place: String, date: String) async throws -> [Report] {
        let url = base.appending(path: "crew/reports").appending(queryItems: [
            URLQueryItem(name: "place", value: place),
            URLQueryItem(name: "date", value: date),
        ])
        return try JSONDecoder().decode(ReportList.self, from: try await get(url)).reports
    }

    private func get(_ url: URL) async throws -> Data {
        let (data, response) = try await Self.session.data(from: url)
        try check(response)
        return data
    }

    private func check(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 405 { throw CrewServiceError.notLive }
        guard (200 ..< 300).contains(http.statusCode) else { throw CrewServiceError.http(http.statusCode) }
    }
}
