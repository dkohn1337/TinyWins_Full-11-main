import Foundation

// MARK: - Card Template

/// A deterministic template for generating coaching cards.
/// Templates have fixed steps and variable interpolation for dynamic content.
struct CardTemplate: Identifiable, Equatable {
    let id: String
    let signalType: SignalType
    let basePriority: CardPriority
    let titleTemplate: String
    let oneLinerTemplate: String
    let steps: [String]
    let whySummaryTemplate: String
    let ctaType: CTAType

    enum CTAType: Equatable {
        case addMoment
        case goalDetail
        case goalsPicker
        case history(HistoryFilter.HistoryTypeFilterOption)
        case manageBehaviors
    }
}

// MARK: - Template Variables

/// Variables that can be interpolated into templates.
struct TemplateVariables {
    let childName: String
    let childId: String
    let goalName: String?
    let goalId: String?
    let behaviorName: String?
    let behaviorId: String?
    let count: Int
    let days: Int
    let daysRemaining: Int?
    let progress: Double?

    func interpolate(_ template: String) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{childName}", with: childName)
        result = result.replacingOccurrences(of: "{count}", with: "\(count)")
        result = result.replacingOccurrences(of: "{days}", with: "\(days)")

        if let goalName = goalName {
            result = result.replacingOccurrences(of: "{goalName}", with: goalName)
        }
        if let behaviorName = behaviorName {
            result = result.replacingOccurrences(of: "{behaviorName}", with: behaviorName)
        }
        if let daysRemaining = daysRemaining {
            result = result.replacingOccurrences(of: "{daysRemaining}", with: "\(daysRemaining)")
        }
        if let progress = progress {
            let percent = Int(progress * 100)
            result = result.replacingOccurrences(of: "{progress}", with: "\(percent)%")
        }

        return result
    }
}

// MARK: - Template Library

enum CardTemplateLibrary {

    // MARK: - Goal at Risk

    static let goalAtRisk = CardTemplate(
        id: "goal_at_risk",
        signalType: .goalAtRisk,
        basePriority: .urgent,
        titleTemplate: "{goalName} needs a push",
        oneLinerTemplate: "Only {daysRemaining} days left and {progress} complete.",
        steps: [
            "Focus on quick wins that earn stars",
            "Celebrate each step toward the goal",
            "Consider if the goal needs adjusting"
        ],
        whySummaryTemplate: "Based on {count} events in the last {days} days, the current pace may not reach the goal in time.",
        ctaType: .goalDetail
    )

    // MARK: - Goal Stalled

    static let goalStalled = CardTemplate(
        id: "goal_stalled",
        signalType: .goalStalled,
        basePriority: .high,
        titleTemplate: "{goalName} progress has paused",
        oneLinerTemplate: "No progress in the last {days} days.",
        steps: [
            "Check in with {childName} about the goal",
            "Look for small wins to log today",
            "Consider breaking the goal into smaller milestones"
        ],
        whySummaryTemplate: "No positive moments logged toward this goal in {days} days.",
        ctaType: .goalDetail
    )

    // MARK: - Routine Forming

    static let routineForming = CardTemplate(
        id: "routine_forming",
        signalType: .routineForming,
        basePriority: .medium,
        titleTemplate: "{behaviorName} is becoming a habit",
        oneLinerTemplate: "{childName} has done this {count} times in the last {days} days.",
        steps: [
            "Keep acknowledging when it happens",
            "Try not to overpraise - consistency matters more",
            "Notice if it happens at the same time each day"
        ],
        whySummaryTemplate: "{count} occurrences in {days} days shows a pattern forming.",
        ctaType: .history(.routines)
    )

    // MARK: - Routine Slipping

    static let routineSlipping = CardTemplate(
        id: "routine_slipping",
        signalType: .routineSlipping,
        basePriority: .high,
        titleTemplate: "{behaviorName} has been quiet",
        oneLinerTemplate: "Last logged {days} days ago after being consistent.",
        steps: [
            "Check if something changed in the routine",
            "Gently remind {childName} about this behavior",
            "Don't worry - habits can restart"
        ],
        whySummaryTemplate: "This routine was happening regularly but hasn't been logged in {days} days.",
        ctaType: .history(.routines)
    )

    // MARK: - High Challenge Week

    static let highChallengeWeek = CardTemplate(
        id: "high_challenge_week",
        signalType: .highChallengeWeek,
        basePriority: .medium,
        titleTemplate: "Tough stretch for {childName}",
        oneLinerTemplate: "{count} challenges logged in the last {days} days.",
        steps: [
            "Look for patterns in when challenges happen",
            "Try to catch and log more positive moments",
            "Consider if something external is affecting behavior"
        ],
        whySummaryTemplate: "More challenges than positive moments in the last {days} days. This is data, not a judgment.",
        ctaType: .history(.challenges)
    )

