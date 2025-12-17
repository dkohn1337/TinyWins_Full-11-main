import Foundation

// MARK: - Signal Types

/// The 5 deterministic signals that the engine detects.
enum SignalType: String, CaseIterable, Codable {
    case goalAtRisk
    case goalStalled
    case routineForming
    case routineSlipping
    case highChallengeWeek

    /// Whether this signal type is a "risk" signal (overwhelming/negative).
    var isRiskSignal: Bool {
        switch self {
        case .goalAtRisk, .highChallengeWeek:
            return true
        case .goalStalled, .routineForming, .routineSlipping:
            return false
        }
    }

    /// Whether this signal type is an "improvement" signal.
    var isImprovementSignal: Bool {
        switch self {
        case .goalStalled, .routineForming, .routineSlipping:
            return true
        case .goalAtRisk, .highChallengeWeek:
            return false
        }
    }
}

// MARK: - Signal Detection Context

/// Context provided to signal detectors containing all necessary data.
struct SignalDetectionContext {
    let childId: String
    let events: [UnifiedEvent]
    let goals: [CanonicalGoal]
    let behaviors: [CanonicalBehavior]
    let now: Date

    /// Events filtered to the standard 7-day window
    var events7Days: [UnifiedEvent] {
        events.forChild(childId).inWindow(.sevenDays)
    }

    /// Events filtered to the standard 14-day window
    var events14Days: [UnifiedEvent] {
        events.forChild(childId).inWindow(.fourteenDays)
    }
}

// MARK: - HOW TO ADD A NEW SIGNAL
//
// 1. Add a new case to SignalType enum above
// 2. Create a new static function in SignalDetectors below that:
//    - Takes the required parameters (goal, behavior, events, etc.)
//    - Returns SignalResult with triggered=true/false
//    - Provides explanation string for debugging
//    - Calculates confidence (0-1)
//    - Collects evidence event IDs
// 3. Add a new template in CardTemplateLibrary (CardTemplates.swift)
// 4. Call the detector in CoachingEngineImpl.generateCards()
// 5. Add tests in InsightsEngineTests.swift
//

// MARK: - Signal Result

/// Result of evaluating a signal.
struct SignalResult: Equatable {
    let signalType: SignalType
    let triggered: Bool
    let confidence: Double  // 0.0 to 1.0
    let evidence: InsightEvidence
    let explanation: String  // Debug only
    let metadata: SignalMetadata

    static func notTriggered(_ type: SignalType, reason: String) -> SignalResult {
        SignalResult(
            signalType: type,
            triggered: false,
            confidence: 0,
            evidence: .empty,
            explanation: reason,
            metadata: .empty
        )
    }
}

/// Additional metadata for signal-specific information.
struct SignalMetadata: Equatable {
    let goalId: String?
    let goalName: String?
    let behaviorId: String?
    let behaviorName: String?
    let daysRemaining: Int?
    let progress: Double?
    let count: Int?
    let daysSinceOccurrence: Int?

    static let empty = SignalMetadata(
        goalId: nil,
        goalName: nil,
        behaviorId: nil,
        behaviorName: nil,
        daysRemaining: nil,
        progress: nil,
        count: nil,
        daysSinceOccurrence: nil
    )
}

// MARK: - Signal Detectors

enum SignalDetectors {

    // MARK: - Optimized Detectors (using PreFilteredEvents)

