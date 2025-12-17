import Foundation
import SwiftUI

/// Use case for generating insights from behavior data.
/// Extracts complex insight generation logic from FamilyInsightsView.
@MainActor
final class InsightGenerationUseCase {

    // MARK: - Dependencies

    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore

    // MARK: - Initialization

    init(behaviorsStore: BehaviorsStore, childrenStore: ChildrenStore) {
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
    }

    // MARK: - Quick Insight

    struct QuickInsight {
        let icon: String
        let title: String
        let message: String
        let gradient: [Color]
    }

    /// Generate a quick insight summary based on positive/total ratio.
    func generateQuickInsight(for period: InsightPeriod) -> QuickInsight? {
        let range = period.dateRange
        let periodEvents = behaviorsStore.behaviorEvents.filter {
            $0.timestamp >= range.start && $0.timestamp <= range.end
        }
        let positive = periodEvents.filter { $0.pointsApplied > 0 }.count
        let total = periodEvents.count

        guard total > 0 else { return nil }

        let ratio = Double(positive) / Double(total)

        if ratio >= 0.8 {
            return QuickInsight(
                icon: "star.fill",
                title: "Stellar Week!",
                message: "You're noticing \(Int(ratio * 100))% positive moments. Keep it up!",
                gradient: [.yellow, .orange]
            )
        } else if ratio >= 0.6 {
            return QuickInsight(
                icon: "hand.thumbsup.fill",
                title: "Great Balance",
                message: "Healthy mix of wins and growth opportunities this week.",
                gradient: [.green, .mint]
            )
        } else if ratio >= 0.4 {
            return QuickInsight(
                icon: "lightbulb.fill",
                title: "Room to Grow",
                message: "Try catching a few more positive moments today.",
                gradient: [.blue, .cyan]
            )
        } else {
            return QuickInsight(
                icon: "heart.fill",
                title: "Tough Week?",
                message: "Look for small wins. They add up to big changes.",
                gradient: [.purple, .pink]
            )
        }
    }

    // MARK: - Aha Insights

    struct AhaInsight {
        let icon: String
        let gradient: [Color]
        let title: String
        let message: String
        let actionable: String?
    }

    /// Generate "aha moment" insights from behavior patterns.
    func generateAhaInsights(for period: InsightPeriod) -> [AhaInsight] {
        var insights: [AhaInsight] = []
        let range = period.dateRange
        let periodEvents = behaviorsStore.behaviorEvents.filter {
            $0.timestamp >= range.start && $0.timestamp <= range.end
        }

        guard periodEvents.count >= 5 else { return [] }

        // Time of day analysis
        var timeOfDay: [String: (positive: Int, negative: Int)] = [
            "Morning": (0, 0),
            "Afternoon": (0, 0),
            "Evening": (0, 0)
        ]

        for event in periodEvents {
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            let time = hour < 12 ? "Morning" : (hour < 17 ? "Afternoon" : "Evening")
            if event.pointsApplied > 0 {
                timeOfDay[time]?.positive += 1
            } else {
                timeOfDay[time]?.negative += 1
            }
        }

        // Find challenge hot spot
        if let (peakTime, data) = timeOfDay.max(by: { $0.value.negative < $1.value.negative }),
           data.negative >= 3 {
            let tip: String
            switch peakTime {
            case "Morning":
                tip = "Try adjusting the morning routine or wake-up time."
            case "Afternoon":
                tip = "A snack or quiet time might help the afternoon slump."
            default:
                tip = "Wind-down activities before dinner may reduce friction."
            }

            insights.append(AhaInsight(
                icon: "clock.fill",
                gradient: [.orange, .red.opacity(0.8)],
                title: "Challenge Hotspot: \(peakTime)s",
                message: "\(data.negative) challenges happen in the \(peakTime.lowercased()).",
                actionable: tip
            ))
        }

        // Find strength time
        if let (peakTime, data) = timeOfDay.max(by: { $0.value.positive < $1.value.positive }),
           data.positive >= 3 {
            insights.append(AhaInsight(
                icon: "sun.max.fill",
                gradient: [.yellow, .orange],
                title: "Best Time: \(peakTime)s",
                message: "Most positive moments happen in the \(peakTime.lowercased()).",
                actionable: "Schedule important conversations during this time."
            ))
        }

        // Multi-child comparison
        if childrenStore.activeChildren.count > 1 {
            var childCounts: [UUID: Int] = [:]
            for event in periodEvents {
                childCounts[event.childId, default: 0] += 1
            }

            let sorted = childCounts.sorted { $0.value > $1.value }
            if sorted.count >= 2 {
                let top = sorted[0]
                let bottom = sorted[sorted.count - 1]

                if top.value > bottom.value * 2,
                   let topChild = childrenStore.child(id: top.key),
                   let bottomChild = childrenStore.child(id: bottom.key) {
                    // Supportive, opt-in framing - not scolding
                    insights.append(AhaInsight(
                        icon: "person.2.fill",
                        gradient: [.blue, .cyan],
                        title: "Attention Balance",
                        message: "You've logged more moments for \(topChild.name) lately.",
                        actionable: "Want a gentle nudge to notice \(bottomChild.name) too?"
                    ))
                }
            }
        }

        return Array(insights.prefix(3))
    }

