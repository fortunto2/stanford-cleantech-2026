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
                if let report = model.reports.first(where: { $0.id == id }) { EscalateView(report: report) }
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
            Button { Task { await model.send() } } label: {
                Text(model.isSending ? "Sending…" : "Send").primaryButton()
            }
            .disabled(model.isSending)
            if let message = model.message {
                Text(message).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
            }
            if !model.reports.isEmpty { list }
            if let report = model.toEscalate {
                NavigationLink(value: report.id) {
                    Text("Not fixed in 30 min? Take it further →")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, Theme.Space.s)
                }
            }
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
                    Text(report.headline).font(Theme.Font.row).foregroundStyle(Theme.ink).lineLimit(2)
                    Spacer(minLength: 0)
                    StatusPill(report: report)
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
