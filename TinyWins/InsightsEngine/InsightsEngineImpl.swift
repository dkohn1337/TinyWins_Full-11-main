import Foundation

// MARK: - Coaching Engine Protocol

/// Protocol for the deterministic coaching engine.
protocol CoachingEngine {
    /// Generate coaching cards for a specific child.
    /// IMPORTANT: This is a pure function - it does NOT record cooldowns.
    /// Call `recordCardsDisplayed` when cards are actually shown to the user.
    func generateCards(childId: String, now: Date) -> [CoachCard]

    /// Record that cards were displayed to the user.
    /// This triggers cooldown tracking - call ONLY when cards are actually shown.
    func recordCardsDisplayed(_ cards: [CoachCard], at date: Date)

    /// Generate a debug report for a specific child.
    func debugReport(childId: String, now: Date) -> InsightsDebugReport
}

// MARK: - Coaching Engine Implementation

/// Deterministic coaching engine that generates coaching cards based on evidence.
final class CoachingEngineImpl: CoachingEngine {

    // MARK: - Dependencies

    private let dataProvider: InsightsDataProvider
    private let cooldownManager: CooldownManager

    // MARK: - Init

    init(
        dataProvider: InsightsDataProvider,
        cooldownManager: CooldownManager = CooldownManager()
    ) {
        self.dataProvider = dataProvider
        self.cooldownManager = cooldownManager
    }

    // MARK: - Generate Cards

    func generateCards(childId: String, now: Date) -> [CoachCard] {
        // Fetch canonical data
        guard let child = dataProvider.child(id: childId) else {
            return []
        }

        let events = dataProvider.events(forChild: childId)
        let goals = dataProvider.goals(forChild: childId)
        let behaviors = dataProvider.routineBehaviors()

        // Pre-filter events once for all signal detectors (performance optimization)
        let preFiltered = PreFilteredEvents(childEvents: events)

        // Check for insufficient data using pre-filtered 14-day events
        if preFiltered.in14Days.count < InsightsEngineConstants.minimumEventsForInsight {
            return [CoachCard.insufficientData(
                childId: childId,
                childName: child.name,
                reason: "Only \(preFiltered.in14Days.count) moments logged in the last 14 days."
            )]
        }

        // Build canonical event ID set for evidence validation
        let canonicalEventIds = Set(events.map { $0.id })

        // Run all signal detectors using pre-filtered events
        var cards: [CoachCard] = []

        // Goal-related signals
        for goal in goals.activeOnly() {
            let atRisk = SignalDetectors.detectGoalAtRisk(goal: goal, preFiltered: preFiltered, now: now)
            if atRisk.triggered, let card = buildCard(signal: atRisk, child: child, now: now) {
                cards.append(card)
            }

            let stalled = SignalDetectors.detectGoalStalled(goal: goal, preFiltered: preFiltered, now: now)
            if stalled.triggered, let card = buildCard(signal: stalled, child: child, now: now) {
                cards.append(card)
            }
        }

        // Routine-related signals
        for behavior in behaviors {
            let forming = SignalDetectors.detectRoutineForming(
                behavior: behavior,
                preFiltered: preFiltered,
                childId: childId,
                now: now
            )
            if forming.triggered, let card = buildCard(signal: forming, child: child, now: now) {
                cards.append(card)
            }

            let slipping = SignalDetectors.detectRoutineSlipping(
                behavior: behavior,
                preFiltered: preFiltered,
                childId: childId,
                now: now
            )
            if slipping.triggered, let card = buildCard(signal: slipping, child: child, now: now) {
                cards.append(card)
            }
        }

        // Challenge signal
        let highChallenge = SignalDetectors.detectHighChallengeWeek(
            preFiltered: preFiltered,
            childId: childId,
            now: now
        )
        if highChallenge.triggered, let card = buildCard(signal: highChallenge, child: child, now: now) {
            cards.append(card)
        }

        // Validate evidence integrity
        let (validCards, _) = EvidenceValidator.filterValid(
            cards: cards,
            canonicalEventIds: canonicalEventIds
        )

        // Apply safety rails: limit risk and improvement cards
        let safeCards = applySafetyRails(validCards)

        // Rank and filter (pure - does not record cooldowns)
        let rankedCards = CardRanker.rankAndFilter(
            cards: safeCards,
            cooldownManager: cooldownManager,
            now: now
        )

        // NOTE: Cooldowns are NOT recorded here.
        // Call recordCardsDisplayed() when cards are actually shown to the user.

        return rankedCards
    }

