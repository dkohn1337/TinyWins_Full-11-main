# TinyWins Theme Architecture Design

**Deliverable B - Theme Architecture**
**Date:** December 2024
**Status:** Complete

---

## 1. Design Principles

### 1.1 Core Separation (Non-Negotiable)

```
APPEARANCE          THEME PACK           CHILD IDENTITY
(Light/Dark)   x   (Color Scheme)   x   (Avatar Color)
     |                   |                    |
     v                   v                    v
  Affects           Affects only         Affects only
  all colors        accent colors        avatar/badge
  contrast          (primary, accent)    decorations
```

**Rule:** Typography tokens NEVER depend on theme pack or child identity.

### 1.2 Token Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│  PRIMITIVE TOKENS (Raw Values - Never Used in Views)        │
│  ──────────────────────────────────────────────────────────  │
│  white: #FFFFFF, black: #000000, gray50: #F9FAFB, etc.      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           v
┌─────────────────────────────────────────────────────────────┐
│  SEMANTIC TOKENS (Role-Based - Used in Components)          │
│  ──────────────────────────────────────────────────────────  │
│  bgApp, bgSurface, bgCard, textPrimary, textSecondary       │
│  These resolve PRIMITIVES based on APPEARANCE (dark/light)  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           v
┌─────────────────────────────────────────────────────────────┐
│  COMPONENT TOKENS (UI-Specific - Used in Views)             │
│  ──────────────────────────────────────────────────────────  │
│  buttonPrimaryBg, cardBorder, inputBackground, etc.         │
│  These compose SEMANTIC TOKENS for specific components      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Primitive Token Definitions

### 2.1 Neutral Scale (Gray)

```swift
enum Primitives {
    enum Neutral {
        static let white = Color(hex: "FFFFFF")
        static let gray50 = Color(hex: "F9FAFB")
        static let gray100 = Color(hex: "F3F4F6")
        static let gray200 = Color(hex: "E5E7EB")
        static let gray300 = Color(hex: "D1D5DB")
        static let gray400 = Color(hex: "9CA3AF")
        static let gray500 = Color(hex: "6B7280")
        static let gray600 = Color(hex: "4B5563")
        static let gray700 = Color(hex: "374151")
        static let gray800 = Color(hex: "1F2937")
        static let gray900 = Color(hex: "111827")
        static let black = Color(hex: "000000")
    }
}
```

### 2.2 Theme Pack Palettes

```swift
extension Primitives {
    enum Classic {
        static let primary = Color(hex: "7C3AED")    // Violet
        static let secondary = Color(hex: "8B5CF6")
        static let accent = Color(hex: "A78BFA")
    }

    enum Ocean {
        static let primary = Color(hex: "0891B2")    // Cyan
        static let secondary = Color(hex: "06B6D4")
        static let accent = Color(hex: "22D3EE")
    }

    enum Sunset {
        static let primary = Color(hex: "F97316")    // Orange
        static let secondary = Color(hex: "FB923C")
        static let accent = Color(hex: "FDBA74")
    }

    enum Forest {
        static let primary = Color(hex: "059669")    // Emerald
        static let secondary = Color(hex: "10B981")
        static let accent = Color(hex: "34D399")
    }

    enum Midnight {
        static let primary = Color(hex: "6366F1")    // Indigo
        static let secondary = Color(hex: "818CF8")
        static let accent = Color(hex: "A5B4FC")
    }

    // ... additional theme palettes
}
```

### 2.3 Semantic Color Scale

```swift
extension Primitives {
    enum Semantic {
        // Success (for positive behaviors, wins)
        static let success50 = Color(hex: "F0FDF4")
        static let success500 = Color(hex: "22C55E")
        static let success600 = Color(hex: "16A34A")

        // Warning (for challenges, attention)
        static let warning50 = Color(hex: "FFFBEB")
        static let warning500 = Color(hex: "F59E0B")
        static let warning600 = Color(hex: "D97706")

        // Error (for negative states)
        static let error50 = Color(hex: "FEF2F2")
        static let error500 = Color(hex: "EF4444")
        static let error600 = Color(hex: "DC2626")

        // Info (for hints, tips)
        static let info50 = Color(hex: "EFF6FF")
        static let info500 = Color(hex: "3B82F6")
        static let info600 = Color(hex: "2563EB")

        // Stars (for rewards)
        static let starLight = Color(hex: "FCD34D")
        static let starDark = Color(hex: "FBBF24")
    }
}
```

### 2.4 Child Identity Colors (Avatar)

