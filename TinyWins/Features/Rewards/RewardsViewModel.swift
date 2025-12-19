import Foundation
import Combine
import SwiftUI

/// Precomputed data for a child in the rewards view.
struct ChildRewardData: Equatable, Identifiable {
    let id: UUID
    let child: Child
    let hasActiveReward: Bool
    let hasReadyReward: Bool
    let summaryText: String
    let activeGoalCount: Int

    static func == (lhs: ChildRewardData, rhs: ChildRewardData) -> Bool {
        lhs.id == rhs.id &&
        lhs.child.id == rhs.child.id &&
        lhs.child.totalPoints == rhs.child.totalPoints &&
        lhs.hasActiveReward == rhs.hasActiveReward &&
        lhs.hasReadyReward == rhs.hasReadyReward &&
        lhs.summaryText == rhs.summaryText &&
        lhs.activeGoalCount == rhs.activeGoalCount
    }
}

/// ViewModel for the Rewards screen.
/// PERFORMANCE: Precomputes all child data via Combine to eliminate store access during render.
/// Manages reward selection, child selection, paywall gating, and progress computation.
@MainActor
final class RewardsViewModel: ObservableObject {

    // MARK: - Precomputed State

    struct ViewState: Equatable {
        var childrenData: [ChildRewardData] = []
        var hasAnyActiveGoal: Bool = false
        var firstChildWithReadyRewardId: UUID? = nil
    }

    @Published private(set) var state = ViewState()

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let behaviorsStore: BehaviorsStore
    private let userPreferences: UserPreferencesStore
    private let subscriptionManager: SubscriptionManager

    // MARK: - Visibility Gate

    private var isVisible = false
    private var pendingState: ViewState?

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var selectedChildId: UUID?

    // MARK: - Computed Properties (for compatibility)

    // PHASE 2: Use precomputed activeChildren from snapshot
    var activeChildren: [Child] {
        childrenStore.activeChildren
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
        state.hasAnyActiveGoal
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

        #if DEBUG
        print("🟢 INIT RewardsViewModel", ObjectIdentifier(self))
        #endif

        // Load persisted selection
        let idString = userPreferences.selectedRewardsChildId
        if !idString.isEmpty, let id = UUID(uuidString: idString) {
            self.selectedChildId = id
        }

        setupObservers()
        recomputeState()
    }

    deinit {
        #if DEBUG
        print("🔴 DEINIT RewardsViewModel", ObjectIdentifier(self))
        #endif
    }

    // MARK: - Visibility Gate

    func setVisible(_ visible: Bool) {
        isVisible = visible

        guard visible else { return }

        Task { @MainActor in
            await Task.yield()

            if let pending = pendingState {
                pendingState = nil
                state = pending
            }
        }
    }

    private func applyState(_ newState: ViewState) {
        guard isVisible else {
            pendingState = newState
            return
        }

        state = newState
    }

    // MARK: - Combine Observers

    private func setupObservers() {
        // PHASE 1: Observe store snapshots (single publish per store) instead of individual properties
        // Merge all store changes into a single pipeline to avoid redundant recomputation
        Publishers.Merge3(
            childrenStore.$snapshot.map { _ in () },
            rewardsStore.$snapshot.map { _ in () },
            behaviorsStore.$snapshot.map { _ in () }
        )
        .dropFirst()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.recomputeState()
        }
        .store(in: &cancellables)
    }

    // MARK: - State Computation

    private func recomputeState() {
        let events = behaviorsStore.behaviorEvents
        let rewards = rewardsStore.rewards
        // PHASE 2: Use precomputed activeChildren from snapshot
        let children = childrenStore.activeChildren

        var anyActiveGoal = false
        var firstReadyChildId: UUID? = nil

        let childrenData = children.map { child -> ChildRewardData in
            let childRewards = rewards
                .filter { $0.childId == child.id && !$0.isRedeemed && !$0.isExpired }
                .sorted { $0.priority < $1.priority }

            let activeReward = childRewards.first
            let hasActive = activeReward != nil

            if hasActive {
                anyActiveGoal = true
            }

            // Check if primary reward is ready
            var hasReady = false
            if let primary = activeReward {
                hasReady = primary.status(from: events, isPrimaryReward: true) == .readyToRedeem
                if hasReady && firstReadyChildId == nil {
                    firstReadyChildId = child.id
                }
            }

            // Generate summary text
            let goalCount = childRewards.count
            let summaryText: String
            if goalCount == 0 {
                summaryText = "\(child.totalPoints) stars · No goals yet"
            } else {
                summaryText = "\(child.totalPoints) stars \u{00B7} \(goalCount) goal\(goalCount == 1 ? "" : "s")"
            }

            return ChildRewardData(
                id: child.id,
                child: child,
                hasActiveReward: hasActive,
                hasReadyReward: hasReady,
                summaryText: summaryText,
                activeGoalCount: goalCount
            )
        }

        let newState = ViewState(
            childrenData: childrenData,
            hasAnyActiveGoal: anyActiveGoal,
            firstChildWithReadyRewardId: firstReadyChildId
        )

        applyState(newState)
    }

    // MARK: - Precomputed Data Access

    func childData(for childId: UUID) -> ChildRewardData? {
        state.childrenData.first { $0.id == childId }
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
        childData(for: child.id)?.hasReadyReward ?? false
    }

    func firstChildWithReadyReward() -> Child? {
        guard let id = state.firstChildWithReadyRewardId else { return nil }
        return activeChildren.first { $0.id == id }
    }

    func starsEarned(for reward: Reward, isPrimary: Bool) -> Int {
        reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    func rewardStatus(for reward: Reward, isPrimary: Bool) -> Reward.RewardStatus {
        reward.status(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    // MARK: - Summary Text

    func summaryText(for child: Child) -> String {
        childData(for: child.id)?.summaryText ?? "\(child.totalPoints) stars"
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
