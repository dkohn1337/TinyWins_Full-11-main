import XCTest
import SwiftUI
@testable import TinyWins

/// Tests for the design token system
/// Validates WCAG contrast requirements and token resolution
final class TokenTests: XCTestCase {

    // MARK: - Contrast Tests

    /// Test that all text colors meet WCAG AA contrast on their intended backgrounds
    func testTextContrastMeetsWCAGAA() {
        for themePack in ThemePack.allCases {
            for appearance in Appearance.allCases {
                let tokens = SemanticTokens(appearance: appearance, themePack: themePack)

                // Primary text on app background
                let primaryContrast = tokens.textPrimary.contrastRatio(with: tokens.bgApp)
                XCTAssertGreaterThanOrEqual(
                    primaryContrast, 4.5,
                    "Primary text contrast failed for \(themePack) \(appearance): \(primaryContrast)"
                )

                // Secondary text on app background
                let secondaryContrast = tokens.textSecondary.contrastRatio(with: tokens.bgApp)
                XCTAssertGreaterThanOrEqual(
                    secondaryContrast, 4.5,
                    "Secondary text contrast failed for \(themePack) \(appearance): \(secondaryContrast)"
                )

                // Primary text on surface background
                let surfaceContrast = tokens.textPrimary.contrastRatio(with: tokens.bgSurface)
                XCTAssertGreaterThanOrEqual(
                    surfaceContrast, 4.5,
                    "Surface text contrast failed for \(themePack) \(appearance): \(surfaceContrast)"
                )

                // Text on primary buttons
                let buttonContrast = tokens.textOnPrimary.contrastRatio(with: tokens.accentPrimary)
                XCTAssertGreaterThanOrEqual(
                    buttonContrast, 4.5,
                    "Button text contrast failed for \(themePack) \(appearance): \(buttonContrast)"
                )
            }
        }
    }

    /// Test that all child avatar colors provide contrast-safe initials text
    func testAvatarInitialsContrast() {
        for childColor in Primitives.ChildColors.allCases {
            for appearance in Appearance.allCases {
                let avatarTokens = AvatarTokens(childColor: childColor.color, appearance: appearance)

                let contrast = avatarTokens.initialsText.contrastRatio(with: avatarTokens.circleFill)
                XCTAssertGreaterThanOrEqual(
                    contrast, 4.5,
                    "Avatar initials contrast failed for \(childColor) \(appearance): \(contrast)"
                )
            }
        }
    }

    /// Test that semantic colors meet contrast requirements
    func testSemanticColorContrast() {
        for appearance in Appearance.allCases {
            let tokens = SemanticTokens(appearance: appearance, themePack: .classic)

            // Positive color on positive background
            let positiveContrast = tokens.positive.contrastRatio(with: tokens.positiveBg)
            XCTAssertGreaterThanOrEqual(
                positiveContrast, 3.0,
                "Positive color contrast failed for \(appearance): \(positiveContrast)"
            )

            // Challenge color on challenge background
            let challengeContrast = tokens.challenge.contrastRatio(with: tokens.challengeBg)
            XCTAssertGreaterThanOrEqual(
                challengeContrast, 3.0,
                "Challenge color contrast failed for \(appearance): \(challengeContrast)"
            )

            // Error color on error background
            let errorContrast = tokens.error.contrastRatio(with: tokens.errorBg)
            XCTAssertGreaterThanOrEqual(
                errorContrast, 3.0,
                "Error color contrast failed for \(appearance): \(errorContrast)"
            )
        }
    }

    // MARK: - Token Resolution Tests

    /// Test that tokens resolve correctly for light mode
    func testLightModeResolution() {
        let tokens = SemanticTokens(appearance: .light, themePack: .classic)

        // Background should be white in light mode
        XCTAssertEqual(tokens.bgApp, Primitives.Neutral.white)

        // Text should be dark in light mode
        XCTAssertEqual(tokens.textPrimary, Primitives.Neutral.gray900)
    }

    /// Test that tokens resolve correctly for dark mode
    func testDarkModeResolution() {
        let tokens = SemanticTokens(appearance: .dark, themePack: .classic)

        // Background should be dark in dark mode
        XCTAssertEqual(tokens.bgApp, Primitives.Neutral.gray950)

        // Text should be light in dark mode
        XCTAssertEqual(tokens.textPrimary, Primitives.Neutral.gray50)
    }

    /// Test that different themes produce different accent colors
    func testThemePackDifferentiation() {
        let classic = SemanticTokens(appearance: .light, themePack: .classic)
        let ocean = SemanticTokens(appearance: .light, themePack: .ocean)
        let sunset = SemanticTokens(appearance: .light, themePack: .sunset)

        // Accent colors should be different
        XCTAssertNotEqual(classic.accentPrimary, ocean.accentPrimary)
        XCTAssertNotEqual(classic.accentPrimary, sunset.accentPrimary)
        XCTAssertNotEqual(ocean.accentPrimary, sunset.accentPrimary)

        // But text colors should be the same (theme doesn't affect legibility)
        XCTAssertEqual(classic.textPrimary, ocean.textPrimary)
        XCTAssertEqual(classic.textPrimary, sunset.textPrimary)
    }

    // MARK: - Component Token Tests

    /// Test button tokens are properly derived from semantic tokens
    func testButtonTokenDerivation() {
        let semantic = SemanticTokens(appearance: .light, themePack: .classic)
        let button = ButtonTokens(semantic: semantic)

        // Primary button background should match accent
        XCTAssertEqual(button.primaryBackground, semantic.accentPrimary)

        // Primary button text should be onPrimary
        XCTAssertEqual(button.primaryText, semantic.textOnPrimary)
    }

    /// Test card tokens are properly derived from semantic tokens
    func testCardTokenDerivation() {
        let semantic = SemanticTokens(appearance: .light, themePack: .classic)
        let card = CardTokens(semantic: semantic)

        // Card background should match surface
        XCTAssertEqual(card.background, semantic.bgSurface)

        // Card border should match borderSubtle
        XCTAssertEqual(card.border, semantic.borderSubtle)
    }

    // MARK: - Luminance Tests

    /// Test luminance calculation accuracy
    func testLuminanceCalculation() {
        // White should have luminance close to 1
        let whiteLuminance = Primitives.Neutral.white.luminance
        XCTAssertGreaterThan(whiteLuminance, 0.95)

        // Black should have luminance close to 0
        let blackLuminance = Primitives.Neutral.black.luminance
        XCTAssertLessThan(blackLuminance, 0.05)

        // Gray should be in the middle
        let grayLuminance = Primitives.Neutral.gray500.luminance
        XCTAssertGreaterThan(grayLuminance, 0.1)
        XCTAssertLessThan(grayLuminance, 0.5)
    }

    /// Test contrast ratio calculation
    func testContrastRatioCalculation() {
        // Black on white should have maximum contrast
        let maxContrast = Primitives.Neutral.black.contrastRatio(with: Primitives.Neutral.white)
        XCTAssertGreaterThan(maxContrast, 20)

        // Same color should have contrast ratio of 1
        let sameColorContrast = Primitives.Neutral.gray500.contrastRatio(with: Primitives.Neutral.gray500)
        XCTAssertEqual(sameColorContrast, 1.0, accuracy: 0.01)
    }
}

// MARK: - Test Helpers

extension Appearance: CaseIterable {
    public static var allCases: [Appearance] = [.light, .dark]
}
