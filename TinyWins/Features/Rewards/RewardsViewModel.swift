import Foundation
import Combine
import SwiftUI

/// ViewModel for the Rewards screen.
/// Manages reward selection, child selection, paywall gating, and progress computation.
@MainActor
final class RewardsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let behaviorsStore: BehaviorsStore
    private let userPreferences: UserPreferencesStore
    private let subscriptionManager: SubscriptionManager

    // MARK: - Published State

    @Published var selectedChildId: UUID?

    // MARK: - Computed Properties

    var activeChildren: [Child] {
        childrenStore.children.filter { !$0.isArchived }
    }

    var selectedChild: Child? {
        guard let id = selectedChildId else { return nil }
        return childrenStore.children.first { $0.id == id }
    }

    var effectiveSelectedChild: Child? {
        // If we have a valid selection, use it
        if let child = selectedChild {
            return child
        }
        // Fall back to first child
        return activeChildren.first
    }

    var hasAnyActiveGoal: Bool {
        activeChildren.contains { child in
            activeReward(forChild: child.id) != nil
        }
    }

    // MARK: - Initialization

    init(
        childrenStore: ChildrenStore,
        rewardsStore: RewardsStore,
        behaviorsStore: BehaviorsStore,
        userPreferences: UserPreferencesStore,
        subscriptionManager: SubscriptionManager
    ) {
        self.childrenStore = childrenStore
        self.rewardsStore = rewardsStore
        self.behaviorsStore = behaviorsStore
        self.userPreferences = userPreferences
        self.subscriptionManager = subscriptionManager

        // Load persisted selection
        let idString = userPreferences.selectedRewardsChildId
        if !idString.isEmpty, let id = UUID(uuidString: idString) {
            self.selectedChildId = id
        }
    }

    // MARK: - Reward Query Methods

    func rewards(forChild childId: UUID) -> [Reward] {
        rewardsStore.rewards.filter { $0.childId == childId }
    }

    func activeReward(forChild childId: UUID) -> Reward? {
        let childRewards = rewards(forChild: childId)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
        return childRewards.first
    }

    func hasReadyReward(for child: Child) -> Bool {
        let rewards = rewards(forChild: child.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }

        guard let primaryReward = rewards.first else { return false }
        return primaryReward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: true) == .readyToRedeem
    }

    func firstChildWithReadyReward() -> Child? {
        activeChildren.first { hasReadyReward(for: $0) }
    }

    func starsEarned(for reward: Reward, isPrimary: Bool) -> Int {
        reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    func rewardStatus(for reward: Reward, isPrimary: Bool) -> Reward.RewardStatus {
        reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    // MARK: - Summary Text

    func summaryText(for child: Child) -> String {
        let points = child.totalPoints
        let goalCount = rewards(forChild: child.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .count

        if goalCount == 0 {
            return "\(points) points · No goals yet"
        } else {
            return "\(points) points \u{00B7} \(goalCount) goal\(goalCount == 1 ? "" : "s")"
        }
    }

    // MARK: - Selection Management

    func selectChild(_ child: Child) {
        selectedChildId = child.id
        userPreferences.selectedRewardsChildId = child.id.uuidString
    }

    // MARK: - Reward Actions

    func addReward(_ reward: Reward) {
        rewardsStore.addReward(reward)
    }

    func updateReward(_ reward: Reward) {
        rewardsStore.updateReward(reward)
    }

    func deleteReward(_ reward: Reward) {
        rewardsStore.deleteReward(id: reward.id)
    }

    func reorderRewards(childId: UUID, from source: IndexSet, to destination: Int) {
        var childRewards = rewards(forChild: childId)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }

        childRewards.move(fromOffsets: source, toOffset: destination)

        // Update priorities
        for (index, reward) in childRewards.enumerated() {
            var updated = reward
            updated.priority = index
            rewardsStore.updateReward(updated)
        }
    }

    // MARK: - Paywall Gating

    func canAddReward(for child: Child) -> Bool {
        let childRewardCount = rewards(forChild: child.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .count
        return subscriptionManager.canAddChild(currentCount: childRewardCount)
    }

    func needsPaywallForAddingReward(for child: Child) -> Bool {
        !canAddReward(for: child)
    }

    // MARK: - Expired Rewards Check

    func checkExpiredRewards() {
        for reward in rewardsStore.rewards where reward.hasDeadline && reward.isExpired && !reward.isRedeemed {
            // Check if already logged
            let alreadyLogged = rewardsStore.rewardHistoryEvents.contains {
                $0.rewardId == reward.id && $0.eventType == .expired
            }

            if !alreadyLogged {
                // Log expired event
                let isPrimary = activeReward(forChild: reward.childId)?.id == reward.id
                let starsEarned = starsEarned(for: reward, isPrimary: isPrimary)
                rewardsStore.logRewardHistoryEvent(
                    reward: reward,
                    eventType: .expired,
                    starsEarned: starsEarned
                )
            }

            if reward.autoResetOnExpire {
                // Apply soft reset
                var updatedReward = reward
                updatedReward.applySoftReset()
                rewardsStore.updateReward(updatedReward)
            }
        }
    }
}
