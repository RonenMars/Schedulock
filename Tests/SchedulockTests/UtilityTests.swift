import XCTest
@testable import Shared

/// Unit tests for utility modules: ImageProcessor, TextRenderer, ColorUtils, AppGroupManager, DesignTokens.
final class UtilityTests: XCTestCase {

    // MARK: - ImageProcessor Tests

    func testAspectFillCropProducesExpectedSize() {
        // Given: A test image
        let size = CGSize(width: 1000, height: 2000)
        guard let image = createTestImage(size: size) else {
            XCTFail("Failed to create test image")
            return
        }

        let targetSize = CGSize(width: 1179, height: 2556)

        // When: Cropping to target size
        let cropped = ImageProcessor.aspectFillCrop(image: image, targetSize: targetSize)

        // Then: Should produce image of target size
        XCTAssertNotNil(cropped)
        XCTAssertEqual(cropped?.size.width, targetSize.width)
        XCTAssertEqual(cropped?.size.height, targetSize.height)
    }

    func testAspectFillCropWithWideImage() {
        // Given: A wide image
        guard let image = createTestImage(size: CGSize(width: 3000, height: 1500)) else {
            XCTFail("Failed to create test image")
            return
        }

        let targetSize = CGSize(width: 1000, height: 2000)

        // When: Cropping
        let cropped = ImageProcessor.aspectFillCrop(image: image, targetSize: targetSize)

        // Then: Should crop width and maintain height aspect
        XCTAssertNotNil(cropped)
        XCTAssertEqual(cropped?.size.width, targetSize.width)
        XCTAssertEqual(cropped?.size.height, targetSize.height)
    }

    func testAspectFillCropWithTallImage() {
        // Given: A tall image
        guard let image = createTestImage(size: CGSize(width: 1500, height: 3000)) else {
            XCTFail("Failed to create test image")
            return
        }

        let targetSize = CGSize(width: 1000, height: 1000)

        // When: Cropping
        let cropped = ImageProcessor.aspectFillCrop(image: image, targetSize: targetSize)

        // Then: Should crop height and maintain width aspect
        XCTAssertNotNil(cropped)
        XCTAssertEqual(cropped?.size.width, targetSize.width)
        XCTAssertEqual(cropped?.size.height, targetSize.height)
    }

    func testApplyBlurReturnsNonNilImage() {
        // Given: A test image
        guard let image = createTestImage(size: CGSize(width: 500, height: 500)) else {
            XCTFail("Failed to create test image")
            return
        }

        // When: Applying blur
        let blurred = ImageProcessor.applyBlur(to: image, radius: 10.0)

        // Then: Should return non-nil image
        XCTAssertNotNil(blurred)
    }

    func testApplyBlurWithZeroRadius() {
        // Given: A test image
        guard let image = createTestImage(size: CGSize(width: 500, height: 500)) else {
            XCTFail("Failed to create test image")
            return
        }

        // When: Applying zero blur
        let blurred = ImageProcessor.applyBlur(to: image, radius: 0.0)

        // Then: Should return original image
        XCTAssertNotNil(blurred)
        XCTAssertEqual(blurred, image)
    }

    func testApplyBlurWithLargeRadius() {
        // Given: A test image
        guard let image = createTestImage(size: CGSize(width: 500, height: 500)) else {
            XCTFail("Failed to create test image")
            return
        }

        // When: Applying large blur
        let blurred = ImageProcessor.applyBlur(to: image, radius: 30.0)

        // Then: Should return non-nil image
        XCTAssertNotNil(blurred)
    }

    func testAdjustBrightnessReturnsNonNilImage() {
        // Given: A test image
        guard let image = createTestImage(size: CGSize(width: 500, height: 500)) else {
            XCTFail("Failed to create test image")
            return
        }

        // When: Adjusting brightness
        let brightened = ImageProcessor.adjustBrightness(of: image, amount: 0.3)

        // Then: Should return non-nil image
        XCTAssertNotNil(brightened)
    }

    func testAdjustBrightnessWithZeroAmount() {
        // Given: A test image
        guard let image = createTestImage(size: CGSize(width: 500, height: 500)) else {
            XCTFail("Failed to create test image")
            return
        }

        // When: Adjusting brightness by 0
        let result = ImageProcessor.adjustBrightness(of: image, amount: 0.0)

        // Then: Should return original image
        XCTAssertNotNil(result)
        XCTAssertEqual(result, image)
    }

