import CrewKit
import SwiftUI

/// Rung three: out of the company, without the worker's name. Only the Cal/OSHA link is live.
struct EscalateView: View {
    let report: Report
    @Environment(\.dismiss) private var dismiss

    private static let calOSHA = URL(string: "https://www.dir.ca.gov/dosh/Complaint.htm")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Button("← Back") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.nightInkSecondary)
                    .padding(.horizontal, Theme.Space.s)
                ScreenTitle(
                    title: String(localized: "Not fixed in 30 minutes"),
                    subtitle: String(localized: "Send it on. Your name is not in it."),
                    ink: Theme.nightInk, secondary: Theme.nightInkSecondary
                )
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
        .toolbar(.hidden, for: .navigationBar)
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
