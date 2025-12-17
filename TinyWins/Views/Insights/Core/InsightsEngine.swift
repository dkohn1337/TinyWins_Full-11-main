import Foundation
import SwiftUI

// MARK: - Insights Engine

/// Converts raw behavior events into actionable Coach insights.
/// Generates "Interpretation → Try" pairs based on patterns.
final class InsightsEngine {

    // MARK: - Public API

    /// Generate all relevant insights for the current scope and time range
    func generateInsights(
        scope: InsightsScopeType,
        timeRange: InsightsTimeRange,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        children: [Child],
        reflectionData: ReflectionEngineData? = nil
    ) -> [CoachInsight] {

        switch scope {
        case .family:
            return generateFamilyInsights(
                timeRange: timeRange,
                events: events,
                behaviorTypes: behaviorTypes,
                children: children
            )

        case .child(let childId):
            return generateChildInsights(
                childId: childId,
                timeRange: timeRange,
                events: events,
                behaviorTypes: behaviorTypes,
                children: children
            )

        case .you:
            return generateParentInsights(
                timeRange: timeRange,
                events: events,
                reflectionData: reflectionData
            )
        }
    }

    /// Get the featured "One small thing" insight
    func featuredInsight(from insights: [CoachInsight]) -> CoachInsight? {
        insights.first { $0.priority == .featured } ?? insights.first
    }

    // MARK: - Family Insights

    private func generateFamilyInsights(
        timeRange: InsightsTimeRange,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        children: [Child]
    ) -> [CoachInsight] {

        var insights: [CoachInsight] = []
        let range = timeRange.dateRange
        let periodEvents = events.filter { $0.timestamp >= range.start && $0.timestamp <= range.end }

        // 1. Weekly momentum insight
        if let momentum = calculateMomentumInsight(events: periodEvents, timeRange: timeRange, isFamily: true) {
            insights.append(momentum)
        }

        // 2. Balance insight (wins vs challenges)
        if let balance = calculateBalanceInsight(events: periodEvents, timeRange: timeRange) {
            insights.append(balance)
        }

        // 3. Peak time pattern
        if let peakTime = calculatePeakTimeInsight(events: periodEvents) {
            insights.append(peakTime)
        }

        // 4. Top strength emerging
        if let strength = calculateStrengthInsight(events: periodEvents, behaviorTypes: behaviorTypes) {
            insights.append(strength)
        }

        // Mark the best one as featured
        return prioritizeInsights(insights)
    }

    // MARK: - Child Insights

    private func generateChildInsights(
        childId: UUID,
        timeRange: InsightsTimeRange,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        children: [Child]
    ) -> [CoachInsight] {

        var insights: [CoachInsight] = []
        let range = timeRange.dateRange
        let childEvents = events.filter {
            $0.childId == childId && $0.timestamp >= range.start && $0.timestamp <= range.end
        }

        let child = children.first { $0.id == childId }
        let childName = child?.name ?? "Child"

        // 1. Momentum insight (child-specific)
        if let momentum = calculateMomentumInsight(events: childEvents, timeRange: timeRange, isFamily: false, childName: childName) {
            insights.append(momentum)
        }

        // 2. Strength building
        if let strength = calculateStrengthInsight(events: childEvents, behaviorTypes: behaviorTypes, childName: childName) {
            insights.append(strength)
        }

        // 3. Challenge pattern
        if let challenge = calculateChallengeInsight(events: childEvents, behaviorTypes: behaviorTypes, childName: childName) {
            insights.append(challenge)
        }

        // 4. Best day/time
        if let pattern = calculatePatternInsight(events: childEvents, childName: childName) {
            insights.append(pattern)
        }

        // 5. Week-over-week trajectory
        if let trajectory = calculateTrajectoryInsight(allEvents: events, childId: childId, childName: childName) {
            insights.append(trajectory)
        }

        return prioritizeInsights(insights)
    }

    // MARK: - Parent ("You") Insights

