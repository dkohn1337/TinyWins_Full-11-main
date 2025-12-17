import SwiftUI

/// Centralized store for all user preferences and @AppStorage values.
/// This replaces scattered @AppStorage declarations across views.
@MainActor
final class UserPreferencesStore: ObservableObject {

    // MARK: - Onboarding & First-Time Experience

    @AppStorage("hasCompletedOnboarding")
    var hasCompletedOnboarding: Bool = false

    @AppStorage("onboardingCompletedDate")
    private var onboardingCompletedDateString: String = ""

    var onboardingCompletedDate: Date? {
        get {
            guard !onboardingCompletedDateString.isEmpty else { return nil }
            return Self.dateFormatter.date(from: onboardingCompletedDateString)
        }
        set {
            if let date = newValue {
                onboardingCompletedDateString = Self.dateFormatter.string(from: date)
            } else {
                onboardingCompletedDateString = ""
            }
        }
    }

    // MARK: - Coach Marks & Tooltips

    @AppStorage("hasSeenTodayCoachMarks")
    var hasSeenTodayCoachMarks: Bool = false

    @AppStorage("first48Day1Shown")
    var first48Day1Shown: Bool = false

    @AppStorage("first48Day2Shown")
    var first48Day2Shown: Bool = false

    @AppStorage("hasSeenGoalTooltip")
    var hasSeenGoalTooltip: Bool = false

    @AppStorage("hasSeenGoalInterception")
    var hasSeenGoalInterception: Bool = false

    @AppStorage("hasSeenSecondChildCoachMark")
    var hasSeenSecondChildCoachMark: Bool = false

    // MARK: - Coach Mark Sequences (Post-Onboarding)

    @AppStorage("coachMarks.today.completed")
    var hasCompletedTodayCoachMarks: Bool = false

    @AppStorage("coachMarks.kids.completed")
    var hasCompletedKidsCoachMarks: Bool = false

    @AppStorage("coachMarks.goals.completed")
    var hasCompletedGoalsCoachMarks: Bool = false

    @AppStorage("coachMarks.insights.completed")
    var hasCompletedInsightsCoachMarks: Bool = false

    @AppStorage("coachMarks.skippedAll")
    var hasSkippedAllCoachMarks: Bool = false

    // MARK: - Banner Tracking

    @AppStorage("lastFirstPositiveBannerDate")
    private var lastFirstPositiveBannerDateString: String = ""

    @AppStorage("lastWeeklyRecapDate")
    private var lastWeeklyRecapDateString: String = ""

    @AppStorage("lastConsistencyBannerDate")
    private var lastConsistencyBannerDateString: String = ""

    @AppStorage("lastReturnBannerDate")
    private var lastReturnBannerDateString: String = ""

    var lastFirstPositiveBannerDate: Date? {
        get { Self.dateFormatter.date(from: lastFirstPositiveBannerDateString) }
        set { lastFirstPositiveBannerDateString = newValue.map { Self.dateFormatter.string(from: $0) } ?? "" }
    }

    var lastWeeklyRecapDate: Date? {
        get { Self.dateFormatter.date(from: lastWeeklyRecapDateString) }
        set { lastWeeklyRecapDateString = newValue.map { Self.dateFormatter.string(from: $0) } ?? "" }
    }

    var lastConsistencyBannerDate: Date? {
        get { Self.dateFormatter.date(from: lastConsistencyBannerDateString) }
        set { lastConsistencyBannerDateString = newValue.map { Self.dateFormatter.string(from: $0) } ?? "" }
    }

    var lastReturnBannerDate: Date? {
        get { Self.dateFormatter.date(from: lastReturnBannerDateString) }
        set { lastReturnBannerDateString = newValue.map { Self.dateFormatter.string(from: $0) } ?? "" }
    }

    // MARK: - Appearance

    @AppStorage("appTheme")
    var appTheme: AppTheme = .system

    @AppStorage("accentColorName")
    var accentColorName: String = "blue"

    // MARK: - Privacy & Analytics

    @AppStorage("analyticsEnabled")
    private var _analyticsEnabled: Bool = true

    /// Whether analytics collection is enabled.
    /// When changed, updates AnalyticsTracker state.
    var analyticsEnabled: Bool {
        get { _analyticsEnabled }
        set {
            _analyticsEnabled = newValue
            // Update AnalyticsTracker state
            Task { @MainActor in
                AnalyticsTracker.shared.setEnabled(newValue)
            }
        }
    }

