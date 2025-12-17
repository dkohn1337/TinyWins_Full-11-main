import Foundation
import SwiftUI
import Combine

/// ViewModel for the Kid View (child-friendly screen).
/// Manages theme selection and reward progress display for children.
@MainActor
final class KidViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let behaviorsStore: BehaviorsStore
    private let userPreferences: UserPreferencesStore

    // MARK: - State

    let childId: UUID

    // MARK: - Computed Properties

    var child: Child? {
        childrenStore.children.first { $0.id == childId }
    }

    var activeReward: Reward? {
        rewardsStore.rewards.first {
            $0.childId == childId && $0.priority == 0 && !$0.isRedeemed && !$0.isExpired
        }
    }

    func selectedTheme() -> KidViewTheme {
        KidViewTheme(rawValue: userPreferences.kidViewTheme(forChildId: childId)) ?? .classic
    }

    func goalsCompleted() -> Int {
        rewardsStore.rewards.filter {
            $0.childId == childId && $0.isRedeemed
        }.count
    }

    func unlockedThemes() -> [KidViewTheme] {
        KidViewTheme.unlockedThemes(goalsCompleted: goalsCompleted())
    }

    func starsEarned(for reward: Reward) -> Int {
        let isPrimary = reward.priority == 0
        return reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
    }

    // MARK: - Initialization

    init(
        childId: UUID,
        childrenStore: ChildrenStore,
        rewardsStore: RewardsStore,
        behaviorsStore: BehaviorsStore,
        userPreferences: UserPreferencesStore
    ) {
        self.childId = childId
        self.childrenStore = childrenStore
        self.rewardsStore = rewardsStore
        self.behaviorsStore = behaviorsStore
        self.userPreferences = userPreferences
    }

    // MARK: - Actions

    func setTheme(_ theme: KidViewTheme) {
        userPreferences.setKidViewTheme(theme.rawValue, forChildId: childId)
    }
}
