import CrewKit
import UIKit
import Vision

/// What leaves the phone: the sky, not the people under it.
///
/// Every face Vision finds is painted over before the photo is encoded, the frame is cut just
/// below the horizon when the camera knows where that is, and the long side is capped at 768 px.
enum SkyImagePrep {
    /// - Parameter horizon: the horizon's height as a fraction from the top, for a live frame.
    nonisolated static func jpeg(from image: UIImage, horizon: Double?) throws -> Data {
        let upright = redraw(image, keepTop: horizon.flatMap { SkyCrop.keepFraction(horizon: $0) } ?? 1)
        guard let cgImage = upright.cgImage else { throw SkyCheckError.noImage }
        let faces = (try? faceBoxes(in: cgImage)) ?? []
        let masked = faces.isEmpty ? upright : paint(faces, over: upright)
        guard let data = masked.jpegData(compressionQuality: 0.8) else { throw SkyCheckError.noImage }
        return data
    }

    /// Applies the EXIF orientation, crops to the top `keepTop` of the frame, and downsizes.
    private nonisolated static func redraw(_ image: UIImage, keepTop: Double) -> UIImage {
        let source = image.size
        let kept = CGSize(width: source.width, height: source.height * keepTop)
        let (w, h) = SkyCrop.fitted(width: kept.width, height: kept.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let scale = w / kept.width
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: source.width * scale, height: source.height * scale))
        }
    }

    /// Face boxes in image coordinates (origin top-left), grown by a fifth to cover hair and chin.
    private nonisolated static func faceBoxes(in image: CGImage) throws -> [CGRect] {
        let request = VNDetectFaceRectanglesRequest()
        try VNImageRequestHandler(cgImage: image).perform([request])
        let size = CGSize(width: image.width, height: image.height)
        return (request.results ?? []).map { face in
            let box = face.boundingBox
            let rect = CGRect(
                x: box.minX * size.width, y: (1 - box.maxY) * size.height,
                width: box.width * size.width, height: box.height * size.height
            )
            return rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
        }
    }

    private nonisolated static func paint(_ boxes: [CGRect], over image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            image.draw(at: .zero)
            UIColor.black.setFill()
            boxes.forEach { context.cgContext.fillEllipse(in: $0) }
        }
    }
}
