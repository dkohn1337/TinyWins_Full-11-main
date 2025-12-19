import SwiftUI

// MARK: - Theme Provider

/// Provides theme-aware colors that adapt based on current AppTheme and system color scheme.
/// This is the single source of truth for all theme-dependent colors in the app.
/// Supports the "System" theme that automatically follows iOS dark/light mode.
///
/// **Migration Note:** This class now bridges to the new DesignTokens system.
/// For new code, prefer using `@Environment(\.tokens)` directly.
/// Existing code using ThemeProvider will continue to work.
@MainActor
final class ThemeProvider: ObservableObject {
    @Published var currentTheme: AppTheme
    @Published var colorScheme: ColorScheme = .light

    init(theme: AppTheme = .system) {
        self.currentTheme = theme
    }

    /// Get the resolved theme with current color scheme applied
    var resolved: ResolvedTheme {
        ResolvedTheme(baseTheme: currentTheme, colorScheme: colorScheme)
    }

    /// Whether we're currently in dark mode (either via system or midnight theme)
    var isDarkMode: Bool {
        resolved.isDark
    }

    // MARK: - New Token System Bridge

    /// Current appearance derived from color scheme
    var appearance: Appearance {
        Appearance(from: colorScheme)
    }

    /// Current theme pack derived from AppTheme
    var themePack: ThemePack {
        ThemePack(rawValue: currentTheme.rawValue) ?? .classic
    }

    /// Semantic tokens resolved for current state
    var tokens: SemanticTokens {
        SemanticTokens(appearance: appearance, themePack: themePack)
    }

    /// Get avatar tokens for a child's color
    func avatarTokens(for childColor: Color) -> AvatarTokens {
        AvatarTokens(childColor: childColor, appearance: appearance)
    }

    /// Get avatar tokens from a ColorTag
    func avatarTokens(for colorTag: ColorTag) -> AvatarTokens {
        AvatarTokens(childColor: colorTag.color, appearance: appearance)
    }

    // MARK: - Core Theme Tokens (bridged to new token system)

    /// Primary accent color used for buttons, highlights, selected states
    var accentColor: Color {
        tokens.accentPrimary
    }

    /// Background color for main content areas
    var backgroundColor: Color {
        tokens.bgApp
    }

    /// Card background color
    var cardBackground: Color {
        tokens.bgSurface
    }

    /// Primary text color
    var primaryText: Color {
        tokens.textPrimary
    }

    /// Secondary text color (subtitles, captions)
    var secondaryText: Color {
        tokens.textSecondary
    }

    /// Chip/pill background color
    var chipBackground: Color {
        tokens.accentMuted
    }

    /// Chip/pill text color
    var chipForeground: Color {
        tokens.accentPrimary
    }

    // MARK: - Semantic Colors (bridged to new token system)

    /// Positive behavior color (green)
    var positiveColor: Color {
        tokens.positive
    }

    /// Challenge/negative behavior color (orange)
    var challengeColor: Color {
        tokens.challenge
    }

    /// Routine behavior color (blue/violet)
    var routineColor: Color {
        tokens.routine
    }

    /// Star/points color (yellow)
    var starColor: Color {
        tokens.star
    }

    /// Plus tier color (purple)
    var plusColor: Color {
        tokens.plus
    }

    // MARK: - Card Styling

    var cardShadow: Color {
        tokens.shadow.opacity(tokens.shadowIntensity)
    }

    var cardShadowRadius: CGFloat {
        tokens.shadowIntensity > 0.15 ? 10 : 8
    }

    // MARK: - Button Styling

    /// Button border width
    var buttonBorderWidth: CGFloat {
        resolved.cardBorderWidth > 0 ? 2 : 0
    }

    /// Corner radius for buttons and cards
    var cornerRadius: CGFloat {
        resolved.cornerRadius
    }

    /// Icon size modifier
    var iconSizeMultiplier: CGFloat {
        switch currentTheme {
        case .candy, .rainbow:
            return 1.15  // Slightly larger for playful themes
        default:
            return 1.0
        }
    }

    // MARK: - Extended Color Tokens (bridged)

    /// Elevated surface color (slightly above background)
    var surfaceElevated: Color {
        tokens.bgSurface
    }

    /// Subtle border color for cards and containers
    var borderSubtle: Color {
        tokens.borderSubtle
    }

    /// Overlay color for modals and sheets
    var overlay: Color {
        tokens.bgOverlay
    }

