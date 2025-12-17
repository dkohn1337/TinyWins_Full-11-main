import Foundation

/// Use case for determining when to prompt user to create a goal for a child.
/// Encapsulates the business logic for goal prompt eligibility checking.
/// Performs no UI work - returns eligibility data only.
@MainActor
final class GoalPromptUseCase {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore

    // MARK: - Configuration

    /// Number of positive moments required before prompting for a goal
    private let momentsBeforePrompt = 3

    // MARK: - Initialization

    init(
        childrenStore: ChildrenStore,
        behaviorsStore: BehaviorsStore,
        rewardsStore: RewardsStore
    ) {
        self.childrenStore = childrenStore
        self.behaviorsStore = behaviorsStore
        self.rewardsStore = rewardsStore
    }

    // MARK: - Result Types

    /// Result indicating whether to show a goal prompt
    struct GoalPromptResult {
        /// The child who should be prompted for a goal, or nil if no prompt needed
        let childToPrompt: Child?

        /// Whether a prompt should be shown
        var shouldShowPrompt: Bool {
            childToPrompt != nil
        }
    }

    // MARK: - Execute

    /// Check if any active child should be prompted to create a goal.
    /// Logic: After 3 positive moments without a goal, prompt.
    /// - Returns: GoalPromptResult indicating if/which child to prompt
    func execute() -> GoalPromptResult {
        for child in childrenStore.activeChildren {
            // Skip if child already has an active goal
            let hasGoal = rewardsStore.activeReward(forChild: child.id) != nil
            if hasGoal { continue }

            // Count positive moments for this child
            let recentPositiveCount = behaviorsStore.behaviorEvents.filter {
                $0.childId == child.id && $0.pointsApplied > 0
            }.count

            // After 3 positive moments without a goal, prompt
            // Use modulo to only prompt at intervals (3, 6, 9, etc.)
            if recentPositiveCount >= momentsBeforePrompt &&
               recentPositiveCount % momentsBeforePrompt == 0 {
                return GoalPromptResult(childToPrompt: child)
            }
        }

        return GoalPromptResult(childToPrompt: nil)
    }

    /// Check if a specific child should be prompted for a goal
    /// - Parameter childId: The child ID to check
    /// - Returns: true if the child should be prompted
    func shouldPromptForGoal(childId: UUID) -> Bool {
        guard let child = childrenStore.child(id: childId) else {
            return false
        }

        // Skip if child already has an active goal
        let hasGoal = rewardsStore.activeReward(forChild: child.id) != nil
        if hasGoal { return false }

        // Count positive moments for this child
        let recentPositiveCount = behaviorsStore.behaviorEvents.filter {
            $0.childId == child.id && $0.pointsApplied > 0
        }.count

        return recentPositiveCount >= momentsBeforePrompt &&
               recentPositiveCount % momentsBeforePrompt == 0
    }
}
