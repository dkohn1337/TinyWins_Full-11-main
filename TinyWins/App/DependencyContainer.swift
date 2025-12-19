import Foundation
import SwiftUI

/// Central dependency injection container for the TinyWins app.
/// Manages the lifecycle and dependencies of stores, services, and other shared objects.
@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: - Preferences

    let userPreferences: UserPreferencesStore
    let themeProvider: ThemeProvider

    // MARK: - Repository

    let repository: Repository

    // MARK: - Domain Stores

    let childrenStore: ChildrenStore
    let behaviorsStore: BehaviorsStore
    let rewardsStore: RewardsStore
    let insightsStore: InsightsStore
    let progressionStore: ProgressionStore
    let agreementsStore: AgreementsStore
    let celebrationStore: CelebrationStore

    // MARK: - Services (Injected, no longer using .shared directly)

    let featureFlags: FeatureFlags
    let subscriptionManager: SubscriptionManager
    let notificationService: NotificationService
    let hapticService: HapticService
    let feedbackManager: FeedbackManager
    let celebrationManager: CelebrationManager
    // cloudBackupService: Removed - iCloud backup feature deprecated
    let coachMarkManager: CoachMarkManager

    // Note: AnalyticsService and MediaManager are kept as static .shared usage
    // - AnalyticsService: struct, stateless logging
    // - MediaManager: class without ObservableObject, direct file operations

    // MARK: - Use Cases

    let logBehaviorUseCase: LogBehaviorUseCase
    let redeemRewardUseCase: RedeemRewardUseCase
    let celebrationQueueUseCase: CelebrationQueueUseCase
    let goalPromptUseCase: GoalPromptUseCase

    // MARK: - View Models

    let contentViewModel: ContentViewModel
    let todayViewModel: TodayViewModel
    let kidsViewModel: KidsViewModel
    let rewardsViewModel: RewardsViewModel
    let insightsHomeViewModel: InsightsHomeViewModel

    // MARK: - Navigation State

    let insightsNavigationState: InsightsNavigationState

    // MARK: - Initialization

    init(backend: SyncBackend = LocalSyncBackend()) {
        // Initialize in dependency order
        self.userPreferences = UserPreferencesStore()

        // Initialize theme provider with current preferences
        self.themeProvider = ThemeProvider(theme: userPreferences.appTheme)

        // Initialize repository
        self.repository = Repository(backend: backend)

        // Initialize domain stores with repository
        self.childrenStore = ChildrenStore(repository: repository)
        self.behaviorsStore = BehaviorsStore(repository: repository)
        self.rewardsStore = RewardsStore(repository: repository)
        self.insightsStore = InsightsStore(repository: repository)
        self.progressionStore = ProgressionStore()
        self.agreementsStore = AgreementsStore(repository: repository)
        self.celebrationStore = CelebrationStore()

        // Initialize services via dependency injection
        // Use .shared for now to maintain singleton behavior during migration
        // This allows gradual migration of views to use injected instances
        self.featureFlags = FeatureFlags.shared
        self.subscriptionManager = SubscriptionManager.shared
        self.notificationService = NotificationService.shared
        self.hapticService = HapticService.shared
        self.feedbackManager = FeedbackManager.shared
        self.celebrationManager = CelebrationManager()
        // cloudBackupService removed - iCloud backup feature deprecated
        self.coachMarkManager = CoachMarkManager(userPreferences: userPreferences)

        // Initialize use cases
        self.logBehaviorUseCase = LogBehaviorUseCase(
            behaviorsStore: behaviorsStore,
            childrenStore: childrenStore,
            rewardsStore: rewardsStore,
            progressionStore: progressionStore,
            celebrationStore: celebrationStore
        )
        self.redeemRewardUseCase = RedeemRewardUseCase(
            rewardsStore: rewardsStore,
            childrenStore: childrenStore,
            behaviorsStore: behaviorsStore,
            celebrationStore: celebrationStore
        )
        self.celebrationQueueUseCase = CelebrationQueueUseCase(
            behaviorsStore: behaviorsStore,
            childrenStore: childrenStore,
            insightsStore: insightsStore
        )
        self.goalPromptUseCase = GoalPromptUseCase(
            childrenStore: childrenStore,
            behaviorsStore: behaviorsStore,
            rewardsStore: rewardsStore
        )

        // Initialize view models
        self.contentViewModel = ContentViewModel(
            childrenStore: childrenStore,
            behaviorsStore: behaviorsStore,
            rewardsStore: rewardsStore,
            insightsStore: insightsStore,
            celebrationStore: celebrationStore,
            userPreferences: userPreferences
        )

        // PERFORMANCE: Wire up use cases and manager to ContentViewModel
        // This enables Combine-based observation instead of view onChange handlers
        self.contentViewModel.celebrationManager = celebrationManager
        self.contentViewModel.goalPromptUseCase = goalPromptUseCase
        self.contentViewModel.celebrationQueueUseCase = celebrationQueueUseCase
        self.todayViewModel = TodayViewModel(
            behaviorsStore: behaviorsStore,
            childrenStore: childrenStore,
            rewardsStore: rewardsStore,
            userPreferences: userPreferences
        )
        self.kidsViewModel = KidsViewModel(
            childrenStore: childrenStore,
            rewardsStore: rewardsStore,
            behaviorsStore: behaviorsStore,
            subscriptionManager: subscriptionManager
        )
        self.rewardsViewModel = RewardsViewModel(
            childrenStore: childrenStore,
            rewardsStore: rewardsStore,
            behaviorsStore: behaviorsStore,
            userPreferences: userPreferences,
            subscriptionManager: subscriptionManager
        )

        // Initialize navigation state for Insights
        self.insightsNavigationState = InsightsNavigationState()

        // Initialize InsightsHomeViewModel
        self.insightsHomeViewModel = InsightsHomeViewModel(
            repository: repository,
            childrenStore: childrenStore,
            navigation: insightsNavigationState
        )
    }
}
