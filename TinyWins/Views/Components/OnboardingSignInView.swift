import SwiftUI

// MARK: - Onboarding Sign-In View

/// Sign-in step for onboarding when Firebase is enabled.
/// Allows users to sign in for cloud sync or skip to continue locally.
struct OnboardingSignInView: View {
    @Environment(\.theme) private var theme

    let authService: any AuthService
    let onSignedIn: (AuthUser) -> Void
    let onSkip: () -> Void

    // Phase-based state management
    @State private var phase: OnboardingSignInPhase = .options
    @State private var currentProvider: SignInProviderType = .email
    @State private var signedInEmail: String = ""
    @State private var signedInName: String?
    @State private var isNewAccount = true
    @State private var showEmailSignIn = false
    @State private var pendingUser: AuthUser?

    enum OnboardingSignInPhase: Equatable {
        case options
        case loading
        case success
        case error(SignInErrorInfo)
    }

    var body: some View {
        ZStack {
            switch phase {
            case .options, .loading:
                optionsContent
                    .overlay {
                        if phase == .loading {
                            SignInLoadingView(
                                provider: currentProvider,
                                isCreatingAccount: isNewAccount
                            )
                        }
                    }
            case .success:
                SignInSuccessView(
                    email: signedInEmail,
                    displayName: signedInName,
                    isNewAccount: isNewAccount,
                    momentCount: 0, // New user has no moments yet
                    onContinue: {
                        if let user = pendingUser {
                            onSignedIn(user)
                        }
                    }
                )
            case .error(let errorInfo):
                optionsContent
                    .sheet(isPresented: .constant(true)) {
                        SignInErrorView(
                            error: errorInfo,
                            onRetry: {
                                phase = .options
                                retrySignIn()
                            },
                            onAlternative: getAlternativeAction(errorInfo),
                            onDismiss: {
                                phase = .options
                            }
                        )
                        .presentationDetents([.height(420)])
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showEmailSignIn) {
            OnboardingEmailSignInView(
                authService: authService,
                onComplete: { user, email, name, isNew in
                    showEmailSignIn = false
                    signedInEmail = email
                    signedInName = name
                    isNewAccount = isNew
                    pendingUser = user
                    SignInHaptics.success()
                    phase = .success
                },
                onCancel: {
                    showEmailSignIn = false
                }
            )
        }
    }

    // MARK: - Options Content

    private var optionsContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Progress indicator
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ForEach(0..<4) { _ in
                            Capsule()
                                .fill(theme.borderStrong)
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 8) {
                        ForEach(["Child", "Goal", "Behaviors", "Done"], id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)

                // Hero illustration
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor, Color.green)
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Create Your Account")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Sign in to save your progress and keep your data safe")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Benefits
                VStack(spacing: 14) {
                    benefitRow(icon: "checkmark.shield.fill", color: .green, text: "Keep your data safe")
                    benefitRow(icon: "arrow.clockwise", color: .blue, text: "Restore if you switch devices")
                    benefitRow(icon: "wifi.slash", color: .orange, text: "Works offline too")
                }
                .padding(16)
                .background(theme.surface2)
                .cornerRadius(14)
                .padding(.horizontal)

                Spacer(minLength: 16)

                // Sign-in buttons
                VStack(spacing: 12) {
                    // Apple Sign-In Button
                    Button {
                        signInWithApple()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Continue with Apple")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(phase == .loading)

                    // Google Sign-In Button
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: 10) {
                            Text("G")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.red, .yellow, .green, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                            Text("Continue with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.surface2)
                        .foregroundColor(theme.textPrimary)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.borderStrong, lineWidth: 1)
                        )
                    }
                    .disabled(phase == .loading)

                    // Email Sign-In Button
                    Button {
                        currentProvider = .email
                        showEmailSignIn = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                            Text("Continue with Email")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.surface2)
                        .foregroundColor(theme.textPrimary)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.borderStrong, lineWidth: 1)
                        )
                    }
                    .disabled(phase == .loading)

                    // Skip button
                    Button {
                        onSkip()
                    } label: {
                        Text("Continue without signing in")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.accentColor)
                    }
                    .disabled(phase == .loading)
                    .padding(.top, 4)

                    // Helper text
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("You can always sign in later from Settings")
                            .font(.caption)
                    }
                    .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func benefitRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)

            Spacer()
        }
    }

    // MARK: - Sign In Actions

    private func signInWithApple() {
        SignInHaptics.buttonTap()
        currentProvider = .apple
        phase = .loading

        Task {
            do {
                try await authService.signInWithApple()

                if let user = authService.currentUser {
                    await MainActor.run {
                        signedInEmail = user.email ?? "your account"
                        signedInName = user.displayName
                        pendingUser = user
                        isNewAccount = false // Apple sign-in could be either
                        SignInHaptics.success()
                        phase = .success
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    handleAuthError(error)
                }
            } catch let nsError as NSError {
                await MainActor.run {
                    handleNSError(nsError)
                }
            } catch {
                await MainActor.run {
                    SignInHaptics.error()
                    phase = .error(.genericError(error.localizedDescription))
                }
            }
        }
    }

    private func signInWithGoogle() {
        SignInHaptics.buttonTap()
        currentProvider = .google
        phase = .loading

        Task {
            do {
                try await authService.signInWithGoogle()

                if let user = authService.currentUser {
                    await MainActor.run {
                        signedInEmail = user.email ?? "your account"
                        signedInName = user.displayName
                        pendingUser = user
                        isNewAccount = false
                        SignInHaptics.success()
                        phase = .success
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    switch error {
                    case .signInCancelled:
                        phase = .options
                    case .notImplemented:
                        SignInHaptics.warning()
                        phase = .error(SignInErrorInfo(
                            title: "Coming Soon",
                            message: "Google Sign In will be available in a future update.",
                            suggestion: "Try signing in with Apple or Email for now.",
                            icon: "g.circle",
                            canRetry: false,
                            alternativeAction: "Use Email Instead"
                        ))
                    default:
                        handleAuthError(error)
                    }
                }
            } catch {
                await MainActor.run {
                    SignInHaptics.error()
                    phase = .error(.genericError(error.localizedDescription))
                }
            }
        }
    }

    private func retrySignIn() {
        switch currentProvider {
        case .apple:
            signInWithApple()
        case .google:
            signInWithGoogle()
        case .email:
            showEmailSignIn = true
        }
    }

    private func getAlternativeAction(_ errorInfo: SignInErrorInfo) -> (() -> Void)? {
        guard let action = errorInfo.alternativeAction else { return nil }

        return {
            phase = .options
            if action == "Use Email Instead" || action == "Create Account" {
                currentProvider = .email
                showEmailSignIn = true
            } else if action == "Continue Without Signing In" {
                onSkip()
            }
        }
    }

    private func handleAuthError(_ error: AuthError) {
        switch error {
        case .signInCancelled:
            phase = .options
        case .notAvailable:
            SignInHaptics.warning()
            phase = .error(SignInErrorInfo(
                title: "Sign In Not Available",
                message: "Apple Sign In is not available on this device.",
                suggestion: "You can continue without signing in and set up sync later.",
                icon: "apple.logo",
                canRetry: false,
                alternativeAction: "Use Email Instead"
            ))
        default:
            SignInHaptics.error()
            phase = .error(.genericError(error.localizedDescription))
        }
    }

    private func handleNSError(_ error: NSError) {
        // Handle ASAuthorizationError codes
        if error.domain == "com.apple.AuthenticationServices.AuthorizationError" {
            switch error.code {
            case 1001: // Cancelled
                phase = .options
                return
            case 1000: // Unknown error
                phase = .error(SignInErrorInfo(
                    title: "Couldn't connect to Apple",
                    message: "There was a problem connecting to Apple's servers.",
                    suggestion: "Make sure you're signed into iCloud in Settings, then try again.",
                    icon: "apple.logo",
                    canRetry: true,
                    alternativeAction: "Use Email Instead"
                ))
            case 1002: // Invalid response
                phase = .error(SignInErrorInfo(
                    title: "Something went wrong",
                    message: "Received an unexpected response from Apple.",
                    suggestion: "Please try again. If the problem persists, restart the app.",
                    icon: "exclamationmark.triangle",
                    canRetry: true,
                    alternativeAction: nil
                ))
            case 1003: // Not handled
                phase = .error(SignInErrorInfo(
                    title: "Not Set Up",
                    message: "Sign in with Apple is not configured for this app yet.",
                    suggestion: "You can use email sign-in for now.",
                    icon: "apple.logo",
                    canRetry: false,
                    alternativeAction: "Use Email Instead"
                ))
            case 1004: // Failed
                phase = .error(SignInErrorInfo(
                    title: "Sign In Failed",
                    message: "The authorization attempt failed.",
                    suggestion: "Please check your internet connection and try again.",
                    icon: "wifi.slash",
                    canRetry: true,
                    alternativeAction: nil
                ))
            default:
                phase = .error(.genericError("Error code: \(error.code)"))
            }
        } else {
            phase = .error(.genericError(error.localizedDescription))
        }
        SignInHaptics.error()
    }
}

// MARK: - Onboarding Email Sign In View

/// Email sign-in for onboarding flow with success callback
private struct OnboardingEmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let authService: any AuthService
    let onComplete: (AuthUser, String, String?, Bool) -> Void
    let onCancel: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = true // Default to sign up in onboarding
    @State private var isLoading = false
    @State private var errorInfo: SignInErrorInfo?
    @State private var showingErrorSheet = false
    @State private var showingForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, password
    }

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = isSignUp ? isPasswordValid : password.count >= 6
        let nameValid = !isSignUp || !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        return emailValid && passwordValid && nameValid
    }

    private var isPasswordValid: Bool {
        password.count >= 8 &&
        password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
        password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mode toggle
                    Picker("Mode", selection: $isSignUp) {
                        Text("Create Account").tag(true)
                        Text("Sign In").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: isSignUp) { _, _ in
                        errorInfo = nil
                    }

                    // Form
                    VStack(spacing: 16) {
                        // Display name field (sign up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Your Name")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)

                                TextField("How should we greet you?", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .focused($focusedField, equals: .name)
                            }
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)

                            TextField("your@email.com", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)

                            SecureField(isSignUp ? "Create a password" : "Enter password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.oneTimeCode)
                                .focused($focusedField, equals: .password)

                            // Password requirements (for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirementRowSmall(text: "At least 8 characters", isMet: password.count >= 8)
                                    PasswordRequirementRowSmall(text: "One uppercase letter", isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil)
                                    PasswordRequirementRowSmall(text: "One lowercase letter", isMet: password.rangeOfCharacter(from: .lowercaseLetters) != nil)
                                    PasswordRequirementRowSmall(text: "One number", isMet: password.rangeOfCharacter(from: .decimalDigits) != nil)
                                }
                                .padding(.top, 4)
                            }
                        }

                        // Forgot password (sign in only)
                        if !isSignUp {
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Submit button
                    Button {
                        SignInHaptics.buttonTap()
                        submit()
                    } label: {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFormValid ? Color.accentColor : Color.gray)
                            .cornerRadius(14)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showingErrorSheet) {
                if let error = errorInfo {
                    SignInErrorView(
                        error: error,
                        onRetry: {
                            showingErrorSheet = false
                            submit()
                        },
                        onAlternative: error.alternativeAction == "Sign In Instead" ? {
                            showingErrorSheet = false
                            isSignUp = false
                        } : error.alternativeAction == "Forgot Password?" ? {
                            showingErrorSheet = false
                            showingForgotPassword = true
                        } : nil,
                        onDismiss: {
                            showingErrorSheet = false
                        }
                    )
                    .presentationDetents([.height(420)])
                }
            }
            .overlay {
                if isLoading {
                    SignInLoadingView(provider: .email, isCreatingAccount: isSignUp)
                }
            }
        }
    }

    private func submit() {
        focusedField = nil
        errorInfo = nil
        isLoading = true

        Task {
            do {
                if isSignUp {
                    try await authService.createAccount(
                        email: email,
                        password: password,
                        displayName: displayName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : displayName
                    )
                } else {
                    try await authService.signInWithEmail(email: email, password: password)
                }

                if let user = authService.currentUser {
                    await MainActor.run {
                        isLoading = false
                        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
                        onComplete(user, email, trimmedName.isEmpty ? user.displayName : trimmedName, isSignUp)
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isLoading = false
                    SignInHaptics.error()
                    errorInfo = SignInErrorInfo.fromAuthError(error, email: email)
                    showingErrorSheet = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    SignInHaptics.error()
                    // Get the underlying NSError code for Firebase errors
                    let nsError = error as NSError
                    errorInfo = SignInErrorInfo.fromFirebaseError(
                        code: nsError.code,
                        email: email
                    )
                    showingErrorSheet = true
                }
            }
        }
    }
}

// MARK: - Password Requirement Row Small

private struct PasswordRequirementRowSmall: View {
    @Environment(\.theme) private var theme
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .green : theme.textSecondary)
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? theme.textPrimary : theme.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OnboardingSignInView(
            authService: LocalAuthService(),
            onSignedIn: { _ in },
            onSkip: {}
        )
    }
}
