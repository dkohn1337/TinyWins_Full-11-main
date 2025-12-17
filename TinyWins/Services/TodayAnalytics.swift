import Foundation

// MARK: - TodayAnalytics

/// Analytics events for the Today tab experience.
/// Tracks the habit loop: open → select child → add moment → reward.
enum TodayAnalytics {

    // MARK: - Event Definitions

    /// Tracks when the Today tab is opened
    struct TodayOpened: AnalyticsEvent {
        static let name = "today_opened"

        let childCount: Int
        let hasActivityToday: Bool
        let selectedChildIndex: Int?
        let timestamp: Date

        var parameters: [String: Any] {
            var params: [String: Any] = [
                "child_count": childCount,
                "has_activity_today": hasActivityToday,
                "timestamp": timestamp.timeIntervalSince1970
            ]
            if let index = selectedChildIndex {
                params["selected_child_index"] = index
            }
            return params
        }
    }

    /// Tracks when the Today tab is backgrounded or user leaves
    struct TodayBackgrounded: AnalyticsEvent {
        static let name = "today_backgrounded"

        let scrollDepthPercent: Double
        let timeOnScreenMs: Int
        let didLogMoment: Bool

        var parameters: [String: Any] {
            [
                "scroll_depth_percent": scrollDepthPercent,
                "time_on_screen_ms": timeOnScreenMs,
                "did_log_moment": didLogMoment
            ]
        }
    }

    /// Tracks when a child is selected in the picker
    struct ChildSelected: AnalyticsEvent {
        static let name = "child_selected"

        let childIndex: Int
        let previousIndex: Int?
        let wasScrollRequired: Bool
        let source: String // "tap", "auto_select", "external"

        var parameters: [String: Any] {
            var params: [String: Any] = [
                "child_index": childIndex,
                "was_scroll_required": wasScrollRequired,
                "source": source
            ]
            if let prev = previousIndex {
                params["previous_index"] = prev
            }
            return params
        }
    }

    /// Tracks when the child picker is scrolled
    struct ChildPickerScrolled: AnalyticsEvent {
        static let name = "child_picker_scrolled"

        let direction: String // "left", "right"
        let childCount: Int

        var parameters: [String: Any] {
            [
                "direction": direction,
                "child_count": childCount
            ]
        }
    }

    /// Tracks when the Add Moment button is tapped
    struct AddMomentTapped: AnalyticsEvent {
        static let name = "add_moment_tapped"

        let source: String // "primary_button", "child_avatar", "latest_card"
        let selectedChildIndex: Int
        let hasActiveGoal: Bool
        let timeFromOpenMs: Int

        var parameters: [String: Any] {
            [
                "source": source,
                "selected_child_index": selectedChildIndex,
                "has_active_goal": hasActiveGoal,
                "time_from_open_ms": timeFromOpenMs
            ]
        }
    }

    /// Tracks when a moment is successfully logged
    struct MomentLogged: AnalyticsEvent {
        static let name = "moment_logged"

        let childIndex: Int
        let hasGoal: Bool
        let stars: Int
        let isPositive: Bool
        let durationFromOpenMs: Int
        let durationFromTapMs: Int

        var parameters: [String: Any] {
            [
                "child_index": childIndex,
                "has_goal": hasGoal,
                "stars": stars,
                "is_positive": isPositive,
                "duration_from_open_ms": durationFromOpenMs,
                "duration_from_tap_ms": durationFromTapMs
            ]
        }
    }

    /// Tracks when the Latest Today card is tapped
    struct LatestTodayTapped: AnalyticsEvent {
        static let name = "latest_today_tapped"

        let momentCount: Int

        var parameters: [String: Any] {
            ["moment_count": momentCount]
        }
    }

    /// Tracks when a collapsible row is expanded
    struct RowExpanded: AnalyticsEvent {
        static let name = "row_expanded"

        let rowType: String // "streak", "focus", "reflection"

        var parameters: [String: Any] {
            ["row_type": rowType]
        }
    }

    /// Tracks when a collapsible row is collapsed
    struct RowCollapsed: AnalyticsEvent {
        static let name = "row_collapsed"

        let rowType: String
        let timeExpandedMs: Int

        var parameters: [String: Any] {
            [
                "row_type": rowType,
                "time_expanded_ms": timeExpandedMs
            ]
        }
    }

    /// Tracks when a dismissable row is dismissed
    struct RowDismissed: AnalyticsEvent {
        static let name = "row_dismissed"

        let rowType: String

        var parameters: [String: Any] {
            ["row_type": rowType]
        }
    }

    /// Tracks when the reflection flow is opened
    struct ReflectionOpened: AnalyticsEvent {
        static let name = "reflection_opened"

        let trigger: String // "row_tap", "evening_prompt", "reminder"

        var parameters: [String: Any] {
            ["trigger": trigger]
        }
    }

