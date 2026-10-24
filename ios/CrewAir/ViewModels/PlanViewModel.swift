import CrewKit
import Foundation

@Observable
@MainActor
final class PlanViewModel {
    enum Day: String, CaseIterable, Identifiable {
        case today, tomorrow
        var id: String { rawValue }
        var title: String {
            switch self {
            case .today: String(localized: "Today")
            case .tomorrow: String(localized: "Tomorrow")
            }
        }
    }

    var place = "Fresno"
    var day: Day = .today
    var shift = Shift(start: 7, end: 17)
    private(set) var response: CrewResponse?
    private(set) var isLoading = false
    private(set) var error: String?

    private let service: CrewService
    private var loaded: String?

    init(service: CrewService, response: CrewResponse? = nil) {
        self.service = service
        self.response = response
    }

    var date: String {
        let now = Date()
        let d = day == .today ? now : Clock.calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let parts = Clock.calendar.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    var digest: PlanDigest? { response.map { PlanDigest(plan: $0.plan) } }

    /// The printable /crew page for the same place, day and shift.
    var briefingURL: URL? {
        var parts = URLComponents(string: "https://airsignal.app/crew")
        parts?.queryItems = [
            URLQueryItem(name: "place", value: place),
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "shift", value: shift.query),
        ]
        return parts?.url
    }

    func load(force: Bool = false) async {
        let key = "\(place)|\(date)|\(shift.query)"
        guard force || key != loaded else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await service.plan(place: place, date: date, shift: shift.query)
            loaded = key
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
