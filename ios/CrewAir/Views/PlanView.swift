import CrewKit
import SwiftUI

struct PlanView: View {
    @Bindable var model: PlanViewModel
    var location: HeadingProvider?
    var onHelp: () -> Void = {}
    @State private var editing = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                header
                if let error = model.error {
                    Text(error).font(Theme.Font.caption).foregroundStyle(Theme.color(.unhealthy))
                }
                if let response = model.response, let digest = model.digest {
                    PlanContent(response: response, digest: digest)
                    Button {
                        if let url = model.briefingURL { openURL(url) }
                    } label: {
                        Text("Print the briefing sheet").primaryButton()
                    }
                    .padding(.top, Theme.Space.xs)
                    notes(response)
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, Theme.Space.xxl)
                }
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.bottom, Theme.Space.xxl)
        }
        .background(Theme.ground)
        .refreshable { await model.load(force: true) }
        .sheet(isPresented: $editing) { PlanSettings(model: model, location: location) }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button { editing = true } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Space.s) {
                        Text(placeTitle).font(Theme.Font.title).foregroundStyle(Theme.ink)
                        Image(systemName: "chevron.down").font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    Text(subtitle).font(Theme.Font.subtitle).foregroundStyle(Theme.inkSecondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Change place, day or shift"))
            Spacer()
            if let level = model.response?.plan.confidence?.level { ConfidenceChip(level: level) }
            Button(action: onHelp) {
                Image(systemName: "questionmark").font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background(Theme.card, in: .circle)
            }
            .accessibilityLabel(Text("How Crew Air works"))
        }
        .padding(.top, Theme.Space.l)
        .padding(.horizontal, Theme.Space.s)
        .padding(.bottom, Theme.Space.xs)
    }

    private var placeTitle: String { model.displayName }

    private var subtitle: String {
        let day = model.response.map { Clock.weekday($0.date) } ?? model.day.title
        return "\(day) · \(Clock.hour(model.shift.start)) – \(Clock.hour(model.shift.end))"
    }

    private func notes(_ response: CrewResponse) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            ForEach(response.plan.confidence?.notes ?? [], id: \.self) { note in
                Text(note)
            }
            if let bms = response.plan.bms { Text(bms.reason) }
        }
        .font(Theme.Font.caption)
        .foregroundStyle(Theme.inkSecondary)
        .padding(.horizontal, Theme.Space.s)
        .padding(.top, Theme.Space.s)
    }
}

struct ConfidenceChip: View {
    let level: Confidence.Level

    var body: some View {
        switch level {
        case .sensorConfirmed:
            Text("Checked").font(Theme.Font.chip).pill(fill: Theme.ok, ink: Theme.okInk)
        case .modelAdjusted:
            Text("Adjusted").font(Theme.Font.chip).pill(fill: Theme.ok, ink: Theme.okInk)
        case .modelOnly:
            Text("Model only").font(Theme.Font.chip).pill(fill: Theme.neutralPill, ink: Theme.inkSecondary)
        }
    }
}

/// Hero, fire warning, the two tiles, the chart.
struct PlanContent: View {
    let response: CrewResponse
    let digest: PlanDigest

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            HeroCard(digest: digest)
            if let alert = response.alerts?.first { AlertNote(alert: alert) }
            if let fire = response.plan.confidence?.fire, fire.isClose { FireCard(fire: fire) }
            HStack(spacing: Theme.Space.m) {
                HeatTile(digest: digest)
                WorkTile(window: digest.cleanestWindow)
            }
            AirChart(hours: response.plan.hours)
            RecordLine(response: response)
        }
    }
}

/// An active NWS alert: one red line with the event name.
struct AlertNote: View {
    let alert: WeatherAlert

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 14, weight: .bold))
            Text("NWS: \(alert.event)").font(Theme.Font.row).lineLimit(2)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.sickInk)
        .padding(.horizontal, Theme.Space.l)
        .padding(.vertical, Theme.Space.m)
        .background(Theme.sick, in: .rect(cornerRadius: Theme.Radius.panel))
    }
}

