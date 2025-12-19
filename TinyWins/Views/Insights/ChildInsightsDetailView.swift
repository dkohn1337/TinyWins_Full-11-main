import SwiftUI

// MARK: - Child Insights Detail View

/// Detailed insights view for a specific child.
/// Shows all coach cards, quick stats, and links to deeper analytics.
///
/// ## Structure
/// - Child header with avatar and quick stats
/// - All coach cards for this child
/// - Explore section (History, Growth Rings, Advanced)
struct ChildInsightsDetailView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var navigation: InsightsNavigationState
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    let child: Child

    @State private var cards: [CoachCard] = []
    @State private var isLoading = true
    @State private var impressionTracker: CardImpressionTracker?
    @State private var _engine: CoachingEngine?

    // Coaching engine instance (cached)
    private func getOrCreateEngine() -> CoachingEngine {
        if _engine == nil {
            let dataProvider = RepositoryDataProvider(repository: repository)
            _engine = CoachingEngineImpl(dataProvider: dataProvider)
        }
        return _engine!
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sectionGap) {
                // Child Header
                childHeader

                // Quick Stats
                quickStatsRow

                // Coach Cards
                coachCardsSection

                // Explore Links
                exploreSection

                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, AppSpacing.sectionGap)
        }
        .background(theme.bg0)
        .navigationTitle(Text("\(child.name)'s Insights", tableName: "Insights"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCards()
        }
    }

    // MARK: - Child Header

    private var childHeader: some View {
        HStack(spacing: 16) {
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
                    .frame(width: 64, height: 64)

                Text(child.name.prefix(1).uppercased())
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)

                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
    }

    private var headerSubtitle: String {
        let eventsThisWeek = recentEvents.count
        if eventsThisWeek == 0 {
            return String(localized: "No moments this week", table: "Insights")
        } else if eventsThisWeek == 1 {
            return String(localized: "1 moment this week", table: "Insights")
        } else {
            return String(localized: "\(eventsThisWeek) moments this week", table: "Insights")
        }
    }

    private var recentEvents: [BehaviorEvent] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return repository.appData.behaviorEvents.filter {
            $0.childId == child.id && $0.timestamp >= weekAgo
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            quickStatCard(
                icon: "star.fill",
                value: "\(positiveCount)",
                label: String(localized: "Wins", table: "Insights"),
                color: theme.success
            )

            quickStatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(challengeCount)",
                label: String(localized: "Challenges", table: "Insights"),
                color: theme.danger
            )

            quickStatCard(
                icon: "arrow.up.right",
                value: trendLabel,
                label: String(localized: "Trend", table: "Insights"),
                color: trendColor
            )
        }
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
    }

    private var positiveCount: Int {
        recentEvents.filter { $0.pointsApplied > 0 }.count
    }

    private var challengeCount: Int {
        recentEvents.filter { $0.pointsApplied < 0 }.count
    }

    private var trendLabel: String {
        // Compare this week to last week
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let lastWeekEvents = repository.appData.behaviorEvents.filter {
            $0.childId == child.id && $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo && $0.pointsApplied > 0
        }

        let thisWeekPositive = positiveCount
        let lastWeekPositive = lastWeekEvents.count

        if lastWeekPositive == 0 {
            return thisWeekPositive > 0 ? "Up" : "—"
        }

        let change = Double(thisWeekPositive - lastWeekPositive) / Double(lastWeekPositive)

        if change >= 0.2 {
            return "Up"
        } else if change <= -0.2 {
            return "Down"
        } else {
            return "Steady"
        }
    }

    private var trendColor: Color {
        switch trendLabel {
        case "Up": return theme.success
        case "Down": return theme.danger
        default: return theme.accentPrimary
        }
    }

    // MARK: - Coach Cards Section

    @ViewBuilder
    private var coachCardsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
            Text("Insights", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if cards.isEmpty {
                emptyCardsState
            } else {
                ForEach(cards) { card in
                    CoachCardView(card: card) {
                        // Record interaction when user opens evidence
                        recordCardInteraction(card)
                        navigation.showingEvidenceSheet = card
                    }
                    .onAppear {
                        impressionTracker?.cardBecameVisible(card)
                    }
                    .onDisappear {
                        impressionTracker?.cardBecameHidden(card)
                    }
                }
            }
        }
    }

    private var emptyCardsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(theme.accentPrimary)

            Text("Building insights...", tableName: "Insights")
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)

            Text("Log a few more moments to see patterns emerge.", tableName: "Insights")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
    }

    // MARK: - Explore Section

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
            Text("Explore", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            // History
            Button {
                navigation.path.append(InsightsDestination.history)
            } label: {
                exploreRow(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    subtitle: "Browse all moments",
                    isPremium: false
                )
            }
            .buttonStyle(.plain)

            // Growth Rings (premium)
            Button {
                if subscriptionManager.effectiveIsPlusSubscriber {
                    navigation.path.append(InsightsDestination.growthRings)
                } else {
                    navigation.path.append(InsightsDestination.paywall)
                }
            } label: {
                exploreRow(
                    icon: "circles.hexagongrid.fill",
                    title: "Growth Rings",
                    subtitle: "Character development over time",
                    isPremium: true
                )
            }
            .buttonStyle(.plain)

            // Advanced Analytics (premium)
            Button {
                if subscriptionManager.effectiveIsPlusSubscriber {
                    navigation.path.append(InsightsDestination.advancedAnalytics)
                } else {
                    navigation.path.append(InsightsDestination.paywall)
                }
            } label: {
                exploreRow(
                    icon: "chart.bar.doc.horizontal",
                    title: "Advanced Analytics",
                    subtitle: "Deep patterns and trends",
                    isPremium: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func exploreRow(icon: String, title: String, subtitle: String, isPremium: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isPremium && !subscriptionManager.effectiveIsPlusSubscriber ? .purple : theme.accentPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)

                    if isPremium && !subscriptionManager.effectiveIsPlusSubscriber {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .padding(14)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
    }

    // MARK: - Data Loading

    private func loadCards() {
        isLoading = true

        let currentEngine = getOrCreateEngine()
        // NOTE: We do NOT call recordCardsDisplayed() here.
        // Cooldowns are recorded via CardImpressionTracker after threshold or interaction.
        let generatedCards = currentEngine.generateCards(childId: child.id.uuidString, now: Date())

        cards = generatedCards
        isLoading = false

        // Initialize impression tracker if needed
        if impressionTracker == nil {
            impressionTracker = CardImpressionTracker(engine: currentEngine)
        }
    }

    /// Record impression when user interacts with a card
    private func recordCardInteraction(_ card: CoachCard) {
        impressionTracker?.recordInteraction(with: card)
    }
}

// MARK: - Preview

#Preview("Child Insights Detail") {
    let navigation = InsightsNavigationState()
    let repository = Repository.preview
    let child = repository.appData.children.first ?? Child(name: "Emma", colorTag: .coral)

    NavigationStack {
        ChildInsightsDetailView(child: child)
    }
    .environmentObject(navigation)
    .environmentObject(repository)
    .environmentObject(ChildrenStore(repository: repository))
    .environmentObject(SubscriptionManager())
    .withTheme(Theme())
}