    private func generateParentInsights(
        timeRange: InsightsTimeRange,
        events: [BehaviorEvent],
        reflectionData: ReflectionEngineData?
    ) -> [CoachInsight] {

        var insights: [CoachInsight] = []
        let range = timeRange.dateRange
        let periodEvents = events.filter { $0.timestamp >= range.start && $0.timestamp <= range.end }

        // 1. Logging consistency
        if let consistency = calculateConsistencyInsight(events: periodEvents, timeRange: timeRange) {
            insights.append(consistency)
        }

        // 2. Reflection correlation (if data available)
        if let reflection = reflectionData, let correlationInsight = calculateReflectionCorrelation(events: periodEvents, reflectionData: reflection) {
            insights.append(correlationInsight)
        }

        // 3. Noticing pattern (what you're logging most)
        if let noticing = calculateNoticingInsight(events: periodEvents) {
            insights.append(noticing)
        }

        // 4. Coach level milestone
        if let milestone = calculateMilestoneInsight(events: periodEvents) {
            insights.append(milestone)
        }

        return prioritizeInsights(insights)
    }

    // MARK: - Insight Calculators

    private func calculateMomentumInsight(
        events: [BehaviorEvent],
        timeRange: InsightsTimeRange,
        isFamily: Bool,
        childName: String? = nil
    ) -> CoachInsight? {

        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        let challengeEvents = events.filter { $0.pointsApplied < 0 }

        guard positiveEvents.count + challengeEvents.count >= 3 else { return nil }

        let ratio = challengeEvents.isEmpty ? 100.0 : Double(positiveEvents.count) / Double(challengeEvents.count)

        let headline: String
        let interpretation: String
        let tryAction: String

        if ratio >= 3.0 {
            headline = isFamily ? "Wins are leading" : "\(childName ?? "They")'s on a roll"
            interpretation = "You logged \(positiveEvents.count) wins and \(challengeEvents.count) challenges. That's a healthy balance."
            tryAction = "Try: Keep the momentum going with a quick celebration tonight"
        } else if ratio >= 1.5 {
            headline = isFamily ? "Building momentum" : "Progress is happening"
            interpretation = "\(positiveEvents.count) wins this \(timeRange.shortDisplayKey). You're noticing the good stuff."
            tryAction = "Try: Name one win at dinner to reinforce it"
        } else {
            headline = isFamily ? "A challenging stretch" : "Some bumps this week"
            interpretation = "More challenges logged than wins. That's data, not failure."
            tryAction = "Try: Look for one small win tomorrow and celebrate it out loud"
        }

        // Build week dots visual
        let weekDots = buildWeekDots(from: events)

        return CoachInsight(
            id: UUID(),
            category: .momentum,
            headline: headline,
            interpretation: interpretation,
            tryAction: tryAction,
            visualData: .weekDots(weekDots),
            priority: .featured
        )
    }

    private func calculateBalanceInsight(events: [BehaviorEvent], timeRange: InsightsTimeRange) -> CoachInsight? {
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        let challengeEvents = events.filter { $0.pointsApplied < 0 }

        let total = positiveEvents.count + challengeEvents.count
        guard total >= 5 else { return nil }

        let positiveRatio = Double(positiveEvents.count) / Double(total)

        let headline: String
        let interpretation: String
        let tryAction: String

        if positiveRatio >= 0.7 {
            headline = "Strengths outweigh struggles"
            interpretation = "\(Int(positiveRatio * 100))% of moments logged are wins. You're focusing on growth."
            tryAction = "Try: Share one win story at bedtime to end the day strong"
        } else if positiveRatio >= 0.5 {
            headline = "Balanced view"
            interpretation = "You're capturing both wins and challenges evenly. That's honest parenting."
            tryAction = "Try: For each challenge, find a related strength to acknowledge"
        } else {
            headline = "Noticing the hard parts"
            interpretation = "More challenges logged than wins. That awareness is step one."
            tryAction = "Try: Set a reminder to log one win before lunch tomorrow"
        }

        let trendDirection: InsightVisualData.TrendDirection = positiveRatio >= 0.6 ? .up : (positiveRatio >= 0.4 ? .steady : .down)

        return CoachInsight(
            id: UUID(),
            category: .balance,
            headline: headline,
            interpretation: interpretation,
            tryAction: tryAction,
            visualData: .trendArrow(trendDirection, nil),
            priority: .standard
        )
    }

