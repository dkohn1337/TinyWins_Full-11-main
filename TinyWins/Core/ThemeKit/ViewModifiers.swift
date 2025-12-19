import SwiftUI

// MARK: - Card Modifiers

/// Apply themed card styling to any view (ThemeKit version).
struct TKCardModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let isSelected: Bool
    let elevation: CardElevation

    enum CardElevation {
        case surface1  // Default card
        case surface2  // Elevated (sheet, modal)
        case surface3  // Highest (popover, pressed)
    }

    func body(content: Content) -> some View {
        let background: Color = {
            switch elevation {
            case .surface1: return isSelected ? theme.surface2 : theme.surface1
            case .surface2: return isSelected ? theme.surface3 : theme.surface2
            case .surface3: return theme.surface3
            }
        }()

        content
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(background)
                    .shadow(
                        color: theme.shadowColor.opacity(theme.shadowStrength),
                        radius: isSelected ? 12 : 8,
                        y: isSelected ? 6 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(
                        isSelected ? theme.borderStrong : theme.borderSoft,
                        lineWidth: theme.cardBorderWidth
                    )
            )
    }
}

extension View {
    /// Apply themed card styling (ThemeKit version).
    func tkCard(isSelected: Bool = false, elevation: TKCardModifier.CardElevation = .surface1) -> some View {
        modifier(TKCardModifier(isSelected: isSelected, elevation: elevation))
    }
}

// MARK: - Button Modifiers

/// Primary button with gradient background (ThemeKit version).
struct TKPrimaryButtonModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        let opacity = isEnabled ? 1.0 : 0.55

        content
            .foregroundColor(theme.textOnAccent.opacity(isEnabled ? 1.0 : 0.75))
            .font(.headline.weight(.semibold))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: theme.accentGradient.map { $0.opacity(opacity) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(theme.cornerRadius)
            .shadow(
                color: isEnabled ? theme.accentPrimary.opacity(0.4) : .clear,
                radius: 8,
                y: 4
            )
    }
}

/// Secondary button with border (ThemeKit version).
struct TKSecondaryButtonModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .foregroundColor(isEnabled ? theme.accentPrimary : theme.textDisabled)
            .font(.headline.weight(.medium))
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(theme.surface1)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(
                        isEnabled ? theme.borderStrong : theme.borderSoft,
                        lineWidth: 1.5
                    )
            )
    }
}

/// Destructive button (ThemeKit version).
struct TKDestructiveButtonModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        let opacity = isEnabled ? 1.0 : 0.55

        content
            .foregroundColor(.white.opacity(isEnabled ? 1.0 : 0.75))
            .font(.headline.weight(.semibold))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(theme.danger.opacity(opacity))
            .cornerRadius(theme.cornerRadius)
    }
}

extension View {
    /// Apply primary button styling with gradient (ThemeKit version).
    func tkPrimaryButton() -> some View {
        modifier(TKPrimaryButtonModifier())
    }

    /// Apply secondary button styling with border (ThemeKit version).
    func tkSecondaryButton() -> some View {
        modifier(TKSecondaryButtonModifier())
    }

    /// Apply destructive button styling (ThemeKit version).
    func tkDestructiveButton() -> some View {
        modifier(TKDestructiveButtonModifier())
    }
}

// MARK: - List Row Modifiers

/// Themed list row background (ThemeKit version).
struct TKListRowModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let showSeparator: Bool

    func body(content: Content) -> some View {
        content
            .listRowBackground(theme.surface1)
            .listRowSeparatorTint(showSeparator ? theme.separator : .clear)
    }
}

extension View {
    /// Apply themed list row styling (ThemeKit version).
    func tkListRow(showSeparator: Bool = true) -> some View {
        modifier(TKListRowModifier(showSeparator: showSeparator))
    }
}

// MARK: - Chip/Badge Modifiers

/// Themed chip/badge with accent background (ThemeKit version).
struct TKChipModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let style: ChipStyle

    enum ChipStyle {
        case accent
        case success
        case warning
        case danger
        case info
        case muted
    }

    func body(content: Content) -> some View {
        let (background, foreground): (Color, Color) = {
            switch style {
            case .accent:
                return (theme.accentMuted, theme.accentPrimary)
            case .success:
                return (theme.successBg, theme.success)
            case .warning:
                return (theme.warningBg, theme.warning)
            case .danger:
                return (theme.dangerBg, theme.danger)
            case .info:
                return (theme.infoBg, theme.info)
            case .muted:
                return (theme.bg1, theme.textSecondary)
            }
        }()

        content
            .font(.caption.weight(.medium))
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(background)
            )
    }
}