```swift
extension Primitives {
    enum ChildColors {
        // These are ONLY for avatar circles, badges, and decorations
        // NEVER for text or typography
        static let blue = Color(hex: "4285F4")
        static let green = Color(hex: "4DC779")
        static let orange = Color(hex: "FF9400")
        static let purple = Color(hex: "9E52E0")
        static let pink = Color(hex: "F55C8D")
        static let teal = Color(hex: "00BFC7")
        static let coral = Color(hex: "FF6B6B")
        static let yellow = Color(hex: "FFCC00")
    }
}
```

---

## 3. Semantic Token Definitions

### 3.1 Background Tokens

```swift
protocol SemanticTokens {
    // App-level backgrounds
    var bgApp: Color { get }              // Main app background
    var bgSurface: Color { get }          // Elevated surface (cards, sheets)
    var bgSurfaceSecondary: Color { get } // Subtle surface variation
    var bgOverlay: Color { get }          // Modal/sheet overlay

    // Interactive backgrounds
    var bgInteractive: Color { get }      // Default interactive element
    var bgInteractiveHover: Color { get } // Hover state
    var bgInteractivePressed: Color { get } // Pressed state
    var bgInteractiveDisabled: Color { get } // Disabled state
}
```

### 3.2 Text Tokens

```swift
extension SemanticTokens {
    // Typography colors
    var textPrimary: Color { get }        // Headlines, body text
    var textSecondary: Color { get }      // Captions, hints
    var textTertiary: Color { get }       // Placeholders
    var textDisabled: Color { get }       // Disabled text
    var textInverse: Color { get }        // Text on dark backgrounds
    var textOnPrimary: Color { get }      // Text on primary color buttons
}
```

### 3.3 Border & Divider Tokens

```swift
extension SemanticTokens {
    var borderDefault: Color { get }      // Standard borders
    var borderSubtle: Color { get }       // Very light borders
    var borderStrong: Color { get }       // Emphasized borders
    var borderFocused: Color { get }      // Focus ring
    var divider: Color { get }            // List dividers
}
```

### 3.4 Accent & Brand Tokens

```swift
extension SemanticTokens {
    // Theme-driven accents
    var accentPrimary: Color { get }      // Primary brand color
    var accentSecondary: Color { get }    // Secondary brand color
    var accentMuted: Color { get }        // Subdued accent

    // Semantic colors (constant across themes)
    var positive: Color { get }           // Success, wins
    var positiveBackground: Color { get }
    var challenge: Color { get }          // Challenges, attention
    var challengeBackground: Color { get }
    var error: Color { get }              // Errors, failures
    var errorBackground: Color { get }
    var star: Color { get }               // Star/reward color
}
```

### 3.5 Resolution by Appearance

```swift
struct SemanticTokenResolver {
    let appearance: Appearance  // .light or .dark
    let themePack: ThemePack    // .classic, .ocean, etc.

    var bgApp: Color {
        switch appearance {
        case .light: return Primitives.Neutral.white
        case .dark: return Primitives.Neutral.gray900
        }
    }

    var bgSurface: Color {
        switch appearance {
        case .light: return Primitives.Neutral.white
        case .dark: return Primitives.Neutral.gray800
        }
    }

    var textPrimary: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray900
        case .dark: return Primitives.Neutral.gray50
        }
    }

    var textSecondary: Color {
        switch appearance {
        case .light: return Primitives.Neutral.gray500
        case .dark: return Primitives.Neutral.gray400
        }
    }

    var accentPrimary: Color {
        // This varies by theme pack
        themePack.primaryColor(for: appearance)
    }
}
```

---

## 4. Component Token Definitions

### 4.1 Button Tokens

```swift
struct ButtonTokens {
    // Primary Button
    var primaryBackground: Color
    var primaryBackgroundPressed: Color
    var primaryBackgroundDisabled: Color
    var primaryText: Color
    var primaryTextDisabled: Color

    // Secondary Button
    var secondaryBackground: Color
    var secondaryBackgroundPressed: Color
    var secondaryBorder: Color
    var secondaryText: Color

    // Destructive Button
    var destructiveBackground: Color
    var destructiveText: Color

    // Ghost Button
    var ghostText: Color
    var ghostTextPressed: Color
}
```

### 4.2 Card Tokens

```swift
struct CardTokens {
    var background: Color
    var backgroundElevated: Color
    var backgroundSelected: Color
    var border: Color
    var borderSelected: Color
    var shadow: Color
    var shadowIntensity: Double
}
```

