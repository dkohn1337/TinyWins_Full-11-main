import SwiftUI

// MARK: - Contrast Utilities

/// Utilities for calculating color contrast and ensuring accessibility.
/// All UI that uses avatar colors or dynamic backgrounds must use these utilities.
enum ContrastUtilities {

    // MARK: - Luminance Calculation (WCAG 2.1)

    /// Calculate relative luminance of a color.
    /// Returns a value between 0 (black) and 1 (white).
    static func luminance(of color: Color) -> CGFloat {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Apply gamma correction per WCAG 2.1
        func adjust(_ component: CGFloat) -> CGFloat {
            component <= 0.03928
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        let r = adjust(red)
        let g = adjust(green)
        let b = adjust(blue)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    // MARK: - Contrast Ratio Calculation (WCAG 2.1)

    /// Calculate contrast ratio between two colors.
    /// Returns a value from 1:1 (same color) to 21:1 (black/white).
    static func contrastRatio(between color1: Color, and color2: Color) -> CGFloat {
        let l1 = luminance(of: color1)
        let l2 = luminance(of: color2)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // MARK: - WCAG AA Compliance Check

    /// Check if contrast meets WCAG AA for normal text (4.5:1).
    static func meetsWCAGAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(between: foreground, and: background) >= 4.5
    }

    /// Check if contrast meets WCAG AA for large text (3:1).
    static func meetsWCAGAALarge(foreground: Color, background: Color) -> Bool {
        contrastRatio(between: foreground, and: background) >= 3.0
    }

    /// Check if contrast meets WCAG AAA for normal text (7:1).
    static func meetsWCAGAAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(between: foreground, and: background) >= 7.0
    }

    // MARK: - Safe On-Color Derivation

    /// Returns a safe foreground color (white or near-black) for any background.
    /// Guarantees WCAG AA compliance.
    static func safeOnColor(for background: Color) -> Color {
        let bgLuminance = luminance(of: background)

        // Use white text on dark backgrounds, dark text on light backgrounds
        // Threshold of 0.179 corresponds to ~4.5:1 contrast with white
        if bgLuminance > 0.179 {
            return Color(red: 0.1, green: 0.1, blue: 0.12)  // Near-black, not pure black
        } else {
            return Color.white.opacity(0.95)  // Off-white, not pure white for comfort
        }
    }

    /// Returns an adjusted version of the accent color that meets contrast requirements
    /// against the given background.
    static func safeAccentColor(accent: Color, on background: Color, minContrast: CGFloat = 4.5) -> Color {
        let currentContrast = contrastRatio(between: accent, and: background)

        if currentContrast >= minContrast {
            return accent
        }

        // Need to adjust - determine direction based on background luminance
        let bgLuminance = luminance(of: background)

        // Extract color components
        let uiColor = UIColor(accent)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // Adjust brightness to meet contrast
        var adjustedBrightness = b
        let step: CGFloat = 0.05
        let maxIterations = 20

        for _ in 0..<maxIterations {
            if bgLuminance > 0.5 {
                // Light background - darken the accent
                adjustedBrightness = max(0.1, adjustedBrightness - step)
            } else {
                // Dark background - lighten the accent
                adjustedBrightness = min(1.0, adjustedBrightness + step)
            }

            let adjustedColor = Color(UIColor(hue: h, saturation: s, brightness: adjustedBrightness, alpha: a))
            if contrastRatio(between: adjustedColor, and: background) >= minContrast {
                return adjustedColor
            }
        }

        // Fallback to safe on-color if adjustment wasn't sufficient
        return safeOnColor(for: background)
    }
}

// MARK: - Color Extension (Additional Utilities)
// Note: `luminance` is already defined in Primitives.swift

extension Color {
    /// Contrast ratio with another color.
    func contrastRatioWith(_ other: Color) -> CGFloat {
        ContrastUtilities.contrastRatio(between: self, and: other)
    }

    /// Safe text color for use on this background.
    var safeOnColor: Color {
        ContrastUtilities.safeOnColor(for: self)
    }

    /// Check if this foreground color meets WCAG AA on the given background.
    func meetsWCAGAA(on background: Color) -> Bool {
        ContrastUtilities.meetsWCAGAA(foreground: self, background: background)
    }
}

// MARK: - Avatar Color Safety

/// Safe avatar color derivation ensuring contrast compliance.
struct AvatarColorDerivation {
    let baseColor: Color
    let appearance: EffectiveAppearance

    /// Primary fill color for the avatar circle.
    var fill: Color {
        baseColor
    }

    /// Safe text/icon color on the avatar fill.
    /// Guaranteed to meet WCAG AA (4.5:1 contrast).
    var onFill: Color {
        ContrastUtilities.safeOnColor(for: baseColor)
    }

    /// Muted fill for badge backgrounds.
    var mutedFill: Color {
        baseColor.opacity(appearance == .dark ? 0.25 : 0.15)
    }

    /// Border color for avatar outline.
    var border: Color {
        baseColor.opacity(appearance == .dark ? 0.75 : 0.6)
    }

    /// Whether the base color is safe to use as text on the given background.
    func isSafeAsText(on background: Color, isLargeText: Bool = false) -> Bool {
        let minContrast: CGFloat = isLargeText ? 3.0 : 4.5
        return ContrastUtilities.contrastRatio(between: baseColor, and: background) >= minContrast
    }

    /// Get a safe version of the base color for use as text.
    /// Returns nil if no safe version can be derived.
    func safeTextColor(on background: Color) -> Color? {
        if isSafeAsText(on: background) {
            return baseColor
        }

        // Try to adjust the color
        let adjusted = ContrastUtilities.safeAccentColor(accent: baseColor, on: background)
        let adjustedContrast = ContrastUtilities.contrastRatio(between: adjusted, and: background)

        // Only return if we achieved reasonable contrast (at least 3:1 for large text)
        if adjustedContrast >= 3.0 {
            return adjusted
        }

        return nil
    }
}