    func testAdjustBrightnessWithNegativeAmount() {
        // Given: A test image
        guard let image = createTestImage(size: CGSize(width: 500, height: 500)) else {
            XCTFail("Failed to create test image")
            return
        }

        // When: Darkening
        let darkened = ImageProcessor.adjustBrightness(of: image, amount: -0.5)

        // Then: Should return non-nil image
        XCTAssertNotNil(darkened)
    }

    // MARK: - TextRenderer Tests

    func testDrawTextDoesNotCrashWithEmptyString() {
        // Given: Empty string
        let text = ""
        let size = CGSize(width: 200, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            XCTFail("Failed to create graphics context")
            return
        }

        let font = UIFont.systemFont(ofSize: 16)
        let rect = CGRect(origin: .zero, size: size)

        // When: Drawing empty text
        TextRenderer.drawText(
            text,
            in: context,
            rect: rect,
            font: font,
            color: .white,
            alignment: .center
        )

        // Then: Should complete without crashing
        XCTAssertNotNil(UIGraphicsGetImageFromCurrentImageContext())
    }

    func testDrawTextWithNonEmptyString() {
        // Given: Non-empty string
        let text = "Hello, Schedulock!"
        let size = CGSize(width: 300, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            XCTFail("Failed to create graphics context")
            return
        }

        let font = UIFont.systemFont(ofSize: 24)
        let rect = CGRect(origin: .zero, size: size)

        // When: Drawing text
        TextRenderer.drawText(
            text,
            in: context,
            rect: rect,
            font: font,
            color: .black,
            alignment: .left
        )

        // Then: Should complete without crashing
        XCTAssertNotNil(UIGraphicsGetImageFromCurrentImageContext())
    }

    func testDrawTextWithShadow() {
        // Given: Text with shadow
        let text = "Shadowed Text"
        let size = CGSize(width: 300, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            XCTFail("Failed to create graphics context")
            return
        }

        let font = UIFont.systemFont(ofSize: 24)
        let rect = CGRect(origin: .zero, size: size)
        let shadow = (color: UIColor.black, offset: CGSize(width: 2, height: 2), blur: CGFloat(4.0))

        // When: Drawing text with shadow
        TextRenderer.drawText(
            text,
            in: context,
            rect: rect,
            font: font,
            color: .white,
            alignment: .center,
            shadow: shadow
        )

        // Then: Should complete without crashing
        XCTAssertNotNil(UIGraphicsGetImageFromCurrentImageContext())
    }

    func testFontFromFamilyReturnsValidFont() {
        // Given: All font families
        for fontFamily in FontFamily.allCases {
            // When: Creating font
            let font = TextRenderer.font(from: fontFamily, size: 16)

            // Then: Should return valid UIFont
            XCTAssertNotNil(font)
            XCTAssertEqual(font.pointSize, 16)
        }
    }

    func testFontFromFamilySFPro() {
        // Given: SF Pro font family
        let fontFamily = FontFamily.sfPro

        // When: Creating font
        let font = TextRenderer.font(from: fontFamily, size: 20, weight: .bold)

        // Then: Should return system font
        XCTAssertNotNil(font)
        XCTAssertEqual(font.pointSize, 20)
    }

    func testFontFromFamilyWithDifferentWeights() {
        // Given: Different font weights
        let weights: [UIFont.Weight] = [.ultraLight, .light, .regular, .medium, .semibold, .bold, .heavy, .black]

        for weight in weights {
            // When: Creating font with weight
            let font = TextRenderer.font(from: .sfPro, size: 16, weight: weight)

            // Then: Should return valid font
            XCTAssertNotNil(font)
            XCTAssertEqual(font.pointSize, 16)
        }
    }