/// The record a crew lead reads before going in: how the AQI was determined and the rule in force.
struct RecordLine: View {
    let response: CrewResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Record").font(Theme.Font.tileLabel).foregroundStyle(Theme.inkSecondary)
            Text("AQI determined: \(source)").font(Theme.Font.row).foregroundStyle(Theme.ink)
            Text(rule).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.l + 2)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.tile))
        .accessibilityElement(children: .combine)
    }

    private var source: String {
        if let fallback = response.fallback, let monitor = fallback.monitor {
            return String(localized: "forecast held at monitor \(monitor)")
        }
        if let ground = response.plan.confidence?.ground {
            return String(localized: "AirNow \(ground.nearest), \(String(format: "%.0f", ground.nearestKm)) km")
        }
        return String(localized: "forecast model only")
    }

    private var rule: String {
        if let action = response.plan.actions.first(where: { $0.citation != nil }), let cite = action.citation {
            return String(localized: "Rule in force: \(cite)")
        }
        return String(localized: "Rule in force: Cal/OSHA T8 §5141.1 (below the AQI 151 trigger)")
    }
}

struct HeroCard: View {
    let digest: PlanDigest

    var body: some View {
        let band = digest.peakBand ?? .good
        let ink = Theme.onColor(band)
        VStack(alignment: .leading, spacing: 6) {
            Text(lead(band)).font(Theme.Font.heroLead)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(digest.peakAqi.map { "\($0)" } ?? "–")
                    .font(Theme.Font.hero).kerning(-3).monospacedDigit()
                Text("AQI").font(Theme.Font.heroUnit)
            }
            Text(sentence).font(Theme.Font.heroSentence).padding(.top, 6)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.xl)
        .background(Theme.color(band), in: .rect(cornerRadius: Theme.Radius.hero))
        .accessibilityElement(children: .combine)
    }

    private func lead(_ band: AQIBand) -> String {
        band >= .sensitive
            ? String(localized: "Smoke · \(band.title)")
            : String(localized: "Air · \(band.title) all shift")
    }

    private var sentence: String {
        guard let action = digest.smokeAction else { return String(localized: "No N95 rule yet: it starts at AQI 151") }
        return String(localized: "\(action.sentence) from \(Clock.short(action.clock))")
    }
}

struct FireCard: View {
    let fire: Fire

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: "flame.fill").font(.system(size: 26, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Fire \(Int(fire.nearestKm)) km \(fire.direction)").font(Theme.Font.cardTitle)
                Text("Smoke can shift fast. Check the sky.").font(Theme.Font.tileNote)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.sickInk)
        .padding(Theme.Space.l + 2)
        .background(Theme.sick, in: .rect(cornerRadius: Theme.Radius.tile))
    }
}

struct HeatTile: View {
    let digest: PlanDigest

    var body: some View {
        Tile(
            label: String(localized: "Heat"),
            value: digest.peakTempF.map { "\($0)°" } ?? "–",
            note: digest.shadeFrom.map { String(localized: "Shade from \(Clock.short($0))") }
                ?? String(localized: "Shade at \(PlanDigest.shadeTriggerF)°"),
            fill: Theme.heat, ink: Theme.heatInk
        )
    }
}

struct WorkTile: View {
    let window: ClosedRange<Int>?

    var body: some View {
        Tile(
            label: String(localized: "Heavy work"),
            value: window.map { "\(Clock.dial($0.lowerBound))–\(Clock.dial($0.upperBound))" } ?? "–",
            note: [window.map { Clock.meridiem($0.upperBound) } ?? "", String(localized: "cleanest air")]
                .filter { !$0.isEmpty }.joined(separator: ", "),
            fill: Theme.calm, ink: Theme.calmInk
        )
    }
}

struct Tile: View {
    let label: String
    let value: String
    let note: String
    let fill: Color
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(label).font(Theme.Font.tileLabel).foregroundStyle(ink)
            Text(value).font(Theme.Font.tileValue).kerning(-1).foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(note).font(Theme.Font.tileNote).foregroundStyle(ink).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.l + 2)
        .background(fill, in: .rect(cornerRadius: Theme.Radius.tile))
        .accessibilityElement(children: .combine)
    }
}

/// Bars ∝ AQI, coloured by band. Scaled to the shift's own peak so a clean day still shows shape.
struct AirChart: View {
    let hours: [Hour]

