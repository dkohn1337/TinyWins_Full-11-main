import SwiftUI

// MARK: - Appearance

/// The visual appearance mode of the app
enum Appearance: String, CaseIterable {
    case light
    case dark

    init(from colorScheme: ColorScheme) {
        self = colorScheme == .dark ? .dark : .light
    }

    var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }
}

// MARK: - Theme Pack

/// The selected theme pack (color scheme)
/// This affects accent colors, not legibility
enum ThemePack: String, CaseIterable, Identifiable {
    case system
    case classic
    case ocean
    case sunset
    case forest
    case midnight
    case aurora
    case rosegold
    case lavender
    case mint
    case slate
    case champagne
    case nordic

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var isPremium: Bool {
        switch self {
        case .system, .classic, .ocean, .sunset, .forest:
            return false
        case .midnight, .aurora, .rosegold, .lavender, .mint, .slate, .champagne, .nordic:
            return true
        }
    }

    /// Primary accent color for this theme
    func primaryColor(for appearance: Appearance) -> Color {
        switch self {
        case .system, .classic:
            return appearance == .dark ? Primitives.Classic.primaryLight : Primitives.Classic.primary
        case .ocean:
            return appearance == .dark ? Primitives.Ocean.primaryLight : Primitives.Ocean.primary
        case .sunset:
            return appearance == .dark ? Primitives.Sunset.primaryLight : Primitives.Sunset.primary
        case .forest:
            return appearance == .dark ? Primitives.Forest.primaryLight : Primitives.Forest.primary
        case .midnight:
            return appearance == .dark ? Primitives.Midnight.primaryLight : Primitives.Midnight.primary
        case .aurora:
            return appearance == .dark ? Primitives.Aurora.primaryLight : Primitives.Aurora.primary
        case .rosegold:
            return appearance == .dark ? Primitives.Rosegold.primaryLight : Primitives.Rosegold.primary
        case .lavender:
            return appearance == .dark ? Primitives.Lavender.primaryLight : Primitives.Lavender.primary
        case .mint:
            return appearance == .dark ? Primitives.Mint.primaryLight : Primitives.Mint.primary
        case .slate:
            return appearance == .dark ? Primitives.Slate.primaryLight : Primitives.Slate.primary
        case .champagne:
            return appearance == .dark ? Primitives.Champagne.primaryLight : Primitives.Champagne.primary
        case .nordic:
            return appearance == .dark ? Primitives.Nordic.primaryLight : Primitives.Nordic.primary
        }
    }

    /// Secondary accent color for this theme
    func secondaryColor(for appearance: Appearance) -> Color {
        switch self {
        case .system, .classic: return Primitives.Classic.secondary
        case .ocean: return Primitives.Ocean.secondary
        case .sunset: return Primitives.Sunset.secondary
        case .forest: return Primitives.Forest.secondary
        case .midnight: return Primitives.Midnight.secondary
        case .aurora: return Primitives.Aurora.secondary
        case .rosegold: return Primitives.Rosegold.secondary
        case .lavender: return Primitives.Lavender.secondary
        case .mint: return Primitives.Mint.secondary
        case .slate: return Primitives.Slate.secondary
        case .champagne: return Primitives.Champagne.secondary
        case .nordic: return Primitives.Nordic.secondary
        }
    }

    /// Accent tint color for backgrounds
    func accentTint(for appearance: Appearance) -> Color {
        switch self {
        case .system, .classic: return Primitives.Classic.accent
        case .ocean: return Primitives.Ocean.accent
        case .sunset: return Primitives.Sunset.accent
        case .forest: return Primitives.Forest.accent
        case .midnight: return Primitives.Midnight.accent
        case .aurora: return Primitives.Aurora.accent
        case .rosegold: return Primitives.Rosegold.accent
        case .lavender: return Primitives.Lavender.accent
        case .mint: return Primitives.Mint.accent
        case .slate: return Primitives.Slate.accent
        case .champagne: return Primitives.Champagne.accent
        case .nordic: return Primitives.Nordic.accent
        }
    }

