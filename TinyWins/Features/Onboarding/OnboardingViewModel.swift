import Foundation
import Combine

/// ViewModel for the Onboarding flow.
/// Manages onboarding state and completion.
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Dependencies

    private let userPreferences: UserPreferencesStore
    private let childrenStore: ChildrenStore

    // MARK: - Initialization

    init(
        userPreferences: UserPreferencesStore,
        childrenStore: ChildrenStore
    ) {
        self.userPreferences = userPreferences
        self.childrenStore = childrenStore
    }

    // MARK: - Onboarding Actions

    func completeOnboarding(with child: Child) {
        childrenStore.addChild(child)
        userPreferences.hasCompletedOnboarding = true
        userPreferences.onboardingCompletedDate = Date()
    }

    func skipOnboarding() {
        userPreferences.hasCompletedOnboarding = true
        userPreferences.onboardingCompletedDate = Date()
    }
}
