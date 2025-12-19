import Foundation
import Combine
import SwiftUI

/// ViewModel for the Today screen.
///
/// PERFORMANCE REFACTOR:
/// - Single CombineLatest4 pipeline instead of 3 separate sinks
/// - Heavy compute runs off-main via recalcQueue
/// - No weeklyParentMetrics call (replaced with single-pass aggregation)
/// - Focus binding from generator's @Published (not one-time copy)
/// - 16ms micro-coalesce to batch bursty updates without perceived lag
/// - Visibility gate: defers heavy work until tab is visible to prevent frame drops during tab switch
@MainActor
final class TodayViewModel: ObservableObject {

    // MARK: - Dependencies

    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let userPreferences: UserPreferencesStore

    // MARK: - Internals

    private var cancellables = Set<AnyCancellable>()
    private let recalcQueue = DispatchQueue(label: "TinyWins.TodayViewModel.recalc", qos: .userInitiated)

    // MARK: - Visibility Gate (prevents heavy work during tab transitions)

    private var isVisible: Bool = true  // Start visible since Today is default tab
    private var pendingCachedProps: TodayCachedProps?
    private var lastCachedProps: TodayCachedProps = TodayCachedProps.empty(now: Date())

    // MARK: - State (single publish for all data properties)

    struct TodayState: Equatable {
        var hasMomentsToday: Bool = false
        var yesterdayPositiveCount: Int = 0
        var childrenWithGoalsReached: [String] = []
        var cachedWeekProgressMessage: String = ""
        var daysActiveThisWeek: Int = 0
        var todayEventsGroupedByChild: [UUID: [BehaviorEvent]] = [:]
    }

    // MARK: - Published State (single publish = single objectWillChange)

    @Published private(set) var state = TodayState()

    // Convenience accessors for backward compatibility
    var hasMomentsToday: Bool { state.hasMomentsToday }
    var yesterdayPositiveCount: Int { state.yesterdayPositiveCount }
    var childrenWithGoalsReached: [String] { state.childrenWithGoalsReached }
    var cachedWeekProgressMessage: String { state.cachedWeekProgressMessage }
    var daysActiveThisWeek: Int { state.daysActiveThisWeek }
    var todayEventsGroupedByChild: [UUID: [BehaviorEvent]] { state.todayEventsGroupedByChild }

    // Focus is separate since it comes from TodayFocusGenerator async
    @Published private(set) var todayFocus: TodayFocus?

    // MARK: - Banner / Coaching State

    @Published var showingFirst48Coaching = false
    @Published var first48Message: (title: String, message: String)?
    @Published var showingFirstPositiveBanner = false
    @Published var showingWeeklyParentRecap = false
    @Published var showingConsistencyBanner = false
    @Published var showingReturnBanner = false

    // MARK: - Init

    init(
        behaviorsStore: BehaviorsStore,
        childrenStore: ChildrenStore,
        rewardsStore: RewardsStore,
        userPreferences: UserPreferencesStore
    ) {
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
        self.rewardsStore = rewardsStore
        self.userPreferences = userPreferences

        #if DEBUG
        print("🟢 INIT TodayViewModel", ObjectIdentifier(self))
        #endif

        setupSubscriptions()
        setupFocusBinding()

        // Initial state setup using empty cached props
        applyEssentialProps(TodayCachedProps.empty(now: Date()))

        // Initial coaching check
        checkFirst48Coaching()

        // Trigger initial focus generation
        triggerFocusGeneration()
    }

    deinit {
        #if DEBUG
        print("🔴 DEINIT TodayViewModel", ObjectIdentifier(self))
        #endif
    }

    // MARK: - Visibility Gate

    /// Called by ContentView when tab visibility changes.
    /// PHASE 2: When becoming visible, applies pending state and deferred work after Task.yield().
    func setVisible(_ visible: Bool) {
        #if DEBUG
        print("👁️ TodayViewModel.setVisible(\(visible))")
        #endif

        isVisible = visible
        guard visible else { return }

        // Defer state application until after the tab switch animation settles
        Task { @MainActor in
            // Yield to let the tab transition complete first
            await Task.yield()

            // Apply any pending cached props that arrived while hidden
            if let pending = pendingCachedProps {
                pendingCachedProps = nil
                // Apply both essential props (state) and visible-only work
                applyEssentialProps(pending)
                applyVisibleOnlyWork(using: pending)
            } else {
                // No pending props, just run deferred work with last known state
                applyVisibleOnlyWork(using: lastCachedProps)
            }
        }
    }

    /// Work that should only run when visible (banners, coaching, focus generation)
    private func applyVisibleOnlyWork(using cached: TodayCachedProps) {
        checkFirst48Coaching()
        checkAndShowBanners(using: cached)
        triggerFocusGeneration()
    }

