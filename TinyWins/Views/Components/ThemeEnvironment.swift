import SwiftUI

// MARK: - Theme Provider

/// Provides theme-aware colors that adapt based on current AppTheme and system color scheme.
/// This is the single source of truth for all theme-dependent colors in the app.
/// Supports the "System" theme that automatically follows iOS dark/light mode.
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

    // MARK: - Core Theme Tokens (using resolved theme)

    /// Primary accent color used for buttons, highlights, selected states
    var accentColor: Color {
        resolved.primaryColor
    }

    /// Background color for main content areas
    var backgroundColor: Color {
        resolved.backgroundColor
    }

    /// Card background color
    var cardBackground: Color {
        resolved.cardBackground
    }

    /// Primary text color
    var primaryText: Color {
        resolved.primaryTextColor
    }

    /// Secondary text color (subtitles, captions)
    var secondaryText: Color {
        resolved.secondaryTextColor
    }

    /// Chip/pill background color
    var chipBackground: Color {
        resolved.cardBackgroundTinted
    }

    /// Chip/pill text color
    var chipForeground: Color {
        resolved.primaryColor
    }

    // MARK: - Semantic Colors (behavior tracking)

    /// Positive behavior color (green)
    var positiveColor: Color {
        resolved.positiveColor
    }

    /// Challenge/negative behavior color (orange)
    var challengeColor: Color {
        resolved.warningColor
    }

    /// Routine behavior color (blue) - using secondary color
    var routineColor: Color {
        resolved.secondaryColor
    }

    /// Star/points color (yellow)
    var starColor: Color {
        resolved.starColor
    }

    /// Plus tier color (purple)
    var plusColor: Color {
        Color(red: 0.6, green: 0.4, blue: 0.9)
    }

    // MARK: - Card Styling

    var cardShadow: Color {
        resolved.shadowColor.opacity(resolved.shadowIntensity)
    }

    var cardShadowRadius: CGFloat {
        resolved.shadowIntensity > 0.15 ? 10 : 8
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

    // MARK: - Extended Color Tokens

    /// Elevated surface color (slightly above background)
    var surfaceElevated: Color {
        resolved.cardBackground
    }

    /// Subtle border color for cards and containers
    var borderSubtle: Color {
        resolved.cardBorderColor
    }

    /// Overlay color for modals and sheets
    var overlay: Color {
        Color.black.opacity(0.4)
    }

    /// Divider color
    var divider: Color {
        isDarkMode
            ? Color.white.opacity(0.1)
            : Color(.systemGray5)
    }

    // MARK: - Interaction States

    /// Accent color on hover/focus
    var accentHover: Color {
        accentColor.opacity(0.9)
    }

    /// Accent color when pressed
    var accentPressed: Color {
        accentColor.opacity(0.8)
    }

    /// Accent color when disabled
    var accentDisabled: Color {
        Color(.systemGray4)
    }

    /// Destructive action color (for delete, remove actions)
    var destructive: Color {
        isDarkMode
            ? Color(red: 1.0, green: 0.4, blue: 0.4)
            : Color(red: 0.95, green: 0.3, blue: 0.3)
    }

    /// Success color (for confirmations, success states)
    var success: Color {
        positiveColor
    }

    /// Warning color (for caution states)
    var warning: Color {
        challengeColor
    }

    // MARK: - Child Color Helpers

    /// Get dark-mode-aware child color wrapper
    func childColor(_ baseColor: Color) -> DarkModeAwareChildColor {
        DarkModeAwareChildColor(baseColor: baseColor, isDarkMode: isDarkMode)
    }

    // MARK: - Dark Mode Aware Banner/Badge Colors

    /// Background color for positive/success banners (adapts to dark mode)
    var bannerPositiveBackground: Color {
        isDarkMode
            ? Color.green.opacity(0.25)
            : Color.green.opacity(0.1)
    }

    /// Background color for challenge/warning banners
    var bannerChallengeBackground: Color {
        isDarkMode
            ? Color.orange.opacity(0.25)
            : Color.orange.opacity(0.1)
    }

    /// Background color for info/neutral banners
    var bannerInfoBackground: Color {
        isDarkMode
            ? Color.blue.opacity(0.25)
            : Color.blue.opacity(0.1)
    }

    /// Background color for special/purple banners
    var bannerSpecialBackground: Color {
        isDarkMode
            ? Color.purple.opacity(0.25)
            : Color.purple.opacity(0.1)
    }

    /// Background color for pink/heart banners
    var bannerPinkBackground: Color {
        isDarkMode
            ? Color.pink.opacity(0.25)
            : Color.pink.opacity(0.1)
    }

    /// Background for focus/yellow cards
    var bannerFocusBackground: Color {
        isDarkMode
            ? Color.yellow.opacity(0.15)
            : Color.yellow.opacity(0.05)
    }

    // MARK: - Streak/Progress Colors

    /// Active streak indicator color
    var streakActiveColor: Color {
        isDarkMode
            ? Color(red: 0.4, green: 0.9, blue: 0.5)
            : Color.green
    }

    /// Inactive/pending day indicator
    var streakInactiveColor: Color {
        isDarkMode
            ? Color(white: 0.25)
            : Color(.systemGray5)
    }

    /// Hot streak color (5+ days)
    var streakHotColor: Color {
        isDarkMode
            ? Color(red: 1.0, green: 0.6, blue: 0.3)
            : Color.orange
    }

    // MARK: - Text on Colored Backgrounds

    /// Text color that works on colored badge backgrounds
    var textOnColoredBackground: Color {
        isDarkMode ? .white : .primary
    }

    /// Secondary text visible in dark mode
    var secondaryTextAdaptive: Color {
        isDarkMode
            ? Color.white.opacity(0.7)
            : Color.secondary
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
    func themedNavigationBar(_ themeProvider: ThemeProvider) -> some View {
        modifier(ThemedNavigationBarModifier(themeProvider: themeProvider))
    }
}

private struct ThemedNavigationBarModifier: ViewModifier {
    @ObservedObject var themeProvider: ThemeProvider

    func body(content: Content) -> some View {
        let resolved = themeProvider.resolved

        content
            .toolbarBackground(resolved.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(resolved.isDark ? .dark : .light, for: .navigationBar)
    }
}
