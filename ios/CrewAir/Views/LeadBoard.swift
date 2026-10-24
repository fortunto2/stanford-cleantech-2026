import CrewKit
import SwiftUI

/// The crew lead's side: open reports with their evidence and a clock, and a way to close them.
struct LeadBoard: View {
    @Bindable var model: ReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            ScreenTitle(
                title: String(localized: "\(model.open.count) reports waiting"),
                subtitle: String(localized: "Crew lead · \(model.placeName)")
            )
            ForEach(model.open) { report in OpenReportCard(model: model, report: report) }
            if let message = model.message {
                Text(message).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
            }
            ForEach(model.handled) { report in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.headline).font(Theme.Font.row)
                        if let note = report.handledNote, !note.isEmpty {
                            Text(note).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                    StatusPill(report: report)
                }
                .padding(.horizontal, Theme.Space.l + 2).padding(.vertical, Theme.Space.l)
                .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.tile))
            }
            if model.reports.isEmpty {
                Text("No reports today.").font(Theme.Font.subtitle).foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, Theme.Space.s)
            }
        }
    }
}

struct OpenReportCard: View {
    @Bindable var model: ReportViewModel
    let report: Report

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(report.headline).font(Theme.Font.cardTitle)
            countdown
            EvidenceTiles(evidence: report.evidence)
            VStack(alignment: .leading, spacing: 6) {
                Text("What you did").font(Theme.Font.tileNote).foregroundStyle(Theme.inkSecondary)
                TextField("N95s out, work moved west", text: note)
                    .font(Theme.Font.field)
                    .padding(.horizontal, Theme.Space.l)
                    .frame(height: Theme.Size.field)
                    .background(Theme.fieldOnCard, in: .rect(cornerRadius: Theme.Radius.field))
            }
            Button { Task { await model.handle(report) } } label: {
                Text(model.handling == report.id ? "Saving…" : "Mark fixed")
                    .primaryButton(fill: Theme.okSolid, ink: .white)
            }
            .disabled(model.handling != nil || Int(report.id) == nil)
        }
        .foregroundStyle(Theme.ink)
        .padding(Theme.Space.xl - 2)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.hero))
    }

    private var note: Binding<String> {
        Binding { model.leadNotes[report.id] ?? "" } set: { model.leadNotes[report.id] = $0 }
    }

    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let left = ReportClock.minutesUntilEscalation(since: report.createdAt, now: context.date) ?? 0
            HStack {
                Text(left > 0 ? "Goes further in" : "Can go further now")
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.waitingInk)
                Spacer()
                if left > 0 { Text("\(left) min").font(Theme.Font.countdown) }
            }
            .padding(.horizontal, Theme.Space.l).padding(.vertical, 14)
            .background(Theme.heat, in: .rect(cornerRadius: Theme.Radius.button))
        }
    }
}

/// Four facts the server attached when the report was made.
struct EvidenceTiles: View {
    let evidence: Evidence?

    private let columns = [GridItem(.flexible(), spacing: Theme.Space.s), GridItem(.flexible(), spacing: Theme.Space.s)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Space.s) {
            tile(String(localized: "Forecast"), value: evidence?.metrics?.usAqiPm25.map { "AQI \($0)" },
                 fill: Theme.ok, ink: Theme.okInk)
            tile(String(localized: "Satellite"),
                 value: evidence?.fire.map { String(localized: "Fire \(Int($0.nearestKm)) km") },
                 fill: Theme.sick, ink: Theme.sickInk)
            tile(String(localized: "Monitor"), value: evidence?.ground.map { "\(Int($0.pm25.rounded())) µg" },
                 fill: Theme.calm, ink: Theme.calmInk)
            facingTile
        }
    }

    /// "Facing S" with "toward the fire" or the coordinates under it.
    private var facingTile: some View {
        let from = evidence?.from
        let value = from?.facing.map { String(localized: "Facing \(Compass.point(for: $0.headingDeg))") }
        let note: String? = if from?.facing?.towardFire == true {
            String(localized: "toward the fire")
        } else {
            from?.position.map { OriginText.coordinate($0.lat, $0.lon) }
        }
        let located = from?.position != nil ? String(localized: "Located") : nil
        return tile(
            String(localized: "Where"), value: value ?? located, note: note, fill: Theme.heat, ink: Theme.heatInk
        )
    }

    private func tile(_ label: String, value: String?, note: String? = nil, fill: Color, ink: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(ink)
            Text(value ?? "–").font(Theme.Font.evidence).lineLimit(1).minimumScaleFactor(0.6)
            if let note { Text(note).font(.system(size: 12, weight: .semibold)).foregroundStyle(ink).lineLimit(1) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.m)
        .background(fill, in: .rect(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let plan = PlanViewModel(service: PreviewCrewService(), response: .preview)
    ScrollView {
        LeadBoard(model: ReportViewModel(service: PreviewCrewService(), plan: plan, reports: Report.previews))
            .padding()
    }
    .background(Theme.ground)
}
