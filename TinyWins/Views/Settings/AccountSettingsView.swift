import SwiftUI

#if canImport(FirebaseCore)
import FirebaseAuth
#endif

// MARK: - Account Settings Section (for SettingsView)

struct AccountSettingsSection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @State private var showingSignIn = false
    @State private var showingAccountManagement = false
    @State private var isSignedIn = false
    @State private var userEmail: String?
    @State private var authProvider: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                if isSignedIn {
                    signedInContent
                } else {
                    signedOutContent
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .onAppear {
            checkAuthState()
        }
        .sheet(isPresented: $showingSignIn) {
            AccountSignInView(onSignInComplete: {
                checkAuthState()
                showingSignIn = false
            })
        }
        .sheet(isPresented: $showingAccountManagement) {
            AccountManagementView(
                userEmail: userEmail ?? "",
                authProvider: authProvider ?? "email",
                onSignOut: {
                    checkAuthState()
                    showingAccountManagement = false
                }
            )
        }
    }

    // MARK: - Signed Out Content

    private var signedOutContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "icloud")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)

                Text("Back Up Your Data")
                    .font(.headline)

                Text("Sign in to keep your family's moments safe across devices.")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            Button {
                showingSignIn = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Sign In or Create Account")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)

            Text("Your data stays on this device until you sign in.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Signed In Content

    private var signedInContent: some View {
        VStack(spacing: 0) {
            Button {
                showingAccountManagement = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: authProviderIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userEmail ?? "Signed In")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Backed up")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var authProviderIcon: String {
        switch authProvider {
        case "apple": return "applelogo"
        case "google": return "g.circle.fill"
        default: return "envelope.fill"
        }
    }

    private func checkAuthState() {
        #if canImport(FirebaseCore)
        if let user = Auth.auth().currentUser {
            isSignedIn = true
            userEmail = user.email

            // Determine auth provider
            if let providerData = user.providerData.first {
                switch providerData.providerID {
                case "apple.com": authProvider = "apple"
                case "google.com": authProvider = "google"
                default: authProvider = "email"
                }
            }
        } else {
            isSignedIn = false
            userEmail = nil
            authProvider = nil
        }
        #else
        isSignedIn = false
        #endif
    }
}

// MARK: - Account Sign In View

struct AccountSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var behaviorsStore: BehaviorsStore

    var onSignInComplete: () -> Void

    // Phase-based state management
    @State private var phase: SignInPhase = .options
    @State private var showingEmailSignIn = false
    @State private var currentProvider: SignInProviderType = .email
    @State private var signedInEmail: String = ""
    @State private var signedInName: String?
    @State private var isNewAccount = false

    enum SignInPhase: Equatable {
        case options
        case loading
        case success
        case error(SignInErrorInfo)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content based on phase
                switch phase {
                case .options:
                    optionsContent
                case .loading:
                    optionsContent
                        .overlay(
                            SignInLoadingView(
                                provider: currentProvider,
                                isCreatingAccount: isNewAccount
                            )
                        )
                case .success:
                    SignInSuccessView(
                        email: signedInEmail,
                        displayName: signedInName,
                        isNewAccount: isNewAccount,
                        momentCount: behaviorsStore.allEvents(forPeriod: .allTime).count,
                        onContinue: {
                            onSignInComplete()
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
                                onAlternative: errorInfo.alternativeAction != nil ? {
                                    handleAlternativeAction(errorInfo)
                                } : nil,
                                onDismiss: {
                                    phase = .options
                                }
                            )
                            .presentationDetents([.height(420)])
                        }
                }
            }
            .navigationTitle(phase == .success ? "" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if phase != .success {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showingEmailSignIn) {
                SettingsEmailSignInView(
                    onComplete: { email, name, isNew in
                        showingEmailSignIn = false
                        signedInEmail = email
                        signedInName = name
                        isNewAccount = isNew
                        SignInHaptics.success()
                        phase = .success
                    },
                    onCancel: {
                        showingEmailSignIn = false
                    }
                )
            }
        }
    }

    // MARK: - Options Content

    private var optionsContent: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "icloud.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("Back Up Your Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Sign in to keep your family's moments safe and sync across all your devices.")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 32)

            Spacer()

            // Sign-in buttons
            VStack(spacing: 12) {
                // Sign in with Apple
                SignInProviderButton(
                    provider: .apple,
                    isLoading: phase == .loading && currentProvider == .apple
                ) {
                    signInWithApple()
                }

                // Sign in with Google
                SignInProviderButton(
                    provider: .google,
                    isLoading: phase == .loading && currentProvider == .google
                ) {
                    signInWithGoogle()
                }

                // Sign in with Email
                SignInProviderButton(
                    provider: .email,
                    isLoading: false
                ) {
                    currentProvider = .email
                    showingEmailSignIn = true
                }
            }
            .padding(.horizontal, 24)
            .disabled(phase == .loading)

            Spacer()

            // Privacy note
            Text("We only use your email to back up your data.\nWe never share your information.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Sign In Actions

    private func signInWithApple() {
        SignInHaptics.buttonTap()
        currentProvider = .apple
        phase = .loading

        #if canImport(FirebaseCore)
        // TODO: Implement actual Apple Sign In when available
        // For now, show informative error
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SignInHaptics.warning()
            phase = .error(SignInErrorInfo(
                title: "Coming Soon",
                message: "Apple Sign In requires additional setup.",
                suggestion: "Use email sign-in for now. Apple Sign In will be available in a future update.",
                icon: "apple.logo",
                canRetry: false,
                alternativeAction: "Use Email Instead"
            ))
        }
        #else
        phase = .error(.genericError("Firebase is not configured."))
        #endif
    }

    private func signInWithGoogle() {
        SignInHaptics.buttonTap()
        currentProvider = .google
        phase = .loading

        #if canImport(FirebaseCore)
        // TODO: Implement actual Google Sign In when available
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SignInHaptics.warning()
            phase = .error(SignInErrorInfo(
                title: "Coming Soon",
                message: "Google Sign In will be available in a future update.",
                suggestion: "Use email sign-in for now.",
                icon: "g.circle",
                canRetry: false,
                alternativeAction: "Use Email Instead"
            ))
        }
        #else
        phase = .error(.genericError("Firebase is not configured."))
        #endif
    }

    private func retrySignIn() {
        switch currentProvider {
        case .apple:
            signInWithApple()
        case .google:
            signInWithGoogle()
        case .email:
            showingEmailSignIn = true
        }
    }

    private func handleAlternativeAction(_ errorInfo: SignInErrorInfo) {
        phase = .options
        if errorInfo.alternativeAction == "Use Email Instead" {
            currentProvider = .email
            showingEmailSignIn = true
        } else if errorInfo.alternativeAction == "Sign In Instead" {
            currentProvider = .email
            showingEmailSignIn = true
        } else if errorInfo.alternativeAction == "Create Account" {
            currentProvider = .email
            showingEmailSignIn = true
        }
    }
}

