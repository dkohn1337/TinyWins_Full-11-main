import SwiftUI

// MARK: - INSIGHTS AUDIT (December 2024)
//
// ## What is Working
//
// 1. **InsightsContext** - Observable pattern for global scope/time state (InsightsContext.swift)
//    - Tracks scope (Family/Child/You), timeRange, and recently viewed children
//    - Proper environment injection via withInsightsContext()
//
// 2. **Deterministic CoachingEngine** (/InsightsEngine/InsightsEngineImpl.swift)
//    - Signal-based detection (goalAtRisk, goalStalled, routineForming, etc.)
//    - CardTemplates provide structured, testable card generation
//    - Evidence validation ensures cards link to real events
//    - Safety rails (max 1 risk card, max 2 improvement cards)
//    - Cooldown management prevents card fatigue
//    - Localization-ready structure with LocalizedContent
//
// 3. **Rich Analytics Infrastructure**
//    - AdvancedInsightsService for premium dashboards
//    - TraitAnalysisService for character radar
//    - PremiumAnalyticsDashboard and FamilyAnalyticsDashboard exist
//
// 4. **Visual Components Library** (InsightVisualComponents.swift)
//    - WeekActivityDots, TrendArrowBadge, BehaviorPillStack, MiniBarChart
//    - CharacterRadarChart for premium tier
//
// ## What is Confusing
//
// 1. **CHILD SELECTION - Multiple Sources of Truth** (CRITICAL)
//    - AppCoordinator.selectedChildId (persisted to UserDefaults)
//    - InsightsContext.scope (with embedded child UUID)
//    - InsightsViewModel.selectedChildId (separate ViewModel)
//    - FamilyInsightsView uses coordinator.selectedChildId
//    - CoachHomeView uses InsightsContext environment
//    - ChildInsightsView takes child: Child parameter directly
//    - PremiumAnalyticsDashboard takes child: Child parameter
//
//    RESULT: Navigating between screens can show inconsistent children.
//    User picks Emma in one place, sees Jake in another.
//
// 2. **TWO InsightsEngine IMPLEMENTATIONS**
//    - OLD: /Views/Insights/Core/InsightsEngine.swift
//      - generateInsights(scope:timeRange:events:...) returns CoachInsight
//      - No cooldowns, no evidence validation, no safety rails
//      - Used by CoachHomeView
//    - NEW: /InsightsEngine/InsightsEngineImpl.swift
//      - generateCards(childId:now:) returns CoachCard
//      - Full deterministic pipeline with evidence
//      - NOT integrated into main UI
//
// 3. **DEPRECATED BUT PRESENT FILES**
//    - InsightsView.swift marked "// DEPRECATED" but still exists
//    - Causes confusion about which is the actual entry point
//
// 4. **SCOPE MODEL COMPLEXITY**
//    - Family/Child/You scopes with different meanings
//    - "You" scope is parent reflection, different from child insights
//    - Not clear to users what each scope shows
//
// ## What is Redundant
//
// 1. CoachHomeView + FamilyInsightsView - two entry points for Insights tab
// 2. InsightsEngine + CoachingEngine - two card generation systems
// 3. InsightsScopeChips + InsightsContextBar - overlapping scope selectors
// 4. Multiple child picker sheets (ChildScopeSelectorSheet, ScopeSelectorSheet)
// 5. CoachInsight + CoachCard - similar but incompatible data models
//
// ## What is Missing for Product Promise
//
// 1. **Single Source of Truth for Child Selection**
//    - Need one persisted childId that all views respect
//    - Child Context Bar should be persistent anchor
//
// 2. **Integration of Deterministic Engine**
//    - CoachCard pipeline not used in main UI
//    - Evidence sheets not implemented
//    - Cooldowns not surfaced to user
//
// 3. **Clear Premium Value Ladder**
//    - Free tier should show "mini-dashboard" not just text
//    - Premium gates should be calm, not pushy
//    - Currently mixed signals on what's free vs paid
//
// 4. **Action-First Design**
//    - Current screens show data without clear next steps
//    - Coach cards should drive behavior, not just inform
//
// 5. **Multi-Child Clarity**
//    - Switching children should be obvious and fast
//    - Current flow requires multiple taps and sheet dismissals
//
// MARK: - END AUDIT