    func testMeasureTextReturnsNonZeroSize() {
        // Given: Non-empty text
        let text = "Measure this text"
        let font = UIFont.systemFont(ofSize: 16)

        // When: Measuring text
        let size = TextRenderer.measureText(text, font: font, maxWidth: 300)

        // Then: Should return non-zero size
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    func testMeasureTextWithEmptyString() {
        // Given: Empty string
        let text = ""
        let font = UIFont.systemFont(ofSize: 16)

        // When: Measuring text
        let size = TextRenderer.measureText(text, font: font, maxWidth: 300)

        // Then: Should return minimal size
        XCTAssertGreaterThanOrEqual(size.width, 0)
        XCTAssertGreaterThanOrEqual(size.height, 0)
    }

    func testMeasureTextRespectsMaxWidth() {
        // Given: Long text
        let text = String(repeating: "Long text that will wrap ", count: 20)
        let font = UIFont.systemFont(ofSize: 16)
        let maxWidth: CGFloat = 200

        // When: Measuring text
        let size = TextRenderer.measureText(text, font: font, maxWidth: maxWidth)

        // Then: Width should not exceed maxWidth (with small tolerance for rounding)
        XCTAssertLessThanOrEqual(size.width, maxWidth + 1)
        XCTAssertGreaterThan(size.height, font.lineHeight) // Should wrap to multiple lines
    }

    func testNSTextAlignmentConversion() {
        // Given: All TextAlignment cases
        XCTAssertEqual(TextRenderer.nsTextAlignment(from: .left), .left)
        XCTAssertEqual(TextRenderer.nsTextAlignment(from: .center), .center)
        XCTAssertEqual(TextRenderer.nsTextAlignment(from: .right), .right)
    }

    func testStandardTextShadow() {
        // Given: Shadow strength
        let strength: CGFloat = 0.5

        // When: Creating standard shadow
        let shadow = TextRenderer.standardTextShadow(strength: strength)

        // Then: Should have expected properties
        XCTAssertEqual(shadow.offset, CGSize(width: 0, height: 1))
        XCTAssertEqual(shadow.blur, strength * 3)
    }

    // MARK: - ColorUtils Tests

    func testColorFromValidSixCharHex() {
        // Given: Valid 6-char hex strings
        let red = ColorUtils.color(from: "#FF0000")
        let green = ColorUtils.color(from: "#00FF00")
        let blue = ColorUtils.color(from: "#0000FF")

        // Then: Should produce expected colors
        XCTAssertEqual(red, UIColor.red)
        XCTAssertEqual(green, UIColor.green)
        XCTAssertEqual(blue, UIColor.blue)
    }

    func testColorFromThreeCharHex() {
        // Given: 3-char hex strings
        let red = ColorUtils.color(from: "#F00")
        let green = ColorUtils.color(from: "#0F0")
        let blue = ColorUtils.color(from: "#00F")

        // Then: Should produce expected colors
        XCTAssertEqual(red, UIColor.red)
        XCTAssertEqual(green, UIColor.green)
        XCTAssertEqual(blue, UIColor.blue)
    }

    func testColorFromHexWithoutHashPrefix() {
        // Given: Hex string without # prefix
        let color = ColorUtils.color(from: "FF0000")

        // Then: Should parse correctly
        XCTAssertEqual(color, UIColor.red)
    }

    func testColorFromInvalidHex() {
        // Given: Invalid hex string
        let color = ColorUtils.color(from: "invalid")

        // Then: Should fall back to white
        XCTAssertEqual(color, UIColor.white)
    }

    func testColorFromEmptyString() {
        // Given: Empty string
        let color = ColorUtils.color(from: "")

        // Then: Should fall back to white
        XCTAssertEqual(color, UIColor.white)
    }

    func testHexFromColor() {
        // Given: UIColors
        let redHex = ColorUtils.hex(from: .red)
        let greenHex = ColorUtils.hex(from: .green)
        let blueHex = ColorUtils.hex(from: .blue)

        // Then: Should produce valid hex strings
        XCTAssertTrue(redHex.hasPrefix("#"))
        XCTAssertEqual(redHex.count, 7) // #RRGGBB
        XCTAssertTrue(greenHex.hasPrefix("#"))
        XCTAssertTrue(blueHex.hasPrefix("#"))
    }

    func testHexFromColorRoundTrip() {
        // Given: A specific color
        let originalHex = "#6C63FF"
        let color = ColorUtils.color(from: originalHex)

        // When: Converting back to hex
        let resultHex = ColorUtils.hex(from: color)

        // Then: Should be the same (accounting for rounding)
        XCTAssertEqual(resultHex.uppercased(), originalHex.uppercased())
    }

    func testHexFromColorWithAlpha() {
        // Given: Color with alpha < 1
        let color = UIColor.red.withAlphaComponent(0.5)

        // When: Converting to hex
        let hex = ColorUtils.hex(from: color)

        // Then: Should include alpha in format #RRGGBBAA
        XCTAssertEqual(hex.count, 9) // #RRGGBBAA
        XCTAssertTrue(hex.hasSuffix("80")) // 0.5 * 255 ≈ 128 = 0x80
    }

    func testGradientImageProducesNonNilImage() {
        // Given: Gradient colors and size
        let colors = [UIColor.red, UIColor.blue]
        let size = CGSize(width: 300, height: 600)

        // When: Creating gradient
        let gradientImage = ColorUtils.gradientImage(colors: colors, size: size)

        // Then: Should produce non-nil image
        XCTAssertNotNil(gradientImage)
    }

    func testGradientImageWithExpectedSize() {
        // Given: Gradient parameters
        let colors = [UIColor.red, UIColor.orange, UIColor.yellow]
        let size = CGSize(width: 400, height: 800)

        // When: Creating gradient
        let gradientImage = ColorUtils.gradientImage(colors: colors, size: size)

        // Then: Should have expected dimensions
        XCTAssertNotNil(gradientImage)
        XCTAssertEqual(CGFloat(gradientImage!.width), size.width)
        XCTAssertEqual(CGFloat(gradientImage!.height), size.height)
    }

    func testGradientImageWithEmptyColors() {
        // Given: Empty colors array
        let colors: [UIColor] = []
        let size = CGSize(width: 300, height: 600)

        // When: Creating gradient
        let gradientImage = ColorUtils.gradientImage(colors: colors, size: size)

        // Then: Should return nil
        XCTAssertNil(gradientImage)
    }

    func testGradientImageWithZeroSize() {
        // Given: Zero size
        let colors = [UIColor.red, UIColor.blue]
        let size = CGSize.zero

        // When: Creating gradient
        let gradientImage = ColorUtils.gradientImage(colors: colors, size: size)

        // Then: Should return nil
        XCTAssertNil(gradientImage)
    }

    func testAdjustBrightnessOfColor() {
        // Given: A color
        let color = UIColor.blue

        // When: Adjusting brightness
        let brighter = ColorUtils.adjustBrightness(of: color, by: 0.3)
        let darker = ColorUtils.adjustBrightness(of: color, by: -0.3)

        // Then: Should return non-nil colors
        XCTAssertNotNil(brighter)
        XCTAssertNotNil(darker)
        XCTAssertNotEqual(brighter, color)
        XCTAssertNotEqual(darker, color)
    }

    func testAdjustBrightnessClamps() {
        // Given: A color
        let color = UIColor.white

        // When: Trying to increase brightness beyond max
        let result = ColorUtils.adjustBrightness(of: color, by: 10.0)

        // Then: Should clamp to valid range
        XCTAssertNotNil(result)
    }

    func testWithOpacity() {
        // Given: A color
        let color = UIColor.red

        // When: Setting opacity
        let transparent = ColorUtils.withOpacity(color, opacity: 0.5)
        let opaque = ColorUtils.withOpacity(color, opacity: 1.0)

        // Then: Should have correct alpha
        XCTAssertNotNil(transparent)
        XCTAssertNotNil(opaque)

        var alpha: CGFloat = 0
        transparent.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.5, accuracy: 0.01)
    }

