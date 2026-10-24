import CrewKit
import SwiftUI

struct PlanView: View {
    @Bindable var model: PlanViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    inputs
                    if let error = model.error {
                        Text(error).font(.footnote).foregroundStyle(Theme.warning)
                    }
                    if let response = model.response {
                        PlanContent(response: response)
                    } else if model.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .padding(Theme.Space.l)
            }
            .refreshable { await model.load(force: true) }
            .navigationTitle(model.response?.place.name ?? "Crew Air")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var inputs: some View {
        VStack(spacing: Theme.Space.s) {
            TextField("Place", text: $model.place)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { Task { await model.load() } }
            Picker("Day", selection: $model.day) {
                ForEach(PlanViewModel.Day.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: model.day) { Task { await model.load() } }
            HStack {
                Stepper("Start \(String(format: "%02d", model.shift.start)):00", value: shiftStart, in: 0 ... 22)
                Stepper("End \(String(format: "%02d", model.shift.end)):00", value: shiftEnd, in: 1 ... 23)
            }
            .font(.subheadline)
        }
    }

    private var shiftStart: Binding<Int> {
        Binding { model.shift.start } set: { value in
            model.shift = Shift(start: value, end: max(value + 1, model.shift.end))
            Task { await model.load() }
        }
    }

    private var shiftEnd: Binding<Int> {
        Binding { model.shift.end } set: { value in
            model.shift = Shift(start: min(model.shift.start, value - 1), end: value)
            Task { await model.load() }
        }
    }
}

/// Everything below the inputs: confidence, actions, hours, building ventilation.
struct PlanContent: View {
    let response: CrewResponse

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            if let confidence = response.plan.confidence { ConfidenceSection(confidence: confidence) }
            ActionsSection(actions: response.plan.actions)
            HourStrip(hours: response.plan.hours)
            if let bms = response.plan.bms { BMSLine(bms: bms) }
        }
    }
}

struct ConfidenceSection: View {
    let confidence: Confidence

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if let fire = confidence.fire { FireBanner(fire: fire) }
            Text(confidence.level.rawValue.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            ForEach(confidence.notes, id: \.self) { note in
                Text(note).font(.footnote)
            }
        }
    }
}

struct FireBanner: View {
    let fire: Fire

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: "flame.fill").foregroundStyle(Theme.fire)
            Text(fire.isClose
                 ? "Active fire \(Int(fire.nearestKm)) km \(fire.direction): expect smoke to shift fast"
                 : "Nearest active fire \(Int(fire.nearestKm)) km \(fire.direction)")
                .font(fire.isClose ? .headline : .subheadline)
        }
        .padding(fire.isClose ? Theme.Space.m : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fire.isClose ? Theme.fire.opacity(0.15) : .clear, in: .rect(cornerRadius: Theme.Radius.m))
    }
}

struct ActionsSection: View {
    let actions: [Action]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Actions").font(.headline)
            if actions.isEmpty {
                Text("No rule is crossed in this shift.").font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
            ForEach(actions) { action in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.m) {
                    Text(action.clock).font(.subheadline.monospacedDigit().weight(.semibold))
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Text(action.text).font(.subheadline)
                        if let cite = action.citation {
                            Text(cite).font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

struct HourStrip: View {
    let hours: [Hour]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.xs) {
                ForEach(hours) { hour in cell(hour) }
            }
        }
    }

    private func cell(_ hour: Hour) -> some View {
        VStack(spacing: Theme.Space.xs) {
            Text(String(hour.clock.prefix(2))).font(.caption2).foregroundStyle(Theme.textSecondary)
            if let aqi = hour.metrics.usAqiPm25 {
                let band = AQIBand(aqi: aqi)
                Text("\(aqi)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.onColor(band))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.s)
                    .background(Theme.color(band), in: .rect(cornerRadius: Theme.Radius.s))
            } else {
                Text("–").frame(maxWidth: .infinity).padding(.vertical, Theme.Space.s)
            }
            Text(hour.metrics.tempFFloor.map { "\($0)°" } ?? "–").font(.caption.monospacedDigit())
        }
        .frame(width: Theme.Size.hourCellWidth)
    }
}

struct BMSLine: View {
    let bms: BMS

    var body: some View {
        Label {
            Text(bms.reason).font(.footnote)
        } icon: {
            Image(systemName: bms.recirculateAt == nil ? "wind" : "building.2")
        }
        .foregroundStyle(Theme.textSecondary)
    }
}

#Preview {
    ScrollView { PlanContent(response: .preview).padding() }
}
