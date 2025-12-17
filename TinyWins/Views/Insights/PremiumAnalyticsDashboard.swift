import SwiftUI

// MARK: - PremiumAnalyticsDashboard

/// Comprehensive analytics dashboard with momentum, balance, heatmaps, and AI insights.
/// Premium feature for Plus subscribers.
struct PremiumAnalyticsDashboard: View {
    @Environment(\.themeProvider) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore

    @Binding var child: Child
    var allChildren: [Child]

    @State private var selectedPeriod: TimePeriod = .thisWeek
    @State private var momentum: MomentumScore?
    @State private var balance: BalanceIndex?
    @State private var positiveHeatmap: HeatmapData?
    @State private var challengeHeatmap: HeatmapData?
    @State private var trajectory: WeeklyTrajectory?
    @State private var insights: [Insight] = []
    @State private var peaks: [PeakTimeSlot] = []
    @State private var showingChildPicker = false
    @State private var showingMomentumInfo = false

    private let insightsService = AdvancedInsightsService()
    private let insightGenerator = InsightGenerator()

    // Convenience init for when not using binding
    init(child: Child) {
        self._child = .constant(child)
        self.allChildren = []
    }

    init(child: Binding<Child>, allChildren: [Child]) {
        self._child = child
        self.allChildren = allChildren
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sticky Context Bar with child + time picker
            stickyContextBar

            ScrollView {
                VStack(spacing: 24) {
                    // Main Insight
                if let mainInsight = insights.first {
                    mainInsightCard(mainInsight)
                }

                // Momentum & Balance Row
                HStack(spacing: 16) {
                    momentumCard
                    balanceCard
                }

                // This Week's Highlights (replaces Character Radar)
                WeekHighlightsCard(child: child, maxMoments: 5)

                // Weekly Trajectory
                if let trajectory = trajectory {
                    trajectoryCard(trajectory)
                }

                // Heatmaps
                heatmapSection

                // Peak Times
                if !peaks.isEmpty {
                    peakTimesSection
                }

                // All Insights
                if insights.count > 1 {
                    allInsightsSection
                }
            }
                .padding()
                .tabBarBottomPadding()
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.advancedAnalyticsRoot)
        .navigationTitle("Advanced Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadData()
        }
        .onChange(of: child.id) { _, _ in
            loadData()
        }
        .sheet(isPresented: $showingChildPicker) {
            childPickerSheet
        }
        .sheet(isPresented: $showingMomentumInfo) {
            momentumInfoSheet
        }
    }

    // MARK: - Child Picker Sheet

    private var childPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(allChildren) { childOption in
                    Button {
                        child = childOption
                        showingChildPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [childOption.colorTag.color, childOption.colorTag.color.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                Text(childOption.name.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Text(childOption.name)
                                .font(.body)
                                .foregroundColor(theme.primaryText)

                            Spacer()

                            if childOption.id == child.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingChildPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Momentum Info Sheet

    private var momentumInfoSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor.opacity(0.2), theme.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 32))
                        .foregroundColor(theme.accentColor)
                }
                .padding(.top, 8)

                // Title
                VStack(spacing: 8) {
                    Text("Momentum = Your Parenting Pulse")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                        .multilineTextAlignment(.center)

                    Text("Track how actively you're capturing your child's growth")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                // Factors
                VStack(spacing: 16) {
                    Text("What drives your score:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    momentumFactorRow(
                        icon: "calendar.badge.checkmark",
                        color: .green,
                        title: "Consistency",
                        description: "Log moments most days"
                    )

                    momentumFactorRow(
                        icon: "star.fill",
                        color: .yellow,
                        title: "Celebration",
                        description: "Focus on wins over challenges"
                    )

                    momentumFactorRow(
                        icon: "heart.fill",
                        color: .pink,
                        title: "Engagement",
                        description: "Stay active and involved"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground)
                )

                // Trend explanation
                VStack(spacing: 12) {
                    Text("What the trend means:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        trendBadge(icon: "arrow.up.right", label: "Rising", color: .green)
                        trendBadge(icon: "arrow.right", label: "Steady", color: .blue)
                        trendBadge(icon: "arrow.down.right", label: "Falling", color: .orange)
                    }

                    Text("Compared to your activity last week")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.cardBackground)
                )

                // Tip
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)

