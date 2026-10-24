import CrewKit
import SwiftUI

/// Camera preview with fires and monitors pinned to their compass bearings on the horizon.
///
/// Only the camera layer ignores the safe area. Everything that takes touches sits inside it,
/// so the tab bar is never covered, and the pins do not take touches at all.
struct SkyView: View {
    let response: CrewResponse?
    let checker: SkyChecker
    var onReportSmoke: () -> Void = {}
    @State private var heading = HeadingProvider()
    @State private var camera = CameraSession()
    @State private var cameraRunning = false
    @State private var verdict: String?
    @State private var checking = false
    @State private var dragStart: Double?

    /// Used until the camera reports its own: an iPhone wide lens in portrait, aspect-fill.
    private static let fallbackFOV = 45.0

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            CompassChip(heading: heading.heading, source: headingSource)
            dragArea
            panel
        }
        .padding(.horizontal, Theme.Space.l)
        .padding(.bottom, Theme.Space.m)
        .background {
            ZStack {
                if cameraRunning {
                    CameraPreview(session: camera.session)
                } else {
                    Theme.skyPlaceholder
                }
                GeometryReader { geo in
                    SkyOverlay(projection: projection(in: geo.size), markers: SkyMarker.markers(for: response))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task {
            heading.start()
            if CameraSession.isAvailable { cameraRunning = await camera.start() }
        }
        .onDisappear {
            heading.stop()
            camera.stop()
            cameraRunning = false
        }
    }

    /// The open middle of the screen. Takes a drag only in the Simulator, where it turns you.
    @ViewBuilder
    private var dragArea: some View {
        if heading.isSimulated {
            Color.clear.contentShape(.rect).gesture(panGesture)
        } else {
            Spacer()
        }
    }

    private var headingSource: String {
        if heading.isSimulated { return String(localized: "simulated, drag to turn") }
        return heading.isTrueNorth ? String(localized: "true north") : String(localized: "magnetic")
    }

    private func projection(in size: CGSize) -> HorizonProjection {
        var fov = Self.fallbackFOV
        if let lens = camera.lensFOV, let buffer = camera.bufferSize {
            fov = HorizonProjection.fieldAcrossView(
                lensFOV: lens, bufferWidth: buffer.width, bufferHeight: buffer.height,
                viewWidth: size.width, viewHeight: size.height
            )
        }
        return HorizonProjection(
            heading: heading.heading, pitch: heading.pitch, horizontalFOV: fov,
            width: size.width, height: size.height
        )
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let start = dragStart ?? heading.heading
                dragStart = start
                heading.heading = Compass.normalized(start - value.translation.width / 8)
            }
            .onEnded { _ in dragStart = nil }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("YOUR SKY").font(Theme.Font.mono).kerning(0.7).foregroundStyle(Theme.skyAccent)
            Text(verdict ?? String(localized: "Point the camera at the horizon"))
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.skyInk)
            if let line = forecastLine {
                Text(line).font(.system(size: 13)).foregroundStyle(Theme.skyInkSecondary)
            }
            HStack(spacing: Theme.Space.s) {
                Button(action: onReportSmoke) {
                    Text("Report smoke").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.monitorInk)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.skyInk, in: .rect(cornerRadius: 10))
                }
                Button { Task { await check() } } label: {
                    Text(checking ? "Checking…" : verdict == nil ? "Check the sky" : "Check again")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.skyInk)
                        .padding(.horizontal, 14).frame(minHeight: 44)
                        .glass(.rect(cornerRadius: 10), interactive: true)
                }
                .disabled(checking)
            }
            .padding(.top, Theme.Space.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.l).padding(.vertical, 14)
        .background(Theme.skyPanel, in: .rect(cornerRadius: Theme.Radius.panel))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.panel).stroke(Theme.skyStroke))
    }

    /// What the plan says for now, so what you see can be held against it.
    private var forecastLine: String? {
        guard let plan = response?.plan else { return nil }
        let hour = Clock.calendar.component(.hour, from: .now)
        let now = plan.hours.first { $0.hourOfDay == hour } ?? plan.hours.first
        guard let aqi = now?.metrics.usAqiPm25 else { return nil }
        return String(localized: "The model says AQI \(aqi) here. If it looks worse, tell the crew lead.")
    }

    private func check() async {
        checking = true
        defer { checking = false }
        let request = SkyCheckRequest(
            skyCropJPEG: nil, heading: heading.heading, place: response?.place.name ?? ""
        )
        do {
            verdict = try await checker.check(request).summary
        } catch {
            verdict = error.localizedDescription
        }
    }
}

