import CrewKit
import SwiftUI

/// Rung three: out of the company, without the worker's name. Only the Cal/OSHA link is live.
struct EscalateView: View {
    let report: Report
    /// Fetches the server's complaint draft; nil in previews.
    var draft: (@MainActor () async throws -> ComplaintDraft)?
    @Environment(\.dismiss) private var dismiss
    @State private var complaint = ""
    @State private var fileAt: URL?
    @State private var draftError: String?
    @State private var copied = false

    private static let calOSHA = URL(string: "https://www.dir.ca.gov/dosh/Complaint.htm")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Button("← Back") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.nightInkSecondary)
                    .padding(.horizontal, Theme.Space.s)
                ScreenTitle(
                    title: isOverdue ? String(localized: "Not fixed in 30 minutes")
                        : String(localized: "Take it further"),
                    subtitle: String(localized: "Send it on. Your name is not in it."),
                    ink: Theme.nightInk, secondary: Theme.nightInkSecondary
                )
                complaintEditor
                summary
                if let url = Self.calOSHA {
                    Link(destination: url) {
                        card(String(localized: "Cal/OSHA complaint"),
                             String(localized: "Anonymous if you want. Firing you for it is illegal."),
                             fill: Theme.ground, ink: Theme.inkSecondary)
                    }
                }
                card(String(localized: "Union or worker center"),
                     String(localized: "Coming: once a partner agrees to receive reports"),
                     fill: Theme.heat, ink: Theme.heatInk)
                card(String(localized: "Free legal aid"),
                     String(localized: "Coming: once a partner agrees to receive reports"),
                     fill: Theme.calm, ink: Theme.calmInk)
                Text("Labor Code §6310 protects workers who report safety problems.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.nightInkTertiary)
                    .padding(.horizontal, Theme.Space.s)
                    .padding(.top, Theme.Space.s)
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.top, Theme.Space.l)
            .padding(.bottom, Theme.Space.xxl)
        }
        .background(Theme.night)
        .task { await loadDraft() }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// The draft the worker reads, fills and files themselves. Nothing is sent from here.
    @ViewBuilder
    private var complaintEditor: some View {
        if !complaint.isEmpty || draftError != nil {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Cal/OSHA complaint, drafted").font(Theme.Font.chip).foregroundStyle(Theme.nightAccent)
                Text("Fill the [brackets]. Nothing is sent from the app: you copy it into the form.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.nightInkSecondary)
                if let draftError {
                    Text(draftError).font(.system(size: 13)).foregroundStyle(Theme.nightInkSecondary)
                } else {
                    TextEditor(text: $complaint)
                        .font(.system(size: 15, weight: .medium))
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Theme.ink)
                        .frame(minHeight: 260)
                        .padding(Theme.Space.s)
                        .background(Theme.ground, in: .rect(cornerRadius: Theme.Radius.field))
                    HStack(spacing: Theme.Space.s) {
                        Button {
                            UIPasteboard.general.string = complaint
                            copied = true
                        } label: {
                            Text(copied ? "Copied" : "Copy").primaryButton(fill: Theme.nightCard, ink: Theme.nightInk)
                        }
                        if let url = fileAt ?? Self.calOSHA {
                            Link(destination: url) {
                                Text("Open the Cal/OSHA form").primaryButton(fill: Theme.ground, ink: Theme.ink)
                            }
                        }
                    }
                }
            }
            .padding(Theme.Space.l)
            .background(Theme.nightCard.opacity(0.6), in: .rect(cornerRadius: Theme.Radius.tile))
        }
    }

    private var isOverdue: Bool {
        (ReportClock.minutesUntilEscalation(since: report.createdAt, now: .now) ?? 0) == 0
    }

    private func loadDraft() async {
        guard let draft, complaint.isEmpty, Int(report.id) != nil else { return }
        do {
            let result = try await draft()
            complaint = result.complaint
            fileAt = result.fileAt
        } catch {
            draftError = String(localized: "No draft for this report yet: \(error.localizedDescription)")
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What goes with it").font(Theme.Font.chip).foregroundStyle(Theme.nightAccent)
            Text(facts).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.nightInk)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.l + 2).padding(.vertical, Theme.Space.l)
        .background(Theme.nightCard, in: .rect(cornerRadius: Theme.Radius.tile))
    }

    private var facts: String {
        var parts = [report.headline]
        if let aqi = report.evidence?.metrics?.usAqiPm25 { parts.append(String(localized: "Forecast AQI \(aqi)")) }
        if let fire = report.evidence?.fire {
            parts.append(String(localized: "fire \(Int(fire.nearestKm)) km \(fire.direction) (NASA satellite)"))
        }
        if let ground = report.evidence?.ground {
            parts.append(String(localized: "monitor \(Int(ground.pm25.rounded())) µg/m³"))
        }
        return parts.joined(separator: ". ") + "."
    }

    private func card(_ title: String, _ note: String, fill: Color, ink: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(title).font(.system(size: 20, weight: .heavy)).foregroundStyle(Theme.ink)
            Text(note).font(Theme.Font.tileNote).foregroundStyle(ink)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(Theme.Space.l + 2)
        .background(fill, in: .rect(cornerRadius: Theme.Radius.tile))
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    EscalateView(report: Report.previews[0])
}
