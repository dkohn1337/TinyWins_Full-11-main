import SwiftUI

#if DEBUG

// MARK: - Theme Debug Panel

/// DEBUG-only panel showing current theme state and controls.
struct ThemeDebugPanel: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var systemColorScheme

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(theme.accentPrimary)
                    Text("Theme Debug")
                        .font(.caption.bold())
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .background(theme.separator)

                VStack(alignment: .leading, spacing: 8) {
                    // Current State
                    Group {
                        debugRow("Palette", theme.paletteId.displayName)
                        debugRow("Mode", theme.isDark ? "Dark" : "Light")
                        debugRow("System", systemColorScheme == .dark ? "Dark" : "Light")
                        debugRow("Effective", theme.effectiveAppearance == .dark ? "Dark" : "Light")
                    }

                    Divider()
                        .background(theme.separator)

                    // Quick Toggles
                    HStack(spacing: 8) {
                        toggleButton("Light") {
                            theme.appearanceMode = .light
                        }
                        toggleButton("Dark") {
                            theme.appearanceMode = .dark
                        }
                        toggleButton("Auto") {
                            theme.appearanceMode = .auto
                        }
                    }
                }
                .padding(12)
            }
        }
        .background(theme.surface2)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.borderSoft, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 4)
        .frame(width: 200)
    }

    private func debugRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption2.bold())
                .foregroundColor(theme.textPrimary)
        }
    }

    private func toggleButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.accentMuted)
                .foregroundColor(theme.accentPrimary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Preview Screen

/// DEBUG-only screen showing all semantic tokens and sample components.
struct ThemePreviewScreen: View {
    @Environment(\.theme) private var theme
    @State private var selectedPalette: PaletteId = .system

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Palette Picker
                    palettePickerSection

                    // Token Swatches
                    tokenSwatchesSection

                    // Sample Components
                    sampleComponentsSection

                    // Contrast Warnings
                    contrastWarningsSection
                }
                .padding()
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle("Theme Preview")
            .tkNavigation()
        }
        .onChange(of: selectedPalette) { _, newPalette in
            theme.paletteId = newPalette
        }
        .onAppear {
            selectedPalette = theme.paletteId
        }
    }

    // MARK: - Sections

    private var palettePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palette")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80))
            ], spacing: 8) {
                ForEach(PaletteId.allCases) { palette in
                    paletteChip(palette)
                }
            }
        }
        .padding()
        .tkCard()
    }

    private func paletteChip(_ palette: PaletteId) -> some View {
        Button {
            selectedPalette = palette
        } label: {
            Text(palette.displayName)
                .font(.caption.bold())
                .foregroundColor(selectedPalette == palette ? theme.textOnAccent : theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedPalette == palette ? theme.accentPrimary : theme.surface2)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var tokenSwatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Semantic Tokens")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            // Surfaces
            swatchGroup("Surfaces", [
                ("bg0", theme.bg0),
                ("bg1", theme.bg1),
                ("surface1", theme.surface1),
                ("surface2", theme.surface2),
                ("surface3", theme.surface3),
            ])

            // Text
            swatchGroup("Text", [
                ("primary", theme.textPrimary),
                ("secondary", theme.textSecondary),
                ("tertiary", theme.textTertiary),
                ("disabled", theme.textDisabled),
            ])

            // Borders
            swatchGroup("Borders", [
                ("soft", theme.borderSoft),
                ("strong", theme.borderStrong),
                ("separator", theme.separator),
            ])

            // Accents
            swatchGroup("Accents", [
                ("primary", theme.accentPrimary),
                ("secondary", theme.accentSecondary),
                ("muted", theme.accentMuted),
            ])

            // Semantic
            swatchGroup("Semantic", [
                ("success", theme.success),
                ("warning", theme.warning),
                ("danger", theme.danger),
                ("info", theme.info),
                ("star", theme.star),
                ("routine", theme.routine),
            ])
        }
        .padding()
        .tkCard()
    }

    private func swatchGroup(_ title: String, _ colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(theme.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(colors, id: \.0) { name, color in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(theme.borderSoft, lineWidth: 1)
                            )
                        Text(name)
                            .font(.caption2)
                            .foregroundColor(theme.textTertiary)
                    }
                }
            }
        }
    }

    private var sampleComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample Components")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            // Buttons
            HStack(spacing: 12) {
                Button("Primary") {}
                    .tkPrimaryButton()

                Button("Secondary") {}
                    .tkSecondaryButton()
            }

            // Cards
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Card")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.textPrimary)
                Text("This is secondary text on a card surface.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .tkCard()

            // Chips
            HStack(spacing: 8) {
                Text("Accent").tkChip(style: .accent)
                Text("Success").tkChip(style: .success)
                Text("Warning").tkChip(style: .warning)
                Text("Danger").tkChip(style: .danger)
            }

            // Avatar
            HStack(spacing: 12) {
                Text("JD")
                    .tkAvatar(childColor: Color.blue, size: 44)
                Text("AB")
                    .tkAvatar(childColor: Color.yellow, size: 44)
                Text("XY")
                    .tkAvatar(childColor: Color.green, size: 44)
            }
        }
        .padding()
        .tkCard()
    }

    private var contrastWarningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contrast Checks")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            contrastCheck("textPrimary on bg0", theme.textPrimary, theme.bg0)
            contrastCheck("textPrimary on surface1", theme.textPrimary, theme.surface1)
            contrastCheck("textSecondary on bg0", theme.textSecondary, theme.bg0)
            contrastCheck("textSecondary on surface1", theme.textSecondary, theme.surface1)
            contrastCheck("textOnAccent on accentPrimary", theme.textOnAccent, theme.accentPrimary)
        }
        .padding()
        .tkCard()
    }

    private func contrastCheck(_ label: String, _ foreground: Color, _ background: Color) -> some View {
        let ratio = ContrastUtilities.contrastRatio(between: foreground, and: background)
        let meetsAA = ratio >= 4.5
        let meetsAALarge = ratio >= 3.0

        return HStack {
            Circle()
                .fill(meetsAA ? theme.success : (meetsAALarge ? theme.warning : theme.danger))
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            Spacer()

            Text(String(format: "%.1f:1", ratio))
                .font(.caption.monospaced())
                .foregroundColor(meetsAA ? theme.success : (meetsAALarge ? theme.warning : theme.danger))
        }
    }
}

// MARK: - Preview Modifier

extension View {
    /// Add floating theme debug panel (DEBUG only).
    func withThemeDebugPanel() -> some View {
        overlay(alignment: .bottomTrailing) {
            ThemeDebugPanel()
                .padding()
        }
    }
}

#endif

// MARK: - Non-DEBUG Stubs

#if !DEBUG
extension View {
    func withThemeDebugPanel() -> some View {
        self  // No-op in release builds
    }
}
#endif
