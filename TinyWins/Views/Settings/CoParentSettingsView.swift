import SwiftUI

// MARK: - CoParentSettingsView

/// Settings view for managing cloud sync and co-parent features.
/// - Cloud sync (single user): FREE for all signed-in users
/// - Co-Parent features (invite partner, partner dashboard): PREMIUM only
struct CoParentSettingsView: View {
    @Environment(\.themeProvider) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showSignIn = false
    @State private var showInviteSheet = false
    @State private var showPaywall = false
    @State private var showFamilySetup = false
    @State private var showJoinFamily = false
    @State private var signedInUser: AuthUser?
    @State private var generatedInviteCode: String?
    @State private var isGeneratingCode = false
    @State private var copiedToClipboard = false

    /// Whether user has access to CO-PARENT features (not basic cloud sync)
    /// Basic cloud sync is FREE for all users.
    /// Premium is only required for: inviting a second parent, partner dashboard.
    private var hasPremiumAccess: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    var body: some View {
        // Cloud sync is available to ALL users
        // Only co-parent invite features are gated behind premium
        mainContent
        .navigationTitle("Co-Parent Sync")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSignIn) {
            SignInView(
                authService: BackendModeDetector.createAuthService(),
                onSignedIn: { user in
                    showSignIn = false
                    signedInUser = user

                    // Check if user needs to set up or join a family
                    if repository.appData.family.memberIds.isEmpty {
                        // New user - show family setup/join options
                        showFamilySetup = true
                    } else {
                        // Existing family - just update the parent ID
                        handleSignInComplete(user: user)
                    }
                }
            )
        }
        .sheet(isPresented: $showFamilySetup) {
            if let user = signedInUser {
                FamilySetupView(
                    currentUser: user,
                    onCreateFamily: { family, parent in
                        handleFamilyCreated(family: family, parent: parent)
                        showFamilySetup = false
                    },
                    onJoinFamily: {
                        showFamilySetup = false
                        showJoinFamily = true
                    }
                )
            }
        }
        .sheet(isPresented: $showJoinFamily) {
            if let user = signedInUser {
                JoinFamilyView(
                    currentUser: user,
                    onJoinFamily: { code, parent in
                        handleJoinFamily(code: code, parent: parent)
                    }
                )
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            inviteShareSheet
        }
        .sheet(isPresented: $showPaywall) {
            PlusPaywallView(context: .coParent)
        }
        .toast(isShowing: $copiedToClipboard, message: "Copied to clipboard", icon: "doc.on.clipboard.fill")
    }

    // MARK: - Main Content (Available to ALL users)

    private var mainContent: some View {
        List {
            // Sync Status Section - FREE
            syncStatusSection

            // Partner Section - shows partner if already syncing (premium feature active)
            if repository.appData.hasCoParentSync {
                partnerSection
            } else if repository.appData.currentParentId != nil {
                // User is signed in - show invite section
                // But gate the actual invite action behind premium
                invitePartnerSection
            }

            // Account Section - FREE (sign-in/sign-out)
            accountSection

            // If not premium, show upgrade prompt at bottom
            if !hasPremiumAccess && repository.appData.currentParentId != nil {
                coParentUpgradeSection
            }
        }
    }

    // MARK: - Co-Parent Upgrade Section (shown to signed-in free users)

    private var coParentUpgradeSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite Your Partner")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        Text("Upgrade to Plus to sync with a co-parent")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }

