import CrewKit
import Foundation

/// Worker → crew lead, and the crew lead's board. A report the server refuses stays on the
/// phone marked unsent, so a tap is never lost silently.
@Observable
@MainActor
final class ReportViewModel {
    var selected: ReportKind = .smoke
    var note = ""
    /// The crew lead sees the board instead of the report buttons. Remembered on this phone.
    var isLead: Bool {
        didSet { UserDefaults.standard.set(isLead, forKey: Self.leadKey) }
    }
    /// "What you did", per open report id.
    var leadNotes: [String: String] = [:]
    private(set) var reports: [Report] = []
    private(set) var isSending = false
    private(set) var handling: String?
    private(set) var message: String?

    private let service: CrewService
    private let plan: PlanViewModel
    private var unsent: [Report] = []
    private static let leadKey = "isCrewLead"

    init(service: CrewService, plan: PlanViewModel, reports: [Report] = []) {
        self.service = service
        self.plan = plan
        self.reports = reports
        isLead = UserDefaults.standard.bool(forKey: Self.leadKey)
    }

    var place: String { plan.place }
    var open: [Report] { reports.filter(\.isOpen) }
    var handled: [Report] { reports.filter(\.isHandled) }
    /// The one to take further: the oldest still open.
    var toEscalate: Report? { open.last }

    func send() async {
        isSending = true
        defer { isSending = false }
        let body = ReportRequest(
            place: plan.place, date: plan.date, shift: plan.shift.query, kind: selected, note: note
        )
        do {
            let receipt = try await service.sendReport(body)
            message = String(localized: "Sent to the crew lead.")
            note = ""
            reports.insert(
                Report(id: receipt.id, createdAt: receipt.createdAt, kind: selected, note: body.note,
                       status: receipt.status),
                at: 0
            )
            await refresh()
        } catch {
            let local = Report(
                id: UUID().uuidString, createdAt: ISO8601DateFormatter().string(from: .now), kind: selected,
                note: body.note, status: "unsent"
            )
            unsent.insert(local, at: 0)
            reports.insert(local, at: 0)
            message = String(localized: "Not sent: \(error.localizedDescription) Kept on this phone.")
        }
    }

    func handle(_ report: Report) async {
        guard let id = Int(report.id) else { return }
        handling = report.id
        defer { handling = nil }
        let body = HandleRequest(place: plan.place, date: plan.date, id: id, note: leadNotes[report.id] ?? "")
        do {
            _ = try await service.handle(body)
            leadNotes[report.id] = nil
            message = nil
            await refresh()
        } catch {
            message = String(localized: "Could not mark it fixed: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        do {
            let remote = try await service.reports(place: plan.place, date: plan.date)
            reports = unsent + remote
        } catch {
            // Server unreachable: keep what we have.
        }
    }
}
