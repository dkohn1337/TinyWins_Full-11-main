import Foundation
import Combine

// MARK: - Today's Focus Model

/// A personalized focus tip generated from behavior data
struct TodayFocus: Codable, Equatable, Identifiable {
    let id: UUID
    let date: Date
    let primaryTip: String
    let actionTip: String
    let source: FocusSource
    let relatedChildId: UUID?
    let relatedChildName: String?
    let confidence: FocusConfidence

    /// Where this focus tip was derived from
    enum FocusSource: String, Codable {
        case challengePattern    // Based on recent challenges
        case strengthBuilding    // Based on emerging strength
        case streakCelebration   // Consecutive days of logging
        case recoveryCelebration // Bounce back after tough week
        case routineSupport      // Based on routine needs
        case balanceNeeded       // Positive/negative ratio needs attention
        case genericTip          // Fallback generic tip
    }

    /// How confident we are in this recommendation
    enum FocusConfidence: String, Codable {
        case high      // Clear pattern in data
        case medium    // Some signal
        case low       // Limited data, using fallback
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        primaryTip: String,
        actionTip: String,
        source: FocusSource,
        relatedChildId: UUID? = nil,
        relatedChildName: String? = nil,
        confidence: FocusConfidence = .medium
    ) {
        self.id = id
        self.date = date
        self.primaryTip = primaryTip
        self.actionTip = actionTip
        self.source = source
        self.relatedChildId = relatedChildId
        self.relatedChildName = relatedChildName
        self.confidence = confidence
    }
}

// MARK: - Today Focus Generator

/// Generates personalized daily focus tips based on behavior patterns.
///
/// Key features:
/// - Analyzes recent behavior events to find patterns
/// - Prioritizes actionable insights over generic tips
/// - Uses child-specific data when available
/// - Syncs via Firebase for co-parent visibility
/// - Falls back to rotating generic tips when data is limited
@MainActor
final class TodayFocusGenerator: ObservableObject {

    // MARK: - Singleton

    static let shared = TodayFocusGenerator()

    // MARK: - Published State

    @Published private(set) var todayFocus: TodayFocus?
    @Published private(set) var isGenerating: Bool = false

    // MARK: - Private State

    private var lastGeneratedDate: Date?
    private var cachedFocus: TodayFocus?

    // MARK: - Configuration

    /// Minimum events needed for data-driven focus
    private let minimumEventsForInsights = 5

