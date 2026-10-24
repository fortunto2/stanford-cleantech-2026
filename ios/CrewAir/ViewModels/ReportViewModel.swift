import CrewKit
import Foundation

/// Worker → crew lead. Sends a report and lists today's, tolerating an endpoint that is not
/// live yet: a report that could not be sent stays on the phone, marked unsent.
@Observable
@MainActor
final class ReportViewModel {
    var note = ""
    private(set) var reports: [Report] = []
    private(set) var sending: ReportKind?
    private(set) var message: String?

    private let service: CrewService
    private let plan: PlanViewModel
    private var unsent: [Report] = []

    init(service: CrewService, plan: PlanViewModel) {
        self.service = service
        self.plan = plan
    }

    func send(_ kind: ReportKind) async {
        sending = kind
        defer { sending = nil }
        let body = ReportRequest(
            place: plan.place, date: plan.date, shift: plan.shift.query, kind: kind, note: note
        )
        do {
            let receipt = try await service.sendReport(body)
            message = "Sent to crew lead: \(kind.title)."
            note = ""
            reports.insert(
                Report(id: receipt.id, createdAt: receipt.createdAt, kind: kind, note: body.note,
                       status: receipt.status, handledAt: nil),
                at: 0
            )
            await refresh()
        } catch {
            let local = Report(
                id: UUID().uuidString, createdAt: ISO8601DateFormatter().string(from: .now), kind: kind,
                note: body.note, status: "unsent", handledAt: nil
            )
            unsent.insert(local, at: 0)
            reports.insert(local, at: 0)
            message = "Not sent: \(error.localizedDescription) Kept on this phone."
        }
    }

    func refresh() async {
        do {
            let remote = try await service.reports(place: plan.place, date: plan.date)
            reports = unsent + remote
        } catch {
            // Endpoint not live: keep what we have.
        }
    }
}
