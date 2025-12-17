import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// MARK: - Analytics Tracker

/// Centralized analytics tracking for user behavior insights.
///
/// Uses Firebase Analytics when available, with privacy-conscious defaults:
/// - No PII (personally identifiable information) is ever logged
/// - Child names, emails, and IDs are never sent
/// - Only aggregate behavior patterns are tracked
/// - Disabled in DEBUG builds to avoid polluting data
///
/// Usage:
/// ```swift
/// AnalyticsTracker.shared.trackBehaviorLogged(category: .positive, points: 5)
/// AnalyticsTracker.shared.trackScreenView(screenName: "Today")
/// ```
@MainActor
final class AnalyticsTracker: ObservableObject {

    // MARK: - Singleton

    static let shared = AnalyticsTracker()

    // MARK: - Properties

    private var isEnabled: Bool = false
    private var hasSetUserProperties: Bool = false

    // MARK: - Initialization

    private init() {}

    /// Initialize analytics tracking.
    /// Call this after Firebase is configured.
    func initialize() {
        // Check user preference for analytics
        let userEnabled = UserDefaults.standard.object(forKey: "analyticsEnabled") as? Bool ?? true

        #if canImport(FirebaseAnalytics)
        #if DEBUG
        // Disable analytics in debug builds
        Analytics.setAnalyticsCollectionEnabled(false)
        isEnabled = false
        print("[Analytics] Disabled in DEBUG build")
        #else
        Analytics.setAnalyticsCollectionEnabled(userEnabled)
        isEnabled = userEnabled
        print("[Analytics] Firebase Analytics \(userEnabled ? "enabled" : "disabled") by user preference")
        #endif
        #else
        isEnabled = false
        print("[Analytics] Firebase Analytics SDK not available")
        #endif
    }

    /// Enable or disable analytics collection.
    /// Called when user changes the analytics preference in settings.
    func setEnabled(_ enabled: Bool) {
        #if canImport(FirebaseAnalytics)
        #if DEBUG
        // Always disabled in debug builds
        isEnabled = false
        print("[Analytics] Cannot enable in DEBUG build")
        #else
        Analytics.setAnalyticsCollectionEnabled(enabled)
        isEnabled = enabled
        print("[Analytics] Analytics \(enabled ? "enabled" : "disabled") by user")
        #endif
        #else
        isEnabled = false
        #endif
    }

    // MARK: - User Properties

    /// Set user properties for segmentation.
    /// Call this when subscription status or app state changes.
    func setUserProperties(
        subscriptionTier: String,
        childCount: Int,
        hasCompletedOnboarding: Bool,
        daysSinceInstall: Int
    ) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(subscriptionTier, forName: "subscription_tier")
        Analytics.setUserProperty(String(min(childCount, 5)), forName: "child_count") // Cap at 5 for privacy
        Analytics.setUserProperty(hasCompletedOnboarding ? "true" : "false", forName: "onboarding_complete")

        // Bucket days since install for privacy
        let daysBucket: String
        switch daysSinceInstall {
        case 0: daysBucket = "0_today"
        case 1...7: daysBucket = "1_first_week"
        case 8...30: daysBucket = "2_first_month"
        case 31...90: daysBucket = "3_first_quarter"
        default: daysBucket = "4_veteran"
        }
        Analytics.setUserProperty(daysBucket, forName: "user_tenure")

