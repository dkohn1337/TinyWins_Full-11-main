import SwiftUI
import Combine

// MARK: - Design Tokens Provider

/// The main token provider that serves as the single source of truth for all design tokens.
/// Inject this via environment and use throughout the app.
@MainActor
final class DesignTokens: ObservableObject {

    // MARK: - Published State

    @Published var appearance: Appearance
    @Published var themePack: ThemePack

    // MARK: - Computed Semantic Tokens

    /// All semantic tokens resolved for current appearance and theme
    var semantic: SemanticTokens {
        SemanticTokens(appearance: appearance, themePack: themePack)
    }

    // MARK: - Component Tokens

    var button: ButtonTokens {
        ButtonTokens(semantic: semantic)
    }

    var card: CardTokens {
        CardTokens(semantic: semantic)
    }

    var input: InputTokens {
        InputTokens(semantic: semantic)
    }

    // MARK: - Avatar Tokens

    /// Get avatar tokens for a specific child color
    func avatar(for childColor: Color) -> AvatarTokens {
        AvatarTokens(childColor: childColor, appearance: appearance)
    }

    /// Get avatar tokens from a ColorTag
    func avatar(for colorTag: ColorTag) -> AvatarTokens {
        AvatarTokens(childColor: colorTag.color, appearance: appearance)
    }

    // MARK: - Convenience Accessors (Semantic Shortcuts)

    // Backgrounds
    var bgApp: Color { semantic.bgApp }
    var bgSurface: Color { semantic.bgSurface }
    var bgSurfaceSecondary: Color { semantic.bgSurfaceSecondary }
    var bgGrouped: Color { semantic.bgGrouped }

    // Text
    var textPrimary: Color { semantic.textPrimary }
    var textSecondary: Color { semantic.textSecondary }
    var textTertiary: Color { semantic.textTertiary }
    var textDisabled: Color { semantic.textDisabled }
    var textOnPrimary: Color { semantic.textOnPrimary }

    // Accents
    var accentPrimary: Color { semantic.accentPrimary }
    var accentSecondary: Color { semantic.accentSecondary }
    var accentMuted: Color { semantic.accentMuted }

    // Semantic
    var positive: Color { semantic.positive }
    var positiveBg: Color { semantic.positiveBg }
    var challenge: Color { semantic.challenge }
    var challengeBg: Color { semantic.challengeBg }
    var error: Color { semantic.error }
    var star: Color { semantic.star }
    var routine: Color { semantic.routine }
    var plus: Color { semantic.plus }

    // Borders
    var borderDefault: Color { semantic.borderDefault }
    var borderSubtle: Color { semantic.borderSubtle }
    var divider: Color { semantic.divider }

    // MARK: - Initialization

    init(appearance: Appearance = .light, themePack: ThemePack = .classic) {
        self.appearance = appearance
        self.themePack = themePack
    }

    /// Create from system color scheme
    convenience init(colorScheme: ColorScheme, themePack: ThemePack = .classic) {
        self.init(appearance: Appearance(from: colorScheme), themePack: themePack)
    }

    // MARK: - Sync with System

    /// Update appearance based on system color scheme
    func syncWithColorScheme(_ colorScheme: ColorScheme) {
        let newAppearance = Appearance(from: colorScheme)
        if appearance != newAppearance {
            appearance = newAppearance
        }
    }

    // MARK: - Button Gradient

    /// Get button gradient colors for the current theme
    var buttonGradient: [Color] {
        themePack.buttonGradient(for: appearance)
    }
}

// MARK: - Environment Key

private struct DesignTokensKey: EnvironmentKey {
    @MainActor static let defaultValue: DesignTokens = DesignTokens()
}

extension EnvironmentValues {
    /// Access design tokens from environment
    var tokens: DesignTokens {
        get { self[DesignTokensKey.self] }
        set { self[DesignTokensKey.self] = newValue }
    }
}

// MARK: - View Extension for Token Injection

extension View {
    /// Inject design tokens into the view hierarchy
    func withDesignTokens(_ tokens: DesignTokens) -> some View {
        self
            .environment(\.tokens, tokens)
            .environmentObject(tokens)
    }

    /// Convenience to apply standard themed background
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}

// MARK: - Themed Background Modifier

private struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.tokens) private var tokens

    func body(content: Content) -> some View {
        content
            .background(tokens.bgApp)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension DesignTokens {
    /// Light mode with classic theme for previews
    static var previewLight: DesignTokens {
        DesignTokens(appearance: .light, themePack: .classic)
    }

    /// Dark mode with classic theme for previews
    static var previewDark: DesignTokens {
        DesignTokens(appearance: .dark, themePack: .classic)
    }

    /// All theme variations for preview testing
    static var allThemePreviews: [(String, DesignTokens)] {
        var previews: [(String, DesignTokens)] = []
        for theme in ThemePack.allCases {
            previews.append(("Light-\(theme.rawValue)", DesignTokens(appearance: .light, themePack: theme)))
            previews.append(("Dark-\(theme.rawValue)", DesignTokens(appearance: .dark, themePack: theme)))
        }
        return previews
    }
}
#endif

// MARK: - Token-Based View Modifiers

extension View {
    /// Apply themed card styling using design tokens
    func tokenCard(isSelected: Bool = false) -> some View {
        modifier(TokenCardModifier(isSelected: isSelected))
    }

    /// Apply themed primary button styling using design tokens
    func tokenPrimaryButton() -> some View {
        modifier(TokenPrimaryButtonModifier())
    }

    /// Apply themed secondary button styling using design tokens
    func tokenSecondaryButton() -> some View {
        modifier(TokenSecondaryButtonModifier())
    }
}

// MARK: - Token-Based Modifiers

private struct TokenCardModifier: ViewModifier {
    let isSelected: Bool
    @Environment(\.tokens) private var tokens

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? tokens.card.backgroundSelected : tokens.card.background)
                    .shadow(
                        color: tokens.card.shadow.opacity(tokens.card.shadowIntensity),
                        radius: isSelected ? 12 : 8,
                        y: isSelected ? 6 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? tokens.card.borderSelected : tokens.card.border,
                        lineWidth: 1
                    )
            )
    }
}

private struct TokenPrimaryButtonModifier: ViewModifier {
    @Environment(\.tokens) private var tokens
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .foregroundColor(isEnabled ? tokens.button.primaryText : tokens.button.primaryTextDisabled)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: tokens.buttonGradient.map { isEnabled ? $0 : $0.opacity(0.5) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(
                color: isEnabled ? tokens.accentPrimary.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
    }
}

private struct TokenSecondaryButtonModifier: ViewModifier {
    @Environment(\.tokens) private var tokens
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .foregroundColor(isEnabled ? tokens.button.secondaryText : tokens.textDisabled)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(tokens.button.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(tokens.button.secondaryBorder, lineWidth: 1)
            )
    }
}