                    Text("Even 1 moment a day keeps your momentum strong!")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Understanding Momentum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingMomentumInfo = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func momentumFactorRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)

                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()
        }
    }

    private func trendBadge(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sticky Context Bar

    private var stickyContextBar: some View {
        HStack(spacing: 12) {
            // Child Avatar + Name (tappable)
            Button {
                if allChildren.count > 1 {
                    showingChildPicker = true
                }
            } label: {
                HStack(spacing: 10) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        child.colorTag.color,
                                        child.colorTag.color.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Text(child.name.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Name + change indicator
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.name)
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        if allChildren.count > 1 {
                            Text("Tap to switch")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryText)
                        }
                    }

                    if allChildren.count > 1 {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(allChildren.count <= 1)

            Spacer()

            // Time range picker
            timeRangePicker
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 10)
        .background(theme.backgroundColor)
        .overlay(
            // Bottom separator line
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Menu {
            ForEach([TimePeriod.thisWeek, .thisMonth, .last3Months], id: \.rawValue) { period in
                Button {
                    withAnimation {
                        selectedPeriod = period
                    }
                } label: {
                    HStack {
                        Text(period.displayName)
                        if selectedPeriod == period {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedPeriod.shortDisplayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }

    // MARK: - Period Selector (legacy - keeping for reference)

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([TimePeriod.thisWeek, .thisMonth, .last3Months], id: \.rawValue) { period in
                    Button {
                        withAnimation {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedPeriod == period ? .white : theme.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPeriod == period ?
                                          theme.accentColor : theme.chipBackground)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Main Insight Card

    private func mainInsightCard(_ insight: Insight) -> some View {
        HStack(spacing: 16) {
            Image(systemName: insight.icon)
                .font(.title)
                .foregroundColor(insight.type.color.swiftUIColor)
                .frame(width: 50, height: 50)
                .background(insight.type.color.swiftUIColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(insight.type.color.swiftUIColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(insight.type.color.swiftUIColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Momentum Card

    private var momentumCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Momentum")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)

                // Info button with explanation
                Button {
                    showingMomentumInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .accessibilityLabel("Learn how momentum is calculated")
            }

            if let momentum = momentum {
                // Gauge
                ZStack {
                    Circle()
                        .stroke(theme.accentColor.opacity(0.15), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: momentum.score / 100)
                        .stroke(
                            LinearGradient(
                                colors: [theme.accentColor, momentum.trend.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(momentum.score))")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)

                        HStack(spacing: 2) {
                            Image(systemName: momentum.trend.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(momentum.trend.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(momentum.trend.color)
                    }
                }
                .frame(width: 90, height: 90)

                // Explanation text
                Text("Based on recent wins")
                    .font(.system(size: 9))
                    .foregroundColor(theme.secondaryText)
            } else {
                ProgressView()
                    .frame(width: 90, height: 90)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
    }

    // MARK: - Balance Card

    // Warm, distinct colors for balance bar
    private let balanceRoutineColor = Color(red: 0.6, green: 0.5, blue: 0.85) // Soft purple
    private let balancePositiveColor = Color(red: 0.4, green: 0.78, blue: 0.55) // Green
    private let balanceChallengeColor = Color(red: 1.0, green: 0.6, blue: 0.4) // Warm orange

    private var balanceCard: some View {
        VStack(spacing: 10) {
            Text("Balance")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)

            if let balance = balance {
                VStack(spacing: 10) {
                    // Balance bar with rounded segments
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            if balance.routineRatio > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(balanceRoutineColor)
                                    .frame(width: max(8, geometry.size.width * balance.routineRatio - 1))
                            }

                            if balance.positiveRatio > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(balancePositiveColor)
                                    .frame(width: max(8, geometry.size.width * balance.positiveRatio - 1))
                            }

                            if balance.challengeRatio > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(balanceChallengeColor)
                                    .frame(width: max(8, geometry.size.width * balance.challengeRatio - 1))
                            }
                        }
                    }
                    .frame(height: 20)

                    // Legend with labels AND percentages
                    VStack(spacing: 6) {
                        balanceLegendRow(
                            color: balanceRoutineColor,
                            label: "Routines",
                            value: balance.routineRatio
                        )
                        balanceLegendRow(
                            color: balancePositiveColor,
                            label: "Wins",
                            value: balance.positiveRatio
                        )
                        balanceLegendRow(
                            color: balanceChallengeColor,
                            label: "Challenges",
                            value: balance.challengeRatio
                        )
                    }
                }
            } else {
                ProgressView()
                    .frame(height: 80)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
    }

    private func balanceLegendRow(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText)

            Spacer()

            Text("\(Int(value * 100))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(theme.primaryText)
        }
    }

    // MARK: - Trajectory Card

    private func trajectoryCard(_ trajectory: WeeklyTrajectory) -> some View {
        HStack(spacing: 16) {
            Image(systemName: trajectory.trendIcon)
                .font(.title)
                .foregroundColor(trajectory.trendColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Week Over Week")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(trajectory.percentChange >= 0 ? "+" : "")
                        .font(.subheadline)
                    Text("\(Int(trajectory.percentChange))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .foregroundColor(trajectory.trendColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("This week: \(trajectory.thisWeekPoints) pts")
                    .font(.caption)
                Text("Last week: \(trajectory.lastWeekPoints) pts")
                    .font(.caption)
            }
            .foregroundColor(theme.secondaryText)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
    }

    // MARK: - Activity Summary Section (replaces complex heatmap)

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Patterns")
                .font(.headline)
                .foregroundColor(theme.primaryText)

            VStack(spacing: 16) {
                // Wins by Day - Simple bar chart
                activityDayChart

                Divider()
                    .padding(.vertical, 4)

                // Quick insights
                activityInsights
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
        }
    }

    private var activityDayChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(theme.positiveColor)

                Text("Wins by Day")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
            }

            // Simple horizontal bars for each day
            let dayStats = calculateDayStats()
            let maxCount = dayStats.map { $0.count }.max() ?? 1

            VStack(spacing: 8) {
                ForEach(dayStats, id: \.day) { stat in
                    HStack(spacing: 10) {
                        Text(stat.dayShort)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 30, alignment: .leading)

                        GeometryReader { geometry in
                            let width = maxCount > 0 ? (CGFloat(stat.count) / CGFloat(maxCount)) * geometry.size.width : 0

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.positiveColor.opacity(0.15))
                                    .frame(height: 16)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.positiveColor, theme.positiveColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, width), height: 16)
                            }
                        }
                        .frame(height: 16)

                        Text("\(stat.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(stat.count > 0 ? theme.primaryText : theme.secondaryText)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var activityInsights: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)

                Text("Quick Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
            }

            let insights = generateActivityInsights()

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(theme.positiveColor)

                    Text(insight)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.06))
        )
    }

    private struct DayStat {
        let day: Int // 1 = Sunday, 7 = Saturday
        let dayShort: String
        let count: Int
    }

    private func calculateDayStats() -> [DayStat] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let events = repository.appData.behaviorEvents
            .filter { $0.childId == child.id }
            .filter { $0.timestamp >= weekAgo }
            .filter { $0.pointsApplied > 0 }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var counts: [Int: Int] = [:]

        for event in events {
            let weekday = calendar.component(.weekday, from: event.timestamp)
            counts[weekday, default: 0] += 1
        }

        // Return in order Mon-Sun for better readability
        let orderedDays = [2, 3, 4, 5, 6, 7, 1] // Mon, Tue, Wed, Thu, Fri, Sat, Sun

        return orderedDays.map { day in
            DayStat(
                day: day,
                dayShort: dayNames[day - 1],
                count: counts[day] ?? 0
            )
        }
    }

    private func generateActivityInsights() -> [String] {
        var insights: [String] = []
        let dayStats = calculateDayStats()

        // Best day
        if let bestDay = dayStats.max(by: { $0.count < $1.count }), bestDay.count > 0 {
            insights.append("\(bestDay.dayShort) is the best day for wins this week")
        }

        // Weekend vs weekday
        let weekendCount = dayStats.filter { $0.day == 1 || $0.day == 7 }.reduce(0) { $0 + $1.count }
        let weekdayCount = dayStats.filter { $0.day >= 2 && $0.day <= 6 }.reduce(0) { $0 + $1.count }

        if weekendCount > weekdayCount && weekendCount > 0 {
            insights.append("Weekends show more positive behaviors")
        } else if weekdayCount > weekendCount && weekdayCount > 0 {
            insights.append("Weekdays are stronger for building habits")
        }

        // Consistency
        let activeDays = dayStats.filter { $0.count > 0 }.count
        if activeDays >= 5 {
            insights.append("Great consistency across the week!")
        } else if activeDays >= 3 {
            insights.append("Good momentum - try to add one more active day")
        }

        return Array(insights.prefix(3))
    }

    // MARK: - Peak Times Section

    private var peakTimesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Times for Wins")
                .font(.headline)
                .foregroundColor(theme.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(peaks.prefix(5)) { peak in
                        VStack(spacing: 8) {
                            Text(peak.dayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryText)

                            ZStack {
                                Circle()
                                    .fill(theme.positiveColor.opacity(peak.intensity))
                                    .frame(width: 50, height: 50)

                                Text(peak.timeString)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(peak.intensity > 0.5 ? .white : theme.primaryText)
                            }

                            Text("\(peak.eventCount) wins")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryText)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
        }
    }

    // MARK: - All Insights Section

    private var allInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Insights")
                .font(.headline)
                .foregroundColor(theme.primaryText)

            ForEach(insights.dropFirst()) { insight in
                insightRow(insight)
            }
        }
    }

    private func insightRow(_ insight: Insight) -> some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundColor(insight.type.color.swiftUIColor)
                .frame(width: 36, height: 36)
                .background(insight.type.color.swiftUIColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)

                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Data Loading

    private func loadData() {
        let events = repository.appData.behaviorEvents
        let types = repository.appData.behaviorTypes

        momentum = insightsService.calculateMomentumScore(
            childId: child.id,
            events: events,
            period: selectedPeriod
        )

        balance = insightsService.calculateBalanceIndex(
            childId: child.id,
            events: events,
            behaviorTypes: types,
            period: selectedPeriod
        )

        positiveHeatmap = insightsService.generateHeatmapData(
            childId: child.id,
            events: events,
            category: .positive,
            period: selectedPeriod
        )

        challengeHeatmap = insightsService.generateHeatmapData(
            childId: child.id,
            events: events,
            category: .negative,
            period: selectedPeriod
        )

        trajectory = insightsService.calculateWeeklyTrajectory(
            childId: child.id,
            events: events
        )

        peaks = insightsService.findPeakPerformanceTimes(
            childId: child.id,
            events: events,
            period: selectedPeriod
        )

        insights = insightGenerator.generateAllInsights(
            childId: child.id,
            childName: child.name,
            events: events,
            behaviorTypes: types
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PremiumAnalyticsDashboard(child: Child.preview)
    }
    .environmentObject(Repository.preview)
    .withThemeProvider(ThemeProvider())
}