    /// Divider color
    var divider: Color {
        tokens.divider
    }

    // MARK: - Interaction States (bridged)

    /// Accent color on hover/focus
    var accentHover: Color {
        tokens.accentPrimary.opacity(0.9)
    }

    /// Accent color when pressed
    var accentPressed: Color {
        tokens.accentPrimary.opacity(0.8)
    }

    /// Accent color when disabled
    var accentDisabled: Color {
        tokens.textDisabled
    }

    /// Destructive action color (for delete, remove actions)
    var destructive: Color {
        tokens.error
    }

    /// Success color (for confirmations, success states)
    var success: Color {
        tokens.positive
    }

    /// Warning color (for caution states)
    var warning: Color {
        tokens.challenge
    }

    // MARK: - Child Color Helpers

    /// Get dark-mode-aware child color wrapper
    /// Deprecated: Use avatarTokens(for:) instead for better type safety
    func childColor(_ baseColor: Color) -> DarkModeAwareChildColor {
        DarkModeAwareChildColor(baseColor: baseColor, isDarkMode: isDarkMode)
    }

    // MARK: - Dark Mode Aware Banner/Badge Colors (bridged)

    /// Background color for positive/success banners (adapts to dark mode)
    var bannerPositiveBackground: Color {
        tokens.positiveBg
    }

    /// Background color for challenge/warning banners
    var bannerChallengeBackground: Color {
        tokens.challengeBg
    }

    /// Background color for info/neutral banners
    var bannerInfoBackground: Color {
        tokens.infoBg
    }

    /// Background color for special/purple banners
    var bannerSpecialBackground: Color {
        tokens.accentMuted
    }

    /// Background color for pink/heart banners
    var bannerPinkBackground: Color {
        appearance == .dark
            ? Primitives.Rosegold.primary.opacity(0.25)
            : Primitives.Rosegold.primary.opacity(0.1)
    }

    /// Background for focus/yellow cards
    var bannerFocusBackground: Color {
        tokens.starGlow.opacity(appearance == .dark ? 0.25 : 0.1)
    }

    // MARK: - Streak/Progress Colors (bridged)

    /// Active streak indicator color
    var streakActiveColor: Color {
        tokens.positive
    }

    /// Inactive/pending day indicator
    var streakInactiveColor: Color {
        tokens.bgSurfaceSecondary
    }

    /// Hot streak color (5+ days)
    var streakHotColor: Color {
        tokens.challenge
    }

    // MARK: - Text on Colored Backgrounds (bridged)

    /// Text color that works on colored badge backgrounds
    var textOnColoredBackground: Color {
        tokens.textPrimary
    }

    /// Secondary text visible in dark mode
    var secondaryTextAdaptive: Color {
        tokens.textSecondary
    }

    // MARK: - Helper Methods

    /// Get color for a specific behavior category
    func colorForCategory(_ category: BehaviorCategory) -> Color {
        switch category {
        case .positive:
            return positiveColor
        case .negative:
            return challengeColor
        case .routinePositive:
            return routineColor
        }
    }
}

// MARK: - Environment Key

private struct ThemeProviderKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = ThemeProvider()
}

extension EnvironmentValues {
    var themeProvider: ThemeProvider {
        get { self[ThemeProviderKey.self] }
        set { self[ThemeProviderKey.self] = newValue }
    }
}

extension View {
    /// Inject theme provider into environment
    func withThemeProvider(_ provider: ThemeProvider) -> some View {
        environment(\.themeProvider, provider)
    }

    /// Sync theme provider's colorScheme with environment
    func syncThemeWithColorScheme(_ provider: ThemeProvider) -> some View {
        modifier(ThemeColorSchemeSyncModifier(provider: provider))
    }
}

// MARK: - Color Scheme Sync Modifier

/// Modifier that syncs the ThemeProvider's colorScheme with the environment
private struct ThemeColorSchemeSyncModifier: ViewModifier {
    @ObservedObject var provider: ThemeProvider
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, newScheme in
                provider.colorScheme = newScheme
            }
            .onAppear {
                provider.colorScheme = colorScheme
            }
    }
}

// MARK: - Navigation Bar Theming

extension View {
    /// Apply themed navigation bar appearance
    func themedNavigationBar(_ theme: Theme) -> some View {
        modifier(ThemedNavigationBarModifier(theme: theme))
    }
}

private struct ThemedNavigationBarModifier: ViewModifier {
    @ObservedObject var theme: Theme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(theme.navBarBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
    }
}
