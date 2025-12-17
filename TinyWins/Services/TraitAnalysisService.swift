import Foundation

// MARK: - TraitAnalysisService

/// Service for calculating character trait scores from behavior events.
/// Powers the Growth Rings visualization.
final class TraitAnalysisService {

    // MARK: - Core Calculations

    /// Calculate trait scores for a child in a given time period.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - period: The time period to analyze
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    /// - Returns: Array of TraitScore sorted by score descending
    func calculateTraitScores(
        childId: UUID,
        period: TimePeriod,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> [TraitScore] {
        let range = period.dateRange

        // Filter events for this child in the time period
        let childEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end &&
            $0.pointsApplied > 0 // Only positive behaviors contribute to traits
        }

        // Group events by trait
        var traitData: [CharacterTrait: (count: Int, points: Int)] = [:]

        for event in childEvents {
            guard let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                continue
            }

            let traits = CharacterTrait.traitsForBehavior(behaviorType.name)

            for trait in traits {
                let current = traitData[trait] ?? (count: 0, points: 0)
                traitData[trait] = (
                    count: current.count + 1,
                    points: current.points + event.pointsApplied
                )
            }
        }

        // Calculate normalized scores (0-100)
        let maxPoints = traitData.values.map { $0.points }.max() ?? 1
        let normalizedMax = max(maxPoints, 1)

        return CharacterTrait.allCases.map { trait in
            let data = traitData[trait] ?? (count: 0, points: 0)
            let normalizedScore = Double(data.points) / Double(normalizedMax) * 100

            return TraitScore(
                trait: trait,
                score: normalizedScore,
                eventCount: data.count,
                totalPoints: data.points
            )
        }.sorted { $0.score > $1.score }
    }

    /// Calculate trait growth over time (monthly breakdown).
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    ///   - monthsBack: Number of months to analyze
    /// - Returns: Array of monthly trait data, oldest first
    func traitGrowthOverTime(
        childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        monthsBack: Int = 6
    ) -> [MonthlyTraitData] {
        let calendar = Calendar.current
        let now = Date()

        var monthlyData: [MonthlyTraitData] = []

        for monthOffset in (0..<monthsBack).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: -monthOffset + 1, to: now) else {
                continue
            }

            let startOfMonth = calendar.startOfMonth(for: monthStart)
            let endOfMonth = monthEnd

            // Filter events for this month
            let monthEvents = events.filter {
                $0.childId == childId &&
                $0.timestamp >= startOfMonth &&
                $0.timestamp < endOfMonth &&
                $0.pointsApplied > 0
            }

            // Calculate trait scores for this month
            var traitScores: [CharacterTrait: Double] = [:]

            for event in monthEvents {
                guard let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                    continue
                }

                let traits = CharacterTrait.traitsForBehavior(behaviorType.name)

                for trait in traits {
                    traitScores[trait, default: 0] += Double(event.pointsApplied)
                }
            }

            // Normalize scores
            let maxScore = traitScores.values.max() ?? 1
            let normalizedScores = traitScores.mapValues { $0 / max(maxScore, 1) * 100 }

            let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: startOfMonth) - 1]

            monthlyData.append(MonthlyTraitData(
                month: monthName,
                date: startOfMonth,
                traitScores: normalizedScores
            ))
        }

        return monthlyData
    }

    /// Identify traits that are growing (improving over recent periods).
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    /// - Returns: Array of growing traits with their trends
    func emergingTraits(
        childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> [TraitTrend] {
        // Compare last 2 weeks to previous 2 weeks
        let calendar = Calendar.current
        let now = Date()

        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now),
              let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: now) else {
            return []
        }

        // Current period events
        let currentEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= twoWeeksAgo &&
            $0.pointsApplied > 0
        }

        // Previous period events
        let previousEvents = events.filter {
            $0.childId == childId &&
            $0.timestamp >= fourWeeksAgo &&
            $0.timestamp < twoWeeksAgo &&
            $0.pointsApplied > 0
        }

        // Calculate scores for each period
        let currentScores = calculateScoresFromEvents(currentEvents, behaviorTypes: behaviorTypes)
        let previousScores = calculateScoresFromEvents(previousEvents, behaviorTypes: behaviorTypes)

        // Create trends
        return CharacterTrait.allCases.compactMap { trait in
            let current = currentScores[trait] ?? 0
            let previous = previousScores[trait] ?? 0

            // Only include traits with activity
            guard current > 0 || previous > 0 else { return nil }

            let isGrowing = current > previous

            return TraitTrend(
                trait: trait,
                currentScore: current,
                previousScore: previous,
                isGrowing: isGrowing
            )
        }.filter { $0.percentChange.magnitude > 5 } // Only significant changes
         .sorted { abs($0.percentChange) > abs($1.percentChange) }
    }

    /// Get the top N traits for a child.
    /// - Parameters:
    ///   - childId: The child's ID
    ///   - events: All behavior events
    ///   - behaviorTypes: Available behavior types
    ///   - limit: Maximum number of traits to return
    /// - Returns: Top traits by score
    func topTraits(
        childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        limit: Int = 3
    ) -> [TraitScore] {
        let scores = calculateTraitScores(
            childId: childId,
            period: .last3Months,
            events: events,
            behaviorTypes: behaviorTypes
        )

        return Array(scores.filter { $0.score > 0 }.prefix(limit))
    }

    // MARK: - Helper Methods

    private func calculateScoresFromEvents(
        _ events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> [CharacterTrait: Double] {
        var scores: [CharacterTrait: Double] = [:]

        for event in events {
            guard let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) else {
                continue
            }

            let traits = CharacterTrait.traitsForBehavior(behaviorType.name)

            for trait in traits {
                scores[trait, default: 0] += Double(event.pointsApplied)
            }
        }

        return scores
    }
}

// MARK: - Monthly Trait Data

/// Trait scores for a single month.
struct MonthlyTraitData: Identifiable {
    let id = UUID()
    let month: String
    let date: Date
    let traitScores: [CharacterTrait: Double]

    /// Get normalized score for a trait (0-1 range).
    func normalizedScore(for trait: CharacterTrait) -> Double {
        let score = traitScores[trait] ?? 0
        return min(score / 100.0, 1.0)
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