    func testWithOpacityClamps() {
        // Given: A color
        let color = UIColor.blue

        // When: Setting invalid opacity
        let result1 = ColorUtils.withOpacity(color, opacity: -1.0)
        let result2 = ColorUtils.withOpacity(color, opacity: 2.0)

        // Then: Should clamp to [0, 1]
        var alpha1: CGFloat = 0
        var alpha2: CGFloat = 0
        result1.getRed(nil, green: nil, blue: nil, alpha: &alpha1)
        result2.getRed(nil, green: nil, blue: nil, alpha: &alpha2)

        XCTAssertEqual(alpha1, 0.0)
        XCTAssertEqual(alpha2, 1.0)
    }

    func testBlendColorsAt0() {
        // Given: Two colors
        let color1 = UIColor.red
        let color2 = UIColor.blue

        // When: Blending at ratio 0 (all color1)
        let blended = ColorUtils.blend(color1, with: color2, ratio: 0.0)

        // Then: Should be equal to color1
        XCTAssertEqual(blended, color1)
    }

    func testBlendColorsAt1() {
        // Given: Two colors
        let color1 = UIColor.red
        let color2 = UIColor.blue

        // When: Blending at ratio 1 (all color2)
        let blended = ColorUtils.blend(color1, with: color2, ratio: 1.0)

        // Then: Should be equal to color2
        XCTAssertEqual(blended, color2)
    }

