import SwiftUI

// MARK: - Primary Button

/// Main call-to-action button with full-width layout and prominent styling
/// Includes loading states, disabled states, and haptic feedback
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var hapticFeedback: Bool = true
    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: handleAction) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }

                Text(title)
                    .font(AppTypography.buttonLarge)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(
                        isDisabled ?
                            LinearGradient(
                                colors: [theme.textDisabled.opacity(0.5), theme.textDisabled.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            (isPressed ?
                                LinearGradient(
                                    colors: theme.accentGradient.map { $0.opacity(0.8) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                theme.buttonGradient
                            )
                    )
                    .shadow(
                        color: (theme.accentGradient.first ?? theme.accentPrimary).opacity(isPressed ? 0.2 : 0.35),
                        radius: isPressed ? 4 : 10,
                        y: isPressed ? 2 : 5
                    )
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading, please wait" : (isDisabled ? "Button disabled" : "Double tap to activate"))
        .accessibilityAddTraits(.isButton)
    }

    private func handleAction() {
        if hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        action()
    }
}

// MARK: - Secondary Button

/// Secondary action button with outline style
/// Less prominent than PrimaryButton for alternative actions
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    var hapticFeedback: Bool = true
    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: handleAction) {
            Text(title)
                .font(AppTypography.button)
                .foregroundColor(isDisabled ? theme.textDisabled : theme.accentPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(isPressed ? theme.accentPrimary.opacity(0.1) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(isDisabled ? theme.textDisabled : theme.accentPrimary, lineWidth: 2)
                        )
                )
        }
        .disabled(isDisabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint(isDisabled ? "Button disabled" : "Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }

    private func handleAction() {
        if hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        action()
    }
}

// MARK: - Tertiary Button

/// Text-only button for less prominent actions
/// No background, minimal visual weight
struct TertiaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.buttonSmall)
                .foregroundColor(isDisabled ? theme.textDisabled : theme.accentPrimary)
        }
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityHint(isDisabled ? "Button disabled" : "Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Destructive Button

/// Button for delete/remove actions with red styling
struct DestructiveButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        let destructiveColor = Color(red: 0.95, green: 0.3, blue: 0.3)

        Button(action: action) {
            Text(title)
                .font(AppTypography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(isDisabled ? theme.textDisabled : (isPressed ? destructiveColor.opacity(0.8) : destructiveColor))
                )
        }
        .disabled(isDisabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint(isDisabled ? "Button disabled" : "Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Icon Button

/// Circular button with just an icon
/// Used for actions like close, edit, etc.
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 44
    var tint: Color?
    @Environment(\.theme) private var theme
    @State private var isPressed = false

    var body: some View {
        let effectiveColor = tint ?? theme.accentPrimary

        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.5))
                .foregroundColor(effectiveColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(effectiveColor.opacity(isPressed ? 0.3 : 0.15))
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(accessibilityLabelForIcon)
        .accessibilityHint("Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabelForIcon: String {
        // Map common SF Symbols to descriptive labels
        switch systemName {
        case "xmark": return "Close"
        case "pencil": return "Edit"
        case "trash": return "Delete"
        case "plus": return "Add"
        case "star.fill": return "Favorite"
        case "chevron.left": return "Back"
        case "chevron.right": return "Forward"
        case "gearshape": return "Settings"
        case "ellipsis": return "More options"
        default: return systemName.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "fill", with: "").trimmingCharacters(in: .whitespaces)
        }
    }
}

// MARK: - Floating Action Button

/// Large circular button that floats over content
/// Used for primary actions like "Add"
struct FloatingActionButton: View {
    let systemName: String
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(theme.buttonGradient)
                        .shadow(
                            color: (theme.accentGradient.first ?? theme.accentPrimary).opacity(0.4),
                            radius: 12,
                            y: 4
                        )
                )
        }
        .accessibilityLabel(fabAccessibilityLabel)
        .accessibilityHint("Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }

    private var fabAccessibilityLabel: String {
        switch systemName {
        case "plus": return "Add new item"
        default: return systemName.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "fill", with: "").trimmingCharacters(in: .whitespaces)
        }
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            Text("Button Components")
                .font(AppTypography.title2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: AppSpacing.md) {
                // Primary Buttons
                Text("Primary Buttons")
                    .font(AppTypography.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PrimaryButton(title: "Log a Moment", action: {})
                PrimaryButton(title: "Loading...", action: {}, isLoading: true)
                PrimaryButton(title: "Disabled", action: {}, isDisabled: true)

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Secondary Buttons
                Text("Secondary Buttons")
                    .font(AppTypography.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SecondaryButton(title: "View All Goals", action: {})
                SecondaryButton(title: "Disabled", action: {}, isDisabled: true)

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Tertiary Buttons
                Text("Tertiary Buttons")
                    .font(AppTypography.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    TertiaryButton(title: "Cancel", action: {})
                    Spacer()
                    TertiaryButton(title: "Learn More", action: {})
                }

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Destructive Button
                Text("Destructive Button")
                    .font(AppTypography.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DestructiveButton(title: "Delete Child", action: {})

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Icon Buttons
                Text("Icon Buttons")
                    .font(AppTypography.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: AppSpacing.md) {
                    IconButton(systemName: "xmark", action: {})
                    IconButton(systemName: "pencil", action: {})
                    IconButton(systemName: "trash", action: {}, tint: .red)
                    IconButton(systemName: "star.fill", action: {}, tint: .yellow)
                }

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Floating Action Button
                Text("Floating Action Button")
                    .font(AppTypography.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Spacer()
                    FloatingActionButton(systemName: "plus", action: {})
                }
            }
        }
        .padding(AppSpacing.screenPadding)
    }
    .background(Theme().bg1)
    .withTheme(Theme())
}
