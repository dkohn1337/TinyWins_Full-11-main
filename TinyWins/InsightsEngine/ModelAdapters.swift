import Foundation

// MARK: - Static Date Formatters

/// Static date formatters to avoid repeated allocation.
/// DateFormatter creation is expensive (~50μs per instance).
/// These are lazily initialized once and reused throughout the app.
enum DateFormatters {

    // MARK: - Standard Formatters

    /// Short date format (e.g., "12/25/24")
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Year-month-day format (e.g., "2024-12-25")
    static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Medium date format (e.g., "Dec 25, 2024")
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Time only format (e.g., "3:30 PM")
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Relative date formatter (e.g., "2 days ago")
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Week Calculation

    /// Year-week format for week comparisons (e.g., "2024-52")
    static func yearWeekString(from date: Date) -> String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.year, from: date)
        return "\(year)-\(weekOfYear)"
    }

    /// Today's date string in yyyy-MM-dd format (cached for current day)
    static var todayString: String {
        yearMonthDay.string(from: Date())
    }
}

// MARK: - Model Adapters

/// Adapters to convert existing TinyWins models to canonical representations.
/// These adapters do not modify the underlying storage.

enum ModelAdapters {

    // MARK: - Event Adapter

    /// Convert BehaviorEvent to UnifiedEvent
    static func toUnifiedEvent(
        _ event: BehaviorEvent,
        behaviorType: BehaviorType?
    ) -> UnifiedEvent {
        let category: UnifiedEvent.EventCategory
        if let type = behaviorType {
            switch type.category {
            case .routinePositive:
                category = .routinePositive
            case .positive:
                category = .positive
            case .negative:
                category = .negative
            }
        } else {
            // Fallback based on points
            category = event.pointsApplied >= 0 ? .positive : .negative
        }

        return UnifiedEvent(
            id: event.id.uuidString,
            childId: event.childId.uuidString,
            timestamp: event.timestamp,
            category: category,
            starsDelta: event.pointsApplied,
            behaviorTypeId: event.behaviorTypeId.uuidString,
            behaviorName: behaviorType?.name ?? "Unknown",
            linkedGoalId: event.rewardId?.uuidString,
            caregiverId: event.loggedByParentId
        )
    }

    /// Convert array of BehaviorEvents to UnifiedEvents
    static func toUnifiedEvents(
        _ events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> [UnifiedEvent] {
        let typeMap = Dictionary(uniqueKeysWithValues: behaviorTypes.map { ($0.id, $0) })
        return events.map { event in
            toUnifiedEvent(event, behaviorType: typeMap[event.behaviorTypeId])
        }
    }

    // MARK: - Goal Adapter

    /// Convert Reward to CanonicalGoal
    static func toCanonicalGoal(
        _ reward: Reward,
        events: [BehaviorEvent],
        isPrimaryReward: Bool
    ) -> CanonicalGoal {
        // Calculate points earned for this reward
        let points = calculatePointsForReward(
            reward: reward,
            events: events,
            isPrimaryReward: isPrimaryReward
        )

        return CanonicalGoal(
            id: reward.id.uuidString,
            childId: reward.childId.uuidString,
            name: reward.name,
            targetPoints: reward.targetPoints,
            currentPoints: points,
            createdDate: reward.createdDate,
            dueDate: reward.dueDate,
            isRedeemed: reward.isRedeemed,
            isExpired: reward.isExpired
        )
    }

    /// Calculate points earned for a reward
    private static func calculatePointsForReward(
        reward: Reward,
        events: [BehaviorEvent],
        isPrimaryReward: Bool
    ) -> Int {
        // Use frozenEarnedPoints if redeemed/expired
        if reward.isRedeemed || reward.isExpired, let frozen = reward.frozenEarnedPoints {
            return frozen
        }

        let startDate = reward.startDate ?? reward.createdDate
        let endDate = reward.dueDate ?? Date()

        let relevantEvents = events.filter { event in
            event.childId == reward.childId &&
            event.timestamp >= startDate &&
            event.timestamp <= endDate &&
            event.pointsApplied > 0 &&
            (isPrimaryReward || event.rewardId == reward.id)
        }

        return relevantEvents.reduce(0) { $0 + $1.pointsApplied }
    }

    /// Convert array of Rewards to CanonicalGoals
    static func toCanonicalGoals(
        _ rewards: [Reward],
        events: [BehaviorEvent],
        activeRewardId: UUID?
    ) -> [CanonicalGoal] {
        rewards.map { reward in
            let isPrimary = reward.id == activeRewardId
            return toCanonicalGoal(reward, events: events, isPrimaryReward: isPrimary)
        }
    }

    // MARK: - Behavior Adapter

    /// Convert BehaviorType to CanonicalBehavior
    static func toCanonicalBehavior(_ type: BehaviorType) -> CanonicalBehavior {
        let category: UnifiedEvent.EventCategory
        switch type.category {
        case .routinePositive:
            category = .routinePositive
        case .positive:
            category = .positive
        case .negative:
            category = .negative
        }

        return CanonicalBehavior(
            id: type.id.uuidString,
            name: type.name,
            category: category,
            defaultPoints: type.defaultPoints,
            isActive: type.isActive
        )
    }

    /// Convert array of BehaviorTypes to CanonicalBehaviors
    static func toCanonicalBehaviors(_ types: [BehaviorType]) -> [CanonicalBehavior] {
        types.map { toCanonicalBehavior($0) }
    }

    // MARK: - Child Adapter

    /// Convert Child to CanonicalChild
    static func toCanonicalChild(_ child: Child) -> CanonicalChild {
        CanonicalChild(
            id: child.id.uuidString,
            name: child.name,
            age: child.age,
            activeGoalId: child.activeRewardId?.uuidString
        )
    }

    /// Convert array of Children to CanonicalChildren
    static func toCanonicalChildren(_ children: [Child]) -> [CanonicalChild] {
        children.map { toCanonicalChild($0) }
    }
}

// MARK: - Pre-Filtered Events Cache

/// Pre-computed filtered event arrays to avoid redundant filtering in signal detectors.
/// Create once at the start of signal detection and pass to all detectors.
struct PreFilteredEvents {
    /// All events for the child (already filtered by childId)
    let all: [UnifiedEvent]

