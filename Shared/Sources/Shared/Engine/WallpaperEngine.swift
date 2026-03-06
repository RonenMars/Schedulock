import UIKit
import CoreGraphics

/// The central orchestrator for wallpaper generation.
/// Manages template renderers and generates wallpapers at device-specific resolutions.
public final class WallpaperEngine: Sendable {
    private let renderers: [TemplateType: WallpaperRenderer]

    /// Initialize with a dictionary of renderers.
    /// - Parameter renderers: Dictionary mapping template types to their renderers
    public init(renderers: [TemplateType: WallpaperRenderer] = [:]) {
        self.renderers = renderers
    }

    /// Register all built-in renderers.
    /// This method should be called during app initialization.
    /// Template builders will call this to register their renderers.
    public static func withAllRenderers(_ renderers: [WallpaperRenderer]) -> WallpaperEngine {
        var rendererMap: [TemplateType: WallpaperRenderer] = [:]
        for renderer in renderers {
            rendererMap[renderer.templateType] = renderer
        }
        return WallpaperEngine(renderers: rendererMap)
    }

    /// Generate a wallpaper image for the given template and events.
    ///
    /// - Parameters:
    ///   - template: The wallpaper template to render
    ///   - image: Optional background image (will be resized to fit resolution)
    ///   - events: Array of calendar events to render
    ///   - resolution: Target device resolution
    ///   - date: The date being rendered (defaults to current date)
    /// - Returns: Generated wallpaper image, or nil if rendering fails
    public func generateWallpaper(
        template: WallpaperTemplate,
        image: UIImage?,
        events: [CalendarEvent],
        resolution: DeviceResolution,
        date: Date = Date()
    ) -> UIImage? {
        // 1. Get the appropriate renderer for this template type
        guard let renderer = renderers[template.templateType] else {
            print("⚠️ No renderer found for template type: \(template.templateType)")
            return nil
        }

        let size = resolution.size

        // 2. Create a bitmap context at the target resolution
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            print("⚠️ Failed to create CGContext")
            return nil
        }

        // 3. Configure context for high-quality rendering
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        // 4. Process background image if provided (resize to fit resolution)
        let processedImage = image.map { resizeImage($0, toFit: size) }

        // 5. Flip to UIKit coordinate system (Y-down, origin top-left)
        //    Raw CGContext has Y-up (origin bottom-left); all renderers use UIKit conventions.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // 6. Call the renderer to draw into the context
        renderer.render(
            context: context,
            size: size,
            backgroundImage: processedImage,
            events: events,
            settings: template.settings,
            date: date
        )

        // 6. Extract the rendered image from the context
        guard let cgImage = context.makeImage() else {
            print("⚠️ Failed to create CGImage from context")
            return nil
        }

        return UIImage(cgImage: cgImage, scale: CGFloat(resolution.scale), orientation: .up)
    }

    // MARK: - Private Helpers

    /// Resize an image to fit the target size while maintaining aspect ratio.
    /// The image will be scaled to fill the target size, then cropped to fit.
    private func resizeImage(_ image: UIImage, toFit size: CGSize) -> UIImage {
        let imageSize = image.size
        let widthRatio = size.width / imageSize.width
        let heightRatio = size.height / imageSize.height

        // Use the larger ratio to ensure the image fills the entire target size
        let scale = max(widthRatio, heightRatio)
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        // Calculate the rect to draw the image centered
        let drawRect = CGRect(
            x: (size.width - scaledSize.width) / 2,
            y: (size.height - scaledSize.height) / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )

        // Create a new context and draw the resized image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return image
        }

        context.interpolationQuality = .high

        // Flip to UIKit coordinate space so the image draws right-side up and
        // UIImage.draw(in:) correctly applies the photo's orientation metadata.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsPushContext(context)
        image.draw(in: drawRect)
        UIGraphicsPopContext()

        guard let resizedCGImage = context.makeImage() else {
            return image
        }

        return UIImage(cgImage: resizedCGImage)
    }
}
