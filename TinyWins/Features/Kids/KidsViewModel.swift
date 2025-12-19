import Foundation
import Combine

/// Precomputed row data for a child - eliminates store access during view render.
/// All computations happen in ViewModel via Combine, not during SwiftUI body evaluation.
struct KidRowData: Equatable, Identifiable {
    let id: UUID
    let child: Child
    let activeReward: Reward?
    let rewardStatus: Reward.RewardStatus?
    let progress: Double
    let starsRemainingForPrimary: Int
    let nextQueuedReward: Reward?
    let starsRemainingForNext: Int
    let additionalQueuedCount: Int
    let isArchived: Bool

    static func == (lhs: KidRowData, rhs: KidRowData) -> Bool {
        lhs.id == rhs.id &&
        lhs.child.id == rhs.child.id &&
        lhs.child.name == rhs.child.name &&
        lhs.child.totalPoints == rhs.child.totalPoints &&
        lhs.activeReward?.id == rhs.activeReward?.id &&
        lhs.rewardStatus == rhs.rewardStatus &&
        lhs.progress == rhs.progress &&
        lhs.starsRemainingForPrimary == rhs.starsRemainingForPrimary &&
        lhs.nextQueuedReward?.id == rhs.nextQueuedReward?.id &&
        lhs.starsRemainingForNext == rhs.starsRemainingForNext &&
        lhs.additionalQueuedCount == rhs.additionalQueuedCount &&
        lhs.isArchived == rhs.isArchived
    }
}

/// ViewModel for the Kids list screen.
/// PERFORMANCE: Precomputes all row data via Combine to eliminate store access during render.
/// Manages child list display and paywall gating for adding children.
@MainActor
final class KidsViewModel: ObservableObject {

    // MARK: - Precomputed State

    struct ViewState: Equatable {
        var activeChildrenData: [KidRowData] = []
        var archivedChildrenData: [KidRowData] = []
        var canAddChild: Bool = true
    }

    @Published private(set) var state = ViewState()

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let behaviorsStore: BehaviorsStore
    private let subscriptionManager: SubscriptionManager

    // MARK: - Visibility Gate

    private var isVisible = false
    private var pendingState: ViewState?

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties (for compatibility)

    var children: [Child] {
        childrenStore.children
    }

    // PHASE 2: Use precomputed activeChildren from snapshot
    var activeChildren: [Child] {
        childrenStore.activeChildren
    }

    var canAddChild: Bool {
        state.canAddChild
    }

    // MARK: - Initialization

    init(
        childrenStore: ChildrenStore,
        rewardsStore: RewardsStore,
        behaviorsStore: BehaviorsStore,
        subscriptionManager: SubscriptionManager
    ) {
        self.childrenStore = childrenStore
        self.rewardsStore = rewardsStore
        self.behaviorsStore = behaviorsStore
        self.subscriptionManager = subscriptionManager

        #if DEBUG
        print("🟢 INIT KidsViewModel", ObjectIdentifier(self))
        #endif

        setupObservers()
        recomputeState()
    }

    // Convenience initializer for backwards compatibility
    convenience init(
        childrenStore: ChildrenStore,
        subscriptionManager: SubscriptionManager
    ) {
        // This path won't have behavior/reward data - used only for legacy code paths
        // The full initializer should be used in DependencyContainer
        fatalError("Use full initializer with rewardsStore and behaviorsStore")
    }

    deinit {
        #if DEBUG
        print("🔴 DEINIT KidsViewModel", ObjectIdentifier(self))
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

        let activeData = childrenStore.children
            .filter { !$0.isArchived }
            .map { child in
                computeRowData(for: child, events: events, rewards: rewards, isArchived: false)
            }

        let archivedData = childrenStore.children
            .filter { $0.isArchived }
            .map { child in
                computeRowData(for: child, events: events, rewards: rewards, isArchived: true)
            }

        let canAdd = subscriptionManager.canAddChild(currentCount: activeData.count)

        let newState = ViewState(
            activeChildrenData: activeData,
            archivedChildrenData: archivedData,
            canAddChild: canAdd
        )

        applyState(newState)
    }

    private func computeRowData(for child: Child, events: [BehaviorEvent], rewards: [Reward], isArchived: Bool) -> KidRowData {
        // Get queued rewards for this child
        let childRewards = rewards
            .filter { $0.childId == child.id && !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }

        let activeReward = childRewards.first

        // Compute status and progress for primary reward
        let rewardStatus: Reward.RewardStatus?
        let progress: Double
        let starsRemainingForPrimary: Int

        if let reward = activeReward {
            rewardStatus = reward.status(from: events, isPrimaryReward: true)
            let earned = reward.pointsEarnedInWindow(from: events, isPrimaryReward: true)
            progress = min(Double(earned) / Double(reward.targetPoints), 1.0)
            starsRemainingForPrimary = max(0, reward.targetPoints - earned)
        } else {
            rewardStatus = nil
            progress = 0
            starsRemainingForPrimary = 0
        }

        // Get next queued reward
        let nextQueuedReward = childRewards.count > 1 ? childRewards[1] : nil

        // Compute stars remaining for next reward
        let starsRemainingForNext: Int
        if let nextReward = nextQueuedReward {
            let earned = nextReward.pointsEarnedInWindow(from: events, isPrimaryReward: false)
            starsRemainingForNext = max(0, nextReward.targetPoints - earned)
        } else {
            starsRemainingForNext = 0
        }

        // Additional queued count (excluding primary)
        let additionalQueuedCount = max(0, childRewards.count - 1)

        return KidRowData(
            id: child.id,
            child: child,
            activeReward: activeReward,
            rewardStatus: rewardStatus,
            progress: progress,
            starsRemainingForPrimary: starsRemainingForPrimary,
            nextQueuedReward: nextQueuedReward,
            starsRemainingForNext: starsRemainingForNext,
            additionalQueuedCount: additionalQueuedCount,
            isArchived: isArchived
        )
    }

    // MARK: - Actions

    func addChild(_ child: Child) {
        childrenStore.addChild(child)
    }

    func updateChild(_ child: Child) {
        childrenStore.updateChild(child)
    }

    func archiveChild(_ child: Child) {
        childrenStore.archiveChild(id: child.id)
    }

    // MARK: - Row Data Access

    func rowData(for childId: UUID) -> KidRowData? {
        state.activeChildrenData.first { $0.id == childId } ??
        state.archivedChildrenData.first { $0.id == childId }
    }
}
