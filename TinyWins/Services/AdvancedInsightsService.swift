import Foundation
import SwiftUI

// MARK: - AdvancedInsightsService

/// Service for calculating advanced analytics metrics.
/// Provides momentum scores, balance indices, heatmap data, and pattern detection.
final class AdvancedInsightsService {

    // MARK: - Momentum Score

    /// Calculate the momentum score for a child (0-100).
    /// Combines logging consistency, positive/negative ratio, and streak data.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - period: Time period to analyze
    /// - Returns: MomentumScore with score and trend
    func calculateMomentumScore(
        childId: UUID,
        events: [BehaviorEvent],
        period: TimePeriod = .thisWeek
    ) -> MomentumScore {
        let range = period.dateRange

        let childEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }

        // Factor 1: Logging consistency (0-40 points)
        let daysInPeriod = Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 7
        let daysWithEvents = Set(childEvents.map {
            Calendar.current.startOfDay(for: $0.timestamp)
        }).count
        let consistencyScore = min(Double(daysWithEvents) / Double(max(daysInPeriod, 1)) * 40, 40)

        // Factor 2: Positive/Negative ratio (0-40 points)
        let positiveEvents = childEvents.filter { $0.pointsApplied > 0 }.count
        let negativeEvents = childEvents.filter { $0.pointsApplied < 0 }.count
        let totalEvents = positiveEvents + negativeEvents
        let ratioScore: Double
        if totalEvents > 0 {
            let ratio = Double(positiveEvents) / Double(totalEvents)
            ratioScore = ratio * 40
        } else {
            ratioScore = 0
        }

        // Factor 3: Volume bonus (0-20 points)
        let volumeScore = min(Double(totalEvents) / 5.0 * 20, 20)

        let totalScore = consistencyScore + ratioScore + volumeScore