    /// Tracks when reflection is completed
    struct ReflectionCompleted: AnalyticsEvent {
        static let name = "reflection_completed"

        let selectionsCount: Int
        let hasNote: Bool
        let timeOpenMs: Int

        var parameters: [String: Any] {
            [
                "selections_count": selectionsCount,
                "has_note": hasNote,
                "time_open_ms": timeOpenMs
            ]
        }
    }

    /// Tracks when reflection is dismissed without completing
    struct ReflectionDismissed: AnalyticsEvent {
        static let name = "reflection_dismissed"

        let timeOpenMs: Int
        let hadSelections: Bool

        var parameters: [String: Any] {
            [
                "time_open_ms": timeOpenMs,
                "had_selections": hadSelections
            ]
        }
    }
}

// MARK: - Analytics Event Protocol

/// Protocol for analytics events to ensure consistent structure.
protocol AnalyticsEvent {
    static var name: String { get }
    var parameters: [String: Any] { get }
}

// MARK: - Analytics Tracker

/// Simple analytics tracker that can be replaced with actual implementation.
/// Currently logs to console in DEBUG builds.
final class TodayAnalyticsTracker {
    static let shared = TodayAnalyticsTracker()

    private var todayOpenedTimestamp: Date?
    private var addMomentTappedTimestamp: Date?

    private init() {}

    // MARK: - Session Tracking

    func trackTodayOpened(childCount: Int, hasActivityToday: Bool, selectedChildIndex: Int?) {
        todayOpenedTimestamp = Date()

        let event = TodayAnalytics.TodayOpened(
            childCount: childCount,
            hasActivityToday: hasActivityToday,
            selectedChildIndex: selectedChildIndex,
            timestamp: Date()
        )
        log(event)
    }

    func trackTodayBackgrounded(scrollDepthPercent: Double, didLogMoment: Bool) {
        let timeOnScreen = todayOpenedTimestamp.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0

        let event = TodayAnalytics.TodayBackgrounded(
            scrollDepthPercent: scrollDepthPercent,
            timeOnScreenMs: timeOnScreen,
            didLogMoment: didLogMoment
        )
        log(event)
    }

    // MARK: - Child Selection

    func trackChildSelected(childIndex: Int, previousIndex: Int?, wasScrollRequired: Bool, source: String) {
        let event = TodayAnalytics.ChildSelected(
            childIndex: childIndex,
            previousIndex: previousIndex,
            wasScrollRequired: wasScrollRequired,
            source: source
        )
        log(event)
    }

    // MARK: - Add Moment Flow

    func trackAddMomentTapped(source: String, selectedChildIndex: Int, hasActiveGoal: Bool) {
        addMomentTappedTimestamp = Date()
        let timeFromOpen = todayOpenedTimestamp.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0

        let event = TodayAnalytics.AddMomentTapped(
            source: source,
            selectedChildIndex: selectedChildIndex,
            hasActiveGoal: hasActiveGoal,
            timeFromOpenMs: timeFromOpen
        )
        log(event)
    }

    func trackMomentLogged(childIndex: Int, hasGoal: Bool, stars: Int, isPositive: Bool) {
        let durationFromOpen = todayOpenedTimestamp.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0
        let durationFromTap = addMomentTappedTimestamp.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0

        let event = TodayAnalytics.MomentLogged(
            childIndex: childIndex,
            hasGoal: hasGoal,
            stars: stars,
            isPositive: isPositive,
            durationFromOpenMs: durationFromOpen,
            durationFromTapMs: durationFromTap
        )
        log(event)
    }

    // MARK: - Row Interactions

    func trackRowExpanded(rowType: String) {
        let event = TodayAnalytics.RowExpanded(rowType: rowType)
        log(event)
    }

    func trackRowCollapsed(rowType: String, timeExpandedMs: Int) {
        let event = TodayAnalytics.RowCollapsed(rowType: rowType, timeExpandedMs: timeExpandedMs)
        log(event)
    }

    func trackRowDismissed(rowType: String) {
        let event = TodayAnalytics.RowDismissed(rowType: rowType)
        log(event)
    }

    // MARK: - Reflection

    func trackReflectionOpened(trigger: String) {
        let event = TodayAnalytics.ReflectionOpened(trigger: trigger)
        log(event)
    }

    func trackReflectionCompleted(selectionsCount: Int, hasNote: Bool, timeOpenMs: Int) {
        let event = TodayAnalytics.ReflectionCompleted(
            selectionsCount: selectionsCount,
            hasNote: hasNote,
            timeOpenMs: timeOpenMs
        )
        log(event)
    }

    // MARK: - Logging

    private func log<T: AnalyticsEvent>(_ event: T) {
        #if DEBUG
        print("[Analytics] \(T.name): \(event.parameters)")
        #endif

        // TODO: Replace with actual analytics provider (Firebase, Amplitude, etc.)
        // AnalyticsProvider.shared.track(T.name, parameters: event.parameters)
    }
}
