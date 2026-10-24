import CrewKit
import PhotosUI
import SwiftUI

/// Camera preview with fires and monitors pinned to their compass bearings on the horizon, and
/// a sky check: a frame, a library photo or a bundled sample, read by Jev.
///
/// Only the camera layer ignores the safe area. Everything that takes touches sits inside it,
/// so the tab bar is never covered, and the pins do not take touches at all.
struct SkyView: View {
    let response: CrewResponse?
    let sky: SkyCheckModel
    let reports: ReportViewModel
    let heading: HeadingProvider
    var onClose: () -> Void = {}
    @State private var camera = CameraSession()
    @State private var cameraRunning = false
    @State private var dragStart: Double?
    @State private var viewSize = CGSize.zero
    @State private var pickerItem: PhotosPickerItem?

    /// Used until the camera reports its own: an iPhone wide lens in portrait, aspect-fill.
    private static let fallbackFOV = 45.0

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            topBar
            dragArea
            SkyPanel(
                response: response, sky: sky, reports: reports, heading: heading, cameraRunning: cameraRunning,
                pickerItem: $pickerItem, onCamera: { Task { await checkCamera() } }
            )
        }
        .padding(.horizontal, Theme.Space.l)
        .padding(.bottom, Theme.Space.m)
        .background { backdrop }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task {
            heading.startMotion()
            if CameraSession.isAvailable { cameraRunning = await camera.start() }
        }
        .onDisappear {
            heading.stopMotion()
            camera.stop()
            cameraRunning = false
        }
        .onChange(of: pickerItem) { Task { await checkPicked() } }
    }

    private var backdrop: some View {
        ZStack {
            if let photo = sky.photo {
                Theme.skyPlaceholder
                Image(uiImage: photo).resizable().scaledToFill()
            } else if cameraRunning {
                CameraPreview(session: camera.session)
            } else {
                Theme.skyPlaceholder
            }
            GeometryReader { geo in
                if sky.photo == nil {
                    SkyOverlay(projection: projection(in: geo.size), markers: SkyMarker.markers(for: response))
                }
                Color.clear.onAppear { viewSize = geo.size }.onChange(of: geo.size) { viewSize = geo.size }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        ZStack(alignment: .topLeading) {
            if sky.photo == nil {
                CompassChip(heading: heading.heading, source: headingSource).frame(maxWidth: .infinity)
            }
            Button {
                if sky.photo != nil || sky.result != nil { sky.clear() } else { onClose() }
            } label: {
                Image(systemName: "xmark").font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.skyInk)
                    .frame(width: 44, height: 44)
                    .glass(.circle, interactive: true)
            }
            .accessibilityLabel(Text(sky.photo != nil || sky.result != nil ? "Back to the camera" : "Close"))
        }
    }

    /// The open middle of the screen. Takes a drag only in the Simulator, where it turns you.
    @ViewBuilder
    private var dragArea: some View {
        if heading.isSimulated && sky.photo == nil {
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

    /// The plan's own query, so the check is held against the same forecast.
    private var place: String { reports.place }

    /// The preview fills the screen's height, so the horizon's height on screen is its height
    /// in the portrait frame too.
    private func checkCamera() async {
        guard let data = await camera.capture(), let image = UIImage(data: data) else { return }
        let horizon = viewSize.height > 0 ? projection(in: viewSize).horizonY / viewSize.height : nil
        let origin = CheckOrigin(input: heading.origin(cameraHeading: true), takenClock: nil, fromLibrary: false)
        await sky.check(image, horizon: horizon, place: place, showPhoto: false, origin: origin)
    }

    private func checkPicked() async {
        guard let item = pickerItem else { return }
        pickerItem = nil
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let origin = CheckOrigin.exif(data)
        // Checked against the forecast where the photo was taken, when it says.
        var photoPlace: String?
        if let lat = origin?.input.lat, let lon = origin?.input.lon { photoPlace = PlaceQuery.coordinate(lat, lon) }
        await sky.check(image, horizon: nil, place: photoPlace ?? place, showPhoto: true, origin: origin)
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

    static func point(_ degrees: Double) -> String { Compass.point(for: degrees) }
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
    let plan = PlanViewModel(service: PreviewCrewService(), response: .preview)
    SkyView(
        response: .preview, sky: SkyCheckModel(checker: StubSkyChecker()),
        reports: ReportViewModel(service: PreviewCrewService(), plan: plan), heading: HeadingProvider()
    )
}