// MARK: - Insights Navigation State

/// Single source of truth for Insights navigation state.
/// This replaces the fragmented state across InsightsContext, AppCoordinator, and InsightsViewModel.
///
/// ARCHITECTURE NOTE: Uses ObservableObject (not @Observable) for stable NavigationPath binding.
/// The @Observable macro creates issues when used with NavigationPath because @Bindable
/// wrappers created inside view body get recreated on each render, causing navigation resets.
final class InsightsNavigationState: ObservableObject {

    // MARK: - Child Selection (Single Source of Truth)

    /// The currently selected child for insights.
    /// This is THE canonical source - all child-specific views read from here.
    @Published private(set) var selectedChildId: UUID? {
        didSet {
            persistSelection()
        }
    }

    /// Recently viewed children for smart ordering
    @Published private(set) var recentChildIds: [UUID] = []

    // MARK: - Time Range

    @Published var timeRange: InsightsTimeRange = .week

    // MARK: - Navigation Path

    @Published var path = NavigationPath()

    // MARK: - Sheet State

    @Published var showingChildPicker = false
    @Published var showingEvidenceSheet: CoachCard?

    // MARK: - Initialization

    init() {
        loadPersistedSelection()
    }

    // MARK: - Child Selection Actions

    func selectChild(_ childId: UUID) {
        selectedChildId = childId
        trackRecent(childId)
    }

    func clearChildSelection() {
        selectedChildId = nil
    }

    // MARK: - Convenience

    func selectedChild(from children: [Child]) -> Child? {
        guard let id = selectedChildId else { return nil }
        return children.first { $0.id == id }
    }

