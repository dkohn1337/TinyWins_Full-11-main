import Foundation
import Combine
import SwiftUI

/// ViewModel for the Today screen.
/// Manages first 48 hours coaching, parent reinforcement banners, and today-specific logic.
/// Extracted from TodayView to separate presentation logic from view.
///
/// Key performance optimization: Expensive computed properties are cached as @Published
/// properties and updated via Combine subscriptions with debouncing. This prevents
/// recalculation on every SwiftUI view render.
@MainActor
final class TodayViewModel: ObservableObject {

    // MARK: - Dependencies

    private let progressionStore: ProgressionStore
    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let userPreferences: UserPreferencesStore

    // MARK: - Cancellables for Combine subscriptions

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State (Banner/Coaching)

    @Published var showingFirst48Coaching = false
    @Published var first48Message: (title: String, message: String)?
    @Published var showingFirstPositiveBanner = false
    @Published var showingWeeklyParentRecap = false
    @Published var showingConsistencyBanner = false
    @Published var showingReturnBanner = false

    // MARK: - Cached Computed Properties (updated via Combine)

    /// Whether there are any moments logged today
    @Published private(set) var hasMomentsToday: Bool = false

    /// Yesterday's positive moment count for comparison
    @Published private(set) var yesterdayPositiveCount: Int = 0

    /// Children who have reached their goal target today
    @Published private(set) var childrenWithGoalsReached: [String] = []

    /// Data-driven focus for today
    @Published private(set) var todayFocus: TodayFocus?

    /// Week progress message for display
    @Published private(set) var cachedWeekProgressMessage: String = ""

    /// Days active this week (for metrics)
    @Published private(set) var daysActiveThisWeek: Int = 0

    // MARK: - Initialization

    init(
        progressionStore: ProgressionStore,
        behaviorsStore: BehaviorsStore,
        childrenStore: ChildrenStore,
        rewardsStore: RewardsStore,
        userPreferences: UserPreferencesStore
    ) {
        self.progressionStore = progressionStore
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
        self.rewardsStore = rewardsStore
        self.userPreferences = userPreferences

        // Set up Combine subscriptions to update cached properties
        setupSubscriptions()

        // Initial calculation
        recalculateCachedProperties()
    }

    // MARK: - Combine Subscriptions

    private func setupSubscriptions() {
        // Subscribe to behavior events changes with debouncing
        behaviorsStore.$behaviorEvents
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recalculateCachedProperties()
            }
            .store(in: &cancellables)

