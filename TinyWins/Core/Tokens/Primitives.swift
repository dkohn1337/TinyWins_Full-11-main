import SwiftUI

// MARK: - Color Extension for Hex Initialization

extension Color {
    /// Initialize a Color from a hex string (without #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Primitive Token Definitions

/// Raw color values - the single source of truth for all colors in the app.
/// These should NEVER be used directly in views. Use SemanticTokens instead.
enum Primitives {

    // MARK: - Neutral Scale (Grays)

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
        static let gray950 = Color(hex: "030712")
        static let black = Color(hex: "000000")
    }

    // MARK: - Theme Pack Palettes

    enum Classic {
        static let primary = Color(hex: "7C3AED")    // Violet-600
        static let primaryLight = Color(hex: "A78BFA") // Violet-400
        static let primaryDark = Color(hex: "5B21B6")  // Violet-800
        static let secondary = Color(hex: "8B5CF6")    // Violet-500
        static let accent = Color(hex: "DDD6FE")       // Violet-200
    }

    enum Ocean {
        static let primary = Color(hex: "0891B2")    // Cyan-600
        static let primaryLight = Color(hex: "22D3EE") // Cyan-400
        static let primaryDark = Color(hex: "0E7490")  // Cyan-700
        static let secondary = Color(hex: "06B6D4")    // Cyan-500
        static let accent = Color(hex: "A5F3FC")       // Cyan-200
    }

    enum Sunset {
        static let primary = Color(hex: "EA580C")    // Orange-600
        static let primaryLight = Color(hex: "FB923C") // Orange-400
        static let primaryDark = Color(hex: "C2410C")  // Orange-700
        static let secondary = Color(hex: "F97316")    // Orange-500
        static let accent = Color(hex: "FED7AA")       // Orange-200
    }

    enum Forest {
        static let primary = Color(hex: "059669")    // Emerald-600
        static let primaryLight = Color(hex: "34D399") // Emerald-400
        static let primaryDark = Color(hex: "047857")  // Emerald-700
        static let secondary = Color(hex: "10B981")    // Emerald-500
        static let accent = Color(hex: "A7F3D0")       // Emerald-200
    }

    enum Midnight {
        static let primary = Color(hex: "4F46E5")    // Indigo-600
        static let primaryLight = Color(hex: "818CF8") // Indigo-400
        static let primaryDark = Color(hex: "3730A3")  // Indigo-800
        static let secondary = Color(hex: "6366F1")    // Indigo-500
        static let accent = Color(hex: "C7D2FE")       // Indigo-200
    }

    enum Aurora {
        static let primary = Color(hex: "8B5CF6")    // Violet-500
        static let primaryLight = Color(hex: "A78BFA") // Violet-400
        static let primaryDark = Color(hex: "7C3AED")  // Violet-600
        static let secondary = Color(hex: "22D3EE")    // Cyan-400
        static let accent = Color(hex: "E879F9")       // Fuchsia-400
    }

    enum Rosegold {
        static let primary = Color(hex: "DB2777")    // Pink-600
        static let primaryLight = Color(hex: "F472B6") // Pink-400
        static let primaryDark = Color(hex: "BE185D")  // Pink-700
        static let secondary = Color(hex: "EC4899")    // Pink-500
        static let accent = Color(hex: "FBCFE8")       // Pink-200
    }

    enum Lavender {
        static let primary = Color(hex: "9333EA")    // Purple-600
        static let primaryLight = Color(hex: "C084FC") // Purple-400
        static let primaryDark = Color(hex: "7E22CE")  // Purple-700
        static let secondary = Color(hex: "A855F7")    // Purple-500
        static let accent = Color(hex: "E9D5FF")       // Purple-200
    }

    enum Mint {
        static let primary = Color(hex: "0D9488")    // Teal-600
        static let primaryLight = Color(hex: "2DD4BF") // Teal-400
        static let primaryDark = Color(hex: "0F766E")  // Teal-700
        static let secondary = Color(hex: "14B8A6")    // Teal-500
        static let accent = Color(hex: "99F6E4")       // Teal-200
    }

    enum Slate {
        static let primary = Color(hex: "475569")    // Slate-600
        static let primaryLight = Color(hex: "94A3B8") // Slate-400
        static let primaryDark = Color(hex: "334155")  // Slate-700
        static let secondary = Color(hex: "64748B")    // Slate-500
        static let accent = Color(hex: "CBD5E1")       // Slate-300
    }

    enum Champagne {
        static let primary = Color(hex: "D97706")    // Amber-600
        static let primaryLight = Color(hex: "FBBF24") // Amber-400
        static let primaryDark = Color(hex: "B45309")  // Amber-700
        static let secondary = Color(hex: "F59E0B")    // Amber-500
        static let accent = Color(hex: "FDE68A")       // Amber-200
    }

