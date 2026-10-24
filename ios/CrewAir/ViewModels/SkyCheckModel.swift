import CrewKit
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

    private let checker: SkyChecker

    init(checker: SkyChecker) {
        self.checker = checker
    }

    func check(_ image: UIImage, horizon: Double?, place: String, showPhoto: Bool) async {
        isChecking = true
        error = nil
        reported = false
        photo = showPhoto ? image : nil
        defer { isChecking = false }
        do {
            let jpeg = try await Self.prepare(image, horizon: horizon)
            result = try await checker.check(jpeg: jpeg, place: place)
            checkedAt = .now
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
        reported = false
    }

    func markReported() { reported = true }

    /// Vision and JPEG encoding off the main actor.
    @concurrent
    private nonisolated static func prepare(_ image: UIImage, horizon: Double?) async throws -> Data {
        try SkyImagePrep.jpeg(from: image, horizon: horizon)
    }
}
