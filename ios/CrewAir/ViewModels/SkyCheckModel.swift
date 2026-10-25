import CrewKit
import ImageIO
import SuperDuperAnalytics
import UIKit

/// One sky check at a time: a camera frame, a library photo or a bundled sample, prepared on
/// the phone and sent to Jev.
@Observable
@MainActor
final class SkyCheckModel {
    enum Sample: String, CaseIterable, Identifiable {
        case smoke = "sample-smoke"
        case clear = "sample-clear"
        var id: String { rawValue }
        var title: String {
            switch self {
            case .smoke: String(localized: "Smoky city (sample)")
            case .clear: String(localized: "Clear mountains (sample)")
            }
        }
    }

    private(set) var result: SkyCheckResult?
    private(set) var isChecking = false
    private(set) var error: String?
    /// The photo checked, when it is not the live camera: shown instead of the preview.
    private(set) var photo: UIImage?
    private(set) var checkedAt: Date?
    private(set) var reported = false
    /// Where and which way the checked photo was taken: live for the camera, EXIF for a
    /// library photo, nothing for a sample.
    private(set) var origin: CheckOrigin?
    /// The photo as it was sent (faces painted over), for the shareable card.
    private(set) var sentImage: UIImage?
    /// The evidence card, rendered once per check.
    var shareImage: UIImage?

    private let checker: SkyChecker

    init(checker: SkyChecker) {
        self.checker = checker
    }

    func check(
        _ image: UIImage, horizon: Double?, place: String, showPhoto: Bool, origin: CheckOrigin? = nil
    ) async {
        isChecking = true
        error = nil
        reported = false
        shareImage = nil
        photo = showPhoto ? image : nil
        self.origin = origin
        defer { isChecking = false }
        do {
            let jpeg = try await Self.prepare(image, horizon: horizon)
            sentImage = UIImage(data: jpeg)
            result = try await checker.check(jpeg: jpeg, place: place)
            checkedAt = .now
            Analytics.track("sky_checked")
        } catch {
            result = nil
            self.error = error.localizedDescription
        }
    }

    func check(sample: Sample, place: String) async {
        guard let url = Bundle.main.url(forResource: sample.rawValue, withExtension: "jpg"),
              let image = UIImage(contentsOfFile: url.path) else { return }
        await check(image, horizon: nil, place: place, showPhoto: true)
    }

    func clear() {
        result = nil
        error = nil
        photo = nil
        origin = nil
        sentImage = nil
        shareImage = nil
        reported = false
    }

    func markReported() { reported = true }

    /// Vision and JPEG encoding off the main actor.
    @concurrent
    private nonisolated static func prepare(_ image: UIImage, horizon: Double?) async throws -> Data {
        try SkyImagePrep.jpeg(from: image, horizon: horizon)
    }
}

/// Where a checked photo came from.
struct CheckOrigin: Sendable, Equatable {
    let input: ReportOrigin.Input
    /// Local clock time the photo was taken, when the photo says ("10:05").
    let takenClock: String?
    let fromLibrary: Bool

    var headingDeg: Double? { input.headingDeg }
    var hasPosition: Bool { input.lat != nil && input.lon != nil }

    /// From a library photo's EXIF; nil when it carries none of it.
    static func exif(_ data: Data) -> CheckOrigin? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return nil }
        let photo = PhotoOrigin(
            gps: props[kCGImagePropertyGPSDictionary as String] as? [String: Any],
            exif: props[kCGImagePropertyExifDictionary as String] as? [String: Any]
        )
        guard !photo.isEmpty else { return nil }
        return CheckOrigin(
            input: ReportOrigin.Input(lat: photo.lat, lon: photo.lon, accuracyM: nil, headingDeg: photo.headingDeg),
            takenClock: photo.takenClock, fromLibrary: true
        )
    }
}
