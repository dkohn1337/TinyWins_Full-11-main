import SwiftUI
import Combine

// MARK: - Appearance Mode

/// User preference for appearance mode.
enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case auto = "auto"     // Follow system setting
    case light = "light"   // Always light
    case dark = "dark"     // Always dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Theme

/// The main theme object that provides resolved semantic tokens.
/// Inject via environment and use throughout the app.
@MainActor
final class Theme: ObservableObject {

    // MARK: - Published State

    @Published var paletteId: PaletteId
    @Published var appearanceMode: AppearanceMode
    @Published var systemColorScheme: ColorScheme = .light
    @Published var avatarColor: Color?

    // MARK: - Initialization

    init(
        paletteId: PaletteId = .system,
        appearanceMode: AppearanceMode = .auto,
        avatarColor: Color? = nil
    ) {
        self.paletteId = paletteId
        self.appearanceMode = appearanceMode
        self.avatarColor = avatarColor
    }

    // MARK: - Effective Appearance

    /// The resolved appearance (always light or dark).
    var effectiveAppearance: EffectiveAppearance {
        // Midnight is always dark
        if paletteId.isDarkOnly {
            return .dark
        }

        switch appearanceMode {
        case .auto:
            return systemColorScheme == .dark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// Whether currently in dark mode.
    var isDark: Bool {
        effectiveAppearance == .dark
    }

    // MARK: - Resolved Tokens

    /// All resolved semantic tokens.
    var tokens: ResolvedSemanticTokens {
        ResolvedSemanticTokens(
            palette: paletteId.palette,
            appearance: effectiveAppearance,
            avatarColor: avatarColor
        )
    }

    // MARK: - Token Accessors (Convenience)

    // Surfaces
    var bg0: Color { tokens.bg0 }
    var bg1: Color { tokens.bg1 }
    var surface1: Color { tokens.surface1 }
    var surface2: Color { tokens.surface2 }
    var surface3: Color { tokens.surface3 }
    var scrim: Color { tokens.scrim }

    // Borders
    var borderSoft: Color { tokens.borderSoft }
    var borderStrong: Color { tokens.borderStrong }
    var separator: Color { tokens.separator }

    // Text
    var textPrimary: Color { tokens.textPrimary }
    var textSecondary: Color { tokens.textSecondary }
    var textTertiary: Color { tokens.textTertiary }
    var textDisabled: Color { tokens.textDisabled }
    var textOnAccent: Color { tokens.textOnAccent }
    var textInverse: Color { tokens.textInverse }

    // Accents
    var accentPrimary: Color { tokens.accentPrimary }
    var accentSecondary: Color { tokens.accentSecondary }
    var accentMuted: Color { tokens.accentMuted }
    var accentGradient: [Color] { tokens.accentGradient }

    // Semantic States
    var success: Color { tokens.success }
    var successBg: Color { tokens.successBg }
    var warning: Color { tokens.warning }
    var warningBg: Color { tokens.warningBg }
    var danger: Color { tokens.danger }
    var dangerBg: Color { tokens.dangerBg }
    var info: Color { tokens.info }
    var infoBg: Color { tokens.infoBg }
    var star: Color { tokens.star }
    var routine: Color { tokens.routine }

    // Navigation
    var tabBarBg: Color { tokens.tabBarBg }
    var tabBarBorder: Color { tokens.tabBarBorder }
    var tabIconDefault: Color { tokens.tabIconDefault }
    var tabIconSelected: Color { tokens.tabIconSelected }
    var navBarBg: Color { tokens.navBarBg }
    var navBarText: Color { tokens.navBarText }

    // Effects
    var shadowColor: Color { tokens.shadowColor }
    var shadowStrength: CGFloat { tokens.shadowStrength }
    var glowColor: Color { tokens.glowColor }

    // Avatar
    var avatarFill: Color { tokens.avatarFill }
    var avatarOnFill: Color { tokens.avatarOnFill }
    var avatarMutedFill: Color { tokens.avatarMutedFill }
    var avatarBorder: Color { tokens.avatarBorder }

    // MARK: - Palette Properties

    var cornerRadius: CGFloat {
        let palette = paletteId.palette
        return isDark ? palette.dark.cornerRadius : palette.light.cornerRadius
    }

    var cardBorderWidth: CGFloat {
        let palette = paletteId.palette
        return isDark ? palette.dark.cardBorderWidth : palette.light.cardBorderWidth
    }

    // MARK: - Gradients

    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: accentGradient,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [bg0, bg1],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Avatar Derivation

    /// Get safe avatar color derivation for a specific color.
    func avatarDerivation(for color: Color) -> AvatarColorDerivation {
        AvatarColorDerivation(baseColor: color, appearance: effectiveAppearance)
    }

    /// Get avatar tokens for a color tag (bridging to legacy AvatarTokens).
    func avatarTokens(for colorTag: ColorTag) -> AvatarTokens {
        let appearance: Appearance = isDark ? .dark : .light
        return AvatarTokens(childColor: colorTag.color, appearance: appearance)
    }

    /// Get avatar tokens for a child color.
    func avatarTokens(for childColor: Color) -> AvatarTokens {
        let appearance: Appearance = isDark ? .dark : .light
        return AvatarTokens(childColor: childColor, appearance: appearance)
    }

    // MARK: - System Sync

    /// Update system color scheme from environment.
    func syncWithSystem(_ colorScheme: ColorScheme) {
        if systemColorScheme != colorScheme {
            systemColorScheme = colorScheme
        }
    }
}

// MARK: - Environment Integration

private struct ThemeEnvironmentKey: EnvironmentKey {
    @MainActor static let defaultValue: Theme = Theme()
}

extension EnvironmentValues {
    /// Access the theme from the environment.
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Inject theme into the view hierarchy.
    func withTheme(_ theme: Theme) -> some View {
        self
            .environment(\.theme, theme)
            .environmentObject(theme)
    }

    /// Sync theme with system color scheme.
    func syncThemeWithSystem(_ theme: Theme) -> some View {
        modifier(ThemeSystemSyncModifier(theme: theme))
    }
}

private struct ThemeSystemSyncModifier: ViewModifier {
    @ObservedObject var theme: Theme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, newScheme in
                theme.syncWithSystem(newScheme)
            }
            .onAppear {
                theme.syncWithSystem(colorScheme)
            }
    }
}

// MARK: - Compatibility with AppTheme

extension Theme {
    /// Create a Theme from the legacy AppTheme enum.
    convenience init(from appTheme: AppTheme, colorScheme: ColorScheme, avatarColor: Color? = nil) {
        let paletteId = PaletteId(rawValue: appTheme.rawValue) ?? .system
        self.init(paletteId: paletteId, avatarColor: avatarColor)
        self.systemColorScheme = colorScheme
    }

    /// Get the equivalent AppTheme (for backward compatibility).
    var appTheme: AppTheme {
        AppTheme(rawValue: paletteId.rawValue) ?? .system
    }
}

extension PaletteId {
    /// Initialize from AppTheme for backward compatibility.
    init(from appTheme: AppTheme) {
        self = PaletteId(rawValue: appTheme.rawValue) ?? .system
    }
}
