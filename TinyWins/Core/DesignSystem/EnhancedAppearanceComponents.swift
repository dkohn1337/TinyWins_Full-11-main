import SwiftUI

// MARK: - Enhanced Appearance Settings Components
// Premium theme gallery with visual previews

// MARK: - Theme Data Models

/// Theme configuration
struct AppTheme: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let gradientColors: [Color]
    let accentColor: Color
    let isPremium: Bool
    let previewImage: String? // SF Symbol for preview

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Theme Gallery Section

/// Section header with optional premium upsell
struct ThemeGallerySectionHeader: View {
    let title: String
    let isPremium: Bool
    let isLocked: Bool
    let onUpgrade: (() -> Void)?

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))

                if isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
            }

            Spacer()

            if isLocked, let onUpgrade = onUpgrade {
                Button(action: onUpgrade) {
                    Text("Unlock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Theme Preview Card

/// Visual theme preview card
struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void

    @Environment(\.theme) private var themeEnv
    @State private var shimmerOffset: CGFloat = -100

    var body: some View {
        Button(action: {
            if !isLocked {
                HapticManager.shared.selection()
                onSelect()
            }
        }) {
            VStack(spacing: 12) {
                // Theme preview
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)

                    // Sample UI elements
                    VStack(spacing: 10) {
                        // Fake progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: 44, height: 44)

                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))

                            Text("7")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // Fake button
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 70, height: 24)
                    }

                    // Lock overlay
                    if isLocked {
                        ZStack {
                            Color.black.opacity(0.5)
                                .cornerRadius(16)

                            VStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)

                                Text("Premium")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // Selected checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 28, height: 28)

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.green)
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }

                    // Premium shimmer
                    if theme.isPremium && !isLocked {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.2), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 16))
                            .onAppear {
                                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(Double.random(in: 0...1))) {
                                    shimmerOffset = 200
                                }
                            }
                    }
                }

                // Theme name
                Text(theme.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isLocked ? themeEnv.textSecondary : themeEnv.textPrimary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeEnv.surface1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                isSelected ? themeEnv.accentPrimary : themeEnv.borderSoft,
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? themeEnv.accentPrimary.opacity(0.3) : .black.opacity(0.06), radius: isSelected ? 12 : 8, y: isSelected ? 6 : 4)
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.8 : 1.0)
    }
}

// MARK: - Theme Grid

/// Grid of theme preview cards
struct ThemeGrid: View {
    let themes: [AppTheme]
    let selectedThemeId: UUID?
    let lockedThemeIds: Set<UUID>
    let onSelect: (AppTheme) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(themes) { theme in
                ThemePreviewCard(
                    theme: theme,
                    isSelected: selectedThemeId == theme.id,
                    isLocked: lockedThemeIds.contains(theme.id),
                    onSelect: { onSelect(theme) }
                )
            }
        }
    }
}

// MARK: - Premium Themes Upsell Banner

/// Banner promoting premium themes
struct PremiumThemesUpsell: View {
    let onUpgrade: () -> Void

    @State private var sparkleRotation: Double = 0

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                        .rotationEffect(.degrees(sparkleRotation))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("More ways to personalize")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(theme.textPrimary)

                    Text("Includes Forest, Midnight, and Lavender")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.purple)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .pink.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sparkleRotation = 15
            }
        }
    }
}

// MARK: - Icon Style Selector

/// App icon customization section
struct IconStyleSelector: View {
    let icons: [AppIconOption]
    @Binding var selectedIcon: AppIconOption?
    let isPremiumUser: Bool
    let onUpgrade: () -> Void

    struct AppIconOption: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let previewColors: [Color]
        let isPremium: Bool