// MARK: - Sign In Provider Button

enum SignInProvider {
    case apple, google, email

    var title: String {
        switch self {
        case .apple: return "Sign in with Apple"
        case .google: return "Sign in with Google"
        case .email: return "Sign in with Email"
        }
    }

    var icon: String {
        switch self {
        case .apple: return "applelogo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .apple: return .black
        case .google: return .white
        case .email: return .blue
        }
    }

    var foregroundColor: Color {
        switch self {
        case .apple: return .white
        case .google: return .black
        case .email: return .white
        }
    }

    var borderColor: Color? {
        switch self {
        case .google: return .gray.opacity(0.3)
        default: return nil
        }
    }
}

struct SignInProviderButton: View {
    let provider: SignInProvider
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: provider.icon)
                    .font(.system(size: 18))
                Text(provider.title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(provider.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(provider.backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(provider.borderColor ?? .clear, lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
    }
}

// MARK: - Settings Email Sign In View

struct SettingsEmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorInfo: SignInErrorInfo?
    @State private var showingForgotPassword = false
    @State private var showingErrorSheet = false
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, password
    }

    /// Called on successful sign-in with email, display name, and whether it's a new account
    var onComplete: (String, String?, Bool) -> Void
    var onCancel: () -> Void

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
                        Text("Sign In").tag(false)
                        Text("Create Account").tag(true)
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

                            SecureField("Enter password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.oneTimeCode)
                                .focused($focusedField, equals: .password)

                            // Password requirements (for sign up)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 4) {
                                    SettingsPasswordRequirementRow(
                                        text: "At least 8 characters",
                                        isMet: password.count >= 8
                                    )
                                    SettingsPasswordRequirementRow(
                                        text: "One uppercase letter",
                                        isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil
                                    )
                                    SettingsPasswordRequirementRow(
                                        text: "One lowercase letter",
                                        isMet: password.rangeOfCharacter(from: .lowercaseLetters) != nil
                                    )
                                    SettingsPasswordRequirementRow(
                                        text: "One number",
                                        isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
                                    )
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
                                .foregroundColor(.blue)
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
                            .background(isFormValid ? Color.blue : theme.textDisabled)
                            .cornerRadius(12)
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
                    Button("Cancel") {
                        onCancel()
                    }
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
                    SignInLoadingView(
                        provider: .email,
                        isCreatingAccount: isSignUp
                    )
                }
            }
        }
    }

    private func submit() {
        focusedField = nil
        errorInfo = nil
        isLoading = true

        #if canImport(FirebaseCore)
        Task {
            do {
                if isSignUp {
                    let result = try await Auth.auth().createUser(withEmail: email, password: password)

                    // Update display name if provided
                    let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty {
                        let changeRequest = result.user.createProfileChangeRequest()
                        changeRequest.displayName = trimmedName
                        try? await changeRequest.commitChanges()
                    }

                    await MainActor.run {
                        isLoading = false
                        SignInHaptics.success()
                        onComplete(email, trimmedName.isEmpty ? nil : trimmedName, true)
                    }
                } else {
                    try await Auth.auth().signIn(withEmail: email, password: password)

                    // Get display name from user profile
                    let userName = Auth.auth().currentUser?.displayName

                    await MainActor.run {
                        isLoading = false
                        SignInHaptics.success()
                        onComplete(email, userName, false)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    SignInHaptics.error()
                    errorInfo = SignInErrorInfo.fromFirebaseError(
                        code: (error as NSError).code,
                        email: email
                    )
                    showingErrorSheet = true
                }
            }
        }
        #else
        isLoading = false
        errorInfo = .genericError("Firebase is not configured.")
        showingErrorSheet = true
        #endif
    }
}