    // MARK: - All Templates

    static let all: [CardTemplate] = [
        goalAtRisk,
        goalStalled,
        routineForming,
        routineSlipping,
        highChallengeWeek
    ]

    static func template(for id: String) -> CardTemplate? {
        all.first { $0.id == id }
    }

    static func template(for signal: SignalType) -> CardTemplate? {
        all.first { $0.signalType == signal }
    }
}

// MARK: - Card Builder

enum CardBuilder {

    /// Build a CoachCard from a template and signal result.
    static func build(
        template: CardTemplate,
        signal: SignalResult,
        variables: TemplateVariables,
        expiresAt: Date
    ) -> CoachCard {

        let cta: CoachCTA
        switch template.ctaType {
        case .addMoment:
            cta = .openAddMoment(childId: variables.childId)
        case .goalDetail:
            if let goalId = variables.goalId {
                cta = .openGoalDetail(goalId: goalId)
            } else {
                cta = .openGoalsPicker(childId: variables.childId)
            }
        case .goalsPicker:
            cta = .openGoalsPicker(childId: variables.childId)
        case .history(let filterType):
            let filter = HistoryFilter(
                typeFilter: filterType,
                behaviorId: variables.behaviorId,
                timePeriod: variables.days
            )
            cta = .openHistory(childId: variables.childId, filter: filter)
        case .manageBehaviors:
            cta = .openManageBehaviors(childId: variables.childId)
        }

        // Determine primary entity for stable key
        let primaryEntityId = variables.goalId ?? variables.behaviorId

        // Generate deterministic ID based on template, child, entity, and window
        let stableIdBase = "\(template.id):\(variables.childId):\(primaryEntityId ?? "none"):\(variables.days)"
        let stableId = stableIdBase.data(using: .utf8).map {
            $0.reduce(0) { ($0 &* 31) &+ Int($1) }
        }.map { String(format: "%08x", abs($0)) } ?? UUID().uuidString

        // Build localization-ready content
        let localizedContent = buildLocalizedContent(
            template: template,
            variables: variables
        )

        return CoachCard(
            id: "\(template.id)-\(stableId)",
            childId: variables.childId,
            priority: calculatePriority(template: template, signal: signal),
            title: variables.interpolate(template.titleTemplate),
            oneLiner: variables.interpolate(template.oneLinerTemplate),
            steps: template.steps.map { variables.interpolate($0) },
            whySummary: variables.interpolate(template.whySummaryTemplate),
            evidenceEventIds: signal.evidence.eventIds,
            cta: cta,
            expiresAt: expiresAt,
            templateId: template.id,
            evidenceWindow: variables.days,
            primaryEntityId: primaryEntityId,
            localizedContent: localizedContent
        )
    }

    /// Build localization-ready content from template and variables.
    private static func buildLocalizedContent(
        template: CardTemplate,
        variables: TemplateVariables
    ) -> CoachCard.LocalizedContent {
        // Build common args dictionary
        var args: [String: String] = [
            "childName": variables.childName,
            "count": "\(variables.count)",
            "days": "\(variables.days)"
        ]
        if let goalName = variables.goalName {
            args["goalName"] = goalName
        }
        if let behaviorName = variables.behaviorName {
            args["behaviorName"] = behaviorName
        }
        if let daysRemaining = variables.daysRemaining {
            args["daysRemaining"] = "\(daysRemaining)"
        }
        if let progress = variables.progress {
            args["progress"] = "\(Int(progress * 100))%"
        }

        // Generate step keys
        let stepsKeys = (0..<template.steps.count).map { index in
            "insights.\(template.id).step_\(index + 1)"
        }

        return CoachCard.LocalizedContent(
            titleKey: "insights.\(template.id).title",
            titleArgs: args,
            oneLinerKey: "insights.\(template.id).one_liner",
            oneLinerArgs: args,
            stepsKeys: stepsKeys,
            stepsArgs: template.steps.map { _ in args },
            whyKey: "insights.\(template.id).why",
            whyArgs: args
        )
    }

    /// Calculate final priority based on template, signal, and recency.
    private static func calculatePriority(
        template: CardTemplate,
        signal: SignalResult
    ) -> Int {
        var priority = template.basePriority.rawValue

        // Boost for higher confidence
        if signal.confidence > 0.8 {
            priority += 1
        }

        // Boost for 7-day evidence (more recent = more relevant)
        if signal.evidence.window == .sevenDays {
            priority += 1
        }

        // Cap at critical
        return min(priority, CardPriority.critical.rawValue)
    }
}