    /// Button gradient colors
    func buttonGradient(for appearance: Appearance) -> [Color] {
        let primary = primaryColor(for: appearance)
        let secondary = secondaryColor(for: appearance)
        return [primary, secondary]
    }
}

// MARK: - Semantic Tokens Protocol

/// Role-based color tokens that resolve based on appearance
protocol SemanticTokensProtocol {
    // MARK: - Backgrounds

    /// Main app background
    var bgApp: Color { get }
    /// Elevated surface (cards, modals)
    var bgSurface: Color { get }
    /// Subtle surface variation
    var bgSurfaceSecondary: Color { get }
    /// Grouped/inset background
    var bgGrouped: Color { get }
    /// Overlay for modals/sheets
    var bgOverlay: Color { get }

    // MARK: - Text

    /// Primary text (headlines, body)
    var textPrimary: Color { get }
    /// Secondary text (captions, hints)
    var textSecondary: Color { get }
    /// Tertiary text (placeholders)
    var textTertiary: Color { get }
    /// Disabled text
    var textDisabled: Color { get }
    /// Inverse text (on dark backgrounds in light mode, vice versa)
    var textInverse: Color { get }
    /// Text on primary accent color
    var textOnPrimary: Color { get }

    // MARK: - Borders & Dividers

    /// Default border color
    var borderDefault: Color { get }
    /// Subtle/light border
    var borderSubtle: Color { get }
    /// Strong/emphasized border
    var borderStrong: Color { get }
    /// Focus ring color
    var borderFocused: Color { get }
    /// List/section dividers
    var divider: Color { get }

    // MARK: - Accents (Theme-Driven)

    /// Primary accent color
    var accentPrimary: Color { get }
    /// Secondary accent color
    var accentSecondary: Color { get }
    /// Muted accent for backgrounds
    var accentMuted: Color { get }
    /// Accent tint for subtle backgrounds
    var accentTint: Color { get }

    // MARK: - Semantic Colors (Fixed Across Themes)

    /// Positive/success color (wins)
    var positive: Color { get }
    /// Positive background
    var positiveBg: Color { get }
    /// Challenge/warning color
    var challenge: Color { get }
    /// Challenge background
    var challengeBg: Color { get }
    /// Error color
    var error: Color { get }
    /// Error background
    var errorBg: Color { get }
    /// Info color
    var info: Color { get }
    /// Info background
    var infoBg: Color { get }
    /// Star/reward color
    var star: Color { get }
    /// Star glow color
    var starGlow: Color { get }
    /// Routine color
    var routine: Color { get }
    /// Plus/premium color
    var plus: Color { get }

    // MARK: - Shadows

    /// Shadow color
    var shadow: Color { get }
    /// Shadow intensity multiplier
    var shadowIntensity: Double { get }
}

// MARK: - Semantic Tokens Implementation

/// Concrete implementation that resolves tokens based on appearance and theme
struct SemanticTokens: SemanticTokensProtocol {
    let appearance: Appearance
    let themePack: ThemePack

    // MARK: - Backgrounds

    var bgApp: Color {
        switch appearance {
        case .light: return Primitives.Neutral.white
        case .dark: return Primitives.Neutral.gray950
        }
    }

    var bgSurface: Color {
        switch appearance {
        case .light: return Primitives.Neutral.white
        case .dark: return Primitives.Neutral.gray900
        }
    }

