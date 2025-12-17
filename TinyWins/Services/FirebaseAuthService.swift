import Foundation
import Combine
import AuthenticationServices
import CryptoKit

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
#endif

// MARK: - FirebaseAuthService

/// Firebase-backed authentication service with Apple Sign-In support.
///
/// This service:
/// - Implements the AuthService protocol for Firebase Auth
/// - Supports Apple Sign-In (primary auth method)
/// - Supports Google Sign-In (prepared for future Android app)
/// - Manages auth state and publishes changes
/// - Creates Parent records on first sign-in
///
/// Requirements:
/// - Firebase SDK must be installed via SPM
/// - GoogleService-Info.plist must be in the bundle
/// - FirebaseApp.configure() must be called before use
@MainActor
final class FirebaseAuthService: NSObject, ObservableObject, AuthService {

    // MARK: - Published State

    @Published private(set) var currentUser: AuthUser? = nil
    @Published private(set) var authError: String? = nil
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private Properties

    private var authStateHandle: Any?
    private var currentNonce: String?

    // Subject for publishing auth state changes
    private let userSubject = CurrentValueSubject<AuthUser?, Never>(nil)

    // MARK: - Computed Properties

    var isSignedIn: Bool { currentUser != nil }

    var currentUserPublisher: AnyPublisher<AuthUser?, Never> {
        userSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setupAuthStateListener()
        #if DEBUG
        print("[Auth] FirebaseAuthService initialized")
        #endif
    }

    deinit {
        #if canImport(FirebaseCore)
        if let handle = authStateHandle as? AuthStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        #endif
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        #if canImport(FirebaseCore)
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user)
            }
        }
        #endif
    }

    #if canImport(FirebaseCore)
    private func handleAuthStateChange(_ firebaseUser: User?) {
        if let user = firebaseUser {
            let authUser = AuthUser(
                id: user.uid,
                displayName: user.displayName,
                email: user.email
            )
            currentUser = authUser
            userSubject.send(authUser)
            #if DEBUG
            print("[Auth] User signed in: \(user.uid)")
            #endif
        } else {
            currentUser = nil
            userSubject.send(nil)
            #if DEBUG
            print("[Auth] User signed out")
            #endif
        }
    }
    #endif

    // MARK: - Apple Sign-In

    func signInWithApple() async throws {
        #if canImport(FirebaseCore)
        isLoading = true
        authError = nil

        defer { isLoading = false }

        do {
            // Generate nonce for security
            let nonce = try randomNonceString()
            currentNonce = nonce

            // Create Apple ID request
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            // Perform the authorization
            let result = try await performAppleSignIn(request: request)

            // Process the credential
            guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.signInFailed(underlying: NSError(
                    domain: "FirebaseAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]
                ))
            }

            // Create Firebase credential
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            // Sign in with Firebase
            let authResult = try await Auth.auth().signIn(with: credential)

            // Update display name if this is first sign-in
            if let fullName = appleIDCredential.fullName,
               authResult.user.displayName == nil {
                let displayName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                if !displayName.isEmpty {
                    let changeRequest = authResult.user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    try? await changeRequest.commitChanges()
                }
            }

            #if DEBUG
            print("[Auth] Apple Sign-In successful: \(authResult.user.uid)")
            #endif

        } catch let error as ASAuthorizationError where error.code == .canceled {
            throw AuthError.signInCancelled
        } catch {
            authError = error.localizedDescription
            throw AuthError.signInFailed(underlying: error)
        }
        #else
        throw AuthError.notAvailable
        #endif
    }

    #if canImport(FirebaseCore)
    @MainActor
    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate

            // Hold reference to delegate
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

            controller.performRequests()
        }
    }
    #endif

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        #if canImport(FirebaseCore) && canImport(GoogleSignIn)
        isLoading = true
        authError = nil

        defer { isLoading = false }

        do {
            // Get the client ID from Firebase
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.signInFailed(underlying: NSError(
                    domain: "FirebaseAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Missing Google client ID"]
                ))
            }

            // Create Google Sign-In configuration
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Get the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw AuthError.signInFailed(underlying: NSError(
                    domain: "FirebaseAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No root view controller"]
                ))
            }

            // Perform Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.signInFailed(underlying: NSError(
                    domain: "FirebaseAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to fetch Google ID token"]
                ))
            }

            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            // Sign in with Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            #if DEBUG
            print("[Auth] Google Sign-In successful: \(authResult.user.uid)")
            #endif

        } catch let error as GIDSignInError where error.code == .canceled {
            throw AuthError.signInCancelled
        } catch {
            authError = error.localizedDescription
            throw AuthError.signInFailed(underlying: error)
        }
        #else
        // Google Sign-In SDK not available
        authError = "Google Sign-In is not available"
        throw AuthError.notImplemented(method: "signInWithGoogle")
        #endif
    }

    // MARK: - Email/Password Sign-In

    func signInWithEmail(email: String, password: String) async throws {
        #if canImport(FirebaseCore)
        isLoading = true
        authError = nil

        defer { isLoading = false }

        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            #if DEBUG
            print("[Auth] Email Sign-In successful: \(authResult.user.uid)")
            #endif
        } catch let error as NSError {
            authError = error.localizedDescription
            throw mapFirebaseError(error)
        }
        #else
        throw AuthError.notAvailable
        #endif
    }

    // MARK: - Create Account with Email/Password

    func createAccount(email: String, password: String, displayName: String?) async throws {
        #if canImport(FirebaseCore)
        isLoading = true
        authError = nil

        defer { isLoading = false }

        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)

            // Set display name if provided
            if let displayName = displayName, !displayName.isEmpty {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
            }

            #if DEBUG
            print("[Auth] Account created successfully: \(authResult.user.uid)")
            #endif
        } catch let error as NSError {
            authError = error.localizedDescription
            throw mapFirebaseError(error)
        }
        #else
        throw AuthError.notAvailable
        #endif
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        #if canImport(FirebaseCore)
        isLoading = true
        authError = nil

        defer { isLoading = false }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            #if DEBUG
            print("[Auth] Password reset email sent to: \(email)")
            #endif
        } catch let error as NSError {
            authError = error.localizedDescription
            throw AuthError.passwordResetFailed(underlying: error)
        }
        #else
        throw AuthError.notAvailable
        #endif
    }

    // MARK: - Sign Out

    func signOut() throws {
        #if canImport(FirebaseCore)
        do {
            try Auth.auth().signOut()
            #if DEBUG
            print("[Auth] User signed out successfully")
            #endif
        } catch {
            authError = error.localizedDescription
            throw AuthError.signOutFailed(underlying: error)
        }
        #else
        throw AuthError.notAvailable
        #endif
    }

    // MARK: - Firebase Error Mapping

    #if canImport(FirebaseCore)
    private func mapFirebaseError(_ error: NSError) -> AuthError {
        // Firebase Auth error codes
        switch error.code {
        case 17008: // ERROR_INVALID_EMAIL
            return .invalidEmail
        case 17026: // ERROR_WEAK_PASSWORD
            return .weakPassword
        case 17007: // ERROR_EMAIL_ALREADY_IN_USE
            return .emailAlreadyInUse
        case 17009: // ERROR_WRONG_PASSWORD
            return .wrongPassword
        case 17011: // ERROR_USER_NOT_FOUND
            return .userNotFound
        default:
            return .signInFailed(underlying: error)
        }
    }
    #endif

    // MARK: - Helpers

    /// Generate a random nonce string for Apple Sign-In security.
    private func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            throw AuthError.signInFailed(underlying: NSError(
                domain: "SecRandomCopyBytes",
                code: Int(errorCode),
                userInfo: [NSLocalizedDescriptionKey: "Unable to generate secure nonce for Apple Sign-In"]
            ))
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    /// Hash a string using SHA256 for Apple Sign-In.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - Apple Sign-In Delegate