    // MARK: - Combine Subscriptions

    private func setupSubscriptions() {
        // Single pipeline: combine all store changes, compute off-main, apply on main
        // PERFORMANCE: Observe store snapshots (single publish) instead of individual properties
        Publishers.CombineLatest3(
            behaviorsStore.$snapshot,
            childrenStore.$snapshot,
            rewardsStore.$snapshot
        )
        .map { behaviorsSnapshot, childrenSnapshot, rewardsSnapshot in
            TodaySnapshot(
                behaviorEvents: behaviorsSnapshot.behaviorEvents,
                behaviorTypes: behaviorsSnapshot.behaviorTypes,
                children: childrenSnapshot.children,
                rewards: rewardsSnapshot.rewards
            )
        }
        .receive(on: recalcQueue)
        // Micro-coalesce: batch bursty updates without perceived lag
        .throttle(for: .milliseconds(16), scheduler: recalcQueue, latest: true)
        .map { snapshot in
            TodayCachedProps.compute(snapshot: snapshot, now: Date(), calendar: .current)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] cached in
            guard let self else { return }
            self.handleNewCachedProps(cached)
        }
        .store(in: &cancellables)
    }

    private func setupFocusBinding() {
        // Bind to generator's published focus so async updates propagate
        TodayFocusGenerator.shared.$todayFocus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] focus in
                self?.todayFocus = focus
            }
            .store(in: &cancellables)
    }

    // MARK: - Apply

    /// Routes new cached props through visibility gate.
    /// PHASE 2: Publish gating - when not visible, store pending state instead of publishing.
    /// This prevents hidden tabs from causing SwiftUI re-renders during tab transitions.
    private func handleNewCachedProps(_ cached: TodayCachedProps) {
        // Always store as last known state
        lastCachedProps = cached

        // PHASE 2: If not visible, defer ALL state updates to prevent re-renders
        guard isVisible else {
            pendingCachedProps = cached
            return
        }

        // Visible: apply state immediately
        applyEssentialProps(cached)
        applyVisibleOnlyWork(using: cached)
    }

    /// Essential props that must be applied immediately (used by UI bindings)
    /// PERFORMANCE: Builds complete TodayState and assigns once = single objectWillChange
    private func applyEssentialProps(_ cached: TodayCachedProps) {
        let todayEvents = behaviorsStore.todayEvents

        // Build new state struct (no publishes yet)
        var next = TodayState()
        next.hasMomentsToday = !todayEvents.isEmpty
        next.todayEventsGroupedByChild = Dictionary(grouping: todayEvents) { $0.childId }
        next.yesterdayPositiveCount = cached.yesterdayPositiveCount
        next.childrenWithGoalsReached = cached.childrenWithGoalsReached
        next.daysActiveThisWeek = cached.daysActiveThisWeek
        next.cachedWeekProgressMessage = calculateWeekProgressMessage(daysActive: cached.daysActiveThisWeek)

        // Single assignment = single objectWillChange
        state = next
    }

    /// Legacy method for initial setup - applies everything
    private func applyCachedProps(_ cached: TodayCachedProps) {
        lastCachedProps = cached
        applyEssentialProps(cached)
        applyVisibleOnlyWork(using: cached)
    }

    private func triggerFocusGeneration() {
        TodayFocusGenerator.shared.generateTodayFocusNonBlocking(
            children: childrenStore.activeChildren,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )
    }

    // MARK: - Week Progress Message

    private func calculateWeekProgressMessage(daysActive: Int) -> String {
        let dayText = daysActive == 1 ? "day" : "days"

        if daysActive == 0 {
            return "Every time you open TinyWins, you are building a habit that helps your kids."
        } else if daysActive == 1 {
            return "You have shown up on 1 day this week. Every moment you log matters."
        } else {
            return "You have shown up on \(daysActive) \(dayText) this week. You're building something lasting."
        }
    }

    // MARK: - First 48 Hours Coaching

    var isInFirst48Hours: Bool {
        guard let completedDate = userPreferences.onboardingCompletedDate else { return false }
        let hoursSince = Date().timeIntervalSince(completedDate) / 3600
        return hoursSince <= 48
    }

    var first48DayNumber: Int {
        guard let completedDate = userPreferences.onboardingCompletedDate else { return 0 }
        let daysSince = Calendar.current.dateComponents([.day], from: completedDate, to: Date()).day ?? 0
        return daysSince + 1
    }

    func checkFirst48Coaching() {
        guard isInFirst48Hours else { return }

        if first48DayNumber == 1 && !userPreferences.first48Day1Shown {
            first48Message = (
                title: "Your first day!",
                message: "Just try noticing one good moment today. It could be something tiny: a smile, a thank you, a task done without asking."
            )
            withAnimation { showingFirst48Coaching = true }
            userPreferences.first48Day1Shown = true
        } else if first48DayNumber == 2 && !userPreferences.first48Day2Shown {
            first48Message = (
                title: "Day 2: You're building a habit!",
                message: "Keep going. Small wins really do add up. Look for one moment that made you proud of your child today."
            )
            withAnimation { showingFirst48Coaching = true }
            userPreferences.first48Day2Shown = true
        }
    }

    func dismissFirst48Coaching() {
        withAnimation { showingFirst48Coaching = false }
    }

    // MARK: - Banners

    private func checkAndShowBanners(using cached: TodayCachedProps) {
        // Priority order same as original
        if shouldShowFirstPositiveBanner(using: cached) {
            showingFirstPositiveBanner = true
            userPreferences.lastFirstPositiveBannerDate = Date()
        } else if shouldShowWeeklyParentRecap() {
            showingWeeklyParentRecap = true
            userPreferences.lastWeeklyRecapDate = Date()
        } else if shouldShowConsistencyBanner(using: cached) {
            showingConsistencyBanner = true
            userPreferences.lastConsistencyBannerDate = Date()
        } else if shouldShowReturnBanner(using: cached) {
            showingReturnBanner = true
            userPreferences.lastReturnBannerDate = Date()
        }
    }

    private func shouldShowFirstPositiveBanner(using cached: TodayCachedProps) -> Bool {
        guard !isSameDay(userPreferences.lastFirstPositiveBannerDate, Date()) else { return false }
        return cached.hasPositiveMomentToday
    }

    private func shouldShowWeeklyParentRecap() -> Bool {
        guard !isSameWeek(userPreferences.lastWeeklyRecapDate, Date()) else { return false }
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 // Sunday
    }

    private func shouldShowConsistencyBanner(using cached: TodayCachedProps) -> Bool {
        guard !isSameWeek(userPreferences.lastConsistencyBannerDate, Date()) else { return false }
        return cached.daysActiveThisWeek >= 3
    }

    private func shouldShowReturnBanner(using cached: TodayCachedProps) -> Bool {
        guard !isSameWeek(userPreferences.lastReturnBannerDate, Date()) else { return false }
        guard let days = cached.daysSinceLastActivity else { return false }
        return days >= 7
    }

    // MARK: - Date Helpers

    private func isSameDay(_ a: Date?, _ b: Date) -> Bool {
        guard let a else { return false }
        return Calendar.current.isDate(a, inSameDayAs: b)
    }

    private func isSameWeek(_ a: Date?, _ b: Date) -> Bool {
        guard let a else { return false }
        let cal = Calendar.current
        let c1 = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: a)
        let c2 = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: b)
        return c1.yearForWeekOfYear == c2.yearForWeekOfYear && c1.weekOfYear == c2.weekOfYear
    }
}

