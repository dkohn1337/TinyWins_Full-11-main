import SwiftUI

// MARK: - Card Elevation System

/// Defines visual hierarchy levels for cards and containers
/// Higher elevation = more prominent shadow and visual separation
enum CardElevation {
    case flat       // No shadow, blends with background
    case low        // Subtle elevation for secondary content
    case medium     // Standard cards (most common)
    case high       // Featured cards and important content
    case floating   // Modals, sheets, overlays

    var shadowRadius: CGFloat {
        switch self {
        case .flat: return 0
        case .low: return 4
        case .medium: return 8
        case .high: return 16
        case .floating: return 24
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .flat: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 4
        case .floating: return 8
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .flat: return 0
        case .low: return 0.05
        case .medium: return 0.08
        case .high: return 0.12
        case .floating: return 0.15
        }
    }
}

// MARK: - Elevated Card Component

/// Accent position for themed cards
enum CardAccentPosition {
    case none
    case top
    case leading
}

/// A card container with configurable elevation and theme-aware styling
/// Provides consistent padding, corner radius, and shadows across the app
struct ElevatedCard<Content: View>: View {
    let content: Content
    var elevation: CardElevation
    var padding: CGFloat?
    var accentPosition: CardAccentPosition
    var customAccentColor: Color?
    @Environment(\.theme) private var theme

    init(
        elevation: CardElevation = .medium,
        padding: CGFloat? = nil,
        accent: CardAccentPosition = .none,
        accentColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.padding = padding
        self.accentPosition = accent
        self.customAccentColor = accentColor
        self.content = content()
    }

    var body: some View {
        let accentColor = customAccentColor ?? theme.accentPrimary

        content
            .padding(padding ?? AppSpacing.cardPadding)
            .background(theme.surface1)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(theme.borderSoft, lineWidth: 1)
            )
            .overlay(alignment: accentAlignment) {
                if accentPosition != .none {
                    accentBar(color: accentColor, cornerRadius: theme.cornerRadius)
                }
            }
            .shadow(
                color: theme.shadowColor.opacity(elevation.shadowOpacity * theme.shadowStrength * (theme.isDark ? 1.5 : 1.0)),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
    }

    private var accentAlignment: Alignment {
        switch accentPosition {
        case .none: return .center
        case .top: return .top
        case .leading: return .leading
        }
    }

    @ViewBuilder
    private func accentBar(color: Color, cornerRadius: CGFloat) -> some View {
        switch accentPosition {
        case .none:
            EmptyView()
        case .top:
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
            .fill(color)
            .frame(height: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        case .leading:
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(color)
            .frame(width: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Large Elevated Card (for hero content)

/// A larger card variant with extra padding for featured content
struct ElevatedCardLarge<Content: View>: View {
    let content: Content
    var elevation: CardElevation
    @Environment(\.theme) private var theme

    init(
        elevation: CardElevation = .high,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardPaddingLarge)
            .background(theme.surface1)
            .cornerRadius(theme.cornerRadius + 4)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius + 4)
                    .strokeBorder(theme.borderSoft, lineWidth: 1)
            )
            .shadow(
                color: theme.shadowColor.opacity(elevation.shadowOpacity * theme.shadowStrength * (theme.isDark ? 1.5 : 1.0)),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
    }
}

// MARK: - Pressable Card (with tap feedback)

/// A card that responds to touch with scale and opacity feedback
struct PressableCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    var elevation: CardElevation
    @Environment(\.theme) private var theme
    @State private var isPressed = false

    init(
        elevation: CardElevation = .medium,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(AppSpacing.cardPadding)
                .background(theme.surface1)
                .cornerRadius(theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .strokeBorder(theme.borderSoft, lineWidth: 1)
                )
                .shadow(
                    color: theme.shadowColor.opacity((isPressed ? elevation.shadowOpacity * 0.5 : elevation.shadowOpacity) * theme.shadowStrength),
                    radius: isPressed ? elevation.shadowRadius * 0.7 : elevation.shadowRadius,
                    y: isPressed ? elevation.shadowY * 0.5 : elevation.shadowY
                )
        }
        .buttonStyle(PressableCardButtonStyle(isPressed: $isPressed))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to open")
    }
}

// MARK: - Button Style for Pressable Card

private struct PressableCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Card Style View Modifier

/// A view modifier that applies consistent card styling
/// Use this for quick card styling without wrapping in ElevatedCard
struct CardStyleModifier: ViewModifier {
    let elevation: CardElevation
    let padding: CGFloat?
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(padding ?? AppSpacing.cardPadding)
            .background(theme.surface1)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(theme.borderSoft, lineWidth: 1)
            )
            .shadow(
                color: theme.shadowColor.opacity(elevation.shadowOpacity * theme.shadowStrength * (theme.isDark ? 1.5 : 1.0)),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
    }
}

extension View {
    /// Apply consistent card styling to any view
    /// - Parameters:
    ///   - elevation: Visual prominence level (default: .medium)
    ///   - padding: Custom padding (default: AppSpacing.cardPadding)
    func cardStyle(elevation: CardElevation = .medium, padding: CGFloat? = nil) -> some View {
        modifier(CardStyleModifier(elevation: elevation, padding: padding))
    }
}

// MARK: - Preview

#Preview("Card Elevations") {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            Text("Card Elevation System")
                .font(AppTypography.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screenPadding)

            VStack(spacing: AppSpacing.md) {
                ElevatedCard(elevation: .flat) {
                    CardContentExample(title: "Flat Card", subtitle: "No shadow, blends with background")
                }

                ElevatedCard(elevation: .low) {
                    CardContentExample(title: "Low Elevation", subtitle: "Subtle shadow for secondary content")
                }

                ElevatedCard(elevation: .medium) {
                    CardContentExample(title: "Medium Elevation", subtitle: "Standard cards (most common)")
                }

                ElevatedCard(elevation: .high) {
                    CardContentExample(title: "High Elevation", subtitle: "Featured cards and important content")
                }

                ElevatedCardLarge(elevation: .high) {
                    CardContentExample(title: "Large Featured Card", subtitle: "Extra padding for hero content")
                }

                PressableCard(elevation: .medium, action: {}) {
                    CardContentExample(title: "Pressable Card", subtitle: "Tap me to see interaction feedback")
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
        .padding(.vertical, AppSpacing.lg)
    }
    .background(Theme().bg1)
    .withTheme(Theme())
}

// MARK: - Preview Helper

private struct CardContentExample: View {
    @Environment(\.theme) private var theme
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.title3)

            Text(subtitle)
                .font(AppTypography.bodySmall)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