    /// Optimized goal at risk detection using pre-filtered events.
    static func detectGoalAtRisk(
        goal: CanonicalGoal,
        preFiltered: PreFilteredEvents,
        now: Date
    ) -> SignalResult {
        guard goal.hasDeadline,
              !goal.isRedeemed,
              !goal.isExpired,
              let daysRemaining = goal.daysRemaining,
              daysRemaining > 0 else {
            return .notTriggered(.goalAtRisk, reason: "Goal has no deadline, is completed, or expired")
        }

        // Use pre-filtered positive events in 14-day window
        let windowEvents = preFiltered.positiveIn14Days

        guard windowEvents.count >= InsightsEngineConstants.minimumEventsForGoalAtRisk else {
            return .notTriggered(.goalAtRisk, reason: "Insufficient events (\(windowEvents.count) < \(InsightsEngineConstants.minimumEventsForGoalAtRisk))")
        }

        let pointsNeeded = goal.targetPoints - goal.currentPoints
        guard pointsNeeded > 0 else {
            return .notTriggered(.goalAtRisk, reason: "Goal is already complete or nearly complete")
        }

        let paceNeeded = Double(pointsNeeded) / Double(daysRemaining)

        // Use pre-filtered positive events in 7-day window
        let recentEvents = preFiltered.positiveIn7Days
        let recentPoints = recentEvents.reduce(0) { $0 + $1.starsDelta }
        let currentPace = Double(recentPoints) / 7.0

        let isAtRisk = currentPace < paceNeeded * 0.7

        guard isAtRisk else {
            return .notTriggered(.goalAtRisk, reason: "Current pace (\(String(format: "%.1f", currentPace))/day) is sufficient")
        }

        let paceRatio = currentPace / paceNeeded
        let confidence = max(0, min(1, 1.0 - paceRatio))

        return SignalResult(
            signalType: .goalAtRisk,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: recentEvents.eventIds,
                window: .sevenDays,
                count: recentEvents.count
            ),
            explanation: "Goal '\(goal.name)' is at risk: need \(pointsNeeded) points in \(daysRemaining) days",
            metadata: SignalMetadata(
                goalId: goal.id,
                goalName: goal.name,
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: daysRemaining,
                progress: goal.progress,
                count: recentEvents.count,
                daysSinceOccurrence: nil
            )
        )
    }

    /// Optimized goal stalled detection using pre-filtered events.
    static func detectGoalStalled(
        goal: CanonicalGoal,
        preFiltered: PreFilteredEvents,
        now: Date
    ) -> SignalResult {
        guard !goal.isRedeemed, !goal.isExpired else {
            return .notTriggered(.goalStalled, reason: "Goal is completed or expired")
        }

        let positiveEvents = preFiltered.positive
        let windowEvents = preFiltered.positiveIn14Days

        guard windowEvents.count >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.goalStalled, reason: "Insufficient events in 14-day window")
        }

        let stalledWindow = InsightsEngineConstants.goalStalledDays
        let stalledDate = Calendar.current.date(byAdding: .day, value: -stalledWindow, to: now) ?? now

        let recentEvents = positiveEvents.filter { $0.timestamp >= stalledDate }

        guard recentEvents.isEmpty else {
            return .notTriggered(.goalStalled, reason: "Found \(recentEvents.count) events in last \(stalledWindow) days")
        }

        let sortedEvents = positiveEvents.sorted { $0.timestamp > $1.timestamp }
        guard let lastEvent = sortedEvents.first else {
            return .notTriggered(.goalStalled, reason: "No events found for this child")
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastEvent.timestamp, to: now).day ?? 0
        let confidence = min(1.0, Double(daysSince) / 10.0)

        return SignalResult(
            signalType: .goalStalled,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: windowEvents.eventIds,
                window: .fourteenDays,
                count: windowEvents.count
            ),
            explanation: "Goal '\(goal.name)' has stalled: no progress in \(daysSince) days",
            metadata: SignalMetadata(
                goalId: goal.id,
                goalName: goal.name,
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: goal.daysRemaining,
                progress: goal.progress,
                count: windowEvents.count,
                daysSinceOccurrence: daysSince
            )
        )
    }

    /// Optimized routine forming detection using pre-filtered events.
    static func detectRoutineForming(
        behavior: CanonicalBehavior,
        preFiltered: PreFilteredEvents,
        childId: String,
        now: Date
    ) -> SignalResult {
        guard behavior.category == .routinePositive else {
            return .notTriggered(.routineForming, reason: "Behavior is not a routine type")
        }

        let behaviorEvents14 = preFiltered.behaviorEventsIn14Days(behavior.id)

        guard behaviorEvents14.count >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.routineForming, reason: "Insufficient events (\(behaviorEvents14.count) < \(InsightsEngineConstants.minimumEventsForInsight))")
        }

        let recentEvents = preFiltered.behaviorEventsIn7Days(behavior.id)
        guard recentEvents.count >= InsightsEngineConstants.routineFormingThreshold else {
            return .notTriggered(.routineForming, reason: "Not frequent enough (\(recentEvents.count) < \(InsightsEngineConstants.routineFormingThreshold) in 7 days)")
        }

        let uniqueDays = recentEvents.uniqueDays()
        guard uniqueDays.count >= 3 else {
            return .notTriggered(.routineForming, reason: "Not consistent enough (only \(uniqueDays.count) unique days)")
        }

        let confidence = min(1.0, Double(recentEvents.count) / 7.0)

        return SignalResult(
            signalType: .routineForming,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: recentEvents.eventIds,
                window: .sevenDays,
                count: recentEvents.count
            ),
            explanation: "Routine '\(behavior.name)' is forming: \(recentEvents.count) times in 7 days",
            metadata: SignalMetadata(
                goalId: nil,
                goalName: nil,
                behaviorId: behavior.id,
                behaviorName: behavior.name,
                daysRemaining: nil,
                progress: nil,
                count: recentEvents.count,
                daysSinceOccurrence: nil
            )
        )
    }

    /// Optimized routine slipping detection using pre-filtered events.
    static func detectRoutineSlipping(
        behavior: CanonicalBehavior,
        preFiltered: PreFilteredEvents,
        childId: String,
        now: Date
    ) -> SignalResult {
        guard behavior.category == .routinePositive else {
            return .notTriggered(.routineSlipping, reason: "Behavior is not a routine type")
        }

        let behaviorEvents = preFiltered.behaviorEventsIn14Days(behavior.id)
            .sorted { $0.timestamp > $1.timestamp }

        guard behaviorEvents.count >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.routineSlipping, reason: "Insufficient events to establish routine")
        }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let olderEvents = behaviorEvents.filter {
            $0.timestamp >= fourteenDaysAgo && $0.timestamp < sevenDaysAgo
        }
        let recentEvents = behaviorEvents.filter {
            $0.timestamp >= sevenDaysAgo
        }

        guard olderEvents.count >= 3 else {
            return .notTriggered(.routineSlipping, reason: "No established pattern in older window")
        }

        let olderRate = Double(olderEvents.count) / 7.0
        let recentRate = Double(recentEvents.count) / 7.0

        guard recentRate < olderRate * 0.5 else {
            return .notTriggered(.routineSlipping, reason: "Recent rate not significantly lower than older rate")
        }

        guard let lastEvent = behaviorEvents.first else {
            return .notTriggered(.routineSlipping, reason: "No events found")
        }

        let daysSince = calendar.dateComponents([.day], from: lastEvent.timestamp, to: now).day ?? 0

        guard daysSince >= InsightsEngineConstants.routineSlippingGapDays else {
            return .notTriggered(.routineSlipping, reason: "Gap (\(daysSince) days) not long enough")
        }

        let confidence = min(1.0, Double(daysSince) / 7.0)

        return SignalResult(
            signalType: .routineSlipping,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: behaviorEvents.eventIds,
                window: .fourteenDays,
                count: behaviorEvents.count
            ),
            explanation: "Routine '\(behavior.name)' is slipping: \(daysSince) days since last occurrence",
            metadata: SignalMetadata(
                goalId: nil,
                goalName: nil,
                behaviorId: behavior.id,
                behaviorName: behavior.name,
                daysRemaining: nil,
                progress: nil,
                count: recentEvents.count,
                daysSinceOccurrence: daysSince
            )
        )
    }

    /// Optimized high challenge week detection using pre-filtered events.
    static func detectHighChallengeWeek(
        preFiltered: PreFilteredEvents,
        childId: String,
        now: Date
    ) -> SignalResult {
        let positiveEvents = preFiltered.positiveIn7Days
        let challengeEvents = preFiltered.challengesIn7Days

        let totalEvents = positiveEvents.count + challengeEvents.count
        guard totalEvents >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.highChallengeWeek, reason: "Insufficient total events (\(totalEvents) < \(InsightsEngineConstants.minimumEventsForInsight))")
        }

        let positiveCount = positiveEvents.count
        let challengeCount = challengeEvents.count

        guard positiveCount > 0 else {
            if challengeCount >= InsightsEngineConstants.minimumEventsForInsight {
                return SignalResult(
                    signalType: .highChallengeWeek,
                    triggered: true,
                    confidence: 1.0,
                    evidence: InsightEvidence(
                        eventIds: challengeEvents.eventIds,
                        window: .sevenDays,
                        count: challengeCount
                    ),
                    explanation: "High challenge week: \(challengeCount) challenges and 0 positives",
                    metadata: SignalMetadata(
                        goalId: nil,
                        goalName: nil,
                        behaviorId: nil,
                        behaviorName: nil,
                        daysRemaining: nil,
                        progress: nil,
                        count: challengeCount,
                        daysSinceOccurrence: nil
                    )
                )
            } else {
                return .notTriggered(.highChallengeWeek, reason: "Not enough challenges to qualify")
            }
        }

        let ratio = Double(challengeCount) / Double(positiveCount)

        guard ratio >= InsightsEngineConstants.highChallengeThreshold else {
            return .notTriggered(.highChallengeWeek, reason: "Challenge ratio (\(String(format: "%.2f", ratio))) below threshold")
        }

        let confidence = min(1.0, ratio / 2.0)

        return SignalResult(
            signalType: .highChallengeWeek,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: (challengeEvents + positiveEvents).eventIds,
                window: .sevenDays,
                count: totalEvents
            ),
            explanation: "High challenge week: \(challengeCount) challenges vs \(positiveCount) positives",
            metadata: SignalMetadata(
                goalId: nil,
                goalName: nil,
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: nil,
                progress: nil,
                count: challengeCount,
                daysSinceOccurrence: nil
            )
        )
    }

    // MARK: - Legacy Detectors (for backward compatibility)

    // MARK: - Goal at Risk

    /// Detects if a goal with a deadline is at risk of not being completed.
    /// Triggers with 2+ events if deadline exists.
    static func detectGoalAtRisk(
        goal: CanonicalGoal,
        events: [UnifiedEvent],
        now: Date
    ) -> SignalResult {
        guard goal.hasDeadline,
              !goal.isRedeemed,
              !goal.isExpired,
              let daysRemaining = goal.daysRemaining,
              daysRemaining > 0 else {
            return .notTriggered(.goalAtRisk, reason: "Goal has no deadline, is completed, or expired")
        }

        // Get events for this child in the relevant window
        let windowEvents = events
            .forChild(goal.childId)
            .positiveOnly()
            .inWindow(.fourteenDays)

        // Need at least 2 events for goal at risk (exception to 3-event rule)
        guard windowEvents.count >= InsightsEngineConstants.minimumEventsForGoalAtRisk else {
            return .notTriggered(.goalAtRisk, reason: "Insufficient events (\(windowEvents.count) < \(InsightsEngineConstants.minimumEventsForGoalAtRisk))")
        }

        // Calculate if at risk
        let pointsNeeded = goal.targetPoints - goal.currentPoints
        guard pointsNeeded > 0 else {
            return .notTriggered(.goalAtRisk, reason: "Goal is already complete or nearly complete")
        }

        // Calculate average daily pace needed
        let paceNeeded = Double(pointsNeeded) / Double(daysRemaining)

        // Calculate current pace from recent events
        let recentEvents = events
            .forChild(goal.childId)
            .positiveOnly()
            .inWindow(.sevenDays)
        let recentPoints = recentEvents.reduce(0) { $0 + $1.starsDelta }
        let currentPace = Double(recentPoints) / 7.0

        // At risk if current pace is less than 70% of needed pace
        let isAtRisk = currentPace < paceNeeded * 0.7

        guard isAtRisk else {
            return .notTriggered(.goalAtRisk, reason: "Current pace (\(String(format: "%.1f", currentPace))/day) is sufficient for needed pace (\(String(format: "%.1f", paceNeeded))/day)")
        }

        // Calculate confidence based on how far behind
        let paceRatio = currentPace / paceNeeded
        let confidence = max(0, min(1, 1.0 - paceRatio))

        return SignalResult(
            signalType: .goalAtRisk,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: recentEvents.eventIds,
                window: .sevenDays,
                count: recentEvents.count
            ),
            explanation: "Goal '\(goal.name)' is at risk: need \(pointsNeeded) points in \(daysRemaining) days, current pace is \(String(format: "%.1f", currentPace))/day vs needed \(String(format: "%.1f", paceNeeded))/day",
            metadata: SignalMetadata(
                goalId: goal.id,
                goalName: goal.name,
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: daysRemaining,
                progress: goal.progress,
                count: recentEvents.count,
                daysSinceOccurrence: nil
            )
        )
    }

    // MARK: - Goal Stalled

    /// Detects if a goal has stalled (no progress in X days).
    static func detectGoalStalled(
        goal: CanonicalGoal,
        events: [UnifiedEvent],
        now: Date
    ) -> SignalResult {
        guard !goal.isRedeemed, !goal.isExpired else {
            return .notTriggered(.goalStalled, reason: "Goal is completed or expired")
        }

        let childEvents = events
            .forChild(goal.childId)
            .positiveOnly()

        // Look at last 14 days
        let windowEvents = childEvents.inWindow(.fourteenDays)

        guard windowEvents.count >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.goalStalled, reason: "Insufficient events in 14-day window")
        }

        // Check if there are any events in the last stalledDays
        let stalledWindow = InsightsEngineConstants.goalStalledDays
        let stalledDate = Calendar.current.date(byAdding: .day, value: -stalledWindow, to: now) ?? now

        let recentEvents = childEvents.filter { $0.timestamp >= stalledDate }

        // If there are recent events, goal is not stalled
        guard recentEvents.isEmpty else {
            return .notTriggered(.goalStalled, reason: "Found \(recentEvents.count) events in last \(stalledWindow) days")
        }

        // Find the most recent event to calculate days since
        let sortedEvents = childEvents.sorted { $0.timestamp > $1.timestamp }
        guard let lastEvent = sortedEvents.first else {
            return .notTriggered(.goalStalled, reason: "No events found for this child")
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastEvent.timestamp, to: now).day ?? 0

        // Confidence based on how long it's been
        let confidence = min(1.0, Double(daysSince) / 10.0)

        return SignalResult(
            signalType: .goalStalled,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: windowEvents.eventIds,
                window: .fourteenDays,
                count: windowEvents.count
            ),
            explanation: "Goal '\(goal.name)' has stalled: no progress in \(daysSince) days",
            metadata: SignalMetadata(
                goalId: goal.id,
                goalName: goal.name,
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: goal.daysRemaining,
                progress: goal.progress,
                count: windowEvents.count,
                daysSinceOccurrence: daysSince
            )
        )
    }

    // MARK: - Routine Forming

    /// Detects if a routine behavior is forming (consistent occurrences).
    static func detectRoutineForming(
        behavior: CanonicalBehavior,
        events: [UnifiedEvent],
        childId: String,
        now: Date
    ) -> SignalResult {
        guard behavior.category == .routinePositive else {
            return .notTriggered(.routineForming, reason: "Behavior is not a routine type")
        }

        let behaviorEvents = events
            .forChild(childId)
            .forBehavior(behavior.id)
            .inWindow(.fourteenDays)

        guard behaviorEvents.count >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.routineForming, reason: "Insufficient events (\(behaviorEvents.count) < \(InsightsEngineConstants.minimumEventsForInsight))")
        }

        // Check frequency: at least routineFormingThreshold occurrences in 7 days
        let recentEvents = behaviorEvents.inWindow(.sevenDays)
        guard recentEvents.count >= InsightsEngineConstants.routineFormingThreshold else {
            return .notTriggered(.routineForming, reason: "Not frequent enough (\(recentEvents.count) < \(InsightsEngineConstants.routineFormingThreshold) in 7 days)")
        }

        // Check consistency: should be on multiple different days
        let uniqueDays = recentEvents.uniqueDays()
        guard uniqueDays.count >= 3 else {
            return .notTriggered(.routineForming, reason: "Not consistent enough (only \(uniqueDays.count) unique days)")
        }

        // Confidence based on frequency
        let confidence = min(1.0, Double(recentEvents.count) / 7.0)

        return SignalResult(
            signalType: .routineForming,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: recentEvents.eventIds,
                window: .sevenDays,
                count: recentEvents.count
            ),
            explanation: "Routine '\(behavior.name)' is forming: \(recentEvents.count) times in 7 days across \(uniqueDays.count) different days",
            metadata: SignalMetadata(
                goalId: nil,
                goalName: nil,
                behaviorId: behavior.id,
                behaviorName: behavior.name,
                daysRemaining: nil,
                progress: nil,
                count: recentEvents.count,
                daysSinceOccurrence: nil
            )
        )
    }

    // MARK: - Routine Slipping

    /// Detects if a previously consistent routine has slipped.
    static func detectRoutineSlipping(
        behavior: CanonicalBehavior,
        events: [UnifiedEvent],
        childId: String,
        now: Date
    ) -> SignalResult {
        guard behavior.category == .routinePositive else {
            return .notTriggered(.routineSlipping, reason: "Behavior is not a routine type")
        }

        let behaviorEvents = events
            .forChild(childId)
            .forBehavior(behavior.id)
            .inWindow(.fourteenDays)
            .sorted { $0.timestamp > $1.timestamp }

        guard behaviorEvents.count >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.routineSlipping, reason: "Insufficient events to establish routine")
        }

        // Check if there was a pattern in older window (days 7-14) but not recent (days 0-7)
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let olderEvents = behaviorEvents.filter {
            $0.timestamp >= fourteenDaysAgo && $0.timestamp < sevenDaysAgo
        }
        let recentEvents = behaviorEvents.filter {
            $0.timestamp >= sevenDaysAgo
        }

        // Was there a pattern before? (at least 3 events in older window)
        guard olderEvents.count >= 3 else {
            return .notTriggered(.routineSlipping, reason: "No established pattern in older window")
        }

        // Has it dropped significantly? (less than half the older rate)
        let olderRate = Double(olderEvents.count) / 7.0
        let recentRate = Double(recentEvents.count) / 7.0

        guard recentRate < olderRate * 0.5 else {
            return .notTriggered(.routineSlipping, reason: "Recent rate (\(String(format: "%.1f", recentRate))) is not significantly lower than older rate (\(String(format: "%.1f", olderRate)))")
        }

        // Calculate days since last occurrence
        guard let lastEvent = behaviorEvents.first else {
            return .notTriggered(.routineSlipping, reason: "No events found")
        }

        let daysSince = calendar.dateComponents([.day], from: lastEvent.timestamp, to: now).day ?? 0

        // Only trigger if there's been a significant gap
        guard daysSince >= InsightsEngineConstants.routineSlippingGapDays else {
            return .notTriggered(.routineSlipping, reason: "Gap (\(daysSince) days) not long enough")
        }

        let confidence = min(1.0, Double(daysSince) / 7.0)

        return SignalResult(
            signalType: .routineSlipping,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: behaviorEvents.eventIds,
                window: .fourteenDays,
                count: behaviorEvents.count
            ),
            explanation: "Routine '\(behavior.name)' is slipping: was \(olderEvents.count) times in older week, now \(recentEvents.count) times. Last occurrence \(daysSince) days ago",
            metadata: SignalMetadata(
                goalId: nil,
                goalName: nil,
                behaviorId: behavior.id,
                behaviorName: behavior.name,
                daysRemaining: nil,
                progress: nil,
                count: recentEvents.count,
                daysSinceOccurrence: daysSince
            )
        )
    }

    // MARK: - High Challenge Week

    /// Detects if challenges exceed positives in the last 7 days.
    static func detectHighChallengeWeek(
        events: [UnifiedEvent],
        childId: String,
        now: Date
    ) -> SignalResult {
        let childEvents = events.forChild(childId).inWindow(.sevenDays)

        let positiveEvents = childEvents.positiveOnly()
        let challengeEvents = childEvents.challengesOnly()

        // Need minimum events
        let totalEvents = positiveEvents.count + challengeEvents.count
        guard totalEvents >= InsightsEngineConstants.minimumEventsForInsight else {
            return .notTriggered(.highChallengeWeek, reason: "Insufficient total events (\(totalEvents) < \(InsightsEngineConstants.minimumEventsForInsight))")
        }

        // Check if challenges exceed positives
        let positiveCount = positiveEvents.count
        let challengeCount = challengeEvents.count

        // Avoid division by zero
        guard positiveCount > 0 else {
            // All challenges, no positives - this is high challenge
            if challengeCount >= InsightsEngineConstants.minimumEventsForInsight {
                return SignalResult(
                    signalType: .highChallengeWeek,
                    triggered: true,
                    confidence: 1.0,
                    evidence: InsightEvidence(
                        eventIds: challengeEvents.eventIds,
                        window: .sevenDays,
                        count: challengeCount
                    ),
                    explanation: "High challenge week: \(challengeCount) challenges and 0 positives in 7 days",
                    metadata: SignalMetadata(
                        goalId: nil,
                        goalName: nil,
                        behaviorId: nil,
                        behaviorName: nil,
                        daysRemaining: nil,
                        progress: nil,
                        count: challengeCount,
                        daysSinceOccurrence: nil
                    )
                )
            } else {
                return .notTriggered(.highChallengeWeek, reason: "Not enough challenges to qualify")
            }
        }

        let ratio = Double(challengeCount) / Double(positiveCount)

        guard ratio >= InsightsEngineConstants.highChallengeThreshold else {
            return .notTriggered(.highChallengeWeek, reason: "Challenge ratio (\(String(format: "%.2f", ratio))) below threshold (\(InsightsEngineConstants.highChallengeThreshold))")
        }

        let confidence = min(1.0, ratio / 2.0)  // Cap at 2:1 ratio

        return SignalResult(
            signalType: .highChallengeWeek,
            triggered: true,
            confidence: confidence,
            evidence: InsightEvidence(
                eventIds: (challengeEvents + positiveEvents).eventIds,
                window: .sevenDays,
                count: totalEvents
            ),
            explanation: "High challenge week: \(challengeCount) challenges vs \(positiveCount) positives (ratio: \(String(format: "%.2f", ratio)))",
            metadata: SignalMetadata(
                goalId: nil,
                goalName: nil,
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: nil,
                progress: nil,
                count: challengeCount,
                daysSinceOccurrence: nil
            )
        )
    }
}
