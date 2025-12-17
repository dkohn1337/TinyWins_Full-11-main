import Foundation
import Combine

// MARK: - AuthUser Model

/// Represents an authenticated user.
/// This is a simple value type that both LocalAuthService and future
/// FirebaseAuthService will use to represent the current user.
struct AuthUser: Equatable, Codable, Identifiable {
    let id: String
    let displayName: String?
    let email: String?
    
    init(id: String, displayName: String? = nil, email: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
    }
}

// MARK: - AuthError

/// Errors that can occur during authentication operations.
enum AuthError: LocalizedError {
    case notAvailable
    case notImplemented(method: String)
    case signInCancelled
    case signInFailed(underlying: Error)
    case signOutFailed(underlying: Error)
    case noCurrentUser
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case accountCreationFailed(underlying: Error)
    case passwordResetFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Authentication is not available in local-only mode."
        case .notImplemented(let method):
            return "\(method) is not implemented in local-only mode."
        case .signInCancelled:
            return "Sign-in was cancelled."
        case .signInFailed(let error):
            return "Sign-in failed: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Sign-out failed: \(error.localizedDescription)"
        case .noCurrentUser:
            return "No user is currently signed in."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try signing in instead."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email. Create an account to get started."
        case .accountCreationFailed(let error):
            return "Could not create account: \(error.localizedDescription)"
        case .passwordResetFailed(let error):
            return "Could not send reset email: \(error.localizedDescription)"
        }
    }
}

// MARK: - AuthService Protocol

/// Protocol for authentication services.
///
/// This abstraction allows the app to:
/// - Work in local-only mode with LocalAuthService (no sign-in)
/// - Support Firebase Auth in the future with FirebaseAuthService
///
/// The protocol is intentionally minimal to keep the interface clean
/// and easy to implement for different backends.
///
/// Note: Marked @MainActor for Swift 6 concurrency safety since all
/// auth state mutations should happen on the main thread for UI updates.
@MainActor
protocol AuthService: AnyObject, ObservableObject {
    
    /// The currently signed-in user, or nil if not signed in.
    var currentUser: AuthUser? { get }
    
    /// Publisher for observing auth state changes.
    var currentUserPublisher: AnyPublisher<AuthUser?, Never> { get }
    
    /// Whether a user is currently signed in.
    var isSignedIn: Bool { get }
    
    /// The most recent auth error, if any.
    var authError: String? { get }
    
    /// Sign in with Apple.
    /// - Throws: AuthError if sign-in fails or is cancelled.
    func signInWithApple() async throws
    
    /// Sign in with Google.
    /// - Throws: AuthError if sign-in fails or is cancelled.
    func signInWithGoogle() async throws
    
    /// Sign out the current user.
    /// - Throws: AuthError if sign-out fails.
    func signOut() throws

    /// Sign in with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Throws: AuthError if sign-in fails.
    func signInWithEmail(email: String, password: String) async throws

    /// Create a new account with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 6 characters)
    ///   - displayName: Optional display name for the user
    /// - Throws: AuthError if account creation fails.
    func createAccount(email: String, password: String, displayName: String?) async throws

    /// Send a password reset email.
    /// - Parameter email: User's email address
    /// - Throws: AuthError if sending fails.
    func sendPasswordReset(email: String) async throws
}

// MARK: - Default Implementations

extension AuthService {
    var isSignedIn: Bool {
        currentUser != nil
    }
}

// MARK: - LocalAuthService

/// A no-op auth service for local-only mode.
///
/// This implementation:
/// - Always reports currentUser as nil
/// - Sign-in methods throw "not available" errors
/// - Sign-out is a no-op
///
/// Purpose:
/// - Allows the app to compile and run without Firebase dependencies
/// - Provides a clean interface for views to check auth state
/// - Will be replaced by FirebaseAuthService when Firebase is configured
///
/// Future: FirebaseAuthService will implement this protocol with real
/// Apple Sign-In and Google Sign-In support via Firebase Auth SDK.
@MainActor
final class LocalAuthService: ObservableObject, AuthService {
    
    // MARK: - Published State
    
    @Published private(set) var currentUser: AuthUser? = nil
    @Published private(set) var authError: String? = nil
    
    // MARK: - Computed Properties
    
    var isSignedIn: Bool { currentUser != nil }
    
    var currentUserPublisher: AnyPublisher<AuthUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        // Local mode: No user is ever signed in
        #if DEBUG
        print("[Auth] LocalAuthService initialized (no sign-in available)")
        #endif
    }
    
    // MARK: - AuthService Implementation
    
    func signInWithApple() async throws {
        authError = AuthError.notAvailable.localizedDescription
        throw AuthError.notAvailable
    }
    
    func signInWithGoogle() async throws {
        authError = AuthError.notAvailable.localizedDescription
        throw AuthError.notAvailable
    }

    func signInWithEmail(email: String, password: String) async throws {
        authError = AuthError.notAvailable.localizedDescription
        throw AuthError.notAvailable
    }

    func createAccount(email: String, password: String, displayName: String?) async throws {
        authError = AuthError.notAvailable.localizedDescription
        throw AuthError.notAvailable
    }

    func sendPasswordReset(email: String) async throws {
        authError = AuthError.notAvailable.localizedDescription
        throw AuthError.notAvailable
    }

    func signOut() throws {
        // No-op in local mode - there's never a signed-in user
        // This is intentionally not throwing to allow safe "sign out if needed" calls
    }
}

// MARK: - AuthService Factory

/// Factory for creating the appropriate AuthService based on configuration.
/// This will be expanded in the future when FirebaseAuthService is implemented.
enum AuthServiceFactory {
    
    /// Create the appropriate AuthService based on current configuration.
    ///
    /// Current behavior:
    /// - Always returns LocalAuthService (Firebase not yet implemented)
    ///
    /// Future behavior:
    /// - If Firebase SDK is available AND configured, return FirebaseAuthService
    /// - Otherwise, return LocalAuthService
    @MainActor
    static func create() -> any AuthService {
        // TODO: In the future, check for Firebase availability:
        // #if canImport(FirebaseAuth)
        // if FirebaseApp.app() != nil {
        //     return FirebaseAuthService()
        // }
        // #endif
        
        return LocalAuthService()
    }
}
