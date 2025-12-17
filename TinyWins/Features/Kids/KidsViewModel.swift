import Foundation
import Combine

/// ViewModel for the Kids list screen.
/// Manages child list display and paywall gating for adding children.
@MainActor
final class KidsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let subscriptionManager: SubscriptionManager

    // MARK: - Computed Properties

    var children: [Child] {
        childrenStore.children
    }

    var activeChildren: [Child] {
        childrenStore.children.filter { !$0.isArchived }
    }

    var canAddChild: Bool {
        subscriptionManager.canAddChild(currentCount: activeChildren.count)
    }

    // MARK: - Initialization

    init(
        childrenStore: ChildrenStore,
        subscriptionManager: SubscriptionManager
    ) {
        self.childrenStore = childrenStore
        self.subscriptionManager = subscriptionManager
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
}
