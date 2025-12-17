import Foundation
import Combine
import SwiftUI

/// Store responsible for parent activity tracking, skill badges, special moments, and progression system.
/// Extracted from FamilyViewModel to provide focused progression state management.
@MainActor
final class ProgressionStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var parentActivity: ParentActivity = ParentActivity()
    @Published private(set) var skillBadges: [SkillBadge] = []
    @Published private(set) var specialMoments: [SpecialMoment] = []
    @Published var dailyPrompt: DailyPrompt? = nil
    @Published var lastPromptText: String? = nil

    // MARK: - Initialization

    init() {
        loadProgressionData()
    }

    // MARK: - Data Loading

    func loadProgressionData() {
        loadParentActivity()
        loadSkillBadges()
        loadSpecialMoments()
        refreshDailyPromptIfNeeded()
    }

    // MARK: - Parent Activity Tracking

    func recordParentActivity() {
        parentActivity.recordActivity()
        saveParentActivity()
    }

    private func saveParentActivity() {
        if let data = try? JSONEncoder().encode(parentActivity) {
            UserDefaults.standard.set(data, forKey: "parentActivity")
        }
    }

    private func loadParentActivity() {
        if let data = UserDefaults.standard.data(forKey: "parentActivity"),
           let activity = try? JSONDecoder().decode(ParentActivity.self, from: data) {
            parentActivity = activity
        }
    }

    // MARK: - Daily Prompt

    func refreshDailyPromptIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = parentActivity.lastPromptDate,
           calendar.isDate(lastDate, inSameDayAs: today) {
            // Already showed prompt today
            return
        }

        // Generate new prompt
        dailyPrompt = DailyPrompt.randomPrompt(excluding: lastPromptText)
        lastPromptText = dailyPrompt?.text
    }

    func dismissDailyPrompt() {
        parentActivity.lastPromptDate = Date()
        dailyPrompt = nil
        saveParentActivity()
    }

    /// Clear daily prompt (alias for compatibility)
    func clearDailyPrompt() {
        dismissDailyPrompt()
    }

    // MARK: - Bonus Star

    func canOfferBonusStar(forChild childId: UUID) -> Bool {
        parentActivity.canOfferBonusStar(forChild: childId)
    }

    func recordBonusStarGiven(forChild childId: UUID) {
        parentActivity.recordBonusStar(forChild: childId)
        saveParentActivity()
    }

    // Check if a behavior qualifies for bonus star (challenging behaviors)
    func behaviorQualifiesForBonus(_ behavior: BehaviorType) -> Bool {
        // Keywords that indicate challenging/difficult behaviors worth extra recognition
        let challengingKeywords = [
            "calm", "patient", "frustrat", "angry", "upset", "waiting", "wait",
            "share", "difficult", "hard", "challenge", "sibling", "conflict"
        ]

        let nameLower = behavior.name.lowercased()
        return behavior.defaultPoints > 0 && challengingKeywords.contains(where: { nameLower.contains($0) })
    }

    // MARK: - Skill Badges

    func badges(forChild childId: UUID) -> [SkillBadge] {
        skillBadges.filter { $0.childId == childId }
            .sorted { $0.earnedDate > $1.earnedDate }
    }

    func checkAndAwardBadges(
        forChild childId: UUID,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) {
        let childEvents = behaviorEvents.filter { $0.childId == childId && $0.pointsApplied > 0 }

        for badgeType in BadgeType.allCases {
            let matchingCount = countEventsMatchingBadge(badgeType, events: childEvents, behaviorTypes: behaviorTypes)

            // Check each level
            for level in 1...3 {
                let threshold = BadgeType.thresholdsForLevel(level)
                let hasThisLevel = skillBadges.contains {
                    $0.childId == childId && $0.type == badgeType && $0.level == level
                }

                if matchingCount >= threshold && !hasThisLevel {
                    // Award badge
                    let badge = SkillBadge(
                        childId: childId,
                        type: badgeType,
                        level: level,
                        behaviorCount: matchingCount
                    )
                    skillBadges.append(badge)
                    saveSkillBadges()
                }
            }
        }
    }

    private func countEventsMatchingBadge(
        _ badgeType: BadgeType,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> Int {
        var count = 0
        for event in events {
            if let behavior = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                let nameLower = behavior.name.lowercased()
                if badgeType.keywords.contains(where: { nameLower.contains($0) }) {
                    count += 1
                }
            }
        }
        return count
    }

    private func saveSkillBadges() {
        if let data = try? JSONEncoder().encode(skillBadges) {
            UserDefaults.standard.set(data, forKey: "skillBadges")
        }
    }

    private func loadSkillBadges() {
        if let data = UserDefaults.standard.data(forKey: "skillBadges"),
           let badges = try? JSONDecoder().decode([SkillBadge].self, from: data) {
            skillBadges = badges
        }
    }

    // MARK: - Special Moments

    func specialMoments(forChild childId: UUID) -> [SpecialMoment] {
        specialMoments.filter { $0.childId == childId }
            .sorted { $0.markedDate > $1.markedDate }
    }

    func isSpecialMoment(_ eventId: UUID) -> Bool {
        specialMoments.contains { $0.eventId == eventId }
    }

    func markAsSpecial(event: BehaviorEvent, caption: String? = nil) {
        guard !isSpecialMoment(event.id) else { return }

        let special = SpecialMoment(
            eventId: event.id,
            childId: event.childId,
            caption: caption
        )
        specialMoments.append(special)
        saveSpecialMoments()
    }

    func unmarkAsSpecial(eventId: UUID) {
        specialMoments.removeAll { $0.eventId == eventId }
        saveSpecialMoments()
    }

    private func saveSpecialMoments() {
        if let data = try? JSONEncoder().encode(specialMoments) {
            UserDefaults.standard.set(data, forKey: "specialMoments")
        }
    }

    private func loadSpecialMoments() {
        if let data = UserDefaults.standard.data(forKey: "specialMoments"),
           let moments = try? JSONDecoder().decode([SpecialMoment].self, from: data) {
            specialMoments = moments
        }
    }

    // MARK: - Parent Reinforcement Analytics

    /// Check if today's first positive/routine moment was just logged
    /// Preserves exact logic from FamilyViewModel
    func isFirstPositiveTodayForFamily(
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let positiveTodayCount = behaviorEvents.filter { event in
            let eventDay = calendar.startOfDay(for: event.timestamp)
            guard eventDay == today else { return false }

            // Check if positive or routine
            if let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                return behaviorType.category == .positive || behaviorType.category == .routinePositive
            }
            return event.pointsApplied > 0
        }.count

        return positiveTodayCount == 1
    }

    /// Weekly parent effort metrics
    /// Preserves exact logic from FamilyViewModel.weeklyParentMetrics()
    func weeklyParentMetrics(
        children: [Child],
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        rewards: [Reward]
    ) -> WeeklyParentMetrics {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let weekEvents = behaviorEvents.filter { $0.timestamp >= sevenDaysAgo }

        // Days with positive moments
        var daysWithPositive: Set<Date> = []
        for event in weekEvents {
            if let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                if behaviorType.category == .positive || behaviorType.category == .routinePositive {
                    daysWithPositive.insert(calendar.startOfDay(for: event.timestamp))
                }
            } else if event.pointsApplied > 0 {
                daysWithPositive.insert(calendar.startOfDay(for: event.timestamp))
            }
        }

        // Unique goals worked on
        var goalsWorkedOn: Set<UUID> = []
        for child in children {
            // Find active reward (lowest priority, not redeemed/expired)
            if let reward = rewards
                .filter({ $0.childId == child.id && !$0.isRedeemed && !$0.isExpired })
                .sorted(by: { $0.priority < $1.priority })
                .first {
                let progress = reward.pointsEarnedInWindow(from: weekEvents, isPrimaryReward: true)
                if progress > 0 {
                    goalsWorkedOn.insert(reward.id)
                }
            }
        }

        // Days with repair pattern (challenge + later positive same day same child)
        var daysWithRepair = 0
        let uniqueDays = Set(weekEvents.map { calendar.startOfDay(for: $0.timestamp) })

        for day in uniqueDays {
            for child in children {
                let dayEvents = weekEvents.filter {
                    $0.childId == child.id && calendar.startOfDay(for: $0.timestamp) == day
                }.sorted { $0.timestamp < $1.timestamp }

                // Check for challenge followed by positive
                var hadChallenge = false
                var hadPositiveAfterChallenge = false

                for event in dayEvents {
                    if let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                        if behaviorType.category == .negative {
                            hadChallenge = true
                        } else if hadChallenge && (behaviorType.category == .positive || behaviorType.category == .routinePositive) {
                            hadPositiveAfterChallenge = true
                            break
                        }
                    }
                }

                if hadPositiveAfterChallenge {
                    daysWithRepair += 1
                    break // Only count once per day
                }
            }
        }

        // Total positive moments
        let totalPositive = weekEvents.filter { event in
            if let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                return behaviorType.category == .positive || behaviorType.category == .routinePositive
            }
            return event.pointsApplied > 0
        }.count

        // Days active
        let daysActive = Set(weekEvents.map { calendar.startOfDay(for: $0.timestamp) }).count

        return WeeklyParentMetrics(
            daysWithPositiveMoments: daysWithPositive.count,
            uniqueGoalsWorkedOn: goalsWorkedOn.count,
            daysWithRepair: daysWithRepair,
            totalPositiveMoments: totalPositive,
            daysActive: daysActive
        )
    }

    /// Check if a child had a repair pattern today (challenge followed by positive)
    /// Preserves exact logic from FamilyViewModel
    func hasRepairPatternToday(
        forChild childId: UUID,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayEvents = behaviorEvents.filter { event in
            event.childId == childId && calendar.startOfDay(for: event.timestamp) == today
        }.sorted { $0.timestamp < $1.timestamp }

        var hadChallenge = false

        for event in todayEvents {
            if let behaviorType = behaviorTypes.first(where: { $0.id == event.behaviorTypeId }) {
                if behaviorType.category == .negative {
                    hadChallenge = true
                } else if hadChallenge && (behaviorType.category == .positive || behaviorType.category == .routinePositive) {
                    return true
                }
            }
        }

        return false
    }

    /// Days since last activity
    /// Preserves exact logic from FamilyViewModel
    func daysSinceLastActivity(behaviorEvents: [BehaviorEvent]) -> Int? {
        guard let lastEvent = behaviorEvents.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let lastEventDay = calendar.startOfDay(for: lastEvent.timestamp)
        let today = calendar.startOfDay(for: now)

        return calendar.dateComponents([.day], from: lastEventDay, to: today).day
    }

    // MARK: - Yearly Summary

    func yearlySummary(
        forChild childId: UUID,
        year: Int? = nil,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        rewards: [Reward]
    ) -> YearlySummary {
        let targetYear = year ?? Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current

        let yearEvents = behaviorEvents.filter { event in
            event.childId == childId &&
            calendar.component(.year, from: event.timestamp) == targetYear
        }

        let positiveEvents = yearEvents.filter { $0.pointsApplied > 0 }
        let challengeEvents = yearEvents.filter { $0.pointsApplied < 0 }

        // Count by behavior type
        var behaviorCounts: [UUID: Int] = [:]
        for event in positiveEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }

        // Get top 3 behaviors
        let sortedBehaviors = behaviorCounts.sorted { $0.value > $1.value }
        let topStrengths = sortedBehaviors.prefix(3).compactMap { entry -> String? in
            behaviorTypes.first(where: { $0.id == entry.key })?.name
        }

        // Check for improved area (simplified: any challenge behavior that decreased)
        let improvedArea: String? = nil // Would need previous year comparison

        let yearRewards = rewards.filter { reward in
            reward.childId == childId &&
            reward.isRedeemed &&
            reward.redeemedDate.map { calendar.component(.year, from: $0) == targetYear } ?? false
        }

        let specialCount = specialMoments.filter { moment in
            moment.childId == childId &&
            calendar.component(.year, from: moment.markedDate) == targetYear
        }.count

        return YearlySummary(
            year: targetYear,
            childId: childId,
            totalPositiveMoments: positiveEvents.count,
            totalChallenges: challengeEvents.count,
            goalsCompleted: yearRewards.count,
            topStrengths: topStrengths,
            improvedArea: improvedArea,
            specialMomentsCount: specialCount
        )
    }

    // MARK: - Pattern-Based Bonus Insights

    /// Check for patterns after logging and generate bonus insights (shown occasionally)
    /// Preserves exact logic from FamilyViewModel including the randomness
    func checkForBonusInsight(
        childId: UUID,
        child: Child?,
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> BonusInsight? {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        // Get recent positive events for this child
        let recentEvents = behaviorEvents.filter { event in
            event.childId == childId &&
            event.pointsApplied > 0 &&
            event.timestamp > oneWeekAgo
        }

        // Only show insights occasionally (1 in 5 chance when patterns exist)
        guard Int.random(in: 1...5) == 1 else { return nil }

        // Count by behavior type
        var behaviorCounts: [UUID: Int] = [:]
        for event in recentEvents {
            behaviorCounts[event.behaviorTypeId, default: 0] += 1
        }

        // Find patterns (behaviors logged 3+ times)
        for (behaviorId, count) in behaviorCounts where count >= 3 {
            guard let behavior = behaviorTypes.first(where: { $0.id == behaviorId }),
                  let child = child else { continue }

            // Generate insight based on behavior type
            let insightData = generateInsightForBehavior(behavior, count: count, childName: child.name)
            if let insight = insightData {
                return insight
            }
        }

        // Check for improvement patterns
        if recentEvents.count >= 5 {
            // More positive moments than usual
            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
            let previousWeekEvents = behaviorEvents.filter { event in
                event.childId == childId &&
                event.pointsApplied > 0 &&
                event.timestamp > twoWeeksAgo &&
                event.timestamp <= oneWeekAgo
            }

            if recentEvents.count > previousWeekEvents.count + 3 {
                if let child = child {
                    return BonusInsight(
                        title: "Great Progress!",
                        message: "You've been noticing more positive moments for \(child.name) this week!",
                        suggestion: "Keep it up - consistency builds habits.",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                }
            }
        }

        return nil
    }

    private func generateInsightForBehavior(_ behavior: BehaviorType, count: Int, childName: String) -> BonusInsight? {
        let nameLower = behavior.name.lowercased()

        // Helper-related behaviors
        if nameLower.contains("help") || nameLower.contains("sibling") {
            return BonusInsight(
                title: "Helping Pattern Spotted!",
                message: "You logged '\(behavior.name)' \(count) times this week for \(childName).",
                suggestion: "Consider a sibling-focused reward like a special activity together.",
                icon: "hands.sparkles.fill",
                color: .green
            )
        }

        // Bedtime-related
        if nameLower.contains("bed") || nameLower.contains("sleep") || nameLower.contains("night") {
            return BonusInsight(
                title: "Bedtime Hero Emerging!",
                message: "\(childName) has been great at bedtime \(count) times this week!",
                suggestion: "A bedtime-related reward like 'Extra story time' could motivate more.",
                icon: "moon.stars.fill",
                color: .indigo
            )
        }

        // Sharing-related
        if nameLower.contains("share") || nameLower.contains("gave") {
            return BonusInsight(
                title: "Sharing Star! ",
                message: "\(childName) has been sharing well - \(count) times this week!",
                suggestion: "Celebrate this with specific praise about what they shared.",
                icon: "gift.fill",
                color: .purple
            )
        }

        // Patience/calm-related
        if nameLower.contains("calm") || nameLower.contains("patient") || nameLower.contains("wait") {
            return BonusInsight(
                title: "Patience Growing!",
                message: "\(childName) is showing more patience - \(count) moments this week!",
                suggestion: "This is a challenging skill. Consider extra recognition.",
                icon: "heart.fill",
                color: .pink
            )
        }

        // Generic pattern for other behaviors
        if count >= 4 {
            return BonusInsight(
                title: "Pattern Found!",
                message: "'\(behavior.name)' is becoming a strength for \(childName).",
                suggestion: nil,
                icon: "star.fill",
                color: .yellow
            )
        }

        return nil
    }
}

/// Weekly parent effort metrics
/// Moved from FamilyViewModel
struct WeeklyParentMetrics {
    let daysWithPositiveMoments: Int
    let uniqueGoalsWorkedOn: Int
    let daysWithRepair: Int // Days with challenge + later positive for same child
    let totalPositiveMoments: Int
    let daysActive: Int
}

/// Bonus insight for pattern detection
/// Moved from FamilyViewModel
struct BonusInsight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let suggestion: String?
    let icon: String
    let color: Color
}