    var bgSurfaceSecondary: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray50
        case .dark: return Primitives.Neutral.gray800
        }
    }

    var bgGrouped: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray100
        case .dark: return Primitives.Neutral.gray900
        }
    }

    var bgOverlay: Color {
        switch appearance {
        case .light: return Primitives.Neutral.black.opacity(0.4)
        case .dark: return Primitives.Neutral.black.opacity(0.6)
        }
    }

    // MARK: - Text

    var textPrimary: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray900
        case .dark: return Primitives.Neutral.gray50
        }
    }

    var textSecondary: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray500
        case .dark: return Primitives.Neutral.gray400
        }
    }

    var textTertiary: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray400
        case .dark: return Primitives.Neutral.gray500
        }
    }

    var textDisabled: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray300
        case .dark: return Primitives.Neutral.gray600
        }
    }

    var textInverse: Color {
        switch appearance {
        case .light: return Primitives.Neutral.white
        case .dark: return Primitives.Neutral.gray900
        }
    }

    var textOnPrimary: Color {
        // For most theme colors, white text provides good contrast
        // The accent colors are chosen to ensure this works
        return Primitives.Neutral.white
    }

    // MARK: - Borders & Dividers

    var borderDefault: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray200
        case .dark: return Primitives.Neutral.gray700
        }
    }

    var borderSubtle: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray100
        case .dark: return Primitives.Neutral.gray800
        }
    }

    var borderStrong: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray300
        case .dark: return Primitives.Neutral.gray600
        }
    }

    var borderFocused: Color {
        accentPrimary
    }

    var divider: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray200
        case .dark: return Primitives.Neutral.gray800
        }
    }

    // MARK: - Accents (Theme-Driven)

    var accentPrimary: Color {
        themePack.primaryColor(for: appearance)
    }

    var accentSecondary: Color {
        themePack.secondaryColor(for: appearance)
    }

    var accentMuted: Color {
        accentPrimary.opacity(appearance == .dark ? 0.3 : 0.15)
    }

    var accentTint: Color {
        themePack.accentTint(for: appearance).opacity(appearance == .dark ? 0.15 : 0.1)
    }

    // MARK: - Semantic Colors

    var positive: Color {
        switch appearance {
        case .light: return Primitives.Semantic.success600
        case .dark: return Primitives.Semantic.success500
        }
    }

    var positiveBg: Color {
        switch appearance {
        case .light: return Primitives.Semantic.success50
        case .dark: return Primitives.Semantic.success700.opacity(0.3)
        }
    }

    var challenge: Color {
        switch appearance {
        case .light: return Primitives.Semantic.warning600
        case .dark: return Primitives.Semantic.warning500
        }
    }

    var challengeBg: Color {
        switch appearance {
        case .light: return Primitives.Semantic.warning50
        case .dark: return Primitives.Semantic.warning700.opacity(0.3)
        }
    }

    var error: Color {
        switch appearance {
        case .light: return Primitives.Semantic.error600
        case .dark: return Primitives.Semantic.error500
        }
    }

    var errorBg: Color {
        switch appearance {
        case .light: return Primitives.Semantic.error50
        case .dark: return Primitives.Semantic.error700.opacity(0.3)
        }
    }

    var info: Color {
        switch appearance {
        case .light: return Primitives.Semantic.info600
        case .dark: return Primitives.Semantic.info500
        }
    }

    var infoBg: Color {
        switch appearance {
        case .light: return Primitives.Semantic.info50
        case .dark: return Primitives.Semantic.info700.opacity(0.3)
        }
    }

    var star: Color {
        Primitives.Semantic.starPrimary
    }

    var starGlow: Color {
        switch appearance {
        case .light: return Primitives.Semantic.starGlow
        case .dark: return Primitives.Semantic.starPrimary.opacity(0.4)
        }
    }

    var routine: Color {
        switch appearance {
        case .light: return Primitives.Semantic.routine
        case .dark: return Primitives.Semantic.routineLight
        }
    }

    var plus: Color {
        switch appearance {
        case .light: return Primitives.Semantic.plus
        case .dark: return Primitives.Semantic.plusLight
        }
    }

    // MARK: - Shadows

    var shadow: Color {
        switch appearance {
        case .light: return Primitives.Neutral.black
        case .dark: return Primitives.Neutral.black
        }
    }

    var shadowIntensity: Double {
        switch appearance {
        case .light: return 0.1
        case .dark: return 0.3
        }
    }
}