    /// Days of data to analyze
    private let analysisWindowDays = 14

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Generate today's focus based on behavior data.
    /// Results are cached for the day and synced to Firebase.
    func generateTodayFocus(
        children: [Child],
        behaviorEvents: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> TodayFocus {
        // Check if we already generated for today
        if let cached = cachedFocus,
           Calendar.current.isDateInToday(cached.date) {
            todayFocus = cached
            return cached
        }

        isGenerating = true

        // Filter to recent events
        let recentEvents = filterRecentEvents(behaviorEvents)

        // Generate focus based on available data
        let focus: TodayFocus

        if recentEvents.count >= minimumEventsForInsights {
            focus = generateDataDrivenFocus(
                children: children,
                events: recentEvents,
                behaviorTypes: behaviorTypes
            )
        } else {
            focus = generateGenericFocus()
        }

        // Cache and publish
        cachedFocus = focus
        todayFocus = focus
        isGenerating = false

        #if DEBUG
        print("[TodayFocus] Generated focus: \(focus.source.rawValue) - \(focus.primaryTip)")
        #endif

        return focus
    }

    /// Clear cached focus (for testing or manual refresh)
    func clearCache() {
        cachedFocus = nil
        todayFocus = nil
    }

    // MARK: - Data-Driven Focus Generation

    private func generateDataDrivenFocus(
        children: [Child],
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) -> TodayFocus {
        // Analyze patterns
        let patterns = analyzePatterns(events: events, behaviorTypes: behaviorTypes, children: children)

        // Priority order for focus generation
        // 1. Challenge pattern that needs attention
        if let challengeFocus = generateChallengeFocus(patterns: patterns, children: children, behaviorTypes: behaviorTypes) {
            return challengeFocus
        }

        // 2. Emerging strength to reinforce
        if let strengthFocus = generateStrengthFocus(patterns: patterns, children: children, behaviorTypes: behaviorTypes) {
            return strengthFocus
        }

        // 3. Streak celebration (3+ consecutive days)
        if let streakFocus = generateStreakFocus(patterns: patterns, children: children) {
            return streakFocus
        }

        // 4. Recovery celebration (bounce back after tough week)
        if let recoveryFocus = generateRecoveryFocus(patterns: patterns, children: children) {
            return recoveryFocus
        }

        // 5. Balance needed (too many challenges)
        if let balanceFocus = generateBalanceFocus(patterns: patterns, children: children) {
            return balanceFocus
        }

        // 6. Routine support
        if let routineFocus = generateRoutineFocus(patterns: patterns, children: children, behaviorTypes: behaviorTypes) {
            return routineFocus
        }

        // Fallback to generic
        return generateGenericFocus()
    }

    // MARK: - Pattern Analysis

    private struct BehaviorPatterns {
        var topChallengeBehavior: (typeId: UUID, count: Int, name: String)?
        var topPositiveBehavior: (typeId: UUID, count: Int, name: String)?
        var challengeRatio: Double  // challenges / total
        var childPatterns: [UUID: ChildPattern]
        var recentTrend: Trend

        // Week-over-week data for data-rich templates
        var thisWeekPositiveCount: Int
        var lastWeekPositiveCount: Int
        var thisWeekChallengeCount: Int
        var lastWeekChallengeCount: Int

        // Streak and recovery detection
        var consecutiveDaysWithActivity: Int
        var hadToughLastWeek: Bool  // 3+ challenges in previous week

        struct ChildPattern {
            let childId: UUID
            let childName: String
            let topChallenge: String?
            let topChallengeCount: Int
            let topStrength: String?
            let topStrengthCount: Int
            let positiveRatio: Double
            let thisWeekPositive: Int
            let lastWeekPositive: Int
            let consecutiveDays: Int
        }

        enum Trend {
            case improving
            case declining
            case stable
        }
    }

    private func analyzePatterns(
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        children: [Child]
    ) -> BehaviorPatterns {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        // Split events into this week and last week
        let thisWeekEvents = events.filter { $0.timestamp >= weekAgo }
        let lastWeekEvents = events.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo }

        // Count by behavior type (all events in 14-day window)
        var positiveCount: [UUID: Int] = [:]
        var challengeCount: [UUID: Int] = [:]

        for event in events {
            if event.pointsApplied > 0 {
                positiveCount[event.behaviorTypeId, default: 0] += 1
            } else {
                challengeCount[event.behaviorTypeId, default: 0] += 1
            }
        }

        // Find top behaviors
        let topChallenge = challengeCount.max(by: { $0.value < $1.value })
        let topPositive = positiveCount.max(by: { $0.value < $1.value })

        let topChallengeBehavior: (UUID, Int, String)? = topChallenge.flatMap { (typeId, count) in
            behaviorTypes.first(where: { $0.id == typeId }).map { (typeId, count, $0.name) }
        }

        let topPositiveBehavior: (UUID, Int, String)? = topPositive.flatMap { (typeId, count) in
            behaviorTypes.first(where: { $0.id == typeId }).map { (typeId, count, $0.name) }
        }

        // Calculate challenge ratio
        let totalPositive = positiveCount.values.reduce(0, +)
        let totalChallenges = challengeCount.values.reduce(0, +)
        let total = totalPositive + totalChallenges
        let challengeRatio = total > 0 ? Double(totalChallenges) / Double(total) : 0

        // Week-over-week counts
        let thisWeekPositiveCount = thisWeekEvents.filter { $0.pointsApplied > 0 }.count
        let lastWeekPositiveCount = lastWeekEvents.filter { $0.pointsApplied > 0 }.count
        let thisWeekChallengeCount = thisWeekEvents.filter { $0.pointsApplied <= 0 }.count
        let lastWeekChallengeCount = lastWeekEvents.filter { $0.pointsApplied <= 0 }.count

        // Calculate consecutive days with activity
        let consecutiveDays = calculateConsecutiveDays(events: events)

        // Check if last week was tough (3+ challenges)
        let hadToughLastWeek = lastWeekChallengeCount >= 3

        // Analyze per-child patterns
        var childPatterns: [UUID: BehaviorPatterns.ChildPattern] = [:]
        for child in children {
            let childEvents = events.filter { $0.childId == child.id }
            if childEvents.isEmpty { continue }

            let childThisWeek = childEvents.filter { $0.timestamp >= weekAgo }
            let childLastWeek = childEvents.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo }

            var childPositive: [UUID: Int] = [:]
            var childChallenge: [UUID: Int] = [:]

            for event in childEvents {
                if event.pointsApplied > 0 {
                    childPositive[event.behaviorTypeId, default: 0] += 1
                } else {
                    childChallenge[event.behaviorTypeId, default: 0] += 1
                }
            }

            let childTopChallenge = childChallenge.max(by: { $0.value < $1.value })
            let childTopPositive = childPositive.max(by: { $0.value < $1.value })

            let topChallengeName = childTopChallenge.flatMap { typeId, _ in
                behaviorTypes.first(where: { $0.id == typeId })?.name
            }
            let topChallengeCount = childTopChallenge?.value ?? 0

            let topStrengthName = childTopPositive.flatMap { typeId, _ in
                behaviorTypes.first(where: { $0.id == typeId })?.name
            }
            let topStrengthCount = childTopPositive?.value ?? 0

            let childTotal = childPositive.values.reduce(0, +) + childChallenge.values.reduce(0, +)
            let positiveRatio = childTotal > 0 ? Double(childPositive.values.reduce(0, +)) / Double(childTotal) : 0

            let childThisWeekPositive = childThisWeek.filter { $0.pointsApplied > 0 }.count
            let childLastWeekPositive = childLastWeek.filter { $0.pointsApplied > 0 }.count
            let childConsecutiveDays = calculateConsecutiveDays(events: childEvents)

            childPatterns[child.id] = BehaviorPatterns.ChildPattern(
                childId: child.id,
                childName: child.name,
                topChallenge: topChallengeName,
                topChallengeCount: topChallengeCount,
                topStrength: topStrengthName,
                topStrengthCount: topStrengthCount,
                positiveRatio: positiveRatio,
                thisWeekPositive: childThisWeekPositive,
                lastWeekPositive: childLastWeekPositive,
                consecutiveDays: childConsecutiveDays
            )
        }

