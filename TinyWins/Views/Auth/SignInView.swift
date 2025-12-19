import SwiftUI
import AuthenticationServices

// MARK: - SignInView

/// Sign-in screen with Apple, Google, and Email/Password options.
/// Supports co-parent sync and cross-platform (iOS/Android) compatibility.
struct SignInView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let authService: any AuthService
    let onSignedIn: (AuthUser) -> Void
    var onSkip: (() -> Void)?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Illustration
                    heroSection

                    // Benefits Section
                    benefitsSection

                    // Sign In Buttons
                    signInSection

                    // Skip Option
                    if let onSkip = onSkip {
                        skipSection(action: onSkip)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Sign In Failed", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showEmailForm) {
                EmailSignInView(
                    authService: authService,
                    onSignedIn: onSignedIn
                )
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Parent avatars illustration
            HStack(spacing: -20) {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("👨")
                            .font(.system(size: 40))
                    )

                Circle()
                    .fill(theme.success.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("👩")
                            .font(.system(size: 40))
                    )
            }

            Text("Better Together")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(theme.textPrimary)

            Text("Sign in to sync with your partner and celebrate your children's wins together")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 16) {
            benefitRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Sync Across Devices",
                description: "Both parents see the same data, always up to date"
            )

            benefitRow(
                icon: "cloud.fill",
                title: "Safe & Secure",
                description: "Your family data is encrypted and private"
            )

            benefitRow(
                icon: "arrow.clockwise.icloud",
                title: "Works Offline",
                description: "Log behaviors anytime, syncs when connected"
            )
        }
        .padding(20)
        .background(theme.surface1)
        .cornerRadius(12)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.accentPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Sign In Section

    private var signInSection: some View {
        VStack(spacing: 12) {
            // Apple Sign-In Button
            Button(action: signInWithApple) {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .medium))
                    Text("Continue with Apple")
                        .font(.system(size: 17, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(12)
            }
            .disabled(isLoading)

            // Google Sign-In Button
            Button(action: signInWithGoogle) {
                HStack(spacing: 8) {
                    // Google "G" logo approximation
                    Text("G")
                        .font(.system(size: 18, weight: .bold))
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
                        .font(.system(size: 17, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundColor(theme.textPrimary)
                .background(theme.surface1)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.textDisabled.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isLoading)

            // "Or" Separator
            HStack {
                Rectangle()
                    .fill(theme.textDisabled.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                Rectangle()
                    .fill(theme.textDisabled.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Email Sign-In Button
            Button(action: { showEmailForm = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                    Text("Continue with Email")
                        .font(.system(size: 17, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundColor(theme.textPrimary)
                .background(theme.surface1)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.textDisabled.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isLoading)

            // Loading indicator
            if isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    private func skipSection(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Continue without signing in")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func signInWithApple() {
        isLoading = true
        errorMessage = nil
        AnalyticsTracker.shared.trackSignInAttempt(method: "apple")

        Task {
            do {
                try await authService.signInWithApple()

                if let user = authService.currentUser {
                    await MainActor.run {
                        AnalyticsTracker.shared.trackSignInSuccess(method: "apple")
                        onSignedIn(user)
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    switch error {
                    case .signInCancelled:
                        // User cancelled - don't show error
                        break
                    default:
                        AnalyticsTracker.shared.trackSignInFailure(method: "apple", errorCode: (error as NSError).code)
                        errorMessage = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    AnalyticsTracker.shared.trackSignInFailure(method: "apple", errorCode: (error as NSError).code)
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        AnalyticsTracker.shared.trackSignInAttempt(method: "google")

        Task {
            do {
                try await authService.signInWithGoogle()

                if let user = authService.currentUser {
                    await MainActor.run {
                        AnalyticsTracker.shared.trackSignInSuccess(method: "google")
                        onSignedIn(user)
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    switch error {
                    case .signInCancelled:
                        break
                    case .notImplemented:
                        errorMessage = "Google Sign-In will be available soon."
                    default:
                        AnalyticsTracker.shared.trackSignInFailure(method: "google", errorCode: (error as NSError).code)
                        errorMessage = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    AnalyticsTracker.shared.trackSignInFailure(method: "google", errorCode: (error as NSError).code)
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Email Sign-In View

/// Handles email/password sign-in and account creation
struct EmailSignInView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let authService: any AuthService
    let onSignedIn: (AuthUser) -> Void
    var defaultToSignUp: Bool = false  // When true, starts in Sign Up mode (for onboarding)

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResetPassword = false
    @State private var resetEmailSent = false

    @FocusState private var focusedField: Field?

    enum Field {
        case displayName, email, password
    }

    // MARK: - Password Validation

    private var hasMinLength: Bool { password.count >= 8 }
    private var hasUppercase: Bool { password.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasLowercase: Bool { password.range(of: "[a-z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }

    private var isPasswordValid: Bool {
        // For sign-in, just check minimum length
        // For sign-up, require all criteria
        if isSignUp {
            return hasMinLength && hasUppercase && hasLowercase && hasNumber
        } else {
            return password.count >= 6  // More lenient for existing accounts
        }
    }

    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    init(authService: any AuthService, onSignedIn: @escaping (AuthUser) -> Void, defaultToSignUp: Bool = false) {
        self.authService = authService
        self.onSignedIn = onSignedIn
        self.defaultToSignUp = defaultToSignUp
        self._isSignUp = State(initialValue: defaultToSignUp)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(theme.accentPrimary)

                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(theme.textPrimary)

                        Text(isSignUp
                            ? "Enter your details to get started"
                            : "Sign in with your email and password")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 16) {
                        // Display name (sign up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textSecondary)

                                TextField("Your name", text: $displayName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .focused($focusedField, equals: .displayName)
                                    .padding()
                                    .background(theme.surface1)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .displayName ? theme.accentPrimary : theme.textDisabled.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textSecondary)

                            TextField("your@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(theme.surface1)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .email ? theme.accentPrimary : theme.textDisabled.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textSecondary)

                            SecureField(isSignUp ? "Create a strong password" : "Enter your password", text: $password)
                                .textContentType(.oneTimeCode)  // Prevents strong password autofill overlay
                                .focused($focusedField, equals: .password)
                                .padding()
                                .background(theme.surface1)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .password ? theme.accentPrimary : theme.textDisabled.opacity(0.3), lineWidth: 1)
                                )

                            // Password requirements (sign up only)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirementRow(
                                        text: "At least 8 characters",
                                        isMet: hasMinLength,
                                        isTyping: !password.isEmpty
                                    )
                                    PasswordRequirementRow(
                                        text: "One uppercase letter (A-Z)",
                                        isMet: hasUppercase,
                                        isTyping: !password.isEmpty
                                    )
                                    PasswordRequirementRow(
                                        text: "One lowercase letter (a-z)",
                                        isMet: hasLowercase,
                                        isTyping: !password.isEmpty
                                    )
                                    PasswordRequirementRow(
                                        text: "One number (0-9)",
                                        isMet: hasNumber,
                                        isTyping: !password.isEmpty
                                    )
                                }
                                .padding(.top, 4)
                            }

                            // Forgot password (sign in only)
                            if !isSignUp {
                                HStack {
                                    Spacer()
                                    Button("Forgot password?") {
                                        showResetPassword = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(theme.accentPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    // Error message
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Submit button with clear state indication
                    Button(action: submitForm) {
                        HStack(spacing: 8) {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundColor(isFormValid ? .white : theme.textSecondary)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? theme.accentPrimary : theme.textDisabled.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFormValid ? theme.accentPrimary : theme.textDisabled.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: isFormValid ? theme.accentPrimary.opacity(0.3) : .clear, radius: 8, y: 4)
                    }
                    .disabled(!isFormValid || isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isFormValid)

                    // Toggle sign in / sign up
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)

                        Button(isSignUp ? "Sign In" : "Sign Up") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp.toggle()
                                errorMessage = nil
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentPrimary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Password", isPresented: $showResetPassword) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Button("Send Reset Link") {
                    sendPasswordReset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email address and we'll send you a link to reset your password.")
            }
            .alert("Check Your Email", isPresented: $resetEmailSent) {
                Button("OK") {}
            } message: {
                Text("We've sent a password reset link to \(email). Check your inbox.")
            }
            .overlay {
                // Full-screen loading overlay
                if isLoading {
                    ZStack {
                        // Dimmed background
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        // Loading card
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(theme.accentPrimary)

                            Text(isSignUp ? "Creating your account..." : "Signing you in...")
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)

                            Text(isSignUp ? "Setting up your family space" : "Welcome back!")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(32)
                        .background(theme.surface1)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 20)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        let nameValid = !isSignUp || !displayName.isEmpty
        return isEmailValid && isPasswordValid && nameValid
    }

    // MARK: - Actions

    private func submitForm() {
        focusedField = nil
        isLoading = true
        errorMessage = nil

        let method = isSignUp ? "email_signup" : "email"
        AnalyticsTracker.shared.trackSignInAttempt(method: method)

        Task {
            do {
                if isSignUp {
                    try await authService.createAccount(
                        email: email,
                        password: password,
                        displayName: displayName.isEmpty ? nil : displayName
                    )
                } else {
                    try await authService.signInWithEmail(email: email, password: password)
                }

                if let user = authService.currentUser {
                    await MainActor.run {
                        AnalyticsTracker.shared.trackSignInSuccess(method: method)
                        dismiss()
                        onSignedIn(user)
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    AnalyticsTracker.shared.trackSignInFailure(method: method, errorCode: (error as NSError).code)
                    errorMessage = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    AnalyticsTracker.shared.trackSignInFailure(method: method, errorCode: (error as NSError).code)
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func sendPasswordReset() {
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                await MainActor.run {
                    resetEmailSent = true
                }
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Password Requirement Row

/// Individual password requirement indicator with checkmark animation
private struct PasswordRequirementRow: View {
    @Environment(\.theme) private var theme
    let text: String
    let isMet: Bool
    let isTyping: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .animation(.easeInOut(duration: 0.2), value: isMet)

            Text(text)
                .font(.caption)
                .foregroundColor(textColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), \(isMet ? "met" : "not yet met")")
    }

    private var iconColor: Color {
        if isMet {
            return .green
        } else if isTyping {
            return .orange.opacity(0.6)
        } else {
            return theme.textDisabled.opacity(0.5)
        }
    }

    private var textColor: Color {
        if isMet {
            return .green
        } else if isTyping {
            return theme.textPrimary.opacity(0.8)
        } else {
            return theme.textSecondary.opacity(0.7)
        }
    }
}

// MARK: - Preview

#Preview("Sign In View") {
    SignInView(
        authService: LocalAuthService(),
        onSignedIn: { user in
            print("Signed in: \(user.id)")
        },
        onSkip: {
            print("Skipped sign in")
        }
    )
    .withTheme(Theme())
}

#Preview("Email Sign In") {
    EmailSignInView(
        authService: LocalAuthService(),
        onSignedIn: { user in
            print("Signed in: \(user.id)")
        }
    )
    .withTheme(Theme())
}

// MARK: - Sign In Success View

/// Animated success screen shown after successful sign-in.
/// Provides visual confirmation and shows sync status before dismissing.
struct SignInSuccessView: View {
    @Environment(\.theme) private var theme
    let email: String
    let displayName: String?
    let isNewAccount: Bool
    let momentCount: Int
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showBadge = false
    @State private var showDetails = false
    @State private var showButton = false
    @State private var autoDismissTask: Task<Void, Never>?

    /// Auto-dismiss delay in seconds
    private let autoDismissDelay: TimeInterval = 2.5

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated protected badge
            ProtectedFamilyBadge(isAnimating: $showBadge)
                .frame(width: 120, height: 120)

            // Success message
            VStack(spacing: 10) {
                Text(headline)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subheadline)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showDetails ? 1 : 0)
            .offset(y: showDetails ? 0 : 10)

            // Sync status pill
            if momentCount > 0 {
                SyncStatusPill(count: momentCount, isSyncing: true)
                    .opacity(showDetails ? 1 : 0)
                    .offset(y: showDetails ? 0 : 10)
            }

            Spacer()

            // Continue button
            Button(action: continueTapped) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(14)
            }
            .opacity(showButton ? 1 : 0)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(theme.surface1)
        .onAppear {
            startAnimationSequence()
            scheduleAutoDismiss()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    // MARK: - Computed Properties

    private var headline: String {
        if isNewAccount {
            return "You're all set!"
        } else if let name = displayName, !name.isEmpty {
            return "Welcome back, \(name.components(separatedBy: " ").first ?? name)!"
        } else {
            return "Your family is protected"
        }
    }

    private var subheadline: String {
        "Signed in as \(email)"
    }

    // MARK: - Actions

    private func startAnimationSequence() {
        // Staggered animation sequence
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showBadge = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showDetails = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showButton = true
            }
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDelay * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    onContinue()
                }
            }
        }
    }

    private func continueTapped() {
        autoDismissTask?.cancel()
        onContinue()
    }
}

// MARK: - Protected Family Badge

/// Animated badge showing a shield protecting a family icon
struct ProtectedFamilyBadge: View {
    @Binding var isAnimating: Bool

    @State private var shieldScale: CGFloat = 0.3
    @State private var shieldOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.green.opacity(0.2))
                .scaleEffect(1.3)
                .opacity(glowOpacity)
                .blur(radius: 8)

            // Pulse ring
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .scaleEffect(pulseScale)
                .opacity(2 - pulseScale)

            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(shieldScale)
                .opacity(shieldOpacity)

            // Shield icon with built-in checkmark (no overlay needed)
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(shieldScale)
                .opacity(shieldOpacity)
        }
        .onChange(of: isAnimating) { _, animating in
            if animating {
                runAnimation()
            }
        }
    }

    private func runAnimation() {
        // Shield appears with bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            shieldScale = 1.0
            shieldOpacity = 1.0
        }

        // Glow and haptic after shield appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.4)) {
                glowOpacity = 1.0
            }

            // Trigger success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        // Pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.8)) {
                pulseScale = 1.5
            }
        }

        // Fade glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                glowOpacity = 0.4
            }
        }
    }
}

// MARK: - Sync Status Pill

/// Shows a friendly loading state during sync
struct SyncStatusPill: View {
    @Environment(\.theme) private var theme
    let count: Int
    let isSyncing: Bool

    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            // Sync indicator
            if isSyncing {
                // Circular progress spinner
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }

            // Status text
            Text(statusText)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.surface2)
        .cornerRadius(20)
    }

    private var statusText: String {
        if isSyncing {
            // Friendly, non-technical copy
            return "Syncing your data..."
        } else {
            let momentWord = count == 1 ? "moment" : "moments"
            return "\(count) \(momentWord) backed up"
        }
    }
}

// MARK: - Sign In Loading View

/// Contextual loading view shown during authentication
struct SignInLoadingView: View {
    @Environment(\.theme) private var theme
    let provider: SignInProviderType
    let isCreatingAccount: Bool

    @State private var dotCount = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Loading card
            VStack(spacing: 20) {
                // Provider icon with spinner
                ZStack {
                    Circle()
                        .fill(provider.backgroundColor.opacity(0.15))
                        .frame(width: 72, height: 72)

                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(provider.iconColor)
                }

                // Loading message
                VStack(spacing: 6) {
                    Text(loadingTitle)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    Text(loadingSubtitle)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(32)
            .background(theme.surface1)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 20)
        }
    }

    private var loadingTitle: String {
        if isCreatingAccount {
            return "Creating your account..."
        }

        switch provider {
        case .apple:
            return "Connecting with Apple..."
        case .google:
            return "Connecting with Google..."
        case .email:
            return "Signing you in..."
        }
    }

    private var loadingSubtitle: String {
        if isCreatingAccount {
            return "Setting up your family space"
        }

        switch provider {
        case .apple:
            return "This keeps your login secure"
        case .google:
            return "Verifying your account"
        case .email:
            return "Welcome back!"
        }
    }
}

// MARK: - Sign In Error View

/// Friendly error view with contextual messaging
struct SignInErrorView: View {
    @Environment(\.theme) private var theme
    let error: SignInErrorInfo
    let onRetry: () -> Void
    let onAlternative: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: error.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            .padding(.top, 24)

            // Error message
            VStack(spacing: 12) {
                Text(error.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(error.message)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Suggestion box
            if let suggestion = error.suggestion {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)

                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                if error.canRetry {
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }

                if let alternativeAction = error.alternativeAction, let onAlt = onAlternative {
                    Button(action: onAlt) {
                        Text(alternativeAction)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.accentColor)
                    }
                }

                Button(action: onDismiss) {
                    Text(error.canRetry ? "Cancel" : "OK")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Sign In Error Info

/// Structured error information for display
struct SignInErrorInfo: Equatable {
    let title: String
    let message: String
    let suggestion: String?
    let icon: String
    let canRetry: Bool
    let alternativeAction: String?

    // MARK: - Factory Methods

    static func wrongPassword() -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Hmm, that didn't match",
            message: "The password doesn't match our records.",
            suggestion: "Check for typos or try resetting your password.",
            icon: "key.slash",
            canRetry: true,
            alternativeAction: "Forgot Password?"
        )
    }

    static func noAccount(email: String) -> SignInErrorInfo {
        SignInErrorInfo(
            title: "New here?",
            message: "We don't have an account for \(email).",
            suggestion: "You can create a new account or try a different email.",
            icon: "person.crop.circle.badge.questionmark",
            canRetry: false,
            alternativeAction: "Create Account"
        )
    }

    static func accountExists(provider: String) -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Different sign-in method",
            message: "This email is already linked to \(provider).",
            suggestion: "Try signing in with \(provider) instead.",
            icon: "arrow.triangle.2.circlepath",
            canRetry: false,
            alternativeAction: "Sign in with \(provider)"
        )
    }

    static func appleSignInFailed() -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Apple couldn't connect",
            message: "There was a problem with Apple Sign In.",
            suggestion: "Make sure you're signed into iCloud in Settings.",
            icon: "apple.logo",
            canRetry: true,
            alternativeAction: "Use Email Instead"
        )
    }

    static func googleSignInFailed() -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Google couldn't connect",
            message: "There was a problem with Google Sign In.",
            suggestion: nil,
            icon: "g.circle",
            canRetry: true,
            alternativeAction: "Use Email Instead"
        )
    }

    static func networkError() -> SignInErrorInfo {
        SignInErrorInfo(
            title: "No connection",
            message: "We couldn't reach our servers.",
            suggestion: "Check your internet connection and try again.",
            icon: "wifi.slash",
            canRetry: true,
            alternativeAction: nil
        )
    }

    static func invalidEmail() -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Check your email",
            message: "That doesn't look like a valid email address.",
            suggestion: nil,
            icon: "envelope.badge.shield.half.filled",
            canRetry: true,
            alternativeAction: nil
        )
    }

    static func weakPassword() -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Stronger password needed",
            message: "Your password needs to be at least 8 characters with uppercase, lowercase, and a number.",
            suggestion: nil,
            icon: "lock.trianglebadge.exclamationmark",
            canRetry: true,
            alternativeAction: nil
        )
    }

    static func genericError(_ message: String) -> SignInErrorInfo {
        SignInErrorInfo(
            title: "Something went wrong",
            message: message,
            suggestion: "Please try again. If the problem continues, contact support.",
            icon: "exclamationmark.triangle",
            canRetry: true,
            alternativeAction: nil
        )
    }

    /// Creates error info from an AuthError
    static func fromAuthError(_ error: AuthError, email: String? = nil) -> SignInErrorInfo {
        switch error {
        case .notAvailable:
            return SignInErrorInfo(
                title: "Sign-in not available",
                message: "Sign-in is not available in offline mode.",
                suggestion: "Connect to the internet and try again.",
                icon: "wifi.slash",
                canRetry: true,
                alternativeAction: nil
            )
        case .notImplemented:
            return SignInErrorInfo(
                title: "Coming soon",
                message: "This sign-in method is not yet available.",
                suggestion: "Try email sign-in instead.",
                icon: "clock",
                canRetry: false,
                alternativeAction: "Use Email Instead"
            )
        case .signInCancelled:
            return SignInErrorInfo(
                title: "Cancelled",
                message: "Sign-in was cancelled.",
                suggestion: nil,
                icon: "xmark.circle",
                canRetry: true,
                alternativeAction: nil
            )
        case .signInFailed(let underlying):
            // Check if underlying is an NSError with a Firebase code
            let nsError = underlying as NSError
            if nsError.domain.contains("Firebase") || nsError.code >= 17000 {
                return fromFirebaseError(code: nsError.code, email: email)
            }
            return genericError(underlying.localizedDescription)
        case .invalidEmail:
            return invalidEmail()
        case .weakPassword:
            return weakPassword()
        case .emailAlreadyInUse:
            return SignInErrorInfo(
                title: "Email already in use",
                message: "An account with this email already exists.",
                suggestion: "Try signing in instead.",
                icon: "person.crop.circle.badge.exclamationmark",
                canRetry: false,
                alternativeAction: "Sign In Instead"
            )
        case .wrongPassword:
            return wrongPassword()
        case .userNotFound:
            return noAccount(email: email ?? "this email")
        case .accountCreationFailed(let underlying):
            let nsError = underlying as NSError
            if nsError.code >= 17000 {
                return fromFirebaseError(code: nsError.code, email: email)
            }
            return genericError("Account creation failed: \(underlying.localizedDescription)")
        case .noCurrentUser:
            return SignInErrorInfo(
                title: "Not signed in",
                message: "No user is currently signed in.",
                suggestion: "Please sign in to continue.",
                icon: "person.crop.circle.badge.questionmark",
                canRetry: true,
                alternativeAction: nil
            )
        case .signOutFailed, .passwordResetFailed:
            return genericError(error.localizedDescription)
        }
    }

    /// Creates error info from a Firebase error code
    static func fromFirebaseError(code: Int, email: String? = nil) -> SignInErrorInfo {
        switch code {
        case 17004: // User disabled or email/password sign-in not enabled
            return SignInErrorInfo(
                title: "Sign-in not available",
                message: "Email sign-in may not be enabled for this app.",
                suggestion: "Check that Email/Password authentication is enabled in Firebase Console.",
                icon: "exclamationmark.lock",
                canRetry: false,
                alternativeAction: nil
            )
        case 17005: // User token expired
            return SignInErrorInfo(
                title: "Session expired",
                message: "Your session has expired. Please sign in again.",
                suggestion: nil,
                icon: "clock.badge.exclamationmark",
                canRetry: true,
                alternativeAction: nil
            )
        case 17006: // Invalid API key
            return SignInErrorInfo(
                title: "Configuration error",
                message: "The app is not configured correctly.",
                suggestion: "Please contact support.",
                icon: "gear.badge.xmark",
                canRetry: false,
                alternativeAction: nil
            )
        case 17007: // Account already exists
            return SignInErrorInfo(
                title: "Account already exists",
                message: "An account with this email already exists.",
                suggestion: "Try signing in instead, or use a different email.",
                icon: "person.crop.circle.badge.exclamationmark",
                canRetry: false,
                alternativeAction: "Sign In Instead"
            )
        case 17008: // Invalid email
            return invalidEmail()
        case 17009: // Wrong password
            return wrongPassword()
        case 17011: // User not found
            return noAccount(email: email ?? "this email")
        case 17012: // Account exists with different credential
            return SignInErrorInfo(
                title: "Different sign-in method",
                message: "An account with this email exists but uses a different sign-in method.",
                suggestion: "Try signing in with Google or Apple instead.",
                icon: "arrow.triangle.2.circlepath",
                canRetry: false,
                alternativeAction: "Use Different Method"
            )
        case 17014: // User mismatch
            return SignInErrorInfo(
                title: "Account mismatch",
                message: "The credentials don't match the signed-in user.",
                suggestion: "Sign out and try again.",
                icon: "person.crop.circle.badge.questionmark",
                canRetry: false,
                alternativeAction: nil
            )
        case 17017: // Credential already in use
            return SignInErrorInfo(
                title: "Already linked",
                message: "This credential is already associated with another account.",
                suggestion: "Try a different email or sign-in method.",
                icon: "link.badge.plus",
                canRetry: false,
                alternativeAction: nil
            )
        case 17020: // Network error
            return networkError()
        case 17026: // Weak password
            return weakPassword()
        case 17999: // Internal error
            return SignInErrorInfo(
                title: "Temporary issue",
                message: "There was a temporary problem with sign-in.",
                suggestion: "Please wait a moment and try again.",
                icon: "exclamationmark.icloud",
                canRetry: true,
                alternativeAction: nil
            )
        default:
            return genericError("Error code: \(code)")
        }
    }
}

// MARK: - Sign In Provider Type

/// Provider types with associated styling
enum SignInProviderType {
    case apple
    case google
    case email

    var backgroundColor: Color {
        switch self {
        case .apple: return .black
        case .google: return .white
        case .email: return .blue
        }
    }

    var iconColor: Color {
        switch self {
        case .apple: return .black
        case .google: return .blue
        case .email: return .blue
        }
    }

    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }
}

// MARK: - Haptic Feedback Helpers

enum SignInHaptics {
    static func buttonTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
