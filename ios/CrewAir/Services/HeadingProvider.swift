import CoreLocation
import CoreMotion
import CrewKit
import Foundation

/// Where the phone is and which way it points.
///
/// Two headings, for two uses. In Sky, device motion gives the direction the rear camera
/// looks along (adapted from Starlapse's `AttitudeProvider`), which works with the phone held
/// up. Elsewhere, `CLHeading` gives the compass as the phone is held, which is what a report
/// made from the Report tab should carry. True north needs a position (declination), so both
/// fall back to magnetic until location is allowed. With no motion hardware (the Simulator)
/// `isSimulated` is set and the Sky view drives `heading` from a drag.
@MainActor
@Observable
final class HeadingProvider: NSObject {
    /// Degrees from north the camera looks along (Sky).
    var heading: Double = 315
    /// Degrees above the horizon.
    private(set) var pitch: Double = 0
    private(set) var isTrueNorth = false
    private(set) var isSimulated = false
    private(set) var isMotionRunning = false
    /// The latest fix, once location is allowed.
    private(set) var location: CLLocation?
    /// The compass as held, degrees from north, true when available.
    private(set) var compass: Double?

    private let motion = CMMotionManager()
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    private var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    /// Asks once; tracks if allowed. Denied is fine: reports go without a position.
    func startLocation() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: track()
        default: break
        }
    }

    private func track() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    /// What a report carries. From Sky, the camera's heading; elsewhere, the compass.
    func origin(cameraHeading: Bool) -> ReportOrigin.Input {
        let facing: Double? = cameraHeading && isMotionRunning && !isSimulated ? heading : compass
        return ReportOrigin.Input(
            lat: location?.coordinate.latitude, lon: location?.coordinate.longitude,
            accuracyM: location.map(\.horizontalAccuracy), headingDeg: facing.map { ($0 * 10).rounded() / 10 }
        )
    }

    func startMotion() {
        startLocation()
        guard motion.isDeviceMotionAvailable else {
            isSimulated = true
            return
        }
        let frames = CMMotionManager.availableAttitudeReferenceFrames()
        let frame: CMAttitudeReferenceFrame = isAuthorized && frames.contains(.xTrueNorthZVertical)
            ? .xTrueNorthZVertical : .xMagneticNorthZVertical
        isTrueNorth = frame == .xTrueNorthZVertical
        motion.stopDeviceMotionUpdates()
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] sample, _ in
            guard let self, let sample else { return }
            MainActor.assumeIsolated { self.update(from: sample.attitude.rotationMatrix) }
        }
        isMotionRunning = true
    }

    func stopMotion() {
        motion.stopDeviceMotionUpdates()
        isMotionRunning = false
    }

    /// X is north, Z is up, so Y is west. The rear camera looks along the body's −Z axis;
    /// the transpose of the rotation matrix maps body → reference, so the aim is the negated
    /// third row.
    private func update(from r: CMRotationMatrix) {
        let north = -r.m31, west = -r.m32, up = -r.m33
        heading = (atan2(-west, north) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        pitch = asin(max(-1, min(1, up))) * 180 / .pi
    }
}

extension HeadingProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
            self.track()
            // Now true north can be served; move to it if motion started on magnetic.
            if self.isMotionRunning, !self.isTrueNorth { self.startMotion() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in self.location = latest }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in self.compass = value }
    }
}
