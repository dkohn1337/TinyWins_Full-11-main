import Foundation
import SwiftUI
import Combine

/// Central navigation coordinator for the TinyWins app.
/// Manages tab selection, sheets, and full-screen covers.
/// Preserves exact navigation behavior from the original implementation.
@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Tab Management

    /// M1 DOCUMENTATION: The app intentionally defaults to Today tab on every launch.
    /// This is by design for the following reasons:
    /// 1. User intent: Overwhelmed parents want to see "what's happening now"
    /// 2. Category norms: Habit/wellness apps (Headspace, Calm) land on daily view
    /// 3. Retention loop: Seeing today's progress reinforces the "small wins" promise
    /// 4. Insights is a destination for reflection, not the daily starting point
    /// Tab state is NOT persisted across sessions - this is intentional.
    @Published var selectedTab: Tab = .today

    // MARK: - Insights Navigation State

    /// Navigation state for the Insights tab.
    /// Owned by AppCoordinator to ensure stable lifecycle across view recreations.
    /// Access via coordinator.insightsNavigation in child views.
    let insightsNavigation = InsightsNavigationState()

    // MARK: - Shared Child Selection (synced across tabs)

    /// The currently selected child ID, shared across Insights, Goals, and other child-specific views
    @Published var selectedChildId: UUID?

    /// Sets the selected child and persists to UserDefaults
    func selectChild(_ childId: UUID?) {
        selectedChildId = childId
        if let id = childId {
            UserDefaults.standard.set(id.uuidString, forKey: "selectedChildId")
        }
    }

    /// Loads the persisted child selection on app launch
    func loadPersistedChildSelection() {
        if let idString = UserDefaults.standard.string(forKey: "selectedChildId"),
           let id = UUID(uuidString: idString) {
            selectedChildId = id
        }
    }

    // MARK: - Network Status

    /// Whether the app is currently offline
    @Published var isOffline: Bool = false

    // MARK: - Tab Enum

    enum Tab: String, CaseIterable, Hashable {
        case today
        case kids
        case rewards
        case insights

        var title: String {
            switch self {
            case .today: return "Today"
            case .kids: return "Kids"
            case .rewards: return "Goals"
            case .insights: return "Insights"
            }
        }

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .kids: return "figure.2.and.child.holdinghands"
            case .rewards: return "gift.fill"
            case .insights: return "lightbulb.fill"
            }
        }

        var gradient: [Color] {
            switch self {
            case .today: return [.orange, .yellow]
            case .kids: return [.blue, .cyan]
            case .rewards: return [.purple, .pink]
            case .insights: return [.green, .mint]
            }
        }
    }

    // MARK: - Sheet Navigation

    /// Represents sheets that can be presented
    enum Sheet: Identifiable {
        case logBehavior(child: Child)
        case addChild
        case editChild(Child)
        case addReward(child: Child)
        case editReward(reward: Reward, child: Child)
        case rewardTemplatePicker(child: Child)
        case behaviorManagement
        case feedback
        case settings
        // backupSettings removed - iCloud backup feature deprecated
        case notificationSettings
        case appearanceSettings
        case agreementView(child: Child)
        case editMoment(event: BehaviorEvent)
        case allowanceView
        case paywall
        case goalPrompt(child: Child)

        var id: String {
            switch self {
            case .logBehavior(let child): return "logBehavior-\(child.id)"
            case .addChild: return "addChild"
            case .editChild(let child): return "editChild-\(child.id)"
            case .addReward(let child): return "addReward-\(child.id)"
            case .editReward(let reward, _): return "editReward-\(reward.id)"
            case .rewardTemplatePicker(let child): return "rewardTemplate-\(child.id)"
            case .behaviorManagement: return "behaviorManagement"
            case .feedback: return "feedback"
            case .settings: return "settings"
            // backupSettings removed
            case .notificationSettings: return "notificationSettings"
            case .appearanceSettings: return "appearanceSettings"
            case .agreementView(let child): return "agreement-\(child.id)"
            case .editMoment(let event): return "editMoment-\(event.id)"
            case .allowanceView: return "allowance"
            case .paywall: return "paywall"
            case .goalPrompt(let child): return "goalPrompt-\(child.id)"
            }
        }
    }

    @Published var presentedSheet: Sheet?

    // MARK: - Full Screen Cover Navigation

    /// Represents full-screen covers that can be presented
    enum FullScreenCover: Identifiable {
        case onboarding
        case kidView(child: Child, reward: Reward?)
        case kidGoalSelection(child: Child)
        case goalPrompt(child: Child)

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .kidView(let child, _): return "kidView-\(child.id)"
            case .kidGoalSelection(let child): return "kidGoalSelection-\(child.id)"
            case .goalPrompt(let child): return "goalPrompt-\(child.id)"
            }
        }
    }

    @Published var presentedFullScreenCover: FullScreenCover?

    // MARK: - Deep Link State

    /// Pending invite code from deep link (tinywins://join?code=ABC123)
    @Published var pendingInviteCode: String?

    /// Whether to show join family flow (triggered by deep link)
    @Published var shouldShowJoinFamily: Bool = false

    // MARK: - Pending Goal Celebration

    /// Pending goal celebration to be shown on Goals tab (triggered from Kids tab badge)
    @Published var pendingGoalCelebration: (reward: Reward, child: Child)?

    /// Triggers goal celebration and navigates to Goals tab
    func triggerGoalCelebration(reward: Reward, child: Child) {
        pendingGoalCelebration = (reward, child)
        selectChild(child.id)
        selectedTab = .rewards
    }

    /// Clears pending celebration after it's been shown
    func clearPendingGoalCelebration() {
        pendingGoalCelebration = nil
    }

    // MARK: - Navigation Actions

    func presentSheet(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func presentFullScreenCover(_ cover: FullScreenCover) {
        presentedFullScreenCover = cover
    }

    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }

    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }

    // MARK: - Convenience Navigation Methods

    func showLogBehavior(for child: Child) {
        presentSheet(.logBehavior(child: child))
    }

    func showAddChild() {
        presentSheet(.addChild)
    }

    func showEditChild(_ child: Child) {
        presentSheet(.editChild(child))
    }

    func showAddReward(for child: Child) {
        presentSheet(.addReward(child: child))
    }

    func showKidView(for child: Child, reward: Reward? = nil) {
        presentFullScreenCover(.kidView(child: child, reward: reward))
    }

    func showPaywall() {
        presentSheet(.paywall)
    }

    func showBehaviorManagement() {
        presentSheet(.behaviorManagement)
    }

    func showSettings() {
        presentSheet(.settings)
    }

    func showOnboarding() {
        presentFullScreenCover(.onboarding)
    }

    func showKidGoalSelection(for child: Child) {
        presentFullScreenCover(.kidGoalSelection(child: child))
    }

    func showGoalPrompt(for child: Child) {
        presentFullScreenCover(.goalPrompt(child: child))
    }

    // MARK: - Deep Link Handling

    func handleDeepLink(_ url: URL) {
        // Parse invite codes from deep links
        if let code = InviteService.parseInviteCode(from: url) {
            pendingInviteCode = code
            shouldShowJoinFamily = true
        }
    }

    /// Clear the pending invite code after it's been used
    func clearPendingInviteCode() {
        pendingInviteCode = nil
        shouldShowJoinFamily = false
    }
}