    // MARK: - Safety Rails

    /// Apply safety rails to prevent overwhelming parents.
    /// - Max 1 risk card (goalAtRisk, highChallengeWeek)
    /// - Max 2 improvement cards (routineForming, routineSlipping, goalStalled)
    private func applySafetyRails(_ cards: [CoachCard]) -> [CoachCard] {
        let riskTemplates: Set<String> = ["goal_at_risk", "high_challenge_week"]
        let improvementTemplates: Set<String> = ["goal_stalled", "routine_forming", "routine_slipping"]

        var result: [CoachCard] = []
        var riskCount = 0
        var improvementCount = 0

        // Sort by priority first to keep the most important cards
        let sortedCards = cards.sorted { $0.priority > $1.priority }

        for card in sortedCards {
            if riskTemplates.contains(card.templateId) {
                if riskCount < InsightsEngineConstants.maxRiskCards {
                    result.append(card)
                    riskCount += 1
                }
            } else if improvementTemplates.contains(card.templateId) {
                if improvementCount < InsightsEngineConstants.maxImprovementCards {
                    result.append(card)
                    improvementCount += 1
                }
            } else {
                // Other cards pass through
                result.append(card)
            }
        }

        return result
    }

    // MARK: - Record Display

    func recordCardsDisplayed(_ cards: [CoachCard], at date: Date) {
        CardRanker.recordCardsShown(
            cards: cards,
            cooldownManager: cooldownManager,
            at: date
        )
    }

    // MARK: - Build Card

    private func buildCard(
        signal: SignalResult,
        child: CanonicalChild,
        now: Date
    ) -> CoachCard? {
        guard let template = CardTemplateLibrary.template(for: signal.signalType) else {
            return nil
        }

        let variables = TemplateVariables(
            childName: child.name,
            childId: child.id,
            goalName: signal.metadata.goalName,
            goalId: signal.metadata.goalId,
            behaviorName: signal.metadata.behaviorName,
            behaviorId: signal.metadata.behaviorId,
            count: signal.metadata.count ?? signal.evidence.count,
            days: signal.evidence.window.rawValue,
            daysRemaining: signal.metadata.daysRemaining,
            progress: signal.metadata.progress
        )

        let expiresAt = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: now
        ) ?? now