// MARK: - Snapshot

private struct TodaySnapshot {
    let behaviorEvents: [BehaviorEvent]
    let behaviorTypes: [BehaviorType]
    let children: [Child]
    let rewards: [Reward]
}

// MARK: - Reward Info

private struct TodayRewardInfo {
    let rewardId: UUID
    let start: Date
    let targetPoints: Int
    let frozenEarnedPoints: Int?
}

// MARK: - Cached Props

private struct TodayCachedProps {
    let now: Date
    let yesterdayPositiveCount: Int
    let childrenWithGoalsReached: [String]
    let daysActiveThisWeek: Int

    // Banner inputs
    let hasPositiveMomentToday: Bool
    let daysSinceLastActivity: Int?

    static func empty(now: Date) -> TodayCachedProps {
        TodayCachedProps(
            now: now,
            yesterdayPositiveCount: 0,
            childrenWithGoalsReached: [],
            daysActiveThisWeek: 0,
            hasPositiveMomentToday: false,
            daysSinceLastActivity: nil
        )
    }

    /// Single-pass compute replacing weeklyParentMetrics and children×events loops
    static func compute(snapshot: TodaySnapshot, now: Date, calendar: Calendar) -> TodayCachedProps {
        let startOfToday = calendar.startOfDay(for: now)

        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now) else {
            return empty(now: now)
        }
        let startOfYesterday = calendar.startOfDay(for: yesterdayDate)
        let endOfYesterday = startOfToday

        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return empty(now: now)
        }

        // O(behaviorTypes): build fast lookup for positive detection
        var categoryByTypeId: [UUID: BehaviorCategory] = [:]
        categoryByTypeId.reserveCapacity(snapshot.behaviorTypes.count)
        for bt in snapshot.behaviorTypes {
            categoryByTypeId[bt.id] = bt.category
        }

        func isPositiveLike(_ e: BehaviorEvent) -> Bool {
            if let cat = categoryByTypeId[e.behaviorTypeId] {
                return cat == .positive || cat == .routinePositive
            }
            return e.pointsApplied > 0
        }

        // Select one active reward per child (lowest priority wins)
        let activeRewardByChild = selectActiveRewardByChild(rewards: snapshot.rewards)

        let minRewardStart: Date? = activeRewardByChild.values
            .map { $0.startDate ?? $0.createdDate }
            .min()

        let earliestNeeded = [startOfYesterday, sevenDaysAgo, minRewardStart].compactMap { $0 }.min()

        // Child name lookup
        var childNameById: [UUID: String] = [:]
        childNameById.reserveCapacity(snapshot.children.count)
        for c in snapshot.children {
            childNameById[c.id] = c.name
        }

        // Reward info lookup
        var rewardInfoByChild: [UUID: TodayRewardInfo] = [:]
        rewardInfoByChild.reserveCapacity(activeRewardByChild.count)
        for (childId, reward) in activeRewardByChild {
            let start = reward.startDate ?? reward.createdDate
            let frozen = reward.isRedeemed ? reward.frozenEarnedPoints : nil
            rewardInfoByChild[childId] = TodayRewardInfo(
                rewardId: reward.id,
                start: start,
                targetPoints: reward.targetPoints,
                frozenEarnedPoints: frozen
            )
        }

        // Accumulators
        var yesterdayPos = 0
        var activeDays = Set<Date>()
        activeDays.reserveCapacity(7)

        var earnedByChild: [UUID: Int] = [:]
        earnedByChild.reserveCapacity(rewardInfoByChild.count)

        var hasPositiveToday = false
        var latestActivity: Date?

        // Single bounded pass over events
        for e in snapshot.behaviorEvents {
            // Skip events outside our time window
            if let earliest = earliestNeeded, e.timestamp < earliest { continue }
            if e.timestamp > now { continue }

            // Track latest activity for return banner
            if let cur = latestActivity {
                if e.timestamp > cur { latestActivity = e.timestamp }
            } else {
                latestActivity = e.timestamp
            }

            // Yesterday positive count
            if e.timestamp >= startOfYesterday && e.timestamp < endOfYesterday && e.pointsApplied > 0 {
                yesterdayPos += 1
            }

            // Days active last 7 days
            if e.timestamp >= sevenDaysAgo {
                activeDays.insert(calendar.startOfDay(for: e.timestamp))
            }

            // Has positive today (for first positive banner)
            if !hasPositiveToday && e.timestamp >= startOfToday && isPositiveLike(e) {
                hasPositiveToday = true
            }

            // Reward progress aggregation (matches Reward.pointsEarnedInWindow semantics)
            guard e.pointsApplied > 0 else { continue }
            guard let info = rewardInfoByChild[e.childId] else { continue }
            guard info.frozenEarnedPoints == nil else { continue }
            guard e.timestamp >= info.start else { continue }

            // Reward assignment logic
            if let eventRewardId = e.rewardId {
                guard eventRewardId == info.rewardId else { continue }
            }
            // else: nil rewardId counts toward primary reward

            earnedByChild[e.childId, default: 0] += e.pointsApplied
        }

        // Children with goals reached
        var reachedNames: [String] = []
        reachedNames.reserveCapacity(rewardInfoByChild.count)
        for (childId, info) in rewardInfoByChild {
            let earned = info.frozenEarnedPoints ?? earnedByChild[childId, default: 0]
            if earned >= info.targetPoints, let name = childNameById[childId] {
                reachedNames.append(name)
            }
        }

        // Days since last activity
        let daysSinceLast: Int?
        if let last = latestActivity {
            let lastDay = calendar.startOfDay(for: last)
            let nowDay = calendar.startOfDay(for: now)
            daysSinceLast = calendar.dateComponents([.day], from: lastDay, to: nowDay).day
        } else {
            daysSinceLast = nil
        }

        return TodayCachedProps(
            now: now,
            yesterdayPositiveCount: yesterdayPos,
            childrenWithGoalsReached: reachedNames,
            daysActiveThisWeek: activeDays.count,
            hasPositiveMomentToday: hasPositiveToday,
            daysSinceLastActivity: daysSinceLast
        )
    }
}

// MARK: - Reward Selection

private func selectActiveRewardByChild(rewards: [Reward]) -> [UUID: Reward] {
    // Mirrors weeklyParentMetrics logic: filter(!isRedeemed && !isExpired), sort by priority asc, take first
    var selected: [UUID: Reward] = [:]
    selected.reserveCapacity(rewards.count)

    for r in rewards {
        if r.isRedeemed { continue }
        if r.isExpired { continue }

        if let existing = selected[r.childId] {
            if r.priority < existing.priority {
                selected[r.childId] = r
            }
        } else {
            selected[r.childId] = r
        }
    }

    return selected
}
