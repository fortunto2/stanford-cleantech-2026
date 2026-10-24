import Foundation

/// Where a compass bearing on the horizon (elevation ≈ 0) lands in a camera preview.
///
/// Pinhole model: the focal length in points comes from the horizontal field of view, and a
/// bearing `Δ` degrees right of the heading lands at `centre + f·tan Δ`. Heading + hfov/2 is
/// exactly the right edge. Anything 90° or more away is behind the lens and has no position.
public struct HorizonProjection: Sendable, Equatable {
    /// Where the camera looks, degrees from north.
    public let heading: Double
    /// Camera pitch above the horizon, degrees; moves the horizon line down when positive.
    public let pitch: Double
    /// Horizontal field of view across the preview's width, degrees.
    public let horizontalFOV: Double
    public let width: Double
    public let height: Double

    public init(heading: Double, pitch: Double = 0, horizontalFOV: Double, width: Double, height: Double) {
        self.heading = heading
        self.pitch = pitch
        self.horizontalFOV = horizontalFOV
        self.width = width
        self.height = height
    }

    var focal: Double { width / 2 / tan(horizontalFOV / 2 * .pi / 180) }

    /// x in points for `bearing`, or nil when it is behind the camera. May fall outside
    /// 0...width for bearings in front but beyond the frame; callers clip.
    public func x(for bearing: Double) -> Double? {
        let d = Compass.delta(from: heading, to: bearing)
        guard abs(d) < 90 else { return nil }
        return width / 2 + focal * tan(d * .pi / 180)
    }

    /// y in points of the horizon line.
    public var horizonY: Double {
        let p = max(-89, min(89, pitch))
        return height / 2 + focal * tan(p * .pi / 180)
    }

    /// Degrees across a view's width when a camera buffer is drawn aspect-fill into it.
    ///
    /// `lensFOV` is AVFoundation's `videoFieldOfView`, measured across the sensor's long side.
    /// A portrait phone shows the short side, and aspect-fill crops the width further on a
    /// tall screen, so the lens figure is far wider than what the user actually sees.
    public static func fieldAcrossView(
        lensFOV: Double, bufferWidth: Double, bufferHeight: Double, viewWidth: Double, viewHeight: Double
    ) -> Double {
        let longSide = max(bufferWidth, bufferHeight)
        let focalPixels = longSide / 2 / tan(lensFOV / 2 * .pi / 180)
        let scale = max(viewWidth / bufferWidth, viewHeight / bufferHeight)
        return 2 * atan(viewWidth / 2 / (focalPixels * scale)) * 180 / .pi
    }

    /// Whether a projected x is on screen.
    public func isVisible(_ x: Double) -> Bool { x >= 0 && x <= width }
}