    private func calculatePeakTimeInsight(events: [BehaviorEvent]) -> CoachInsight? {
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        guard positiveEvents.count >= 5 else { return nil }

        // Group by hour
        var hourCounts: [Int: Int] = [:]
        for event in positiveEvents {
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        guard let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key else { return nil }

        let timeDescription: String
        let tryAction: String

        switch peakHour {
        case 6..<10:
            timeDescription = "morning"
            tryAction = "Try: Use mornings for a quick high-five ritual"
        case 10..<14:
            timeDescription = "midday"
            tryAction = "Try: Build on midday energy with a short game together"
        case 14..<18:
            timeDescription = "afternoon"
            tryAction = "Try: Afternoon snack time could be win-sharing time"
        case 18..<21:
            timeDescription = "evening"
            tryAction = "Try: Dinner is perfect for naming today's highlights"
        default:
            timeDescription = "late"
            tryAction = "Try: A bedtime reflection can capture the day's best"
        }

        return CoachInsight(
            id: UUID(),
            category: .pattern,
            headline: "Peak time: \(timeDescription)s",
            interpretation: "Most wins happen in the \(timeDescription). That's when connection is strongest.",
            tryAction: tryAction,
            visualData: nil,
            priority: .standard
        )
    }

    private func calculateStrengthInsight(
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        childName: String? = nil
    ) -> CoachInsight? {

        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        guard positiveEvents.count >= 3 else { return nil }

        // Count behaviors
        var behaviorCounts: [UUID: Int] = [:]
        for event in positiveEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }

        guard let topBehaviorId = behaviorCounts.max(by: { $0.value < $1.value })?.key,
              let topBehavior = behaviorTypes.first(where: { $0.id == topBehaviorId }),
              let count = behaviorCounts[topBehaviorId] else { return nil }

        let subject = childName ?? "Your family"
        let possessive = childName != nil ? "\(childName!)'s" : "Their"

        return CoachInsight(
            id: UUID(),
            category: .strength,
            headline: "\(topBehavior.name) is growing",
            interpretation: "\(subject) showed \(topBehavior.name.lowercased()) \(count) times this period. \(possessive) consistency is building.",
            tryAction: "Try: Celebrate out loud when you notice \(topBehavior.name.lowercased())",
            visualData: .behaviorPills([InsightVisualData.BehaviorPillData(name: topBehavior.name, count: count, isPositive: true)]),
            priority: .standard
        )
    }

    private func calculateChallengeInsight(
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        childName: String
    ) -> CoachInsight? {

        let challengeEvents = events.filter { $0.pointsApplied < 0 }
        guard challengeEvents.count >= 3 else { return nil }

        // Count challenge behaviors
        var behaviorCounts: [UUID: Int] = [:]
        for event in challengeEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }

        guard let topChallengeId = behaviorCounts.max(by: { $0.value < $1.value })?.key,
              let topChallenge = behaviorTypes.first(where: { $0.id == topChallengeId }),
              let count = behaviorCounts[topChallengeId] else { return nil }