        return CardBuilder.build(
            template: template,
            signal: signal,
            variables: variables,
            expiresAt: expiresAt
        )
    }

    // MARK: - Debug Report

    func debugReport(childId: String, now: Date) -> InsightsDebugReport {
        guard let child = dataProvider.child(id: childId) else {
            return InsightsDebugReport(
                childId: childId,
                childName: nil,
                generatedAt: now,
                signalResults: [],
                builtCards: [],
                droppedCards: [],
                selectedCards: [],
                activeCooldowns: [],
                dataStats: InsightsDebugReport.DataStats(
                    totalEvents14Days: 0,
                    positiveEvents7Days: 0,
                    challengeEvents7Days: 0,
                    routineEvents7Days: 0,
                    activeGoals: 0,
                    routineBehaviors: 0
                )
            )
        }

        let events = dataProvider.events(forChild: childId)
        let goals = dataProvider.goals(forChild: childId)
        let behaviors = dataProvider.routineBehaviors()
        let canonicalEventIds = Set(events.map { $0.id })

        // Pre-filter events once for all signal detectors (performance optimization)
        let preFiltered = PreFilteredEvents(childEvents: events)

        // Collect all signal results
        var signalResults: [SignalResult] = []

        // Goal-related signals (using pre-filtered events)
        for goal in goals.activeOnly() {
            signalResults.append(SignalDetectors.detectGoalAtRisk(goal: goal, preFiltered: preFiltered, now: now))
            signalResults.append(SignalDetectors.detectGoalStalled(goal: goal, preFiltered: preFiltered, now: now))
        }

        // Routine-related signals (using pre-filtered events)
        for behavior in behaviors {
            signalResults.append(SignalDetectors.detectRoutineForming(
                behavior: behavior,
                preFiltered: preFiltered,
                childId: childId,
                now: now
            ))
            signalResults.append(SignalDetectors.detectRoutineSlipping(
                behavior: behavior,
                preFiltered: preFiltered,
                childId: childId,
                now: now
            ))
        }

        // Challenge signal (using pre-filtered events)
        signalResults.append(SignalDetectors.detectHighChallengeWeek(
            preFiltered: preFiltered,
            childId: childId,
            now: now
        ))

        // Build cards from triggered signals
        let builtCards = signalResults
            .filter { $0.triggered }
            .compactMap { buildCard(signal: $0, child: child, now: now) }

        // Track dropped cards
        var droppedCards: [InsightsDebugReport.DroppedCard] = []

        // Step 1: Evidence validation
        let (validCards, invalidCards) = EvidenceValidator.filterValid(
            cards: builtCards,
            canonicalEventIds: canonicalEventIds
        )
        for (card, reason) in invalidCards {
            droppedCards.append(InsightsDebugReport.DroppedCard(
                card: card,
                reason: .evidenceInvalid,
                details: reason
            ))
        }

        // Step 2: Safety rails
        let safeCards = applySafetyRailsWithTracking(validCards, droppedCards: &droppedCards)

        // Step 3: Cooldown filtering
        var cooldownFiltered: [CoachCard] = []
        for card in safeCards {
            if cooldownManager.isOnCooldown(templateId: card.templateId, childId: card.childId, now: now) {
                let endDate = cooldownManager.cooldownEndDate(templateId: card.templateId, childId: card.childId)
                let endDateStr = endDate.map { formatDateShort($0) } ?? "unknown"
                droppedCards.append(InsightsDebugReport.DroppedCard(
                    card: card,
                    reason: .cooldownActive,
                    details: "Cooldown ends \(endDateStr)"
                ))
            } else {
                cooldownFiltered.append(card)
            }
        }

        // Step 4: Ranking and limit
        let sortedCards = cooldownFiltered.sorted { a, b in
            if a.priority != b.priority { return a.priority > b.priority }
            if a.evidenceWindow != b.evidenceWindow { return a.evidenceWindow < b.evidenceWindow }
            if a.evidenceEventIds.count != b.evidenceEventIds.count { return a.evidenceEventIds.count > b.evidenceEventIds.count }
            return a.templateId < b.templateId
        }

        let selectedCards = Array(sortedCards.prefix(InsightsEngineConstants.maxCardsOutput))
        let cutoffCards = sortedCards.dropFirst(InsightsEngineConstants.maxCardsOutput)
        for card in cutoffCards {
            droppedCards.append(InsightsDebugReport.DroppedCard(
                card: card,
                reason: .rankingCutoff,
                details: "Exceeded max \(InsightsEngineConstants.maxCardsOutput) cards limit"
            ))
        }

        // Get active cooldowns
        let cooldowns = cooldownManager.activeCooldowns(now: now)

        // Calculate stats using pre-filtered events
        let routineEvents7Days = preFiltered.in7Days.filter { $0.isRoutine }

        let stats = InsightsDebugReport.DataStats(
            totalEvents14Days: preFiltered.in14Days.count,
            positiveEvents7Days: preFiltered.positiveIn7Days.count,
            challengeEvents7Days: preFiltered.challengesIn7Days.count,
            routineEvents7Days: routineEvents7Days.count,
            activeGoals: goals.activeOnly().count,
            routineBehaviors: behaviors.count
        )

        return InsightsDebugReport(
            childId: childId,
            childName: child.name,
            generatedAt: now,
            signalResults: signalResults,
            builtCards: builtCards,
            droppedCards: droppedCards,
            selectedCards: selectedCards,
            activeCooldowns: cooldowns.map { InsightsDebugReport.CooldownInfo(
                templateId: $0.templateId,
                childId: $0.childId,
                endsAt: $0.endsAt
            )},
            dataStats: stats
        )
    }

    /// Apply safety rails with tracking for debug report.
    private func applySafetyRailsWithTracking(
        _ cards: [CoachCard],
        droppedCards: inout [InsightsDebugReport.DroppedCard]
    ) -> [CoachCard] {
        let riskTemplates: Set<String> = ["goal_at_risk", "high_challenge_week"]
        let improvementTemplates: Set<String> = ["goal_stalled", "routine_forming", "routine_slipping"]

        var result: [CoachCard] = []
        var riskCount = 0
        var improvementCount = 0

        let sortedCards = cards.sorted { $0.priority > $1.priority }

        for card in sortedCards {
            if riskTemplates.contains(card.templateId) {
                if riskCount < InsightsEngineConstants.maxRiskCards {
                    result.append(card)
                    riskCount += 1
                } else {
                    droppedCards.append(InsightsDebugReport.DroppedCard(
                        card: card,
                        reason: .safetyRailRisk,
                        details: "Already have \(InsightsEngineConstants.maxRiskCards) risk card(s)"
                    ))
                }
            } else if improvementTemplates.contains(card.templateId) {
                if improvementCount < InsightsEngineConstants.maxImprovementCards {
                    result.append(card)
                    improvementCount += 1
                } else {
                    droppedCards.append(InsightsDebugReport.DroppedCard(
                        card: card,
                        reason: .safetyRailImprovement,
                        details: "Already have \(InsightsEngineConstants.maxImprovementCards) improvement card(s)"
                    ))
                }
            } else {
                result.append(card)
            }
        }

        return result
    }

    private func formatDateShort(_ date: Date) -> String {
        DateFormatters.shortDate.string(from: date)
    }
}