### 4.3 Input Tokens

```swift
struct InputTokens {
    var background: Color
    var backgroundFocused: Color
    var border: Color
    var borderFocused: Color
    var borderError: Color
    var placeholder: Color
    var text: Color
}
```

### 4.4 Avatar Tokens (Child Identity)

```swift
struct AvatarTokens {
    let childColor: Color  // From ColorTag

    // These are DERIVED from childColor + appearance
    var circleFill: Color          // The avatar circle
    var circleStroke: Color        // Avatar ring/border
    var initialsText: Color        // Text inside avatar (ALWAYS contrast-safe)
    var glowEffect: Color          // Shadow/glow
    var badgeBackground: Color     // Achievement badge bg

    init(childColor: Color, appearance: Appearance) {
        self.childColor = childColor
        self.circleFill = childColor
        self.circleStroke = childColor.opacity(appearance == .dark ? 0.8 : 0.6)
        // CRITICAL: initials text is ALWAYS white or dark based on color luminance
        self.initialsText = childColor.contrastingTextColor
        self.glowEffect = childColor.opacity(appearance == .dark ? 0.4 : 0.25)
        self.badgeBackground = childColor.opacity(appearance == .dark ? 0.2 : 0.15)
    }
}
```

---

## 5. Architecture Implementation

### 5.1 Token Provider Protocol

```swift
/// Single source of truth for all design tokens
@MainActor
protocol TokenProvider: ObservableObject {
    // Configuration
    var appearance: Appearance { get set }
    var themePack: ThemePack { get set }

    // Semantic tokens
    var semantic: SemanticTokens { get }

    // Component tokens
    var button: ButtonTokens { get }
    var card: CardTokens { get }
    var input: InputTokens { get }

    // Child-specific tokens (computed on demand)
    func avatar(for childColor: Color) -> AvatarTokens
}
```

### 5.2 Concrete Implementation

```swift
@MainActor
final class DesignTokens: TokenProvider, ObservableObject {
    @Published var appearance: Appearance
    @Published var themePack: ThemePack

    // Cached semantic resolver
    private var resolver: SemanticTokenResolver {
        SemanticTokenResolver(appearance: appearance, themePack: themePack)
    }

    var semantic: SemanticTokens { resolver }

    var button: ButtonTokens {
        ButtonTokens(
            primaryBackground: resolver.accentPrimary,
            primaryBackgroundPressed: resolver.accentPrimary.opacity(0.9),
            primaryBackgroundDisabled: resolver.accentPrimary.opacity(0.5),
            primaryText: resolver.textOnPrimary,
            primaryTextDisabled: resolver.textOnPrimary.opacity(0.7),
            // ...
        )
    }

    func avatar(for childColor: Color) -> AvatarTokens {
        AvatarTokens(childColor: childColor, appearance: appearance)
    }
}
```

### 5.3 Environment Injection

```swift
// Environment key
private struct TokenProviderKey: EnvironmentKey {
    static let defaultValue: TokenProvider = DesignTokens()
}

extension EnvironmentValues {
    var tokens: TokenProvider {
        get { self[TokenProviderKey.self] }
        set { self[TokenProviderKey.self] = newValue }
    }
}

// Usage in views
struct MyView: View {
    @Environment(\.tokens) private var tokens

    var body: some View {
        Text("Hello")
            .foregroundColor(tokens.semantic.textPrimary)
            .background(tokens.semantic.bgSurface)
    }
}
```

---

## 6. Migration Strategy

### 6.1 Phase 1: Foundation (Week 1)

1. Create `Primitives.swift` with all raw color definitions
2. Create `SemanticTokens.swift` with protocol and resolver
3. Create `DesignTokens.swift` as the provider
4. Add environment injection
5. Update `ThemeProvider` to conform to `TokenProvider`

### 6.2 Phase 2: Core Components (Week 2)

1. Update `ElevatedCard` to use card tokens
2. Update `Buttons.swift` to use button tokens
3. Update `AppTypography` to use text tokens
4. Create `AvatarView` component using avatar tokens

### 6.3 Phase 3: Screen Migration (Week 3-4)

Priority order based on audit:
1. `KidView.swift` - Critical dark mode issues
2. `TodayView.swift` - Most visible screen
3. `InsightsView.swift` - Child colors as text
4. `SettingsView.swift` - 68 hardcoded refs
5. `RewardsView.swift` - Child colors + system colors

### 6.4 Phase 4: Remaining Views (Week 5-6)

All remaining views, starting with highest ref count.