        hasSetUserProperties = true
        #endif
    }

    // MARK: - Screen Views

    /// Track screen view for navigation analysis.
    func trackScreenView(screenName: String, screenClass: String? = nil) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
        #endif
    }

    // MARK: - Behavior Events

    /// Track when a behavior is logged.
    func trackBehaviorLogged(category: BehaviorCategory, points: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("behavior_logged", parameters: [
            "category": category.rawValue,
            "points_bucket": pointsBucket(points),
            "is_positive": points >= 0
        ])
        #endif
    }

    /// Track behavior deletion.
    func trackBehaviorDeleted() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("behavior_deleted", parameters: nil)
        #endif
    }

    // MARK: - Child Events

    /// Track when a child is added.
    func trackChildAdded(hasAge: Bool, hasBirthday: Bool) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("child_added", parameters: [
            "has_age": hasAge,
            "has_birthday": hasBirthday
        ])
        #endif
    }

    /// Track when a child is removed.
    func trackChildRemoved() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("child_removed", parameters: nil)
        #endif
    }

    // MARK: - Reward/Goal Events

    /// Track when a reward/goal is created.
    func trackRewardCreated(pointsRequired: Int, isFromTemplate: Bool) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("reward_created", parameters: [
            "points_bucket": pointsBucket(pointsRequired),
            "from_template": isFromTemplate
        ])
        #endif
    }

    /// Track when a goal is completed (reward redeemed).
    func trackGoalCompleted(pointsRequired: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("goal_completed", parameters: [
            "points_bucket": pointsBucket(pointsRequired)
        ])
        #endif
    }

    /// Track when goal prompt is shown.
    func trackGoalPromptShown() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("goal_prompt_shown", parameters: nil)
        #endif
    }

    /// Track goal prompt response.
    func trackGoalPromptResponse(accepted: Bool) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("goal_prompt_response", parameters: [
            "accepted": accepted
        ])
        #endif
    }

    // MARK: - Subscription Events

    /// Track paywall view.
    func trackPaywallViewed(source: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("paywall_viewed", parameters: [
            "source": source
        ])
        #endif
    }

    /// Track subscription started.
    func trackSubscriptionStarted(productId: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterItemCategory: "subscription"
        ])
        #endif
    }

    /// Track subscription cancelled.
    func trackSubscriptionCancelled() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_cancelled", parameters: nil)
        #endif
    }

    /// Track subscription restored.
    func trackSubscriptionRestored(productId: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_restored", parameters: [
            AnalyticsParameterItemID: productId
        ])
        #endif
    }

    // MARK: - Auth Events

    /// Track sign-in attempt.
    func trackSignInAttempt(method: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("sign_in_attempt", parameters: [
            "method": method
        ])
        #endif
    }

    /// Track sign-in success.
    func trackSignInSuccess(method: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
        #endif
    }

    /// Track sign-in failure.
    func trackSignInFailure(method: String, errorCode: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("sign_in_failure", parameters: [
            "method": method,
            "error_code": errorCode
        ])
        #endif
    }

    /// Track sign-out.
    func trackSignOut() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("sign_out", parameters: nil)
        #endif
    }

    // MARK: - Co-Parent Events

    /// Track invite code generated.
    func trackInviteCodeGenerated() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("invite_code_generated", parameters: nil)
        #endif
    }

    /// Track invite code shared.
    func trackInviteCodeShared(method: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterMethod: method,
            AnalyticsParameterContentType: "invite_code"
        ])
        #endif
    }

    /// Track family joined.
    func trackFamilyJoined(viaDeepLink: Bool) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("family_joined", parameters: [
            "via_deep_link": viaDeepLink
        ])
        #endif
    }

    // MARK: - Onboarding Events

    /// Track onboarding step completed.
    func trackOnboardingStep(step: Int, stepName: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("onboarding_step", parameters: [
            "step_number": step,
            "step_name": stepName
        ])
        #endif
    }

    /// Track onboarding completed.
    func trackOnboardingCompleted() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventTutorialComplete, parameters: nil)
        #endif
    }

    /// Track onboarding skipped.
    func trackOnboardingSkipped(atStep: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("onboarding_skipped", parameters: [
            "at_step": atStep
        ])
        #endif
    }

    // MARK: - Feature Usage

    /// Track kid mode entered.
    func trackKidModeEntered() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("kid_mode_entered", parameters: nil)
        #endif
    }

    /// Track kid mode exited.
    func trackKidModeExited(durationSeconds: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        // Bucket duration for privacy
        let durationBucket: String
        switch durationSeconds {
        case 0..<30: durationBucket = "under_30s"
        case 30..<120: durationBucket = "30s_2m"
        case 120..<300: durationBucket = "2m_5m"
        case 300..<600: durationBucket = "5m_10m"
        default: durationBucket = "over_10m"
        }

        Analytics.logEvent("kid_mode_exited", parameters: [
            "duration_bucket": durationBucket
        ])
        #endif
    }

    /// Track insights tab viewed.
    func trackInsightsViewed() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("insights_viewed", parameters: nil)
        #endif
    }

    /// Track settings accessed.
    func trackSettingsAccessed(section: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("settings_accessed", parameters: [
            "section": section
        ])
        #endif
    }

    /// Track theme changed.
    func trackThemeChanged(theme: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("theme_changed", parameters: [
            "theme": theme
        ])
        #endif
    }

    /// Track celebration shown.
    func trackCelebrationShown(type: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("celebration_shown", parameters: [
            "type": type
        ])
        #endif
    }

    // MARK: - Engagement Metrics

    /// Track daily active user.
    func trackDailyActive() {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        // Firebase auto-tracks DAU, but we add a custom event for more control
        Analytics.logEvent("daily_active", parameters: nil)
        #endif
    }

    /// Track app session start with context.
    func trackSessionStart(behaviorsLoggedToday: Int, childCount: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            "behaviors_today_bucket": behaviorCountBucket(behaviorsLoggedToday),
            "child_count": min(childCount, 5)
        ])
        #endif
    }

    // MARK: - Error Tracking

    /// Track non-fatal error for analytics (separate from Crashlytics).
    func trackError(domain: String, code: Int) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("app_error", parameters: [
            "error_domain": domain,
            "error_code": code
        ])
        #endif
    }

    // MARK: - Helpers

    /// Convert points to privacy-safe bucket.
    private func pointsBucket(_ points: Int) -> String {
        let absPoints = abs(points)
        switch absPoints {
        case 0: return "0"
        case 1...5: return "1_5"
        case 6...10: return "6_10"
        case 11...20: return "11_20"
        case 21...50: return "21_50"
        default: return "50_plus"
        }
    }

    /// Convert behavior count to privacy-safe bucket.
    private func behaviorCountBucket(_ count: Int) -> String {
        switch count {
        case 0: return "0"
        case 1...3: return "1_3"
        case 4...10: return "4_10"
        case 11...20: return "11_20"
        default: return "20_plus"
        }
    }
}

// MARK: - Convenience Extensions

extension AnalyticsTracker {
    /// Track a generic custom event.
    /// Use sparingly - prefer typed methods above.
    func trackCustomEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #endif
    }
}
