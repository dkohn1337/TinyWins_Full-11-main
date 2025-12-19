import SwiftUI

// MARK: - Quick Insights Header

/// Header section showing quick insight summary.
struct QuickInsightsHeaderView: View {
    @Environment(\.theme) private var theme
    let insight: InsightGenerationUseCase.QuickInsight?

    var body: some View {
        if let insight = insight {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: insight.gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: insight.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: insight.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.system(size: 16, weight: .bold))
                    Text(insight.message)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: insight.gradient.map { $0.opacity(0.08) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: insight.gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Family Summary Card

/// Card showing family-level stats for the selected period.
struct FamilySummaryCardView: View {
    @Environment(\.theme) private var theme

    let positiveCount: Int
    let challengeCount: Int
    let totalPoints: Int
    let selectedPeriod: InsightPeriod
    let animateStats: Bool
    let positivityMessage: String

    /// Computed takeaway based on the pattern (1 line max)
    private var takeaway: String? {
        let total = positiveCount + challengeCount
        guard total >= 3 else { return nil }

        let ratio = challengeCount > 0 ? Double(positiveCount) / Double(challengeCount) : Double(positiveCount)

        if ratio >= 3 {
            return "More wins than challenges lately."
        } else if ratio >= 1.5 {
            return "Wins are edging ahead."
        } else if positiveCount > 0 {
            return "Challenges are frequent this period."
        } else {
            return nil
        }
    }

    /// Computed next step suggestion (1 line max, doable now)
    private var tryLine: String? {
        let total = positiveCount + challengeCount
        guard total >= 3 else { return nil }

        let ratio = challengeCount > 0 ? Double(positiveCount) / Double(challengeCount) : Double(positiveCount)

        if ratio >= 3 {
            return "Name one win at dinner tonight."
        } else if ratio >= 1.5 {
            return "Catch one small win before bed."
        } else if positiveCount > 0 {
            return "Log the next positive you see."
        } else {
            return nil
        }
    }

    /// Context footer with early pattern messaging
    private var footerText: String? {
        let total = positiveCount + challengeCount
        guard total >= 1 else { return nil }
        return InsightCopyHelper.footerText(sampleCount: total, period: selectedPeriod.rawValue.lowercased())
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: InsightIconGradients.summary.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "house.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: InsightIconGradients.summary,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: CardAnatomy.overlineToTitle) {
                    Text(InsightOverlines.summary)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .tracking(0.5)

                    Text("Family Overview")
                        .font(.system(size: 17, weight: .bold))
                }

                Spacer()
            }

            // Animated stat boxes
            HStack(spacing: 12) {
                AnimatedStatBox(
                    value: positiveCount,
                    label: "Positive",
                    icon: "hand.thumbsup.fill",
                    gradient: [.green, .mint],
                    animate: animateStats
                )

                AnimatedStatBox(
                    value: challengeCount,
                    label: "Challenges",
                    icon: "exclamationmark.triangle.fill",
                    gradient: [.orange, .yellow],
                    animate: animateStats
                )

                AnimatedStatBox(
                    value: abs(totalPoints),
                    label: "Net Stars",
                    icon: "star.fill",
                    gradient: totalPoints >= 0 ? [.blue, .cyan] : [.orange, .red],
                    prefix: totalPoints >= 0 ? "+" : "-",
                    animate: animateStats
                )
            }

            // Positivity gauge
            if positiveCount + challengeCount > 0 {
                PositivityGaugeView(
                    positive: positiveCount,
                    negative: challengeCount,
                    animateStats: animateStats,
                    positivityMessage: positivityMessage
                )
            }

            // Takeaway + Try section
            if let takeaway = takeaway {
                VStack(alignment: .leading, spacing: CardAnatomy.takeawaySpacing) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)

                        Text("Takeaway: \(takeaway)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let tryLine = tryLine {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(.purple)

                            Text("Try: \(tryLine)")
                                .font(.system(size: 13))
                                .foregroundColor(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .background(AppSurfaces.takeawayBackground)
                .cornerRadius(AppCorners.md)
            }

            // Footer
            if let footer = footerText {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
                    .italic()
            }
        }
        .padding(AppCardPadding.large)
        .background(
            RoundedRectangle(cornerRadius: AppCorners.lg)
                .fill(theme.surface1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Positivity Gauge

/// Visual gauge showing positive/negative ratio.
struct PositivityGaugeView: View {
    @Environment(\.theme) private var theme
    let positive: Int
    let negative: Int
    let animateStats: Bool
    let positivityMessage: String

    private var total: Int { positive + negative }
    private var ratio: Double { negative > 0 ? Double(positive) / Double(negative) : Double(positive) }
    private var percentage: CGFloat { CGFloat(positive) / CGFloat(total) }

    /// Color based on ratio - uses semantic theme colors
    private var ratioColor: Color {
        if ratio >= 3 { return theme.success }
        if ratio >= 1.5 { return theme.accentPrimary }
        return theme.danger
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Positivity Balance")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()

                // Status badge with actual counts - uses semantic theme colors
                HStack(spacing: 4) {
                    Image(systemName: ratio >= 3 ? "checkmark.circle.fill" : (ratio >= 1.5 ? "arrow.up.circle.fill" : "exclamationmark.circle.fill"))
                        .font(.system(size: 12))
                    Text("\(positive) wins · \(negative) challenges")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(ratioColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(ratioColor.opacity(0.15))
                )
            }

            // Animated gauge - uses semantic theme colors
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.borderSoft)

                    // Positive fill with gradient - uses theme positive color
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [theme.success, theme.success.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateStats ? max(geo.size.width * percentage, 12) : 12)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateStats)

                    // Target line at 75%
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2)
                        .offset(x: geo.size.width * 0.75)
                }
            }
            .frame(height: 20)

            // Message
            Text(positivityMessage)
                .font(.system(size: 13))
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Child Switcher Section

/// Compact child selector with header row and optional picker sheet.
/// Scales well for 1-10+ children without horizontal scrolling clutter.
struct ChildSwitcherSectionView: View {
    @Environment(\.theme) private var theme

    let children: [Child]
    @Binding var selectedChildIndex: Int
    var showAllChildrenOption: Bool = false
    var onAllChildrenTap: (() -> Void)? = nil

    @State private var showingChildPicker = false

    private var selectedChild: Child? {
        guard selectedChildIndex < children.count else { return nil }
        return children[selectedChildIndex]
    }

    var body: some View {
        // Single child: just show avatar and name, no picker needed
        // Multiple children: show selected child with "Change" button
        if let child = selectedChild {
            HStack(spacing: 12) {
                // Selected child avatar
                ZStack {
                    Circle()
                        .fill(child.colorTag.color)
                        .frame(width: 44, height: 44)

                    Text(child.initials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                // Child name
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    if children.count > 1 {
                        Text("Viewing insights")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                // Change button (only if multiple children)
                if children.count > 1 {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingChildPicker = true
                    }) {
                        Text("Change")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Change child")
                    .accessibilityHint("Opens picker to select a different child")
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Viewing \(child.name)'s insights")
            .sheet(isPresented: $showingChildPicker) {
                InsightsChildPickerSheet(
                    children: children,
                    selectedChildIndex: $selectedChildIndex
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Insights Child Picker Sheet

/// Bottom sheet for selecting a child in Insights - clean list with avatars.
struct InsightsChildPickerSheet: View {
    @Environment(\.theme) private var theme
    let children: [Child]
    @Binding var selectedChildIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedChildIndex = index
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(child.colorTag.color)
                                    .frame(width: 40, height: 40)

                                Text(child.initials)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            // Name
                            Text(child.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textPrimary)

                            Spacer()

                            // Selection checkmark
                            if selectedChildIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(child.name)
                    .accessibilityAddTraits(selectedChildIndex == index ? [.isSelected] : [])
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Weekly Trend Chart

/// Dot matrix showing 7-day activity patterns.
struct WeeklyTrendChartView: View {
    @Environment(\.theme) private var theme

    let dailyData: [InsightGenerationUseCase.DailyActivityData]
    let animateStats: Bool

    // MARK: - Constants

    private let minDotSize: CGFloat = 12
    private let maxDotSize: CGFloat = 44
    private let emptyDotSize: CGFloat = 8

    // MARK: - Computed Properties

    /// Maximum stacked value (positive + challenges) for scaling
    private var maxStackedValue: Int {
        max(dailyData.map { $0.positive + $0.negative }.max() ?? 1, 1)
    }

    /// Check if there's any actual data to display
    private var hasData: Bool {
        !dailyData.isEmpty && dailyData.contains { $0.positive > 0 || $0.negative > 0 }
    }

    /// Total events this week
    private var totalEvents: Int {
        dailyData.reduce(0) { $0 + $1.positive + $1.negative }
    }

    /// Total positive events
    private var totalPositive: Int {
        dailyData.reduce(0) { $0 + $1.positive }
    }

    /// Total challenge events
    private var totalChallenges: Int {
        dailyData.reduce(0) { $0 + $1.negative }
    }

    /// Is this early data (< 5 moments)?
    private var isEarlyData: Bool {
        totalEvents > 0 && totalEvents < InsightCopyHelper.confidenceThreshold
    }

    /// Find the best day (most positive moments)
    private var bestDay: (dayName: String, shortName: String, positive: Int)? {
        guard hasData else { return nil }
        let sorted = dailyData.filter { $0.positive > 0 }.sorted { $0.positive > $1.positive }
        guard let best = sorted.first else { return nil }
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "EEEE"
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "EEE"
        return (fullFormatter.string(from: best.date), shortFormatter.string(from: best.date), best.positive)
    }

    /// Find day with most challenges
    private var hardestDay: (dayName: String, challenges: Int)? {
        guard hasData else { return nil }
        let sorted = dailyData.filter { $0.negative > 0 }.sorted { $0.negative > $1.negative }
        guard let hardest = sorted.first, hardest.negative >= 2 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return (formatter.string(from: hardest.date), hardest.negative)
    }

    /// Takeaway based on pattern (1 line max, no recall required)
    private var takeaway: String? {
        guard hasData else { return nil }

        // Early data: cautious takeaway
        if isEarlyData {
            if let best = bestDay, best.positive >= 2 {
                return "Early pattern: \(best.dayName)s may be easier."
            }
            return "Building your weekly picture."
        }

        // Normal data: confident takeaway
        if let best = bestDay, best.positive >= 3 {
            return "\(best.dayName)s have the most positive moments."
        }

        let activeDays = dailyData.filter { $0.positive > 0 || $0.negative > 0 }.count
        if totalPositive > totalChallenges * 2 {
            return "Positive moments are spread across the week."
        } else if totalChallenges > totalPositive {
            return "Challenges are showing up more often."
        } else if activeDays >= 5 {
            return "Your weekly rhythm is becoming clear."
        }
        return "Patterns emerging as you log more."
    }

    /// Try line (1 line max, doable in 60 seconds, no recall required)
    private var tryLine: String? {
        guard hasData, totalEvents >= 3 else { return nil }

        // Actionable suggestions that don't require remembering specific days
        if totalChallenges > totalPositive {
            return "Notice one small win before the next meal."
        } else if let _ = bestDay {
            return "Keep the first 5 minutes of tomorrow calm."
        } else {
            return "Catch one positive moment today."
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with overline
            cardHeader

            if hasData {
                // Dot matrix chart
                dotMatrix
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Weekly activity chart")
                    .accessibilityValue("\(totalPositive) positive, \(totalChallenges) challenges")

                // Compact legend
                dotLegend

                // Takeaway + Try section
                if let takeaway = takeaway {
                    takeawaySection(takeaway: takeaway)
                }

                // Footer
                footerText
            } else {
                // Empty state
                emptyState
            }
        }
        .padding(AppCardPadding.large)
        .background(
            RoundedRectangle(cornerRadius: AppCorners.lg)
                .fill(theme.surface1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Subviews

    private var cardHeader: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: InsightIconGradients.activity.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: InsightIconGradients.activity,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: CardAnatomy.overlineToTitle) {
                Text(InsightOverlines.activity)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .tracking(0.5)

                Text("Daily Activity")
                    .font(.system(size: 17, weight: .bold))
            }

            Spacer()
        }
    }

    private var dotMatrix: some View {
        HStack(spacing: 0) {
            ForEach(Array(dailyData.enumerated()), id: \.offset) { index, day in
                let isToday = Calendar.current.isDateInToday(day.date)
                let dayTotal = day.positive + day.negative

                VStack(spacing: 6) {
                    // Activity dot
                    Circle()
                        .fill(dotColor(positive: day.positive, negative: day.negative))
                        .frame(
                            width: animateStats ? dotSize(for: dayTotal) : emptyDotSize,
                            height: animateStats ? dotSize(for: dayTotal) : emptyDotSize
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.05), value: animateStats)

                    // Locale-aware day label
                    Text(localeAwareWeekdaySymbol(for: day.date))
                        .font(.system(size: 11, weight: isToday ? .bold : .regular))
                        .foregroundColor(isToday ? theme.textPrimary : theme.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: maxDotSize + 24) // Fixed height for alignment
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(localeAwareWeekdayName(for: day.date))
                .accessibilityValue(dayTotal > 0 ? "\(day.positive) positive, \(day.negative) challenges" : "No activity")
            }
        }
    }

    private var dotLegend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                Circle()
                    .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 8, height: 8)
                Text("Positive")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text("Challenges")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Text("Size = activity")
                .font(.system(size: 10))
                .foregroundColor(theme.textSecondary.opacity(0.7))
        }
    }

    private func takeawaySection(takeaway: String) -> some View {
        VStack(alignment: .leading, spacing: CardAnatomy.takeawaySpacing) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)

                Text("Takeaway: \(takeaway)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let tryLine = tryLine {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)

                    Text("Try: \(tryLine)")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(AppSurfaces.takeawayBackground)
        .cornerRadius(AppCorners.md)
    }

    @ViewBuilder
    private var footerText: some View {
        if totalEvents >= 1 {
            Text(InsightCopyHelper.footerText(sampleCount: totalEvents, period: "this week"))
                .font(.system(size: 11))
                .foregroundColor(theme.textSecondary)
                .italic()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            // Show placeholder dots
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(theme.borderSoft)
                            .frame(width: emptyDotSize, height: emptyDotSize)

                        Text(weekdaySymbol(for: index))
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: maxDotSize + 24)
                }
            }

            VStack(spacing: 8) {
                Text("Log a few moments to see patterns here.")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)

                // Try line for empty state
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(.purple.opacity(0.7))
                    Text("Try: Notice one small positive moment today.")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("No activity data yet")
        .accessibilityHint("Log moments to see your weekly patterns")
    }

    // MARK: - Helper Methods

    /// Calculate dot size based on activity count
    private func dotSize(for total: Int) -> CGFloat {
        guard total > 0 else { return emptyDotSize }
        let maxValue = max(maxStackedValue, 1)
        let proportion = CGFloat(total) / CGFloat(maxValue)
        return minDotSize + (maxDotSize - minDotSize) * proportion
    }

    /// Calculate dot color based on positive/negative balance
    private func dotColor(positive: Int, negative: Int) -> some ShapeStyle {
        let total = positive + negative
        guard total > 0 else {
            return AnyShapeStyle(theme.borderSoft)
        }

        let positiveRatio = CGFloat(positive) / CGFloat(total)

        if positiveRatio >= 0.7 {
            // Mostly positive - green gradient
            return AnyShapeStyle(LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        } else if positiveRatio >= 0.4 {
            // Mixed - blend color
            return AnyShapeStyle(LinearGradient(
                colors: [.green.opacity(0.7), .orange.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        } else {
            // Mostly challenges - orange
            return AnyShapeStyle(Color.orange)
        }
    }

    /// Locale-aware very short weekday symbol (e.g., S, M, T, W, T, F, S)
    private func localeAwareWeekdaySymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEEE" // Very short format
        return formatter.string(from: date)
    }

    /// Locale-aware full weekday name for accessibility
    private func localeAwareWeekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// Weekday symbol for empty state placeholder (uses current locale)
    private func weekdaySymbol(for index: Int) -> String {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1
        let adjustedIndex = (index + firstWeekday) % 7
        return symbols[adjustedIndex]
    }
}

// MARK: - Aha Insights Section

/// Section displaying pattern-based insights (Highlights).
/// Premium CTA is handled separately at the tab level.
struct AhaInsightsSectionView: View {
    @Environment(\.theme) private var theme

    let insights: [InsightGenerationUseCase.AhaInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Highlights")
                    .font(.system(size: 17, weight: .bold))

                // Insight count badge
                Text("\(insights.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.borderSoft)
                    .cornerRadius(10)

                Spacer()
            }

            ForEach(Array(insights.enumerated()), id: \.element.title) { index, insight in
                AhaInsightCard(
                    icon: insight.icon,
                    gradient: insight.gradient,
                    title: insight.title,
                    message: insight.message,
                    actionable: insight.actionable,
                    index: index
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.surface1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Parent Journey Section

/// Section showing parent's engagement progress.
struct ParentJourneySectionView: View {
    @Environment(\.theme) private var theme

    let level: CoachLevel
    let activeDays: Int
    let animateStats: Bool

    var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: level.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text("Your Journey")
                            .font(.system(size: 18, weight: .bold))

                        Text(level.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    Text(level.description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }

            // Weekly streak
            HStack(spacing: 16) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(theme.borderSoft, lineWidth: 6)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: animateStats ? CGFloat(activeDays) / 7.0 : 0)
                        .stroke(
                            AngularGradient(
                                colors: [.green, .mint, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: animateStats)

                    VStack(spacing: 0) {
                        Text("\(activeDays)")
                            .font(.system(size: 24, weight: .bold))
                        Text("of 7")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Days This Week")
                        .font(.system(size: 14, weight: .semibold))

                    // Day dots
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            ZStack {
                                Circle()
                                    .fill(day < activeDays ?
                                        LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [theme.borderSoft], startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(width: 28, height: 28)

                                if day < activeDays {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }

                    Text(activeDays >= 5 ? "Amazing consistency! 🎉" : (activeDays >= 3 ? "Great progress! Keep going!" : "Every day counts!"))
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.surface1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Plus Upsell Section

/// Premium subscription upsell card.
struct PlusUpsellSectionView: View {
    @Environment(\.theme) private var theme
    let onTapUpgrade: () -> Void
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Deeper Insights")
                        .font(.system(size: 18, weight: .bold))

                    Text("See patterns others miss")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }

            // Features grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PlusFeatureItem(icon: "calendar.badge.clock", title: "30-day trends")
                PlusFeatureItem(icon: "clock.fill", title: "Time patterns")
                PlusFeatureItem(icon: "person.2.fill", title: "Unlimited kids")
                PlusFeatureItem(icon: "chart.xyaxis.line", title: "Deep analytics")
            }

            // CTA
            Button(action: onTapUpgrade) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Try Plus Free")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 14))
                )
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.08), .pink.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
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
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Period Selector View

/// Horizontal scrollable period selector with premium gating and scroll anchoring.
struct PeriodSelectorView: View {
    @Environment(\.theme) private var theme

    @Binding var selectedPeriod: InsightPeriod
    let isPlusSubscriber: Bool
    let onLockedPeriodTapped: () -> Void
    @Namespace private var animation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(InsightPeriod.allCases, id: \.self) { period in
                        let isLocked = InsightPeriod.premiumPeriods.contains(period) && !isPlusSubscriber

                        Button {
                            if isLocked {
                                onLockedPeriodTapped()
                            } else {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedPeriod = period
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                }
                                Text(period.rawValue)
                                    .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Group {
                                    if selectedPeriod == period {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple, .blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                                            .matchedGeometryEffect(id: "periodBg", in: animation)
                                    } else {
                                        Capsule()
                                            .fill(theme.surface2)
                                    }
                                }
                            )
                            .foregroundColor(selectedPeriod == period ? .white : (isLocked ? theme.textSecondary : theme.textPrimary))
                        }
                        .buttonStyle(.plain)
                        .id(period)
                        .accessibilityLabel(isLocked ? "\(period.rawValue), requires Plus subscription" : period.rawValue)
                        .accessibilityHint(selectedPeriod == period ? "Currently selected" : (isLocked ? "Double tap to view Plus subscription" : "Double tap to select"))
                        .accessibilityAddTraits(selectedPeriod == period ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: selectedPeriod) { _, newPeriod in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newPeriod, anchor: .center)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(selectedPeriod, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Child Deep Dive Section View

/// Section showing detailed stats for a specific child.
struct ChildDeepDiveSectionView: View {
    @Environment(\.theme) private var theme
    let child: Child
    let deepDive: InsightGenerationUseCase.ChildDeepDiveData
    let selectedPeriod: InsightPeriod
    let activeReward: Reward?
    let behaviorEvents: [BehaviorEvent]
    let animateStats: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Child header card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [child.colorTag.color, child.colorTag.color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 58, height: 58)

                    ChildAvatar(child: child, size: 50)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("This \(selectedPeriod.rawValue.lowercased()) with \(child.name)")
                        .font(.system(size: 16, weight: .bold))

                    HStack(spacing: 12) {
                        StatPill(value: deepDive.positiveEvents.count, label: "wins", color: .green)
                        StatPill(value: deepDive.challengeEvents.count, label: "challenges", color: .orange)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [child.colorTag.color.opacity(0.1), child.colorTag.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            // Biggest Win card
            if let behavior = deepDive.topWinBehavior, deepDive.topWinCount >= 2 {
                InsightHighlightCard(
                    icon: "trophy.fill",
                    iconGradient: [.yellow, .orange],
                    title: "Biggest Win",
                    subtitle: behavior.name,
                    detail: "\(deepDive.topWinCount) times this \(selectedPeriod.rawValue.lowercased())",
                    tip: "Keep praising \(child.name) for this. Verbal recognition matters as much as stars!"
                )
            }

            // Area to work on card
            if let behavior = deepDive.topChallengeBehavior, deepDive.topChallengeCount >= 2 {
                InsightHighlightCard(
                    icon: "lightbulb.fill",
                    iconGradient: [.orange, .red.opacity(0.8)],
                    title: "Growth Opportunity",
                    subtitle: behavior.name,
                    detail: "\(deepDive.topChallengeCount) times this \(selectedPeriod.rawValue.lowercased())",
                    tip: "Understanding the pattern is the first step. When does this usually happen?"
                )
            }

            // Goal progress if active
            if let reward = activeReward {
                GoalProgressCardView(
                    child: child,
                    reward: reward,
                    behaviorEvents: behaviorEvents,
                    animateStats: animateStats
                )
            }
        }
    }
}

// MARK: - Goal Progress Card View

/// Card showing progress toward a child's active goal with milestone celebrations.
struct GoalProgressCardView: View {
    @Environment(\.theme) private var theme

    let child: Child
    let reward: Reward
    let behaviorEvents: [BehaviorEvent]
    let animateStats: Bool

    @State private var showMilestoneCelebration = false

    private var status: Reward.RewardStatus {
        reward.status(from: behaviorEvents, isPrimaryReward: true)
    }

    private var earned: Int {
        reward.pointsEarnedInWindow(from: behaviorEvents, isPrimaryReward: true)
    }

    private var progress: Double {
        min(Double(earned) / Double(reward.targetPoints), 1.0)
    }

    private var starsNeeded: Int {
        max(0, reward.targetPoints - earned)
    }

    /// Current milestone reached (25, 50, 75, or 100)
    private var currentMilestone: Int? {
        let percentage = Int(progress * 100)
        if percentage >= 100 { return 100 }
        if percentage >= 75 { return 75 }
        if percentage >= 50 { return 50 }
        if percentage >= 25 { return 25 }
        return nil
    }

    /// Milestone message for encouragement
    private var milestoneMessage: String? {
        switch currentMilestone {
        case 25: return "Quarter way there!"
        case 50: return "Halfway to the goal!"
        case 75: return "Almost there!"
        case 100: return "Goal achieved! 🎉"
        default: return nil
        }
    }

    /// Milestone gradient colors
    private var milestoneGradient: [Color] {
        switch currentMilestone {
        case 25: return [.blue, .cyan]
        case 50: return [.purple, .pink]
        case 75: return [.orange, .yellow]
        case 100: return [.green, .mint]
        default: return [child.colorTag.color, child.colorTag.color.opacity(0.7)]
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [child.colorTag.color.opacity(0.2), child.colorTag.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: reward.imageName ?? "gift.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [child.colorTag.color, child.colorTag.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, options: .speed(0.5), value: showMilestoneCelebration)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Working toward")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textSecondary)

                        if status == .readyToRedeem {
                            Text("EARNED!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                        )
                                )
                        } else if let daysRemaining = reward.daysRemaining, daysRemaining <= 7 {
                            // Deadline proximity warning
                            DeadlineProximityBadge(daysRemaining: daysRemaining)
                        }
                    }

                    Text(reward.name)
                        .font(.system(size: 16, weight: .semibold))
                }

                Spacer()

                // Circular progress with milestone indicator
                ZStack {
                    Circle()
                        .stroke(theme.borderSoft, lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: animateStats ? progress : 0)
                        .stroke(
                            LinearGradient(
                                colors: milestoneGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: animateStats)

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))

                    // Milestone celebration sparkle
                    if showMilestoneCelebration && currentMilestone != nil {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(milestoneGradient.first ?? .yellow)
                            .offset(x: 18, y: -18)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            // Milestone celebration banner
            if let milestone = currentMilestone, let message = milestoneMessage {
                HStack(spacing: 8) {
                    Image(systemName: milestone == 100 ? "trophy.fill" : "flag.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(message)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text("\(milestone)%")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.3)))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: milestoneGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .scaleEffect(showMilestoneCelebration ? 1.0 : 0.95)
                .animation(.spring(response: 0.4), value: showMilestoneCelebration)
            } else if status != .readyToRedeem {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("\(starsNeeded) more star\(starsNeeded == 1 ? "" : "s") to go")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .onAppear {
            if currentMilestone != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4)) {
                        showMilestoneCelebration = true
                    }
                }
            }
        }
    }
}
