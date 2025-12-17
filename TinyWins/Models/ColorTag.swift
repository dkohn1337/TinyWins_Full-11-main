import SwiftUI

enum ColorTag: String, Codable, CaseIterable, Identifiable {
    // Row 1: Primary kid-friendly colors
    case blue
    case green
    case orange
    case purple
    // Row 2: Accent colors (distinct from row 1)
    case pink
    case teal
    case coral
    case yellow

    // Legacy support - maps old "red" to "coral"
    case red

    var id: String { rawValue }

    /// Custom colors designed for visual distinction and kid-friendliness
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.26, green: 0.52, blue: 0.96)     // Friendly blue
        case .green: return Color(red: 0.30, green: 0.78, blue: 0.47)    // Fresh green
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.0)     // Warm orange
        case .purple: return Color(red: 0.62, green: 0.32, blue: 0.88)   // Vibrant purple
        case .pink: return Color(red: 0.96, green: 0.36, blue: 0.55)     // Soft pink (distinct from coral)
        case .teal: return Color(red: 0.0, green: 0.75, blue: 0.78)      // Fresh teal
        case .coral, .red: return Color(red: 1.0, green: 0.42, blue: 0.42)  // Warm coral (red maps here for migration)
        case .yellow: return Color(red: 1.0, green: 0.80, blue: 0.0)     // Sunny yellow
        }
    }

    var displayName: String {
        // Show "Coral" for both coral and legacy red
        if self == .red { return "Coral" }
        return rawValue.capitalized
    }

    /// Colors available for selection in UI (excludes legacy red)
    static var selectableColors: [ColorTag] {
        [.blue, .green, .orange, .purple, .pink, .teal, .coral, .yellow]
    }
}
