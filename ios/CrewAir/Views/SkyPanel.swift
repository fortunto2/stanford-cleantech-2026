import CrewKit
import PhotosUI
import SwiftUI

/// The dark card at the bottom: what to do, or what the model saw.
struct SkyPanel: View {
    let response: CrewResponse?
    let sky: SkyCheckModel
    let reports: ReportViewModel
    let heading: HeadingProvider
    let cameraRunning: Bool
    @Binding var pickerItem: PhotosPickerItem?
    let onCamera: () -> Void
    @State private var confirming = false
    @State private var complaintFor: Report?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if let result = sky.result {
                SkyVerdict(result: result, origin: sky.origin)
                if result.shouldReport { reportButton(result) }
                if let image = sky.shareImage {
                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(Text("Sky evidence"), image: Image(uiImage: image))
                    ) {
                        Label("Share the evidence card", systemImage: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.skyInk)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .glass(.rect(cornerRadius: 10), interactive: true)
                    }
                }
            } else {
                Text("YOUR SKY").font(Theme.Font.mono).kerning(0.7).foregroundStyle(Theme.skyAccent)
                Text(sky.error ?? intro).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.skyInk)
                if let line = forecastLine {
                    Text(line).font(.system(size: 13)).foregroundStyle(Theme.skyInkSecondary)
                }
            }
            actions.padding(.top, Theme.Space.xs)
            if sky.result == nil { SkyCheckDisclosure() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.l).padding(.vertical, 14)
        .background(Theme.skyPanel, in: .rect(cornerRadius: Theme.Radius.panel))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.panel).stroke(Theme.skyStroke))
        .task(id: sky.checkedAt) { renderShareCard() }
    }

    /// The forwardable card: the photo as sent, with the forecast and the satellites beside it.
    private func renderShareCard() {
        guard let result = sky.result, let photo = sky.sentImage else { return }
        let card = EvidenceCard(
            photo: photo, result: result, response: response,
            headingDeg: sky.origin?.headingDeg ?? heading.origin(cameraHeading: true).headingDeg,
            takenClock: sky.origin?.takenClock
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        sky.shareImage = renderer.uiImage
    }

    private var intro: String {
        cameraRunning
            ? String(localized: "Point the camera at the horizon")
            : String(localized: "No camera here: check a photo instead")
    }

    private var actions: some View {
        HStack(spacing: Theme.Space.s) {
            Button(action: onCamera) {
                Text(sky.isChecking ? "Checking…" : sky.result == nil ? "Check the sky" : "Check again")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.monitorInk)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.skyInk.opacity(cameraRunning ? 1 : 0.4), in: .rect(cornerRadius: 10))
            }
            .disabled(sky.isChecking || !cameraRunning)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                SkyIcon(name: "photo.on.rectangle")
            }
            .accessibilityLabel(Text("Use a photo"))
            .disabled(sky.isChecking)
            Menu {
                ForEach(SkyCheckModel.Sample.allCases) { sample in
                    Button(sample.title) {
                        Task { await sky.check(sample: sample, place: reports.place) }
                    }
                }
            } label: {
                SkyIcon(name: "sparkles.rectangle.stack")
            }
            .accessibilityLabel(Text("Try a sample"))
            .disabled(sky.isChecking)
        }
    }

    /// Report smoke, in two steps: first what will be sent and where, then Send.
    @ViewBuilder
    private func reportButton(_ result: SkyCheckResult) -> some View {
        if confirming && !sky.reported {
            SendDisclosure(placeName: reports.placeName, sendsLocation: sendsLocation, dark: true)
            HStack(spacing: Theme.Space.s) {
                Button { confirming = false } label: {
                    Text("Cancel").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.skyInk)
                        .frame(minWidth: 90, minHeight: 48)
                        .glass(.rect(cornerRadius: 12), interactive: true)
                }
                Button { Task { await send(result) } } label: {
                    Text(reports.isSending ? "Sending…" : "Send to the crew lead")
                        .font(.system(size: 16, weight: .heavy)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Theme.color(.unhealthy), in: .rect(cornerRadius: 12))
                }
                .disabled(reports.isSending)
            }
        } else if sky.reported, let sent = reports.lastSent, Int(sent.id) != nil {
            Button { complaintFor = sent } label: {
                (Text("Sent to the crew lead") + Text(" · ") + Text("Prepare a complaint").underline())
                    .font(.system(size: 15, weight: .heavy)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.okSolid, in: .rect(cornerRadius: 12))
            }
            .sheet(item: $complaintFor) { report in
                EscalateView(report: report) { try await reports.complaint(for: report) }
            }
        } else {
            Button { confirming = true } label: {
                Text(sky.reported ? "Sent to the crew lead" : "Report smoke")
                    .font(.system(size: 16, weight: .heavy)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.color(.unhealthy), in: .rect(cornerRadius: 12))
            }
            .disabled(sky.reported)
        }
    }

    private var sendsLocation: Bool {
        if let origin = sky.origin { return !origin.input.isEmpty }
        return reports.sendsLocation
    }

    private func send(_ result: SkyCheckResult) async {
        reports.isLead = false
        reports.selected = .smoke
        reports.note = result.verdict
        await reports.send(origin: sky.origin?.input, sky: SkySummary(result))
        sky.markReported()
        confirming = false
    }

    /// What the plan says for now, so what you see can be held against it.
    private var forecastLine: String? {
        guard let plan = response?.plan else { return nil }
        let hour = Clock.calendar.component(.hour, from: .now)
        let now = plan.hours.first { $0.hourOfDay == hour } ?? plan.hours.first
        guard let aqi = now?.metrics.usAqiPm25 else { return nil }
        return String(localized: "The model says AQI \(aqi) here. If it looks worse, tell the crew lead.")
    }
}