    // MARK: - Positivity Analysis

    /// Generate positivity message based on ratio.
    func positivityMessage(ratio: Double) -> String {
        if ratio >= 3 {
            return "A strong positive pattern!"
        } else if ratio >= 1.5 {
            return "A healthy balance of moments."
        } else {
            return "Every moment noticed matters."
        }
    }

    // MARK: - Period Stats

    struct PeriodStats {
        let positiveCount: Int
        let challengeCount: Int
        let totalPoints: Int
        let events: [BehaviorEvent]
    }

    /// Calculate statistics for a given period.
    func calculatePeriodStats(for period: InsightPeriod) -> PeriodStats {
        let range = period.dateRange
        let events = behaviorsStore.behaviorEvents.filter {
            $0.timestamp >= range.start && $0.timestamp <= range.end
        }
        let positiveCount = events.filter { $0.pointsApplied > 0 }.count
        let challengeCount = events.filter { $0.pointsApplied < 0 }.count
        let totalPoints = events.reduce(0) { $0 + $1.pointsApplied }

        return PeriodStats(
            positiveCount: positiveCount,
            challengeCount: challengeCount,
            totalPoints: totalPoints,
            events: events
        )
    }

    // MARK: - Child Deep Dive

    struct ChildDeepDiveData {
        let child: Child
        let positiveEvents: [BehaviorEvent]
        let challengeEvents: [BehaviorEvent]
        let topWinBehavior: BehaviorType?
        let topWinCount: Int
        let topChallengeBehavior: BehaviorType?
        let topChallengeCount: Int
    }

    /// Generate deep dive analysis for a specific child.
    func generateChildDeepDive(for child: Child, period: InsightPeriod) -> ChildDeepDiveData {
        let range = period.dateRange
        let events = behaviorsStore.behaviorEvents.filter {
            $0.childId == child.id &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }
        let positiveEvents = events.filter { $0.pointsApplied > 0 }
        let challengeEvents = events.filter { $0.pointsApplied < 0 }

        // Find biggest win
        var winCounts: [UUID: Int] = [:]
        for event in positiveEvents {
            winCounts[event.behaviorTypeId, default: 0] += 1
        }
        let topWin = winCounts.max(by: { $0.value < $1.value })
        let topWinBehavior = topWin.flatMap { behaviorsStore.behaviorType(id: $0.key) }

        // Find biggest challenge
        var challengeCounts: [UUID: Int] = [:]
        for event in challengeEvents {
            challengeCounts[event.behaviorTypeId, default: 0] += 1
        }
        let topChallenge = challengeCounts.max(by: { $0.value < $1.value })
        let topChallengeBehavior = topChallenge.flatMap { behaviorsStore.behaviorType(id: $0.key) }

        return ChildDeepDiveData(
            child: child,
            positiveEvents: positiveEvents,
            challengeEvents: challengeEvents,
            topWinBehavior: topWinBehavior,
            topWinCount: topWin?.value ?? 0,
            topChallengeBehavior: topChallengeBehavior,
            topChallengeCount: topChallenge?.value ?? 0
        )
    }

    // MARK: - Daily Activity Data

    struct DailyActivityData {
        let date: Date
        let positive: Int
        let negative: Int
    }

    /// Generate daily activity data for chart display.
    func generateDailyActivityData(for period: InsightPeriod, maxDays: Int = 7) -> [DailyActivityData] {
        let range = period.dateRange
        let events = behaviorsStore.behaviorEvents.filter {
            $0.timestamp >= range.start && $0.timestamp <= range.end
        }

        let calendar = Calendar.current
        var dailyData: [DailyActivityData] = []
        var current = range.start

        while current <= range.end {
            let dayStart = calendar.startOfDay(for: current)
            let dayEvents = events.filter { calendar.isDate($0.timestamp, inSameDayAs: dayStart) }
            let positive = dayEvents.filter { $0.pointsApplied > 0 }.count
            let negative = dayEvents.filter { $0.pointsApplied < 0 }.count
            dailyData.append(DailyActivityData(date: dayStart, positive: positive, negative: negative))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
        }

        return Array(dailyData.suffix(maxDays))
    }
}