    // MARK: - Selection State

    @AppStorage("selectedRewardsChildId")
    var selectedRewardsChildId: String = ""

    // MARK: - Debug

    #if DEBUG
    @AppStorage("debug.unlockPlus")
    var debugUnlockPlus: Bool = false

    @AppStorage("debug.showDebugInfo")
    var showDebugInfo: Bool = false

    @AppStorage("debug.showPartnerAttribution")
    var showPartnerAttribution: Bool = false

    @AppStorage("debug.showDemoPaywall")
    var showDemoPaywall: Bool = false

    /// When true, enables Firebase sync features (cloud sync, Apple Sign-In, co-parent sync).
    /// When false, app operates in local-only mode.
    /// This overrides AppConfiguration.backendMode at runtime for testing.
    @AppStorage("debug.firebaseSyncEnabled")
    var firebaseSyncEnabled: Bool = true
    #endif

    // MARK: - Partner Features

    /// Whether to show "Logged by [Parent]" attribution on behavior events.
    /// Requires co-parent sync to be enabled and Plus subscription.
    @AppStorage("partnerAttributionEnabled")
    var partnerAttributionEnabled: Bool = true

    // MARK: - Per-Child Settings

    /// Gets the per-child theme for Kid View
    /// Note: This uses dynamic keys based on child ID, so we provide a method instead of a property
    func kidViewTheme(forChildId childId: UUID) -> String {
        UserDefaults.standard.string(forKey: "kidViewTheme_\(childId.uuidString)") ?? KidViewTheme.classic.rawValue
    }

    func setKidViewTheme(_ theme: String, forChildId childId: UUID) {
        UserDefaults.standard.set(theme, forKey: "kidViewTheme_\(childId.uuidString)")
        objectWillChange.send()
    }

    /// Gets the per-child goal tooltip state
    func hasSeenGoalTooltip(forChildId childId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: "hasSeenGoalTooltip_\(childId.uuidString)")
    }

    func setHasSeenGoalTooltip(_ seen: Bool, forChildId childId: UUID) {
        UserDefaults.standard.set(seen, forKey: "hasSeenGoalTooltip_\(childId.uuidString)")
        objectWillChange.send()
    }

    /// Gets the per-child goal interception state
    func hasSeenGoalInterception(forChildId childId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: "hasSeenGoalInterception_\(childId.uuidString)")
    }

    func setHasSeenGoalInterception(_ seen: Bool, forChildId childId: UUID) {
        UserDefaults.standard.set(seen, forKey: "hasSeenGoalInterception_\(childId.uuidString)")
        objectWillChange.send()
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    // MARK: - Premium Theme Validation

    /// Validates that user's selected theme is accessible based on subscription.
    /// Call this on app launch and when subscription status changes.
    /// If user has a premium theme but no subscription, reset to default free theme.
    func validateThemeAccess(isPlusSubscriber: Bool) {
        // Reset premium theme to system if user loses subscription
        if !isPlusSubscriber && appTheme.isPremium {
            appTheme = .system
        }

        // Reset premium accent colors
        let premiumColorNames = ExtendedColorTag.premiumColors.map { $0.rawValue }
        if !isPlusSubscriber && premiumColorNames.contains(accentColorName) {
            accentColorName = "blue"
        }
    }

    // MARK: - Reset Methods

    func resetAllCoachMarks() {
        hasSeenTodayCoachMarks = false
        first48Day1Shown = false
        first48Day2Shown = false
        hasSeenGoalTooltip = false
        hasSeenGoalInterception = false
        hasSeenSecondChildCoachMark = false
        // Reset post-onboarding coach mark sequences
        hasCompletedTodayCoachMarks = false
        hasCompletedKidsCoachMarks = false
        hasCompletedGoalsCoachMarks = false
        hasCompletedInsightsCoachMarks = false
        hasSkippedAllCoachMarks = false
    }

    func resetAllBannerDates() {
        lastFirstPositiveBannerDateString = ""
        lastWeeklyRecapDateString = ""
        lastConsistencyBannerDateString = ""
        lastReturnBannerDateString = ""
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        onboardingCompletedDateString = ""
        resetAllCoachMarks()
    }
}
