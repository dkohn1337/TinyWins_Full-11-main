import SwiftUI

// MARK: - Goal Size Helper
// Centralized logic for goal size labels, emojis, and helper text
// Ensures consistency across onboarding, reward creation, and insights

/// Represents a goal size category with associated metadata
enum GoalSizeCategory: String, CaseIterable, Identifiable {
    case quickWin = "Quick Win"
    case goodGoal = "Good Goal"
    case bigGoal = "Big Goal"
    case epicGoal = "Epic Goal"

    var id: String { rawValue }

    /// The emoji representing this goal size
    var emoji: String {
        switch self {
        case .quickWin: return "🎯"
        case .goodGoal: return "⭐"
        case .bigGoal: return "🌟"
        case .epicGoal: return "🏆"
        }
    }

    /// Warm, encouraging helper text for parents
    var helperText: String {
        switch self {
        case .quickWin: return "Perfect for building momentum"
        case .goodGoal: return "A week of great choices"
        case .bigGoal: return "Something worth working toward"
        case .epicGoal: return "A dream worth the journey"
        }
    }

    /// Typical timeframe description
    var timeframeHint: String {
        switch self {
        case .quickWin: return "1-3 days"
        case .goodGoal: return "4-10 days"
        case .bigGoal: return "2-3 weeks"
        case .epicGoal: return "3-4+ weeks"
        }
    }

    /// Star range for this category
    var starRange: ClosedRange<Int> {
        switch self {
        case .quickWin: return 1...5
        case .goodGoal: return 6...15
        case .bigGoal: return 16...30
        case .epicGoal: return 31...50
        }
    }

    /// Default preset value for quick selection
    var presetValue: Int {
        switch self {
        case .quickWin: return 5
        case .goodGoal: return 15
        case .bigGoal: return 30
        case .epicGoal: return 50
        }
    }

    /// Color associated with this goal size (gradient feel)
    var color: Color {
        switch self {
        case .quickWin: return .green
        case .goodGoal: return .blue
        case .bigGoal: return .purple
        case .epicGoal: return .orange
        }
    }

    /// Accessibility label with full description
    var accessibilityLabel: String {
        "\(rawValue), \(starRange.lowerBound) to \(starRange.upperBound) stars, \(helperText)"
    }

    /// Initialize from a star count
    static func from(stars: Int) -> GoalSizeCategory {
        switch stars {
        case 1...5: return .quickWin
        case 6...15: return .goodGoal
        case 16...30: return .bigGoal
        default: return .epicGoal
        }
    }
}

// MARK: - Goal Size Configuration

/// Central configuration for goal size UI components
enum GoalSizeConfig {
    /// Minimum stars allowed (supports toddlers, first goals)
    static let minStars = 1

    /// Maximum stars allowed
    static let maxStars = 50

    /// All preset options for quick selection
    static let presets: [GoalSizeCategory] = GoalSizeCategory.allCases

    /// Get dynamic label for any star count
    static func label(for stars: Int) -> String {
        GoalSizeCategory.from(stars: stars).rawValue
    }

    /// Get dynamic emoji for any star count
    static func emoji(for stars: Int) -> String {
        GoalSizeCategory.from(stars: stars).emoji
    }

    /// Get helper text for any star count
    static func helperText(for stars: Int) -> String {
        GoalSizeCategory.from(stars: stars).helperText
    }

    /// Get color for any star count
    static func color(for stars: Int) -> Color {
        GoalSizeCategory.from(stars: stars).color
    }
}

// MARK: - Timeframe Helper

/// Represents a timeframe category with warm, parent-friendly labels
enum TimeframeCategory: String, CaseIterable {
    case fewDays = "A few days"
    case aboutAWeek = "About a week"
    case coupleWeeks = "A couple weeks"
    case thisMonth = "This month"

    /// Day range for this category
    var dayRange: ClosedRange<Int> {
        switch self {
        case .fewDays: return 1...3
        case .aboutAWeek: return 4...7
        case .coupleWeeks: return 8...14
        case .thisMonth: return 15...30
        }
    }

    /// Default preset value
    var presetValue: Int {
        switch self {
        case .fewDays: return 3
        case .aboutAWeek: return 7
        case .coupleWeeks: return 14
        case .thisMonth: return 30
        }
    }

