import SwiftUI
import Network

/// Main content view with optimized store dependencies.
///
/// PERFORMANCE OPTIMIZATION:
/// - Reduced from 8 @EnvironmentObject to 4 essential ones
/// - Celebration processing moved to ContentViewModel (Combine-based)
/// - Heavy operations run asynchronously via ViewModel
/// - Store observation happens in ViewModel, not view body
struct ContentView: View {
    let logBehaviorUseCase: LogBehaviorUseCase

    // MARK: - Essential Dependencies Only
    // ContentViewModel handles celebration processing via Combine
    // childrenStore/rewardsStore only needed for sheet callbacks (not observation)
    @EnvironmentObject private var contentViewModel: ContentViewModel
    @EnvironmentObject private var todayViewModel: TodayViewModel
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @EnvironmentObject private var coachMarkManager: CoachMarkManager
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var kidsViewModel: KidsViewModel
    @EnvironmentObject private var rewardsViewModel: RewardsViewModel
    @EnvironmentObject private var insightsNavigation: InsightsNavigationState
    @EnvironmentObject private var insightsHomeViewModel: InsightsHomeViewModel

    // NOTE: behaviorsStore and celebrationStore observation moved to ContentViewModel
    // This prevents view body recalculation on every store change

    var body: some View {
        ZStack {
            Group {
                // Show onboarding until explicitly completed
                if contentViewModel.hasCompletedOnboarding {
                    mainTabView
                } else {
                    OnboardingFlowView()
                }
            }
            // PERFORMANCE: Removed .onChange(of: behaviorsStore.behaviorEvents.count)
            // Now handled by ContentViewModel using Combine (doesn't trigger view re-render)
            .sheet(item: $coordinator.presentedSheet) { sheet in
                // PHASE 4: DeferredBuild to prevent sheet presentation stalls
                DeferredBuild {
                    sheetContent(for: sheet)
                }
                #if DEBUG
                .onAppear {
                    FrameStallMonitor.shared.markPresentSheet(sheet.trackingName)
                }
                #endif
            }
            .fullScreenCover(item: $coordinator.presentedFullScreenCover) { cover in
                // PHASE 4: DeferredBuild to prevent presentation stalls
                DeferredBuild {
                    fullScreenCoverContent(for: cover)
                }
                #if DEBUG
                .onAppear {
                    FrameStallMonitor.shared.markPresentFullscreen(cover.trackingName)
                }
                #endif
            }

            // Unified celebration overlay from CelebrationManager
            // PERFORMANCE: Animation scoped to this specific view, not affecting parent/siblings
            if let celebration = celebrationManager.activeCelebration {
                CelebrationOverlay(celebration: celebration) {
                    celebrationManager.dismissCelebration()
                    contentViewModel.dismissMilestone()
                    contentViewModel.dismissRewardEarnedCelebration()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: celebrationManager.activeCelebration != nil)
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
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: celebrationManager.currentSecondaryBanner != nil)
                .zIndex(99)
            }

            // Coach marks overlay - only shown when no active celebration
            if coachMarkManager.isShowingCoachMark && celebrationManager.activeCelebration == nil {
                CoachMarkOverlay(manager: coachMarkManager)
                    .animation(.easeInOut(duration: 0.3), value: coachMarkManager.isShowingCoachMark)
                    .zIndex(98)
            }
        }
        #if DEBUG
        .withThemeDebugPanel()
        #endif
        // PERFORMANCE: Animation modifiers removed from parent to prevent tab transition jitter
        // Animations are now applied directly to the celebration/coach mark views using withAnimation
        // Collect coach mark target rects from child views
        .onPreferenceChange(CoachMarkTargetPreferenceKey.self) { targets in
            for (target, rect) in targets {
                coachMarkManager.registerTarget(target, rect: rect)
            }
        }
        // PERFORMANCE: Removed .onChange handlers for celebrationStore
        // Now handled by ContentViewModel using Combine publishers
    }

    @State private var isOffline: Bool = false

    /// Main tab view using native SwiftUI TabView for optimal performance.
    ///
    /// PERFORMANCE: Native TabView has built-in view caching and lazy loading.
    /// The system TabView is hidden and replaced with custom FloatingTabBar.
    /// Animation is explicitly disabled on selection to prevent jittery transitions.
    private var mainTabView: some View {
        // PERFORMANCE: Use TabBarInsetProvider at root to set environment for all children
        // This fixes the tabBarInset warning and prevents layout recalculations on tab switch
        TabBarInsetProvider {
            ZStack(alignment: .bottom) {
                // Native TabView - hidden tab bar, keeps views cached
                // PERFORMANCE: Use transaction to disable implicit animations on tab switch
                TabView(selection: Binding(
                    get: { coordinator.selectedTab },
                    set: { newTab in
                        // Disable animation for instant tab switching
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            coordinator.selectedTab = newTab
                        }
                    }
                )) {
                    // Today Tab
                    TodayView(logBehaviorUseCase: logBehaviorUseCase)
                        .tag(AppCoordinator.Tab.today)
                        .toolbar(.hidden, for: .tabBar)

                    // Kids Tab
                    KidsView()
                        .tag(AppCoordinator.Tab.kids)
                        .toolbar(.hidden, for: .tabBar)

                    // Rewards Tab
                    RewardsView()
                        .tag(AppCoordinator.Tab.rewards)
                        .toolbar(.hidden, for: .tabBar)

                    // Insights Tab
                    InsightsHomeView()
                        .tag(AppCoordinator.Tab.insights)
                        .toolbar(.hidden, for: .tabBar)
                }
                .tabViewStyle(.automatic)
                .animation(.none, value: coordinator.selectedTab)

                // Offline banner overlay
                if isOffline {
                    VStack {
                        OfflineBanner()
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: isOffline)
                }

                // Custom floating tab bar (simplified - no longer needs to manage environment)
                VStack {
                    Spacer()
                    FloatingTabBar(selectedTab: $coordinator.selectedTab)
                }
            }
        }
        // PERFORMANCE: Animation removed from parent ZStack to prevent tab transition interference
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // PHASE 0: Set initial screen context BEFORE any NavigationStack renders
            // This ensures first stalls are never attributed to "unknown"
            #if DEBUG
            FrameStallMonitor.shared.setScreen("TodayView")
            #endif

            startNetworkMonitoring()
            checkForGoalPromptOnLaunch()
        }
        // PERFORMANCE: Visibility gate - notify ViewModels when their tab becomes visible/hidden
        // This defers heavy work (banners, focus generation, coaching) until after tab transition
        .onChange(of: coordinator.selectedTab) { oldTab, newTab in
            // Track tab navigation for stall attribution (DEBUG only)
            #if DEBUG
            FrameStallMonitor.shared.markTabSwitch(from: oldTab.rawValue, to: newTab.rawValue)
            #endif

            // Notify TodayViewModel of visibility change
            todayViewModel.setVisible(newTab == .today)

            // Notify KidsViewModel of visibility change
            kidsViewModel.setVisible(newTab == .kids)

            // Notify RewardsViewModel of visibility change
            rewardsViewModel.setVisible(newTab == .rewards)

            // Notify InsightsHomeViewModel of visibility change
            insightsHomeViewModel.setVisible(newTab == .insights)
        }
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

    // PERFORMANCE: flagGoalPromptForNextSession moved to ContentViewModel
    // It's now called via Combine observer, not view onChange

    /// Check for goal prompt on app launch (not during active logging)
    private func checkForGoalPromptOnLaunch() {
        // Only show if flagged from previous session
        guard UserDefaults.standard.bool(forKey: "pendingGoalPrompt") else { return }

        // Clear the flag
        UserDefaults.standard.set(false, forKey: "pendingGoalPrompt")

        // Delay to let UI settle after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Use ViewModel's goalPromptUseCase reference
            if let useCase = contentViewModel.goalPromptUseCase {
                let result = useCase.execute()
                if let child = result.childToPrompt {
                    coordinator.presentSheet(.goalPrompt(child: child))
                }
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

// MARK: - Lazy Tab Container

/// A container that lazily renders tab content and prevents hidden tabs from re-rendering.
///
/// PERFORMANCE: Unlike opacity-based hiding, this container:
/// - Only evaluates the body of the currently visible tab
/// - Keeps previously shown tabs in memory (via @State) but doesn't re-render them
/// - Prevents hidden tabs from observing @EnvironmentObject changes
private struct LazyTabContainer<Today: View, Kids: View, Rewards: View, Insights: View>: View {
    let selectedTab: AppCoordinator.Tab
    @ViewBuilder let todayContent: () -> Today
    @ViewBuilder let kidsContent: () -> Kids
    @ViewBuilder let rewardsContent: () -> Rewards
    @ViewBuilder let insightsContent: () -> Insights

    // Track which tabs have been shown (for persistence)
    @State private var hasShownToday = false
    @State private var hasShownKids = false
    @State private var hasShownRewards = false
    @State private var hasShownInsights = false

    var body: some View {
        ZStack {
            // Only render tabs that are currently selected OR have been shown before
            // Use .id() to give each tab a stable identity

            if selectedTab == .today || hasShownToday {
                todayContent()
                    .opacity(selectedTab == .today ? 1 : 0)
                    .allowsHitTesting(selectedTab == .today)
                    .onAppear { hasShownToday = true }
                    .id("today")
            }

            if selectedTab == .kids || hasShownKids {
                kidsContent()
                    .opacity(selectedTab == .kids ? 1 : 0)
                    .allowsHitTesting(selectedTab == .kids)
                    .onAppear { hasShownKids = true }
                    .id("kids")
            }

            if selectedTab == .rewards || hasShownRewards {
                rewardsContent()
                    .opacity(selectedTab == .rewards ? 1 : 0)
                    .allowsHitTesting(selectedTab == .rewards)
                    .onAppear { hasShownRewards = true }
                    .id("rewards")
            }

            if selectedTab == .insights || hasShownInsights {
                insightsContent()
                    .opacity(selectedTab == .insights ? 1 : 0)
                    .allowsHitTesting(selectedTab == .insights)
                    .onAppear { hasShownInsights = true }
                    .id("insights")
            }
        }
    }
}

// MARK: - Tab Bar with Safe Area

/// Floating tab bar that calculates its own safe area inset.
///
/// PERFORMANCE: Uses @State to cache the safe area value and prevent
/// GeometryReader from causing layout thrashing on every frame.
/// The safe area is only recalculated on appear and orientation changes.
private struct TabBarWithSafeArea: View {
    @Binding var selectedTab: AppCoordinator.Tab
    @State private var cachedSafeAreaBottom: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var computedTabBarInset: CGFloat {
        FloatingTabBarMetrics.totalFixedHeight + cachedSafeAreaBottom
    }

    var body: some View {
        VStack {
            Spacer()
            FloatingTabBar(selectedTab: $selectedTab)
        }
        .environment(\.tabBarInset, computedTabBarInset)
        .background(
            // Hidden GeometryReader that only updates cached value on meaningful changes
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        cachedSafeAreaBottom = geometry.safeAreaInsets.bottom
                    }
                    .onChange(of: horizontalSizeClass) { _, _ in
                        // Recalculate on orientation/size class change
                        cachedSafeAreaBottom = geometry.safeAreaInsets.bottom
                    }
            }
            .frame(height: 0)
        )
    }
}

