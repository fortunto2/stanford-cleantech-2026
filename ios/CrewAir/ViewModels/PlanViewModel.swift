import CrewKit
import Foundation
import SuperDuperAnalytics

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

    /// What the API is asked for: a name ("Fresno") or a coordinate ("36.7477,-119.7724").
    private(set) var place: String
    /// The name to show for it, when the place is a coordinate the user picked.
    private(set) var placeLabel: String?
    /// Plan for where the phone is, as fixes arrive. On until a place is chosen by hand.
    private(set) var followsLocation: Bool
    var day: Day = .today
    var shift = Shift(start: 7, end: 17)
    private(set) var response: CrewResponse?
    private(set) var isLoading = false
    private(set) var error: String?

    private let service: CrewService
    private var loaded: String?

    private enum Key {
        static let place = "place"
        static let label = "placeLabel"
        static let follows = "followsLocation"
    }

    init(service: CrewService, response: CrewResponse? = nil) {
        self.service = service
        self.response = response
        let saved = UserDefaults.standard
        place = saved.string(forKey: Key.place) ?? "Fresno"
        placeLabel = saved.string(forKey: Key.label)
        // A first launch follows the phone; a place picked by hand sticks.
        followsLocation = saved.object(forKey: Key.follows) as? Bool ?? true
    }

    /// "Fresno", "near Fresno": the chosen name, else the name the plan came back with.
    var displayName: String {
        if let placeLabel { return placeLabel }
        if let name = response?.place.name { return String(name.split(separator: ",").first ?? Substring(name)) }
        return PlaceQuery.isCoordinate(place) ? String(localized: "Here") : place
    }

    /// The service, for the place search.
    var placeService: CrewService { service }

    /// A suggestion from the search, or a name typed and submitted.
    func choose(_ suggestion: PlaceSuggestion) {
        set(place: suggestion.query, label: suggestion.name, follows: false)
    }

    func choose(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        set(place: trimmed, label: nil, follows: false)
    }

    /// "Use my location": follow the phone from now on.
    func useLocation(lat: Double?, lon: Double?) {
        followsLocation = true
        UserDefaults.standard.set(true, forKey: Key.follows)
        if let lat, let lon { located(lat: lat, lon: lon) }
    }

    /// A fix arrived. Re-plans only when following and the phone moved more than ~1 km.
    func located(lat: Double, lon: Double) {
        guard followsLocation else { return }
        let query = PlaceQuery.coordinate((lat * 100).rounded() / 100, (lon * 100).rounded() / 100)
        guard query != place else { return }
        set(place: query, label: nil, follows: true)
    }

    private func set(place: String, label: String?, follows: Bool) {
        self.place = place
        placeLabel = label
        followsLocation = follows
        let saved = UserDefaults.standard
        saved.set(place, forKey: Key.place)
        saved.set(label, forKey: Key.label)
        saved.set(follows, forKey: Key.follows)
        Task { await load() }
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
            Analytics.track("plan_viewed")
        } catch {
            self.error = error.localizedDescription
        }
    }
}
