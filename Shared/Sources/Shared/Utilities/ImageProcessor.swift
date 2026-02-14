import UIKit
import CoreImage

/// High-performance image processing pipeline for wallpaper backgrounds.
/// Uses Core Image for efficient GPU-accelerated transformations.
public struct ImageProcessor {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Image Processing Pipeline

    /// Crops image to aspect-fill the given size (9:19.5 ratio for wallpapers).
    /// The image is scaled to fill the entire target size, cropping excess content.
    public static func aspectFillCrop(image: UIImage, targetSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let targetAspect = targetSize.width / targetSize.height
        let imageAspect = imageSize.width / imageSize.height

        var cropRect: CGRect

        if imageAspect > targetAspect {
            // Image is wider - crop width
            let newWidth = imageSize.height * targetAspect
            let xOffset = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Image is taller - crop height
            let newHeight = imageSize.width / targetAspect
            let yOffset = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        }

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)

        // Scale to exact target size
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Applies Gaussian blur using Core Image.
    /// - Parameter radius: Blur radius in points (0 = no blur, 20+ = heavy blur)
    public static func applyBlur(to image: UIImage, radius: Double) -> UIImage? {
        guard radius > 0, let ciImage = CIImage(image: image) else { return image }

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = blurFilter.outputImage else { return image }

        // Clamp to original bounds to avoid edge artifacts
        let clampedImage = outputImage.clampedToExtent().cropped(to: ciImage.extent)

        guard let cgImage = ciContext.createCGImage(clampedImage, from: ciImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Adjusts brightness using CIColorControls.
    /// - Parameter amount: Brightness adjustment (-1.0 to 1.0, where 0 = no change)
    public static func adjustBrightness(of image: UIImage, amount: Double) -> UIImage? {
        guard amount != 0, let ciImage = CIImage(image: image) else { return image }

        guard let colorFilter = CIFilter(name: "CIColorControls") else { return image }
        colorFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorFilter.setValue(amount, forKey: kCIInputBrightnessKey)

        guard let outputImage = colorFilter.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: ciImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Full processing pipeline: crop → blur → brightness.
    /// This is the primary method for preparing wallpaper backgrounds.
    public static func processForWallpaper(
        image: UIImage,
        targetSize: CGSize,
        blurRadius: Double,
        brightnessAdjustment: Double
    ) -> UIImage? {
        var processed = image

        // Step 1: Crop to target aspect ratio
        if let cropped = aspectFillCrop(image: processed, targetSize: targetSize) {
            processed = cropped
        } else {
            return nil
        }

        // Step 2: Apply blur
        if blurRadius > 0, let blurred = applyBlur(to: processed, radius: blurRadius) {
            processed = blurred
        }

        // Step 3: Adjust brightness
        if brightnessAdjustment != 0,
           let brightened = adjustBrightness(of: processed, amount: brightnessAdjustment) {
            processed = brightened
        }

        return processed
    }

    // MARK: - Caching

    /// Saves processed image to App Group cache.
    /// Images are stored as PNG for lossless quality.
    /// - Returns: URL of cached file, or nil on failure
    public static func cacheProcessedImage(_ image: UIImage, filename: String) -> URL? {
        let cacheURL = AppGroupManager.imagesDirectory.appendingPathComponent(filename)

        guard let pngData = image.pngData() else { return nil }

        do {
            try pngData.write(to: cacheURL, options: .atomic)
            return cacheURL
        } catch {
            print("Failed to cache image '\(filename)': \(error)")
            return nil
        }
    }

    /// Loads cached image if available.
    /// Returns nil if the file doesn't exist or can't be decoded.
    public static func loadCachedImage(filename: String) -> UIImage? {
        let cacheURL = AppGroupManager.imagesDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        return UIImage(contentsOfFile: cacheURL.path)
    }
}
