import Foundation
import Combine

/// ViewModel for the Log Behavior sheet.
/// Manages behavior logging UI state.
@MainActor
final class LogBehaviorViewModel: ObservableObject {

    // MARK: - Dependencies

    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore

    // MARK: - Computed Properties

    var activeBehaviorTypes: [BehaviorType] {
        behaviorsStore.behaviorTypes.filter { $0.isActive }
    }

    var positiveActiveBehaviors: [BehaviorType] {
        activeBehaviorTypes.filter { $0.defaultPoints > 0 }
    }

    var challengeActiveBehaviors: [BehaviorType] {
        activeBehaviorTypes.filter { $0.defaultPoints < 0 }
    }

    func suggestedBehaviors(forChild childId: UUID, category: BehaviorCategory) -> [BehaviorType] {
        guard let child = childrenStore.children.first(where: { $0.id == childId }),
              let age = child.age else {
            return activeBehaviorTypes.filter { $0.category == category }
        }

        let filtered = activeBehaviorTypes.filter {
            $0.category == category && $0.suggestedAgeRange.contains(age: age)
        }

        return filtered.isEmpty ? activeBehaviorTypes.filter { $0.category == category } : filtered
    }

    // MARK: - Initialization

    init(
        behaviorsStore: BehaviorsStore,
        childrenStore: ChildrenStore
    ) {
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
    }

    // MARK: - Behavior Logging
    // Note: Actual logging will be done through LogBehaviorUseCase
}