    /// Initialize from day count
    static func from(days: Int) -> TimeframeCategory {
        switch days {
        case 1...3: return .fewDays
        case 4...7: return .aboutAWeek
        case 8...14: return .coupleWeeks
        default: return .thisMonth
        }
    }

    /// Get label for any day count
    static func label(for days: Int) -> String {
        from(days: days).rawValue
    }
}

// MARK: - Goal Size Selector View

/// Reusable goal size selector with preset buttons and slider
struct GoalSizeSelector: View {
    @Binding var starCount: Int
    let childColor: Color
    var showPresets: Bool = true
    var showHelperText: Bool = true
    var onSelectionChanged: ((Int) -> Void)?

    @State private var selectedCategory: GoalSizeCategory?

    var body: some View {
        VStack(spacing: 20) {
            // Header with current value
            HStack {
                Text("Stars to earn")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text(GoalSizeConfig.emoji(for: starCount))
                        .font(.title3)
                    Text("\(starCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(childColor)
                }
            }

            // Preset buttons
            if showPresets {
                HStack(spacing: 8) {
                    ForEach(GoalSizeCategory.allCases) { category in
                        GoalPresetButton(
                            category: category,
                            isSelected: GoalSizeCategory.from(stars: starCount) == category,
                            childColor: childColor
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                starCount = category.presetValue
                                selectedCategory = category
                            }
                            HapticManager.shared.selection()
                            onSelectionChanged?(starCount)
                        }
                    }
                }
            }

            // Slider with labels
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(starCount) },
                        set: { newValue in
                            starCount = Int(newValue)
                            onSelectionChanged?(starCount)
                        }
                    ),
                    in: Double(GoalSizeConfig.minStars)...Double(GoalSizeConfig.maxStars),
                    step: 1
                )
                .tint(childColor)

                // Range labels with category indicators
                HStack {
                    Text("\(GoalSizeConfig.minStars)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Dynamic category label
                    Text(GoalSizeConfig.label(for: starCount))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(GoalSizeConfig.color(for: starCount))

                    Spacer()

                    Text("\(GoalSizeConfig.maxStars)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Helper text
            if showHelperText {
                Text(GoalSizeConfig.helperText(for: starCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(GoalSizeConfig.color(for: starCount).opacity(0.1))
                    )
                    .animation(.easeInOut(duration: 0.2), value: starCount)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stars to earn, currently \(starCount) stars, \(GoalSizeConfig.label(for: starCount))")
        .accessibilityHint(GoalSizeConfig.helperText(for: starCount))
    }
}

// MARK: - Goal Preset Button

/// Individual preset button for goal size selection
struct GoalPresetButton: View {
    let category: GoalSizeCategory
    let isSelected: Bool
    let childColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(category.emoji)
                    .font(.system(size: 20))

                Text(shortLabel)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? childColor : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? childColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? childColor.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.accessibilityLabel)
    }

    private var shortLabel: String {
        switch category {
        case .quickWin: return "Quick"
        case .goodGoal: return "Good"
        case .bigGoal: return "Big"
        case .epicGoal: return "Epic"
        }
    }
}

// MARK: - Timeframe Selector View

/// Reusable timeframe selector with warm labels
struct TimeframeSelector: View {
    @Binding var days: Int
    let childColor: Color
    var showHelperText: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            // Header with current value
            HStack {
                Text("Target timeframe")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                Text(daysLabel)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(days) },
                        set: { days = Int($0) }
                    ),
                    in: 1...30,
                    step: 1
                )
                .tint(childColor)

                // Labels
                HStack {
                    Text("1")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(TimeframeCategory.label(for: days))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(childColor)

                    Spacer()

                    Text("30")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var daysLabel: String {
        if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}

// MARK: - Previews

#Preview("Goal Size Selector") {
    VStack(spacing: 40) {
        GoalSizeSelector(
            starCount: .constant(10),
            childColor: .blue
        )

        GoalSizeSelector(
            starCount: .constant(30),
            childColor: .purple,
            showPresets: true
        )
    }
    .padding()
}

#Preview("Timeframe Selector") {
    TimeframeSelector(
        days: .constant(7),
        childColor: .blue
    )
    .padding()
}

#Preview("Preset Buttons") {
    HStack(spacing: 8) {
        ForEach(GoalSizeCategory.allCases) { category in
            GoalPresetButton(
                category: category,
                isSelected: category == .goodGoal,
                childColor: .purple
            ) {}
        }
    }
    .padding()
}
