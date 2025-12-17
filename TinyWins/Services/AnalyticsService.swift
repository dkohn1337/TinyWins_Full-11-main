import Foundation

// MARK: - AnalyticsService
//
// Architecture Note: AnalyticsService uses the singleton pattern (.shared) intentionally.
//
// This service is a stateless analytics utility that:
// - Contains only pure static functions for data analysis
// - Has no mutable state (struct with static methods)
// - Takes all required data as parameters (events, behaviorTypes, etc.)
// - Returns computed results without side effects
//
// The .shared instance exists for:
// 1. Event logging (log() method) - debug-only console output
// 2. Consistency with service access patterns in the codebase
//
// Most analytics methods are static and don't require an instance:
// - AnalyticsService.behaviorFrequency(events:childId:period:)
// - AnalyticsService.improvementSuggestions(events:behaviorTypes:child:)
// - AnalyticsService.weeklySummary(events:behaviorTypes:childId:)
//
// DI is unnecessary here because:
// 1. Static methods have no state to mock
// 2. Tests can pass mock data directly to static methods
// 3. The struct is value-typed and trivially constructible
//
// If future requirements add external analytics backends (Firebase, Mixpanel),
// consider making log() take a protocol-based backend for testability.

/// Provides analytics calculations and behavioral insights.
///
/// This service offers:
/// - Behavior frequency analysis per child and time period
/// - Positive/negative behavior counts
/// - Improvement suggestions based on patterns
/// - Weekly summary generation
///
/// Most methods are static and take data as parameters.
/// Access instance methods via `AnalyticsService.shared` or create an instance.
struct AnalyticsService {
    /// Shared singleton instance for event logging.
    /// Static analysis methods don't require an instance.
    static let shared = AnalyticsService()

    /// Creates a new AnalyticsService instance.
    init() {}
    
    /// Analytics event types
    enum AnalyticsEvent {
        case custom(String, [String: String])
        case behaviorLogged(childId: String, behaviorId: String)
        case rewardCreated(childId: String)
        case goalCompleted(childId: String, rewardId: String)
    }
    
