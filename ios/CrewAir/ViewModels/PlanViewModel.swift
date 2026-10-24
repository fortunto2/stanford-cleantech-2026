import CrewKit
import Foundation

@Observable
@MainActor
final class PlanViewModel {
    enum Day: String, CaseIterable, Identifiable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        var id: String { rawValue }
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

    /// The crews are in California; the plan's hours are Pacific wall-clock.
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return c
    }()

    var date: String {
        let now = Date()
        let d = day == .today ? now : Self.calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let parts = Self.calendar.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
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