        // Calculate trend (comparing last 7 days to previous 7 days)
        let trend = calculateTrend(events: events)

        return BehaviorPatterns(
            topChallengeBehavior: topChallengeBehavior,
            topPositiveBehavior: topPositiveBehavior,
            challengeRatio: challengeRatio,
            childPatterns: childPatterns,
            recentTrend: trend,
            thisWeekPositiveCount: thisWeekPositiveCount,
            lastWeekPositiveCount: lastWeekPositiveCount,
            thisWeekChallengeCount: thisWeekChallengeCount,
            lastWeekChallengeCount: lastWeekChallengeCount,
            consecutiveDaysWithActivity: consecutiveDays,
            hadToughLastWeek: hadToughLastWeek
        )
    }

    /// Calculate how many consecutive days (ending today) have at least one event
    private func calculateConsecutiveDays(events: [BehaviorEvent]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with events
        var daysWithEvents: Set<Date> = []
        for event in events {
            let dayStart = calendar.startOfDay(for: event.timestamp)
            daysWithEvents.insert(dayStart)
        }

        // Count consecutive days backward from today
        var consecutiveDays = 0
        var checkDate = today

        while daysWithEvents.contains(checkDate) {
            consecutiveDays += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return consecutiveDays
    }

    private func calculateTrend(events: [BehaviorEvent]) -> BehaviorPatterns.Trend {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) else {
            return .stable
        }

        let recentEvents = events.filter { $0.timestamp >= weekAgo }
        let previousEvents = events.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo }

        let recentPositive = recentEvents.filter { $0.pointsApplied > 0 }.count
        let previousPositive = previousEvents.filter { $0.pointsApplied > 0 }.count

        if recentPositive > previousPositive + 2 {
            return .improving
        } else if recentPositive < previousPositive - 2 {
            return .declining
        }
        return .stable
    }

    // MARK: - Focus Generators

    private func generateChallengeFocus(
        patterns: BehaviorPatterns,
        children: [Child],
        behaviorTypes: [BehaviorType]
    ) -> TodayFocus? {
        // Find child with most challenges
        let childWithMostChallenges = patterns.childPatterns.values
            .filter { $0.positiveRatio < 0.5 && $0.topChallenge != nil }
            .min(by: { $0.positiveRatio < $1.positiveRatio })

        if let child = childWithMostChallenges, let challenge = child.topChallenge {
            // Data-rich template with counts and comparison
            let challengeCount = child.topChallengeCount
            let comparisonText: String
            if child.lastWeekPositive > 0 && child.thisWeekPositive > child.lastWeekPositive {
                comparisonText = " (but \(child.thisWeekPositive) wins this week, up from \(child.lastWeekPositive))"
            } else {
                comparisonText = ""
            }

            return TodayFocus(
                primaryTip: "\(challengeCount) \(challenge.lowercased()) moments with \(child.childName) this week\(comparisonText).",
                actionTip: "Try saying \"I can see this is hard\" before reacting.",
                source: .challengePattern,
                relatedChildId: child.childId,
                relatedChildName: child.childName,
                confidence: .high
            )
        }

        return nil
    }

    private func generateStrengthFocus(
        patterns: BehaviorPatterns,
        children: [Child],
        behaviorTypes: [BehaviorType]
    ) -> TodayFocus? {
        // Find child with emerging strength
        let childWithStrength = patterns.childPatterns.values
            .filter { $0.topStrength != nil && $0.positiveRatio >= 0.6 }
            .max(by: { $0.positiveRatio < $1.positiveRatio })

        if let child = childWithStrength, let strength = child.topStrength {
            // Data-rich template with counts and comparison
            let strengthCount = child.topStrengthCount
            let comparisonText: String
            if child.lastWeekPositive > 0 {
                let diff = child.thisWeekPositive - child.lastWeekPositive
                if diff > 0 {
                    comparisonText = ", up from \(child.lastWeekPositive) last week"
                } else if diff < 0 {
                    comparisonText = ""  // Don't highlight decline
                } else {
                    comparisonText = ", same as last week"
                }
            } else {
                comparisonText = ""
            }

            return TodayFocus(
                primaryTip: "\(child.childName) showed \(strength.lowercased()) \(strengthCount) times this week\(comparisonText).",
                actionTip: "Notice it out loud: \"I saw you \(strength.lowercased()) today.\"",
                source: .strengthBuilding,
                relatedChildId: child.childId,
                relatedChildName: child.childName,
                confidence: .high
            )
        }

        return nil
    }

    private func generateStreakFocus(
        patterns: BehaviorPatterns,
        children: [Child]
    ) -> TodayFocus? {
        // Find child with best streak (3+ consecutive days)
        let childWithStreak = patterns.childPatterns.values
            .filter { $0.consecutiveDays >= 3 }
            .max(by: { $0.consecutiveDays < $1.consecutiveDays })

        if let child = childWithStreak {
            let days = child.consecutiveDays
            return TodayFocus(
                primaryTip: "You've noticed \(child.childName) \(days) days in a row. That consistency matters.",
                actionTip: "Keep it going - one moment today keeps the streak alive.",
                source: .streakCelebration,
                relatedChildId: child.childId,
                relatedChildName: child.childName,
                confidence: .high
            )
        }

        // Check family-wide streak
        if patterns.consecutiveDaysWithActivity >= 3 {
            let days = patterns.consecutiveDaysWithActivity
            return TodayFocus(
                primaryTip: "You've logged moments \(days) days in a row. You're building a habit.",
                actionTip: "One small win today keeps the streak alive.",
                source: .streakCelebration,
                confidence: .high
            )
        }

        return nil
    }

    private func generateRecoveryFocus(
        patterns: BehaviorPatterns,
        children: [Child]
    ) -> TodayFocus? {
        // Check for recovery pattern: tough last week + good this week
        guard patterns.hadToughLastWeek && patterns.thisWeekPositiveCount >= 3 else {
            return nil
        }

        // Find child who bounced back the most
        let childWhoRecovered = patterns.childPatterns.values
            .filter { $0.thisWeekPositive >= 3 }
            .max(by: { $0.thisWeekPositive < $1.thisWeekPositive })

        if let child = childWhoRecovered {
            return TodayFocus(
                primaryTip: "\(child.childName) bounced back - \(child.thisWeekPositive) wins this week after a tough stretch.",
                actionTip: "Celebrate the turnaround: \"I noticed things are going better.\"",
                source: .recoveryCelebration,
                relatedChildId: child.childId,
                relatedChildName: child.childName,
                confidence: .high
            )
        }

        // Family-wide recovery
        return TodayFocus(
            primaryTip: "Your family bounced back - \(patterns.thisWeekPositiveCount) wins this week after a tough stretch.",
            actionTip: "Acknowledge the turnaround tonight.",
            source: .recoveryCelebration,
            confidence: .medium
        )
    }

    private func generateBalanceFocus(
        patterns: BehaviorPatterns,
        children: [Child]
    ) -> TodayFocus? {
        // If challenge ratio is too high
        if patterns.challengeRatio > 0.4 {
            // Data-rich: show actual counts
            let wins = patterns.thisWeekPositiveCount
            let challenges = patterns.thisWeekChallengeCount
            let comparisonText: String
            if patterns.lastWeekPositiveCount > 0 && wins > patterns.lastWeekPositiveCount {
                comparisonText = " (up from \(patterns.lastWeekPositiveCount) last week)"
            } else {
                comparisonText = ""
            }

            return TodayFocus(
                primaryTip: "\(wins) wins vs \(challenges) challenges this week\(comparisonText). Try catching one more positive today.",
                actionTip: "Even a brief \"thank you\" or smile counts.",
                source: .balanceNeeded,
                confidence: .medium
            )
        }
        return nil
    }

    private func generateRoutineFocus(
        patterns: BehaviorPatterns,
        children: [Child],
        behaviorTypes: [BehaviorType]
    ) -> TodayFocus? {
        // Check for routine-related patterns
        if let topPositive = patterns.topPositiveBehavior {
            let routineKeywords = ["routine", "morning", "bedtime", "teeth", "homework"]
            let isRoutine = routineKeywords.contains(where: { topPositive.name.lowercased().contains($0) })

            if isRoutine {
                // Data-rich: show count
                let count = topPositive.count
                return TodayFocus(
                    primaryTip: "\(topPositive.name) logged \(count) times this week. It's becoming a habit.",
                    actionTip: "Consistency matters more than perfection.",
                    source: .routineSupport,
                    confidence: .medium
                )
            }
        }
        return nil
    }

    // MARK: - Generic Focus (Fallback)

    private func generateGenericFocus() -> TodayFocus {
        let tips = [
            ("Try to catch one sharing moment today.", "Say \"I see you working hard on that.\""),
            ("Notice one moment of effort today.", "Tell them what you loved about how they tried."),
            ("Look for a chance to appreciate without commenting.", "Just watch and enjoy one moment."),
            ("When they struggle, try \"That looks hard\" first.", "See if they ask for help before offering."),
            ("Catch them being patient today.", "Notice kindness with a sibling or friend."),
            ("Look for a moment of curiosity or wonder.", "Celebrate their questions today."),
            ("Notice when they handle frustration.", "See how they manage a tough moment."),
            ("Watch for acts of kindness today.", "Notice when they think of others.")
        ]

        // Use day of year for deterministic selection
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let (primary, action) = tips[dayOfYear % tips.count]

        return TodayFocus(
            primaryTip: primary,
            actionTip: action,
            source: .genericTip,
            confidence: .low
        )
    }

    // MARK: - Helpers

    private func filterRecentEvents(_ events: [BehaviorEvent]) -> [BehaviorEvent] {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -analysisWindowDays, to: Date()) else {
            return events
        }
        return events.filter { $0.timestamp >= cutoffDate }
    }
}

