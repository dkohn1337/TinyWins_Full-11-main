import Foundation
import Combine

/// ViewModel for the Settings screen.
/// Manages app settings and preferences.
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let userPreferences: UserPreferencesStore
    private let subscriptionManager: SubscriptionManager

    // MARK: - Initialization

    init(
        userPreferences: UserPreferencesStore,
        subscriptionManager: SubscriptionManager
    ) {
        self.userPreferences = userPreferences
        self.subscriptionManager = subscriptionManager
    }

    // MARK: - Preferences Access
    // Note: Appearance settings not yet implemented in UserPreferencesStore
}