// MARK: - Settings Password Requirement Row

private struct SettingsPasswordRequirementRow: View {
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

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSuccess = false

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isSuccess {
                    successContent
                } else {
                    formContent
                }
            }
            .padding()
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "Sending reset link...")
                }
            }
        }
    }

    private var formContent: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .padding(.top, 32)

            // Instructions
            VStack(spacing: 8) {
                Text("Forgot your password?")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
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
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Submit button
            Button {
                sendResetLink()
            } label: {
                Text("Send Reset Link")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isEmailValid ? Color.blue : theme.textDisabled)
                    .cornerRadius(12)
            }
            .disabled(!isEmailValid || isLoading)

            Spacer()
        }
    }

    private var successContent: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .padding(.top, 32)

            // Success message
            VStack(spacing: 8) {
                Text("Check your email")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("We sent a password reset link to")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)

                Text(email)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Hint
            Text("Didn't get it? Check your spam folder or try again.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    sendResetLink()
                } label: {
                    Text("Resend Email")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Back to Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }

            Spacer()
        }
    }

    private func sendResetLink() {
        isLoading = true
        errorMessage = nil

        #if canImport(FirebaseCore)
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run {
                    isLoading = false
                    isSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
        #else
        isLoading = false
        errorMessage = "Firebase is not configured."
        #endif
    }
}

// MARK: - Account Management View

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    let userEmail: String
    let authProvider: String
    var onSignOut: () -> Void

    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccount = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                // Account info section
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: authProviderIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userEmail)
                                .font(.headline)

                            Text("Signed in with \(authProviderName)")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Sync status section
                Section {
                    HStack {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundColor(.green)
                        Text("All data backed up")
                        Spacer()
                    }
                } header: {
                    Text("Sync Status")
                }

                // Account actions
                Section {
                    if authProvider == "email" {
                        Button {
                            // Change password would go here
                        } label: {
                            Label("Change Password", systemImage: "key.fill")
                        }
                    }

                    Button {
                        showingSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } header: {
                    Text("Account")
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showingDeleteAccount = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Permanently delete your account and all associated data. This cannot be undone.")
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Sign Out?", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Your data will remain backed up in the cloud. You can sign in again anytime to access it.")
            }
            .sheet(isPresented: $showingDeleteAccount) {
                DeleteAccountView(userEmail: userEmail, onDelete: {
                    showingDeleteAccount = false
                    onSignOut()
                })
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "Signing out...")
                }
            }
        }
    }

    private var authProviderIcon: String {
        switch authProvider {
        case "apple": return "applelogo"
        case "google": return "g.circle.fill"
        default: return "envelope.fill"
        }
    }

    private var authProviderName: String {
        switch authProvider {
        case "apple": return "Apple"
        case "google": return "Google"
        default: return "Email"
        }
    }

    private func signOut() {
        isLoading = true

        #if canImport(FirebaseCore)
        do {
            try Auth.auth().signOut()
            AppConfiguration.storedFamilyId = nil
            isLoading = false
            onSignOut()
        } catch {
            isLoading = false
            // Handle error
        }
        #endif
    }
}