// MARK: - Sync Extension (Firebase integration)

extension TodayFocusGenerator {
    /// Convert focus to dictionary for Firebase storage
    func focusToFirebaseDict(_ focus: TodayFocus) -> [String: Any] {
        var dict: [String: Any] = [
            "id": focus.id.uuidString,
            "date": focus.date.timeIntervalSince1970,
            "primaryTip": focus.primaryTip,
            "actionTip": focus.actionTip,
            "source": focus.source.rawValue,
            "confidence": focus.confidence.rawValue
        ]

        if let childId = focus.relatedChildId {
            dict["relatedChildId"] = childId.uuidString
        }
        if let childName = focus.relatedChildName {
            dict["relatedChildName"] = childName
        }

        return dict
    }

    /// Create focus from Firebase dictionary
    func focusFromFirebaseDict(_ dict: [String: Any]) -> TodayFocus? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = dict["date"] as? TimeInterval,
              let primaryTip = dict["primaryTip"] as? String,
              let actionTip = dict["actionTip"] as? String,
              let sourceRaw = dict["source"] as? String,
              let source = TodayFocus.FocusSource(rawValue: sourceRaw) else {
            return nil
        }

        let confidence: TodayFocus.FocusConfidence
        if let confRaw = dict["confidence"] as? String,
           let conf = TodayFocus.FocusConfidence(rawValue: confRaw) {
            confidence = conf
        } else {
            confidence = .medium
        }

        let childId = (dict["relatedChildId"] as? String).flatMap { UUID(uuidString: $0) }
        let childName = dict["relatedChildName"] as? String

        return TodayFocus(
            id: id,
            date: Date(timeIntervalSince1970: timestamp),
            primaryTip: primaryTip,
            actionTip: actionTip,
            source: source,
            relatedChildId: childId,
            relatedChildName: childName,
            confidence: confidence
        )
    }
}
