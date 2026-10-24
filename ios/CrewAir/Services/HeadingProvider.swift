import CoreLocation
import CoreMotion
import Foundation

/// Which way the rear camera points, from device motion: no ARKit, no camera frames needed.
///
/// Adapted from Starlapse's `AttitudeProvider`. True north needs a position (declination),
/// so it asks for location when-in-use and falls back to magnetic north without it. With no
/// motion hardware (the Simulator) it reports `isSimulated` and the view drives `heading`
/// from a drag instead.
@MainActor
@Observable
final class HeadingProvider: NSObject {
    /// Degrees from north the camera looks along.
    var heading: Double = 315
    /// Degrees above the horizon.
    private(set) var pitch: Double = 0
    private(set) var isTrueNorth = false
    private(set) var isSimulated = false

    private let motion = CMMotionManager()
    private let location = CLLocationManager()

    override init() {
        super.init()
        location.delegate = self
    }

    func start() {
        guard motion.isDeviceMotionAvailable else {
            isSimulated = true
            return
        }
        if location.authorizationStatus == .notDetermined { location.requestWhenInUseAuthorization() }
        startMotion()
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }

    private func startMotion() {
        let frames = CMMotionManager.availableAttitudeReferenceFrames()
        let authorized = location.authorizationStatus == .authorizedWhenInUse
            || location.authorizationStatus == .authorizedAlways
        let frame: CMAttitudeReferenceFrame = authorized && frames.contains(.xTrueNorthZVertical)
            ? .xTrueNorthZVertical : .xMagneticNorthZVertical
        isTrueNorth = frame == .xTrueNorthZVertical
        motion.stopDeviceMotionUpdates()
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] sample, _ in
            guard let self, let sample else { return }
            MainActor.assumeIsolated { self.update(from: sample.attitude.rotationMatrix) }
        }
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
            guard status == .authorizedWhenInUse || status == .authorizedAlways,
                  self.motion.isDeviceMotionActive, !self.isTrueNorth else { return }
            self.startMotion()
        }
    }
}