        // Calculate trend (compare to previous period)
        let previousRange = previousPeriodRange(for: period)
        let previousEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= previousRange.start &&
            $0.timestamp <= previousRange.end
        }
        let previousPositive = previousEvents.filter { $0.pointsApplied > 0 }.count
        let trend: MomentumTrend
        if positiveEvents > previousPositive + 2 {
            trend = .rising
        } else if positiveEvents < previousPositive - 2 {
            trend = .falling
        } else {
            trend = .steady
        }

        return MomentumScore(
            score: min(totalScore, 100),
            trend: trend,
            consistencyFactor: consistencyScore / 40,
            ratioFactor: ratioScore / 40,
            volumeFactor: volumeScore / 20
        )
    }

    // MARK: - Balance Index

    /// Calculate the balance index between positive and challenge behaviors.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    ///   - period: Time period to analyze
    /// - Returns: BalanceIndex with category breakdown
    func calculateBalanceIndex(
        childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        period: TimePeriod = .thisWeek
    ) -> BalanceIndex {
        let range = period.dateRange

        let childEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }

        var routineCount = 0
        var positiveCount = 0
        var challengeCount = 0

        for event in childEvents {
            guard let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                continue
            }

            switch behaviorType.category {
            case .routinePositive:
                routineCount += 1
            case .positive:
                positiveCount += 1
            case .negative:
                challengeCount += 1
            }
        }

        let total = routineCount + positiveCount + challengeCount

        return BalanceIndex(
            routineRatio: total > 0 ? Double(routineCount) / Double(total) : 0,
            positiveRatio: total > 0 ? Double(positiveCount) / Double(total) : 0,
            challengeRatio: total > 0 ? Double(challengeCount) / Double(total) : 0,
            totalEvents: total
        )
    }

    // MARK: - Heatmap Data

    /// Generate heatmap data showing behavior patterns by day and hour.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - category: Filter by category (nil for all)
    ///   - period: Time period to analyze
    /// - Returns: 7x24 matrix of event counts
    func generateHeatmapData(
        childId: UUID,
        events: [BehaviorEvent],
        category: BehaviorCategory? = nil,
        period: TimePeriod = .thisMonth
    ) -> HeatmapData {
        let range = period.dateRange
        let calendar = Calendar.current

        var data = [[Int]](repeating: [Int](repeating: 0, count: 24), count: 7)

        let childEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }

        for event in childEvents {
            // Filter by category if specified
            if let category = category {
                let isMatch: Bool
                switch category {
                case .positive:
                    isMatch = event.pointsApplied > 0
                case .negative:
                    isMatch = event.pointsApplied < 0
                case .routinePositive:
                    isMatch = event.pointsApplied > 0 // Include routines with positive
                }
                guard isMatch else { continue }
            }

            let weekday = (calendar.component(.weekday, from: event.timestamp) + 5) % 7 // Monday = 0
            let hour = calendar.component(.hour, from: event.timestamp)

            data[weekday][hour] += 1
        }

        // Find max for normalization
        let maxValue = data.flatMap { $0 }.max() ?? 1

        return HeatmapData(
            data: data,
            maxValue: maxValue,
            period: period
        )
    }

    // MARK: - Peak Performance Times

    /// Identify the best times for positive behaviors.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - period: Time period to analyze
    /// - Returns: Array of peak time slots
    func findPeakPerformanceTimes(
        childId: UUID,
        events: [BehaviorEvent],
        period: TimePeriod = .thisMonth
    ) -> [PeakTimeSlot] {
        let heatmap = generateHeatmapData(
            childId: childId,
            events: events,
            category: .positive,
            period: period
        )

        var peaks: [PeakTimeSlot] = []

        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        for (dayIndex, dayData) in heatmap.data.enumerated() {
            for (hour, count) in dayData.enumerated() where count > 0 {
                if count >= heatmap.maxValue / 2 { // Top 50% threshold
                    peaks.append(PeakTimeSlot(
                        dayIndex: dayIndex,
                        dayName: dayNames[dayIndex],
                        hour: hour,
                        eventCount: count,
                        intensity: Double(count) / Double(max(heatmap.maxValue, 1))
                    ))
                }
            }
        }

        return peaks.sorted { $0.eventCount > $1.eventCount }
    }

    // MARK: - Challenge Patterns

    /// Identify patterns in challenge behaviors.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    ///   - period: Time period to analyze
    /// - Returns: Array of challenge patterns with insights
    func identifyChallengePatterns(
        childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        period: TimePeriod = .thisMonth
    ) -> [ChallengePattern] {
        let range = period.dateRange
        let calendar = Calendar.current

        let challengeEvents = events.filter {
            $0.childId == childId &&
            $0.pointsApplied < 0 &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }

        // Group by time of day
        var morningChallenges = 0 // 5-11
        var afternoonChallenges = 0 // 12-17
        var eveningChallenges = 0 // 18-21
        var nightChallenges = 0 // 22-4

        for event in challengeEvents {
            let hour = calendar.component(.hour, from: event.timestamp)
            switch hour {
            case 5..<12: morningChallenges += 1
            case 12..<18: afternoonChallenges += 1
            case 18..<22: eveningChallenges += 1
            default: nightChallenges += 1
            }
        }

        var patterns: [ChallengePattern] = []

        let total = challengeEvents.count
        guard total > 0 else { return patterns }

        // Time-based patterns
        let maxTimeSlot = max(morningChallenges, afternoonChallenges, eveningChallenges, nightChallenges)

        if morningChallenges == maxTimeSlot && Double(morningChallenges) / Double(total) > 0.4 {
            patterns.append(ChallengePattern(
                type: .timeOfDay,
                description: "Most challenges occur in the morning",
                insight: "Consider adjusting morning routine or allowing more transition time",
                frequency: Double(morningChallenges) / Double(total)
            ))
        }

        if eveningChallenges == maxTimeSlot && Double(eveningChallenges) / Double(total) > 0.4 {
            patterns.append(ChallengePattern(
                type: .timeOfDay,
                description: "Most challenges occur in the evening",
                insight: "This might indicate tiredness. Try an earlier bedtime.",
                frequency: Double(eveningChallenges) / Double(total)
            ))
        }

        // Day of week pattern
        var weekdayChallenges = 0
        var weekendChallenges = 0

        for event in challengeEvents {
            let weekday = calendar.component(.weekday, from: event.timestamp)
            if weekday == 1 || weekday == 7 {
                weekendChallenges += 1
            } else {
                weekdayChallenges += 1
            }
        }

        if Double(weekdayChallenges) / Double(total) > 0.7 {
            patterns.append(ChallengePattern(
                type: .dayOfWeek,
                description: "Challenges cluster on weekdays",
                insight: "School/routine days may be more stressful. Plan decompression time.",
                frequency: Double(weekdayChallenges) / Double(total)
            ))
        }

        return patterns
    }

    // MARK: - Weekly Trajectory

    /// Calculate week-over-week trend.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    /// - Returns: Weekly trajectory with percent change
    func calculateWeeklyTrajectory(
        childId: UUID,
        events: [BehaviorEvent]
    ) -> WeeklyTrajectory {
        let calendar = Calendar.current
        let now = Date()

        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) else {
            return WeeklyTrajectory(thisWeekPoints: 0, lastWeekPoints: 0, percentChange: 0)
        }

        let thisWeekEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= thisWeekStart &&
            $0.pointsApplied > 0
        }

        let lastWeekEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= lastWeekStart &&
            $0.timestamp < thisWeekStart &&
            $0.pointsApplied > 0
        }

        let thisWeekPoints = thisWeekEvents.reduce(0) { $0 + $1.pointsApplied }
        let lastWeekPoints = lastWeekEvents.reduce(0) { $0 + $1.pointsApplied }

        let percentChange: Double
        if lastWeekPoints > 0 {
            percentChange = Double(thisWeekPoints - lastWeekPoints) / Double(lastWeekPoints) * 100
        } else {
            percentChange = thisWeekPoints > 0 ? 100 : 0
        }

        return WeeklyTrajectory(
            thisWeekPoints: thisWeekPoints,
            lastWeekPoints: lastWeekPoints,
            percentChange: percentChange
        )
    }

    // MARK: - Helpers

    private func previousPeriodRange(for period: TimePeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let range = period.dateRange
        let duration = range.end.timeIntervalSince(range.start)

        let previousEnd = range.start
        let previousStart = calendar.date(byAdding: .second, value: -Int(duration), to: previousEnd) ?? previousEnd

        return (previousStart, previousEnd)
    }
}

