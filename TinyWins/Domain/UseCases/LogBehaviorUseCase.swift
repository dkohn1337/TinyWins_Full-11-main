import Foundation

/// Use case for logging a behavior event.
/// Coordinates all side effects: recording event, updating parent activity,
/// checking badges, checking milestones, and triggering celebrations.
/// Preserves exact logic from FamilyViewModel.logBehavior method.
@MainActor
final class LogBehaviorUseCase {

    // MARK: - Dependencies

    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let progressionStore: ProgressionStore
    private let celebrationStore: CelebrationStore

    // MARK: - Initialization

    init(
        behaviorsStore: BehaviorsStore,
        childrenStore: ChildrenStore,
        rewardsStore: RewardsStore,
        progressionStore: ProgressionStore,
        celebrationStore: CelebrationStore
    ) {
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
        self.rewardsStore = rewardsStore
        self.progressionStore = progressionStore
        self.celebrationStore = celebrationStore
    }

    // MARK: - Execute

    /// Log a behavior event with all side effects.
    /// Preserves exact logic and ordering from FamilyViewModel.logBehavior
    func execute(
        childId: UUID,
        behaviorTypeId: UUID,
        timestamp: Date = Date(),
        note: String? = nil
    ) {
        guard let child = childrenStore.children.first(where: { $0.id == childId }) else {
            return
        }

        guard let behaviorType = behaviorsStore.behaviorTypes.first(where: { $0.id == behaviorTypeId }) else {
            return
        }

        // 1. Record parent activity
        progressionStore.recordParentActivity()

        // 2. Create and add behavior event
        let event = BehaviorEvent(
            childId: childId,
            behaviorTypeId: behaviorTypeId,
            timestamp: timestamp,
            pointsApplied: behaviorType.defaultPoints,
            note: note
        )
        behaviorsStore.addBehaviorEvent(event)

        // Track analytics
        AnalyticsTracker.shared.trackBehaviorLogged(
            category: behaviorType.category,
            points: behaviorType.defaultPoints
        )

        // 3. Update child total points
        var updatedChild = child
        updatedChild.totalPoints += behaviorType.defaultPoints
        childrenStore.updateChild(updatedChild)

        // 4. Check and award badges (if positive behavior)
        if behaviorType.defaultPoints > 0 {
            progressionStore.checkAndAwardBadges(
                forChild: childId,
                behaviorEvents: behaviorsStore.behaviorEvents,
                behaviorTypes: behaviorsStore.behaviorTypes
            )
        }

        // 5. Check milestone/celebration for active reward
        if let activeReward = rewardsStore.rewards.first(where: {
            $0.childId == childId && $0.priority == 0 && !$0.isRedeemed && !$0.isExpired
        }) {
            let isPrimary = true
            let previousPoints = activeReward.pointsEarnedInWindow(
                from: behaviorsStore.behaviorEvents.filter { $0.id != event.id },
                isPrimaryReward: isPrimary
            )

            celebrationStore.checkAndTriggerCelebrations(
                reward: activeReward,
                previousPoints: previousPoints,
                behaviorEvents: behaviorsStore.behaviorEvents,
                isPrimary: isPrimary,
                child: updatedChild
            )

            // Log reward history event if earned
            let newPoints = activeReward.pointsEarnedInWindow(
                from: behaviorsStore.behaviorEvents,
                isPrimaryReward: isPrimary
            )
            let wasBelowTarget = previousPoints < activeReward.targetPoints
            let isNowAtTarget = newPoints >= activeReward.targetPoints

            if wasBelowTarget && isNowAtTarget && !activeReward.isRedeemed && !activeReward.isExpired {
                rewardsStore.logRewardHistoryEvent(
                    reward: activeReward,
                    eventType: .earned,
                    starsEarned: newPoints
                )
            }
        }

        // 6. Update behavior streaks
        // Note: Streak updates handled by BehaviorsStore internally
    }
}
