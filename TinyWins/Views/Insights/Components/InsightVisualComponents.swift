import SwiftUI

// MARK: - WeekActivityDots

/// 7-day horizontal row showing daily activity intensity.
/// Used in free tier to give visual proof of logging activity.
struct WeekActivityDots: View {
    @Environment(\.themeProvider) private var theme

    let dailyData: [InsightGenerationUseCase.DailyActivityData]
    var accentColor: Color = .green

    private let calendar = Calendar.current
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Normalize daily data to last 7 days starting from Monday
    private var weekData: [(date: Date, positive: Int, negative: Int)] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // Calculate days since Monday (weekday 2 in Gregorian)
        let daysSinceMonday = (weekday + 5) % 7

        var result: [(date: Date, positive: Int, negative: Int)] = []

        for dayOffset in 0..<7 {
            let targetDate = calendar.date(
                byAdding: .day,
                value: dayOffset - daysSinceMonday,
                to: today
            ) ?? today

            // Find matching data
            if let match = dailyData.first(where: {
                calendar.isDate($0.date, inSameDayAs: targetDate)
            }) {
                result.append((targetDate, match.positive, match.negative))
            } else {
                result.append((targetDate, 0, 0))
            }
        }

        return result
    }

    private var maxActivity: Int {
        let maxVal = weekData.map { $0.positive + $0.negative }.max() ?? 1
        return max(maxVal, 1)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                VStack(spacing: 4) {
                    // Activity dot
                    activityDot(
                        positive: data.positive,
                        negative: data.negative,
                        isToday: calendar.isDateInToday(data.date)
                    )

                    // Day label
                    Text(dayLabels[index])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func activityDot(positive: Int, negative: Int, isToday: Bool) -> some View {
        let total = positive + negative
        let intensity = total > 0 ? min(Double(total) / Double(maxActivity), 1.0) : 0

        return ZStack {
            // Background/outline
            Circle()
                .stroke(
                    total == 0 ? theme.secondaryText.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
                .frame(width: 14, height: 14)

            // Filled dot based on activity
            if total > 0 {
                Circle()
                    .fill(dotColor(positive: positive, negative: negative).opacity(0.3 + intensity * 0.7))
                    .frame(width: 14, height: 14)
            }

            // Today highlight ring
            if isToday {
                Circle()
                    .stroke(theme.accentColor, lineWidth: 2)
                    .frame(width: 18, height: 18)
            }
        }
        .frame(width: 20, height: 20)
    }

    private func dotColor(positive: Int, negative: Int) -> Color {
        if positive > negative {
            return theme.positiveColor
        } else if negative > positive {
            return theme.challengeColor
        } else {
            return accentColor
        }
    }

    private var accessibilityDescription: String {
        let activeDays = weekData.filter { $0.positive + $0.negative > 0 }.count
        return "\(activeDays) active days this week"
    }
}

// MARK: - TrendArrowBadge

/// Compact trend indicator with arrow and optional percentage.
struct TrendArrowBadge: View {
    @Environment(\.themeProvider) private var theme

    enum Trend {
        case up
        case steady
        case down

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .steady: return "arrow.right"
            case .down: return "arrow.down.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .steady: return .blue
            case .down: return .orange
            }
        }

        var label: String {
            switch self {
            case .up: return "Trending up"
            case .steady: return "Steady"
            case .down: return "Trending down"
            }
        }
    }

    let trend: Trend
    var percentChange: Double? = nil
    var showLabel: Bool = true
    var compact: Bool = false

    /// Initialize from a percentage change value
    init(percentChange: Double, showLabel: Bool = true, compact: Bool = false) {
        self.percentChange = percentChange
        self.showLabel = showLabel
        self.compact = compact

        if percentChange > 5 {
            self.trend = .up
        } else if percentChange < -5 {
            self.trend = .down
        } else {
            self.trend = .steady
        }
    }

    /// Initialize with explicit trend
    init(trend: Trend, percentChange: Double? = nil, showLabel: Bool = true, compact: Bool = false) {
        self.trend = trend
        self.percentChange = percentChange
        self.showLabel = showLabel
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: compact ? 2 : 4) {
            Image(systemName: trend.icon)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
                .foregroundColor(trend.color)

            if let pct = percentChange, pct != 0 {
                Text(pct >= 0 ? "+\(Int(pct))%" : "\(Int(pct))%")
                    .font(.system(size: compact ? 10 : 12, weight: .semibold))
                    .foregroundColor(trend.color)
            } else if showLabel {
                Text(trend.label)
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
                    .foregroundColor(trend.color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        if let pct = percentChange {
            return "\(trend.label), \(Int(abs(pct))) percent \(pct >= 0 ? "increase" : "decrease")"
        }
        return trend.label
    }
}

// MARK: - BehaviorPillStack

/// Horizontal scrollable list of top behaviors as pills.
struct BehaviorPillStack: View {
    @Environment(\.themeProvider) private var theme

    struct BehaviorItem: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
        let isPositive: Bool
    }

    let behaviors: [BehaviorItem]
    var maxVisible: Int = 3
    var showTruncationHint: Bool = true

    private var visibleBehaviors: [BehaviorItem] {
        Array(behaviors.prefix(maxVisible))
    }

    private var hasMore: Bool {
        behaviors.count > maxVisible
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleBehaviors) { behavior in
                    behaviorPill(behavior)
                }

                if hasMore && showTruncationHint {
                    truncationPill
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func behaviorPill(_ behavior: BehaviorItem) -> some View {
        let color = behavior.isPositive ? theme.positiveColor : theme.challengeColor

        return HStack(spacing: 4) {
            Image(systemName: behavior.isPositive ? "star.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(behavior.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            Text("\(behavior.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }

    private var truncationPill: some View {
        HStack(spacing: 2) {
            Text("+\(behaviors.count - maxVisible)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.secondaryText)
            Image(systemName: "ellipsis")
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.secondaryText.opacity(0.1))
        )
    }

    private var accessibilityDescription: String {
        let topBehavior = behaviors.first?.name ?? "none"
        return "Top behaviors: \(topBehavior) and \(behaviors.count - 1) others"
    }
}

// MARK: - MiniBarChart

/// Compact 4-week trend visualization showing relative activity levels.
struct MiniBarChart: View {
    @Environment(\.themeProvider) private var theme

    let weeklyTotals: [Int]
    var accentColor: Color = .green
    var height: CGFloat = 24
    var barWidth: CGFloat = 10
    var spacing: CGFloat = 4

    private var maxValue: Int {
        max(weeklyTotals.max() ?? 1, 1)
    }

    private var normalizedHeights: [CGFloat] {
        weeklyTotals.map { value in
            CGFloat(value) / CGFloat(maxValue) * height
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(normalizedHeights.enumerated()), id: \.offset) { index, barHeight in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: barWidth, height: max(barHeight, 2))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func barColor(for index: Int) -> Color {
        // Most recent week (last index) is fully opaque, others fade
        let isLatest = index == weeklyTotals.count - 1
        return isLatest ? accentColor : accentColor.opacity(0.4 + Double(index) * 0.15)
    }

    private var accessibilityDescription: String {
        guard weeklyTotals.count >= 2 else { return "Activity chart" }
        let latest = weeklyTotals.last ?? 0
        let previous = weeklyTotals.dropLast().last ?? 0
        let trend = latest > previous ? "increasing" : (latest < previous ? "decreasing" : "steady")
        return "Activity \(trend) over \(weeklyTotals.count) weeks"
    }
}

// MARK: - ReflectionCorrelationCard

/// Shows the correlation between parent reflection and child positive moments.
struct ReflectionCorrelationCard: View {
    @Environment(\.themeProvider) private var theme

    let percentageMorePositive: Double
    let daysAnalyzed: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("On days you reflect, kids have")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)

                HStack(spacing: 4) {
                    Text("\(Int(percentageMorePositive))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.positiveColor)
                    Text("more positive moments")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.primaryText)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("On days you reflect, kids have \(Int(percentageMorePositive)) percent more positive moments")
    }
}

// MARK: - EnhancedMicroHintChip

/// Enhanced version of the micro hint chip with optional trend indicator.
struct EnhancedMicroHintChip: View {
    @Environment(\.themeProvider) private var theme

    let icon: String
    let label: String
    let sublabel: String
    let color: Color
    var trend: TrendArrowBadge.Trend? = nil
    var percentChange: Double? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.primaryText)

                    if let trend = trend {
                        TrendArrowBadge(
                            trend: trend,
                            percentChange: percentChange,
                            showLabel: false,
                            compact: true
                        )
                    }
                }

                Text(sublabel)
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Previews

#Preview("Week Activity Dots") {
    let calendar = Calendar.current
    let sampleData: [InsightGenerationUseCase.DailyActivityData] = (0..<7).map { offset in
        let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
        return InsightGenerationUseCase.DailyActivityData(
            date: date,
            positive: Int.random(in: 0...5),
            negative: Int.random(in: 0...2)
        )
    }

    VStack(spacing: 20) {
        WeekActivityDots(dailyData: sampleData)
        WeekActivityDots(dailyData: sampleData, accentColor: .purple)
    }
    .padding()
    .withThemeProvider(ThemeProvider())
}

#Preview("Trend Arrow Badge") {
    VStack(spacing: 16) {
        TrendArrowBadge(percentChange: 23)
        TrendArrowBadge(percentChange: -12)
        TrendArrowBadge(percentChange: 2)
        TrendArrowBadge(trend: .up, showLabel: true)
        TrendArrowBadge(percentChange: 45, compact: true)
    }
    .padding()
    .withThemeProvider(ThemeProvider())
}

#Preview("Behavior Pill Stack") {
    let behaviors: [BehaviorPillStack.BehaviorItem] = [
        .init(name: "Sharing", count: 5, isPositive: true),
        .init(name: "Kindness", count: 3, isPositive: true),
        .init(name: "Patience", count: 2, isPositive: true),
        .init(name: "Listening", count: 4, isPositive: false),
        .init(name: "Tantrums", count: 2, isPositive: false)
    ]

    VStack(spacing: 20) {
        BehaviorPillStack(behaviors: behaviors, maxVisible: 3)
        BehaviorPillStack(behaviors: behaviors, maxVisible: 5, showTruncationHint: false)
    }
    .padding()
    .withThemeProvider(ThemeProvider())
}

#Preview("Mini Bar Chart") {
    VStack(spacing: 20) {
        MiniBarChart(weeklyTotals: [12, 8, 15, 20])
        MiniBarChart(weeklyTotals: [5, 10, 8, 12], accentColor: .purple)
        MiniBarChart(weeklyTotals: [20, 15, 10, 5], accentColor: .orange)
    }
    .padding()
    .withThemeProvider(ThemeProvider())
}

#Preview("Reflection Correlation Card") {
    ReflectionCorrelationCard(percentageMorePositive: 23, daysAnalyzed: 30)
        .padding()
        .withThemeProvider(ThemeProvider())
}

#Preview("Enhanced Micro Hint Chip") {
    VStack(spacing: 12) {
        EnhancedMicroHintChip(
            icon: "star.fill",
            label: "15 wins",
            sublabel: "this week",
            color: .green,
            trend: .up,
            percentChange: 12
        )

        EnhancedMicroHintChip(
            icon: "calendar",
            label: "5 active days",
            sublabel: "this week",
            color: .blue
        )
    }
    .padding()
    .withThemeProvider(ThemeProvider())
}
