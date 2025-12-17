import Foundation
import SwiftUI

/// Central feature flags for the app
/// Debug flags are only available in DEBUG builds
/// NOTE: This now delegates to UserPreferencesStore for persistence
@MainActor
final class FeatureFlags: ObservableObject {
    /// Shared singleton instance for backward compatibility.
    /// New code should use dependency injection via DependencyContainer.
    static let shared = FeatureFlags()

    /// Creates a new FeatureFlags instance.
    /// Use `shared` singleton for backward compatibility or inject via DependencyContainer.
    init() {}

    // MARK: - Debug Flags (DEBUG builds only)

    #if DEBUG
    /// When true, unlocks all TinyWins Plus features without a real subscription.
    /// This value persists across app launches for convenience during testing.
    /// Delegates to UserPreferencesStore for actual storage.
    var debugUnlockPlus: Bool {
        get { UserPreferencesStore().debugUnlockPlus }
        set {
            UserPreferencesStore().debugUnlockPlus = newValue
            objectWillChange.send()
        }
    }

    /// When true, shows additional debug information in the UI.
    /// Delegates to UserPreferencesStore for actual storage.
    var showDebugInfo: Bool {
        get { UserPreferencesStore().showDebugInfo }
        set {
            UserPreferencesStore().showDebugInfo = newValue
            objectWillChange.send()
        }
    }
    #endif

    // MARK: - Helpers

    /// Returns true if Plus should be unlocked (via debug flag or real subscription).
    /// Use SubscriptionManager.shared.effectiveIsPlusSubscriber instead for most cases.
    var isDebugPlusEnabled: Bool {
        #if DEBUG
        return debugUnlockPlus
        #else
        return false
        #endif
    }
}
