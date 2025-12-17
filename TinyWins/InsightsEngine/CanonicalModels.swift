import Foundation

// MARK: - Canonical Internal Representations

/// Unified event representation for insights analysis.
/// All events (wins, challenges, routines) are normalized to this format.
struct UnifiedEvent: Identifiable, Equatable {
    let id: String
    let childId: String
    let timestamp: Date
    let category: EventCategory
    let starsDelta: Int
    let behaviorTypeId: String
    let behaviorName: String
    let linkedGoalId: String?
    let caregiverId: String?

    enum EventCategory: String, Codable, Equatable {
        case routinePositive  // Daily routines completed
        case positive         // Wins / good behaviors
        case negative         // Challenges
    }

    var isPositive: Bool {
        category == .positive || category == .routinePositive
    }

    var isRoutine: Bool {
        category == .routinePositive
    }

    var isChallenge: Bool {
        category == .negative
    }
}

/// Canonical goal representation for insights analysis.
struct CanonicalGoal: Identifiable, Equatable {
    let id: String
    let childId: String
    let name: String
    let targetPoints: Int
    let currentPoints: Int
    let createdDate: Date
    let dueDate: Date?
    let isRedeemed: Bool
    let isExpired: Bool

    var hasDeadline: Bool {
        dueDate != nil
    }

    var progress: Double {
        guard targetPoints > 0 else { return 0 }
        return min(Double(currentPoints) / Double(targetPoints), 1.0)
    }

    var daysRemaining: Int? {
        guard let due = dueDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        return max(0, days)
    }

    var isAtRisk: Bool {
        guard let remaining = daysRemaining, targetPoints > currentPoints else { return false }
        let pointsNeeded = targetPoints - currentPoints
        // At risk if needing more than 3 points per day remaining
        return remaining > 0 && Double(pointsNeeded) / Double(remaining) > 3.0
    }
}

/// Canonical behavior type for insights analysis.
struct CanonicalBehavior: Identifiable, Equatable {
    let id: String
    let name: String
    let category: UnifiedEvent.EventCategory
    let defaultPoints: Int
    let isActive: Bool
}

/// Canonical child representation for insights analysis.
struct CanonicalChild: Identifiable, Equatable {
    let id: String
    let name: String
    let age: Int?
    let activeGoalId: String?
}

// MARK: - Time Windows

/// Standard time windows for analysis.
enum AnalysisWindow: Int, CaseIterable {
    case sevenDays = 7
    case fourteenDays = 14
    case thirtyDays = 30

    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -rawValue, to: now) ?? now
        return (start, now)
    }
}

// MARK: - Evidence Container

/// Evidence container that holds IDs of events supporting an insight.
struct InsightEvidence: Equatable {
    let eventIds: [String]
    let window: AnalysisWindow
    let count: Int

    var isValid: Bool {
        count >= InsightsEngineConstants.minimumEventsForInsight
    }

    static let empty = InsightEvidence(eventIds: [], window: .sevenDays, count: 0)
}

// MARK: - Constants

enum InsightsEngineConstants {
    /// Minimum events required to generate most insights
    static let minimumEventsForInsight = 3

    /// Minimum events for goal-at-risk (exception: can be 2 with deadline)
    static let minimumEventsForGoalAtRisk = 2

    /// Maximum cards to output
    static let maxCardsOutput = 6

    /// Cooldown period in days between same template for same child
    static let cooldownDays = 3

    /// Days considered "recent" for routine forming/slipping
    static let recentDays = 7

    /// Days to look back for routine history
    static let routineHistoryDays = 14

    /// Threshold ratio for high challenge week (challenges / positives)
    static let highChallengeThreshold = 1.0

    /// Minimum routine occurrences to consider "forming"
    static let routineFormingThreshold = 4

    /// Minimum gap days to consider routine "slipping"
    static let routineSlippingGapDays = 3

    /// Days without goal progress to consider "stalled"
    static let goalStalledDays = 5

    /// Maximum risk cards (goalAtRisk, highChallengeWeek) to show at once
    static let maxRiskCards = 1

    /// Maximum improvement cards (routineForming, routineSlipping, goalStalled) to show at once
    static let maxImprovementCards = 2

    /// Minimum evidence required by template
    static func minimumEvidence(for templateId: String) -> Int {
        switch templateId {
        case "goal_at_risk":
            return minimumEventsForGoalAtRisk
        case "insufficient_data":
            return 0  // No evidence required for insufficient data card
        default:
            return minimumEventsForInsight
        }
    }
}

// MARK: - Evidence Validation

/// Result of validating card evidence.
struct EvidenceValidationResult: Equatable {
    let isValid: Bool
    let reason: String?

    static let valid = EvidenceValidationResult(isValid: true, reason: nil)

    static func invalid(_ reason: String) -> EvidenceValidationResult {
        EvidenceValidationResult(isValid: false, reason: reason)
    }
}

/// Validates that card evidence is correct and sufficient.
enum EvidenceValidator {

    /// Validate a card's evidence against the canonical event list.
    static func validate(
        card: CoachCard,
        canonicalEventIds: Set<String>
    ) -> EvidenceValidationResult {
        let templateId = card.templateId

        // Check minimum evidence count
        let minRequired = InsightsEngineConstants.minimumEvidence(for: templateId)
        if card.evidenceEventIds.count < minRequired {
            return .invalid("Insufficient evidence: \(card.evidenceEventIds.count) < \(minRequired) required for \(templateId)")
        }

        // Check that all evidence IDs exist in canonical events
        let missingIds = card.evidenceEventIds.filter { !canonicalEventIds.contains($0) }
        if !missingIds.isEmpty {
            return .invalid("Evidence IDs not found in canonical events: \(missingIds.prefix(3).joined(separator: ", "))\(missingIds.count > 3 ? "..." : "")")
        }

        return .valid
    }

    /// Validate multiple cards and return only valid ones.
    /// Returns tuple of (validCards, invalidCardsWithReasons).
    static func filterValid(
        cards: [CoachCard],
        canonicalEventIds: Set<String>
    ) -> (valid: [CoachCard], invalid: [(card: CoachCard, reason: String)]) {
        var valid: [CoachCard] = []
        var invalid: [(card: CoachCard, reason: String)] = []

        for card in cards {
            let result = validate(card: card, canonicalEventIds: canonicalEventIds)
            if result.isValid {
                valid.append(card)
            } else {
                invalid.append((card, result.reason ?? "Unknown validation error"))
            }
        }

        return (valid, invalid)
    }
}