// MARK: - Preview

#Preview {
    let dependencies = DependencyContainer()
    let coordinator = AppCoordinator()
    ContentView(
        logBehaviorUseCase: dependencies.logBehaviorUseCase
    )
        .environmentObject(dependencies.contentViewModel)
        .environmentObject(dependencies.childrenStore)
        .environmentObject(dependencies.rewardsStore)
        .environmentObject(dependencies.celebrationManager)
        .environmentObject(dependencies.coachMarkManager)
        .environmentObject(coordinator)
        // Additional environment objects needed by child views
        .environmentObject(dependencies.repository)
        .environmentObject(dependencies.behaviorsStore)
        .environmentObject(dependencies.insightsStore)
        .environmentObject(dependencies.progressionStore)
        .environmentObject(dependencies.agreementsStore)
        .environmentObject(dependencies.celebrationStore)
        .environmentObject(dependencies.userPreferences)
        .environmentObject(dependencies.todayViewModel)
        .environmentObject(dependencies.kidsViewModel)
        .environmentObject(dependencies.rewardsViewModel)
        .environmentObject(dependencies.subscriptionManager)
        .environmentObject(dependencies.notificationService)
        .environmentObject(dependencies.feedbackManager)
        .environmentObject(dependencies.featureFlags)
        .environmentObject(dependencies.themeProvider)
        .environmentObject(dependencies.insightsNavigationState)
        .environmentObject(dependencies.insightsHomeViewModel)
}