/// Jev's answer: the verdict, the smoke score, and the forecast it disagrees with.
struct SkyVerdict: View {
    let result: SkyCheckResult
    let origin: CheckOrigin?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("YOUR SKY · JUST NOW").font(Theme.Font.mono).kerning(0.7).foregroundStyle(Theme.skyAccent)
            Text(headline).font(.system(size: 20, weight: .heavy)).foregroundStyle(Theme.skyInk)
            if result.skyVisible { smokeBar }
            if result.looksWorseThanModel == true {
                Label("Looks worse than the forecast", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, Theme.Space.m).padding(.vertical, Theme.Space.s)
                    .background(Theme.heat, in: .rect(cornerRadius: 10))
            }
            if let detail { Text(detail).font(.system(size: 13)).foregroundStyle(Theme.skyInkSecondary) }
            if let taken = origin.flatMap(OriginText.taken) {
                Text(taken).font(Theme.Font.mono).foregroundStyle(Theme.skyInkSecondary)
            }
        }
    }

    private var headline: String {
        if !result.skyVisible { return String(localized: "No sky in this photo. Point higher.") }
        if result.smokeCall == .unsure { return String(localized: "Not sure, take another photo") }
        return result.verdict
    }

    private var smokeBar: some View {
        HStack(spacing: Theme.Space.s) {
            Text("Smoke").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.skyInkSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.skyStroke)
                    Capsule().fill(result.smokeCall == .yes ? Theme.color(.unhealthy) : Theme.color(.good))
                        .frame(width: geo.size.width * min(1, max(0.03, result.smoke)))
                }
            }
            .frame(height: 8)
            Text("\(Int((result.smoke * 100).rounded()))%").font(Theme.Font.mono).foregroundStyle(Theme.skyInk)
        }
        .accessibilityElement(children: .combine)
    }

    /// Forecast against the photo; visibility only when the model's estimate is trusted.
    private var detail: String? {
        var parts: [String] = []
        if let aqi = result.model?.aqi { parts.append(String(localized: "Forecast AQI \(aqi)")) }
        if let visibility = result.visibility, visibility.trusted {
            parts.append(String(localized: "you can see \(visibility.label)"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct SkyIcon: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.skyInk)
            .frame(width: 48, height: 44)
            .glass(.rect(cornerRadius: 10), interactive: true)
    }
}
