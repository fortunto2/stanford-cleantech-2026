@preconcurrency import AVFoundation
import SwiftUI

/// The rear wide camera, preview only. Session calls run on one serial queue; the session is
/// `@unchecked Sendable` by that contract, as in Starlapse's capture engine.
final class CameraSession: @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "co.superduperai.crewair.camera")
    /// Lens field of view across the sensor's long side, and the buffer size; nil until configured.
    private(set) var lensFOV: Double?
    private(set) var bufferSize: CGSize?

    /// False where there is no camera (the Simulator) or access is denied.
    static var isAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    func start() async -> Bool {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return false }
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.configureAndRun())
            }
        }
    }

    func stop() {
        queue.async { self.session.stopRunning() }
    }

    private func configureAndRun() -> Bool {
        if session.inputs.isEmpty {
            guard let device = AVCaptureDevice.default(
                      .builtInWideAngleCamera, for: .video, position: .back
                  ),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return false }
            session.beginConfiguration()
            session.sessionPreset = .photo
            session.addInput(input)
            session.commitConfiguration()
            lensFOV = Double(device.activeFormat.videoFieldOfView)
            let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
            // Delivered landscape; the portrait preview shows it turned.
            bufferSize = CGSize(
                width: Double(min(dims.width, dims.height)), height: Double(max(dims.width, dims.height))
            )
        }
        session.startRunning()
        return session.isRunning
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        // The layer class above guarantees the type.
        // swiftlint:disable:next force_cast
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