    var body: some View {
        let peak = max(50, hours.compactMap(\.metrics.usAqiPm25).max() ?? 50)
        VStack(alignment: .leading, spacing: 10) {
            Text("Air by the hour").font(Theme.Font.tileLabel).foregroundStyle(Theme.inkSecondary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(hours) { hour in
                    let aqi = hour.metrics.usAqiPm25 ?? 0
                    RoundedRectangle(cornerRadius: Theme.Radius.chart)
                        .fill(Theme.color(AQIBand(aqi: aqi)))
                        .frame(height: max(6, Theme.Size.chart * CGFloat(aqi) / CGFloat(peak)))
                        .accessibilityLabel(Text("\(Clock.hour(hour.hourOfDay ?? 0)): AQI \(aqi)"))
                }
            }
            .frame(height: Theme.Size.chart, alignment: .bottom)
            HStack {
                ForEach(axis, id: \.self) { label in
                    Text(label)
                    if label != axis.last { Spacer() }
                }
            }
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, Theme.Space.l + 2)
        .padding(.top, Theme.Space.l + 2)
        .padding(.bottom, Theme.Space.m + 2)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.tile))
    }

    private var axis: [String] {
        let marks = hours.compactMap(\.hourOfDay)
        guard let first = marks.first, let last = marks.last else { return [] }
        let middle = marks[marks.count / 2]
        return [first, middle, last].map(Clock.hour)
    }
}

/// Place, day and shift: out of the way until needed.
struct PlanSettings: View {
    @Bindable var model: PlanViewModel
    var location: HeadingProvider?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var suggestions: [PlaceSuggestion] = []
    @State private var searching = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { useLocation() } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use my location").foregroundStyle(Theme.ink)
                                if model.followsLocation {
                                    Text("On: the plan follows where you are")
                                        .font(Theme.Font.caption).foregroundStyle(Theme.okInk)
                                }
                            }
                        } icon: {
                            Image(systemName: model.followsLocation ? "location.fill" : "location")
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    TextField("Search a town or city", text: $query)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { pickFirstOrName() }
                    results
                } header: {
                    Text("Place")
                }
                Section {
                    Picker("Day", selection: $model.day) {
                        ForEach(PlanViewModel.Day.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Stepper("Start \(Clock.hour(model.shift.start))", value: start, in: 0 ... 22)
                    Stepper("End \(Clock.hour(model.shift.end))", value: end, in: 1 ... 23)
                } header: {
                    Text("Shift")
                }
                Section {
                    if let url = PrivacyLink.url { Link("Privacy", destination: url) }
                    Text("A planning aid, not legal advice.").foregroundStyle(Theme.inkSecondary)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle(model.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { close() }
                }
            }
            .task(id: query) { await search() }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var results: some View {
        if searching {
            HStack(spacing: Theme.Space.s) {
                ProgressView()
                Text("Searching…").foregroundStyle(Theme.inkSecondary)
            }
        } else if query.trimmingCharacters(in: .whitespaces).count >= 2, suggestions.isEmpty {
            Text("No places found").foregroundStyle(Theme.inkSecondary)
        }
        ForEach(suggestions) { place in
            Button {
                model.choose(place)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.ink)
                    if let detail = place.detail {
                        Text(detail).font(Theme.Font.caption).foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
        }
    }

    /// Live suggestions, a quarter second after the last keystroke.
    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else {
            suggestions = []
            searching = false
            return
        }
        searching = true
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        let found = (try? await model.placeService.places(matching: text)) ?? []
        guard !Task.isCancelled else { return }
        suggestions = found
        searching = false
    }

    private func pickFirstOrName() {
        if let first = suggestions.first { model.choose(first) } else { model.choose(name: query) }
        dismiss()
    }

    private func useLocation() {
        location?.startLocation()
        let fix = location?.location?.coordinate
        model.useLocation(lat: fix?.latitude, lon: fix?.longitude)
        dismiss()
    }

    private func close() {
        dismiss()
        Task { await model.load() }
    }

    private var start: Binding<Int> {
        Binding { model.shift.start } set: { model.shift = Shift(start: $0, end: max($0 + 1, model.shift.end)) }
    }

    private var end: Binding<Int> {
        Binding { model.shift.end } set: { model.shift = Shift(start: min(model.shift.start, $0 - 1), end: $0) }
    }
}

#Preview {
    PlanView(model: PlanViewModel(service: PreviewCrewService(), response: .preview))
}
