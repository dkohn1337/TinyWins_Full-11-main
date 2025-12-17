import SwiftUI

// MARK: - DEPRECATED
// This view has been superseded by InsightsHomeView.
// It remains in the codebase only because it contains shared types (InsightsScope, InsightPeriod).
// DO NOT use this view for new features. If you see this in production routing, fix it.

// MARK: - Insights Scope

/// The three main scopes for Insights navigation
enum InsightsScope: String, CaseIterable {
    case family = "Family"
    case child = "Child"
    case you = "You"

    var icon: String {
        switch self {
        case .family: return "house.fill"
        case .child: return "figure.child"
        case .you: return "person.fill"
        }
    }
}

/// Unified Family Insights View - Premium analytics experience
/// Three distinct scopes: Family (household), Child (individual), You (parent journey)
struct FamilyInsightsView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var insightsStore: InsightsStore
    @EnvironmentObject private var progressionStore: ProgressionStore
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var themeProvider: ThemeProvider

    @State private var selectedScope: InsightsScope = .family
    @State private var selectedPeriod: InsightPeriod = .thisWeek
    @State private var showingPaywall = false
    @State private var showingDailyCheckIn = false
    @State private var animateStats = false

    // MARK: - Use Case (injected via computed property for now)

    private var insightUseCase: InsightGenerationUseCase {
        InsightGenerationUseCase(behaviorsStore: behaviorsStore, childrenStore: childrenStore)
    }

    // MARK: - Computed Properties

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    private var isEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 18 || hour < 6
    }

    /// Suggest 30-day view if user has been active 4+ weeks
    private var shouldSuggest30DayView: Bool {
        let weeksActive = progressionStore.parentActivity.activeDays.count / 7
        return weeksActive >= 4
    }

    /// Selected child index based on coordinator's shared selection
    private var selectedChildIndex: Int {
        get {
            guard let selectedId = coordinator.selectedChildId,
                  let index = childrenStore.activeChildren.firstIndex(where: { $0.id == selectedId }) else {
                return 0
            }
            return index
        }
    }

    private var selectedChild: Child? {
        guard !childrenStore.activeChildren.isEmpty,
              selectedChildIndex < childrenStore.activeChildren.count else { return nil }
        return childrenStore.activeChildren[selectedChildIndex]
    }

    /// Updates the shared child selection in coordinator
    private func selectChildAtIndex(_ index: Int) {
        guard index < childrenStore.activeChildren.count else { return }
        let child = childrenStore.activeChildren[index]
        coordinator.selectChild(child.id)
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch selectedScope {
        case .family:
            return "Family Overview"
        case .child:
            if let child = selectedChild {
                return "\(child.name)'s Progress"
            }
            return "Child Progress"
        case .you:
            return "Your Journey"
        }
    }

    // MARK: - Body

    var body: some View {
        // DEPRECATED: This view should not be used. Use InsightsHomeView instead.
        #if DEBUG
        let _ = {
            assertionFailure("FamilyInsightsView is deprecated. Use InsightsHomeView instead.")
        }()
        #endif

        NavigationStack {
            Group {
                if childrenStore.children.isEmpty {
                    InsightsEmptyStateView(animateStats: $animateStats)
                } else if behaviorsStore.behaviorEvents.isEmpty {
                    InsightsNoDataStateView(
                        animateStats: $animateStats,
                        eventCount: behaviorsStore.behaviorEvents.count
                    )
                } else {
                    insightsContent
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingPaywall) {
                PlusPaywallView(context: .advancedInsights)
            }
            .sheet(isPresented: $showingDailyCheckIn) {
                DailyCheckInView()
            }
            .themedNavigationBar(themeProvider)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                animateStats = true
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Simplified: Just settings icon for consistency across all tabs
            // History and daily check-in accessible from within Insights content
            Button(action: { coordinator.presentSheet(.settings) }) {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Main Content

    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Scope selector (Family | Child | You)
                scopeSelector

                // Time period selector (shared across all scopes)
                PeriodSelectorView(
                    selectedPeriod: $selectedPeriod,
                    isPlusSubscriber: isPlusSubscriber,
                    onLockedPeriodTapped: { showingPaywall = true }
                )

                // Scope-specific content
                switch selectedScope {
                case .family:
                    familyScopeContent
                case .child:
                    childScopeContent
                case .you:
                    youScopeContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .tabBarBottomPadding()
        }
        .background(themeProvider.backgroundColor)
    }

    // MARK: - Scope Selector

    private var scopeSelector: some View {
        HStack(spacing: 0) {
            ForEach(InsightsScope.allCases, id: \.self) { scope in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedScope = scope
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: scope.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(scope.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedScope == scope ? .white : themeProvider.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44) // Accessibility: minimum tap target
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedScope == scope ? themeProvider.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(scope.rawValue) scope")
                .accessibilityAddTraits(selectedScope == scope ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.cardBackground)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Insights scope selector")
    }

    // MARK: - Family Scope Content
    // Structure: Hero takeaway → WeekActivityDots → 2 micro-hints → behavior pills → 1 gentle action → 1 premium CTA

    @ViewBuilder
    private var familyScopeContent: some View {
        let stats = insightUseCase.calculatePeriodStats(for: selectedPeriod)
        let dailyData = insightUseCase.generateDailyActivityData(for: selectedPeriod)
        let trajectory = calculateFamilyTrajectory()

        VStack(spacing: 16) {
            // 1. HERO TAKEAWAY (1 sentence, warm, specific)
            familyHeroCard(stats: stats, dailyData: dailyData)

            // 2. TWO MICRO-HINTS with trend indicator (tiny dashboard feel)
            familyMicroHints(stats: stats, dailyData: dailyData, trajectory: trajectory)

            // 3. TOP BEHAVIORS (visual proof of what's being tracked)
            familyBehaviorPills(stats: stats)

            // 4. ONE GENTLE ACTION (one experiment)
            familyGentleAction(stats: stats)

            // 5. ONE PREMIUM CTA (single entry point)
            advancedInsightsCTAFamily
        }
    }

    // MARK: - Family Trajectory Calculation

    private func calculateFamilyTrajectory() -> (percentChange: Double, thisWeek: Int, lastWeek: Int) {
        let calendar = Calendar.current
        let now = Date()

        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) else {
            return (0, 0, 0)
        }

        let events = behaviorsStore.behaviorEvents
        let thisWeekEvents = events.filter { $0.timestamp >= thisWeekStart && $0.pointsApplied > 0 }
        let lastWeekEvents = events.filter { $0.timestamp >= lastWeekStart && $0.timestamp < thisWeekStart && $0.pointsApplied > 0 }

        let thisWeekCount = thisWeekEvents.count
        let lastWeekCount = lastWeekEvents.count

        let percentChange: Double
        if lastWeekCount > 0 {
            percentChange = Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount) * 100
        } else if thisWeekCount > 0 {
            percentChange = 100
        } else {
            percentChange = 0
        }

        return (percentChange, thisWeekCount, lastWeekCount)
    }

    // MARK: - Family Hero Card

    private func familyHeroCard(stats: InsightGenerationUseCase.PeriodStats, dailyData: [InsightGenerationUseCase.DailyActivityData]) -> some View {
        let total = stats.positiveCount + stats.challengeCount
        let heroMessage = familyHeroMessage(stats: stats)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.accentColor)

                Text("This \(selectedPeriod.shortLabel)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeProvider.secondaryText)

                Spacer()
            }

            Text(heroMessage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeProvider.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Week Activity Dots (visual proof of logging)
            WeekActivityDots(dailyData: dailyData, accentColor: themeProvider.positiveColor)
                .padding(.top, 4)

            if total > 0 && total < 5 {
                Text("Early pattern from \(total) moments")
                    .font(.system(size: 11))
                    .foregroundColor(themeProvider.secondaryText)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeProvider.cardBackground)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func familyHeroMessage(stats: InsightGenerationUseCase.PeriodStats) -> String {
        let total = stats.positiveCount + stats.challengeCount

        if total == 0 {
            return "Start logging moments to see patterns."
        }

        let ratio = stats.challengeCount > 0 ? Double(stats.positiveCount) / Double(stats.challengeCount) : Double(stats.positiveCount)

        if ratio >= 3 {
            return "Your family is in a positive flow. Wins are leading by far."
        } else if ratio >= 1.5 {
            return "More wins than challenges right now. You're noticing the good."
        } else if stats.positiveCount > 0 {
            return "Challenges are frequent, but you're still catching wins too."
        } else {
            return "Tough stretch. Every challenge logged is progress."
        }
    }

    // MARK: - Family Micro-Hints

    private func familyMicroHints(stats: InsightGenerationUseCase.PeriodStats, dailyData: [InsightGenerationUseCase.DailyActivityData], trajectory: (percentChange: Double, thisWeek: Int, lastWeek: Int)) -> some View {
        HStack(spacing: 10) {
            // Hint 1: Activity balance chip with trend
            let trend: TrendArrowBadge.Trend = trajectory.percentChange > 5 ? .up : (trajectory.percentChange < -5 ? .down : .steady)
            EnhancedMicroHintChip(
                icon: "star.fill",
                label: "\(stats.positiveCount) wins",
                sublabel: "\(stats.challengeCount) challenges",
                color: stats.positiveCount >= stats.challengeCount ? themeProvider.positiveColor : themeProvider.challengeColor,
                trend: trajectory.lastWeek > 0 ? trend : nil,
                percentChange: trajectory.lastWeek > 0 ? trajectory.percentChange : nil
            )

            // Hint 2: Consistency chip (active days this week)
            let activeDays = dailyData.filter { $0.positive + $0.negative > 0 }.count
            microHintChip(
                icon: "calendar",
                label: "\(activeDays) active days",
                sublabel: "this week",
                color: activeDays >= 4 ? themeProvider.positiveColor : themeProvider.accentColor
            )
        }
    }

    private func microHintChip(icon: String, label: String, sublabel: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeProvider.primaryText)
                Text(sublabel)
                    .font(.system(size: 10))
                    .foregroundColor(themeProvider.secondaryText)
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

    // MARK: - Family Gentle Action

    private func familyGentleAction(stats: InsightGenerationUseCase.PeriodStats) -> some View {
        let actionText = familyActionSuggestion(stats: stats)

        return HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)

            Text(actionText)
                .font(.system(size: 14))
                .foregroundColor(themeProvider.primaryText)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.08))
        )
    }

    private func familyActionSuggestion(stats: InsightGenerationUseCase.PeriodStats) -> String {
        let total = stats.positiveCount + stats.challengeCount
        if total == 0 {
            return "Try: Log one moment you notice today."
        }

        let ratio = stats.challengeCount > 0 ? Double(stats.positiveCount) / Double(stats.challengeCount) : Double(stats.positiveCount)

        if ratio >= 3 {
            return "Try: Name one win at dinner tonight."
        } else if ratio >= 1.5 {
            return "Try: Catch one small win before bed."
        } else {
            return "Try: Notice one tiny positive today."
        }
    }

    // MARK: - Family Behavior Pills

    @ViewBuilder
    private func familyBehaviorPills(stats: InsightGenerationUseCase.PeriodStats) -> some View {
        let behaviors = calculateTopBehaviors()

        if !behaviors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Top behaviors")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.secondaryText)

                BehaviorPillStack(
                    behaviors: behaviors,
                    maxVisible: 3,
                    showTruncationHint: behaviors.count > 3
                )
            }
        }
    }

    private func calculateTopBehaviors() -> [BehaviorPillStack.BehaviorItem] {
        let events = behaviorsStore.behaviorEvents
        let calendar = Calendar.current
        let now = Date()

        // Filter to this week
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }

        let weekEvents = events.filter { $0.timestamp >= weekStart }

        // Count by behavior type
        var behaviorCounts: [UUID: (count: Int, isPositive: Bool)] = [:]
        for event in weekEvents {
            let isPositive = event.pointsApplied > 0
            if let existing = behaviorCounts[event.behaviorTypeId] {
                behaviorCounts[event.behaviorTypeId] = (existing.count + 1, existing.isPositive)
            } else {
                behaviorCounts[event.behaviorTypeId] = (1, isPositive)
            }
        }

        // Convert to BehaviorItems and sort by count
        let items: [BehaviorPillStack.BehaviorItem] = behaviorCounts.compactMap { (typeId, data) in
            guard let behaviorType = behaviorsStore.behaviorType(id: typeId) else { return nil }
            return BehaviorPillStack.BehaviorItem(
                name: behaviorType.name,
                count: data.count,
                isPositive: data.isPositive
            )
        }
        .sorted { $0.count > $1.count }

        return Array(items.prefix(5))
    }

    // MARK: - Child Scope Content
    // Structure: Hero takeaway (with inline child picker) → 2 micro-hints → 1 gentle action → 1 premium CTA
    // Simplified: max 2 horizontal control rows (scope tabs + period selector)

    @State private var showingChildPickerSheet = false

    @ViewBuilder
    private var childScopeContent: some View {
        VStack(spacing: 16) {
            // Per-child content (child picker integrated into hero card)
            if let child = selectedChild {
                let deepDive = insightUseCase.generateChildDeepDive(for: child, period: selectedPeriod)
                let childDailyData = calculateChildDailyData(for: child)
                let childTrajectory = calculateChildTrajectory(for: child)

                // 1. HERO TAKEAWAY (with inline child selector + WeekActivityDots)
                childHeroCard(child: child, deepDive: deepDive, dailyData: childDailyData)

                // 2. TWO MICRO-HINTS with trajectory (tiny dashboard feel)
                childMicroHints(child: child, deepDive: deepDive, trajectory: childTrajectory)

                // 3. BEHAVIOR PILLS (top wins + top challenge)
                childBehaviorPills(child: child, deepDive: deepDive)

                // 4. ONE GENTLE ACTION (one experiment)
                childGentleAction(child: child, deepDive: deepDive)

                // 5. ONE PREMIUM CTA (single entry point)
                advancedInsightsCTAChild(child: child)
            } else {
                // No child selected - prompt to add one
                noChildSelectedState
            }
        }
        .sheet(isPresented: $showingChildPickerSheet) {
            InsightsChildPickerSheet(
                children: childrenStore.activeChildren,
                selectedChildIndex: Binding(
                    get: { selectedChildIndex },
                    set: { selectChildAtIndex($0) }
                )
            )
        }
    }

    // MARK: - Child Data Calculations

    private func calculateChildDailyData(for child: Child) -> [InsightGenerationUseCase.DailyActivityData] {
        let calendar = Calendar.current
        let now = Date()
        let events = behaviorsStore.behaviorEvents.filter { $0.childId == child.id }

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

            let dayEvents = events.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let positive = dayEvents.filter { $0.pointsApplied > 0 }.count
            let negative = dayEvents.filter { $0.pointsApplied < 0 }.count

            return InsightGenerationUseCase.DailyActivityData(date: date, positive: positive, negative: negative)
        }.reversed()
    }

    private func calculateChildTrajectory(for child: Child) -> (percentChange: Double, thisWeek: Int, lastWeek: Int) {
        let calendar = Calendar.current
        let now = Date()

        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) else {
            return (0, 0, 0)
        }

        let events = behaviorsStore.behaviorEvents.filter { $0.childId == child.id }
        let thisWeekEvents = events.filter { $0.timestamp >= thisWeekStart && $0.pointsApplied > 0 }
        let lastWeekEvents = events.filter { $0.timestamp >= lastWeekStart && $0.timestamp < thisWeekStart && $0.pointsApplied > 0 }

        let thisWeekCount = thisWeekEvents.count
        let lastWeekCount = lastWeekEvents.count

        let percentChange: Double
        if lastWeekCount > 0 {
            percentChange = Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount) * 100
        } else if thisWeekCount > 0 {
            percentChange = 100
        } else {
            percentChange = 0
        }

        return (percentChange, thisWeekCount, lastWeekCount)
    }

    // MARK: - Child Hero Card (with integrated child picker)

    private func childHeroCard(child: Child, deepDive: InsightGenerationUseCase.ChildDeepDiveData, dailyData: [InsightGenerationUseCase.DailyActivityData]) -> some View {
        let heroMessage = childHeroMessage(child: child, deepDive: deepDive)
        let hasMultipleChildren = childrenStore.activeChildren.count > 1

        return VStack(alignment: .leading, spacing: 12) {
            // Header with child avatar, name, and optional "Change" button
            HStack(spacing: 10) {
                Circle()
                    .fill(child.colorTag.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(child.initials)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    )

                Text(child.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeProvider.primaryText)

                // "Change" button for multi-child families (integrated into hero card)
                if hasMultipleChildren {
                    Button(action: { showingChildPickerSheet = true }) {
                        Text("Change")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeProvider.accentColor)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Period label (right-aligned)
                Text(selectedPeriod.shortLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.secondaryText)
            }

            Text(heroMessage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeProvider.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Child-specific Week Activity Dots
            WeekActivityDots(dailyData: dailyData, accentColor: child.colorTag.color)
                .padding(.top, 4)

            let positiveCount = deepDive.positiveEvents.count
            let challengeCount = deepDive.challengeEvents.count
            let total = positiveCount + challengeCount
            if total > 0 && total < 5 {
                Text("Early pattern from \(total) moments")
                    .font(.system(size: 11))
                    .foregroundColor(themeProvider.secondaryText)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeProvider.cardBackground)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func childHeroMessage(child: Child, deepDive: InsightGenerationUseCase.ChildDeepDiveData) -> String {
        let positiveCount = deepDive.positiveEvents.count
        let challengeCount = deepDive.challengeEvents.count
        let total = positiveCount + challengeCount

        if total == 0 {
            return "Start logging moments for \(child.name) to see patterns."
        }

        let ratio = challengeCount > 0 ? Double(positiveCount) / Double(challengeCount) : Double(positiveCount)

        if ratio >= 3 {
            return "\(child.name) is in a positive flow. Wins are leading."
        } else if ratio >= 1.5 {
            return "More wins than challenges for \(child.name) right now."
        } else if positiveCount > 0 {
            return "Challenges are frequent, but wins are still happening."
        } else {
            return "Tough stretch. You're staying engaged."
        }
    }

    // MARK: - Child Micro-Hints

    private func childMicroHints(child: Child, deepDive: InsightGenerationUseCase.ChildDeepDiveData, trajectory: (percentChange: Double, thisWeek: Int, lastWeek: Int)) -> some View {
        let totalPoints = deepDive.positiveEvents.reduce(0) { $0 + $1.pointsApplied } + deepDive.challengeEvents.reduce(0) { $0 + $1.pointsApplied }
        let trend: TrendArrowBadge.Trend = trajectory.percentChange > 5 ? .up : (trajectory.percentChange < -5 ? .down : .steady)

        return HStack(spacing: 10) {
            // Hint 1: Stars with trend indicator
            EnhancedMicroHintChip(
                icon: "star.fill",
                label: "\(totalPoints) stars",
                sublabel: "this period",
                color: totalPoints >= 0 ? themeProvider.positiveColor : themeProvider.challengeColor,
                trend: trajectory.lastWeek > 0 ? trend : nil,
                percentChange: trajectory.lastWeek > 0 ? trajectory.percentChange : nil
            )

            // Hint 2: Top behavior chip
            if let topBehavior = deepDive.topWinBehavior?.name {
                microHintChip(
                    icon: "hand.thumbsup.fill",
                    label: topBehavior,
                    sublabel: "top win",
                    color: child.colorTag.color
                )
            } else {
                let positiveCount = deepDive.positiveEvents.count
                let challengeCount = deepDive.challengeEvents.count
                microHintChip(
                    icon: "chart.bar.fill",
                    label: "\(positiveCount) wins",
                    sublabel: "\(challengeCount) challenges",
                    color: child.colorTag.color
                )
            }
        }
    }

    // MARK: - Child Behavior Pills

    @ViewBuilder
    private func childBehaviorPills(child: Child, deepDive: InsightGenerationUseCase.ChildDeepDiveData) -> some View {
        let behaviors = buildChildBehaviors(deepDive: deepDive)

        if !behaviors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Wins")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeProvider.positiveColor)
                    Text("&")
                        .font(.system(size: 11))
                        .foregroundColor(themeProvider.secondaryText)
                    Text("work-ons")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeProvider.challengeColor)
                }

                BehaviorPillStack(
                    behaviors: behaviors,
                    maxVisible: 3,
                    showTruncationHint: false
                )
            }
        }
    }

    private func buildChildBehaviors(deepDive: InsightGenerationUseCase.ChildDeepDiveData) -> [BehaviorPillStack.BehaviorItem] {
        var behaviors: [BehaviorPillStack.BehaviorItem] = []

        // Add top wins
        if let topWin = deepDive.topWinBehavior {
            behaviors.append(BehaviorPillStack.BehaviorItem(
                name: topWin.name,
                count: deepDive.topWinCount,
                isPositive: true
            ))
        }

        // Add top challenge
        if let topChallenge = deepDive.topChallengeBehavior {
            behaviors.append(BehaviorPillStack.BehaviorItem(
                name: topChallenge.name,
                count: deepDive.topChallengeCount,
                isPositive: false
            ))
        }

        return behaviors
    }

    // MARK: - Child Gentle Action

    private func childGentleAction(child: Child, deepDive: InsightGenerationUseCase.ChildDeepDiveData) -> some View {
        let actionText = childActionSuggestion(child: child, deepDive: deepDive)

        return HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)

            Text(actionText)
                .font(.system(size: 14))
                .foregroundColor(themeProvider.primaryText)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.08))
        )
    }

    private func childActionSuggestion(child: Child, deepDive: InsightGenerationUseCase.ChildDeepDiveData) -> String {
        if let topBehavior = deepDive.topWinBehavior?.name {
            return "Try: Notice when \(child.name) does \"\(topBehavior)\" again."
        }

        let positiveCount = deepDive.positiveEvents.count
        let challengeCount = deepDive.challengeEvents.count
        let total = positiveCount + challengeCount
        if total == 0 {
            return "Try: Log one moment for \(child.name) today."
        }

        let ratio = challengeCount > 0 ? Double(positiveCount) / Double(challengeCount) : Double(positiveCount)

        if ratio >= 1.5 {
            return "Try: Mention one specific win to \(child.name) today."
        } else {
            return "Try: Catch \(child.name) doing something small but good."
        }
    }

    // MARK: - You Scope Content
    // Structure: Hero takeaway + reflection dots → 2 micro-hints → reflection correlation → 1 gentle action → 1 premium CTA
    // Parent habit tracking lives here, NOT called "streak"

    private var reflectionInsightUseCase: ReflectionInsightUseCase {
        ReflectionInsightUseCase(repository: repository, behaviorsStore: behaviorsStore, childrenStore: childrenStore)
    }

    @ViewBuilder
    private var youScopeContent: some View {
        VStack(spacing: 16) {
            // 1. HERO TAKEAWAY with reflection dots
            youHeroCard

            // 2. TWO MICRO-HINTS (tiny dashboard feel)
            youMicroHints

            // 3. REFLECTION CORRELATION (shows impact of parent engagement)
            youReflectionCorrelation

            // 4. ONE GENTLE ACTION (reflection entry)
            reflectEntryCard

            // 5. ONE PREMIUM CTA (single entry point)
            advancedInsightsCTAYou

            // Secondary link: History (subtle, not a CTA)
            historyLinkRow
        }
    }

    // MARK: - You Hero Card

    private var youHeroCard: some View {
        let activeDays = progressionStore.parentActivity.activeDaysThisWeek
        let heroMessage = youHeroMessage(activeDays: activeDays)
        let reflectionDots = calculateParentReflectionDots()

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.plusColor)

                Text("Your Week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeProvider.secondaryText)

                Spacer()
            }

            Text(heroMessage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeProvider.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Reflection dots (days you logged)
            WeekActivityDots(dailyData: reflectionDots, accentColor: themeProvider.plusColor)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeProvider.cardBackground)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func calculateParentReflectionDots() -> [InsightGenerationUseCase.DailyActivityData] {
        let calendar = Calendar.current
        let now = Date()
        let events = behaviorsStore.behaviorEvents

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

            // Count all moments logged by parent that day
            let dayEvents = events.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let positive = dayEvents.filter { $0.pointsApplied > 0 }.count
            let negative = dayEvents.filter { $0.pointsApplied < 0 }.count

            return InsightGenerationUseCase.DailyActivityData(date: date, positive: positive, negative: negative)
        }.reversed()
    }

    private func youHeroMessage(activeDays: Int) -> String {
        if activeDays == 0 {
            return "This is your space to reflect. No pressure, just check-ins."
        } else if activeDays == 1 {
            return "You checked in once this week. Every moment counts."
        } else if activeDays >= 5 {
            return "You've been showing up consistently. That matters."
        } else {
            return "You've checked in \(activeDays) times this week. Keep going at your pace."
        }
    }

    // MARK: - You Micro-Hints

    private var youMicroHints: some View {
        let activeDays = progressionStore.parentActivity.activeDaysThisWeek
        let level = progressionStore.parentActivity.coachLevel

        return HStack(spacing: 10) {
            // Hint 1: Check-ins this week (NOT "streak")
            microHintChip(
                icon: "checkmark.circle.fill",
                label: "\(activeDays) check-ins",
                sublabel: "this week",
                color: activeDays >= 3 ? themeProvider.positiveColor : themeProvider.accentColor
            )

            // Hint 2: Coach level
            microHintChip(
                icon: "leaf.fill",
                label: "Level \(level)",
                sublabel: "coach",
                color: themeProvider.plusColor
            )
        }
    }

    // MARK: - You Reflection Correlation

    @ViewBuilder
    private var youReflectionCorrelation: some View {
        if let correlation = reflectionInsightUseCase.reflectionCorrelation(days: 30),
           correlation.percentageMorePositive > 0 {
            ReflectionCorrelationCard(
                percentageMorePositive: Double(correlation.percentageMorePositive),
                daysAnalyzed: correlation.daysAnalyzed
            )
        }
    }

    // MARK: - History Link Row (subtle, not a CTA)

    private var historyLinkRow: some View {
        NavigationLink(destination: HistoryView()) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13))
                    .foregroundColor(themeProvider.secondaryText)

                Text("View all history")
                    .font(.system(size: 13))
                    .foregroundColor(themeProvider.secondaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(themeProvider.secondaryText.opacity(0.5))
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View history")
    }

    // MARK: - Scope-Specific Advanced Insights CTAs

    /// Family scope CTA - routes to FamilyAnalyticsDashboard (aggregate view)
    @ViewBuilder
    private var advancedInsightsCTAFamily: some View {
        if childrenStore.activeChildren.isEmpty {
            // No children - show disabled state
            advancedInsightsCTABase(
                benefitLine: "Add a child to see patterns",
                destination: nil
            )
        } else if !isPlusSubscriber {
            // Free user - show paywall trigger
            Button(action: { showingPaywall = true }) {
                advancedInsightsCTAContent(
                    benefitLine: "See patterns across all your children",
                    showLock: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unlock Advanced Insights with TinyWins Plus")
        } else {
            // Plus subscriber - route to FamilyAnalyticsDashboard
            NavigationLink(destination: FamilyAnalyticsDashboard()) {
                advancedInsightsCTAContent(
                    benefitLine: "See patterns across all your children",
                    showLock: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Advanced Insights")
        }
    }

    /// Shared CTA visual content (used by Family scope)
    private func advancedInsightsCTAContent(benefitLine: String, showLock: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Advanced Insights")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeProvider.primaryText)
                    if showLock {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(themeProvider.secondaryText)
                    }
                }
                Text(benefitLine)
                    .font(.caption)
                    .foregroundColor(themeProvider.secondaryText)
            }

            Spacer()

            if showLock {
                Text("Plus")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
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
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeProvider.secondaryText)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(showLock ? 0.2 : 0.3), .pink.opacity(showLock ? 0.1 : 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    /// Child scope CTA - uses explicitly selected child
    private func advancedInsightsCTAChild(child: Child) -> some View {
        advancedInsightsCTABase(
            benefitLine: "See \(child.name)'s patterns over time",
            destination: PremiumAnalyticsDashboard(child: child)
        )
    }

    /// You scope CTA - parent-focused, may show kid connections
    @ViewBuilder
    private var advancedInsightsCTAYou: some View {
        if !isPlusSubscriber {
            advancedInsightsCTABase(
                benefitLine: "See how your check-ins connect to wins",
                destination: selectedChild.map { PremiumAnalyticsDashboard(child: $0) }
            )
        } else {
            // Plus subscribers see Kid Connection inline (no extra CTA)
            KidConnectionInsightView()
        }
    }

    /// Shared CTA base component
    @ViewBuilder
    private func advancedInsightsCTABase(benefitLine: String, destination: PremiumAnalyticsDashboard?) -> some View {
        if !isPlusSubscriber {
            Button(action: { showingPaywall = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Advanced Insights")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(themeProvider.primaryText)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(themeProvider.secondaryText)
                        }
                        Text(benefitLine)
                            .font(.caption)
                            .foregroundColor(themeProvider.secondaryText)
                    }

                    Spacer()

                    Text("Plus")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
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
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unlock Advanced Insights with TinyWins Plus")
        } else if let dest = destination {
            NavigationLink(destination: dest) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Advanced Insights")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(themeProvider.primaryText)
                        Text(benefitLine)
                            .font(.caption)
                            .foregroundColor(themeProvider.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeProvider.secondaryText)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeProvider.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Advanced Insights")
        } else {
            // No child available - show prompt to select one first
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeProvider.secondaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Advanced Insights")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeProvider.primaryText)
                    Text("Select a child in Child tab to see their patterns")
                        .font(.caption)
                        .foregroundColor(themeProvider.secondaryText)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.cardBackground.opacity(0.6))
            )
        }
    }

    // MARK: - Reflect Entry Card

    private var reflectEntryCard: some View {
        Button(action: { showingDailyCheckIn = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isEvening ? [.purple.opacity(0.2), .indigo.opacity(0.15)] : [.blue.opacity(0.15), .cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: isEvening ? "moon.stars.fill" : "sun.max.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isEvening ? [.purple, .indigo] : [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(isEvening ? "Evening Reflection" : "Daily Reflection")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeProvider.primaryText)
                    Text("How did today go?")
                        .font(.system(size: 12))
                        .foregroundColor(themeProvider.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeProvider.secondaryText.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isEvening ? Color.purple.opacity(0.2) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open daily reflection")
        .accessibilityHint("Double tap to reflect on your day")
    }

    // MARK: - History Link Card

    private var historyLinkCard: some View {
        NavigationLink(destination: HistoryView()) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.secondaryText)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("View History")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeProvider.primaryText)
                    Text("All past moments and reflections")
                        .font(.system(size: 12))
                        .foregroundColor(themeProvider.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeProvider.secondaryText.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View history")
    }

    // MARK: - No Child Selected State

    private var noChildSelectedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.child.circle")
                .font(.system(size: 40))
                .foregroundColor(themeProvider.secondaryText.opacity(0.5))

            Text("Select a child to view their progress")
                .font(.system(size: 15))
                .foregroundColor(themeProvider.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeProvider.cardBackground)
        )
    }

    // Old CTAs and sections removed - now using scope-specific CTAs above

}

// MARK: - Section Header View

struct SectionHeaderView: View {
    let title: String
    let icon: String
    var gradient: [Color] = [.blue, .cyan]

    var body: some View {
        VStack(spacing: 0) {
            // Divider line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [gradient[0].opacity(0.3), gradient.count > 1 ? gradient[1].opacity(0.1) : gradient[0].opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .padding(.bottom, 12)

            HStack(spacing: 10) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.15), gradient.count > 1 ? gradient[1].opacity(0.1) : gradient[0].opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    FamilyInsightsView()
        .environmentObject(repository)
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(RewardsStore(repository: repository))
        .environmentObject(InsightsStore(repository: repository))
        .environmentObject(ProgressionStore())
        .environmentObject(SubscriptionManager.shared)
}