    /// Events in the last 7 days
    let in7Days: [UnifiedEvent]

    /// Events in the last 14 days
    let in14Days: [UnifiedEvent]

    /// Positive events (wins + routines) in all time
    let positive: [UnifiedEvent]

    /// Positive events in last 7 days
    let positiveIn7Days: [UnifiedEvent]

    /// Positive events in last 14 days
    let positiveIn14Days: [UnifiedEvent]

    /// Challenge events in last 7 days
    let challengesIn7Days: [UnifiedEvent]

    /// Events grouped by behavior type ID (for routine detection)
    let byBehavior: [String: [UnifiedEvent]]

    /// Events grouped by behavior, filtered to 7 days
    let byBehaviorIn7Days: [String: [UnifiedEvent]]

    /// Events grouped by behavior, filtered to 14 days
    let byBehaviorIn14Days: [String: [UnifiedEvent]]

    /// Initialize with events already filtered for a specific child
    init(childEvents: [UnifiedEvent]) {
        self.all = childEvents

        // Pre-compute time windows
        let range7 = AnalysisWindow.sevenDays.dateRange
        let range14 = AnalysisWindow.fourteenDays.dateRange

        self.in7Days = childEvents.filter {
            $0.timestamp >= range7.start && $0.timestamp <= range7.end
        }

        self.in14Days = childEvents.filter {
            $0.timestamp >= range14.start && $0.timestamp <= range14.end
        }

        // Pre-compute positive events
        self.positive = childEvents.filter { $0.isPositive }
        self.positiveIn7Days = in7Days.filter { $0.isPositive }
        self.positiveIn14Days = in14Days.filter { $0.isPositive }

        // Pre-compute challenge events
        self.challengesIn7Days = in7Days.filter { $0.isChallenge }

        // Pre-compute behavior groupings
        self.byBehavior = Dictionary(grouping: childEvents) { $0.behaviorTypeId }
        self.byBehaviorIn7Days = Dictionary(grouping: in7Days) { $0.behaviorTypeId }
        self.byBehaviorIn14Days = Dictionary(grouping: in14Days) { $0.behaviorTypeId }
    }

    /// Get events for a specific behavior in the 7-day window
    func behaviorEventsIn7Days(_ behaviorId: String) -> [UnifiedEvent] {
        byBehaviorIn7Days[behaviorId] ?? []
    }

    /// Get events for a specific behavior in the 14-day window
    func behaviorEventsIn14Days(_ behaviorId: String) -> [UnifiedEvent] {
        byBehaviorIn14Days[behaviorId] ?? []
    }

    /// Get events for a specific behavior (all time)
    func behaviorEvents(_ behaviorId: String) -> [UnifiedEvent] {
        byBehavior[behaviorId] ?? []
    }
}

// MARK: - Filtering Helpers

extension Array where Element == UnifiedEvent {

    /// Filter events to a specific time window
    func inWindow(_ window: AnalysisWindow) -> [UnifiedEvent] {
        let range = window.dateRange
        return filter { $0.timestamp >= range.start && $0.timestamp <= range.end }
    }

    /// Filter events for a specific child
    func forChild(_ childId: String) -> [UnifiedEvent] {
        filter { $0.childId == childId }
    }

    /// Filter to only positive events (wins + routines)
    func positiveOnly() -> [UnifiedEvent] {
        filter { $0.isPositive }
    }

    /// Filter to only challenges
    func challengesOnly() -> [UnifiedEvent] {
        filter { $0.isChallenge }
    }

    /// Filter to only routines
    func routinesOnly() -> [UnifiedEvent] {
        filter { $0.isRoutine }
    }

    /// Filter to specific behavior type
    func forBehavior(_ behaviorId: String) -> [UnifiedEvent] {
        filter { $0.behaviorTypeId == behaviorId }
    }

    /// Group events by behavior type ID
    func groupedByBehavior() -> [String: [UnifiedEvent]] {
        Dictionary(grouping: self) { $0.behaviorTypeId }
    }

    /// Group events by date (day)
    func groupedByDay() -> [Date: [UnifiedEvent]] {
        let calendar = Calendar.current
        return Dictionary(grouping: self) { event in
            calendar.startOfDay(for: event.timestamp)
        }
    }

    /// Get unique days with events
    func uniqueDays() -> Set<Date> {
        let calendar = Calendar.current
        return Set(map { calendar.startOfDay(for: $0.timestamp) })
    }

    /// Extract event IDs
    var eventIds: [String] {
        map { $0.id }
    }
}

extension Array where Element == CanonicalGoal {

    /// Filter to active (not redeemed, not expired) goals
    func activeOnly() -> [CanonicalGoal] {
        filter { !$0.isRedeemed && !$0.isExpired }
    }

    /// Filter to goals with deadlines
    func withDeadlines() -> [CanonicalGoal] {
        filter { $0.hasDeadline }
    }

    /// Filter to goals at risk
    func atRisk() -> [CanonicalGoal] {
        filter { $0.isAtRisk }
    }

    /// Filter for a specific child
    func forChild(_ childId: String) -> [CanonicalGoal] {
        filter { $0.childId == childId }
    }
}
