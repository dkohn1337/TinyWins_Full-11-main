import Foundation

/// Centralized use case for performing a complete factory reset of the app.
///
/// This use case ensures that all data is cleared consistently:
/// - Clears all domain data (children, rewards, events, agreements, etc.)
/// - Resets onboarding flags and coach marks
/// - Clears per-child UserDefaults keys
/// - Does NOT clear subscription status or platform-level settings
///
/// Usage:
/// ```swift
/// let resetUseCase = FactoryResetUseCase(
///     repository: repository,
///     userPreferences: userPreferences
/// )
/// resetUseCase.execute()
/// ```
@MainActor
final class FactoryResetUseCase {

    // MARK: - Dependencies

    private let repository: RepositoryProtocol
    private let userPreferences: UserPreferencesStore

    // MARK: - Initialization

    init(
        repository: RepositoryProtocol,
        userPreferences: UserPreferencesStore
    ) {
        self.repository = repository
        self.userPreferences = userPreferences
    }

    // MARK: - Execution

    /// Performs a complete factory reset of all app data.
    ///
    /// What this does:
    /// - Clears all domain data via repository (children, rewards, events, etc.)
    /// - Resets onboarding completion flag
    /// - Clears all coach marks and banner tracking dates
    /// - Clears per-child UserDefaults keys (goal tooltips, themes, etc.)
    ///
    /// What this does NOT do:
    /// - Clear subscription status
    /// - Clear theme/appearance preferences
    /// - Clear platform-level settings
    func execute() {
        #if DEBUG
        print("[FactoryResetUseCase] Starting factory reset...")
        #endif

        // 1. Get all child IDs before clearing (needed to clean up per-child UserDefaults)
        let childIds = repository.getChildren().map { $0.id }

        // 2. Clear all domain data via repository
        repository.clearAllData()

        // 3. Reset onboarding and coaching flags
        userPreferences.resetOnboarding()
        userPreferences.resetAllCoachMarks()
        userPreferences.resetAllBannerDates()

        // 4. Clear per-child UserDefaults keys
        clearPerChildUserDefaults(for: childIds)

        // 5. Clear selection state
        userPreferences.selectedRewardsChildId = ""

        #if DEBUG
        print("[FactoryResetUseCase] Factory reset complete. App is in fresh-install state.")
        #endif
    }

    // MARK: - Private Helpers

    /// Clears per-child UserDefaults keys
    private func clearPerChildUserDefaults(for childIds: [UUID]) {
        for childId in childIds {
            // Goal tooltip state
            UserDefaults.standard.removeObject(forKey: "hasSeenGoalTooltip_\(childId.uuidString)")

            // Goal interception state
            UserDefaults.standard.removeObject(forKey: "hasSeenGoalInterception_\(childId.uuidString)")

            // Kid view theme
            UserDefaults.standard.removeObject(forKey: "kidViewTheme_\(childId.uuidString)")
        }
    }
}