#Preview("Onboarding") {
    let dependencies = DependencyContainer()
    let coordinator = AppCoordinator()
    ContentView(
        logBehaviorUseCase: dependencies.logBehaviorUseCase
    )
        .environmentObject(dependencies.contentViewModel)
        .environmentObject(dependencies.childrenStore)
        .environmentObject(dependencies.rewardsStore)
        .environmentObject(dependencies.celebrationManager)
        .environmentObject(dependencies.coachMarkManager)
        .environmentObject(coordinator)
        .environmentObject(dependencies.repository)
        .environmentObject(dependencies.behaviorsStore)
        .environmentObject(dependencies.insightsStore)
        .environmentObject(dependencies.progressionStore)
        .environmentObject(dependencies.agreementsStore)
        .environmentObject(dependencies.celebrationStore)
        .environmentObject(dependencies.userPreferences)
        .environmentObject(dependencies.todayViewModel)
        .environmentObject(dependencies.kidsViewModel)
        .environmentObject(dependencies.rewardsViewModel)
        .environmentObject(dependencies.subscriptionManager)
        .environmentObject(dependencies.notificationService)
        .environmentObject(dependencies.feedbackManager)
        .environmentObject(dependencies.featureFlags)
        .environmentObject(dependencies.themeProvider)
        .environmentObject(dependencies.insightsNavigationState)
        .environmentObject(dependencies.insightsHomeViewModel)
}
