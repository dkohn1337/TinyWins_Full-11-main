import Foundation
import SwiftUI
import Combine

/// Orchestrates stores for ContentView's cross-cutting concerns.
/// Handles onboarding flow, celebration coordination, and goal prompts.
@MainActor
final class ContentViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore
    private let insightsStore: InsightsStore
    private let celebrationStore: CelebrationStore
    private let userPreferences: UserPreferencesStore

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