                    Spacer()
                }

                Button {
                    showPaywall = true
                } label: {
                    Text("Get TinyWins+")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
            }
            .padding(.vertical, 8)
        } footer: {
            Text("Your data is already synced to the cloud. Plus lets you invite a partner to view and log behaviors together.")
        }
    }

    // MARK: - Legacy Upgrade Prompt (for users who haven't signed in)
    // This is kept for reference but no longer the main UI

    private var upgradePromptContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero illustration
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .cyan.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Co-Parent Sync")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(theme.primaryText)

                    Text("Celebrate your children's wins together")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    benefitItem(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Real-time Sync",
                        description: "Both parents see the same data, always up to date"
                    )

                    benefitItem(
                        icon: "person.2.badge.gearshape",
                        title: "Partner Dashboard",
                        description: "See who logged what and celebrate alignment"
                    )

                    benefitItem(
                        icon: "icloud.fill",
                        title: "Cloud Backup",
                        description: "Your data is safely backed up and synced"
                    )

                    benefitItem(
                        icon: "wifi.slash",
                        title: "Works Offline",
                        description: "Log behaviors anytime, syncs when connected"
                    )
                }
                .padding(20)
                .background(theme.cardBackground)
                .cornerRadius(16)
                .shadow(color: theme.cardShadow, radius: 8, y: 2)
                .padding(.horizontal)

                // Upgrade button
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Get TinyWins+")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func benefitItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)

                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        Section {
            HStack(spacing: 16) {
                // Status Icon
                Image(systemName: syncStatusIcon)
                    .font(.title2)
                    .foregroundColor(syncStatusColor)
                    .frame(width: 44, height: 44)
                    .background(syncStatusColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(syncStatusTitle)
                        .font(.headline)
                        .foregroundColor(theme.primaryText)

                    Text(syncStatusDescription)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            Text("Sync Status")
        }
    }

    private var syncStatusIcon: String {
        if repository.appData.hasCoParentSync {
            return "checkmark.circle.fill"
        } else if repository.appData.currentParentId != nil {
            return "person.fill"
        } else {
            return "icloud.slash"
        }
    }

    private var syncStatusColor: Color {
        if repository.appData.hasCoParentSync {
            return theme.positiveColor
        } else if repository.appData.currentParentId != nil {
            return theme.accentColor
        } else {
            return theme.secondaryText
        }
    }

    private var syncStatusTitle: String {
        if repository.appData.hasCoParentSync {
            return "Syncing with Partner"
        } else if repository.appData.currentParentId != nil {
            return "Signed In"
        } else {
            return "Local Only"
        }
    }

    private var syncStatusDescription: String {
        if repository.appData.hasCoParentSync {
            return "Both parents can see and log behaviors"
        } else if repository.appData.currentParentId != nil {
            return "Invite your partner to sync together"
        } else {
            return "Sign in to enable cloud sync"
        }
    }

    // MARK: - Partner Section

    private var partnerSection: some View {
        Section {
            if let partner = repository.appData.partnerParent {
                HStack(spacing: 16) {
                    Text(partner.avatarEmoji)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(theme.positiveColor.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(partner.displayName)
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(partner.isRecentlyActive ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)

                            Text(partner.isRecentlyActive ? "Active recently" : "Not active recently")
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Your Partner")
        }
    }

    // MARK: - Invite Partner Section

    private var invitePartnerSection: some View {
        Section {
            // PREMIUM FEATURE: Inviting a partner requires Plus subscription
            if hasPremiumAccess {
                // Premium user - show full invite functionality
                if let inviteCode = repository.appData.family.inviteCode,
                   repository.appData.family.isInviteCodeValid {
                    existingInviteCodeView(inviteCode)
                } else {
                    // Generate new invite button
                    Button(action: generateInviteCode) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(theme.accentColor)

                            Text("Invite Partner")
                                .foregroundColor(theme.primaryText)

                            Spacer()

                            if isGeneratingCode {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                    }
                    .disabled(isGeneratingCode)
                }
            } else {
                // Free user - show locked state with upgrade prompt
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(theme.secondaryText)

                        Text("Invite Partner")
                            .foregroundColor(theme.primaryText)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Plus")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                    }
                }
            }
        } header: {
            Text("Invite Partner")
        } footer: {
            if hasPremiumAccess {
                Text("Your partner can join your family using an invite code. You'll both be able to see and log behaviors for your children.")
            } else {
                Text("Upgrade to Plus to invite a co-parent and sync your family data together.")
            }
        }
    }

    private func existingInviteCodeView(_ inviteCode: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Code Display
            HStack {
                Text("Invite Code")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)

                Spacer()

                if let expiresAt = repository.appData.family.inviteCodeExpiresAt {
                    Text("Expires \(expiresAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }

            HStack(spacing: 8) {
                Text(inviteCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryText)
                    .tracking(4)

                Spacer()

                Button {
                    UIPasteboard.general.string = inviteCode
                    copiedToClipboard = true
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(theme.accentColor)
                }
            }

            // Share Buttons
            HStack(spacing: 12) {
                Button {
                    showInviteSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accentColor)
                        .cornerRadius(8)
                }

                Button(action: generateInviteCode) {
                    Label("New Code", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accentColor.opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            if let currentParent = repository.appData.currentParent {
                // Current user info
                HStack(spacing: 16) {
                    Text(currentParent.avatarEmoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(theme.accentColor.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentParent.displayName)
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        if let email = currentParent.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)

                // Sign out button
                Button(role: .destructive) {
                    signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                }
            } else {
                // Sign in button
                Button {
                    showSignIn = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundColor(theme.accentColor)

                        Text("Sign In to Enable Sync")
                            .foregroundColor(theme.primaryText)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Invite Share Sheet

    private var inviteShareSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.accentColor)

                    Text("Invite Your Partner")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 32)

                // Code Display
                if let code = repository.appData.family.inviteCode {
                    VStack(spacing: 8) {
                        Text("Share this code:")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)

                        Text(code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .tracking(6)
                    }
                    .padding(24)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }

                // Share Options
                VStack(spacing: 16) {
                    shareButton(
                        icon: "message.fill",
                        title: "Share via Messages",
                        color: .green,
                        action: shareViaMessages
                    )

                    shareButton(
                        icon: "envelope.fill",
                        title: "Share via Email",
                        color: theme.accentColor,
                        action: shareViaEmail
                    )

                    shareButton(
                        icon: "doc.on.doc",
                        title: "Copy Code",
                        color: .gray,
                        action: copyCode
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showInviteSheet = false
                    }
                }
            }
        }
    }

    private func shareButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .foregroundColor(theme.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(theme.secondaryText)
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Actions

    private func generateInviteCode() {
        isGeneratingCode = true

        // Generate code locally and update family
        var updatedFamily = repository.appData.family
        updatedFamily.generateInviteCode()

        var updatedData = repository.appData
        updatedData.family = updatedFamily

        repository.updateAppData(updatedData)
        isGeneratingCode = false
    }

    private func shareViaMessages() {
        guard let code = repository.appData.family.inviteCode,
              let parentName = repository.appData.currentParent?.displayName else { return }

        let text = InviteService.shortShareText(inviteCode: code, parentName: parentName)
        let url = "sms:&body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }

    private func shareViaEmail() {
        guard let code = repository.appData.family.inviteCode,
              let parentName = repository.appData.currentParent?.displayName else { return }

        let subject = InviteService.emailSubject(familyName: repository.appData.family.name)
        let body = InviteService.shareText(
            inviteCode: code,
            parentName: parentName,
            familyName: repository.appData.family.name
        )

        let url = "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }

    private func copyCode() {
        guard let code = repository.appData.family.inviteCode else { return }
        UIPasteboard.general.string = code
        copiedToClipboard = true
        showInviteSheet = false
    }

    // MARK: - Post-Sign-In Handlers

    private func handleSignInComplete(user: AuthUser) {
        // Add or update parent in app data
        var updatedData = repository.appData

        if updatedData.parent(byId: user.id) == nil {
            // New parent - create record
            let parent = Parent(
                id: user.id,
                displayName: user.displayName ?? "Parent",
                email: user.email,
                familyId: updatedData.family.id,
                role: updatedData.parents.isEmpty ? .parent1 : .parent2
            )
            updatedData.addParent(parent)
        }

        updatedData.currentParentId = user.id
        repository.updateAppData(updatedData)
    }

    private func handleFamilyCreated(family: Family, parent: Parent) {
        var updatedData = repository.appData

        // Update family with new info
        var newFamily = updatedData.family
        newFamily.name = family.name
        newFamily.memberIds = [parent.id]
        newFamily.createdByParentId = parent.id

        updatedData.family = newFamily
        updatedData.addParent(parent)
        updatedData.currentParentId = parent.id

        repository.updateAppData(updatedData)
    }

    private func handleJoinFamily(code: String, parent: Parent) {
        // This requires Firebase to validate the code and get the family
        // For now, show error - full implementation needs FirebaseSyncBackend
        #if canImport(FirebaseCore)
        Task {
            do {
                let backend = FirebaseSyncBackend(userId: parent.id, familyId: nil)
                _ = try await backend.joinFamily(inviteCode: code)

                // Successfully joined - update local data
                await MainActor.run {
                    var updatedData = repository.appData
                    updatedData.addParent(parent)
                    updatedData.currentParentId = parent.id
                    repository.updateAppData(updatedData)

                    showJoinFamily = false
                }
            } catch {
                // Handle error - would need error state
                #if DEBUG
                print("[CoParent] Join family failed: \(error)")
                #endif
            }
        }
        #else
        // Firebase not available
        showJoinFamily = false
        #endif
    }

    private func signOut() {
        let authService = BackendModeDetector.createAuthService()
        try? authService.signOut()

        // Clear current parent ID
        var updatedData = repository.appData
        updatedData.currentParentId = nil
        repository.updateAppData(updatedData)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CoParentSettingsView()
    }
    .environmentObject(Repository.preview)
    .environmentObject(SubscriptionManager())
    .withThemeProvider(ThemeProvider())
}
