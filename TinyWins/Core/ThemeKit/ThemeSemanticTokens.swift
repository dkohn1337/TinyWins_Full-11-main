import SwiftUI

// MARK: - Semantic Token Protocol

/// Protocol defining all semantic color tokens for the theme system.
/// UI code must ONLY reference these tokens, never raw colors.
protocol SemanticColorTokens {
    // MARK: - Surfaces (backgrounds)

    /// Main app background (lowest level)
    var bg0: Color { get }
    /// Grouped/inset background
    var bg1: Color { get }
    /// Card surface (primary elevated surface)
    var surface1: Color { get }
    /// Elevated card, sheet, modal surface
    var surface2: Color { get }
    /// Highest elevation (pressed state, popover)
    var surface3: Color { get }
    /// Scrim overlay for modals
    var scrim: Color { get }

    // MARK: - Borders and Separators

    /// Subtle border for cards
    var borderSoft: Color { get }
    /// Strong border for focused/selected states
    var borderStrong: Color { get }
    /// List/section separators
    var separator: Color { get }

    // MARK: - Text

    /// Primary text (headlines, body)
    var textPrimary: Color { get }
    /// Secondary text (subtitles, captions)
    var textSecondary: Color { get }
    /// Tertiary text (placeholders, hints)
    var textTertiary: Color { get }
    /// Disabled text
    var textDisabled: Color { get }
    /// Text on accent-colored backgrounds
    var textOnAccent: Color { get }
    /// Inverse text (for dark on light / light on dark)
    var textInverse: Color { get }

    // MARK: - Accents (Theme-Specific)

    /// Primary accent color (buttons, links, selected states)
    var accentPrimary: Color { get }
    /// Secondary accent color
    var accentSecondary: Color { get }
    /// Muted accent for subtle highlights
    var accentMuted: Color { get }
    /// Button gradient colors
    var accentGradient: [Color] { get }

    // MARK: - Semantic States

    /// Success/positive state
    var success: Color { get }
    /// Success background
    var successBg: Color { get }
    /// Warning state
    var warning: Color { get }
    /// Warning background
    var warningBg: Color { get }
    /// Danger/error state
    var danger: Color { get }
    /// Danger background
    var dangerBg: Color { get }
    /// Info state
    var info: Color { get }
    /// Info background
    var infoBg: Color { get }
    /// Star/reward color
    var star: Color { get }
    /// Routine/habit color
    var routine: Color { get }

    // MARK: - Navigation and Chrome

    /// Tab bar background
    var tabBarBg: Color { get }
    /// Tab bar border
    var tabBarBorder: Color { get }
    /// Default tab icon
    var tabIconDefault: Color { get }
    /// Selected tab icon
    var tabIconSelected: Color { get }
    /// Navigation bar background
    var navBarBg: Color { get }
    /// Navigation bar text
    var navBarText: Color { get }

    // MARK: - Effects

    /// Shadow color
    var shadowColor: Color { get }
    /// Shadow intensity (0-1)
    var shadowStrength: CGFloat { get }
    /// Glow color for highlights (optional, use sparingly)
    var glowColor: Color { get }

    // MARK: - Avatar (derived from child color)

    /// Avatar circle fill
    var avatarFill: Color { get }
    /// Text/icon on avatar (contrast-safe)
    var avatarOnFill: Color { get }
    /// Muted avatar fill for backgrounds
    var avatarMutedFill: Color { get }
    /// Avatar border color
    var avatarBorder: Color { get }
}

// MARK: - Resolved Semantic Tokens

/// Concrete implementation of semantic tokens resolved from palette and appearance.
struct ResolvedSemanticTokens: SemanticColorTokens {
    let palette: Palette
    let appearance: EffectiveAppearance
    let avatarColor: Color?

    private var isDark: Bool {
        appearance == .dark
    }

    // MARK: - Surfaces

    var bg0: Color {
        isDark ? palette.dark.bg0 : palette.light.bg0
    }

    var bg1: Color {
        isDark ? palette.dark.bg1 : palette.light.bg1
    }

    var surface1: Color {
        isDark ? palette.dark.surface1 : palette.light.surface1
    }

    var surface2: Color {
        isDark ? palette.dark.surface2 : palette.light.surface2
    }

    var surface3: Color {
        isDark ? palette.dark.surface3 : palette.light.surface3
    }

    var scrim: Color {
        Color.black.opacity(isDark ? 0.7 : 0.5)
    }

    // MARK: - Borders

    var borderSoft: Color {
        isDark ? palette.dark.borderSoft : palette.light.borderSoft
    }