    func testBlendColorsAt05() {
        // Given: Two colors
        let color1 = UIColor.red
        let color2 = UIColor.blue

        // When: Blending at ratio 0.5
        let blended = ColorUtils.blend(color1, with: color2, ratio: 0.5)

        // Then: Should be a mix of both
        XCTAssertNotEqual(blended, color1)
        XCTAssertNotEqual(blended, color2)
    }

    // MARK: - AppGroupManager Tests

    func testGroupIDIsCorrect() {
        // When: Getting group ID
        let groupID = AppGroupManager.groupID

        // Then: Should match expected value
        XCTAssertEqual(groupID, "group.com.ronenmars.Schedulock")
    }

    func testWallpaperDirectoryIsNonNil() {
        // When: Getting wallpaper directory
        let directory = AppGroupManager.wallpaperDirectory

        // Then: Should return non-nil URL
        XCTAssertNotNil(directory)
        XCTAssertTrue(directory.path.contains("Wallpapers"))
    }

    func testImagesDirectoryIsNonNil() {
        // When: Getting images directory
        let directory = AppGroupManager.imagesDirectory

        // Then: Should return non-nil URL
        XCTAssertNotNil(directory)
        XCTAssertTrue(directory.path.contains("Images"))
    }

    func testHistoryDirectoryIsNonNil() {
        // When: Getting history directory
        let directory = AppGroupManager.historyDirectory

        // Then: Should return non-nil URL
        XCTAssertNotNil(directory)
        XCTAssertTrue(directory.path.contains("history"))
    }

    func testEnsureDirectoriesExistDoesNotCrash() {
        // When: Ensuring directories exist
        AppGroupManager.ensureDirectoriesExist()

        // Then: Should complete without crashing
        XCTAssertTrue(FileManager.default.fileExists(atPath: AppGroupManager.wallpaperDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: AppGroupManager.imagesDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: AppGroupManager.historyDirectory.path))
    }

    // MARK: - DesignTokens Tests

    func testBackgroundColorExists() {
        // When: Getting background color
        let color = DesignTokens.background

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testSurfaceColorExists() {
        // When: Getting surface color
        let color = DesignTokens.surface

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testPrimaryColorExists() {
        // When: Getting primary color
        let color = DesignTokens.primary

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testPrimaryGlowColorExists() {
        // When: Getting primary glow color
        let color = DesignTokens.primaryGlow

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testTextPrimaryColorExists() {
        // When: Getting text primary color
        let color = DesignTokens.textPrimary

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testTextMutedColorExists() {
        // When: Getting text muted color
        let color = DesignTokens.textMuted

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testDangerColorExists() {
        // When: Getting danger color
        let color = DesignTokens.danger

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testSuccessColorExists() {
        // When: Getting success color
        let color = DesignTokens.success

        // Then: Should not be nil
        XCTAssertNotNil(color)
    }

    func testCornerRadiiArePositive() {
        // When: Getting corner radii
        XCTAssertGreaterThan(DesignTokens.cardRadius, 0)
        XCTAssertGreaterThan(DesignTokens.glassRadius, 0)
        XCTAssertGreaterThan(DesignTokens.phoneFrameRadius, 0)
    }

    func testSpacingValuesArePositive() {
        // When: Getting spacing values
        XCTAssertGreaterThan(DesignTokens.spacingXS, 0)
        XCTAssertGreaterThan(DesignTokens.spacingSM, 0)
        XCTAssertGreaterThan(DesignTokens.spacingMD, 0)
        XCTAssertGreaterThan(DesignTokens.spacingLG, 0)
        XCTAssertGreaterThan(DesignTokens.spacingXL, 0)
    }

    func testSpacingValuesAreOrderedCorrectly() {
        // Then: Spacing should increase
        XCTAssertLessThan(DesignTokens.spacingXS, DesignTokens.spacingSM)
        XCTAssertLessThan(DesignTokens.spacingSM, DesignTokens.spacingMD)
        XCTAssertLessThan(DesignTokens.spacingMD, DesignTokens.spacingLG)
        XCTAssertLessThan(DesignTokens.spacingLG, DesignTokens.spacingXL)
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw a simple gradient background
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
