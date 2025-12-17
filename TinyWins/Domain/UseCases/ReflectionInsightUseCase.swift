import Foundation
import SwiftUI

/// Use case for generating insights from parent reflection data.
/// Computes top strengths, correlation with positive moments, and month-in-review summaries.
@MainActor
final class ReflectionInsightUseCase {

    // MARK: - Dependencies

    private let repository: Repository
    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore

    private let calendar = Calendar.current

    // MARK: - Initialization

    init(repository: Repository, behaviorsStore: BehaviorsStore, childrenStore: ChildrenStore) {
        self.repository = repository
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
    }

    // MARK: - Parent Strength Insight

    struct TopStrengthInsight {
        let strength: String
        let count: Int
        let period: String
    }

    /// Find the most selected parent win for a given period.
    func topStrength(days: Int) -> TopStrengthInsight? {
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let notes = repository.getParentNotes(from: startDate, to: Date())
            .filter { $0.noteType == .parentWin }

        guard !notes.isEmpty else { return nil }

        // Count occurrences of each win
        var winCounts: [String: Int] = [:]
        for note in notes {
            winCounts[note.content, default: 0] += 1
        }

        guard let topWin = winCounts.max(by: { $0.value < $1.value }) else { return nil }

        let periodString = days == 7 ? "this week" : (days == 30 ? "this month" : "last \(days) days")

        return TopStrengthInsight(
            strength: simplifyWinText(topWin.key),
            count: topWin.value,
            period: periodString
        )
    }

    /// Simplify long win text for display
    private func simplifyWinText(_ text: String) -> String {
        // Map common phrases to shorter versions
        let simplifications: [String: String] = [
            "I stayed calm during a difficult moment": "Staying calm",
            "I praised effort instead of just results": "Praising effort",
            "I listened without interrupting": "Active listening",
            "I gave a genuine hug today": "Showing affection",
            "I apologized when I was wrong": "Apologizing",
            "I took a breather when I needed one": "Taking breaks",
            "I celebrated a small win": "Celebrating wins",
            "I was patient when things were hard": "Being patient"
        ]
        return simplifications[text] ?? text
    }

    // MARK: - Reflection Correlation Insight

    struct CorrelationInsight {
        let percentageMorePositive: Int
        let daysAnalyzed: Int
        let message: String
    }

    /// Calculate correlation between reflection days and positive moments.
    /// Returns nil if not enough data or no meaningful correlation.
    func reflectionCorrelation(days: Int = 30) -> CorrelationInsight? {
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Get days with reflections
        let daysWithReflections = repository.getDaysWithReflections(from: startDate, to: Date())

        guard daysWithReflections.count >= 5 else { return nil } // Need enough data

        // Get behavior events grouped by day
        let events = behaviorsStore.behaviorEvents.filter { $0.timestamp >= startDate }
        let eventsByDay = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.timestamp)
        }

        // Calculate positive ratio on reflection vs non-reflection days
        var reflectionDayPositiveRatio: Double = 0
        var reflectionDayCount: Int = 0
        var nonReflectionDayPositiveRatio: Double = 0
        var nonReflectionDayCount: Int = 0

        // Iterate through all days in the period
        var currentDate = startDate
        while currentDate <= Date() {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEvents = eventsByDay[dayStart] ?? []

            if !dayEvents.isEmpty {
                let positiveCount = dayEvents.filter { $0.pointsApplied > 0 }.count
                let ratio = Double(positiveCount) / Double(dayEvents.count)

                if daysWithReflections.contains(dayStart) {
                    reflectionDayPositiveRatio += ratio
                    reflectionDayCount += 1
                } else {
                    nonReflectionDayPositiveRatio += ratio
                    nonReflectionDayCount += 1
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Need data from both types of days
        guard reflectionDayCount >= 3 && nonReflectionDayCount >= 3 else { return nil }

        let avgReflectionDayRatio = reflectionDayPositiveRatio / Double(reflectionDayCount)
        let avgNonReflectionDayRatio = nonReflectionDayPositiveRatio / Double(nonReflectionDayCount)

        // Only show if reflection days are better (no shaming)
        guard avgReflectionDayRatio > avgNonReflectionDayRatio else { return nil }

        let percentageDiff = Int((avgReflectionDayRatio - avgNonReflectionDayRatio) * 100)

        // Only show if difference is meaningful
        guard percentageDiff >= 5 else { return nil }

        return CorrelationInsight(
            percentageMorePositive: percentageDiff,
            daysAnalyzed: days,
            message: "Days you reflect tend to have \(percentageDiff)% more positive moments logged."
        )
    }

    // MARK: - Month in Review

    struct MonthInReview {
        let month: String
        let totalReflections: Int
        let reflectionStreak: Int
        let topStrengths: [String]
        let totalPositiveMoments: Int
        let mostActiveDayOfWeek: String?
    }

    /// Generate a month-in-review summary for Plus subscribers.
    func generateMonthInReview(for date: Date = Date()) -> MonthInReview? {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return nil
        }

        // Get notes for the month
        let notes = repository.getParentNotes(from: monthStart, to: monthEnd)

        guard !notes.isEmpty else { return nil }

        // Total reflections
        let totalReflections = Set(notes.map { calendar.startOfDay(for: $0.date) }).count

        // Calculate streak for this month
        let daysWithReflections = Set(notes.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var currentDate = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        while daysWithReflections.contains(calendar.startOfDay(for: currentDate)) && currentDate >= monthStart {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? monthStart
        }

        // Top strengths
        let parentWins = notes.filter { $0.noteType == .parentWin }
        var winCounts: [String: Int] = [:]
        for note in parentWins {
            winCounts[note.content, default: 0] += 1
        }
        let topStrengths = winCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { simplifyWinText($0.key) }

        // Total positive moments logged
        let events = behaviorsStore.behaviorEvents.filter { $0.timestamp >= monthStart && $0.timestamp < monthEnd }
        let totalPositive = events.filter { $0.pointsApplied > 0 }.count

        // Most active day of week for reflections
        var dayOfWeekCounts: [Int: Int] = [:]
        for note in notes {
            let weekday = calendar.component(.weekday, from: note.date)
            dayOfWeekCounts[weekday, default: 0] += 1
        }
        let mostActiveWeekday = dayOfWeekCounts.max { $0.value < $1.value }?.key
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let mostActiveDayName: String? = mostActiveWeekday.map { weekday in
            var components = DateComponents()
            components.weekday = weekday
            if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
                return dayFormatter.string(from: date)
            }
            return nil
        } ?? nil

        // Month name
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthName = monthFormatter.string(from: date)

        return MonthInReview(
            month: monthName,
            totalReflections: totalReflections,
            reflectionStreak: streak,
            topStrengths: Array(topStrengths),
            totalPositiveMoments: totalPositive,
            mostActiveDayOfWeek: mostActiveDayName
        )
    }

    // MARK: - All Insights Summary

    struct ParentInsightsSummary {
        let topStrength: TopStrengthInsight?
        let correlation: CorrelationInsight?
        let monthInReview: MonthInReview?
        let currentStreak: Int
    }

    /// Generate all parent insights in one call.
    func generateAllInsights() -> ParentInsightsSummary {
        ParentInsightsSummary(
            topStrength: topStrength(days: 30),
            correlation: reflectionCorrelation(days: 30),
            monthInReview: generateMonthInReview(),
            currentStreak: repository.appData.calculateReflectionStreak()
        )
    }
}