    var borderStrong: Color {
        isDark ? palette.dark.borderStrong : palette.light.borderStrong
    }

    var separator: Color {
        isDark ? palette.dark.separator : palette.light.separator
    }

    // MARK: - Text

    var textPrimary: Color {
        isDark ? palette.dark.textPrimary : palette.light.textPrimary
    }

    var textSecondary: Color {
        isDark ? palette.dark.textSecondary : palette.light.textSecondary
    }

    var textTertiary: Color {
        isDark ? palette.dark.textTertiary : palette.light.textTertiary
    }

    var textDisabled: Color {
        isDark ? palette.dark.textDisabled : palette.light.textDisabled
    }

    var textOnAccent: Color {
        // White provides best contrast on all theme accent colors
        .white
    }

    var textInverse: Color {
        isDark ? palette.light.textPrimary : palette.dark.textPrimary
    }

    // MARK: - Accents

    var accentPrimary: Color {
        isDark ? palette.dark.accentPrimary : palette.light.accentPrimary
    }

    var accentSecondary: Color {
        isDark ? palette.dark.accentSecondary : palette.light.accentSecondary
    }

    var accentMuted: Color {
        accentPrimary.opacity(isDark ? 0.25 : 0.15)
    }

    var accentGradient: [Color] {
        isDark ? palette.dark.gradientColors : palette.light.gradientColors
    }

    // MARK: - Semantic States

    var success: Color {
        isDark
            ? Color(red: 0.35, green: 0.85, blue: 0.5)  // Brighter for dark
            : Color(red: 0.3, green: 0.75, blue: 0.45)
    }

    var successBg: Color {
        success.opacity(isDark ? 0.2 : 0.12)
    }

    var warning: Color {
        isDark
            ? Color(red: 1.0, green: 0.6, blue: 0.35)   // Brighter for dark
            : Color(red: 1.0, green: 0.55, blue: 0.3)
    }

    var warningBg: Color {
        warning.opacity(isDark ? 0.2 : 0.12)
    }

    var danger: Color {
        isDark
            ? Color(red: 1.0, green: 0.45, blue: 0.45)
            : Color(red: 0.9, green: 0.3, blue: 0.3)
    }

    var dangerBg: Color {
        danger.opacity(isDark ? 0.2 : 0.12)
    }

    var info: Color {
        isDark
            ? Color(red: 0.45, green: 0.7, blue: 0.95)
            : Color(red: 0.3, green: 0.55, blue: 0.85)
    }

    var infoBg: Color {
        info.opacity(isDark ? 0.2 : 0.12)
    }

    var star: Color {
        isDark
            ? Color(red: 1.0, green: 0.85, blue: 0.3)
            : Color(red: 1.0, green: 0.78, blue: 0.2)
    }

    var routine: Color {
        isDark
            ? Color(red: 0.7, green: 0.55, blue: 0.95)
            : Color(red: 0.55, green: 0.4, blue: 0.85)
    }

    // MARK: - Navigation Chrome

    var tabBarBg: Color {
        isDark ? palette.dark.surface1 : palette.light.bg0
    }

    var tabBarBorder: Color {
        separator
    }

    var tabIconDefault: Color {
        textTertiary
    }

    var tabIconSelected: Color {
        accentPrimary
    }

    var navBarBg: Color {
        bg0
    }

    var navBarText: Color {
        textPrimary
    }

    // MARK: - Effects

    var shadowColor: Color {
        isDark ? .black : palette.light.shadowColor
    }

    var shadowStrength: CGFloat {
        isDark ? palette.dark.shadowStrength : palette.light.shadowStrength
    }

    var glowColor: Color {
        accentPrimary.opacity(isDark ? 0.4 : 0.25)
    }

    // MARK: - Avatar (with safety)

    var avatarFill: Color {
        guard let avatar = avatarColor else { return accentPrimary }
        return avatar
    }

    var avatarOnFill: Color {
        guard let avatar = avatarColor else { return textOnAccent }
        return ContrastUtilities.safeOnColor(for: avatar)
    }

    var avatarMutedFill: Color {
        guard let avatar = avatarColor else { return accentMuted }
        return avatar.opacity(isDark ? 0.25 : 0.15)
    }

    var avatarBorder: Color {
        guard let avatar = avatarColor else { return borderStrong }
        return avatar.opacity(isDark ? 0.8 : 0.6)
    }
}

// MARK: - Effective Appearance

/// The resolved appearance mode (always light or dark)
enum EffectiveAppearance {
    case light
    case dark

    init(from colorScheme: ColorScheme) {
        self = colorScheme == .dark ? .dark : .light
    }
}
