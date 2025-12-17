import Foundation

/// Use case for redeeming a reward.
/// Coordinates marking reward as redeemed, logging history event,
/// updating child points, and triggering completion notification.
@MainActor
final class RedeemRewardUseCase {

    // MARK: - Dependencies

    private let rewardsStore: RewardsStore
    private let childrenStore: ChildrenStore
    private let behaviorsStore: BehaviorsStore
    private let celebrationStore: CelebrationStore

    // MARK: - Initialization

    init(
        rewardsStore: RewardsStore,
        childrenStore: ChildrenStore,
        behaviorsStore: BehaviorsStore,
        celebrationStore: CelebrationStore
    ) {
        self.rewardsStore = rewardsStore
        self.childrenStore = childrenStore
        self.behaviorsStore = behaviorsStore
        self.celebrationStore = celebrationStore
    }

    // MARK: - Execute

    /// Redeem a reward with all side effects.
    /// Preserves exact logic from FamilyViewModel.markRewardAsGiven
    func execute(rewardId: UUID) {
        guard var reward = rewardsStore.rewards.first(where: { $0.id == rewardId }) else {
            return
        }

        guard let child = childrenStore.children.first(where: { $0.id == reward.childId }) else {
            return
        }

        // Calculate stars earned
        let isPrimary = reward.priority == 0
        let starsEarned = reward.pointsEarnedInWindow(
            from: behaviorsStore.behaviorEvents,
            isPrimaryReward: isPrimary
        )

        // Mark as redeemed
        reward.isRedeemed = true
        rewardsStore.updateReward(reward)

        // Update child allowance if applicable
        // Note: Allowance handling done separately

        // Log history event
        rewardsStore.logRewardHistoryEvent(
            reward: reward,
            eventType: .given,
            starsEarned: starsEarned
        )

        // Check if there's a next reward
        let remainingRewards = rewardsStore.rewards.filter {
            $0.childId == reward.childId && !$0.isRedeemed && !$0.isExpired
        }
        let hasNextReward = !remainingRewards.isEmpty

        // Trigger completion notification
        celebrationStore.triggerRewardCompletedNotification(
            rewardName: reward.name,
            childName: child.name,
            hasNextReward: hasNextReward
        )

        // If there's a next reward, promote it to active (priority 0)
        if hasNextReward {
            promoteNextQueuedReward(forChild: reward.childId)
        }
    }

    // MARK: - Private Helpers

    private func promoteNextQueuedReward(forChild childId: UUID) {
        let nextReward = rewardsStore.rewards
            .filter { $0.childId == childId && !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
            .first

        if var reward = nextReward {
            reward.priority = 0
            rewardsStore.updateReward(reward)
        }
    }
}
