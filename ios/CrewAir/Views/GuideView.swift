import SwiftUI

/// First launch, and the "?" on Plan: two short paths, one for the people working outside and
/// one for the people running the crew. Big type, few words.
struct GuideView: View {
    enum Path: Hashable { case worker, employer }

    /// Called with the chosen path, or nil when closed without choosing.
    let onDone: (Path?) -> Void
    @State private var path: Path?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    switch path {
                    case nil: chooser
                    case .worker: WorkerGuide()
                    case .employer: EmployerGuide()
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.l)
            }
            .background(Theme.ground)
            .toolbar {
                if path != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") { path = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Start") { onDone(path) }.fontWeight(.bold)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { onDone(nil) }
                    }
                }
            }
        }
        .tint(Theme.ink)
    }

    private var chooser: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            ScreenTitle(
                title: String(localized: "Smoke and heat, shift by shift"),
                subtitle: String(localized: "What California's rules give your crew today, and a way to speak up.")
            )
            choice(String(localized: "I work outside"),
                   String(localized: "What you are owed, how to report, how to check the sky"),
                   fill: Theme.color(.unhealthy), ink: .white) { path = .worker }
            choice(String(localized: "I run a crew / I'm the employer"),
                   String(localized: "What you must do and when, and the reports to answer"),
                   fill: Theme.calm, ink: Theme.ink) { path = .employer }
        }
    }

    private func choice(_ title: String, _ note: String, fill: Color, ink: Color,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(title).font(.system(size: 24, weight: .heavy))
                Text(note).font(Theme.Font.tileNote)
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .padding(Theme.Space.xl - 2)
            .background(fill, in: .rect(cornerRadius: Theme.Radius.hero))
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
    }
}

/// One fact: a big figure and what it means.
struct GuideCard: View {
    let figure: String
    let title: String
    let text: String
    var fill: Color = Theme.card

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(figure).font(.system(size: 34, weight: .heavy)).kerning(-1)
            Text(title).font(.system(size: 19, weight: .heavy))
            Text(text).font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.inkSecondary)
        }
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.l + 2)
        .background(fill, in: .rect(cornerRadius: Theme.Radius.tile))
        .accessibilityElement(children: .combine)
    }
}

/// Where the guide's numbers come from.
struct GuideSources: View {
    var body: some View {
        Text("AgSafe/WCNGG Cal/OSHA enforcement summaries; DIR 2024-105; Sonoma County farmworker study 2025.")
            .font(.system(size: 11)).foregroundStyle(Theme.inkTertiary).padding(.horizontal, Theme.Space.s)
    }
}

struct WorkerGuide: View {
    var body: some View {
        ScreenTitle(
            title: String(localized: "If you work outside"),
            subtitle: String(localized: "California law, Cal/OSHA §5141.1 and §3395.")
        )
        GuideCard(figure: "AQI 151", title: String(localized: "N95s are owed to you"),
                  text: String(localized: """
                  At AQI 151 the employer provides them. You should not pay: in a 2025 Sonoma study \
                  nearly a third of farmworkers bought their own.
                  """), fill: Theme.sick)
        GuideCard(figure: "80°F · 95°F", title: String(localized: "The law, not a favour"),
                  text: String(localized: "Shade and water at 80°F, breaks and a watchful eye at 95°F."),
                  fill: Theme.heat)
        GuideCard(figure: String(localized: "One tap"), title: String(localized: "No name, with the evidence"),
                  text: String(localized: """
                  The report reaches the crew lead with the air data attached, so it is not your \
                  word against theirs. Not fixed in 30 minutes? You can take it further.
                  """))
        GuideCard(figure: String(localized: "Sky"), title: String(localized: "Check the sky"),
                  text: String(localized: """
                  Point the phone at the horizon. Faces are blacked out on the phone, only the sky \
                  is sent. If it looks worse than the forecast, report it in one tap.
                  """), fill: Theme.calm)
        GuideCard(figure: "§6310", title: String(localized: "You are protected"),
                  text: String(localized: "Firing or punishing you for a safety report is illegal (Labor Code §6310)."),
                  fill: Theme.ok)
        GuideSources()
    }
}

struct EmployerGuide: View {
    var body: some View {
        ScreenTitle(
            title: String(localized: "If you run the crew"),
            subtitle: String(localized: "What it is worth, in money and in time.")
        )
        GuideCard(figure: "$3,300", title: String(localized: "Per heat-illness violation"),
                  text: String(localized: """
                  Heat illness (§3395) is Cal/OSHA's most-cited rule in agriculture every year: 130 \
                  violations and $404,000 in 2017–18, about $3,300 each. Willful cases go far \
                  higher: $276,425 for one landscaping company in 2024.
                  """), fill: Theme.sick)
        GuideCard(figure: String(localized: "1 min"), title: String(localized: "The usual miss is paper"),
                  text: String(localized: "No plan on site. The briefing sheet is that plan, made in a minute."),
                  fill: Theme.heat)
        GuideCard(figure: String(localized: "By the hour"), title: String(localized: "No morning air checks"),
                  text: String(localized: """
                  The plan gives the hour each rule starts and the clean window, so heavy work moves \
                  instead of the shift stopping.
                  """), fill: Theme.calm)
        GuideCard(figure: "30 min", title: String(localized: "A fix, not a complaint"),
                  text: String(localized: """
                  Reports handled within 30 minutes stay a fix between you and your crew, not a complaint.
                  """), fill: Theme.ok)
        GuideCard(figure: String(localized: "Mode"), title: String(localized: "Turn on crew-lead mode"),
                  text: String(localized: "In Report, \"I'm the crew lead\" shows open reports with a countdown."))
        Text("A planning aid, not legal advice. The rules themselves are in Title 8, §5141.1 and §3395.")
            .font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary).padding(.horizontal, Theme.Space.s)
        GuideSources()
    }
}

#Preview {
    GuideView { _ in }
}
