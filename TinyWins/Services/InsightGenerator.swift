import Foundation
import SwiftUI

// MARK: - InsightGenerator

/// Generates natural language insights from behavior data.
/// Creates "AI-style" summaries and actionable observations.
final class InsightGenerator {

    private let insightsService = AdvancedInsightsService()
    private let traitService = TraitAnalysisService()

    // MARK: - Main Insight

    /// Generate the primary insight for a child.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - childName: The child's name
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    /// - Returns: Primary insight string
    func generateMainInsight(
        childId: UUID,
        childName: String,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> Insight {
        let momentum = insightsService.calculateMomentumScore(childId: childId, events: events)
        let trajectory = insightsService.calculateWeeklyTrajectory(childId: childId, events: events)
        let peaks = insightsService.findPeakPerformanceTimes(childId: childId, events: events)
        let topTraits = traitService.topTraits(childId: childId, events: events, behaviorTypes: behaviorTypes)

        // Determine the most impactful insight
        if trajectory.percentChange > 20 {
            return Insight(
                icon: "chart.line.uptrend.xyaxis",
                title: "On a Roll!",
                message: "\(childName) is up \(Int(trajectory.percentChange))% from last week. Keep noticing those wins!",
                type: .positive
            )
        }

        if let strongestTrait = topTraits.first, strongestTrait.score > 60 {
            return Insight(
                icon: strongestTrait.trait.icon,
                title: "Character Spotlight",
                message: "\(childName) is showing strong \(strongestTrait.displayName.lowercased()) this month with \(strongestTrait.eventCount) related behaviors.",
                type: .character
            )
        }

        if let topPeak = peaks.first {
            return Insight(
                icon: "clock.fill",
                title: "Peak Performance",
                message: "\(childName) shows the most positive behaviors on \(topPeak.dayName) around \(topPeak.timeString).",
                type: .pattern
            )
        }

        if momentum.score > 70 {
            return Insight(
                icon: "flame.fill",
                title: "Strong Momentum",
                message: "\(childName)'s momentum score is \(Int(momentum.score)) - consistent logging is paying off!",
                type: .positive
            )
        }

        // Default insight
        return Insight(
            icon: "lightbulb.fill",
            title: "Keep Watching",
            message: "Log more behaviors to unlock personalized insights for \(childName).",
            type: .neutral
        )
    }

    // MARK: - All Insights

    /// Generate all available insights for a child.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - childName: The child's name
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    /// - Returns: Array of insights ordered by importance
    func generateAllInsights(
        childId: UUID,
        childName: String,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> [Insight] {
        var insights: [Insight] = []

        // Momentum insight
        let momentum = insightsService.calculateMomentumScore(childId: childId, events: events)
        insights.append(generateMomentumInsight(momentum: momentum, childName: childName))

        // Trajectory insight
        let trajectory = insightsService.calculateWeeklyTrajectory(childId: childId, events: events)
        if let insight = generateTrajectoryInsight(trajectory: trajectory, childName: childName) {
            insights.append(insight)
        }

        // Balance insight
        let balance = insightsService.calculateBalanceIndex(
            childId: childId,
            events: events,
            behaviorTypes: behaviorTypes
        )
        if let insight = generateBalanceInsight(balance: balance, childName: childName) {
            insights.append(insight)
        }

        // Peak time insight
        let peaks = insightsService.findPeakPerformanceTimes(childId: childId, events: events)
        if let insight = generatePeakTimeInsight(peaks: peaks, childName: childName) {
            insights.append(insight)
        }

        // Challenge pattern insight
        let patterns = insightsService.identifyChallengePatterns(
            childId: childId,
            events: events,
            behaviorTypes: behaviorTypes
        )
        if let insight = generateChallengeInsight(patterns: patterns, childName: childName) {
            insights.append(insight)
        }

        // Character trait insight
        let topTraits = traitService.topTraits(
            childId: childId,
            events: events,
            behaviorTypes: behaviorTypes
        )
        if let insight = generateTraitInsight(traits: topTraits, childName: childName) {
            insights.append(insight)
        }

        // Emerging traits insight
        let emerging = traitService.emergingTraits(
            childId: childId,
            events: events,
            behaviorTypes: behaviorTypes
        )
        if let insight = generateEmergingTraitInsight(trends: emerging, childName: childName) {
            insights.append(insight)
        }

        // Streak insight
        let streakInsight = generateStreakInsight(childId: childId, events: events, childName: childName)
        if let insight = streakInsight {
            insights.append(insight)
        }

        return insights.filter { $0.type != .neutral }
    }

    // MARK: - Individual Insight Generators

    private func generateMomentumInsight(momentum: MomentumScore, childName: String) -> Insight {
        let icon: String
        let title: String
        let message: String
        let type: InsightType

        switch momentum.score {
        case 80...100:
            icon = "flame.fill"
            title = "Excellent Momentum"
            message = "\(childName) is on fire with a momentum score of \(Int(momentum.score))!"
            type = .positive
        case 60..<80:
            icon = "chart.line.uptrend.xyaxis"
            title = "Good Progress"
            message = "\(childName)'s momentum is strong at \(Int(momentum.score)). Keep it up!"
            type = .positive
        case 40..<60:
            icon = "chart.line.flattrend.xyaxis"
            title = "Steady Progress"
            message = "\(childName)'s momentum is \(Int(momentum.score)). Try logging more consistently."
            type = .neutral
        default:
            icon = "exclamationmark.triangle"
            title = "Needs Attention"
            message = "Log more behaviors to build momentum for \(childName)."
            type = .attention
        }

        return Insight(icon: icon, title: title, message: message, type: type)
    }

    private func generateTrajectoryInsight(trajectory: WeeklyTrajectory, childName: String) -> Insight? {
        guard trajectory.lastWeekPoints > 0 || trajectory.thisWeekPoints > 0 else { return nil }

        if trajectory.percentChange > 25 {
            return Insight(
                icon: "arrow.up.right.circle.fill",
                title: "Week Over Week",
                message: "\(childName) earned \(trajectory.percentChange > 0 ? "+" : "")\(Int(trajectory.percentChange))% more stars than last week!",
                type: .positive
            )
        }

        if trajectory.percentChange < -25 {
            return Insight(
                icon: "arrow.down.right.circle.fill",
                title: "Dip This Week",
                message: "\(childName)'s stars are down \(Int(abs(trajectory.percentChange)))% - a natural fluctuation.",
                type: .attention
            )
        }

        return nil
    }

    private func generateBalanceInsight(balance: BalanceIndex, childName: String) -> Insight? {
        guard balance.totalEvents >= 5 else { return nil }

        if balance.challengeRatio > 0.4 {
            return Insight(
                icon: "scale.3d",
                title: "Balance Check",
                message: "Try noticing more positive behaviors - \(childName) has had more challenges than wins lately.",
                type: .attention
            )
        }

        if balance.positiveRatio > 0.6 {
            return Insight(
                icon: "scale.3d",
                title: "Great Balance",
                message: "\(childName) has a healthy ratio of wins to challenges this week.",
                type: .positive
            )
        }

        return nil
    }

    private func generatePeakTimeInsight(peaks: [PeakTimeSlot], childName: String) -> Insight? {
        guard let topPeak = peaks.first, topPeak.eventCount >= 3 else { return nil }

        return Insight(
            icon: "clock.fill",
            title: "Best Time for Wins",
            message: "\(childName) tends to shine on \(topPeak.dayName) afternoons around \(topPeak.timeString).",
            type: .pattern
        )
    }

    private func generateChallengeInsight(patterns: [ChallengePattern], childName: String) -> Insight? {
        guard let topPattern = patterns.first else { return nil }

        return Insight(
            icon: "lightbulb.fill",
            title: "Pattern Detected",
            message: "\(topPattern.description) - \(topPattern.insight)",
            type: .pattern
        )
    }

    private func generateTraitInsight(traits: [TraitScore], childName: String) -> Insight? {
        guard let topTrait = traits.first, topTrait.score > 50 else { return nil }

        return Insight(
            icon: topTrait.trait.icon,
            title: "Character Strength",
            message: "\(childName) is developing strong \(topTrait.displayName.lowercased()) with \(topTrait.eventCount) related behaviors.",
            type: .character
        )
    }

    private func generateEmergingTraitInsight(trends: [TraitTrend], childName: String) -> Insight? {
        guard let growing = trends.first(where: { $0.isGrowing && $0.percentChange > 20 }) else {
            return nil
        }

        return Insight(
            icon: "arrow.up.forward.circle.fill",
            title: "Emerging Trait",
            message: "\(childName)'s \(growing.trait.displayName.lowercased()) is growing - up \(Int(growing.percentChange))% recently!",
            type: .character
        )
    }

    private func generateStreakInsight(childId: UUID, events: [BehaviorEvent], childName: String) -> Insight? {
        let calendar = Calendar.current
        var currentStreak = 0
        var date = Date()

        // Count consecutive days with positive events
        for _ in 0..<30 {
            let dayEvents = events.filter {
                $0.childId == childId &&
                calendar.isDate($0.timestamp, inSameDayAs: date) &&
                $0.pointsApplied > 0
            }

            if dayEvents.isEmpty {
                break
            }

            currentStreak += 1
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }

        guard currentStreak >= 3 else { return nil }

        return Insight(
            icon: "flame.fill",
            title: "\(currentStreak) Days of Positive Moments!",
            message: "\(childName) has had positive moments \(currentStreak) days in a row. Keep noticing the good!",
            type: .positive
        )
    }
}

// MARK: - Insight Type

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let type: InsightType
}

enum InsightType {
    case positive
    case attention
    case pattern
    case character
    case neutral

    var color: InsightColor {
        switch self {
        case .positive: return .green
        case .attention: return .orange
        case .pattern: return .blue
        case .character: return .purple
        case .neutral: return .gray
        }
    }
}

enum InsightColor {
    case green, orange, blue, purple, gray

    var swiftUIColor: SwiftUI.Color {
        switch self {
        case .green: return .green
        case .orange: return .orange
        case .blue: return .blue
        case .purple: return .purple
        case .gray: return .gray
        }
    }
}
