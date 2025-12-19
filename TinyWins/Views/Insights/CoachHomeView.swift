import SwiftUI

// MARK: - DEPRECATED
// This view has been superseded by InsightsHomeView.
// DO NOT use this view for new features. If you see this in production routing, fix it.

// MARK: - Coach Home View

/// The main landing page for the Insights/Coach tab.
/// Uses the global InsightsContext for scope, child, and time range state.
/// @available(*, deprecated, message: "Use InsightsHomeView instead")
struct CoachHomeView: View {
    @Environment(\.theme) private var theme
    @Environment(\.insightsContext) private var context
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showingScopeSelector = false
    @State private var insights: [CoachInsight] = []
    @State private var isLoading = true

    private let insightsEngine = InsightsEngine()

    var body: some View {
        // DEPRECATED: This view should not be used. Use InsightsHomeView instead.
        #if DEBUG
        let _ = {
            assertionFailure("CoachHomeView is deprecated. Use InsightsHomeView instead.")
        }()
        #endif

        NavigationStack {
            VStack(spacing: 0) {
                // Sticky context bar
                InsightsContextBar(showingScopeSelector: $showingScopeSelector)

                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Scope chips (horizontal switcher)
                        InsightsScopeChips()
                            .padding(.top, 8)

                        // Content based on scope
                        scopeContent
                            .padding(.horizontal, 16)

                        // Premium upgrade nudge (if free tier)
                        if !subscriptionManager.effectiveIsPlusSubscriber {
                            premiumNudge
                                .padding(.horizontal, 16)
                        }

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle(Text("coach_title", tableName: "Insights"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingScopeSelector) {
                ScopeSelectorSheet()
            }
            .onAppear {
                loadInsights()
            }
            .onChange(of: context.scope) { _, _ in
                loadInsights()
            }
            .onChange(of: context.timeRange) { _, _ in
                loadInsights()
            }
        }
    }

    // MARK: - Scope Content

    @ViewBuilder
    private var scopeContent: some View {
        if isLoading {
            loadingView
        } else if insights.isEmpty {
            emptyStateView
        } else {
            insightsContent
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("loading_insights", tableName: "Insights")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.success],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("no_insights_title", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Text("no_insights_message", tableName: "Insights")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Call to action
            NavigationLink(destination: Text("Log moments here")) {
                Text("log_first_moment", tableName: "Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.accentPrimary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: 20) {
            // Featured insight ("One small thing")
            if let featured = insightsEngine.featuredInsight(from: insights) {
                FeaturedInsightBanner(insight: featured)
            }

            // Quick stats row
            quickStatsRow

            // Other insights
            if insights.count > 1 {
                otherInsightsSection
            }

            // Advanced Insights link (for premium)
            advancedInsightsLink
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        let stats = calculateQuickStats()

        return HStack(spacing: 12) {
            // Wins stat
            QuickStatChip(
                icon: "star.fill",
                value: "\(stats.wins)",
                label: String(localized: "wins", table: "Insights"),
                color: theme.success
            )

            // Challenges stat
            QuickStatChip(
                icon: "exclamationmark.triangle.fill",
                value: "\(stats.challenges)",
                label: String(localized: "challenges", table: "Insights"),
                color: theme.danger
            )

            // Trend indicator
            if let trend = stats.trend {
                TrendChip(trend: trend, percentage: stats.trendPercentage)
            }
        }
    }

    // MARK: - Other Insights Section

    private var otherInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("more_insights", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            ForEach(insights.dropFirst()) { insight in
                InsightCard(insight: insight)
            }
        }
    }

    // MARK: - Advanced Insights Link

    private var advancedInsightsLink: some View {
        Group {
            if subscriptionManager.effectiveIsPlusSubscriber {
                NavigationLink(destination: advancedDestination) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.title3)
                            .foregroundColor(theme.accentPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("advanced_insights_title", tableName: "Insights")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textPrimary)

                            Text("advanced_insights_subtitle", tableName: "Insights")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(16)
                    .background(theme.surface1)
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.borderSoft, lineWidth: 1)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var advancedDestination: some View {
        switch context.scope {
        case .family:
            FamilyAnalyticsDashboard()
        case .child(let childId):
            if let child = childrenStore.activeChildren.first(where: { $0.id == childId }) {
                PremiumAnalyticsDashboard(child: child)
            } else {
                FamilyAnalyticsDashboard()
            }
        case .you:
            // Parent journey dashboard (could be new or existing)
            FamilyAnalyticsDashboard()
        }
    }

    // MARK: - Premium Nudge

    private var premiumNudge: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("unlock_deeper_insights", tableName: "Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
            }

            Text("premium_nudge_message", tableName: "Insights")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: PlusPaywallView()) {
                Text("see_plus_features", tableName: "Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(Color.purple.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Data Loading

    private func loadInsights() {
        isLoading = true

        let events = repository.appData.behaviorEvents
        let behaviorTypes = repository.appData.behaviorTypes
        let children = childrenStore.activeChildren

        insights = insightsEngine.generateInsights(
            scope: context.scope,
            timeRange: context.timeRange,
            events: events,
            behaviorTypes: behaviorTypes,
            children: children
        )

        isLoading = false
    }

    private func calculateQuickStats() -> (wins: Int, challenges: Int, trend: InsightVisualData.TrendDirection?, trendPercentage: Double?) {
        let range = context.timeRange.dateRange
        let events = repository.appData.behaviorEvents.filter {
            $0.timestamp >= range.start && $0.timestamp <= range.end
        }

        let scopeEvents: [BehaviorEvent]
        switch context.scope {
        case .family:
            scopeEvents = events
        case .child(let childId):
            scopeEvents = events.filter { $0.childId == childId }
        case .you:
            scopeEvents = events
        }

        let wins = scopeEvents.filter { $0.pointsApplied > 0 }.count
        let challenges = scopeEvents.filter { $0.pointsApplied < 0 }.count

        // Calculate trend (simplified)
        let trend: InsightVisualData.TrendDirection?
        let percentage: Double?

        if wins > challenges * 2 {
            trend = .up
            percentage = nil
        } else if wins < challenges {
            trend = .down
            percentage = nil
        } else {
            trend = .steady
            percentage = nil
        }

        return (wins, challenges, trend, percentage)
    }
}

// MARK: - Quick Stat Chip

struct QuickStatChip: View {
    @Environment(\.theme) private var theme

    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.surface1)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.borderSoft, lineWidth: 1)
        )
    }
}

// MARK: - Trend Chip

struct TrendChip: View {
    @Environment(\.theme) private var theme

    let trend: InsightVisualData.TrendDirection
    let percentage: Double?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 12, weight: .semibold))

            if let pct = percentage {
                Text("\(pct >= 0 ? "+" : "")\(Int(pct))%")
                    .font(.system(size: 12, weight: .medium))
            } else {
                Text(trendLabel)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(trend.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var trendLabel: String {
        switch trend {
        case .up: return String(localized: "trending_up", table: "Insights")
        case .steady: return String(localized: "trending_steady", table: "Insights")
        case .down: return String(localized: "trending_down", table: "Insights")
        }
    }
}

// MARK: - Preview

#Preview("Coach Home") {
    let context = InsightsContext()
    let repository = Repository.preview

    CoachHomeView()
        .withInsightsContext(context)
        .environmentObject(repository)
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(SubscriptionManager())
        .withTheme(Theme())
}
