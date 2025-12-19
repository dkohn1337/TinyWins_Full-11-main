import SwiftUI

// MARK: - Palette ID

/// Identifies the selected theme palette.
/// Maps to AppTheme for backward compatibility.
enum PaletteId: String, CaseIterable, Identifiable, Codable {
    // SPECIAL
    case system = "system"       // Follows iOS settings

    // FREE (3 light themes)
    case gentle = "gentle"       // Soft, calming pastels
    case sunny = "sunny"         // Warm, cheerful yellows
    case ocean = "ocean"         // Cool blues and teals

    // PREMIUM (9)
    case forest = "forest"       // Rich greens
    case candy = "candy"         // Bold pinks and purples
    case midnight = "midnight"   // Premium dark mode
    case sunset = "sunset"       // Warm gradients
    case lavender = "lavender"   // Soft purples
    case mint = "mint"           // Fresh mint greens
    case coral = "coral"         // Warm coral tones
    case slate = "slate"         // Sophisticated grays
    case rainbow = "rainbow"     // Colorful celebration

    var id: String { rawValue }

    var isPremium: Bool {
        switch self {
        case .system, .gentle, .sunny, .ocean:
            return false
        default:
            return true
        }
    }

    /// Midnight is dark-only by design
    var isDarkOnly: Bool {
        self == .midnight
    }

    var displayName: String {
        switch self {
        case .system: return "Auto"
        case .gentle: return "Gentle"
        case .sunny: return "Sunny"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .candy: return "Candy"
        case .midnight: return "Midnight"
        case .sunset: return "Sunset"
        case .lavender: return "Lavender"
        case .mint: return "Mint Fresh"
        case .coral: return "Coral"
        case .slate: return "Slate"
        case .rainbow: return "Rainbow"
        }
    }

    /// Get the palette definition for this ID
    var palette: Palette {
        Palette.forId(self)
    }
}

// MARK: - Palette Color Set

/// A complete set of colors for one appearance mode (light or dark)
struct PaletteColorSet {
    // Surfaces
    let bg0: Color
    let bg1: Color
    let surface1: Color
    let surface2: Color
    let surface3: Color

    // Borders
    let borderSoft: Color
    let borderStrong: Color
    let separator: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textDisabled: Color

    // Accents
    let accentPrimary: Color
    let accentSecondary: Color
    let gradientColors: [Color]

    // Effects
    let shadowColor: Color
    let shadowStrength: CGFloat
    let cornerRadius: CGFloat
    let cardBorderWidth: CGFloat
}

// MARK: - Palette Definition

/// Complete palette definition with light and dark variants
struct Palette {
    let id: PaletteId
    let light: PaletteColorSet
    let dark: PaletteColorSet

    /// Whether this palette only works in dark mode
    var isDarkOnly: Bool {
        id.isDarkOnly
    }
}

// MARK: - Palette Factory

extension Palette {
    static func forId(_ id: PaletteId) -> Palette {
        switch id {
        case .system:
            return systemPalette
        case .gentle:
            return gentlePalette
        case .sunny:
            return sunnyPalette
        case .ocean:
            return oceanPalette
        case .forest:
            return forestPalette
        case .candy:
            return candyPalette
        case .midnight:
            return midnightPalette
        case .sunset:
            return sunsetPalette
        case .lavender:
            return lavenderPalette
        case .mint:
            return mintPalette
        case .coral:
            return coralPalette
        case .slate:
            return slatePalette
        case .rainbow:
            return rainbowPalette
        }
    }

    // MARK: - System (Auto) Palette