extension View {
    /// Apply themed chip styling (ThemeKit version).
    func tkChip(style: TKChipModifier.ChipStyle = .accent) -> some View {
        modifier(TKChipModifier(style: style))
    }
}

// MARK: - Avatar Modifiers

/// Themed avatar with safe text color (ThemeKit version).
struct TKAvatarModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let childColor: Color?
    let size: CGFloat

    func body(content: Content) -> some View {
        let derivation = childColor.map { theme.avatarDerivation(for: $0) }

        content
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundColor(derivation?.onFill ?? theme.textOnAccent)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(derivation?.fill ?? theme.accentPrimary)
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        derivation?.border ?? theme.borderStrong,
                        lineWidth: 2
                    )
            )
    }
}

extension View {
    /// Apply themed avatar styling with safe contrast (ThemeKit version).
    func tkAvatar(childColor: Color? = nil, size: CGFloat = 44) -> some View {
        modifier(TKAvatarModifier(childColor: childColor, size: size))
    }
}

// MARK: - Navigation Modifiers

/// Apply themed navigation bar styling (ThemeKit version).
struct TKNavigationModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(theme.navBarBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
    }
}

extension View {
    /// Apply themed navigation bar (ThemeKit version).
    func tkNavigation() -> some View {
        modifier(TKNavigationModifier())
    }
}

// MARK: - Background Modifiers

/// Apply themed app background (ThemeKit version).
struct TKBackgroundModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let ignoresSafeArea: Bool

    func body(content: Content) -> some View {
        if ignoresSafeArea {
            content
                .background(theme.bg0.ignoresSafeArea())
        } else {
            content
                .background(theme.bg0)
        }
    }
}

extension View {
    /// Apply themed app background (ThemeKit version).
    func tkBackground(ignoresSafeArea: Bool = true) -> some View {
        modifier(TKBackgroundModifier(ignoresSafeArea: ignoresSafeArea))
    }
}

// MARK: - Progress Indicator Modifiers

/// Themed progress ring/bar (ThemeKit version).
struct TKProgressModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let style: ProgressStyle

    enum ProgressStyle {
        case accent
        case success
        case star
        case routine
    }

    func body(content: Content) -> some View {
        let tint: Color = {
            switch style {
            case .accent: return theme.accentPrimary
            case .success: return theme.success
            case .star: return theme.star
            case .routine: return theme.routine
            }
        }()

        content
            .tint(tint)
    }
}

extension View {
    /// Apply themed progress indicator tint (ThemeKit version).
    func tkProgress(style: TKProgressModifier.ProgressStyle = .accent) -> some View {
        modifier(TKProgressModifier(style: style))
    }
}

// MARK: - Text Styling Extensions

extension Text {
    /// Apply primary text styling.
    func themedPrimary() -> some View {
        self.foregroundStyle(Color.primary)  // Will be overridden by theme
    }

    /// Apply secondary text styling.
    func themedSecondary() -> some View {
        self.foregroundStyle(Color.secondary)
    }
}

// MARK: - Semantic Color Helpers

extension View {
    /// Use semantic text color based on theme.
    func textColor(_ semantic: TextSemantic) -> some View {
        modifier(SemanticTextColorModifier(semantic: semantic))
    }
}

enum TextSemantic {
    case primary
    case secondary
    case tertiary
    case disabled
    case onAccent
    case inverse
    case success
    case warning
    case danger
    case info
}

private struct SemanticTextColorModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let semantic: TextSemantic

    func body(content: Content) -> some View {
        let color: Color = {
            switch semantic {
            case .primary: return theme.textPrimary
            case .secondary: return theme.textSecondary
            case .tertiary: return theme.textTertiary
            case .disabled: return theme.textDisabled
            case .onAccent: return theme.textOnAccent
            case .inverse: return theme.textInverse
            case .success: return theme.success
            case .warning: return theme.warning
            case .danger: return theme.danger
            case .info: return theme.info
            }
        }()

        content.foregroundColor(color)
    }
}