    enum Nordic {
        static let primary = Color(hex: "0284C7")    // Sky-600
        static let primaryLight = Color(hex: "38BDF8") // Sky-400
        static let primaryDark = Color(hex: "0369A1")  // Sky-700
        static let secondary = Color(hex: "0EA5E9")    // Sky-500
        static let accent = Color(hex: "BAE6FD")       // Sky-200
    }

    // MARK: - Semantic Colors (Constant Across Themes)

    enum Semantic {
        // Success (positive behaviors, wins)
        static let success50 = Color(hex: "F0FDF4")
        static let success100 = Color(hex: "DCFCE7")
        static let success500 = Color(hex: "22C55E")
        static let success600 = Color(hex: "16A34A")
        static let success700 = Color(hex: "15803D")

        // Warning (challenges, attention needed)
        static let warning50 = Color(hex: "FFFBEB")
        static let warning100 = Color(hex: "FEF3C7")
        static let warning500 = Color(hex: "F59E0B")
        static let warning600 = Color(hex: "D97706")
        static let warning700 = Color(hex: "B45309")

        // Error (mistakes, negative states)
        static let error50 = Color(hex: "FEF2F2")
        static let error100 = Color(hex: "FEE2E2")
        static let error500 = Color(hex: "EF4444")
        static let error600 = Color(hex: "DC2626")
        static let error700 = Color(hex: "B91C1C")

        // Info (hints, tips, informational)
        static let info50 = Color(hex: "EFF6FF")
        static let info100 = Color(hex: "DBEAFE")
        static let info500 = Color(hex: "3B82F6")
        static let info600 = Color(hex: "2563EB")
        static let info700 = Color(hex: "1D4ED8")

        // Stars (rewards, points)
        static let starPrimary = Color(hex: "FBBF24")   // Amber-400
        static let starSecondary = Color(hex: "F59E0B") // Amber-500
        static let starGlow = Color(hex: "FDE68A")      // Amber-200

        // Routines
        static let routine = Color(hex: "8B5CF6")       // Violet-500
        static let routineLight = Color(hex: "C4B5FD")  // Violet-300

        // Plus/Premium
        static let plus = Color(hex: "7C3AED")          // Violet-600
        static let plusLight = Color(hex: "A78BFA")     // Violet-400
    }

    // MARK: - Child Identity Colors (Avatar Only)

    /// These colors are ONLY for avatar circles, badges, and decorations.
    /// They should NEVER be used for text foreground colors.
    enum ChildColors: String, CaseIterable {
        case blue
        case green
        case orange
        case purple
        case pink
        case teal
        case coral
        case yellow

        var color: Color {
            switch self {
            case .blue: return Color(hex: "4285F4")     // Google Blue
            case .green: return Color(hex: "4DC779")    // Fresh Green
            case .orange: return Color(hex: "FF9400")   // Warm Orange
            case .purple: return Color(hex: "9E52E0")   // Vibrant Purple
            case .pink: return Color(hex: "F55C8D")     // Soft Pink
            case .teal: return Color(hex: "00BFC7")     // Fresh Teal
            case .coral: return Color(hex: "FF6B6B")    // Warm Coral
            case .yellow: return Color(hex: "FFCC00")   // Sunny Yellow
            }
        }

        /// Contrast-safe text color for this background
        /// Returns white or dark gray based on luminance
        var contrastingTextColor: Color {
            switch self {
            case .yellow, .coral, .orange, .pink, .green, .teal:
                // Light colors need dark text for contrast
                return Primitives.Neutral.gray900
            case .blue, .purple:
                // Dark colors can use white text
                return Primitives.Neutral.white
            }
        }

        /// Slightly darker variant for pressed/hover states
        var darkerVariant: Color {
            color.opacity(0.85)
        }

        /// Light background variant for badges, chips
        var lightBackground: Color {
            color.opacity(0.15)
        }
    }
}

// MARK: - Color Luminance and Contrast Utilities

extension Color {
    /// Calculate relative luminance (WCAG 2.1 formula)
    var luminance: Double {
        // Convert to UIColor to get RGB components
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Apply gamma correction
        func adjust(_ component: CGFloat) -> Double {
            let c = Double(component)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        let r = adjust(red)
        let g = adjust(green)
        let b = adjust(blue)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Calculate contrast ratio between two colors (WCAG 2.1)
    func contrastRatio(with other: Color) -> Double {
        let l1 = max(luminance, other.luminance)
        let l2 = min(luminance, other.luminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }

    /// Returns a contrasting text color (white or black) based on luminance
    var contrastingTextColor: Color {
        luminance > 0.179 ? Primitives.Neutral.gray900 : Primitives.Neutral.white
    }

    /// Check if this color meets WCAG AA contrast with another color
    func meetsWCAGAA(with other: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(with: other)
        return isLargeText ? ratio >= 3.0 : ratio >= 4.5
    }
}
