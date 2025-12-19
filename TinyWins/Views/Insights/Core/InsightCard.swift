import SwiftUI

// MARK: - Coach Insight Model

/// Represents a single insight from the Coach system.
/// Structure: Interpretation (what we see) → Try (action) → optional visual
struct CoachInsight: Identifiable, Equatable {
    let id: UUID
    let category: InsightCategory
    let headline: String          // e.g., "Patience is building"
    let interpretation: String    // e.g., "You logged 3 more calm moments this week than last"
    let tryAction: String         // e.g., "Try: Celebrate out loud when you notice patience"
    let visualData: InsightVisualData?
    let priority: InsightPriority

    enum InsightCategory: String, CaseIterable {
        case momentum       // Trends and trajectory
        case strength       // Character strengths emerging
        case pattern        // Time/day patterns
        case balance        // Win/challenge ratio
        case connection     // Parent engagement correlation
        case milestone      // Achievement unlocked

        var icon: String {
            switch self {
            case .momentum: return "arrow.up.right"
            case .strength: return "star.fill"
            case .pattern: return "clock.fill"
            case .balance: return "scale.3d"
            case .connection: return "heart.fill"
            case .milestone: return "trophy.fill"
            }
        }

        var color: Color {
            switch self {
            case .momentum: return .blue
            case .strength: return .purple
            case .pattern: return .orange
            case .balance: return .green
            case .connection: return .pink
            case .milestone: return .yellow
            }
        }
    }

    enum InsightPriority: Int, Comparable {
        case featured = 0   // Top card, highlighted
        case standard = 1   // Regular cards
        case secondary = 2  // Lower priority

        static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Insight Visual Data

/// Optional visual data to accompany an insight
enum InsightVisualData: Equatable {
    case weekDots([DayActivity])           // 7-day activity dots
    case miniChart([Int])                  // Simple bar chart (4 weeks)
    case trendArrow(TrendDirection, Double?) // Arrow with optional percentage
    case progressRing(Double)              // 0-1 progress
    case behaviorPills([BehaviorPillData]) // (name, count, isPositive)

    struct DayActivity: Equatable {
        let dayIndex: Int  // 0 = Monday
        let intensity: Double // 0-1
        let isToday: Bool
    }

    struct BehaviorPillData: Equatable {
        let name: String
        let count: Int
        let isPositive: Bool
    }

    enum TrendDirection: Equatable {
        case up, steady, down

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
    }
}

// MARK: - Insight Card View

/// Action-oriented insight card with Interpretation → Try → Visual structure
struct InsightCard: View {
    @Environment(\.theme) private var theme

    let insight: CoachInsight
    let isFeatured: Bool

    init(insight: CoachInsight, isFeatured: Bool = false) {
        self.insight = insight
        self.isFeatured = isFeatured
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge + headline
            headerSection

            // Interpretation text
            interpretationSection

            // Visual data (if present)
            if let visualData = insight.visualData {
                visualSection(visualData)
            }

            // Try action
            tryActionSection
        }
        .padding(16)
        .background(cardBackground)
        .overlay(cardBorder)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            // Category icon
            Image(systemName: insight.category.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(insight.category.color)
                .frame(width: 24, height: 24)
                .background(insight.category.color.opacity(0.15))
                .clipShape(Circle())

            // Headline
            Text(insight.headline)
                .font(.system(size: isFeatured ? 17 : 15, weight: .semibold))
                .foregroundColor(theme.textPrimary)

            Spacer()
        }
    }

    // MARK: - Interpretation

    private var interpretationSection: some View {
        Text(insight.interpretation)
            .font(.system(size: 14))
            .foregroundColor(theme.textSecondary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Visual Section

    @ViewBuilder
    private func visualSection(_ data: InsightVisualData) -> some View {
        switch data {
        case .weekDots(let days):
            weekDotsView(days)

        case .miniChart(let values):
            miniChartView(values)

        case .trendArrow(let direction, let percentage):
            trendArrowView(direction, percentage)

        case .progressRing(let progress):
            progressRingView(progress)

        case .behaviorPills(let behaviors):
            behaviorPillsView(behaviors)
        }
    }

    private func weekDotsView(_ days: [InsightVisualData.DayActivity]) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let day = days.first { $0.dayIndex == index }
                let intensity = day?.intensity ?? 0
                let isToday = day?.isToday ?? false

                Circle()
                    .fill(intensity > 0 ? theme.accentPrimary.opacity(0.3 + intensity * 0.7) : theme.borderSoft)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isToday ? theme.accentPrimary : Color.clear, lineWidth: 2)
                    )
            }
        }
        .padding(.vertical, 4)
    }

    private func miniChartView(_ values: [Int]) -> some View {
        let maxValue = values.max() ?? 1

        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<values.count, id: \.self) { index in
                let value = values[index]
                let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) * 24 : 0

                RoundedRectangle(cornerRadius: 2)
                    .fill(index == values.count - 1 ? theme.accentPrimary : theme.accentPrimary.opacity(0.4))
                    .frame(width: 12, height: max(4, height))
            }
        }
        .frame(height: 24)
        .padding(.vertical, 4)
    }

    private func trendArrowView(_ direction: InsightVisualData.TrendDirection, _ percentage: Double?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: direction.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(direction.color)

            if let pct = percentage {
                Text("\(pct >= 0 ? "+" : "")\(Int(pct))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(direction.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(direction.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func progressRingView(_ progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(theme.borderSoft, lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(theme.accentPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textPrimary)
        }
        .frame(width: 40, height: 40)
    }

    private func behaviorPillsView(_ behaviors: [InsightVisualData.BehaviorPillData]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(0..<min(behaviors.count, 3), id: \.self) { index in
                    let pill = behaviors[index]

                    HStack(spacing: 4) {
                        Text(pill.name)
                            .font(.caption)
                        Text("\(pill.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(pill.isPositive ? theme.success : theme.danger)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((pill.isPositive ? theme.success : theme.danger).opacity(0.12))
                    )
                }
            }
        }
    }

    // MARK: - Try Action

    private var tryActionSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 13))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 2)

            Text(insight.tryAction)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.12),
                    Color.orange.opacity(0.06)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Card Styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(isFeatured ? insight.category.color.opacity(0.06) : theme.surface1)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .stroke(
                isFeatured ? insight.category.color.opacity(0.2) : theme.borderSoft,
                lineWidth: isFeatured ? 1.5 : 1
            )
    }

    private var accessibilityDescription: String {
        var description = "\(insight.headline). \(insight.interpretation)."
        description += " \(insight.tryAction)"
        return description
    }
}

