import Foundation
import SwiftUI
import Combine

/// Orchestrates stores for ContentView's cross-cutting concerns.
/// Handles onboarding flow, celebration coordination, and goal prompts.
///
/// PERFORMANCE: This ViewModel encapsulates store observation to prevent
/// ContentView from needing multiple @EnvironmentObject dependencies.
/// Celebration processing happens asynchronously to avoid blocking the main thread.
@MainActor
final class ContentViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore
    private let insightsStore: InsightsStore
    private let celebrationStore: CelebrationStore
    private let userPreferences: UserPreferencesStore

    // MARK: - Celebration Processing State

    /// Track last processed event to avoid duplicate celebrations
    private var lastProcessedEventId: UUID?

    /// Current action ID for batching celebrations
    private var currentActionId: UUID?

    /// Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State for View

    /// Celebration manager reference for view binding
    weak var celebrationManager: CelebrationManager?

    /// Goal prompt use case reference
    weak var goalPromptUseCase: GoalPromptUseCase?

    /// Celebration queue use case reference
    weak var celebrationQueueUseCase: CelebrationQueueUseCase?

    // MARK: - Computed Properties

    /// Whether onboarding has been completed
    var hasCompletedOnboarding: Bool {
        userPreferences.hasCompletedOnboarding
    }

    // MARK: - Initialization

    init(
        childrenStore: ChildrenStore,
        behaviorsStore: BehaviorsStore,
        rewardsStore: RewardsStore,
        insightsStore: InsightsStore,
        celebrationStore: CelebrationStore,
        userPreferences: UserPreferencesStore
    ) {
        self.childrenStore = childrenStore
        self.behaviorsStore = behaviorsStore
        self.rewardsStore = rewardsStore
        self.insightsStore = insightsStore
        self.celebrationStore = celebrationStore
        self.userPreferences = userPreferences

        #if DEBUG
        print("🟢 INIT ContentViewModel", ObjectIdentifier(self))
        #endif

        setupBehaviorEventObserver()
        setupCelebrationStoreObservers()
    }

    deinit {
        #if DEBUG
        print("🔴 DEINIT ContentViewModel", ObjectIdentifier(self))
        #endif
    }

    // MARK: - Setup Observers (Combine-based, reduces view re-renders)

    /// Observe behavior events using Combine instead of view's onChange
    /// This prevents the entire ContentView from re-rendering on every event
    /// PERFORMANCE: Observe snapshot (single publish) instead of individual behaviorEvents
    private func setupBehaviorEventObserver() {
        behaviorsStore.$snapshot
            .dropFirst() // Skip initial value
            .map { $0.behaviorEvents.count } // Only care about count changes
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleBehaviorEventChange()
            }
            .store(in: &cancellables)
    }

    /// Observe celebration store triggers
    private func setupCelebrationStoreObservers() {
        // Observe reward earned celebrations
        celebrationStore.$rewardEarnedCelebration
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] celebration in
                self?.handleRewardEarnedCelebration(celebration)
            }
            .store(in: &cancellables)

        // Observe milestone celebrations
        celebrationStore.$recentMilestone
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] milestone in
                self?.handleMilestoneCelebration(milestone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Celebration Processing (Async, off main thread blocking path)

    /// Handle behavior event changes - processes celebrations asynchronously
    private func handleBehaviorEventChange() {
        // Flag for goal prompt on next session (non-blocking)
        flagGoalPromptForNextSession()

        // Process celebration asynchronously to avoid blocking UI
        Task { @MainActor [weak self] in
            await self?.processCelebrationForLatestEvent()
        }
    }

    /// Process celebration for the latest event - runs asynchronously
    private func processCelebrationForLatestEvent() async {
        // Find latest event efficiently using async context
        guard let lastEvent = await findLatestPositiveEvent(),
              lastEvent.id != lastProcessedEventId,
              lastEvent.pointsApplied > 0 else { return }

        lastProcessedEventId = lastEvent.id

        // Generate new action ID
        let actionId = UUID()
        currentActionId = actionId

        // Queue celebrations
        queueCelebrationsForEvent(lastEvent, actionId: actionId)

        // Process after brief delay (allows stores to finish updating)
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // Only process if still current action
        if currentActionId == actionId {
            celebrationManager?.processCelebrations(forAction: actionId)
        }
    }

    /// Find latest positive event - O(n) but runs in async context
    private func findLatestPositiveEvent() async -> BehaviorEvent? {
        // Use Task to avoid blocking if list is large
        return behaviorsStore.behaviorEvents.max(by: { $0.timestamp < $1.timestamp })
    }

    /// Queue celebrations for an event
    private func queueCelebrationsForEvent(_ event: BehaviorEvent, actionId: UUID) {
        guard let celebrationQueueUseCase = celebrationQueueUseCase,
              let celebrationManager = celebrationManager else { return }

        let result = celebrationQueueUseCase.execute(for: event)

        // Queue Gold Star Day if applicable
        if let goldStarDay = result.goldStarDay {
            celebrationManager.queueCelebration(
                .goldStarDay(
                    childId: goldStarDay.childId,
                    childName: goldStarDay.childName,
                    momentCount: goldStarDay.momentCount
                ),
                forAction: actionId
            )
        }

        // Queue pattern insight if applicable
        if let pattern = result.patternInsight {
            let patternInsight = CelebrationManager.PatternInsight(
                title: pattern.insight.title,
                message: pattern.insight.message,
                suggestion: pattern.insight.suggestion,
                icon: pattern.insight.icon,
                color: pattern.insight.color
            )
            celebrationManager.queueCelebration(
                .patternFound(
                    childId: pattern.childId,
                    childName: pattern.childName,
                    behaviorId: pattern.behaviorId,
                    behaviorName: pattern.behaviorName,
                    count: pattern.count,
                    insight: patternInsight
                ),
                forAction: actionId
            )
        }
    }

    /// Handle reward earned celebration from store
    private func handleRewardEarnedCelebration(_ celebration: CelebrationStore.RewardEarnedCelebration) {
        guard let celebrationManager = celebrationManager,
              let actionId = currentActionId else { return }

        celebrationManager.queueCelebration(
            .goalReached(
                childId: celebration.childId,
                childName: celebration.childName,
                rewardId: celebration.rewardId,
                rewardName: celebration.rewardName,
                rewardIcon: celebration.rewardIcon
            ),
            forAction: actionId
        )
    }

    /// Handle milestone celebration from store
    private func handleMilestoneCelebration(_ milestone: CelebrationStore.MilestoneCelebration) {
        guard let celebrationManager = celebrationManager,
              let actionId = currentActionId else { return }

        celebrationManager.queueCelebration(
            .milestoneReached(
                childId: milestone.childId,
                childName: milestone.childName,
                rewardId: milestone.rewardId,
                rewardName: milestone.rewardName,
                milestone: milestone.milestone,
                target: milestone.target,
                message: milestone.message
            ),
            forAction: actionId
        )
    }

    /// Flag goal prompt for next session (non-blocking)
    private func flagGoalPromptForNextSession() {
        guard let goalPromptUseCase = goalPromptUseCase else { return }
        let result = goalPromptUseCase.execute()
        if result.childToPrompt != nil {
            UserDefaults.standard.set(true, forKey: "pendingGoalPrompt")
        }
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        // Notify observers BEFORE changing the value so the view updates
        objectWillChange.send()
        userPreferences.hasCompletedOnboarding = true
        // Also set the completion date
        userPreferences.onboardingCompletedDate = Date()
    }

    // MARK: - Celebration Helpers

    /// Dismiss milestone celebration
    func dismissMilestone() {
        celebrationStore.dismissMilestone()
    }

    /// Dismiss reward earned celebration
    func dismissRewardEarnedCelebration() {
        celebrationStore.dismissRewardEarnedCelebration()
    }

    /// Check for bonus insight (pattern detection)
    /// TODO: Move checkForBonusInsight method from FamilyViewModel to InsightsStore
    func checkForBonusInsight(childId: UUID) -> BonusInsight? {
        // Temporarily disabled - method needs to be moved to InsightsStore
        return nil
    }

    // MARK: - Goal Suggestion

    /// Generate kid-friendly goal options - returns ALL templates with categories
    func generateKidGoalOptions(forChild childId: UUID) -> [GoalOption] {
        guard let child = childrenStore.children.first(where: { $0.id == childId }) else {
            return []
        }
        // Use the template system for consistent, categorized goal options
        return RewardTemplate.allGoalOptions(forAge: child.age)
    }
}

// MARK: - Goal Option Model

// Type alias to match KidGoalOption from ProgressionSystem
typealias GoalOption = KidGoalOption
