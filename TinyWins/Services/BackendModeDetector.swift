import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
#endif

// MARK: - Backend Mode

/// The current backend mode of the app.
/// This determines which services are used for data persistence and authentication.
enum BackendMode: String, CaseIterable {
    /// Local-only mode: All data stored on device, no sign-in.
    /// This is the default mode and works offline.
    case localOnly = "Local Only"

    /// Firebase mode: Data syncs to Firestore, sign-in available.
    /// This requires Firebase SDK and GoogleService-Info.plist.
    case firebase = "Firebase"

    var description: String {
        switch self {
        case .localOnly:
            return "Data stored locally on this device only"
        case .firebase:
            return "Data syncs to cloud across devices"
        }
    }

    var isRemote: Bool {
        switch self {
        case .localOnly: return false
        case .firebase: return true
        }
    }
}

// MARK: - Backend Mode Detector

/// Detects and provides information about the current backend configuration.
///
/// This helper centralizes the logic for determining which backend mode to use.
/// In the future, it will check for Firebase SDK availability and configuration.
///
/// Usage:
/// ```
/// let mode = BackendModeDetector.currentMode
/// print("Running in \(mode) mode")
/// ```
enum BackendModeDetector {
    
    // MARK: - Detection
    
    /// The current backend mode based on SDK availability and configuration.
    ///
    /// Current behavior:
    /// - Always returns .localOnly (Firebase not yet implemented)
    ///
    /// Future behavior:
    /// - Returns .firebase if Firebase SDK is installed AND GoogleService-Info.plist exists
    /// - Returns .localOnly otherwise
    static var currentMode: BackendMode {
        // Check for Firebase availability
        if isFirebaseAvailable {
            return .firebase
        }
        return .localOnly
    }
    
    /// Whether Firebase SDK is available and configured.
    ///
    /// This uses compile-time checks (#if canImport) to determine if
    /// Firebase is installed, and runtime checks for configuration.
    static var isFirebaseAvailable: Bool {
        #if canImport(FirebaseCore)
        // Check if GoogleService-Info.plist exists
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            return true
        }
        #endif
        return false
    }
    
    /// Whether the app is running in local-only mode.
    static var isLocalOnly: Bool {
        currentMode == .localOnly
    }
    
    /// Whether the app is running with Firebase backend.
    static var isFirebaseMode: Bool {
        currentMode == .firebase
    }
    
    // MARK: - Logging

    /// Log the current backend mode to console.
    /// Call this at app startup for debugging.
    static func logCurrentMode() {
        #if DEBUG
        let mode = currentMode
        print("═══════════════════════════════════════")
        print("TinyWins Backend Mode: \(mode.rawValue)")
        print("═══════════════════════════════════════")
        print("Firebase SDK available: \(isFirebaseAvailable)")
        print("Mode description: \(mode.description)")
        print("═══════════════════════════════════════")
        #endif
    }
    
    // MARK: - Factory Methods

    /// Create the appropriate SyncBackend for the current mode.
    ///
    /// Behavior:
    /// - In .firebase mode with signed-in user: FirebaseSyncBackend
    /// - Otherwise: LocalSyncBackend
    ///
    /// - Parameter familyId: Optional family ID for Firebase mode
    static func createSyncBackend(familyId: String? = nil) -> SyncBackend {
        #if canImport(FirebaseCore)
        if currentMode == .firebase {
            if let userId = Auth.auth().currentUser?.uid {
                #if DEBUG
                print("[Backend] Creating FirebaseSyncBackend for user: \(userId)")
                #endif
                return FirebaseSyncBackend(userId: userId, familyId: familyId)
            }
        }
        #endif

        #if DEBUG
        print("[Backend] Creating LocalSyncBackend")
        #endif
        return LocalSyncBackend()
    }

    /// Create the appropriate AuthService for the current mode.
    ///
    /// Behavior:
    /// - In .firebase mode: FirebaseAuthService
    /// - Otherwise: LocalAuthService
    @MainActor
    static func createAuthService() -> any AuthService {
        #if canImport(FirebaseCore)
        if currentMode == .firebase {
            #if DEBUG
            print("[Auth] Creating FirebaseAuthService")
            #endif
            return FirebaseAuthService()
        }
        #endif

        #if DEBUG
        print("[Auth] Creating LocalAuthService")
        #endif
        return LocalAuthService()
    }

    /// Get the current Firebase user ID, if signed in.
    static var currentUserId: String? {
        #if canImport(FirebaseCore)
        return Auth.auth().currentUser?.uid
        #else
        return nil
        #endif
    }

    /// Whether the user is currently signed in to Firebase.
    static var isSignedIn: Bool {
        #if canImport(FirebaseCore)
        return Auth.auth().currentUser != nil
        #else
        return false
        #endif
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension BackendModeDetector {
    /// Force a specific backend mode for testing.
    /// Only available in DEBUG builds.
    static var debugOverrideMode: BackendMode?
    
    /// Get the effective mode, considering debug overrides.
    static var effectiveMode: BackendMode {
        debugOverrideMode ?? currentMode
    }
}
#endif