// MARK: - Data Types

struct MomentumScore {
    let score: Double // 0-100
    let trend: MomentumTrend
    let consistencyFactor: Double // 0-1
    let ratioFactor: Double // 0-1
    let volumeFactor: Double // 0-1
}

enum MomentumTrend: String {
    case rising = "Rising"
    case steady = "Steady"
    case falling = "Falling"

    var icon: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .steady: return "arrow.right"
        case .falling: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .rising: return Color.green
        case .steady: return Color.blue
        case .falling: return Color.orange
        }
    }
}

struct BalanceIndex {
    let routineRatio: Double
    let positiveRatio: Double
    let challengeRatio: Double
    let totalEvents: Int

    var isHealthy: Bool {
        challengeRatio < 0.3 && (routineRatio + positiveRatio) > 0.7
    }
}

struct HeatmapData {
    let data: [[Int]] // 7 days x 24 hours
    let maxValue: Int
    let period: TimePeriod

    func normalizedValue(day: Int, hour: Int) -> Double {
        guard maxValue > 0 else { return 0 }
        return Double(data[day][hour]) / Double(maxValue)
    }
}

struct PeakTimeSlot: Identifiable {
    let id = UUID()
    let dayIndex: Int
    let dayName: String
    let hour: Int
    let eventCount: Int
    let intensity: Double

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}

struct ChallengePattern: Identifiable {
    let id = UUID()
    let type: ChallengePatternType
    let description: String
    let insight: String
    let frequency: Double // 0-1
}

enum ChallengePatternType {
    case timeOfDay
    case dayOfWeek
    case behaviorType
    case trigger
}

struct WeeklyTrajectory {
    let thisWeekPoints: Int
    let lastWeekPoints: Int
    let percentChange: Double

    var isImproving: Bool { percentChange > 0 }

    var trendIcon: String {
        if percentChange > 10 {
            return "arrow.up.right.circle.fill"
        } else if percentChange < -10 {
            return "arrow.down.right.circle.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }

    var trendColor: Color {
        if percentChange > 10 {
            return .green
        } else if percentChange < -10 {
            return .orange
        } else {
            return .blue
        }
    }
}