#if canImport(FirebaseCore)
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Try to get window from active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
            return window
        }

        // Fallback: try any connected window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first {
            return window
        }

        // Last resort: create a new window (should never happen in practice)
        #if DEBUG
        assertionFailure("No window available for Apple Sign-In presentation - this should not happen in a running app")
        #endif
        return UIWindow()
    }
}
#endif

// MARK: - Reauthentication & Account Management

extension FirebaseAuthService {

    /// Delete the current user's account.
    /// This requires recent authentication.
    func deleteAccount() async throws {
        #if canImport(FirebaseCore)
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }

        do {
            try await user.delete()
            #if DEBUG
            print("[Auth] Account deleted successfully")
            #endif
        } catch {
            authError = error.localizedDescription
            throw AuthError.signOutFailed(underlying: error)
        }
        #else
        throw AuthError.notAvailable
        #endif
    }

    /// Reauthenticate the user with Apple Sign-In.
    /// Required before sensitive operations like account deletion.
    func reauthenticateWithApple() async throws {
        #if canImport(FirebaseCore)
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }

        let nonce = try randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let result = try await performAppleSignIn(request: request)

        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.signInFailed(underlying: NSError(
                domain: "FirebaseAuth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]
            ))
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        try await user.reauthenticate(with: credential)
        #if DEBUG
        print("[Auth] Reauthentication successful")
        #endif
        #else
        throw AuthError.notAvailable
        #endif
    }
}

// MARK: - Parent Integration

extension FirebaseAuthService {

    /// Create a Parent model from the current Firebase user.
    /// Call this after successful sign-in to create or update the parent record.
    func createParentFromCurrentUser(role: Parent.ParentRole = .parent1) -> Parent? {
        guard let user = currentUser else { return nil }

        return Parent(
            id: user.id,
            displayName: user.displayName ?? "Parent",
            email: user.email,
            role: role
        )
    }
}
