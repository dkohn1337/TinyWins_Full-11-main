import Foundation
import Combine

/// Store responsible for analytics and insights calculations.
/// Extracted from FamilyViewModel to provide focused analytics state management.
@MainActor
final class InsightsStore: ObservableObject {

    // MARK: - Dependencies

    private let repository: RepositoryProtocol

    // MARK: - Initialization

    init(repository: RepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Insights Data Calculation

    /// Calculate insights data for a specific child and time range
    /// This preserves the exact logic from FamilyViewModel.insightsData(forChild:timeRange:)
    func insightsData(
        forChild childId: UUID,
        timeRange: InsightTimeRange,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> ChildInsightsData {
        let range = timeRange.dateRange
        let events = behaviorEvents.filter {
            $0.childId == childId &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }

        // Calculate totals
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        let negativeEvents = events.filter { $0.pointsApplied < 0 }
        let totalPositive = positiveEvents.reduce(0) { $0 + $1.pointsApplied }
        let totalNegative = negativeEvents.reduce(0) { $0 + $1.pointsApplied }

        // Daily breakdown
        var dailyData: [Date: Int] = [:]
        let calendar = Calendar.current
        var currentDate = range.start
        while currentDate <= range.end {
            let dayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
            dailyData[calendar.startOfDay(for: currentDate)] = dayEvents.reduce(0) { $0 + $1.pointsApplied }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? range.end
        }

        // Top behaviors
        var behaviorCounts: [UUID: Int] = [:]
        for event in positiveEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }
        let topPositive = behaviorCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .compactMap { (id, count) -> (BehaviorType, Int)? in
                guard let behavior = behaviorTypes.first(where: { $0.id == id }) else { return nil }
                return (behavior, count)
            }

        // Top challenges
        var challengeCounts: [UUID: Int] = [:]
        for event in negativeEvents {
            challengeCounts[event.behaviorTypeId, default: 0] += 1
        }
        let topChallenges = challengeCounts
            .sorted { $0.value > $1.value }
            .prefix(2)
            .compactMap { (id, count) -> (BehaviorType, Int)? in
                guard let behavior = behaviorTypes.first(where: { $0.id == id }) else { return nil }
                return (behavior, count)
            }

        return ChildInsightsData(
            positiveCount: positiveEvents.count,
            negativeCount: negativeEvents.count,
            totalPositive: totalPositive,
            totalNegative: totalNegative,
            netPoints: totalPositive + totalNegative,
            dailyData: dailyData,
            topPositiveBehaviors: topPositive,
            topChallengeBehaviors: topChallenges
        )
    }

    // MARK: - Analytics Service Integration

    /// Get improvement suggestions for a child
    /// Preserves exact logic from FamilyViewModel.improvementSuggestions(forChild:)
    func improvementSuggestions(
        forChild child: Child,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> [ImprovementSuggestion] {
        let allSuggestions = AnalyticsService.improvementSuggestions(
            events: behaviorEvents,
            behaviorTypes: behaviorTypes,
            child: child
        )

        // Filter out suggestions for behaviors that are already active routines
        return allSuggestions.filter { suggestion in
            // Always show reduceNegative suggestions (they don't have "add" actions)
            if suggestion.type == .reduceNegative {
                return true
            }

            // For tryNew and increaseRoutine, filter out already-active behaviors
            let state = routineState(for: suggestion, behaviorTypes: behaviorTypes)
            return state != .alreadyActive
        }
    }

    /// Determine the state of a behavior for a suggestion
    /// Preserves exact logic from FamilyViewModel.routineState(for:)
    func routineState(for suggestion: ImprovementSuggestion, behaviorTypes: [BehaviorType]) -> RoutineState {
        // Find existing behavior by name (case-insensitive)
        let existingBehavior = behaviorTypes.first {
            $0.name.lowercased() == suggestion.behaviorType.name.lowercased()
        }

        guard let existing = existingBehavior else {
            return .notCreated
        }

        return existing.isActive ? .alreadyActive : .existsNotActive
    }

    /// Get weekly summary for a child
    /// Preserves exact logic from FamilyViewModel.weeklySummary(forChild:)
    func weeklySummary(
        forChild childId: UUID,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> AnalyticsService.WeeklySummary? {
        AnalyticsService.weeklySummary(
            events: behaviorEvents,
            behaviorTypes: behaviorTypes,
            childId: childId
        )
    }
}

/// State of a behavior relative to a suggestion action
/// Moved from FamilyViewModel
enum RoutineState {
    case notCreated      // Behavior doesn't exist yet
    case existsNotActive // Behavior exists but is not active
    case alreadyActive   // Behavior exists and is already active
}

/// Insights Data Model
/// Moved from FamilyViewModel
struct ChildInsightsData {
    let positiveCount: Int
    let negativeCount: Int
    let totalPositive: Int
    let totalNegative: Int
    let netPoints: Int
    let dailyData: [Date: Int]
    let topPositiveBehaviors: [(BehaviorType, Int)]
    let topChallengeBehaviors: [(BehaviorType, Int)]

    var hasEnoughData: Bool {
        positiveCount + negativeCount >= 3
    }

    func generateInsightSentence(childName: String) -> String {
        guard hasEnoughData else {
            return "Not enough moments yet. Start adding moments and we'll show insights here."
        }

        var parts: [String] = []
        parts.append("\(childName) had \(positiveCount) positive moment\(positiveCount == 1 ? "" : "s")")

        if negativeCount > 0 {
            parts.append("and \(negativeCount) challenge\(negativeCount == 1 ? "" : "s")")
        }

        var sentence = parts.joined(separator: " ") + "."

        // Add behavior insight
        if let topBehavior = topPositiveBehaviors.first {
            sentence += " Great job with \"\(topBehavior.0.name)\"!"
        }

        return sentence
    }
}