/// "SW  S 182°  SE" across the top.
struct CompassChip: View {
    let heading: Double
    let source: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 22) {
                Text(Self.point(heading - 45)).opacity(0.6)
                Text("\(Self.point(heading)) \(Int(heading))°").fontWeight(.semibold)
                Text(Self.point(heading + 45)).opacity(0.6)
            }
            .font(Theme.Font.mono)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .glass(.capsule)
            Text(source).font(.system(size: 12))
                .padding(.horizontal, 10).padding(.vertical, Theme.Space.xs)
                .background(Theme.skyChip, in: .capsule)
        }
        .foregroundStyle(Theme.skyInk)
        .padding(.top, Theme.Space.s)
    }

    static func point(_ degrees: Double) -> String {
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return points[Int((Compass.normalized(degrees) + 22.5) / 45) % 8]
    }
}

struct SkyMarker: Identifiable, Equatable {
    enum Kind { case fire, monitor }
    let id: String
    let kind: Kind
    let title: String
    let detail: String
    /// nil when the direction is unknown: listed, not pinned.
    let bearing: Double?

    static func markers(for response: CrewResponse?) -> [SkyMarker] {
        guard let response, let confidence = response.plan.confidence else { return [] }
        var out: [SkyMarker] = []
        if let fire = confidence.fire {
            out.append(SkyMarker(
                id: "fire", kind: .fire, title: String(localized: "Fire \(Int(fire.nearestKm)) km"),
                detail: String(localized: "Satellite · \(fire.direction)"), bearing: fire.bearing
            ))
        }
        if let ground = confidence.ground {
            let bearing = ground.nearestLat.flatMap { lat in
                ground.nearestLon.map { lon in
                    Compass.bearing(fromLat: response.place.lat, lon: response.place.lon, toLat: lat, lon: lon)
                }
            }
            out.append(SkyMarker(
                id: "monitor", kind: .monitor,
                title: String(localized: "Monitor \(Int(ground.nearestKm.rounded())) km"),
                detail: String(format: "PM2.5 %.0f µg/m³", ground.pm25), bearing: bearing
            ))
        }
        return out
    }
}

struct SkyOverlay: View {
    let projection: HorizonProjection
    let markers: [SkyMarker]

    var body: some View {
        let y = projection.horizonY
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Theme.skyHorizon)
                .frame(width: projection.width, height: 1)
                .position(x: projection.width / 2, y: y)
            ForEach(markers) { marker in
                if let x = marker.bearing.flatMap(projection.x(for:)), projection.isVisible(x) {
                    let stem: CGFloat = marker.kind == .fire ? 96 : 46
                    SkyPin(marker: marker, stem: stem)
                        .position(x: x, y: y - stem / 2 - 24)
                }
            }
            offscreen.padding(.top, 150).padding(.leading, Theme.Space.l)
        }
    }

    /// Markers off screen get an arrow and how far to turn.
    private var offscreen: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            ForEach(markers) { marker in
                if let hint = hint(marker) {
                    Text(hint).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.skyInk)
                        .padding(.horizontal, 10).padding(.vertical, Theme.Space.xs)
                        .background(Theme.skyChip, in: .capsule)
                }
            }
        }
    }

    private func hint(_ marker: SkyMarker) -> String? {
        guard let bearing = marker.bearing else { return String(localized: "\(marker.title), direction unknown") }
        if let x = projection.x(for: bearing), projection.isVisible(x) { return nil }
        let turn = Compass.delta(from: projection.heading, to: bearing)
        return "\(turn < 0 ? "←" : "→") \(marker.title) · \(Int(abs(turn)))°"
    }
}

struct SkyPin: View {
    let marker: SkyMarker
    let stem: CGFloat

    var body: some View {
        let isFire = marker.kind == .fire
        let color = isFire ? Theme.fire : Color.white
        VStack(spacing: 6) {
            VStack(spacing: 2) {
                Text(marker.title).font(.system(size: isFire ? 14 : 13, weight: isFire ? .bold : .semibold))
                Text(marker.detail).font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isFire ? .white : Theme.monitorInk.opacity(0.8))
            }
            .foregroundStyle(isFire ? .white : Theme.monitorInk)
            .padding(.horizontal, isFire ? 12 : 10).padding(.vertical, isFire ? 8 : 7)
            .background(color, in: .rect(cornerRadius: 10))
            Rectangle().fill(color).frame(width: 2, height: stem)
            Circle().fill(color).frame(width: 10, height: 10)
                .overlay(Circle().stroke(.white, lineWidth: isFire ? 2 : 0))
        }
        .fixedSize()
    }
}

#Preview {
    SkyView(response: .preview, checker: StubSkyChecker())
}