    func sortedChildren(_ children: [Child]) -> [Child] {
        children.sorted { a, b in
            let aIndex = recentChildIds.firstIndex(of: a.id)
            let bIndex = recentChildIds.firstIndex(of: b.id)

            switch (aIndex, bIndex) {
            case (.some(let ai), .some(let bi)):
                return ai < bi
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }

    // MARK: - Child Selection Resilience

    /// Validation result for child selection state
    enum ChildSelectionState {
        case noChildren                      // No children exist at all
        case validSelection(Child)           // Selected child exists and is valid
        case invalidSelection(fallback: Child?) // Selected child was deleted, here's fallback
        case noSelection(firstChild: Child?) // No child selected, suggest first
    }

    /// Validates and resolves the current child selection against available children.
    /// Call this when the view appears or when children list changes.
    ///
    /// ## Fallback Rules
    /// 1. If selected child exists → return it
    /// 2. If selected child deleted → try most recently viewed that still exists
    /// 3. If no recent child exists → try first child by createdAt
    /// 4. If no children → return .noChildren
    func validateSelection(against children: [Child]) -> ChildSelectionState {
        // No children at all
        guard !children.isEmpty else {
            selectedChildId = nil
            return .noChildren
        }

        // Current selection is valid
        if let id = selectedChildId, let child = children.first(where: { $0.id == id }) {
            return .validSelection(child)
        }

        // Selection invalid or missing - try fallback
        let fallback = resolveFallbackChild(from: children)

        if selectedChildId != nil {
            // Was selected but now invalid (deleted child)
            if let fb = fallback {
                selectedChildId = fb.id
                trackRecent(fb.id)
            } else {
                selectedChildId = nil
            }
            return .invalidSelection(fallback: fallback)
        } else {
            // No selection at all
            return .noSelection(firstChild: fallback)
        }
    }

    /// Resolves a fallback child using the priority rules:
    /// 1. Most recently viewed child that still exists
    /// 2. First child by creation order (oldest first, most likely primary child)
    private func resolveFallbackChild(from children: [Child]) -> Child? {
        // Try recent children first
        for recentId in recentChildIds {
            if let child = children.first(where: { $0.id == recentId }) {
                return child
            }
        }

        // Fall back to first child (sorted by creation order if available)
        return children.first
    }

    /// Ensures a valid child is selected. If no valid selection, applies fallback.
    /// Returns the resolved child or nil if no children exist.
    @discardableResult
    func ensureValidSelection(from children: [Child]) -> Child? {
        let state = validateSelection(against: children)

        switch state {
        case .noChildren:
            return nil
        case .validSelection(let child):
            return child
        case .invalidSelection(let fallback):
            return fallback
        case .noSelection(let firstChild):
            if let child = firstChild {
                selectChild(child.id)
            }
            return firstChild
        }
    }

    /// Clean up stale recent child IDs that no longer exist.
    /// Call periodically or when children list changes significantly.
    func pruneStaleRecentIds(validIds: Set<UUID>) {
        let before = recentChildIds.count
        recentChildIds.removeAll { !validIds.contains($0) }

        if recentChildIds.count != before {
            UserDefaults.standard.set(recentChildIds.map { $0.uuidString }, forKey: Self.recentChildrenKey)
        }
    }

    // MARK: - Persistence

    private static let selectedChildKey = "insights_selectedChildId"
    private static let recentChildrenKey = "insights_recentChildIds"

    private func persistSelection() {
        if let id = selectedChildId {
            UserDefaults.standard.set(id.uuidString, forKey: Self.selectedChildKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedChildKey)
        }
    }

    private func loadPersistedSelection() {
        if let idString = UserDefaults.standard.string(forKey: Self.selectedChildKey),
           let id = UUID(uuidString: idString) {
            selectedChildId = id
        }

        if let recentStrings = UserDefaults.standard.stringArray(forKey: Self.recentChildrenKey) {
            recentChildIds = recentStrings.compactMap { UUID(uuidString: $0) }
        }
    }

    private func trackRecent(_ childId: UUID) {
        recentChildIds.removeAll { $0 == childId }
        recentChildIds.insert(childId, at: 0)
        if recentChildIds.count > 10 {
            recentChildIds = Array(recentChildIds.prefix(10))
        }

        UserDefaults.standard.set(recentChildIds.map { $0.uuidString }, forKey: Self.recentChildrenKey)
    }
}

// MARK: - Insights Home View

/// The main landing page for the Insights tab.
/// Uses the deterministic CoachingEngine to generate evidence-based coach cards.
///
/// ## Structure
/// 1. Child Context Bar (sticky) - shows selected child, tap to switch
/// 2. Coach Cards Section - action-oriented insights from the engine
/// 3. Proof Summary - evidence backing the insights
/// 4. Explore Section - links to deeper analytics (premium-gated where appropriate)
struct InsightsHomeView: View {
    @Environment(\.themeProvider) private var theme
    @EnvironmentObject private var navigation: InsightsNavigationState
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var cards: [CoachCard] = []
    @State private var isLoading = true
    @State private var showingDebugReport = false
    @State private var impressionTracker: CardImpressionTracker?

    // Coaching engine instance (cached to preserve cooldown manager state)
    @State private var _engine: CoachingEngine?
    private var engine: CoachingEngine {
        if let existing = _engine {
            return existing
        }
        let dataProvider = RepositoryDataProvider(repository: repository)
        let newEngine = CoachingEngineImpl(dataProvider: dataProvider)
        // Note: Can't set _engine here as this is a computed property
        return newEngine
    }

    private func getOrCreateEngine() -> CoachingEngine {
        if _engine == nil {
            let dataProvider = RepositoryDataProvider(repository: repository)
            _engine = CoachingEngineImpl(dataProvider: dataProvider)
        }
        return _engine!
    }

    var body: some View {
        NavigationStack(path: $navigation.path) {
            VStack(spacing: 0) {
                // Sticky Child Context Bar
                ChildContextBar()

                ScrollView {
                    VStack(spacing: 0) {
                        // Coach Cards Section with warm tint
                        VStack(spacing: AppSpacing.cardGap) {
                            coachCardsSection

                            // Proof Summary (if cards have evidence)
                            if hasEvidence {
                                proofSummarySection
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.vertical, AppSpacing.sectionGap)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.02),
                                    theme.backgroundColor
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Section divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 1)
                            .padding(.horizontal, AppSpacing.screenPadding)

                        // Explore Section with subtle blue tint
                        VStack(spacing: AppSpacing.cardGap) {
                            exploreSection
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.vertical, AppSpacing.sectionGap)
                        .background(
                            LinearGradient(
                                colors: [
                                    theme.backgroundColor,
                                    Color.blue.opacity(0.015)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Premium nudge (for free tier)
                        if !subscriptionManager.effectiveIsPlusSubscriber {
                            premiumNudge
                                .padding(.horizontal, AppSpacing.screenPadding)
                                .padding(.bottom, AppSpacing.sectionGap)
                        }

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .accessibilityIdentifier(InsightsAccessibilityIdentifiers.insightsHomeRoot)
            .navigationTitle(Text("Insights", tableName: "Insights"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDebugReport = true }) {
                        Image(systemName: "ladybug")
                    }
                }
                #endif
            }
            .sheet(isPresented: $navigation.showingChildPicker) {
                InsightsChildSelectionSheet()
                    .environmentObject(navigation)
            }
            .sheet(item: $navigation.showingEvidenceSheet) { card in
                EvidenceSheetView(card: card)
                    .environmentObject(navigation)
            }
            #if DEBUG
            .sheet(isPresented: $showingDebugReport) {
                InsightsEngineDebugView()
            }
            #endif
            .onAppear {
                validateAndLoadCards()
            }
            .onChange(of: navigation.selectedChildId) { _, _ in
                loadCards()
            }
            .onChange(of: childrenStore.activeChildren.count) { _, _ in
                // Re-validate when children list changes (child added/deleted)
                validateAndLoadCards()
            }
            .onReceive(NotificationCenter.default.publisher(for: .demoDataDidLoad)) { notification in
                // Demo data was loaded - reset engine and child selection
                handleDemoDataLoaded(notification: notification)
            }
            .navigationDestination(for: InsightsDestination.self) { destination in
                destinationView(for: destination)
            }
        }
    }

    // MARK: - Coach Cards Section

    /// Cards that represent habit-forming patterns (can be consolidated)
    private var habitFormingCards: [CoachCard] {
        cards.filter { card in
            card.templateId == "routine_forming" || card.templateId == "positive_pattern"
        }
    }

    /// Cards that are NOT habit-forming (displayed individually)
    private var otherCards: [CoachCard] {
        cards.filter { card in
            card.templateId != "routine_forming" && card.templateId != "positive_pattern"
        }
    }

    @ViewBuilder
    private var coachCardsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundColor(theme.positiveColor)

                Text("Patterns This Week", tableName: "Insights")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
            }

            if isLoading {
                loadingState
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.cardsLoadingIndicator)
            } else if cards.isEmpty {
                emptyState
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.cardsEmptyState)
            } else {
                // Consolidated habits card (when 2+ habit-forming cards exist)
                if habitFormingCards.count >= 2 {
                    HabitsFormingCard(cards: habitFormingCards) { card in
                        recordCardInteraction(card)
                        navigation.showingEvidenceSheet = card
                    }
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.coachCard(cardId: "habits-forming"))
                    .onAppear {
                        for card in habitFormingCards {
                            impressionTracker?.cardBecameVisible(card)
                        }
                    }
                    .onDisappear {
                        for card in habitFormingCards {
                            impressionTracker?.cardBecameHidden(card)
                        }
                    }
                } else {
                    // Single habit-forming card (display individually)
                    ForEach(habitFormingCards) { card in
                        CoachCardView(card: card) {
                            recordCardInteraction(card)
                            navigation.showingEvidenceSheet = card
                        }
                        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.coachCard(cardId: card.id))
                        .onAppear {
                            impressionTracker?.cardBecameVisible(card)
                        }
                        .onDisappear {
                            impressionTracker?.cardBecameHidden(card)
                        }
                    }
                }

                // Other cards (always displayed individually)
                ForEach(otherCards) { card in
                    CoachCardView(card: card) {
                        recordCardInteraction(card)
                        navigation.showingEvidenceSheet = card
                    }
                    .accessibilityIdentifier(InsightsAccessibilityIdentifiers.coachCard(cardId: card.id))
                    .onAppear {
                        impressionTracker?.cardBecameVisible(card)
                    }
                    .onDisappear {
                        impressionTracker?.cardBecameHidden(card)
                    }
                }
            }
        }
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.coachCardListRoot)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Analyzing patterns...", tableName: "Insights")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Color.yellow.opacity(0.3), radius: 8, y: 4)

            VStack(spacing: 8) {
                Text("Keep building the picture", tableName: "Insights")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                Text("Log a few more moments and insights will appear here.", tableName: "Insights")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.06),
                    theme.cardBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Proof Summary Section

    private var hasEvidence: Bool {
        cards.contains { $0.hasValidEvidence }
    }

    @ViewBuilder
    private var proofSummarySection: some View {
        let totalEvidence = cards.reduce(0) { $0 + $1.evidenceEventIds.count }
        let evidenceWindow = cards.first?.evidenceWindow ?? 7

        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("Based on \(totalEvidence) real moments", tableName: "Insights")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText)
                }

                Spacer()

                Text("Last \(evidenceWindow) days", tableName: "Insights")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.positiveColor.opacity(0.1))
                    .cornerRadius(8)
            }

            // Quick stats row with warmer colors
            HStack(spacing: 12) {
                proofStatChip(
                    icon: "heart.fill",
                    label: "Patterns found",
                    value: "\(cards.count)",
                    color: Color.pink
                )

                proofStatChip(
                    icon: "star.fill",
                    label: "Moments reviewed",
                    value: "\(totalEvidence)",
                    color: .yellow
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.05),
                    theme.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
        )
    }

    private func proofStatChip(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Explore Section

    @ViewBuilder
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
            Text("Explore", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.primaryText)

            // History link (free)
            exploreLink(
                icon: "clock.arrow.circlepath",
                title: "History",
                subtitle: "Browse all logged moments",
                isPremium: false,
                linkStyle: .standard(color: .blue),
                accessibilityId: InsightsAccessibilityIdentifiers.exploreHistoryLink
            ) {
                navigation.path.append(InsightsDestination.history)
            }

            // Growth Rings (FREE - emotional hook feature)
            exploreLink(
                icon: "circle.hexagongrid.fill",
                title: "Growth Rings",
                subtitle: "See character growth over time",
                isPremium: false,
                linkStyle: .multiColor,  // Special multi-ring colored icon
                accessibilityId: InsightsAccessibilityIdentifiers.exploreGrowthRingsLink
            ) {
                navigation.path.append(InsightsDestination.growthRings)
            }

            // Character Garden (FREE - beautiful plant visualization)
            exploreLink(
                icon: "leaf.fill",
                title: "Character Garden",
                subtitle: "Watch character traits bloom",
                isPremium: false,
                linkStyle: .garden,  // Special garden-themed icon
                accessibilityId: "insights_explore_garden_link"
            ) {
                navigation.path.append(InsightsDestination.characterGarden)
            }

            // Advanced Analytics (premium)
            exploreLink(
                icon: "chart.xyaxis.line",
                title: "Advanced Analytics",
                subtitle: "Deep patterns and insights",
                isPremium: true,
                linkStyle: .premium,  // Purple gradient for premium
                accessibilityId: InsightsAccessibilityIdentifiers.advancedInsightsEntryPoint
            ) {
                if subscriptionManager.effectiveIsPlusSubscriber {
                    navigation.path.append(InsightsDestination.advancedAnalytics)
                } else {
                    navigation.path.append(InsightsDestination.paywall)
                }
            }
        }
    }

    // MARK: - Explore Link Styles

    private enum ExploreLinkStyle {
        case standard(color: Color)
        case multiColor      // For Growth Rings - shows trait colors
        case garden          // For Character Garden - shows plant/leaf theme
        case premium         // Purple gradient for paid features
    }

    private func exploreLink(
        icon: String,
        title: String,
        subtitle: String,
        isPremium: Bool,
        linkStyle: ExploreLinkStyle,
        accessibilityId: String,
        action: @escaping () -> Void
    ) -> some View {
        let showPremiumBadge = isPremium && !subscriptionManager.effectiveIsPlusSubscriber

        return Button(action: action) {
            HStack(spacing: 14) {
                // Dynamic icon based on style
                exploreLinkIcon(icon: icon, style: linkStyle)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)

                        if showPremiumBadge {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                Text("Plus")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.6, green: 0.3, blue: 0.9), Color(red: 0.8, green: 0.4, blue: 0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(6)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(exploreLinkChevronColor(style: linkStyle))
            }
            .padding(16)
            .background(exploreLinkBackground(style: linkStyle))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }

    @ViewBuilder
    private func exploreLinkIcon(icon: String, style: ExploreLinkStyle) -> some View {
        switch style {
        case .standard(let color):
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.3), radius: 4, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

        case .multiColor:
            // Growth Rings - beautiful tree ring visualization
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.2),
                                Color.green.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)

                // Outer ring - warm earthy tone
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.4),
                                Color(red: 0.7, green: 0.5, blue: 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 5
                    )
                    .frame(width: 44, height: 44)

                // Middle ring - fresh green
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.75, blue: 0.45),
                                Color(red: 0.3, green: 0.6, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 32, height: 32)

                // Inner ring - light ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.85, blue: 0.6),
                                Color(red: 0.9, green: 0.75, blue: 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 20, height: 20)

                // Center with seedling icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.7, blue: 0.4),
                                    Color(red: 0.2, green: 0.55, blue: 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 14, height: 14)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.4), radius: 6, y: 3)

        case .garden:
            // Character Garden - beautiful plant/nature themed icon
            ZStack {
                // Soft glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.25),
                                Color.yellow.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)

                // Main circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.7, blue: 0.4),
                                Color(red: 0.25, green: 0.55, blue: 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                // Plant/flower icon
                ZStack {
                    // Stem
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.4, green: 0.65, blue: 0.35))
                        .frame(width: 3, height: 14)
                        .offset(y: 5)

                    // Flower petals
                    ForEach(0..<5) { i in
                        Ellipse()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 8, height: 12)
                            .offset(y: -6)
                            .rotationEffect(.degrees(Double(i) * 72))
                    }

                    // Flower center
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 7, height: 7)
                }
            }
            .shadow(color: Color.green.opacity(0.4), radius: 6, y: 3)

        case .premium:
            // Premium purple gradient with chart icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.25, blue: 0.85),
                                Color(red: 0.75, green: 0.35, blue: 0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.purple.opacity(0.4), radius: 4, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    private func exploreLinkChevronColor(style: ExploreLinkStyle) -> Color {
        switch style {
        case .standard(let color): return color.opacity(0.5)
        case .multiColor: return theme.positiveColor.opacity(0.5)
        case .garden: return Color.green.opacity(0.5)
        case .premium: return Color.purple.opacity(0.5)
        }
    }

    @ViewBuilder
    private func exploreLinkBackground(style: ExploreLinkStyle) -> some View {
        let (tintColor, borderColor): (Color, Color) = {
            switch style {
            case .standard(let color): return (color, color)
            case .multiColor: return (theme.positiveColor, theme.positiveColor)
            case .garden: return (Color.green, Color.green)
            case .premium: return (Color.purple, Color.purple)
            }
        }()

        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [tintColor.opacity(0.05), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(borderColor.opacity(0.1), lineWidth: 1)
            )
    }

    // MARK: - Premium Nudge

    private var premiumNudge: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Go deeper with TinyWins+", tableName: "Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
            }

            Text("Unlock character radar, growth trends, and advanced patterns.", tableName: "Insights")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                navigation.path.append(InsightsDestination.paywall)
            } label: {
                Text("See what's included", tableName: "Insights")
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
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.premiumNudge)
    }

    // MARK: - Navigation Destinations

    /// Get the effective child for navigation destinations.
    /// Falls back to first active child if none selected.
    private var effectiveChild: Child? {
        navigation.selectedChild(from: childrenStore.activeChildren)
            ?? childrenStore.activeChildren.first
    }

    @ViewBuilder
    private func destinationView(for destination: InsightsDestination) -> some View {
        switch destination {
        case .history:
            HistoryView()
        case .growthRings:
            if let child = effectiveChild {
                GrowthRingsView(child: child)
            } else {
                noChildSelectedView
            }
        case .characterGarden:
            if let child = effectiveChild {
                CharacterGardenView(
                    viewModel: CharacterGardenViewModel(
                        child: child,
                        events: repository.appData.behaviorEvents,
                        behaviorTypes: repository.appData.behaviorTypes
                    )
                )
            } else {
                noChildSelectedView
            }
        case .advancedAnalytics:
            if let child = effectiveChild {
                PremiumAnalyticsDashboard(child: child)
            } else {
                FamilyAnalyticsDashboard()
            }
        case .paywall:
            PlusPaywallView()
        case .childDetail(let childId):
            if let child = childrenStore.activeChildren.first(where: { $0.id == childId }) {
                ChildInsightsDetailView(child: child)
            } else {
                noChildSelectedView
            }
        }
    }

    /// Fallback view when no child is available
    private var noChildSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryText)

            Text("No Child Selected")
                .font(.headline)
                .foregroundColor(theme.primaryText)

            Text("Add a child in the Kids tab to see their insights.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    /// Validates child selection and loads cards.
    /// This is the primary entry point - ensures selection is valid before loading.
    private func validateAndLoadCards() {
        // Validate and auto-fix selection
        let state = navigation.validateSelection(against: childrenStore.activeChildren)

        switch state {
        case .noChildren:
            isLoading = false
            cards = []
            return

        case .validSelection:
            // Selection is valid, proceed to load
            break

        case .invalidSelection(let fallback):
            // Child was deleted, fallback applied (or nil if no children)
            if fallback == nil {
                isLoading = false
                cards = []
                return
            }
            // Fallback was applied, proceed to load

        case .noSelection(let firstChild):
            // No selection yet, select the first child
            if let child = firstChild {
                navigation.selectChild(child.id)
            } else {
                isLoading = false
                cards = []
                return
            }
        }

        // Prune any stale recent IDs
        let validIds = Set(childrenStore.activeChildren.map { $0.id })
        navigation.pruneStaleRecentIds(validIds: validIds)

        loadCards()
    }

    private func loadCards() {
        isLoading = true

        // Use selected child (should be valid after validateAndLoadCards)
        guard let selectedId = navigation.selectedChildId else {
            isLoading = false
            cards = []
            return
        }

        let childId = selectedId.uuidString

        // Get or create engine (preserves cooldown manager state)
        let currentEngine = getOrCreateEngine()

        // Generate cards using deterministic engine
        // NOTE: We do NOT call recordCardsDisplayed() here.
        // Cooldowns are recorded only when cards are actually seen by the user,
        // tracked via CardImpressionTracker (after threshold time or interaction).
        let generatedCards = currentEngine.generateCards(childId: childId, now: Date())

        cards = generatedCards
        isLoading = false

        // Initialize or update impression tracker
        if impressionTracker == nil {
            impressionTracker = CardImpressionTracker(engine: currentEngine)
        }
    }

    // MARK: - Impression Recording

    /// Record impression when user interacts with a card (opens evidence, taps CTA)
    private func recordCardInteraction(_ card: CoachCard) {
        impressionTracker?.recordInteraction(with: card)
    }

    // MARK: - Demo Data Handling

    /// Handle demo data loaded notification - reset engine and child selection
    private func handleDemoDataLoaded(notification: Notification) {
        // Reset cached engine so a new one is created with fresh data
        _engine = nil
        impressionTracker = nil

        // Select the first demo child
        if let firstChildId = notification.userInfo?["firstChildId"] as? UUID {
            navigation.selectChild(firstChildId)
        } else if let firstChild = childrenStore.activeChildren.first {
            navigation.selectChild(firstChild.id)
        }

        // Reload cards with fresh data
        validateAndLoadCards()

        #if DEBUG
        print("[InsightsHomeView] Demo data loaded - engine reset, child selected: \(navigation.selectedChildId?.uuidString ?? "none")")
        #endif
    }
}

// MARK: - Navigation Destinations

enum InsightsDestination: Hashable {
    case history
    case growthRings
    case characterGarden
    case advancedAnalytics
    case paywall
    case childDetail(UUID)
}

// MARK: - Notification Name

extension Notification.Name {
    /// Posted when demo data is loaded, so views can refresh
    static let demoDataDidLoad = Notification.Name("demoDataDidLoad")
}

// MARK: - Preview

#Preview("Insights Home") {
    let navigation = InsightsNavigationState()
    let repository = Repository.preview

    InsightsHomeView()
        .environmentObject(navigation)
        .environmentObject(repository)
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(SubscriptionManager())
        .withThemeProvider(ThemeProvider())
}
