import CrewKit
import SwiftUI

/// Camera preview with fires and monitors pinned to their compass bearings on the horizon.
struct SkyView: View {
    let response: CrewResponse?
    let checker: SkyChecker
    @State private var heading = HeadingProvider()
    @State private var camera = CameraSession()
    @State private var cameraRunning = false
    @State private var verdict: String?
    @State private var checking = false
    @State private var dragStart: Double?

    /// Used until the camera reports its own: an iPhone wide lens in portrait, aspect-fill.
    private static let fallbackFOV = 45.0

    var body: some View {
        ZStack {
            if cameraRunning {
                CameraPreview(session: camera.session).ignoresSafeArea()
            } else {
                Theme.skyPlaceholder.ignoresSafeArea()
            }
            GeometryReader { geo in
                SkyOverlay(
                    projection: projection(in: geo.size),
                    markers: SkyMarker.markers(for: response)
                )
            }
            .ignoresSafeArea()
            .contentShape(.rect)
            .gesture(heading.isSimulated ? panGesture : nil)
            controls
        }
        .task {
            heading.start()
            if CameraSession.isAvailable { cameraRunning = await camera.start() }
        }
        .onDisappear {
            heading.stop()
            camera.stop()
        }
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

    /// Simulator only: drag sideways to turn.
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let start = dragStart ?? heading.heading
                dragStart = start
                heading.heading = Compass.normalized(start - value.translation.width / 8)
            }
            .onEnded { _ in dragStart = nil }
    }

    private var controls: some View {
        VStack {
            Text("\(Int(heading.heading))° \(headingSource)")
                .font(.caption.monospacedDigit())
                .padding(.horizontal, Theme.Space.s).padding(.vertical, Theme.Space.xs)
                .background(Theme.skyLabelBackground, in: .capsule)
                .foregroundStyle(.white)
            Spacer()
            if let verdict {
                Text(verdict).font(.footnote).foregroundStyle(.white)
                    .padding(Theme.Space.s)
                    .background(Theme.skyLabelBackground, in: .rect(cornerRadius: Theme.Radius.s))
            }
            Button(checking ? "Checking…" : "Check the sky") { Task { await check() } }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(checking)
        }
        .padding(Theme.Space.l)
    }

    private var headingSource: String {
        if heading.isSimulated { return "simulated, drag to turn" }
        return heading.isTrueNorth ? "true" : "magnetic"
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

struct SkyMarker: Identifiable, Equatable {
    enum Kind { case fire, monitor }
    let id: String
    let kind: Kind
    let label: String
    /// nil when the direction is unknown: drawn as a chip, not pinned.
    let bearing: Double?

    static func markers(for response: CrewResponse?) -> [SkyMarker] {
        guard let response, let confidence = response.plan.confidence else { return [] }
        var out: [SkyMarker] = []
        if let fire = confidence.fire {
            out.append(SkyMarker(
                id: "fire", kind: .fire, label: "Fire \(Int(fire.nearestKm)) km", bearing: fire.bearing
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
                label: "\(ground.nearest) \(Int(ground.nearestKm)) km", bearing: bearing
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
            Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: projection.width, y: y))
            }
            .stroke(Theme.skyHorizon, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            ForEach(markers) { marker in
                if let x = marker.bearing.flatMap(projection.x(for:)), projection.isVisible(x) {
                    pin(marker).position(x: x, y: y - 28)
                }
            }
            unpinned.padding(.top, 120).padding(.leading, Theme.Space.l)
        }
    }

    /// Markers with no bearing, and pinned ones currently off screen, with an arrow.
    private var unpinned: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            ForEach(markers) { marker in
                if let hint = offscreenHint(marker) {
                    Text(hint).font(.caption2).foregroundStyle(.white)
                        .padding(.horizontal, Theme.Space.s).padding(.vertical, Theme.Space.xs)
                        .background(Theme.skyLabelBackground, in: .capsule)
                }
            }
        }
    }

    private func offscreenHint(_ marker: SkyMarker) -> String? {
        guard let bearing = marker.bearing else { return "\(marker.label), direction unknown" }
        if let x = projection.x(for: bearing), projection.isVisible(x) { return nil }
        let turn = Compass.delta(from: projection.heading, to: bearing)
        return "\(turn < 0 ? "←" : "→") \(marker.label), turn \(Int(abs(turn)))°"
    }

    private func pin(_ marker: SkyMarker) -> some View {
        let color = marker.kind == .fire ? Theme.fire : Theme.monitor
        return VStack(spacing: 2) {
            Label(marker.label, systemImage: marker.kind == .fire ? "flame.fill" : "sensor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Space.s).padding(.vertical, Theme.Space.xs)
                .background(color.opacity(0.85), in: .capsule)
            Rectangle().fill(color).frame(width: 2, height: 16)
        }
        .fixedSize()
    }
}

#Preview {
    SkyView(response: .preview, checker: StubSkyChecker())
}