// MARK: - Avatar Tokens

/// Tokens specific to child avatar rendering
/// Ensures contrast-safe text on avatar backgrounds
struct AvatarTokens {
    let childColor: Color
    let appearance: Appearance

    /// The main circle fill color
    var circleFill: Color {
        childColor
    }

    /// Border/ring around avatar
    var circleStroke: Color {
        switch appearance {
        case .light: return childColor.opacity(0.6)
        case .dark: return childColor.opacity(0.8)
        }
    }

    /// Text color for initials inside avatar (ALWAYS contrast-safe)
    var initialsText: Color {
        childColor.contrastingTextColor
    }

    /// Glow/shadow effect color
    var glowEffect: Color {
        switch appearance {
        case .light: return childColor.opacity(0.25)
        case .dark: return childColor.opacity(0.4)
        }
    }

    /// Light background for badges, chips
    var badgeBackground: Color {
        switch appearance {
        case .light: return childColor.opacity(0.15)
        case .dark: return childColor.opacity(0.2)
        }
    }

    /// Accent text color derived from child color (use sparingly, only for large text)
    /// Returns nil if contrast is insufficient
    var accentTextColor: Color? {
        // Only allow as accent text on appropriate backgrounds
        switch appearance {
        case .light:
            // Check if color is dark enough for white background
            if childColor.contrastRatio(with: Primitives.Neutral.white) >= 3.0 {
                return childColor
            }
            return nil
        case .dark:
            // Check if color is bright enough for dark background
            if childColor.contrastRatio(with: Primitives.Neutral.gray900) >= 3.0 {
                return childColor
            }
            return nil
        }
    }
}

// MARK: - Component Tokens

/// Tokens for button components
struct ButtonTokens {
    let semantic: SemanticTokens

    // Primary button
    var primaryBackground: Color { semantic.accentPrimary }
    var primaryBackgroundPressed: Color { semantic.accentPrimary.opacity(0.85) }
    var primaryBackgroundDisabled: Color { semantic.accentPrimary.opacity(0.5) }
    var primaryText: Color { semantic.textOnPrimary }
    var primaryTextDisabled: Color { semantic.textOnPrimary.opacity(0.7) }

    // Secondary button
    var secondaryBackground: Color { semantic.bgSurface }
    var secondaryBackgroundPressed: Color { semantic.bgSurfaceSecondary }
    var secondaryBorder: Color { semantic.borderDefault }
    var secondaryText: Color { semantic.textPrimary }

    // Destructive button
    var destructiveBackground: Color { semantic.error }
    var destructiveText: Color { Primitives.Neutral.white }

    // Ghost button
    var ghostText: Color { semantic.accentPrimary }
    var ghostTextPressed: Color { semantic.accentPrimary.opacity(0.7) }
}

/// Tokens for card components
struct CardTokens {
    let semantic: SemanticTokens

    var background: Color { semantic.bgSurface }
    var backgroundElevated: Color { semantic.bgSurface }
    var backgroundSelected: Color { semantic.accentMuted }
    var border: Color { semantic.borderSubtle }
    var borderSelected: Color { semantic.accentPrimary.opacity(0.5) }
    var shadow: Color { semantic.shadow }
    var shadowIntensity: Double { semantic.shadowIntensity }
}

/// Tokens for input components
struct InputTokens {
    let semantic: SemanticTokens

    var background: Color { semantic.bgSurfaceSecondary }
    var backgroundFocused: Color { semantic.bgSurface }
    var border: Color { semantic.borderDefault }
    var borderFocused: Color { semantic.accentPrimary }
    var borderError: Color { semantic.error }
    var placeholder: Color { semantic.textTertiary }
    var text: Color { semantic.textPrimary }
}