    private static let systemPalette = Palette(
        id: .system,
        light: PaletteColorSet(
            bg0: Color(red: 0.97, green: 0.96, blue: 0.98),
            bg1: Color(red: 0.94, green: 0.94, blue: 0.96),
            surface1: Color(red: 0.98, green: 0.98, blue: 0.99),
            surface2: Color(red: 0.99, green: 0.99, blue: 1.0),
            surface3: Color(red: 0.92, green: 0.94, blue: 0.98),
            borderSoft: Color(red: 0.88, green: 0.90, blue: 0.94).opacity(0.6),
            borderStrong: Color(red: 0.75, green: 0.78, blue: 0.85),
            separator: Color(red: 0.85, green: 0.87, blue: 0.90),
            textPrimary: Color(red: 0.15, green: 0.15, blue: 0.2),
            textSecondary: Color(red: 0.45, green: 0.45, blue: 0.5),
            textTertiary: Color(red: 0.6, green: 0.6, blue: 0.65),
            textDisabled: Color(red: 0.75, green: 0.75, blue: 0.78),
            accentPrimary: Color(red: 0.4, green: 0.6, blue: 0.9),
            accentSecondary: Color(red: 0.5, green: 0.7, blue: 0.85),
            gradientColors: [Color(red: 0.35, green: 0.55, blue: 0.85), Color(red: 0.45, green: 0.65, blue: 0.9)],
            shadowColor: .black,
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 0.5
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.07, green: 0.07, blue: 0.09),
            bg1: Color(red: 0.09, green: 0.09, blue: 0.11),
            surface1: Color(red: 0.11, green: 0.11, blue: 0.14),
            surface2: Color(red: 0.14, green: 0.14, blue: 0.18),
            surface3: Color(red: 0.17, green: 0.17, blue: 0.21),
            borderSoft: Color.white.opacity(0.08),
            borderStrong: Color.white.opacity(0.15),
            separator: Color.white.opacity(0.1),
            textPrimary: Color.white.opacity(0.92),
            textSecondary: Color.white.opacity(0.6),
            textTertiary: Color.white.opacity(0.4),
            textDisabled: Color.white.opacity(0.25),
            accentPrimary: Color(red: 0.45, green: 0.65, blue: 0.95),
            accentSecondary: Color(red: 0.55, green: 0.75, blue: 0.9),
            gradientColors: [Color(red: 0.4, green: 0.6, blue: 0.9), Color(red: 0.5, green: 0.7, blue: 0.95)],
            shadowColor: .black,
            shadowStrength: 0.3,
            cornerRadius: 16,
            cardBorderWidth: 1.0
        )
    )

    // MARK: - Gentle Palette

    private static let gentlePalette = Palette(
        id: .gentle,
        light: PaletteColorSet(
            bg0: Color(red: 0.97, green: 0.96, blue: 0.98),
            bg1: Color(red: 0.94, green: 0.94, blue: 0.97),
            surface1: Color(red: 0.95, green: 0.96, blue: 0.99),
            surface2: Color(red: 0.97, green: 0.98, blue: 1.0),
            surface3: Color(red: 0.90, green: 0.92, blue: 0.98),
            borderSoft: Color(red: 0.80, green: 0.85, blue: 0.92).opacity(0.5),
            borderStrong: Color(red: 0.70, green: 0.78, blue: 0.88),
            separator: Color(red: 0.85, green: 0.88, blue: 0.92),
            textPrimary: Color(red: 0.15, green: 0.15, blue: 0.2),
            textSecondary: Color(red: 0.45, green: 0.45, blue: 0.5),
            textTertiary: Color(red: 0.6, green: 0.6, blue: 0.65),
            textDisabled: Color(red: 0.75, green: 0.75, blue: 0.78),
            accentPrimary: Color(red: 0.65, green: 0.75, blue: 0.85),
            accentSecondary: Color(red: 0.85, green: 0.8, blue: 0.9),
            gradientColors: [Color(red: 0.6, green: 0.7, blue: 0.85), Color(red: 0.75, green: 0.7, blue: 0.85)],
            shadowColor: .black,
            shadowStrength: 0.06,
            cornerRadius: 20,
            cardBorderWidth: 0.5
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.08, green: 0.08, blue: 0.10),
            bg1: Color(red: 0.10, green: 0.10, blue: 0.12),
            surface1: Color(red: 0.12, green: 0.12, blue: 0.15),
            surface2: Color(red: 0.15, green: 0.15, blue: 0.18),
            surface3: Color(red: 0.18, green: 0.18, blue: 0.22),
            borderSoft: Color.white.opacity(0.08),
            borderStrong: Color.white.opacity(0.15),
            separator: Color.white.opacity(0.1),
            textPrimary: Color.white.opacity(0.90),
            textSecondary: Color.white.opacity(0.58),
            textTertiary: Color.white.opacity(0.38),
            textDisabled: Color.white.opacity(0.22),
            accentPrimary: Color(red: 0.72, green: 0.8, blue: 0.9),
            accentSecondary: Color(red: 0.88, green: 0.82, blue: 0.92),
            gradientColors: [Color(red: 0.65, green: 0.75, blue: 0.88), Color(red: 0.78, green: 0.72, blue: 0.88)],
            shadowColor: .black,
            shadowStrength: 0.25,
            cornerRadius: 20,
            cardBorderWidth: 1.0
        )
    )

    // MARK: - Sunny Palette

    private static let sunnyPalette = Palette(
        id: .sunny,
        light: PaletteColorSet(
            bg0: Color(red: 1.0, green: 0.98, blue: 0.94),
            bg1: Color(red: 0.98, green: 0.95, blue: 0.90),
            surface1: Color(red: 1.0, green: 0.96, blue: 0.88),
            surface2: Color(red: 1.0, green: 0.98, blue: 0.92),
            surface3: Color(red: 1.0, green: 0.90, blue: 0.78),
            borderSoft: Color(red: 1.0, green: 0.72, blue: 0.3).opacity(0.45),
            borderStrong: Color(red: 1.0, green: 0.65, blue: 0.25),
            separator: Color(red: 0.95, green: 0.88, blue: 0.78),
            textPrimary: Color(red: 0.2, green: 0.18, blue: 0.15),
            textSecondary: Color(red: 0.5, green: 0.45, blue: 0.4),
            textTertiary: Color(red: 0.65, green: 0.58, blue: 0.52),
            textDisabled: Color(red: 0.78, green: 0.72, blue: 0.68),
            accentPrimary: Color(red: 1.0, green: 0.72, blue: 0.3),
            accentSecondary: Color(red: 1.0, green: 0.55, blue: 0.4),
            gradientColors: [Color(red: 1.0, green: 0.65, blue: 0.3), Color(red: 1.0, green: 0.5, blue: 0.35)],
            shadowColor: Color(red: 0.5, green: 0.35, blue: 0.15),
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.10, green: 0.08, blue: 0.06),
            bg1: Color(red: 0.13, green: 0.10, blue: 0.08),
            surface1: Color(red: 0.16, green: 0.12, blue: 0.10),
            surface2: Color(red: 0.20, green: 0.15, blue: 0.12),
            surface3: Color(red: 0.24, green: 0.18, blue: 0.14),
            borderSoft: Color(red: 1.0, green: 0.72, blue: 0.3).opacity(0.25),
            borderStrong: Color(red: 1.0, green: 0.72, blue: 0.3).opacity(0.5),
            separator: Color(red: 1.0, green: 0.8, blue: 0.5).opacity(0.15),
            textPrimary: Color(red: 1.0, green: 0.96, blue: 0.90),
            textSecondary: Color(red: 0.85, green: 0.78, blue: 0.68),
            textTertiary: Color(red: 0.68, green: 0.60, blue: 0.52),
            textDisabled: Color(red: 0.48, green: 0.42, blue: 0.36),
            accentPrimary: Color(red: 1.0, green: 0.78, blue: 0.4),
            accentSecondary: Color(red: 1.0, green: 0.6, blue: 0.45),
            gradientColors: [Color(red: 1.0, green: 0.7, blue: 0.35), Color(red: 1.0, green: 0.55, blue: 0.4)],
            shadowColor: .black,
            shadowStrength: 0.35,
            cornerRadius: 16,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Ocean Palette

    private static let oceanPalette = Palette(
        id: .ocean,
        light: PaletteColorSet(
            bg0: Color(red: 0.94, green: 0.98, blue: 1.0),
            bg1: Color(red: 0.90, green: 0.95, blue: 0.98),
            surface1: Color(red: 0.92, green: 0.96, blue: 1.0),
            surface2: Color(red: 0.95, green: 0.98, blue: 1.0),
            surface3: Color(red: 0.85, green: 0.93, blue: 1.0),
            borderSoft: Color(red: 0.2, green: 0.6, blue: 0.8).opacity(0.50),
            borderStrong: Color(red: 0.2, green: 0.55, blue: 0.75),
            separator: Color(red: 0.78, green: 0.88, blue: 0.94),
            textPrimary: Color(red: 0.12, green: 0.18, blue: 0.22),
            textSecondary: Color(red: 0.35, green: 0.45, blue: 0.52),
            textTertiary: Color(red: 0.52, green: 0.60, blue: 0.65),
            textDisabled: Color(red: 0.70, green: 0.76, blue: 0.80),
            accentPrimary: Color(red: 0.2, green: 0.6, blue: 0.8),
            accentSecondary: Color(red: 0.4, green: 0.8, blue: 0.75),
            gradientColors: [Color(red: 0.2, green: 0.6, blue: 0.85), Color(red: 0.3, green: 0.75, blue: 0.8)],
            shadowColor: Color(red: 0.1, green: 0.3, blue: 0.5),
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.05, green: 0.08, blue: 0.10),
            bg1: Color(red: 0.07, green: 0.10, blue: 0.13),
            surface1: Color(red: 0.09, green: 0.13, blue: 0.17),
            surface2: Color(red: 0.12, green: 0.16, blue: 0.21),
            surface3: Color(red: 0.15, green: 0.20, blue: 0.26),
            borderSoft: Color(red: 0.3, green: 0.7, blue: 0.85).opacity(0.25),
            borderStrong: Color(red: 0.3, green: 0.7, blue: 0.85).opacity(0.5),
            separator: Color(red: 0.3, green: 0.6, blue: 0.75).opacity(0.2),
            textPrimary: Color(red: 0.92, green: 0.96, blue: 0.98),
            textSecondary: Color(red: 0.68, green: 0.78, blue: 0.85),
            textTertiary: Color(red: 0.48, green: 0.58, blue: 0.65),
            textDisabled: Color(red: 0.32, green: 0.40, blue: 0.46),
            accentPrimary: Color(red: 0.35, green: 0.72, blue: 0.9),
            accentSecondary: Color(red: 0.5, green: 0.85, blue: 0.82),
            gradientColors: [Color(red: 0.3, green: 0.68, blue: 0.88), Color(red: 0.4, green: 0.8, blue: 0.85)],
            shadowColor: .black,
            shadowStrength: 0.35,
            cornerRadius: 16,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Forest Palette

    private static let forestPalette = Palette(
        id: .forest,
        light: PaletteColorSet(
            bg0: Color(red: 0.96, green: 0.97, blue: 0.95),
            bg1: Color(red: 0.92, green: 0.94, blue: 0.91),
            surface1: Color(red: 0.93, green: 0.97, blue: 0.93),
            surface2: Color(red: 0.96, green: 0.98, blue: 0.95),
            surface3: Color(red: 0.86, green: 0.94, blue: 0.86),
            borderSoft: Color(red: 0.3, green: 0.6, blue: 0.4).opacity(0.50),
            borderStrong: Color(red: 0.25, green: 0.55, blue: 0.38),
            separator: Color(red: 0.78, green: 0.85, blue: 0.78),
            textPrimary: Color(red: 0.15, green: 0.18, blue: 0.15),
            textSecondary: Color(red: 0.38, green: 0.45, blue: 0.40),
            textTertiary: Color(red: 0.55, green: 0.60, blue: 0.55),
            textDisabled: Color(red: 0.72, green: 0.75, blue: 0.72),
            accentPrimary: Color(red: 0.3, green: 0.6, blue: 0.4),
            accentSecondary: Color(red: 0.55, green: 0.45, blue: 0.35),
            gradientColors: [Color(red: 0.25, green: 0.55, blue: 0.4), Color(red: 0.4, green: 0.65, blue: 0.45)],
            shadowColor: Color(red: 0.15, green: 0.25, blue: 0.15),
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.06, green: 0.08, blue: 0.06),
            bg1: Color(red: 0.08, green: 0.10, blue: 0.08),
            surface1: Color(red: 0.10, green: 0.14, blue: 0.11),
            surface2: Color(red: 0.13, green: 0.17, blue: 0.14),
            surface3: Color(red: 0.16, green: 0.21, blue: 0.17),
            borderSoft: Color(red: 0.4, green: 0.7, blue: 0.5).opacity(0.25),
            borderStrong: Color(red: 0.4, green: 0.7, blue: 0.5).opacity(0.5),
            separator: Color(red: 0.35, green: 0.55, blue: 0.4).opacity(0.2),
            textPrimary: Color(red: 0.92, green: 0.95, blue: 0.92),
            textSecondary: Color(red: 0.68, green: 0.75, blue: 0.70),
            textTertiary: Color(red: 0.48, green: 0.55, blue: 0.50),
            textDisabled: Color(red: 0.32, green: 0.38, blue: 0.34),
            accentPrimary: Color(red: 0.45, green: 0.72, blue: 0.52),
            accentSecondary: Color(red: 0.65, green: 0.55, blue: 0.45),
            gradientColors: [Color(red: 0.35, green: 0.62, blue: 0.45), Color(red: 0.5, green: 0.72, blue: 0.52)],
            shadowColor: .black,
            shadowStrength: 0.35,
            cornerRadius: 16,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Candy Palette

    private static let candyPalette = Palette(
        id: .candy,
        light: PaletteColorSet(
            bg0: Color(red: 1.0, green: 0.96, blue: 0.98),
            bg1: Color(red: 0.98, green: 0.92, blue: 0.95),
            surface1: Color(red: 1.0, green: 0.92, blue: 0.96),
            surface2: Color(red: 1.0, green: 0.95, blue: 0.97),
            surface3: Color(red: 1.0, green: 0.85, blue: 0.92),
            borderSoft: Color(red: 0.9, green: 0.35, blue: 0.6).opacity(0.50),
            borderStrong: Color(red: 0.85, green: 0.3, blue: 0.55),
            separator: Color(red: 0.95, green: 0.82, blue: 0.88),
            textPrimary: Color(red: 0.22, green: 0.15, blue: 0.18),
            textSecondary: Color(red: 0.52, green: 0.42, blue: 0.48),
            textTertiary: Color(red: 0.65, green: 0.55, blue: 0.60),
            textDisabled: Color(red: 0.78, green: 0.72, blue: 0.75),
            accentPrimary: Color(red: 0.9, green: 0.35, blue: 0.6),
            accentSecondary: Color(red: 0.6, green: 0.3, blue: 0.9),
            gradientColors: [Color(red: 0.9, green: 0.35, blue: 0.55), Color(red: 0.7, green: 0.3, blue: 0.85)],
            shadowColor: Color(red: 0.5, green: 0.1, blue: 0.3),
            shadowStrength: 0.12,
            cornerRadius: 24,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.10, green: 0.06, blue: 0.08),
            bg1: Color(red: 0.13, green: 0.08, blue: 0.10),
            surface1: Color(red: 0.16, green: 0.10, blue: 0.13),
            surface2: Color(red: 0.20, green: 0.13, blue: 0.16),
            surface3: Color(red: 0.25, green: 0.16, blue: 0.20),
            borderSoft: Color(red: 0.95, green: 0.45, blue: 0.65).opacity(0.3),
            borderStrong: Color(red: 0.95, green: 0.45, blue: 0.65).opacity(0.55),
            separator: Color(red: 0.85, green: 0.4, blue: 0.55).opacity(0.2),
            textPrimary: Color(red: 1.0, green: 0.94, blue: 0.96),
            textSecondary: Color(red: 0.85, green: 0.72, blue: 0.78),
            textTertiary: Color(red: 0.65, green: 0.52, blue: 0.58),
            textDisabled: Color(red: 0.45, green: 0.36, blue: 0.40),
            accentPrimary: Color(red: 0.95, green: 0.48, blue: 0.68),
            accentSecondary: Color(red: 0.7, green: 0.42, blue: 0.95),
            gradientColors: [Color(red: 0.92, green: 0.42, blue: 0.6), Color(red: 0.75, green: 0.38, blue: 0.88)],
            shadowColor: .black,
            shadowStrength: 0.35,
            cornerRadius: 24,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Midnight Palette (Dark Only)

    /// Midnight is a premium dark-only palette with carefully designed luminance hierarchy
    private static let midnightPalette = Palette(
        id: .midnight,
        light: PaletteColorSet(
            // Light mode not used for Midnight (dark-only theme)
            // Fallback values if accessed incorrectly
            bg0: Color(red: 0.08, green: 0.08, blue: 0.12),
            bg1: Color(red: 0.10, green: 0.10, blue: 0.14),
            surface1: Color(red: 0.12, green: 0.12, blue: 0.18),
            surface2: Color(red: 0.15, green: 0.15, blue: 0.22),
            surface3: Color(red: 0.18, green: 0.18, blue: 0.26),
            borderSoft: Color.white.opacity(0.12),
            borderStrong: Color.white.opacity(0.22),
            separator: Color.white.opacity(0.10),
            textPrimary: Color.white.opacity(0.95),
            textSecondary: Color.white.opacity(0.68),
            textTertiary: Color.white.opacity(0.45),
            textDisabled: Color.white.opacity(0.28),
            accentPrimary: Color(red: 0.55, green: 0.45, blue: 0.95),
            accentSecondary: Color(red: 0.4, green: 0.75, blue: 0.95),
            gradientColors: [Color(red: 0.5, green: 0.4, blue: 0.9), Color(red: 0.6, green: 0.5, blue: 0.98)],
            shadowColor: .black,
            shadowStrength: 0.4,
            cornerRadius: 12,
            cardBorderWidth: 1.0
        ),
        dark: PaletteColorSet(
            // Carefully designed luminance hierarchy:
            // bg0 (7.8%) < bg1 (10%) < surface1 (12.5%) < surface2 (15.8%) < surface3 (19%)
            bg0: Color(red: 0.078, green: 0.078, blue: 0.118),          // ~7.8% luminance
            bg1: Color(red: 0.10, green: 0.10, blue: 0.14),              // ~10% luminance
            surface1: Color(red: 0.125, green: 0.125, blue: 0.178),      // ~12.5% luminance
            surface2: Color(red: 0.158, green: 0.158, blue: 0.218),      // ~15.8% luminance
            surface3: Color(red: 0.19, green: 0.19, blue: 0.26),         // ~19% luminance
            borderSoft: Color.white.opacity(0.12),
            borderStrong: Color(red: 0.55, green: 0.45, blue: 0.95).opacity(0.5),
            separator: Color.white.opacity(0.10),
            // Text with proper contrast hierarchy (WCAG AA compliant)
            textPrimary: Color(red: 0.95, green: 0.94, blue: 0.98),      // ~93% luminance (contrast 11.5:1)
            textSecondary: Color(red: 0.72, green: 0.70, blue: 0.78),    // ~68% luminance (contrast 5.2:1)
            textTertiary: Color(red: 0.52, green: 0.50, blue: 0.58),     // ~48% luminance (contrast 3.5:1 - large text)
            textDisabled: Color(red: 0.38, green: 0.36, blue: 0.42),     // ~35% luminance
            // Premium purple accents (calm, not neon)
            accentPrimary: Color(red: 0.58, green: 0.48, blue: 0.92),    // Calm purple
            accentSecondary: Color(red: 0.42, green: 0.72, blue: 0.92), // Cyan accent
            gradientColors: [Color(red: 0.52, green: 0.42, blue: 0.88), Color(red: 0.62, green: 0.52, blue: 0.96)],
            shadowColor: .black,
            shadowStrength: 0.5,                                         // Strong shadows for depth
            cornerRadius: 12,                                            // Sharp, modern
            cardBorderWidth: 1.0
        )
    )

    // MARK: - Sunset Palette

    private static let sunsetPalette = Palette(
        id: .sunset,
        light: PaletteColorSet(
            bg0: Color(red: 1.0, green: 0.97, blue: 0.95),
            bg1: Color(red: 0.98, green: 0.94, blue: 0.90),
            surface1: Color(red: 1.0, green: 0.94, blue: 0.90),
            surface2: Color(red: 1.0, green: 0.96, blue: 0.92),
            surface3: Color(red: 1.0, green: 0.88, blue: 0.82),
            borderSoft: Color(red: 1.0, green: 0.5, blue: 0.3).opacity(0.50),
            borderStrong: Color(red: 1.0, green: 0.45, blue: 0.28),
            separator: Color(red: 0.95, green: 0.85, blue: 0.80),
            textPrimary: Color(red: 0.22, green: 0.16, blue: 0.14),
            textSecondary: Color(red: 0.52, green: 0.42, blue: 0.38),
            textTertiary: Color(red: 0.65, green: 0.55, blue: 0.52),
            textDisabled: Color(red: 0.78, green: 0.72, blue: 0.70),
            accentPrimary: Color(red: 1.0, green: 0.5, blue: 0.3),
            accentSecondary: Color(red: 1.0, green: 0.35, blue: 0.5),
            gradientColors: [Color(red: 1.0, green: 0.55, blue: 0.3), Color(red: 1.0, green: 0.35, blue: 0.45)],
            shadowColor: Color(red: 0.5, green: 0.2, blue: 0.1),
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.10, green: 0.07, blue: 0.06),
            bg1: Color(red: 0.13, green: 0.09, blue: 0.08),
            surface1: Color(red: 0.17, green: 0.11, blue: 0.10),
            surface2: Color(red: 0.21, green: 0.14, blue: 0.12),
            surface3: Color(red: 0.26, green: 0.17, blue: 0.15),
            borderSoft: Color(red: 1.0, green: 0.55, blue: 0.35).opacity(0.3),
            borderStrong: Color(red: 1.0, green: 0.55, blue: 0.35).opacity(0.55),
            separator: Color(red: 1.0, green: 0.5, blue: 0.35).opacity(0.18),
            textPrimary: Color(red: 1.0, green: 0.96, blue: 0.94),
            textSecondary: Color(red: 0.88, green: 0.75, blue: 0.70),
            textTertiary: Color(red: 0.68, green: 0.55, blue: 0.50),
            textDisabled: Color(red: 0.48, green: 0.38, blue: 0.35),
            accentPrimary: Color(red: 1.0, green: 0.58, blue: 0.38),
            accentSecondary: Color(red: 1.0, green: 0.42, blue: 0.55),
            gradientColors: [Color(red: 1.0, green: 0.6, blue: 0.35), Color(red: 1.0, green: 0.42, blue: 0.5)],
            shadowColor: .black,
            shadowStrength: 0.4,
            cornerRadius: 16,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Lavender Palette

    private static let lavenderPalette = Palette(
        id: .lavender,
        light: PaletteColorSet(
            bg0: Color(red: 0.98, green: 0.96, blue: 1.0),
            bg1: Color(red: 0.95, green: 0.92, blue: 0.98),
            surface1: Color(red: 0.96, green: 0.93, blue: 1.0),
            surface2: Color(red: 0.98, green: 0.95, blue: 1.0),
            surface3: Color(red: 0.92, green: 0.86, blue: 1.0),
            borderSoft: Color(red: 0.7, green: 0.55, blue: 0.85).opacity(0.50),
            borderStrong: Color(red: 0.65, green: 0.48, blue: 0.8),
            separator: Color(red: 0.88, green: 0.82, blue: 0.92),
            textPrimary: Color(red: 0.18, green: 0.15, blue: 0.22),
            textSecondary: Color(red: 0.48, green: 0.42, blue: 0.55),
            textTertiary: Color(red: 0.62, green: 0.55, blue: 0.68),
            textDisabled: Color(red: 0.75, green: 0.72, blue: 0.80),
            accentPrimary: Color(red: 0.7, green: 0.55, blue: 0.85),
            accentSecondary: Color(red: 0.55, green: 0.75, blue: 0.9),
            gradientColors: [Color(red: 0.65, green: 0.5, blue: 0.85), Color(red: 0.8, green: 0.55, blue: 0.85)],
            shadowColor: Color(red: 0.35, green: 0.25, blue: 0.45),
            shadowStrength: 0.06,
            cornerRadius: 20,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.08, green: 0.07, blue: 0.10),
            bg1: Color(red: 0.10, green: 0.09, blue: 0.13),
            surface1: Color(red: 0.13, green: 0.11, blue: 0.17),
            surface2: Color(red: 0.16, green: 0.14, blue: 0.21),
            surface3: Color(red: 0.20, green: 0.17, blue: 0.26),
            borderSoft: Color(red: 0.78, green: 0.62, blue: 0.92).opacity(0.28),
            borderStrong: Color(red: 0.78, green: 0.62, blue: 0.92).opacity(0.5),
            separator: Color(red: 0.72, green: 0.58, blue: 0.85).opacity(0.18),
            textPrimary: Color(red: 0.96, green: 0.94, blue: 0.98),
            textSecondary: Color(red: 0.78, green: 0.72, blue: 0.85),
            textTertiary: Color(red: 0.58, green: 0.52, blue: 0.65),
            textDisabled: Color(red: 0.42, green: 0.38, blue: 0.48),
            accentPrimary: Color(red: 0.78, green: 0.62, blue: 0.92),
            accentSecondary: Color(red: 0.62, green: 0.8, blue: 0.95),
            gradientColors: [Color(red: 0.72, green: 0.55, blue: 0.88), Color(red: 0.85, green: 0.6, blue: 0.88)],
            shadowColor: .black,
            shadowStrength: 0.32,
            cornerRadius: 20,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Mint Palette

    private static let mintPalette = Palette(
        id: .mint,
        light: PaletteColorSet(
            bg0: Color(red: 0.95, green: 0.99, blue: 0.98),
            bg1: Color(red: 0.91, green: 0.96, blue: 0.95),
            surface1: Color(red: 0.91, green: 0.98, blue: 0.95),
            surface2: Color(red: 0.94, green: 0.99, blue: 0.96),
            surface3: Color(red: 0.82, green: 0.96, blue: 0.90),
            borderSoft: Color(red: 0.3, green: 0.8, blue: 0.7).opacity(0.50),
            borderStrong: Color(red: 0.25, green: 0.72, blue: 0.62),
            separator: Color(red: 0.78, green: 0.90, blue: 0.86),
            textPrimary: Color(red: 0.12, green: 0.18, blue: 0.16),
            textSecondary: Color(red: 0.35, green: 0.48, blue: 0.44),
            textTertiary: Color(red: 0.52, green: 0.62, blue: 0.58),
            textDisabled: Color(red: 0.70, green: 0.78, blue: 0.75),
            accentPrimary: Color(red: 0.3, green: 0.8, blue: 0.7),
            accentSecondary: Color(red: 0.5, green: 0.85, blue: 0.5),
            gradientColors: [Color(red: 0.25, green: 0.75, blue: 0.65), Color(red: 0.35, green: 0.8, blue: 0.7)],
            shadowColor: Color(red: 0.15, green: 0.35, blue: 0.30),
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.05, green: 0.08, blue: 0.07),
            bg1: Color(red: 0.07, green: 0.10, blue: 0.09),
            surface1: Color(red: 0.09, green: 0.14, blue: 0.12),
            surface2: Color(red: 0.12, green: 0.17, blue: 0.15),
            surface3: Color(red: 0.15, green: 0.21, blue: 0.18),
            borderSoft: Color(red: 0.4, green: 0.85, blue: 0.75).opacity(0.28),
            borderStrong: Color(red: 0.4, green: 0.85, blue: 0.75).opacity(0.5),
            separator: Color(red: 0.35, green: 0.75, blue: 0.65).opacity(0.18),
            textPrimary: Color(red: 0.92, green: 0.98, blue: 0.96),
            textSecondary: Color(red: 0.68, green: 0.82, blue: 0.78),
            textTertiary: Color(red: 0.48, green: 0.60, blue: 0.56),
            textDisabled: Color(red: 0.32, green: 0.42, blue: 0.38),
            accentPrimary: Color(red: 0.42, green: 0.88, blue: 0.78),
            accentSecondary: Color(red: 0.58, green: 0.9, blue: 0.58),
            gradientColors: [Color(red: 0.35, green: 0.82, blue: 0.72), Color(red: 0.45, green: 0.85, blue: 0.75)],
            shadowColor: .black,
            shadowStrength: 0.35,
            cornerRadius: 16,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Coral Palette

    private static let coralPalette = Palette(
        id: .coral,
        light: PaletteColorSet(
            bg0: Color(red: 1.0, green: 0.97, blue: 0.96),
            bg1: Color(red: 0.98, green: 0.94, blue: 0.92),
            surface1: Color(red: 1.0, green: 0.94, blue: 0.92),
            surface2: Color(red: 1.0, green: 0.96, blue: 0.94),
            surface3: Color(red: 1.0, green: 0.88, blue: 0.85),
            borderSoft: Color(red: 1.0, green: 0.5, blue: 0.45).opacity(0.50),
            borderStrong: Color(red: 0.95, green: 0.45, blue: 0.40),
            separator: Color(red: 0.95, green: 0.86, blue: 0.84),
            textPrimary: Color(red: 0.22, green: 0.16, blue: 0.15),
            textSecondary: Color(red: 0.52, green: 0.42, blue: 0.40),
            textTertiary: Color(red: 0.65, green: 0.56, blue: 0.54),
            textDisabled: Color(red: 0.78, green: 0.72, blue: 0.70),
            accentPrimary: Color(red: 1.0, green: 0.5, blue: 0.45),
            accentSecondary: Color(red: 1.0, green: 0.7, blue: 0.5),
            gradientColors: [Color(red: 1.0, green: 0.5, blue: 0.45), Color(red: 1.0, green: 0.6, blue: 0.5)],
            shadowColor: Color(red: 0.45, green: 0.22, blue: 0.18),
            shadowStrength: 0.1,
            cornerRadius: 16,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.10, green: 0.07, blue: 0.07),
            bg1: Color(red: 0.13, green: 0.09, blue: 0.09),
            surface1: Color(red: 0.17, green: 0.11, blue: 0.11),
            surface2: Color(red: 0.21, green: 0.14, blue: 0.13),
            surface3: Color(red: 0.26, green: 0.17, blue: 0.16),
            borderSoft: Color(red: 1.0, green: 0.58, blue: 0.52).opacity(0.3),
            borderStrong: Color(red: 1.0, green: 0.58, blue: 0.52).opacity(0.55),
            separator: Color(red: 1.0, green: 0.5, blue: 0.45).opacity(0.18),
            textPrimary: Color(red: 1.0, green: 0.96, blue: 0.95),
            textSecondary: Color(red: 0.88, green: 0.75, blue: 0.72),
            textTertiary: Color(red: 0.68, green: 0.55, blue: 0.52),
            textDisabled: Color(red: 0.48, green: 0.38, blue: 0.36),
            accentPrimary: Color(red: 1.0, green: 0.58, blue: 0.52),
            accentSecondary: Color(red: 1.0, green: 0.75, blue: 0.58),
            gradientColors: [Color(red: 1.0, green: 0.55, blue: 0.5), Color(red: 1.0, green: 0.65, blue: 0.55)],
            shadowColor: .black,
            shadowStrength: 0.38,
            cornerRadius: 16,
            cardBorderWidth: 1.5
        )
    )

    // MARK: - Slate Palette

    private static let slatePalette = Palette(
        id: .slate,
        light: PaletteColorSet(
            bg0: Color(red: 0.96, green: 0.97, blue: 0.97),
            bg1: Color(red: 0.92, green: 0.93, blue: 0.94),
            surface1: Color(red: 0.95, green: 0.96, blue: 0.97),
            surface2: Color(red: 0.97, green: 0.98, blue: 0.98),
            surface3: Color(red: 0.90, green: 0.91, blue: 0.94),
            borderSoft: Color(red: 0.82, green: 0.84, blue: 0.86),
            borderStrong: Color(red: 0.68, green: 0.72, blue: 0.76),
            separator: Color(red: 0.85, green: 0.87, blue: 0.88),
            textPrimary: Color(red: 0.15, green: 0.17, blue: 0.18),
            textSecondary: Color(red: 0.42, green: 0.46, blue: 0.50),
            textTertiary: Color(red: 0.58, green: 0.62, blue: 0.65),
            textDisabled: Color(red: 0.74, green: 0.77, blue: 0.78),
            accentPrimary: Color(red: 0.45, green: 0.5, blue: 0.55),
            accentSecondary: Color(red: 0.35, green: 0.55, blue: 0.7),
            gradientColors: [Color(red: 0.4, green: 0.45, blue: 0.55), Color(red: 0.5, green: 0.55, blue: 0.65)],
            shadowColor: .black,
            shadowStrength: 0.08,
            cornerRadius: 12,
            cardBorderWidth: 1.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.08, green: 0.09, blue: 0.10),
            bg1: Color(red: 0.10, green: 0.11, blue: 0.12),
            surface1: Color(red: 0.13, green: 0.14, blue: 0.16),
            surface2: Color(red: 0.16, green: 0.18, blue: 0.20),
            surface3: Color(red: 0.20, green: 0.22, blue: 0.24),
            borderSoft: Color.white.opacity(0.1),
            borderStrong: Color.white.opacity(0.2),
            separator: Color.white.opacity(0.08),
            textPrimary: Color(red: 0.92, green: 0.93, blue: 0.94),
            textSecondary: Color(red: 0.70, green: 0.72, blue: 0.75),
            textTertiary: Color(red: 0.50, green: 0.52, blue: 0.55),
            textDisabled: Color(red: 0.35, green: 0.37, blue: 0.40),
            accentPrimary: Color(red: 0.58, green: 0.62, blue: 0.68),
            accentSecondary: Color(red: 0.48, green: 0.65, blue: 0.78),
            gradientColors: [Color(red: 0.52, green: 0.56, blue: 0.62), Color(red: 0.6, green: 0.64, blue: 0.70)],
            shadowColor: .black,
            shadowStrength: 0.3,
            cornerRadius: 12,
            cardBorderWidth: 1.0
        )
    )

    // MARK: - Rainbow Palette

    private static let rainbowPalette = Palette(
        id: .rainbow,
        light: PaletteColorSet(
            bg0: Color(red: 0.99, green: 0.98, blue: 0.99),
            bg1: Color(red: 0.96, green: 0.95, blue: 0.97),
            surface1: Color(red: 0.98, green: 0.94, blue: 0.98),
            surface2: Color(red: 0.99, green: 0.96, blue: 0.99),
            surface3: Color(red: 0.95, green: 0.90, blue: 0.96),
            borderSoft: Color(red: 0.9, green: 0.4, blue: 0.5).opacity(0.50),
            borderStrong: Color(red: 0.85, green: 0.35, blue: 0.48),
            separator: Color(red: 0.92, green: 0.88, blue: 0.92),
            textPrimary: Color(red: 0.18, green: 0.15, blue: 0.20),
            textSecondary: Color(red: 0.48, green: 0.44, blue: 0.52),
            textTertiary: Color(red: 0.62, green: 0.58, blue: 0.65),
            textDisabled: Color(red: 0.76, green: 0.74, blue: 0.78),
            accentPrimary: Color(red: 0.9, green: 0.4, blue: 0.5),
            accentSecondary: Color(red: 0.4, green: 0.7, blue: 0.9),
            gradientColors: [Color(red: 0.9, green: 0.4, blue: 0.5), Color(red: 0.5, green: 0.4, blue: 0.9)],
            shadowColor: Color(red: 0.4, green: 0.2, blue: 0.4),
            shadowStrength: 0.12,
            cornerRadius: 24,
            cardBorderWidth: 2.0
        ),
        dark: PaletteColorSet(
            bg0: Color(red: 0.09, green: 0.08, blue: 0.10),
            bg1: Color(red: 0.11, green: 0.10, blue: 0.13),
            surface1: Color(red: 0.14, green: 0.12, blue: 0.17),
            surface2: Color(red: 0.18, green: 0.15, blue: 0.21),
            surface3: Color(red: 0.22, green: 0.18, blue: 0.26),
            borderSoft: Color(red: 0.95, green: 0.5, blue: 0.58).opacity(0.3),
            borderStrong: Color(red: 0.95, green: 0.5, blue: 0.58).opacity(0.55),
            separator: Color(red: 0.85, green: 0.45, blue: 0.52).opacity(0.18),
            textPrimary: Color(red: 0.98, green: 0.96, blue: 0.98),
            textSecondary: Color(red: 0.82, green: 0.78, blue: 0.85),
            textTertiary: Color(red: 0.62, green: 0.58, blue: 0.65),
            textDisabled: Color(red: 0.42, green: 0.40, blue: 0.45),
            accentPrimary: Color(red: 0.95, green: 0.5, blue: 0.58),
            accentSecondary: Color(red: 0.5, green: 0.78, blue: 0.95),
            gradientColors: [Color(red: 0.92, green: 0.45, blue: 0.55), Color(red: 0.58, green: 0.48, blue: 0.92)],
            shadowColor: .black,
            shadowStrength: 0.35,
            cornerRadius: 24,
            cardBorderWidth: 1.5
        )
    )
}
