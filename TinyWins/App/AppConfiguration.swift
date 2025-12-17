import Foundation
import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
#endif

// MARK: - App Configuration

/// Central configuration for the app's backend services.
/// Change `backendMode` to easily switch between local-only and Firebase modes.
enum AppConfiguration {

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - MAIN SWITCH - Change this to toggle Firebase on/off
    // ═══════════════════════════════════════════════════════════════════════

    /// Set to `.localOnly` to disable all Firebase features.
    /// Set to `.firebase` to enable cloud sync and co-parent features.
    ///
    /// When `.localOnly`:
    /// - App works completely offline
    /// - No sign-in required
    /// - Data stored only on device
    /// - Co-parent features hidden
    ///
    /// When `.firebase`:
    /// - Cloud sync enabled when signed in
    /// - Apple Sign-In available
    /// - Co-parent sync available
    /// - Still works offline (syncs when connected)
    static let backendMode: BackendMode = .firebase  // <-- CHANGE THIS TO .firebase WHEN READY

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - Feature Flags
    // ═══════════════════════════════════════════════════════════════════════

    /// Whether Firebase features are enabled.
    /// In DEBUG builds, this checks the runtime developer setting.
    /// In release builds, this uses the compile-time backendMode.
    static var isFirebaseEnabled: Bool {
        #if DEBUG
        // Check runtime developer setting (defaults to true when backendMode is .firebase)
        return UserDefaults.standard.object(forKey: "debug.firebaseSyncEnabled") as? Bool ?? (backendMode == .firebase)
        #else
        return backendMode == .firebase
        #endif
    }

    /// Whether co-parent sync features should be shown in UI
    static var showCoParentFeatures: Bool {
        isFirebaseEnabled
    }

    /// Whether sign-in option should be shown
    static var showSignIn: Bool {
        isFirebaseEnabled
    }

    /// Whether to show partner dashboard in insights
    static var showPartnerDashboard: Bool {
        isFirebaseEnabled
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - Firebase Configuration
    // ═══════════════════════════════════════════════════════════════════════

    /// Configure Firebase if enabled.
    /// Call this once at app startup.
    static func configureFirebaseIfNeeded() {
        guard isFirebaseEnabled else {
            #if DEBUG
            print("═══════════════════════════════════════")
            print("TinyWins: Running in LOCAL-ONLY mode")
            print("Firebase features: DISABLED")
            print("═══════════════════════════════════════")
            #endif
            // Initialize crash reporter even in local mode (uses os_log fallback)
            CrashReporter.initialize()
            return
        }

        #if canImport(FirebaseCore)
        // Check if already configured
        guard FirebaseApp.app() == nil else {
            #if DEBUG
            print("[Firebase] Already configured")
            #endif
            return
        }

        // Configure Firebase
        FirebaseApp.configure()

        // Initialize crash reporter after Firebase is configured
        CrashReporter.initialize()

        // Initialize analytics tracker
        Task { @MainActor in
            AnalyticsTracker.shared.initialize()
        }

        // Enable offline persistence for Firestore (100MB cache)
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        Firestore.firestore().settings = settings

        #if DEBUG
        print("═══════════════════════════════════════")
        print("TinyWins: Firebase ENABLED")
        print("Offline persistence: ON (100MB cache)")
        print("═══════════════════════════════════════")
        #endif
        #else
        #if DEBUG
        print("═══════════════════════════════════════")
        print("TinyWins: Firebase SDK not installed")
        print("Add FirebaseAuth & FirebaseFirestore via SPM")
        print("═══════════════════════════════════════")
        #endif
        // Initialize crash reporter with os_log fallback
        CrashReporter.initialize()
        #endif
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - Family ID Storage
    // ═══════════════════════════════════════════════════════════════════════

    private static let familyIdKey = "com.tinywins.currentFamilyId"

    /// Get the stored family ID for the current user.
    static var storedFamilyId: String? {
        get { UserDefaults.standard.string(forKey: familyIdKey) }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: familyIdKey)
                #if DEBUG
                print("[AppConfig] Stored familyId: \(value)")
                #endif
            } else {
                UserDefaults.standard.removeObject(forKey: familyIdKey)
                #if DEBUG
                print("[AppConfig] Cleared familyId")
                #endif
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - Backend Creation
    // ═══════════════════════════════════════════════════════════════════════

    /// Create the sync backend for Repository.
    ///
    /// IMPORTANT: Repository ALWAYS uses LocalSyncBackend for instant, non-blocking saves.
    /// Firebase sync is handled separately by SyncManager in the background.
    /// This ensures the UI never freezes due to network issues or permission errors.
    ///
    /// - Returns: LocalSyncBackend for offline-first architecture
    static func createSyncBackend(familyId: String? = nil) -> SyncBackend {
        #if DEBUG
        print("[Backend] Using LocalSyncBackend (offline-first architecture)")
        #endif
        return LocalSyncBackend()
    }

    /// Create the appropriate auth service based on configuration.
    /// - Returns: Configured AuthService
    @MainActor
    static func createAuthService() -> any AuthService {
        guard isFirebaseEnabled else {
            return LocalAuthService()
        }

        #if canImport(FirebaseCore)
        return FirebaseAuthService()
        #else
        return LocalAuthService()
        #endif
    }

    /// Check if user is currently signed in to Firebase.
    static var isSignedIn: Bool {
        guard isFirebaseEnabled else { return false }

        #if canImport(FirebaseCore)
        return Auth.auth().currentUser != nil
        #else
        return false
        #endif
    }

    /// Get current Firebase user ID if signed in.
    static var currentUserId: String? {
        guard isFirebaseEnabled else { return nil }

        #if canImport(FirebaseCore)
        return Auth.auth().currentUser?.uid
        #else
        return nil
        #endif
    }
}

// MARK: - Environment Key for Configuration

private struct AppConfigurationKey: EnvironmentKey {
    static let defaultValue = AppConfiguration.backendMode
}

extension EnvironmentValues {
    var backendMode: BackendMode {
        get { self[AppConfigurationKey.self] }
        set { self[AppConfigurationKey.self] = newValue }
    }
}

// MARK: - View Extension for Feature Gating

extension View {
    /// Only show this view if Firebase features are enabled.
    @ViewBuilder
    func firebaseOnly() -> some View {
        if AppConfiguration.isFirebaseEnabled {
            self
        }
    }

    /// Only show this view if co-parent features are enabled.
    @ViewBuilder
    func coParentOnly() -> some View {
        if AppConfiguration.showCoParentFeatures {
            self
        }
    }

    /// Show alternative content when Firebase is disabled.
    @ViewBuilder
    func firebaseOnly<Placeholder: View>(@ViewBuilder placeholder: () -> Placeholder) -> some View {
        if AppConfiguration.isFirebaseEnabled {
            self
        } else {
            placeholder()
        }
    }
}