        static func == (lhs: AppIconOption, rhs: AppIconOption) -> Bool {
            lhs.id == rhs.id
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("App Icon")
                    .font(.system(size: 22, weight: .bold))

                Spacer()

                if !isPremiumUser {
                    Button(action: onUpgrade) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                            Text("Premium")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical: 5)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.15))
                        )
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(icons) { icon in
                        AppIconPreview(
                            icon: icon,
                            isSelected: selectedIcon == icon,
                            isLocked: icon.isPremium && !isPremiumUser
                        ) {
                            if !icon.isPremium || isPremiumUser {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIcon = icon
                                }
                                HapticManager.shared.selection()
                            } else {
                                onUpgrade()
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Individual app icon preview
struct AppIconPreview: View {
    let icon: IconStyleSelector.AppIconOption
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    // Icon preview
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: icon.previewColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        )
                        .shadow(color: icon.previewColors[0].opacity(0.3), radius: 8, y: 4)

                    // Lock overlay
                    if isLocked {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                    }

                    // Selected indicator
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 20, height: 20)
                                    )
                                    .offset(x: 6, y: -6)
                            }
                            Spacer()
                        }
                        .frame(width: 72, height: 72)
                    }
                }

                Text(icon.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isLocked ? theme.textSecondary : theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Accent Picker

/// Custom accent color selection
struct AccentColorPicker: View {
    @Binding var selectedColor: Color
    let isPremiumUser: Bool
    let onUpgrade: () -> Void

    @Environment(\.theme) private var theme
    private let freeColors: [Color] = [.blue, .purple, .pink, .green, .orange]
    private let premiumColors: [Color] = [.red, .yellow, .mint, .cyan, .indigo, .brown]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color")
                .font(.system(size: 22, weight: .bold))

            // Free colors
            HStack(spacing: 12) {
                ForEach(freeColors, id: \.self) { color in
                    ColorSwatch(
                        color: color,
                        isSelected: selectedColor == color,
                        isLocked: false
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = color
                        }
                        HapticManager.shared.light()
                    }
                }
            }

            // Premium colors
            if !isPremiumUser {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("Premium Colors")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 8)
            }

            HStack(spacing: 12) {
                ForEach(premiumColors, id: \.self) { color in
                    ColorSwatch(
                        color: color,
                        isSelected: selectedColor == color,
                        isLocked: !isPremiumUser
                    ) {
                        if isPremiumUser {
                            withAnimation(.spring(response: 0.3)) {
                                selectedColor = color
                            }
                            HapticManager.shared.light()
                        } else {
                            onUpgrade()
                        }
                    }
                }
            }
        }
    }
}

/// Individual color swatch
struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 8)

                if isLocked {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                }

                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Complete Appearance Settings View

/// Full appearance settings screen
struct EnhancedAppearanceSettingsView: View {
    @State private var selectedTheme: AppTheme?
    @State private var selectedIcon: IconStyleSelector.AppIconOption?
    @State private var selectedAccentColor: Color = .purple
    @State private var showPaywall = false

    @Environment(\.theme) private var theme
    let isPremiumUser: Bool

    // Sample data
    private let freeThemes: [AppTheme] = [
        .init(name: "Default", gradientColors: [.blue, .purple], accentColor: .blue, isPremium: false, previewImage: nil),
        .init(name: "Ocean", gradientColors: [.cyan, .blue], accentColor: .cyan, isPremium: false, previewImage: nil),
        .init(name: "Forest", gradientColors: [.green, .mint], accentColor: .green, isPremium: false, previewImage: nil),
        .init(name: "Sunset", gradientColors: [.orange, .pink], accentColor: .orange, isPremium: false, previewImage: nil)
    ]