// MARK: - Data Provider Protocol

/// Protocol for providing data to the insights engine.
protocol InsightsDataProvider {
    func child(id: String) -> CanonicalChild?
    func events(forChild childId: String) -> [UnifiedEvent]
    func goals(forChild childId: String) -> [CanonicalGoal]
    func routineBehaviors() -> [CanonicalBehavior]
    func allBehaviors() -> [CanonicalBehavior]
}

// MARK: - Repository Adapter

/// Adapter that connects InsightsEngine to the app's Repository.
final class RepositoryDataProvider: InsightsDataProvider {

    private let repository: Repository

    init(repository: Repository) {
        self.repository = repository
    }

    func child(id: String) -> CanonicalChild? {
        guard let uuid = UUID(uuidString: id),
              let child = repository.appData.children.first(where: { $0.id == uuid }) else {
            return nil
        }
        return ModelAdapters.toCanonicalChild(child)
    }

    func events(forChild childId: String) -> [UnifiedEvent] {
        guard let uuid = UUID(uuidString: childId) else { return [] }

        let childEvents = repository.appData.behaviorEvents.filter { $0.childId == uuid }
        return ModelAdapters.toUnifiedEvents(childEvents, behaviorTypes: repository.appData.behaviorTypes)
    }

    func goals(forChild childId: String) -> [CanonicalGoal] {
        guard let uuid = UUID(uuidString: childId),
              let child = repository.appData.children.first(where: { $0.id == uuid }) else {
            return []
        }

        let childRewards = repository.appData.rewards.filter { $0.childId == uuid }
        let childEvents = repository.appData.behaviorEvents.filter { $0.childId == uuid }

        return ModelAdapters.toCanonicalGoals(
            childRewards,
            events: childEvents,
            activeRewardId: child.activeRewardId
        )
    }

    func routineBehaviors() -> [CanonicalBehavior] {
        repository.appData.behaviorTypes
            .filter { $0.category == .routinePositive && $0.isActive }
            .map { ModelAdapters.toCanonicalBehavior($0) }
    }

    func allBehaviors() -> [CanonicalBehavior] {
        ModelAdapters.toCanonicalBehaviors(repository.appData.behaviorTypes)
    }
}