        // Subscribe to children changes
        childrenStore.$children
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recalculateCachedProperties()
            }
            .store(in: &cancellables)

        // Subscribe to rewards changes
        rewardsStore.$rewards
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recalculateCachedProperties()
            }
            .store(in: &cancellables)
    }

    private func recalculateCachedProperties() {
        // Update hasMomentsToday
        hasMomentsToday = !behaviorsStore.todayEvents.isEmpty

        // Update yesterdayPositiveCount
        yesterdayPositiveCount = calculateYesterdayPositiveCount()

        // Update childrenWithGoalsReached
        childrenWithGoalsReached = calculateChildrenWithGoalsReached()

        // Update todayFocus
        todayFocus = TodayFocusGenerator.shared.generateTodayFocus(
            children: childrenStore.activeChildren,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )

        // Update week metrics
        let metrics = progressionStore.weeklyParentMetrics(
            children: childrenStore.children,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes,
            rewards: rewardsStore.rewards
        )
        daysActiveThisWeek = metrics.daysActive
        cachedWeekProgressMessage = calculateWeekProgressMessage(daysActive: metrics.daysActive)
    }

    private func calculateYesterdayPositiveCount() -> Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        guard let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday) else { return 0 }

        return behaviorsStore.behaviorEvents.filter { event in
            event.timestamp >= startOfYesterday &&
            event.timestamp < endOfYesterday &&
            event.pointsApplied > 0
        }.count
    }

    private func calculateChildrenWithGoalsReached() -> [String] {
        childrenStore.activeChildren.compactMap { child in
            guard let goal = rewardsStore.activeReward(forChild: child.id) else { return nil }
            let earned = goal.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: true)
            return earned >= goal.targetPoints ? child.name : nil
        }
    }

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

    // MARK: - First 48 Hours Coaching Logic
    // Preserves exact logic from TodayView lines 38-68

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

    // MARK: - Parent Reinforcement Banner Logic
    // Preserves exact logic from TodayView lines 79-130

    private var todayDateString: String {
        DateFormatters.yearMonthDay.string(from: Date())
    }

    private var thisWeekString: String {
        DateFormatters.yearWeekString(from: Date())
    }

    private func thisWeekString(from date: Date) -> String {
        DateFormatters.yearWeekString(from: date)
    }

    func shouldShowFirstPositiveBanner() -> Bool {
        let todayString = DateFormatters.yearMonthDay.string(from: Date())
        let lastString = userPreferences.lastFirstPositiveBannerDate.map { DateFormatters.yearMonthDay.string(from: $0) } ?? ""
        guard lastString != todayString else { return false }
        return progressionStore.isFirstPositiveTodayForFamily(
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )
    }

    func shouldShowWeeklyParentRecap() -> Bool {
        let lastString = userPreferences.lastWeeklyRecapDate.map { thisWeekString(from: $0) } ?? ""
        guard lastString != thisWeekString else { return false }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1
    }

    func shouldShowConsistencyBanner() -> Bool {
        let lastString = userPreferences.lastConsistencyBannerDate.map { thisWeekString(from: $0) } ?? ""
        guard lastString != thisWeekString else { return false }
        let metrics = progressionStore.weeklyParentMetrics(
            children: childrenStore.children,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes,
            rewards: rewardsStore.rewards
        )
        return metrics.daysActive >= 3
    }

    func shouldShowReturnBanner() -> Bool {
        let lastString = userPreferences.lastReturnBannerDate.map { thisWeekString(from: $0) } ?? ""
        guard lastString != thisWeekString else { return false }
        guard let daysSinceLast = progressionStore.daysSinceLastActivity(
            behaviorEvents: behaviorsStore.behaviorEvents
        ) else { return false }
        return daysSinceLast >= 7
    }

    func markFirstPositiveBannerShown() {
        userPreferences.lastFirstPositiveBannerDate = Date()
    }

    func markWeeklyRecapShown() {
        userPreferences.lastWeeklyRecapDate = Date()
    }

    func markConsistencyBannerShown() {
        userPreferences.lastConsistencyBannerDate = Date()
    }

    func markReturnBannerShown() {
        userPreferences.lastReturnBannerDate = Date()
    }

    // MARK: - Week Progress Computation
    // Preserves exact logic from TodayView lines 132-152

    func daysIntoWeek() -> Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return 1
        }
        let daysFromStart = calendar.dateComponents([.day], from: startOfWeek, to: Date()).day ?? 0
        return daysFromStart + 1
    }

    func weekProgressMessage(thisWeekEvents: [BehaviorEvent]) -> String {
        let positive = thisWeekEvents.filter { $0.pointsApplied > 0 }.count
        let challenges = thisWeekEvents.filter { $0.pointsApplied < 0 }.count

        let days = daysIntoWeek()
        let dayText = days == 1 ? "day" : "days"

        if positive >= challenges {
            return "You are \(days) \(dayText) into this week. Nice start."
        } else {
            return "You are \(days) \(dayText) into this week. Tomorrow is a fresh chance."
        }
    }

    // MARK: - Banner Check (called on appear/refresh)

    func checkAndShowBanners() {
        // Check parent reinforcement banners in priority order
        if shouldShowFirstPositiveBanner() {
            showingFirstPositiveBanner = true
            markFirstPositiveBannerShown()
        } else if shouldShowWeeklyParentRecap() {
            showingWeeklyParentRecap = true
            markWeeklyRecapShown()
        } else if shouldShowConsistencyBanner() {
            showingConsistencyBanner = true
            markConsistencyBannerShown()
        } else if shouldShowReturnBanner() {
            showingReturnBanner = true
            markReturnBannerShown()
        }
    }
}
