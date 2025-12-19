import SwiftUI

@main
struct TinyWinsApp: App {
    @StateObject private var dependencies: DependencyContainer
    @StateObject private var coordinator = AppCoordinator()

    init() {
        // Configure Firebase if enabled (handles offline mode automatically)
        AppConfiguration.configureFirebaseIfNeeded()

        // Create dependencies with appropriate backend
        let backend = AppConfiguration.createSyncBackend()
        let container = DependencyContainer(backend: backend)
        _dependencies = StateObject(wrappedValue: container)

        // Initialize SyncManager synchronously to avoid race conditions
        // This sets up network monitoring and auth state listeners
        // Cloud sync is FREE for all signed-in users
        SyncManager.shared.initialize(
            repository: container.repository,
            subscriptionManager: container.subscriptionManager
        )
    }

    var body: some Scene {
        WindowGroup {
            ThemedContentView(
                dependencies: dependencies,
                coordinator: coordinator
            )
        }
    }
}

// MARK: - Themed Content View (reacts to theme changes)

private struct ThemedContentView: View {
    @ObservedObject var dependencies: DependencyContainer
    @ObservedObject var coordinator: AppCoordinator

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - ThemeKit Integration
    /// New semantic theme system - syncs with existing themeProvider for incremental migration
    @StateObject private var theme = Theme()

    var body: some View {
        // PERFORMANCE: Reduced ContentView dependencies
        // celebrationQueueUseCase and goalPromptUseCase now handled by ContentViewModel
        ContentView(
            logBehaviorUseCase: dependencies.logBehaviorUseCase
        )
            .environmentObject(dependencies.contentViewModel)
            .environmentObject(dependencies.todayViewModel)
            .environmentObject(dependencies.kidsViewModel)
            .environmentObject(dependencies.rewardsViewModel)
            .environmentObject(dependencies.repository)
            .environmentObject(dependencies.childrenStore)
            .environmentObject(dependencies.behaviorsStore)
            .environmentObject(dependencies.rewardsStore)
            .environmentObject(dependencies.insightsStore)
            .environmentObject(dependencies.progressionStore)
            .environmentObject(dependencies.agreementsStore)
            .environmentObject(dependencies.celebrationStore)
            .environmentObject(dependencies.celebrationManager)
            .environmentObject(dependencies.userPreferences)
            .environmentObject(dependencies.themeProvider)
            .environmentObject(dependencies.subscriptionManager)
            .environmentObject(dependencies.notificationService)
            .environmentObject(dependencies.feedbackManager)
            // cloudBackupService removed - iCloud backup feature deprecated
            .environmentObject(dependencies.featureFlags)
            .environmentObject(dependencies.coachMarkManager)
            .environmentObject(coordinator)
            // MARK: Insights Tab Dependencies
            .environmentObject(dependencies.insightsNavigationState)
            .environmentObject(dependencies.insightsHomeViewModel)
            // MARK: ThemeKit - Inject new theme system
            .withTheme(theme)
            .syncThemeWithSystem(theme)
            // Legacy theme provider sync
            .syncThemeWithColorScheme(dependencies.themeProvider)
            .onChange(of: dependencies.userPreferences.appTheme) { _, newTheme in
                dependencies.themeProvider.currentTheme = newTheme
                // Sync ThemeKit with legacy themeProvider
                theme.paletteId = PaletteId(rawValue: newTheme.rawValue) ?? .system
                // Update navigation bar appearance for new theme
                configureNavigationBarAppearance()
            }
            .onChange(of: colorScheme) { _, newScheme in
                dependencies.themeProvider.colorScheme = newScheme
                // ThemeKit syncs automatically via syncThemeWithSystem
                // Update navigation bar appearance for new color scheme
                configureNavigationBarAppearance()
            }
            .onChange(of: dependencies.subscriptionManager.effectiveIsPlusSubscriber) { _, isPremium in
                // Reset premium theme if subscription expires
                dependencies.userPreferences.validateThemeAccess(isPlusSubscriber: isPremium)
                if dependencies.themeProvider.currentTheme != dependencies.userPreferences.appTheme {
                    dependencies.themeProvider.currentTheme = dependencies.userPreferences.appTheme
                }
            }
            .task {
                // Validate theme access on launch
                dependencies.userPreferences.validateThemeAccess(
                    isPlusSubscriber: dependencies.subscriptionManager.effectiveIsPlusSubscriber
                )
                // Sync ThemeKit with current appTheme on launch
                theme.paletteId = PaletteId(rawValue: dependencies.userPreferences.appTheme.rawValue) ?? .system
                // Configure navigation bar appearance on launch
                configureNavigationBarAppearance()
            }
            .onOpenURL { url in
                self.handleDeepLink(url)
            }
            // Apply theme background to entire app
            .background(theme.bg0.ignoresSafeArea())
            // Force re-render when theme or color scheme changes
            .id("\(dependencies.themeProvider.currentTheme.rawValue)-\(colorScheme == .dark ? "dark" : "light")")
            // PERFORMANCE: Apply tracking button style for stall attribution
            #if DEBUG
            .buttonStyle(TrackingPrimitiveButtonStyle())
            #endif
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        // Parse invite codes from deep links
        // Formats:
        // - tinywins://join?code=ABC123
        // - https://tinywins.app/join/ABC123
        if let inviteCode = InviteService.parseInviteCode(from: url) {
            #if DEBUG
            print("[DeepLink] Parsed invite code: \(inviteCode)")
            #endif

            // Store the code for the coordinator to handle
            coordinator.pendingInviteCode = inviteCode
            coordinator.shouldShowJoinFamily = true
        }
    }

    // MARK: - Navigation Bar Appearance

    /// Configures UIKit navigation bar appearance to match ThemeKit colors.
    /// Called on launch and whenever theme or color scheme changes.
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.navBarBg)

        // Title colors
        let titleColor = UIColor(theme.textPrimary)
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        // Back button and bar button items
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(theme.accentPrimary)]
        appearance.buttonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance

        // Apply to all navigation bar styles
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(theme.accentPrimary)
    }
}

