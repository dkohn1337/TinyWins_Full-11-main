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

    var body: some View {
        ContentView(
            logBehaviorUseCase: dependencies.logBehaviorUseCase,
            celebrationQueueUseCase: dependencies.celebrationQueueUseCase,
            goalPromptUseCase: dependencies.goalPromptUseCase
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
            .syncThemeWithColorScheme(dependencies.themeProvider)
            .onChange(of: dependencies.userPreferences.appTheme) { _, newTheme in
                dependencies.themeProvider.currentTheme = newTheme
            }
            .onChange(of: colorScheme) { _, newScheme in
                dependencies.themeProvider.colorScheme = newScheme
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
            }
            .onOpenURL { url in
                self.handleDeepLink(url)
            }
            // Apply theme background to entire app
            .background(dependencies.themeProvider.backgroundColor.ignoresSafeArea())
            // Force re-render when theme or color scheme changes
            .id("\(dependencies.themeProvider.currentTheme.rawValue)-\(colorScheme == .dark ? "dark" : "light")")
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
}
