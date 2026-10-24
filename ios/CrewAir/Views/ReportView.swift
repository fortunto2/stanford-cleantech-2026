import CrewKit
import SwiftUI

struct ReportView: View {
    @Bindable var model: ReportViewModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    Text("Tell your crew lead").font(.headline)
                    TextField("Note (optional)", text: $model.note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    LazyVGrid(columns: columns, spacing: Theme.Space.s) {
                        ForEach(ReportKind.allCases) { kind in button(kind) }
                    }
                    if let message = model.message {
                        Text(message).font(.footnote).foregroundStyle(Theme.textSecondary)
                    }
                    list
                    EscalateRow()
                }
                .padding(Theme.Space.l)
            }
            .refreshable { await model.refresh() }
            .task { await model.refresh() }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func button(_ kind: ReportKind) -> some View {
        Button {
            Task { await model.send(kind) }
        } label: {
            Text(model.sending == kind ? "Sending…" : kind.title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.reportButtonHeight)
        }
        .buttonStyle(.bordered)
        .disabled(model.sending != nil)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Today").font(.headline)
            if model.reports.isEmpty {
                Text("No reports yet.").font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
            ForEach(model.reports) { report in
                HStack {
                    VStack(alignment: .leading) {
                        Text(report.kind.title).font(.subheadline.weight(.semibold))
                        if let note = report.note, !note.isEmpty { Text(note).font(.caption) }
                    }
                    Spacer()
                    Text(report.status).font(.caption.weight(.semibold))
                        .foregroundStyle(report.isOpen ? Theme.warning : Theme.textSecondary)
                }
                Divider()
            }
        }
    }
}

/// Mock only. If the crew lead does not act within 30 minutes, the report goes outside the
/// company, without the worker's name.
struct EscalateRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Label("Escalate anonymously (after 30 min unresolved)", systemImage: "lock.shield")
                .font(.subheadline.weight(.semibold))
            Text(
                "Sends the report without your name to a union, legal aid, or as a Cal/OSHA complaint. "
                    + "Not available yet."
            )
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.separator, style: StrokeStyle(dash: [4]))
        )
        .opacity(0.5)
        .padding(.top, Theme.Space.xl)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Not available yet")
    }
}

#Preview {
    let plan = PlanViewModel(service: PreviewCrewService(), response: .preview)
    ReportView(model: ReportViewModel(service: PreviewCrewService(), plan: plan))
}
