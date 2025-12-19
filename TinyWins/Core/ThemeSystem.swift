import SwiftUI

// MARK: - App Theme (Expanded with Premium + System Support)

/// Complete theme system with dramatically different visual styles.
/// Each theme provides a unique, noticeable experience.
/// The "system" theme automatically follows iOS dark/light mode.
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    // SPECIAL: System theme (follows iOS dark/light mode)
    case system = "system"           // Follows iOS settings - recommended default

    // FREE THEMES (3 light themes)
    case gentle = "gentle"           // Soft, calming pastels - great for bedtime logging
    case sunny = "sunny"             // Warm, cheerful yellows and oranges - energizing
    case ocean = "ocean"             // Cool blues and teals - fresh and clean

    // PREMIUM THEMES (9)
    case forest = "forest"           // Rich greens and earth tones - nature-inspired
    case candy = "candy"             // Bold pinks and purples - fun and playful
    case midnight = "midnight"       // Premium dark mode with purple accents - sleek
    case sunset = "sunset"           // Warm gradients - orange to pink
    case lavender = "lavender"       // Soft purples and pinks - dreamy
    case mint = "mint"               // Fresh mint greens - clean and modern
    case coral = "coral"             // Warm coral and peach tones - friendly
    case slate = "slate"             // Sophisticated grays - minimalist
    case rainbow = "rainbow"         // Colorful, uses all colors - celebratory

    var id: String { rawValue }

    /// Whether this theme requires Plus subscription
    var isPremium: Bool {
        switch self {
        case .system, .gentle, .sunny, .ocean:
            return false
        default:
            return true
        }
    }

    /// Whether this is a dark theme
    var isDarkTheme: Bool {
        self == .midnight
    }

    /// Whether this theme follows system color scheme
    var isSystemTheme: Bool {
        self == .system
    }

    /// Whether this theme is new (recently added)
    var isNew: Bool {
        switch self {
        case .coral, .rainbow:
            return true
        default:
            return false
        }
    }

    /// Whether this theme is popular with users
    var isPopular: Bool {
        switch self {
        case .midnight, .forest, .lavender:
            return true
        default:
            return false
        }
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

    var description: String {
        switch self {
        case .system: return "Follows iOS settings"
        case .gentle: return "Soft and calming"
        case .sunny: return "Warm and cheerful"
        case .ocean: return "Cool and refreshing"
        case .forest: return "Natural and grounded"
        case .candy: return "Fun and playful"
        case .midnight: return "Premium dark mode"
        case .sunset: return "Warm golden hour"
        case .lavender: return "Soft and dreamy"
        case .mint: return "Fresh and clean"
        case .coral: return "Warm and friendly"
        case .slate: return "Modern minimalist"
        case .rainbow: return "Colorful celebration"
        }
    }

    /// Free themes come first (with system at top), then premium
    static var sortedCases: [AppTheme] {
        let system: [AppTheme] = [.system]
        let freeLight = allCases.filter { !$0.isPremium && !$0.isSystemTheme }
        let premium = allCases.filter { $0.isPremium }
        return system + freeLight + premium
    }

    /// Themes excluding system (for when we need actual theme values)
    static var concreteThemes: [AppTheme] {
        allCases.filter { !$0.isSystemTheme }
    }
}

// MARK: - Resolved Theme (concrete colors based on color scheme)

/// A resolved theme that provides actual colors based on the selected theme and system color scheme.
/// Use this when you need concrete color values.
struct ResolvedTheme {
    let baseTheme: AppTheme
    let colorScheme: ColorScheme

    /// The effective theme to use for colors (resolves .system to actual theme)
    /// For system dark, we use .gentle as base but override colors in ResolvedTheme
    var effectiveTheme: AppTheme {
        if baseTheme == .system {
            return .gentle // Base theme for system mode (colors overridden below for dark)
        }
        return baseTheme
    }

    // MARK: - Primary Colors