    private let premiumThemes: [AppTheme] = [
        .init(name: "Aurora", gradientColors: [.purple, .pink, .blue], accentColor: .purple, isPremium: true, previewImage: nil),
        .init(name: "Midnight", gradientColors: [.indigo, .purple], accentColor: .indigo, isPremium: true, previewImage: nil),
        .init(name: "Rose Gold", gradientColors: [.pink, .orange], accentColor: .pink, isPremium: true, previewImage: nil),
        .init(name: "Emerald", gradientColors: [.green, .teal], accentColor: .teal, isPremium: true, previewImage: nil),
        .init(name: "Lavender", gradientColors: [.purple, .pink.opacity(0.6)], accentColor: .purple, isPremium: true, previewImage: nil),
        .init(name: "Coral", gradientColors: [.red, .orange], accentColor: .red, isPremium: true, previewImage: nil)
    ]

    private let appIcons: [IconStyleSelector.AppIconOption] = [
        .init(name: "Default", previewColors: [.blue, .purple], isPremium: false),
        .init(name: "Dark", previewColors: [.gray, .black], isPremium: false),
        .init(name: "Sunrise", previewColors: [.orange, .yellow], isPremium: true),
        .init(name: "Ocean", previewColors: [.cyan, .blue], isPremium: true),
        .init(name: "Forest", previewColors: [.green, .mint], isPremium: true)
    ]

    private var lockedThemeIds: Set<UUID> {
        isPremiumUser ? [] : Set(premiumThemes.map { $0.id })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Free themes
                VStack(alignment: .leading, spacing: 16) {
                    ThemeGallerySectionHeader(
                        title: "Themes",
                        isPremium: false,
                        isLocked: false,
                        onUpgrade: nil
                    )

                    ThemeGrid(
                        themes: freeThemes,
                        selectedThemeId: selectedTheme?.id,
                        lockedThemeIds: [],
                        onSelect: { theme in
                            withAnimation(.spring(response: 0.3)) {
                                selectedTheme = theme
                            }
                        }
                    )
                }
                .padding(.horizontal, 20)

                // Premium upsell (if not premium)
                if !isPremiumUser {
                    PremiumThemesUpsell {
                        showPaywall = true
                    }
                    .padding(.horizontal, 20)
                }

                // Plus themes
                VStack(alignment: .leading, spacing: 16) {
                    ThemeGallerySectionHeader(
                        title: "With Plus",
                        isPremium: true,
                        isLocked: !isPremiumUser,
                        onUpgrade: isPremiumUser ? nil : { showPaywall = true }
                    )

                    ThemeGrid(
                        themes: premiumThemes,
                        selectedThemeId: selectedTheme?.id,
                        lockedThemeIds: lockedThemeIds,
                        onSelect: { theme in
                            if isPremiumUser {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTheme = theme
                                }
                            } else {
                                showPaywall = true
                            }
                        }
                    )
                }
                .padding(.horizontal, 20)

                Divider()
                    .padding(.horizontal, 20)

                // App icon
                IconStyleSelector(
                    icons: appIcons,
                    selectedIcon: $selectedIcon,
                    isPremiumUser: isPremiumUser,
                    onUpgrade: { showPaywall = true }
                )
                .padding(.horizontal, 20)

                Divider()
                    .padding(.horizontal, 20)

                // Accent color
                AccentColorPicker(
                    selectedColor: $selectedAccentColor,
                    isPremiumUser: isPremiumUser,
                    onUpgrade: { showPaywall = true }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
        .background(theme.bg1)
        .navigationTitle("Appearance")
        .sheet(isPresented: $showPaywall) {
            EnhancedPaywallView(
                onPurchase: { _ in showPaywall = false },
                onRestore: { showPaywall = false }
            )
        }
    }
}

// MARK: - Previews

#Preview("Theme Card") {
    let theme = AppTheme(
        name: "Aurora",
        gradientColors: [.purple, .pink, .blue],
        accentColor: .purple,
        isPremium: true,
        previewImage: nil
    )

    ThemePreviewCard(
        theme: theme,
        isSelected: false,
        isLocked: false,
        onSelect: {}
    )
    .frame(width: 170)
    .padding()
}

#Preview("Appearance Settings") {
    NavigationStack {
        EnhancedAppearanceSettingsView(isPremiumUser: false)
    }
}
