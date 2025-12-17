import Foundation
import Combine

/// ViewModel for the Child Detail screen.
/// Manages child-specific data display and actions.
@MainActor
final class ChildDetailViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore

    // MARK: - State

    let childId: UUID

    // MARK: - Computed Properties

    var child: Child? {
        childrenStore.children.first { $0.id == childId }
    }

    var childRewards: [Reward] {
        rewardsStore.rewards.filter { $0.childId == childId }
    }

    var activeReward: Reward? {
        childRewards.first { $0.priority == 0 && !$0.isRedeemed && !$0.isExpired }
    }

    // MARK: - Initialization

    init(
        childId: UUID,
        childrenStore: ChildrenStore,
        behaviorsStore: BehaviorsStore,
        rewardsStore: RewardsStore
    ) {
        self.childId = childId
        self.childrenStore = childrenStore
        self.behaviorsStore = behaviorsStore
        self.rewardsStore = rewardsStore
    }

    // MARK: - Actions

    func updateChild(_ child: Child) {
        childrenStore.updateChild(child)
    }

    func archiveChild() {
        guard let child = child else { return }
        childrenStore.archiveChild(id: child.id)
    }

    func unarchiveChild() {
        guard var child = child else { return }
        child.isArchived = false
        childrenStore.updateChild(child)
    }

    func deleteChild() {
        childrenStore.deleteChild(id: childId)
    }
}