    var primaryColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            // System dark uses a neutral blue accent
            return Color(red: 0.4, green: 0.6, blue: 0.9)
        }
        return effectiveTheme.primaryColor
    }

    var secondaryColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color(red: 0.5, green: 0.7, blue: 0.85)
        }
        return effectiveTheme.secondaryColor
    }

    /// Color for text/icons on primary color backgrounds - guarantees contrast
    var onPrimaryColor: Color {
        // White provides best contrast on all theme primary colors
        // (purple, blue, green, orange, pink variants are all saturated enough)
        return .white
    }

    // MARK: - Background Colors

    var backgroundColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            // Pure dark background for system dark
            return Color(red: 0.07, green: 0.07, blue: 0.09)
        }
        return effectiveTheme.backgroundColor
    }

    var cardBackground: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color(red: 0.11, green: 0.11, blue: 0.14)
        }
        return effectiveTheme.cardBackground
    }

    var cardBackgroundTinted: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color(red: 0.14, green: 0.14, blue: 0.18)
        }
        return effectiveTheme.cardBackgroundTinted
    }

    // MARK: - Text Colors

    var primaryTextColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color.white.opacity(0.92)
        }
        return effectiveTheme.primaryTextColor
    }

    var secondaryTextColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color.white.opacity(0.6)
        }
        return effectiveTheme.secondaryTextColor
    }

    // MARK: - Button Gradients

    var buttonGradient: [Color] {
        if baseTheme == .system && colorScheme == .dark {
            return [Color(red: 0.35, green: 0.55, blue: 0.85), Color(red: 0.45, green: 0.65, blue: 0.9)]
        }
        return effectiveTheme.buttonGradient
    }

    // MARK: - Semantic Colors

    var positiveColor: Color {
        if colorScheme == .dark || effectiveTheme.isDarkTheme {
            // Brighter green for dark backgrounds
            return Color(red: 0.35, green: 0.85, blue: 0.5)
        }
        return effectiveTheme.positiveColor
    }

    var warningColor: Color {
        if colorScheme == .dark || effectiveTheme.isDarkTheme {
            return Color(red: 1.0, green: 0.6, blue: 0.35)
        }
        return effectiveTheme.warningColor
    }

    var starColor: Color {
        if colorScheme == .dark || effectiveTheme.isDarkTheme {
            return Color(red: 1.0, green: 0.85, blue: 0.3)
        }
        return effectiveTheme.starColor
    }

    // MARK: - Visual Style Properties

    var cornerRadius: CGFloat {
        if baseTheme == .system {
            return 16 // Standard for system theme
        }
        return effectiveTheme.cornerRadius
    }

    var shadowIntensity: CGFloat {
        if baseTheme == .system && colorScheme == .dark {
            return 0.3
        }
        return effectiveTheme.shadowIntensity
    }

    var shadowColor: Color {
        if colorScheme == .dark || effectiveTheme.isDarkTheme {
            return Color.black
        }
        return effectiveTheme.shadowColor
    }

    var cardBorderWidth: CGFloat {
        if baseTheme == .system && colorScheme == .dark {
            return 1
        }
        return effectiveTheme.cardBorderWidth
    }

    var cardBorderColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color.white.opacity(0.08)
        }
        return effectiveTheme.cardBorderColor
    }

    var usesGradients: Bool {
        effectiveTheme.usesGradients
    }

    var cardAccentColor: Color {
        if baseTheme == .system && colorScheme == .dark {
            return Color(red: 0.4, green: 0.6, blue: 0.9)
        }
        return effectiveTheme.cardAccentColor
    }

    // MARK: - Preview Gradients

    var previewGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var previewBackgroundGradient: LinearGradient {
        if baseTheme == .system && colorScheme == .dark {
            return LinearGradient(
                colors: [backgroundColor, Color(red: 0.09, green: 0.09, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return effectiveTheme.previewBackgroundGradient
    }

    /// Whether the current resolved theme is dark
    var isDark: Bool {
        (baseTheme == .system && colorScheme == .dark) || effectiveTheme.isDarkTheme
    }
}

// MARK: - AppTheme Color Properties (for non-system themes)

extension AppTheme {
    // MARK: - Primary Colors

    /// Main accent/brand color for the theme
    var primaryColor: Color {
        switch self {
        case .system: return Color(red: 0.4, green: 0.6, blue: 0.9)  // Default blue (will be resolved)
        case .gentle: return Color(red: 0.65, green: 0.75, blue: 0.85)  // Soft blue-gray
        case .sunny: return Color(red: 1.0, green: 0.72, blue: 0.3)     // Warm golden
        case .ocean: return Color(red: 0.2, green: 0.6, blue: 0.8)      // Ocean blue
        case .forest: return Color(red: 0.3, green: 0.6, blue: 0.4)     // Forest green
        case .candy: return Color(red: 0.9, green: 0.35, blue: 0.6)     // Hot pink
        case .midnight: return Color(red: 0.5, green: 0.4, blue: 0.9)   // Purple
        case .sunset: return Color(red: 1.0, green: 0.5, blue: 0.3)     // Sunset orange
        case .lavender: return Color(red: 0.7, green: 0.55, blue: 0.85) // Lavender
        case .mint: return Color(red: 0.3, green: 0.8, blue: 0.7)       // Mint
        case .coral: return Color(red: 1.0, green: 0.5, blue: 0.45)     // Coral
        case .slate: return Color(red: 0.45, green: 0.5, blue: 0.55)    // Slate gray
        case .rainbow: return Color(red: 0.9, green: 0.4, blue: 0.5)    // Rainbow pink
        }
    }

    /// Secondary accent color
    var secondaryColor: Color {
        switch self {
        case .system: return Color(red: 0.5, green: 0.7, blue: 0.85)
        case .gentle: return Color(red: 0.85, green: 0.8, blue: 0.9)    // Soft lilac
        case .sunny: return Color(red: 1.0, green: 0.55, blue: 0.4)     // Coral accent
        case .ocean: return Color(red: 0.4, green: 0.8, blue: 0.75)     // Teal
        case .forest: return Color(red: 0.55, green: 0.45, blue: 0.35)  // Earth brown
        case .candy: return Color(red: 0.6, green: 0.3, blue: 0.9)      // Purple
        case .midnight: return Color(red: 0.3, green: 0.7, blue: 0.9)   // Cyan
        case .sunset: return Color(red: 1.0, green: 0.35, blue: 0.5)    // Pink
        case .lavender: return Color(red: 0.55, green: 0.75, blue: 0.9) // Sky blue
        case .mint: return Color(red: 0.5, green: 0.85, blue: 0.5)      // Light green
        case .coral: return Color(red: 1.0, green: 0.7, blue: 0.5)      // Peach
        case .slate: return Color(red: 0.35, green: 0.55, blue: 0.7)    // Steel blue
        case .rainbow: return Color(red: 0.4, green: 0.7, blue: 0.9)    // Sky blue
        }
    }

    // MARK: - Background Colors

    /// Main background color
    var backgroundColor: Color {
        switch self {
        case .system: return Color(red: 0.97, green: 0.96, blue: 0.98)  // Light default
        case .gentle: return Color(red: 0.97, green: 0.96, blue: 0.98)  // Warm white
        case .sunny: return Color(red: 1.0, green: 0.98, blue: 0.94)    // Cream
        case .ocean: return Color(red: 0.94, green: 0.98, blue: 1.0)    // Ice blue
        case .forest: return Color(red: 0.96, green: 0.97, blue: 0.95)  // Sage white
        case .candy: return Color(red: 1.0, green: 0.96, blue: 0.98)    // Pink white
        case .midnight: return Color(red: 0.078, green: 0.078, blue: 0.118) // Dark - improved luminance hierarchy
        case .sunset: return Color(red: 1.0, green: 0.97, blue: 0.95)   // Warm white
        case .lavender: return Color(red: 0.98, green: 0.96, blue: 1.0) // Lavender white
        case .mint: return Color(red: 0.95, green: 0.99, blue: 0.98)    // Mint white
        case .coral: return Color(red: 1.0, green: 0.97, blue: 0.96)    // Coral white
        case .slate: return Color(red: 0.96, green: 0.97, blue: 0.97)   // Cool gray
        case .rainbow: return Color(red: 0.99, green: 0.98, blue: 0.99) // Subtle pink
        }
    }

    /// Card/surface background color - DRAMATICALLY themed for visibility
    /// Users should instantly recognize which theme is active from card colors
    var cardBackground: Color {
        switch self {
        case .system: return Color(red: 0.98, green: 0.98, blue: 0.99)   // Neutral white
        case .gentle: return Color(red: 0.95, green: 0.96, blue: 0.99)   // Soft blue-white
        case .sunny: return Color(red: 1.0, green: 0.96, blue: 0.88)     // Warm cream - VISIBLE
        case .ocean: return Color(red: 0.92, green: 0.96, blue: 1.0)     // Cool ice blue - VISIBLE
        case .forest: return Color(red: 0.93, green: 0.97, blue: 0.93)   // Sage tint - VISIBLE
        case .candy: return Color(red: 1.0, green: 0.92, blue: 0.96)     // Pink tint - VISIBLE!
        case .midnight: return Color(red: 0.125, green: 0.125, blue: 0.178) // Dark card - improved contrast with bg
        case .sunset: return Color(red: 1.0, green: 0.94, blue: 0.90)    // Warm peach - VISIBLE
        case .lavender: return Color(red: 0.96, green: 0.93, blue: 1.0)  // Lavender - VISIBLE
        case .mint: return Color(red: 0.91, green: 0.98, blue: 0.95)     // Mint - VISIBLE
        case .coral: return Color(red: 1.0, green: 0.94, blue: 0.92)     // Coral - VISIBLE
        case .slate: return Color(red: 0.95, green: 0.96, blue: 0.97)    // Cool gray
        case .rainbow: return Color(red: 0.98, green: 0.94, blue: 0.98)  // Subtle pink-purple
        }
    }

    /// Card background with stronger theme tint for selected/highlighted states
    var cardBackgroundTinted: Color {
        switch self {
        case .system: return Color(red: 0.92, green: 0.94, blue: 0.98)   // More blue
        case .gentle: return Color(red: 0.90, green: 0.92, blue: 0.98)   // Deeper blue-gray
        case .sunny: return Color(red: 1.0, green: 0.90, blue: 0.78)     // Rich gold
        case .ocean: return Color(red: 0.85, green: 0.93, blue: 1.0)     // Deep ocean
        case .forest: return Color(red: 0.86, green: 0.94, blue: 0.86)   // Rich green
        case .candy: return Color(red: 1.0, green: 0.85, blue: 0.92)     // Strong pink!
        case .midnight: return Color(red: 0.158, green: 0.158, blue: 0.218) // Highlighted dark - improved hierarchy
        case .sunset: return Color(red: 1.0, green: 0.88, blue: 0.82)    // Rich sunset
        case .lavender: return Color(red: 0.92, green: 0.86, blue: 1.0)  // Deep lavender
        case .mint: return Color(red: 0.82, green: 0.96, blue: 0.90)     // Strong mint
        case .coral: return Color(red: 1.0, green: 0.88, blue: 0.85)     // Rich coral
        case .slate: return Color(red: 0.90, green: 0.91, blue: 0.94)    // Cooler slate
        case .rainbow: return Color(red: 0.95, green: 0.90, blue: 0.96)  // More colorful
        }
    }

    // MARK: - Text Colors

    var primaryTextColor: Color {
        switch self {
        case .midnight:
            // Improved: Off-white for better readability, WCAG AA compliant (~11.5:1 contrast)
            return Color(red: 0.95, green: 0.94, blue: 0.98)
        default:
            return Color(red: 0.15, green: 0.15, blue: 0.2)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .midnight:
            // Improved: Proper secondary with WCAG AA contrast (~5.2:1)
            return Color(red: 0.72, green: 0.70, blue: 0.78)
        default:
            return Color(red: 0.45, green: 0.45, blue: 0.5)
        }
    }

    // MARK: - Button Gradients

    /// Primary button gradient colors
    var buttonGradient: [Color] {
        switch self {
        case .system: return [Color(red: 0.35, green: 0.55, blue: 0.85), Color(red: 0.45, green: 0.65, blue: 0.9)]
        case .gentle: return [Color(red: 0.6, green: 0.7, blue: 0.85), Color(red: 0.75, green: 0.7, blue: 0.85)]
        case .sunny: return [Color(red: 1.0, green: 0.65, blue: 0.3), Color(red: 1.0, green: 0.5, blue: 0.35)]
        case .ocean: return [Color(red: 0.2, green: 0.6, blue: 0.85), Color(red: 0.3, green: 0.75, blue: 0.8)]
        case .forest: return [Color(red: 0.25, green: 0.55, blue: 0.4), Color(red: 0.4, green: 0.65, blue: 0.45)]
        case .candy: return [Color(red: 0.9, green: 0.35, blue: 0.55), Color(red: 0.7, green: 0.3, blue: 0.85)]
        case .midnight: return [Color(red: 0.45, green: 0.35, blue: 0.85), Color(red: 0.55, green: 0.45, blue: 0.95)]
        case .sunset: return [Color(red: 1.0, green: 0.55, blue: 0.3), Color(red: 1.0, green: 0.35, blue: 0.45)]
        case .lavender: return [Color(red: 0.65, green: 0.5, blue: 0.85), Color(red: 0.8, green: 0.55, blue: 0.85)]
        case .mint: return [Color(red: 0.25, green: 0.75, blue: 0.65), Color(red: 0.35, green: 0.8, blue: 0.7)]
        case .coral: return [Color(red: 1.0, green: 0.5, blue: 0.45), Color(red: 1.0, green: 0.6, blue: 0.5)]
        case .slate: return [Color(red: 0.4, green: 0.45, blue: 0.55), Color(red: 0.5, green: 0.55, blue: 0.65)]
        case .rainbow: return [Color(red: 0.9, green: 0.4, blue: 0.5), Color(red: 0.5, green: 0.4, blue: 0.9)]
        }
    }

    // MARK: - Semantic Colors

    /// Positive/success color (adjusted for theme)
    var positiveColor: Color {
        switch self {
        case .midnight:
            return Color(red: 0.3, green: 0.85, blue: 0.5)
        case .sunny:
            return Color(red: 0.35, green: 0.75, blue: 0.4)
        case .candy:
            return Color(red: 0.4, green: 0.8, blue: 0.55)
        default:
            return Color(red: 0.3, green: 0.75, blue: 0.45)
        }
    }

    /// Warning/challenge color
    var warningColor: Color {
        switch self {
        case .midnight:
            return Color(red: 1.0, green: 0.6, blue: 0.35)
        default:
            return Color(red: 1.0, green: 0.55, blue: 0.3)
        }
    }

    /// Star/reward color
    var starColor: Color {
        switch self {
        case .midnight:
            return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .ocean:
            return Color(red: 1.0, green: 0.75, blue: 0.25)
        default:
            return Color(red: 1.0, green: 0.78, blue: 0.2)
        }
    }

    // MARK: - Visual Style Properties

    /// Corner radius for cards and buttons
    var cornerRadius: CGFloat {
        switch self {
        case .system: return 16
        case .gentle, .lavender: return 20     // Extra rounded, soft
        case .candy, .rainbow: return 24       // Very rounded, playful
        case .slate, .midnight: return 12      // Sharp, modern
        default: return 16                      // Standard
        }
    }

    /// Shadow intensity (0-1)
    var shadowIntensity: CGFloat {
        switch self {
        case .system: return 0.1
        case .gentle, .lavender: return 0.06   // Very subtle
        case .midnight: return 0.4              // Strong for dark mode
        case .slate: return 0.08               // Subtle
        case .candy, .rainbow: return 0.12     // More pronounced
        default: return 0.1
        }
    }

    /// Shadow color
    var shadowColor: Color {
        switch self {
        case .midnight: return Color.black
        case .ocean: return Color(red: 0.1, green: 0.3, blue: 0.5)
        case .sunset: return Color(red: 0.5, green: 0.2, blue: 0.1)
        case .candy: return Color(red: 0.5, green: 0.1, blue: 0.3)
        default: return Color.black
        }
    }

    /// Whether to use gradients prominently
    var usesGradients: Bool {
        switch self {
        case .candy, .sunset, .rainbow, .midnight:
            return true
        default:
            return false
        }
    }

    /// Border style for cards - ALL premium themes have prominent themed borders
    /// Users must immediately see the theme is active after paying
    var cardBorderWidth: CGFloat {
        switch self {
        case .system, .gentle: return 0.5  // Subtle for free themes
        case .slate, .midnight: return 1.0
        default: return 2.0  // ALL premium themes get bold 2px borders - VISIBLE!
        }
    }

    var cardBorderColor: Color {
        switch self {
        case .system: return Color(red: 0.88, green: 0.90, blue: 0.94).opacity(0.6)
        case .gentle: return Color(red: 0.80, green: 0.85, blue: 0.92).opacity(0.5)
        case .sunny: return primaryColor.opacity(0.45)        // Golden border - BOLD
        case .ocean: return primaryColor.opacity(0.50)        // Blue border - BOLD
        case .forest: return primaryColor.opacity(0.50)       // Green border - BOLD
        case .candy: return primaryColor.opacity(0.50)        // Pink border - BOLD
        case .midnight: return Color.white.opacity(0.12)
        case .sunset: return primaryColor.opacity(0.50)       // Warm orange border - BOLD
        case .lavender: return primaryColor.opacity(0.50)     // Purple border - BOLD
        case .mint: return primaryColor.opacity(0.50)         // Mint border - BOLD
        case .coral: return primaryColor.opacity(0.50)        // Coral border - BOLD
        case .slate: return Color(red: 0.82, green: 0.84, blue: 0.86)
        case .rainbow: return primaryColor.opacity(0.50)      // BOLD colorful border!
        }
    }

    /// Accent strip/bar color for cards (for top/left accent bars)
    var cardAccentColor: Color {
        primaryColor
    }

    // MARK: - Preview Gradient (for theme cards)

    /// Gradient used in theme preview cards
    var previewGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Background gradient for theme preview
    var previewBackgroundGradient: LinearGradient {
        switch self {
        case .midnight:
            return LinearGradient(
                colors: [backgroundColor, Color(red: 0.1, green: 0.1, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .sunset:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.95, blue: 0.9), Color(red: 1.0, green: 0.9, blue: 0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .rainbow:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.97, blue: 0.98), Color(red: 0.97, green: 0.97, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [backgroundColor, backgroundColor],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Child Color Dark Mode Adjustments

/// Provides dark-mode-aware versions of child colors
struct DarkModeAwareChildColor {
    let baseColor: Color
    let isDarkMode: Bool

    /// Adjusted color that looks good on both light and dark backgrounds
    var color: Color {
        if isDarkMode {
            // Make colors more vibrant/saturated for dark mode
            return baseColor.opacity(1.0) // Full opacity, colors are already bright
        }
        return baseColor
    }

    /// Background fill for child elements (avatar backgrounds, badges)
    var backgroundFill: Color {
        if isDarkMode {
            return baseColor.opacity(0.2) // Subtle tinted background
        }
        return baseColor.opacity(0.15)
    }

    /// Border/ring color for child elements
    var borderColor: Color {
        if isDarkMode {
            return baseColor.opacity(0.8) // Slightly muted border
        }
        return baseColor.opacity(0.6)
    }

    /// Glow effect color for dark mode
    var glowColor: Color {
        if isDarkMode {
            return baseColor.opacity(0.4)
        }
        return baseColor.opacity(0.25)
    }
}

// MARK: - Theme-Aware View Modifiers

/// ViewModifier for themed primary button with automatic disabled state
private struct ThemedPrimaryButtonModifier: ViewModifier {
    let resolved: ResolvedTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        let backgroundOpacity: Double = isEnabled ? 1.0 : 0.55
        let labelOpacity: Double = isEnabled ? 1.0 : 0.75
        let shadowOpacity: Double = isEnabled ? 0.4 : 0.0

        content
            .foregroundColor(resolved.onPrimaryColor.opacity(labelOpacity))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: resolved.buttonGradient.map { $0.opacity(backgroundOpacity) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(resolved.cornerRadius)
            .shadow(
                color: resolved.buttonGradient.first?.opacity(shadowOpacity) ?? Color.clear,
                radius: 8,
                y: 4
            )
    }
}

extension View {
    /// Apply themed card style
    func themedCard(_ theme: AppTheme, colorScheme: ColorScheme, isSelected: Bool = false) -> some View {
        let resolved = ResolvedTheme(baseTheme: theme, colorScheme: colorScheme)
        return self
            .background(
                RoundedRectangle(cornerRadius: resolved.cornerRadius)
                    .fill(isSelected ? resolved.cardBackgroundTinted : resolved.cardBackground)
                    .shadow(
                        color: resolved.shadowColor.opacity(resolved.shadowIntensity),
                        radius: isSelected ? 12 : 8,
                        y: isSelected ? 6 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: resolved.cornerRadius)
                    .strokeBorder(resolved.cardBorderColor, lineWidth: resolved.cardBorderWidth)
            )
    }

    /// Apply themed card style (legacy - uses light mode)
    func themedCard(_ theme: AppTheme, isSelected: Bool = false) -> some View {
        themedCard(theme, colorScheme: .light, isSelected: isSelected)
    }

    /// Apply themed primary button style with automatic disabled state via @Environment(\.isEnabled)
    func themedPrimaryButton(_ theme: AppTheme, colorScheme: ColorScheme) -> some View {
        let resolved = ResolvedTheme(baseTheme: theme, colorScheme: colorScheme)
        return modifier(ThemedPrimaryButtonModifier(resolved: resolved))
    }

    /// Apply themed primary button style (legacy - uses light mode)
    func themedPrimaryButton(_ theme: AppTheme) -> some View {
        themedPrimaryButton(theme, colorScheme: .light)
    }
}