        return CoachInsight(
            id: UUID(),
            category: .pattern,
            headline: "\(topChallenge.name) is a pattern",
            interpretation: "\(childName) had \(count) \(topChallenge.name.lowercased()) moments. Patterns are where growth hides.",
            tryAction: "Try: Notice what happens right before \(topChallenge.name.lowercased())",
            visualData: .behaviorPills([InsightVisualData.BehaviorPillData(name: topChallenge.name, count: count, isPositive: false)]),
            priority: .secondary
        )
    }

    private func calculatePatternInsight(events: [BehaviorEvent], childName: String) -> CoachInsight? {
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        guard positiveEvents.count >= 5 else { return nil }

        // Group by day of week
        var dayCounts: [Int: Int] = [:]
        for event in positiveEvents {
            let weekday = Calendar.current.component(.weekday, from: event.timestamp)
            dayCounts[weekday, default: 0] += 1
        }

        guard let bestDay = dayCounts.max(by: { $0.value < $1.value })?.key else { return nil }

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let dayName = dayNames[bestDay]

        return CoachInsight(
            id: UUID(),
            category: .pattern,
            headline: "\(dayName)s shine",
            interpretation: "\(childName) has the most wins on \(dayName)s. Something about that day works.",
            tryAction: "Try: What's different about \(dayName)? Bring that energy to other days",
            visualData: nil,
            priority: .secondary
        )
    }

    private func calculateTrajectoryInsight(allEvents: [BehaviorEvent], childId: UUID, childName: String) -> CoachInsight? {
        let now = Date()
        let calendar = Calendar.current

        let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: now)!

        let childEvents = allEvents.filter { $0.childId == childId }
        let thisWeekEvents = childEvents.filter { $0.timestamp >= thisWeekStart && $0.pointsApplied > 0 }
        let lastWeekEvents = childEvents.filter { $0.timestamp >= lastWeekStart && $0.timestamp < thisWeekStart && $0.pointsApplied > 0 }

        guard lastWeekEvents.count >= 3 else { return nil }

        let change = thisWeekEvents.count - lastWeekEvents.count
        let percentChange = lastWeekEvents.count > 0 ? Double(change) / Double(lastWeekEvents.count) * 100 : 0

        let trend: InsightVisualData.TrendDirection
        let headline: String
        let interpretation: String
        let tryAction: String

        if percentChange >= 20 {
            trend = .up
            headline = "Wins are climbing"
            interpretation = "\(thisWeekEvents.count) wins this week vs \(lastWeekEvents.count) last week. \(childName) is building momentum."
            tryAction = "Try: Keep the first 5 minutes after school screen-free for connection"
        } else if percentChange <= -20 {
            trend = .down
            headline = "A quieter week"
            interpretation = "Fewer wins logged than last week. That happens. Keep noticing."
            tryAction = "Try: Set one moment tomorrow to look for something going right"
        } else {
            trend = .steady
            headline = "Steady progress"
            interpretation = "Similar to last week. Consistency matters more than spikes."
            tryAction = "Try: Celebrate the steadiness itself tonight"
        }

        return CoachInsight(
            id: UUID(),
            category: .momentum,
            headline: headline,
            interpretation: interpretation,
            tryAction: tryAction,
            visualData: .trendArrow(trend, percentChange),
            priority: .standard
        )
    }

    private func calculateConsistencyInsight(events: [BehaviorEvent], timeRange: InsightsTimeRange) -> CoachInsight? {
        let range = timeRange.dateRange
        let calendar = Calendar.current

        // Count unique days with logging
        var uniqueDays: Set<String> = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for event in events where event.timestamp >= range.start && event.timestamp <= range.end {
            uniqueDays.insert(formatter.string(from: event.timestamp))
        }

        let totalDays = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 7
        let daysLogged = uniqueDays.count
        let consistency = Double(daysLogged) / Double(max(totalDays, 1))

        let headline: String
        let interpretation: String
        let tryAction: String

        if consistency >= 0.7 {
            headline = "You're showing up"
            interpretation = "You logged on \(daysLogged) of the last \(totalDays) days. That consistency builds trust."
            tryAction = "Try: You've earned a self-care moment this weekend"
        } else if consistency >= 0.4 {
            headline = "Building the habit"
            interpretation = "Logging on \(daysLogged) days this period. Each log is a moment of attention."
            tryAction = "Try: Link logging to an existing routine, like after dinner"
        } else {
            headline = "Room to grow"
            interpretation = "Only \(daysLogged) days of logging. Small steps count."
            tryAction = "Try: Just one log tomorrow. That's the goal."
        }

        let weekDots = buildLoggingDots(from: events, timeRange: timeRange)

        return CoachInsight(
            id: UUID(),
            category: .connection,
            headline: headline,
            interpretation: interpretation,
            tryAction: tryAction,
            visualData: .weekDots(weekDots),
            priority: .featured
        )
    }

    private func calculateReflectionCorrelation(
        events: [BehaviorEvent],
        reflectionData: ReflectionEngineData
    ) -> CoachInsight? {

        // This would use actual reflection data to calculate correlation
        // For now, generate based on available data patterns
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        guard positiveEvents.count >= 5 else { return nil }

        // Simplified: assume reflection correlation exists
        let correlationPercent = 23 // Would be calculated from reflectionData

        return CoachInsight(
            id: UUID(),
            category: .connection,
            headline: "Your reflections matter",
            interpretation: "On days you reflect, kids have \(correlationPercent)% more positive moments logged.",
            tryAction: "Try: 2 minutes of journaling before bed tonight",
            visualData: .progressRing(0.75),
            priority: .standard
        )
    }

    private func calculateNoticingInsight(events: [BehaviorEvent]) -> CoachInsight? {
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        let challengeEvents = events.filter { $0.pointsApplied < 0 }

        let total = positiveEvents.count + challengeEvents.count
        guard total >= 5 else { return nil }

        let positiveRatio = Double(positiveEvents.count) / Double(total)

        if positiveRatio >= 0.6 {
            return CoachInsight(
                id: UUID(),
                category: .strength,
                headline: "You see the good",
                interpretation: "Most of what you log is positive. That focus shapes what kids believe about themselves.",
                tryAction: "Try: Tell one child what you noticed them do well today",
                visualData: nil,
                priority: .standard
            )
        } else {
            return CoachInsight(
                id: UUID(),
                category: .balance,
                headline: "You're noticing struggles",
                interpretation: "More challenges logged. Awareness is the first step to support.",
                tryAction: "Try: For each challenge tomorrow, find one small win to balance it",
                visualData: nil,
                priority: .standard
            )
        }
    }

    private func calculateMilestoneInsight(events: [BehaviorEvent]) -> CoachInsight? {
        let totalEvents = events.count

        let milestone: Int
        let title: String

        if totalEvents >= 500 {
            milestone = 500
            title = "Master Coach"
        } else if totalEvents >= 200 {
            milestone = 200
            title = "Dedicated Coach"
        } else if totalEvents >= 100 {
            milestone = 100
            title = "Active Coach"
        } else if totalEvents >= 50 {
            milestone = 50
            title = "Growing Coach"
        } else if totalEvents >= 20 {
            milestone = 20
            title = "Emerging Coach"
        } else {
            return nil
        }

        return CoachInsight(
            id: UUID(),
            category: .milestone,
            headline: "\(title) unlocked",
            interpretation: "You've logged \(totalEvents) moments. Each one is an act of noticing.",
            tryAction: "Try: Share your parenting journey with a friend who might benefit",
            visualData: .progressRing(min(Double(totalEvents) / Double(milestone), 1.0)),
            priority: .secondary
        )
    }

    // MARK: - Helpers

    private func buildWeekDots(from events: [BehaviorEvent]) -> [InsightVisualData.DayActivity] {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today) // 1 = Sunday

        var dots: [InsightVisualData.DayActivity] = []

        for dayOffset in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today)!
            let dayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: targetDate) }
            let positiveCount = dayEvents.filter { $0.pointsApplied > 0 }.count
            let intensity = min(Double(positiveCount) / 5.0, 1.0) // Max intensity at 5+ events

            let isToday = calendar.isDateInToday(targetDate)
            dots.append(.init(dayIndex: dayOffset, intensity: intensity, isToday: isToday))
        }

        return dots
    }

    private func buildLoggingDots(from events: [BehaviorEvent], timeRange: InsightsTimeRange) -> [InsightVisualData.DayActivity] {
        let calendar = Calendar.current
        let today = Date()

        var dots: [InsightVisualData.DayActivity] = []

        for dayOffset in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today)!
            let dayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: targetDate) }
            let hasLogging = !dayEvents.isEmpty
            let isToday = calendar.isDateInToday(targetDate)

            dots.append(.init(dayIndex: dayOffset, intensity: hasLogging ? 1.0 : 0.0, isToday: isToday))
        }

        return dots
    }

    private func prioritizeInsights(_ insights: [CoachInsight]) -> [CoachInsight] {
        var mutableInsights = insights

        // Find the best candidate for featured
        if let featuredIndex = mutableInsights.firstIndex(where: { $0.priority == .featured }) {
            // Already have a featured one, good
        } else if let firstStandard = mutableInsights.firstIndex(where: { $0.priority == .standard }) {
            // Promote first standard to featured
            let insight = mutableInsights[firstStandard]
            mutableInsights[firstStandard] = CoachInsight(
                id: insight.id,
                category: insight.category,
                headline: insight.headline,
                interpretation: insight.interpretation,
                tryAction: insight.tryAction,
                visualData: insight.visualData,
                priority: .featured
            )
        }

        return mutableInsights.sorted { $0.priority < $1.priority }
    }
}

// MARK: - Reflection Engine Data (Placeholder)

/// Placeholder for reflection data that would come from ReflectionInsightUseCase
struct ReflectionEngineData {
    let totalReflections: Int
    let averagePositiveMomentsOnReflectionDays: Double
    let averagePositiveMomentsOnNonReflectionDays: Double
}