    /// Log an analytics event (stub for now, can be connected to analytics backend)
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        switch event {
        case .custom(let name, let params):
            print("[Analytics] \(name) - \(params)")
        case .behaviorLogged(let childId, let behaviorId):
            print("[Analytics] behavior_logged - child: \(childId), behavior: \(behaviorId)")
        case .rewardCreated(let childId):
            print("[Analytics] reward_created - child: \(childId)")
        case .goalCompleted(let childId, let rewardId):
            print("[Analytics] goal_completed - child: \(childId), reward: \(rewardId)")
        }
        #endif
    }
    
    // MARK: - Behavior Performance Analysis
    
    /// Get behavior frequency for a child over a time period
    static func behaviorFrequency(
        events: [BehaviorEvent],
        childId: UUID,
        period: TimePeriod
    ) -> [UUID: Int] {
        let (start, end) = period.dateRange
        let filteredEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= start &&
            $0.timestamp <= end
        }
        
        var frequency: [UUID: Int] = [:]
        for event in filteredEvents {
            frequency[event.behaviorTypeId, default: 0] += 1
        }
        return frequency
    }
    
    /// Get negative behavior count for a child over a time period
    static func negativeBehaviorCount(
        events: [BehaviorEvent],
        childId: UUID,
        period: TimePeriod
    ) -> Int {
        let (start, end) = period.dateRange
        return events.filter {
            $0.childId == childId &&
            $0.timestamp >= start &&
            $0.timestamp <= end &&
            $0.pointsApplied < 0
        }.count
    }
    
    /// Get positive behavior count for a child over a time period
    static func positiveBehaviorCount(
        events: [BehaviorEvent],
        childId: UUID,
        period: TimePeriod
    ) -> Int {
        let (start, end) = period.dateRange
        return events.filter {
            $0.childId == childId &&
            $0.timestamp >= start &&
            $0.timestamp <= end &&
            $0.pointsApplied >= 0
        }.count
    }
    
    /// Get points earned in a time period
    static func pointsEarned(
        events: [BehaviorEvent],
        childId: UUID,
        period: TimePeriod
    ) -> Int {
        let (start, end) = period.dateRange
        return events.filter {
            $0.childId == childId &&
            $0.timestamp >= start &&
            $0.timestamp <= end
        }.reduce(0) { $0 + $1.pointsApplied }
    }
    
    // MARK: - Improvement Suggestions
    
    /// Analyze child's behavior and suggest areas for improvement
    static func improvementSuggestions(
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        child: Child
    ) -> [ImprovementSuggestion] {
        var suggestions: [ImprovementSuggestion] = []
        
        // Analyze last month's data
        let (start, end) = TimePeriod.lastMonth.dateRange
        let recentEvents = events.filter {
            $0.childId == child.id &&
            $0.timestamp >= start &&
            $0.timestamp <= end
        }
        
        // Count negative behaviors
        var negativeCounts: [UUID: Int] = [:]
        for event in recentEvents where event.pointsApplied < 0 {
            negativeCounts[event.behaviorTypeId, default: 0] += 1
        }
        
        // Find frequent negative behaviors (3+ times in last month)
        for (behaviorId, count) in negativeCounts where count >= 3 {
            if let behavior = behaviorTypes.first(where: { $0.id == behaviorId }) {
                suggestions.append(ImprovementSuggestion(
                    type: .reduceNegative,
                    behaviorType: behavior,
                    frequency: count,
                    message: "\(child.name) had \"\(behavior.name)\" \(count) times last month. Consider working on this together."
                ))
            }
        }
        
        // Find routines that aren't being done regularly
        let routineBehaviors = behaviorTypes.filter { $0.category == .routinePositive && $0.isActive }
        for routine in routineBehaviors {
            let routineEvents = recentEvents.filter { $0.behaviorTypeId == routine.id }
            let daysInMonth = 30
            let completionRate = Double(routineEvents.count) / Double(daysInMonth)
            
            // Suggest if routine is done less than 50% of the time
            if completionRate < 0.5 && routineEvents.count > 0 {
                suggestions.append(ImprovementSuggestion(
                    type: .increaseRoutine,
                    behaviorType: routine,
                    frequency: routineEvents.count,
                    message: "\"\(routine.name)\" was completed only \(routineEvents.count) times last month. Building consistency could help!"
                ))
            }
        }
        
        // Suggest new age-appropriate behaviors if child has an age
        if let age = child.age {
            let ageAppropriateBehaviors = BehaviorType.suggestedBehaviors(forAge: age)
            let usedBehaviorIds = Set(recentEvents.map { $0.behaviorTypeId })
            
            let unusedBehaviors = ageAppropriateBehaviors.filter {
                !usedBehaviorIds.contains($0.id) && $0.category != .negative
            }
            
            // Limit to one routine suggestion and two other suggestions to add variety
            var routineAdded = false
            var selectedBehaviors: [BehaviorType] = []
            
            for behavior in unusedBehaviors {
                if selectedBehaviors.count >= 3 { break }
                
                if behavior.category == .routinePositive {
                    if !routineAdded {
                        selectedBehaviors.append(behavior)
                        routineAdded = true
                    }
                } else {
                    selectedBehaviors.append(behavior)
                }
            }
            
            for behavior in selectedBehaviors {
                suggestions.append(ImprovementSuggestion(
                    type: .tryNew,
                    behaviorType: behavior,
                    frequency: 0,
                    message: "Try tracking \"\(behavior.name)\" - it's great for \(age)-year-olds!"
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Weekly Summary
    
    struct WeeklySummary {
        let childId: UUID
        let weekStart: Date
        let weekEnd: Date
        let totalPoints: Int
        let positiveCount: Int
        let negativeCount: Int
        let topBehaviors: [(BehaviorType, Int)]
        let comparedToLastWeek: Int // Point difference
    }
    
    static func weeklySummary(
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        childId: UUID
    ) -> WeeklySummary? {
        let calendar = Calendar.current
        let now = Date()
        
        // This week
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let thisWeekEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= thisWeekStart &&
            $0.timestamp <= now
        }
        
        // Last week
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
        let lastWeekEnd = thisWeekStart
        let lastWeekEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= lastWeekStart &&
            $0.timestamp < lastWeekEnd
        }
        
        let thisWeekPoints = thisWeekEvents.reduce(0) { $0 + $1.pointsApplied }
        let lastWeekPoints = lastWeekEvents.reduce(0) { $0 + $1.pointsApplied }
        
        // Count behaviors
        var behaviorCounts: [UUID: Int] = [:]
        for event in thisWeekEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }
        
        let topBehaviors = behaviorCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { (id, count) -> (BehaviorType, Int)? in
                guard let behavior = behaviorTypes.first(where: { $0.id == id }) else { return nil }
                return (behavior, count)
            }
        
        return WeeklySummary(
            childId: childId,
            weekStart: thisWeekStart,
            weekEnd: now,
            totalPoints: thisWeekPoints,
            positiveCount: thisWeekEvents.filter { $0.pointsApplied >= 0 }.count,
            negativeCount: thisWeekEvents.filter { $0.pointsApplied < 0 }.count,
            topBehaviors: Array(topBehaviors),
            comparedToLastWeek: thisWeekPoints - lastWeekPoints
        )
    }
}

// MARK: - Supporting Types

struct ImprovementSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let behaviorType: BehaviorType
    let frequency: Int
    let message: String
    
    enum SuggestionType {
        case reduceNegative
        case increaseRoutine
        case tryNew
        
        var title: String {
            switch self {
            case .reduceNegative: return "Area to Improve"
            case .increaseRoutine: return "Build Consistency"
            case .tryNew: return "Try Something New"
            }
        }
        
        var iconName: String {
            switch self {
            case .reduceNegative: return "exclamationmark.triangle.fill"
            case .increaseRoutine: return "arrow.triangle.2.circlepath"
            case .tryNew: return "sparkles"
            }
        }
        
        var color: String {
            switch self {
            case .reduceNegative: return "orange"
            case .increaseRoutine: return "blue"
            case .tryNew: return "green"
            }
        }
    }
}