---

## 7. Compatibility with Existing System

### 7.1 ThemeProvider Bridge

The existing `ThemeProvider` class will be updated to implement `TokenProvider`:

```swift
@MainActor
final class ThemeProvider: TokenProvider, ObservableObject {
    // EXISTING properties (kept for backward compatibility)
    @Published var currentTheme: AppTheme
    @Published var colorScheme: ColorScheme

    // NEW: Computed appearance
    var appearance: Appearance {
        get { colorScheme == .dark ? .dark : .light }
        set { colorScheme = newValue == .dark ? .dark : .light }
    }

    // NEW: Computed themePack
    var themePack: ThemePack {
        ThemePack(from: currentTheme)
    }

    // NEW: Semantic tokens
    var semantic: SemanticTokens {
        SemanticTokenResolver(appearance: appearance, themePack: themePack)
    }

    // EXISTING semantic colors become computed from tokens
    var primaryText: Color { semantic.textPrimary }
    var secondaryText: Color { semantic.textSecondary }
    var backgroundColor: Color { semantic.bgApp }
    // ...
}
```

### 7.2 Deprecation Path

```swift
extension ThemeProvider {
    // Mark old properties as deprecated
    @available(*, deprecated, renamed: "semantic.textPrimary")
    var primaryText: Color { semantic.textPrimary }

    @available(*, deprecated, renamed: "semantic.accentPrimary")
    var accentColor: Color { semantic.accentPrimary }
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

```swift
func testLightModeTextContrast() {
    let tokens = DesignTokens(appearance: .light)
    let contrast = tokens.semantic.textPrimary.contrastRatio(with: tokens.semantic.bgApp)
    XCTAssertGreaterThanOrEqual(contrast, 4.5) // WCAG AA
}

func testDarkModeTextContrast() {
    let tokens = DesignTokens(appearance: .dark)
    let contrast = tokens.semantic.textPrimary.contrastRatio(with: tokens.semantic.bgApp)
    XCTAssertGreaterThanOrEqual(contrast, 4.5) // WCAG AA
}

func testAvatarTextContrastAllColors() {
    for childColor in Primitives.ChildColors.allCases {
        let avatar = AvatarTokens(childColor: childColor, appearance: .light)
        let contrast = avatar.initialsText.contrastRatio(with: avatar.circleFill)
        XCTAssertGreaterThanOrEqual(contrast, 4.5)
    }
}
```

### 8.2 Snapshot Tests

```swift
func testAllThemesLightMode() {
    for theme in ThemePack.allCases {
        let view = TestView().environment(\.tokens, DesignTokens(appearance: .light, themePack: theme))
        assertSnapshot(matching: view, as: .image, named: "light-\(theme.rawValue)")
    }
}

func testAllThemesDarkMode() {
    for theme in ThemePack.allCases {
        let view = TestView().environment(\.tokens, DesignTokens(appearance: .dark, themePack: theme))
        assertSnapshot(matching: view, as: .image, named: "dark-\(theme.rawValue)")
    }
}
```

---

## 9. File Structure

```
TinyWins/
├── Core/
│   └── Tokens/
│       ├── Primitives.swift           # Raw hex values
│       ├── SemanticTokens.swift       # Role-based tokens
│       ├── ComponentTokens.swift      # UI component tokens
│       ├── DesignTokens.swift         # Main provider
│       └── TokenExtensions.swift      # Color utilities (contrast, etc.)
├── ThemeSystem.swift                  # Updated with TokenProvider conformance
└── Views/Components/
    └── ThemeEnvironment.swift         # Updated environment injection
```

---

## 10. Success Criteria

### 10.1 Zero Raw Colors in Views

After migration, `grep` for these patterns should return 0 results in Views/:
- `Color(red:`
- `Color(hex:`
- `.foregroundColor(.white)`
- `.foregroundColor(.black)`
- `.foregroundColor(.primary)`
- `.foregroundColor(.secondary)`
- `Color(.system`

### 10.2 WCAG AA Compliance

All text/background combinations must meet 4.5:1 contrast ratio for normal text.

### 10.3 Theme Independence

Changing `appearance` (light/dark) should work correctly regardless of `themePack`.
Changing `themePack` should only affect accent colors, not legibility.

### 10.4 Child Color Safety

Child avatar colors must NEVER be used for typography. Only for:
- Avatar circle fill
- Avatar ring/border
- Badge backgrounds
- Decorative accents

---

**Architecture Design Complete. Proceed to Deliverable C: Implementation.**
