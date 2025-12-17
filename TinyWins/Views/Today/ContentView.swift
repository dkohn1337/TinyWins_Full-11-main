import SwiftUI
import Network

struct ContentView: View {
    let logBehaviorUseCase: LogBehaviorUseCase
    let celebrationQueueUseCase: CelebrationQueueUseCase
    let goalPromptUseCase: GoalPromptUseCase

    @EnvironmentObject private var contentViewModel: ContentViewModel
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var celebrationStore: CelebrationStore
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @EnvironmentObject private var coachMarkManager: CoachMarkManager
    @EnvironmentObject private var coordinator: AppCoordinator

    // Track last processed event to avoid duplicate celebrations
    @State private var lastProcessedEventId: UUID?

    // Current action ID for batching celebrations
    @State private var currentActionId: UUID?

    // NOTE: InsightsNavigationState is now owned by AppCoordinator for stable lifecycle
    // Access via coordinator.insightsNavigation

    var body: some View {
        ZStack {
            Group {
                // Show onboarding until explicitly completed (not just when child exists)
                if contentViewModel.hasCompletedOnboarding {
                    mainTabView
                } else {
                    OnboardingFlowView()
                }
            }
            // Prompt to create goal if child has moments but no goal
            // H1 FIX: Defer goal prompt to next session to avoid interrupting logging flow
            .onChange(of: behaviorsStore.behaviorEvents.count) { _, newCount in
                // Goal prompt is now checked on app launch, not during active logging
                // This prevents the modal from interrupting the user mid-flow
                flagGoalPromptForNextSession()

                // Get the latest event (use max instead of sorted().first for O(n) vs O(n log n))
                guard let lastEvent = behaviorsStore.behaviorEvents.max(by: { $0.timestamp < $1.timestamp }),
                      lastEvent.id != lastProcessedEventId,
                      lastEvent.pointsApplied > 0 else { return }

                lastProcessedEventId = lastEvent.id

                // Generate a new action ID for this behavior logging action
                let actionId = UUID()
                currentActionId = actionId

                // Queue all celebrations that should trigger from this action
                queueCelebrationsForEvent(lastEvent, actionId: actionId)

                // Process after a short delay to allow stores to finish setting milestone/goal celebrations
                // Reduced from 150ms to 50ms for snappier response (imperceptible delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // Only process if this is still the current action
                    if currentActionId == actionId {
                        celebrationManager.processCelebrations(forAction: actionId)
                    }
                }
            }
            .sheet(item: $coordinator.presentedSheet) { sheet in
                sheetContent(for: sheet)
            }
            .fullScreenCover(item: $coordinator.presentedFullScreenCover) { cover in
                fullScreenCoverContent(for: cover)
            }

            // Unified celebration overlay from CelebrationManager
            if let celebration = celebrationManager.activeCelebration {
                CelebrationOverlay(celebration: celebration) {
                    celebrationManager.dismissCelebration()
                    // Also clear the celebration store states
                    contentViewModel.dismissMilestone()
                    contentViewModel.dismissRewardEarnedCelebration()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(100)
            }

            // Secondary celebration banner (shows after primary modal)
            if let banner = celebrationManager.currentSecondaryBanner {
                VStack {
                    SecondaryCelebrationBanner(celebration: banner) {
                        celebrationManager.dismissSecondaryBanner()
                    }
                    .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(99)
            }

            // L3 DOCUMENTED: Coach marks overlay - PRIORITY HIERARCHY:
            // 1. Primary celebration (zIndex 100) - highest priority
            // 2. Secondary celebration banner (zIndex 99)
            // 3. Coach marks (zIndex 98) - only shown when no active celebration
            // This ensures celebrations always take precedence over guidance overlays
            if coachMarkManager.isShowingCoachMark && celebrationManager.activeCelebration == nil {
                CoachMarkOverlay(manager: coachMarkManager)
                    .zIndex(98)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: celebrationManager.activeCelebration != nil)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: celebrationManager.currentSecondaryBanner != nil)
        .animation(.easeInOut(duration: 0.3), value: coachMarkManager.isShowingCoachMark)
        // Collect coach mark target rects from child views
        .onPreferenceChange(CoachMarkTargetPreferenceKey.self) { targets in
            for (target, rect) in targets {
                coachMarkManager.registerTarget(target, rect: rect)
            }
        }
        // Listen for celebration store triggers and queue to manager
        .onChange(of: celebrationStore.rewardEarnedCelebration?.id) { _, newValue in
            if let celebration = celebrationStore.rewardEarnedCelebration,
               let actionId = currentActionId {
                celebrationManager.queueCelebration(
                    .goalReached(
                        childId: celebration.childId,
                        childName: celebration.childName,
                        rewardId: celebration.rewardId,
                        rewardName: celebration.rewardName,
                        rewardIcon: celebration.rewardIcon
                    ),
                    forAction: actionId
                )
            }
        }
        .onChange(of: celebrationStore.recentMilestone?.id) { _, newValue in
            if let milestone = celebrationStore.recentMilestone,
               let actionId = currentActionId {
                celebrationManager.queueCelebration(
                    .milestoneReached(
                        childId: milestone.childId,
                        childName: milestone.childName,
                        rewardId: milestone.rewardId,
                        rewardName: milestone.rewardName,
                        milestone: milestone.milestone,
                        target: milestone.target,
                        message: milestone.message
                    ),
                    forAction: actionId
                )
            }
        }
    }

    // MARK: - Celebration Processing

    private func queueCelebrationsForEvent(_ event: BehaviorEvent, actionId: UUID) {
        // Use CelebrationQueueUseCase to determine which celebrations to queue
        let result = celebrationQueueUseCase.execute(for: event)

        // Queue Gold Star Day if applicable
        if let goldStarDay = result.goldStarDay {
            celebrationManager.queueCelebration(
                .goldStarDay(
                    childId: goldStarDay.childId,
                    childName: goldStarDay.childName,
                    momentCount: goldStarDay.momentCount
                ),
                forAction: actionId
            )
        }

        // Queue pattern insight if applicable
        if let pattern = result.patternInsight {
            let patternInsight = CelebrationManager.PatternInsight(
                title: pattern.insight.title,
                message: pattern.insight.message,
                suggestion: pattern.insight.suggestion,
                icon: pattern.insight.icon,
                color: pattern.insight.color
            )
            celebrationManager.queueCelebration(
                .patternFound(
                    childId: pattern.childId,
                    childName: pattern.childName,
                    behaviorId: pattern.behaviorId,
                    behaviorName: pattern.behaviorName,
                    count: pattern.count,
                    insight: patternInsight
                ),
                forAction: actionId
            )
        }
    }

    @State private var isOffline: Bool = false

    private var mainTabView: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let computedTabBarInset = FloatingTabBarMetrics.totalFixedHeight + safeAreaBottom

            ZStack(alignment: .bottom) {
                // Content area with computed tab bar inset
                VStack(spacing: 0) {
                    // Offline banner at top
                    if isOffline {
                        OfflineBanner()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Group {
                        switch coordinator.selectedTab {
                        case .today:
                            TodayView(logBehaviorUseCase: logBehaviorUseCase)
                        case .kids:
                            KidsView()
                        case .rewards:
                            RewardsView()
                        case .insights:
                            InsightsHomeView()
                                .environmentObject(coordinator.insightsNavigation)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .environment(\.tabBarInset, computedTabBarInset)

                // Floating tab bar
                FloatingTabBar(selectedTab: $coordinator.selectedTab)
            }
            .animation(.easeInOut(duration: 0.3), value: isOffline)
            .onAppear {
                startNetworkMonitoring()
                // H1 FIX: Check for goal prompt on app launch (deferred from previous session)
                checkForGoalPromptOnLaunch()
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    /// Simple network monitoring using NWPathMonitor
    private func startNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isOffline = path.status != .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    /// H1 FIX: Flag that a goal prompt should be shown on next app launch
    /// This prevents interrupting the user's active logging flow
    private func flagGoalPromptForNextSession() {
        let result = goalPromptUseCase.execute()
        if result.childToPrompt != nil {
            // Store flag for next session - prompt will be shown on next cold launch
            UserDefaults.standard.set(true, forKey: "pendingGoalPrompt")
        }
    }

    /// Check for goal prompt on app launch (not during active logging)
    private func checkForGoalPromptOnLaunch() {
        // Only show if flagged from previous session
        guard UserDefaults.standard.bool(forKey: "pendingGoalPrompt") else { return }

        // Clear the flag
        UserDefaults.standard.set(false, forKey: "pendingGoalPrompt")

        // Delay to let UI settle after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let result = goalPromptUseCase.execute()
            if let child = result.childToPrompt {
                coordinator.presentSheet(.goalPrompt(child: child))
            }
        }
    }

    // MARK: - Sheet Content Builder

    @ViewBuilder
    private func sheetContent(for sheet: AppCoordinator.Sheet) -> some View {
        switch sheet {
        case .logBehavior(let child):
            LogBehaviorSheet(
                child: child,
                onBehaviorSelected: { behaviorTypeId, note, mediaAttachments, rewardId in
                    logBehaviorUseCase.execute(
                        childId: child.id,
                        behaviorTypeId: behaviorTypeId,
                        note: note
                    )
                    coordinator.dismissSheet()
                },
                onQuickAdd: nil
            )
        case .addChild:
            AddEditChildView(mode: .add) { newChild in
                childrenStore.addChild(newChild)
                coordinator.dismissSheet()
            }
        case .editChild(let child):
            AddEditChildView(mode: .edit(child)) { updatedChild in
                childrenStore.updateChild(updatedChild)
                coordinator.dismissSheet()
            }
        case .addReward(let child):
            AddRewardView(child: child)
        case .editReward(let reward, let child):
            AddRewardView(child: child, editingReward: reward)
        case .rewardTemplatePicker(let child):
            RewardTemplatePickerView(
                child: child,
                onTemplateSelected: { template in
                    let reward = Reward(
                        childId: child.id,
                        name: template.name,
                        targetPoints: template.defaultPoints,
                        imageName: template.icon,
                        dueDate: Calendar.current.date(byAdding: .day, value: template.defaultDurationDays, to: Date())
                    )
                    rewardsStore.addReward(reward)
                    coordinator.dismissSheet()
                },
                onCreateCustom: {
                    coordinator.dismissSheet()
                    coordinator.presentSheet(.addReward(child: child))
                }
            )
        case .behaviorManagement:
            BehaviorManagementView()
        case .feedback:
            FeedbackView()
        case .settings:
            SettingsView()
        // backupSettings removed - iCloud backup feature deprecated
        case .notificationSettings:
            NotificationsSettingsView()
        case .appearanceSettings:
            AppearanceSettingsView()
        case .agreementView(let child):
            FamilyPlanView(child: child)
        case .editMoment(let event):
            EditMomentView(event: event)
        case .allowanceView:
            AllowanceView()
        case .paywall:
            PlusPaywallView()
        case .goalPrompt(let child):
            GoalPromptSheet(child: child)
        }
    }

    // MARK: - Full Screen Cover Content Builder

    @ViewBuilder
    private func fullScreenCoverContent(for cover: AppCoordinator.FullScreenCover) -> some View {
        switch cover {
        case .onboarding:
            OnboardingFlowView()
        case .kidView(let child, _):
            KidView(child: child)
        case .kidGoalSelection(let child):
            KidGoalSelectionView(
                child: child,
                suggestions: contentViewModel.generateKidGoalOptions(forChild: child.id),
                onGoalSelected: { selectedOption in
                    // Create the reward from the selected option
                    let reward = Reward(
                        childId: child.id,
                        name: selectedOption.name,
                        targetPoints: selectedOption.stars,
                        imageName: selectedOption.icon,
                        priority: rewardsStore.rewards(forChild: child.id).filter { !$0.isRedeemed }.count,
                        dueDate: Calendar.current.date(byAdding: .day, value: selectedOption.days, to: Date())
                    )
                    rewardsStore.addReward(reward)
                },
                onManageRewards: {
                    // Dismiss and open custom goal creation
                    let childToAdd = child
                    coordinator.dismissFullScreenCover()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        coordinator.selectTab(.rewards)
                        coordinator.presentSheet(.addReward(child: childToAdd))
                    }
                }
            )
        case .goalPrompt(let child):
            GoalPromptSheet(child: child)
        }
    }
}

// MARK: - Preview

#Preview {
    let dependencies = DependencyContainer()
    let coordinator = AppCoordinator()
    ContentView(
        logBehaviorUseCase: dependencies.logBehaviorUseCase,
        celebrationQueueUseCase: dependencies.celebrationQueueUseCase,
        goalPromptUseCase: dependencies.goalPromptUseCase
    )
        .environmentObject(dependencies.contentViewModel)
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
        .environmentObject(coordinator)
}

#Preview("Onboarding") {
    let dependencies = DependencyContainer()
    let coordinator = AppCoordinator()
    ContentView(
        logBehaviorUseCase: dependencies.logBehaviorUseCase,
        celebrationQueueUseCase: dependencies.celebrationQueueUseCase,
        goalPromptUseCase: dependencies.goalPromptUseCase
    )
        .environmentObject(dependencies.contentViewModel)
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
        .environmentObject(coordinator)
}
