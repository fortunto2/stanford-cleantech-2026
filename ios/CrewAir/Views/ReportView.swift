import CrewKit
import SwiftUI

/// The worker's side of the ladder, or the crew lead's board when the toggle is on.
struct ReportView: View {
    @Bindable var model: ReportViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    Toggle(isOn: $model.isLead) {
                        Text("I'm the crew lead").font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
                    }
                    .tint(Theme.okSolid)
                    .padding(.horizontal, Theme.Space.s)
                    if model.isLead {
                        LeadBoard(model: model)
                    } else {
                        WorkerReport(model: model)
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.top, Theme.Space.s)
                .padding(.bottom, Theme.Space.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.ground)
            .refreshable { await model.refresh() }
            .task { await model.refresh() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let report = model.reports.first(where: { $0.id == id }) {
                    EscalateView(report: report) { try await model.complaint(for: report) }
                }
            }
        }
    }
}

struct WorkerReport: View {
    @Bindable var model: ReportViewModel

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            ScreenTitle(
                title: String(localized: "Something wrong?"),
                subtitle: String(localized: "Tell the crew lead. No name needed.")
            )
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ReportKind.primary) { kind in kindButton(kind) }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Where? (optional)").font(Theme.Font.tileNote).foregroundStyle(Theme.inkSecondary)
                TextField("east block", text: $model.note)
                    .font(Theme.Font.field)
                    .padding(.horizontal, Theme.Space.l)
                    .frame(height: Theme.Size.field)
                    .background(Theme.field, in: .rect(cornerRadius: Theme.Radius.field))
                    .submitLabel(.send)
                    .onSubmit { Task { await model.send() } }
            }
            SendDisclosure(placeName: model.placeName, sendsLocation: model.sendsLocation)
            Button { Task { await model.send() } } label: {
                Text(model.isSending ? "Sending…" : "Send").primaryButton()
            }
            .disabled(model.isSending)
            if let message = model.message {
                Text(message).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
            }
            if !model.reports.isEmpty { list }
        }
    }

    private func kindButton(_ kind: ReportKind) -> some View {
        let selected = model.selected == kind
        return Button { model.selected = kind } label: {
            Text(kind.label)
                .font(selected ? .system(size: 19, weight: .heavy) : Theme.Font.kind)
                .foregroundStyle(kind.ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.kindButton, alignment: .leading)
                .padding(.horizontal, Theme.Space.l + 2)
                .background(kind.fill, in: .rect(cornerRadius: Theme.Radius.tile))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.tile)
                        .strokeBorder(selected ? Theme.ink : .clear, lineWidth: Theme.Size.selectedBorder)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var list: some View {
        VStack(spacing: Theme.Space.m) {
            ForEach(model.reports) { report in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.headline).font(Theme.Font.row).foregroundStyle(Theme.ink).lineLimit(2)
                        if let from = report.evidence?.from.flatMap(OriginText.report) {
                            Text(from).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                    StatusPill(report: report)
                }
                if report.isOpen, Int(report.id) != nil {
                    NavigationLink(value: report.id) { ComplaintEntry(report: report) }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Theme.Space.l + 2)
        .padding(.vertical, Theme.Space.l)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.tile))
        .padding(.top, Theme.Space.xs)
    }
}

struct ScreenTitle: View {
    let title: String
    let subtitle: String
    var ink = Theme.ink
    var secondary = Theme.inkSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.Font.title).foregroundStyle(ink)
            Text(subtitle).font(Theme.Font.subtitle).foregroundStyle(secondary)
        }
        .padding(.horizontal, Theme.Space.s)
        .padding(.bottom, Theme.Space.xs)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    let plan = PlanViewModel(service: PreviewCrewService(), response: .preview)
    ReportView(model: ReportViewModel(service: PreviewCrewService(), plan: plan, reports: Report.previews))
}

/// "Prepare a Cal/OSHA complaint", on every open report, from the first minute. The 30 minutes
/// are a courtesy to the crew lead, said under it, not a lock.
struct ComplaintEntry: View {
    let report: Report

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let left = ReportClock.minutesUntilEscalation(since: report.createdAt, now: context.date) ?? 0
            VStack(alignment: .leading, spacing: 2) {
                Text(left > 0 ? "Prepare a Cal/OSHA complaint" : "Not handled: prepare a complaint")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.color(.unhealthy))
                if left > 0 {
                    Text("Usually give the crew lead 30 minutes first (\(left) left)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
    }
}
