import Foundation
import SwiftUI
import StoreKit
import UserNotifications

// MARK: - Service Protocols for Dependency Injection
// These protocols enable testability and remove singleton coupling

// MARK: - Subscription Service Protocol

/// Protocol for subscription management operations
@MainActor
protocol SubscriptionServiceProtocol: ObservableObject {
    var isPlusSubscriber: Bool { get }
    var products: [Product] { get }
    var purchasedProductIds: Set<String> { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var monthlyProduct: Product? { get }
    var yearlyProduct: Product? { get }
    var effectiveIsPlusSubscriber: Bool { get }

    func canUsePremiumFeature(_ feature: PremiumFeature) -> Bool
    func canAddChild(currentCount: Int) -> Bool
    func canAddActiveGoal(currentActiveCount: Int) -> Bool
    func maxInsightsDays() -> Int
    func maxHistoryDays() -> Int
    func loadProducts() async
    func purchase(_ product: Product) async throws -> Bool
    func restorePurchases() async
}

// MARK: - Notification Service Protocol

/// Protocol for notification management operations
protocol NotificationServiceProtocol: ObservableObject {
    var isAuthorized: Bool { get }
    var authorizationStatus: UNAuthorizationStatus { get }
    var hasRequestedPermission: Bool { get set }
    var dailyReminderEnabled: Bool { get set }
    var dailyReminderHour: Int { get set }
    var dailyReminderMinute: Int { get set }
    var gentleReminderEnabled: Bool { get set }
    var dailyReminderTime: Date { get set }

    func checkAuthorizationStatus()
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func scheduleDailyReminder()
    func cancelDailyReminder()
    func scheduleGentleReminderIfInactive(daysSinceLastActivity: Int?)
    func cancelGentleReminder()
}

// MARK: - Feature Flags Protocol

/// Protocol for feature flag access
@MainActor
protocol FeatureFlagsProtocol: ObservableObject {
    #if DEBUG
    var debugUnlockPlus: Bool { get set }
    var showDebugInfo: Bool { get set }
    #endif
    var isDebugPlusEnabled: Bool { get }
}

// MARK: - Analytics Service Protocol

/// Protocol for analytics operations
protocol AnalyticsServiceProtocol {
    func log(_ event: AnalyticsService.AnalyticsEvent)
}

// MARK: - Haptic Service Protocol

/// Protocol for haptic feedback operations
protocol HapticServiceProtocol {
    func prepare()
    func light()
    func medium()
    func heavy()
    func success()
    func warning()
    func error()
    func selection()
}

// MARK: - Feedback Manager Protocol

/// Protocol for feedback prompt management
protocol FeedbackManagerProtocol: ObservableObject {
    var shouldShowPrompt: Bool { get }
    func checkPromptEligibility(totalMomentsLogged: Int)
    func markPromptShown()
}

// MARK: - Protocol Conformance Extensions

// SubscriptionManager already conforms, just declare it
extension SubscriptionManager: SubscriptionServiceProtocol {}

// NotificationService already conforms, just declare it
extension NotificationService: NotificationServiceProtocol {}

// FeatureFlags already conforms, just declare it
extension FeatureFlags: FeatureFlagsProtocol {}

// AnalyticsService conformance
extension AnalyticsService: AnalyticsServiceProtocol {}

// HapticService conformance
extension HapticService: HapticServiceProtocol {}

// FeedbackManager already conforms, just declare it
extension FeedbackManager: FeedbackManagerProtocol {}