// MARK: - Compact Insight Card

/// Smaller version for lists and grids
struct CompactInsightCard: View {
    @Environment(\.theme) private var theme

    let insight: CoachInsight

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: insight.category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(insight.category.color)
                .frame(width: 32, height: 32)
                .background(insight.category.color.opacity(0.15))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.headline)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)

                Text(insight.interpretation)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .padding(12)
        .background(theme.surface1)
        .cornerRadius(12)
    }
}

// MARK: - Featured Insight Banner

/// Large banner card for the "One small thing" featured insight
struct FeaturedInsightBanner: View {
    @Environment(\.theme) private var theme

    let insight: CoachInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overline
            Text("one_small_thing", tableName: "Insights")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(insight.category.color)
                .textCase(.uppercase)
                .tracking(0.5)

            // Headline
            Text(insight.headline)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)

            // Interpretation
            Text(insight.interpretation)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .lineLimit(3)

            // Visual (if present)
            if let visualData = insight.visualData {
                visualContent(visualData)
                    .padding(.vertical, 4)
            }

            // Try action (prominent)
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 3)

                Text(insight.tryAction)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textPrimary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.15),
                        Color.orange.opacity(0.08)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            insight.category.color.opacity(0.08),
                            insight.category.color.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(insight.category.color.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func visualContent(_ data: InsightVisualData) -> some View {
        switch data {
        case .weekDots(let days):
            weekDotsLarge(days)
        case .trendArrow(let direction, let percentage):
            trendBadge(direction, percentage)
        default:
            EmptyView()
        }
    }

    private func weekDotsLarge(_ days: [InsightVisualData.DayActivity]) -> some View {
        HStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { index in
                let day = days.first { $0.dayIndex == index }
                let intensity = day?.intensity ?? 0
                let isToday = day?.isToday ?? false

                VStack(spacing: 4) {
                    Circle()
                        .fill(intensity > 0 ? theme.accentPrimary.opacity(0.3 + intensity * 0.7) : theme.borderSoft)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(isToday ? theme.accentPrimary : Color.clear, lineWidth: 2)
                        )

                    Text(dayLabel(index))
                        .font(.system(size: 9))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    private func trendBadge(_ direction: InsightVisualData.TrendDirection, _ percentage: Double?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: direction.icon)
                .font(.system(size: 16, weight: .semibold))

            if let pct = percentage {
                Text("\(pct >= 0 ? "+" : "")\(Int(pct))%")
                    .font(.system(size: 15, weight: .semibold))
            }

            Text("vs_last_week", tableName: "Insights")
                .font(.caption)
        }
        .foregroundColor(direction.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(direction.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func dayLabel(_ index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
}

// MARK: - Preview

#Preview("Insight Cards") {
    let sampleInsight = CoachInsight(
        id: UUID(),
        category: .strength,
        headline: "Patience is building",
        interpretation: "You logged 3 more calm moments this week than last. That's real progress.",
        tryAction: "Try: Celebrate out loud when you notice patience",
        visualData: .trendArrow(.up, 25),
        priority: .featured
    )

    let weekDaysInsight = CoachInsight(
        id: UUID(),
        category: .pattern,
        headline: "Mornings are golden",
        interpretation: "Most wins happen before 10am. That's when connection is strongest.",
        tryAction: "Try: Use morning time for a quick high-five ritual",
        visualData: .weekDots([
            .init(dayIndex: 0, intensity: 0.8, isToday: false),
            .init(dayIndex: 1, intensity: 0.6, isToday: false),
            .init(dayIndex: 2, intensity: 0.9, isToday: false),
            .init(dayIndex: 3, intensity: 0.4, isToday: false),
            .init(dayIndex: 4, intensity: 0.7, isToday: true),
            .init(dayIndex: 5, intensity: 0, isToday: false),
            .init(dayIndex: 6, intensity: 0, isToday: false)
        ]),
        priority: .standard
    )

    ScrollView {
        VStack(spacing: 20) {
            FeaturedInsightBanner(insight: sampleInsight)

            InsightCard(insight: weekDaysInsight)

            CompactInsightCard(insight: sampleInsight)
        }
        .padding()
    }
    .withTheme(Theme())
}