// MARK: - Delete Account View

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore

    let userEmail: String
    var onDelete: () -> Void

    @State private var currentStep = 0
    @State private var confirmationText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                if currentStep == 0 {
                    warningStep
                } else {
                    confirmationStep
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "Deleting account...")
                }
            }
        }
    }

    // MARK: - Step 1: Warning

    private var warningStep: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
                .padding(.top, 32)

            // Title
            Text("Delete Account")
                .font(.title2)
                .fontWeight(.bold)

            // Warning message
            VStack(alignment: .leading, spacing: 12) {
                Text("This will permanently delete:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    DeleteWarningRow(icon: "person.crop.circle", text: "Your account (\(userEmail))")
                    DeleteWarningRow(icon: "figure.2.and.child.holdinghands", text: "All family data (\(childrenStore.children.count) children)")
                    DeleteWarningRow(icon: "star.fill", text: "All logged moments (\(behaviorsStore.allEvents(forPeriod: .allTime).count) total)")
                    DeleteWarningRow(icon: "gift.fill", text: "All goals and progress")
                }
                .padding()
                .background(theme.surface2)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Text("This cannot be undone.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    currentStep = 1
                } label: {
                    Text("I Understand, Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Keep My Account")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 2: Confirmation

    private var confirmationStep: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "trash.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
                .padding(.top, 32)

            // Instructions
            VStack(spacing: 8) {
                Text("Are you sure?")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Type DELETE to confirm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Confirmation text field
            TextField("Type DELETE", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.allCharacters)
                .padding(.horizontal)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    deleteAccount()
                } label: {
                    Text("Delete My Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(confirmationText == "DELETE" ? Color.red : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(confirmationText != "DELETE" || isLoading)

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func deleteAccount() {
        isLoading = true
        errorMessage = nil

        #if canImport(FirebaseCore)
        Task {
            do {
                guard let user = Auth.auth().currentUser else {
                    throw NSError(domain: "DeleteAccount", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
                }

                // 1. Clear local data
                await MainActor.run {
                    repository.clearAllData()
                }

                // 2. Delete Firebase data (family and subcollections)
                if AppConfiguration.storedFamilyId != nil {
                    // TODO: Delete Firestore data
                    // This would require a Cloud Function or iterating through subcollections
                }

                // 3. Delete the auth account
                try await user.delete()

                // 4. Clear stored familyId
                AppConfiguration.storedFamilyId = nil

                await MainActor.run {
                    isLoading = false
                    onDelete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Check if re-authentication is needed
                    if (error as NSError).code == 17014 {
                        errorMessage = "For security, please sign out and sign back in, then try again."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        #else
        isLoading = false
        errorMessage = "Firebase is not configured."
        #endif
    }
}

// MARK: - Delete Warning Row

struct DeleteWarningRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.red)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    @Environment(\.theme) private var theme
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(theme.surface1.opacity(0.95))
            .cornerRadius(16)
        }
    }
}

// MARK: - Previews

#Preview("Not Signed In") {
    AccountSettingsSection()
        .padding()
        .environmentObject(Repository.preview)
        .environmentObject(ChildrenStore(repository: Repository.preview))
        .environmentObject(BehaviorsStore(repository: Repository.preview))
}

#Preview("Sign In View") {
    AccountSignInView(onSignInComplete: {})
}

#Preview("Forgot Password") {
    ForgotPasswordView()
}

#Preview("Delete Account") {
    DeleteAccountView(userEmail: "sarah@email.com", onDelete: {})
        .environmentObject(Repository.preview)
        .environmentObject(ChildrenStore(repository: Repository.preview))
        .environmentObject(BehaviorsStore(repository: Repository.preview))
}
