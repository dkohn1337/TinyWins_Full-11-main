import SwiftUI

/// Global appearance settings for the app - Personalization focused
struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var prefs: UserPreferencesStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.theme) private var theme
    @State private var previewTheme = Theme()
    @State private var showPaywall = false
    @State private var showAllPlusThemes = false

    private var isPremiumUser: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    /// Featured Plus themes: Forest, Midnight, Lavender
    private let featuredPlusThemes: [AppTheme] = [.forest, .midnight, .lavender]

    /// All other Plus themes (excluding featured)
    private var otherPlusThemes: [AppTheme] {
        AppTheme.allCases.filter { $0.isPremium && !featuredPlusThemes.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header with personalization message
                    VStack(spacing: 8) {
                        Text("Make it feel like yours")
                            .font(.system(size: 28, weight: .bold))

                        Text("Pick a theme that matches your style. TinyWins Plus adds more personalization options.")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Quick-scroll theme thumbnails
                    quickThemeThumbnails

                    // Live Preview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 20)

                        ThemePreviewCards(
                            theme: previewTheme.appTheme,
                            colorScheme: colorScheme
                        )
                    }

                    // Included Section (Free themes)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Included")
                                .font(.system(size: 20, weight: .semibold))

                            Spacer()

                            // Dark mode indicator when System is selected
                            if prefs.appTheme == .system {
                                HStack(spacing: 4) {
                                    Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                                        .font(.caption)
                                    Text(colorScheme == .dark ? "Dark" : "Light")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(theme.surface2)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(AppTheme.sortedCases.filter { !$0.isPremium }) { theme in
                                NewThemeCard(
                                    theme: theme,
                                    isSelected: prefs.appTheme == theme,
                                    isLocked: false,
                                    colorScheme: colorScheme
                                ) {
                                    selectTheme(theme)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Featured Plus Themes Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured with Plus")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(featuredPlusThemes) { theme in
                                NewThemeCard(
                                    theme: theme,
                                    isSelected: prefs.appTheme == theme,
                                    isLocked: !isPremiumUser,
                                    colorScheme: colorScheme
                                ) {
                                    if isPremiumUser {
                                        selectTheme(theme)
                                    } else {
                                        // M3 FIX: Preview the theme briefly before showing paywall
                                        previewThemeBeforePaywall(theme)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // See all Plus themes link
                        Button(action: { showAllPlusThemes = true }) {
                            HStack {
                                Text("See all Plus themes")
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(theme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .accessibilityHint("Opens the full list of Plus themes")
                    }

                    // See what Plus includes (secondary, non-pushy)
                    if !isPremiumUser {
                        Button(action: { showPaywall = true }) {
                            Text("See what TinyWins Plus includes")
                                .font(.subheadline)
                                .foregroundColor(theme.accentPrimary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(previewTheme.bg0)
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAllPlusThemes) {
                AllPlusThemesSheet(
                    isPremiumUser: isPremiumUser,
                    selectedTheme: prefs.appTheme,
                    colorScheme: colorScheme,
                    accentColor: theme.accentPrimary,
                    onSelectTheme: { theme in
                        if isPremiumUser {
                            selectTheme(theme)
                        } else {
                            // M3 FIX: Preview the theme briefly before showing paywall
                            previewThemeBeforePaywall(theme)
                        }
                    },
                    onShowPaywall: { showPaywall = true }
                )
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                previewTheme = Theme(from: prefs.appTheme, colorScheme: colorScheme)
            }
            .onChange(of: colorScheme) { _, newScheme in
                previewTheme = Theme(from: prefs.appTheme, colorScheme: newScheme)
            }
            .sheet(isPresented: $showPaywall) {
                PlusPaywallView(context: .premiumThemes)
            }
        }
    }

    private func selectTheme(_ appTheme: AppTheme) {
        withAnimation(.spring(response: 0.3)) {
            prefs.appTheme = appTheme
            previewTheme = Theme(from: appTheme, colorScheme: colorScheme)
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// M3 FIX: Preview the premium theme briefly before showing paywall
    /// This gives users a taste of the theme before asking them to upgrade
    private func previewThemeBeforePaywall(_ appTheme: AppTheme) {
        // Show preview immediately
        withAnimation(.spring(response: 0.3)) {
            previewTheme = Theme(from: appTheme, colorScheme: colorScheme)
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Show paywall after brief preview (1.5 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showPaywall = true
        }
    }

    // MARK: - Quick Theme Thumbnails

    /// Horizontal scroll of theme thumbnails for quick browsing
    private var quickThemeThumbnails: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Pick")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textSecondary)

                Spacer()

                // Show count
                Text("\(AppTheme.allCases.count) themes")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppTheme.sortedCases) { theme in
                        QuickThemeThumbnail(
                            theme: theme,
                            isSelected: prefs.appTheme == theme,
                            isLocked: theme.isPremium && !isPremiumUser,
                            colorScheme: colorScheme,
                            onTap: {
                                if theme.isPremium && !isPremiumUser {
                                    previewThemeBeforePaywall(theme)
                                } else {
                                    selectTheme(theme)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Quick Theme Thumbnail

/// Compact circular theme thumbnail for horizontal scroll
private struct QuickThemeThumbnail: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    private var resolved: ResolvedTheme {
        ResolvedTheme(baseTheme: theme, colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Theme orb
                    ZStack {
                        Circle()
                            .fill(resolved.previewBackgroundGradient)
                            .frame(width: 52, height: 52)

                        if theme.isSystemTheme {
                            // Split circle for system theme
                            ZStack {
                                Circle()
                                    .trim(from: 0, to: 0.5)
                                    .fill(Color(red: 0.97, green: 0.96, blue: 0.98))
                                    .frame(width: 36, height: 36)
                                    .rotationEffect(.degrees(-90))
                                Circle()
                                    .trim(from: 0.5, to: 1)
                                    .fill(Color(red: 0.11, green: 0.11, blue: 0.14))
                                    .frame(width: 36, height: 36)
                                    .rotationEffect(.degrees(-90))
                            }
                        } else {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [resolved.primaryColor, resolved.secondaryColor.opacity(0.7)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 20
                                    )
                                )
                                .frame(width: 36, height: 36)
                        }

                        // Lock overlay
                        if isLocked {
                            Circle()
                                .fill(Color.gray.opacity(0.7))
                                .frame(width: 36, height: 36)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }

                        // Selection ring
                        if isSelected {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(colors: resolved.buttonGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2.5
                                )
                                .frame(width: 50, height: 50)
                        }
                    }

                    // Badges
                    if theme.isNew {
                        Text("NEW")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                            .offset(x: 4, y: -4)
                    } else if theme.isPopular && !isSelected {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.pink)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }

                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? resolved.primaryColor : .primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Preview Cards (Dramatically Different Per Theme)

private struct ThemePreviewCards: View {
    let theme: AppTheme
    let colorScheme: ColorScheme

    private var resolved: ResolvedTheme {
        ResolvedTheme(baseTheme: theme, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Today Card Mock - Uses theme colors
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(resolved.primaryColor)

                    Text("Today")
                        .font(.headline)
                        .foregroundColor(resolved.primaryTextColor)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("5")
                            .foregroundColor(resolved.primaryColor)
                        Image(systemName: "star.fill")
                            .foregroundColor(resolved.starColor)
                    }
                    .font(.subheadline.weight(.semibold))
                }

                Text("3 moments today, including Sharing and Helping.")
                    .font(.body)
                    .foregroundColor(resolved.secondaryTextColor)

                // Primary action button - Uses theme gradient
                Button(action: {}) {
                    Text("Log a Moment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(resolved.primaryColor)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(resolved.cardBackground)
            .cornerRadius(resolved.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: resolved.cornerRadius)
                    .strokeBorder(resolved.cardBorderColor, lineWidth: resolved.cardBorderWidth)
            )
            .shadow(
                color: resolved.shadowColor.opacity(resolved.shadowIntensity),
                radius: 8,
                y: 4
            )

            // Kid Card Mock
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Avatar with theme color
                    Circle()
                        .fill(resolved.secondaryColor.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(resolved.secondaryColor)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alex")
                            .font(.headline)
                            .foregroundColor(resolved.primaryTextColor)

                        HStack(spacing: 4) {
                            Image(systemName: "flag.fill")
                                .font(.caption2)
                                .foregroundColor(resolved.positiveColor)
                            Text("Working toward Ice Cream Trip")
                                .font(.caption)
                                .foregroundColor(resolved.secondaryTextColor)
                        }
                    }

                    Spacer()
                }

                // Progress chips with theme styling
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("2/5")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(resolved.primaryColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(resolved.primaryColor.opacity(0.15))
                    .cornerRadius(8)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("12 stars")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(resolved.primaryColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(resolved.primaryColor.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(resolved.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(resolved.cardBorderColor, lineWidth: 1)
            )
            .shadow(
                color: resolved.shadowColor.opacity(resolved.shadowIntensity),
                radius: 8,
                y: 4
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(resolved.backgroundColor)
        .cornerRadius(20)
        .padding(.horizontal, 4)
    }
}

// MARK: - New Theme Card (Visual Impact)

private struct NewThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    @State private var isPressed = false

    private var resolved: ResolvedTheme {
        ResolvedTheme(baseTheme: theme, colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Theme preview orb - uses actual theme colors
                ZStack {
                    // Background with theme gradient
                    Circle()
                        .fill(resolved.backgroundColor)
                        .frame(width: 80, height: 80)

                    // Special icon for System theme
                    if theme.isSystemTheme {
                        // Split circle showing light/dark
                        ZStack {
                            // Light half
                            Circle()
                                .trim(from: 0, to: 0.5)
                                .fill(Color(red: 0.97, green: 0.96, blue: 0.98))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))

                            // Dark half
                            Circle()
                                .trim(from: 0.5, to: 1)
                                .fill(Color(red: 0.11, green: 0.11, blue: 0.14))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))

                            // Center icons
                            HStack(spacing: 8) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                            }
                        }
                    } else {
                        // Inner orb with theme's primary/secondary colors
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        resolved.primaryColor.opacity(0.9),
                                        resolved.secondaryColor.opacity(0.7),
                                        resolved.primaryColor.opacity(0.4)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 60, height: 60)

                        // Inner highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                    }

                    // Lock overlay for premium themes
                    if isLocked {
                        Circle()
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 60, height: 60)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Selection ring
                    if isSelected {
                        Circle()
                            .strokeBorder(
                                resolved.primaryColor,
                                lineWidth: 3
                            )
                            .frame(width: 76, height: 76)
                    }
                }

                // Theme name and description
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        // Special icon for system theme
                        if theme.isSystemTheme {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Text(theme.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(resolved.positiveColor)
                        }

                        if isLocked {
                            HStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                Text("Plus")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }

                        // Dark mode badge for midnight theme
                        if theme == .midnight && !isLocked {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.purple)
                        }

                        // New badge
                        if theme.isNew {
                            Text("NEW")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }

                        // Popular badge (only if not new and not locked)
                        if theme.isPopular && !theme.isNew && !isLocked {
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                Text("Popular")
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundColor(.pink)
                        }
                    }

                    Text(theme.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? resolved.primaryColor.opacity(0.15) : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? resolved.primaryColor : theme.cardBorderColor,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? resolved.primaryColor.opacity(0.25) : .black.opacity(0.05),
                radius: isSelected ? 12 : 6,
                y: isSelected ? 6 : 3
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLocked ? "Requires TinyWins Plus" : (isSelected ? "Currently selected" : "Double tap to select"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accessibilityLabel: String {
        var label = "\(theme.displayName) theme"
        if isLocked {
            label += ", Plus"
        }
        if isSelected {
            label += ", selected"
        }
        return label
    }
}

// MARK: - All Plus Themes Sheet

/// Sheet showing all Plus themes for users who want to browse
private struct AllPlusThemesSheet: View {
    let isPremiumUser: Bool
    let selectedTheme: AppTheme
    let colorScheme: ColorScheme
    let accentColor: Color
    let onSelectTheme: (AppTheme) -> Void
    let onShowPaywall: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    private var allPlusThemes: [AppTheme] {
        AppTheme.allCases.filter { $0.isPremium }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("All Plus themes")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(allPlusThemes) { appTheme in
                            NewThemeCard(
                                theme: appTheme,
                                isSelected: selectedTheme == appTheme,
                                isLocked: !isPremiumUser,
                                colorScheme: colorScheme
                            ) {
                                onSelectTheme(appTheme)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if !isPremiumUser {
                        Button(action: {
                            dismiss()
                            onShowPaywall()
                        }) {
                            Text("See what TinyWins Plus includes")
                                .font(.subheadline)
                                .foregroundColor(accentColor)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(theme.bg1)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Legacy Support

/// Legacy AccentColorOption for backward compatibility
enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue, purple, pink, orange, green, teal, red, indigo, mint, yellow

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .orange: return .orange
        case .green: return .green
        case .teal: return .teal
        case .red: return .red
        case .indigo: return .indigo
        case .mint: return .mint
        case .yellow: return .yellow
        }
    }
}

// MARK: - Preview

#Preview {
    AppearanceSettingsView()
        .environmentObject(UserPreferencesStore())
        .environmentObject(SubscriptionManager())
}
