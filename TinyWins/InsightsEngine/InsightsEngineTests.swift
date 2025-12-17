import Foundation

// MARK: - Insights Engine Tests

/// Unit tests for the InsightsEngine.
/// To run: Add this file to a test target and run with XCTest.
///
/// These tests validate:
/// - Each signal triggers only when thresholds are met
/// - Evidence event IDs are correct
/// - Insufficient data path works
/// - Cooldown works
/// - Ranking rules are stable

#if DEBUG

// MARK: - Mock Data Provider

final class MockInsightsDataProvider: InsightsDataProvider {
    var mockChild: CanonicalChild?
    var mockEvents: [UnifiedEvent] = []
    var mockGoals: [CanonicalGoal] = []
    var mockRoutineBehaviors: [CanonicalBehavior] = []
    var mockAllBehaviors: [CanonicalBehavior] = []

    func child(id: String) -> CanonicalChild? {
        mockChild
    }

    func events(forChild childId: String) -> [UnifiedEvent] {
        mockEvents.filter { $0.childId == childId }
    }

    func goals(forChild childId: String) -> [CanonicalGoal] {
        mockGoals.filter { $0.childId == childId }
    }

    func routineBehaviors() -> [CanonicalBehavior] {
        mockRoutineBehaviors
    }

    func allBehaviors() -> [CanonicalBehavior] {
        mockAllBehaviors
    }
}

// MARK: - Test Helpers

enum TestHelpers {

    static let testChildId = "test-child-123"
    static let testGoalId = "test-goal-456"
    static let testBehaviorId = "test-behavior-789"

    static func makeChild(
        id: String = testChildId,
        name: String = "Test Child",
        age: Int? = 8
    ) -> CanonicalChild {
        CanonicalChild(
            id: id,
            name: name,
            age: age,
            activeGoalId: nil
        )
    }

    static func makeEvent(
        id: String = UUID().uuidString,
        childId: String = testChildId,
        timestamp: Date = Date(),
        category: UnifiedEvent.EventCategory = .positive,
        starsDelta: Int = 1,
        behaviorTypeId: String = testBehaviorId,
        behaviorName: String = "Test Behavior"
    ) -> UnifiedEvent {
        UnifiedEvent(
            id: id,
            childId: childId,
            timestamp: timestamp,
            category: category,
            starsDelta: starsDelta,
            behaviorTypeId: behaviorTypeId,
            behaviorName: behaviorName,
            linkedGoalId: nil,
            caregiverId: nil
        )
    }

    static func makeGoal(
        id: String = testGoalId,
        childId: String = testChildId,
        name: String = "Test Goal",
        targetPoints: Int = 50,
        currentPoints: Int = 20,
        dueDate: Date? = nil,
        isRedeemed: Bool = false
    ) -> CanonicalGoal {
        CanonicalGoal(
            id: id,
            childId: childId,
            name: name,
            targetPoints: targetPoints,
            currentPoints: currentPoints,
            createdDate: Date().addingTimeInterval(-86400 * 7),
            dueDate: dueDate,
            isRedeemed: isRedeemed,
            isExpired: false
        )
    }

    static func makeRoutineBehavior(
        id: String = testBehaviorId,
        name: String = "Brush Teeth"
    ) -> CanonicalBehavior {
        CanonicalBehavior(
            id: id,
            name: name,
            category: .routinePositive,
            defaultPoints: 1,
            isActive: true
        )
    }

    static func eventsInPast(days: Int, count: Int, category: UnifiedEvent.EventCategory = .positive) -> [UnifiedEvent] {
        let now = Date()
        return (0..<count).map { i in
            let daysAgo = Double(i % days)
            let timestamp = now.addingTimeInterval(-86400 * daysAgo - Double(i * 3600))
            return makeEvent(
                id: "event-\(i)",
                timestamp: timestamp,
                category: category
            )
        }
    }
}

// MARK: - Test Cases

struct InsightsEngineTestRunner {

    // MARK: - Signal Threshold Tests

    static func testGoalAtRiskTriggersWithDeadline() -> Bool {
        let now = Date()
        let goal = TestHelpers.makeGoal(
            targetPoints: 100,
            currentPoints: 20,
            dueDate: now.addingTimeInterval(86400 * 5) // 5 days left
        )

        // Create events showing slow pace
        let events = (0..<5).map { i in
            TestHelpers.makeEvent(
                id: "event-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                starsDelta: 1
            )
        }

        let result = SignalDetectors.detectGoalAtRisk(goal: goal, events: events, now: now)

        // Should trigger: need 80 points in 5 days (16/day) but only earning ~1/day
        return result.triggered && result.confidence > 0.5
    }

    static func testGoalAtRiskDoesNotTriggerWithoutDeadline() -> Bool {
        let now = Date()
        let goal = TestHelpers.makeGoal(
            targetPoints: 100,
            currentPoints: 20,
            dueDate: nil // No deadline
        )

        let events = TestHelpers.eventsInPast(days: 7, count: 5)

        let result = SignalDetectors.detectGoalAtRisk(goal: goal, events: events, now: now)

        return !result.triggered
    }

    static func testGoalStalledTriggersAfterGap() -> Bool {
        let now = Date()
        let goal = TestHelpers.makeGoal()

        // Create events that stop 6 days ago
        let events = (0..<5).map { i in
            TestHelpers.makeEvent(
                id: "event-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(6 + i))
            )
        }

        let result = SignalDetectors.detectGoalStalled(goal: goal, events: events, now: now)

        return result.triggered
    }

    static func testGoalStalledDoesNotTriggerWithRecentActivity() -> Bool {
        let now = Date()
        let goal = TestHelpers.makeGoal()

        // Create events including recent ones
        let events = (0..<5).map { i in
            TestHelpers.makeEvent(
                id: "event-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i))
            )
        }

        let result = SignalDetectors.detectGoalStalled(goal: goal, events: events, now: now)

        return !result.triggered
    }

    static func testRoutineFormingTriggersWithConsistency() -> Bool {
        let now = Date()
        let behavior = TestHelpers.makeRoutineBehavior()

        // Create 5 routine events across 4 different days
        var events: [UnifiedEvent] = []
        for i in 0..<5 {
            events.append(TestHelpers.makeEvent(
                id: "event-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i % 4)),
                category: .routinePositive,
                behaviorTypeId: behavior.id
            ))
        }

        let result = SignalDetectors.detectRoutineForming(
            behavior: behavior,
            events: events,
            childId: TestHelpers.testChildId,
            now: now
        )

        return result.triggered
    }

    static func testRoutineFormingDoesNotTriggerWithFewEvents() -> Bool {
        let now = Date()
        let behavior = TestHelpers.makeRoutineBehavior()

        // Only 2 events - below threshold
        let events = (0..<2).map { i in
            TestHelpers.makeEvent(
                id: "event-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .routinePositive,
                behaviorTypeId: behavior.id
            )
        }

        let result = SignalDetectors.detectRoutineForming(
            behavior: behavior,
            events: events,
            childId: TestHelpers.testChildId,
            now: now
        )

        return !result.triggered
    }

    static func testRoutineSlippingTriggersAfterGap() -> Bool {
        let now = Date()
        let behavior = TestHelpers.makeRoutineBehavior()

        // Create events: consistent 7-14 days ago, nothing in last 7 days
        var events: [UnifiedEvent] = []
        for i in 0..<5 {
            events.append(TestHelpers.makeEvent(
                id: "event-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(8 + i)),
                category: .routinePositive,
                behaviorTypeId: behavior.id
            ))
        }

        let result = SignalDetectors.detectRoutineSlipping(
            behavior: behavior,
            events: events,
            childId: TestHelpers.testChildId,
            now: now
        )

        return result.triggered
    }

    static func testHighChallengeWeekTriggersWhenChallengesExceedPositives() -> Bool {
        let now = Date()

        var events: [UnifiedEvent] = []

        // 4 challenges
        for i in 0..<4 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }

        // 2 positives
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }

        let result = SignalDetectors.detectHighChallengeWeek(
            events: events,
            childId: TestHelpers.testChildId,
            now: now
        )

        return result.triggered
    }

    static func testHighChallengeWeekDoesNotTriggerWhenPositivesDominate() -> Bool {
        let now = Date()

        var events: [UnifiedEvent] = []

        // 2 challenges
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }

        // 5 positives
        for i in 0..<5 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }

        let result = SignalDetectors.detectHighChallengeWeek(
            events: events,
            childId: TestHelpers.testChildId,
            now: now
        )

        return !result.triggered
    }

    // MARK: - Evidence Tests

    static func testEvidenceEventIdsAreCorrect() -> Bool {
        let now = Date()

        let eventIds = ["event-1", "event-2", "event-3", "event-4"]
        let events = eventIds.enumerated().map { i, id in
            TestHelpers.makeEvent(
                id: id,
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            )
        }

        let result = SignalDetectors.detectHighChallengeWeek(
            events: events,
            childId: TestHelpers.testChildId,
            now: now
        )

        // Evidence should contain the event IDs
        let evidenceIds = Set(result.evidence.eventIds)
        let expectedIds = Set(eventIds)

        return evidenceIds.isSuperset(of: expectedIds)
    }

    // MARK: - Insufficient Data Tests

    static func testInsufficientDataReturnsSpecialCard() -> Bool {
        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()
        dataProvider.mockEvents = [
            TestHelpers.makeEvent() // Only 1 event
        ]
        dataProvider.mockGoals = []
        dataProvider.mockRoutineBehaviors = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider)
        let cards = engine.generateCards(childId: TestHelpers.testChildId, now: Date())

        guard cards.count == 1 else { return false }
        return cards[0].templateId == "insufficient_data"
    }

    // MARK: - Cooldown Tests

    static func testCooldownPreventsRepeatCards() -> Bool {
        let cooldownManager = CooldownManager(userDefaults: UserDefaults(suiteName: "test")!)
        cooldownManager.clearAllCooldowns()

        let templateId = "goal_at_risk"
        let childId = TestHelpers.testChildId
        let now = Date()

        // Record that template was shown
        cooldownManager.recordShown(templateId: templateId, childId: childId, at: now)

        // Should be on cooldown now
        let isOnCooldown = cooldownManager.isOnCooldown(templateId: templateId, childId: childId, now: now)

        // Should not be on cooldown after cooldown period
        let afterCooldown = now.addingTimeInterval(86400 * Double(InsightsEngineConstants.cooldownDays + 1))
        let isStillOnCooldown = cooldownManager.isOnCooldown(templateId: templateId, childId: childId, now: afterCooldown)

        return isOnCooldown && !isStillOnCooldown
    }

    // MARK: - Ranking Tests

    static func testRankingPrioritizesHigherPriority() -> Bool {
        let cooldownManager = CooldownManager(userDefaults: UserDefaults(suiteName: "test")!)
        cooldownManager.clearAllCooldowns()

        let lowPriorityCard = CoachCard(
            id: "low",
            childId: TestHelpers.testChildId,
            priority: 2,
            title: "Low Priority",
            oneLiner: "Test",
            steps: [],
            whySummary: "Test",
            evidenceEventIds: [],
            cta: .openAddMoment(childId: TestHelpers.testChildId),
            expiresAt: Date().addingTimeInterval(86400),
            templateId: "low",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        )

        let highPriorityCard = CoachCard(
            id: "high",
            childId: TestHelpers.testChildId,
            priority: 5,
            title: "High Priority",
            oneLiner: "Test",
            steps: [],
            whySummary: "Test",
            evidenceEventIds: [],
            cta: .openAddMoment(childId: TestHelpers.testChildId),
            expiresAt: Date().addingTimeInterval(86400),
            templateId: "high",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        )

        let ranked = CardRanker.rankAndFilter(
            cards: [lowPriorityCard, highPriorityCard],
            cooldownManager: cooldownManager
        )

        return ranked.first?.id == "high"
    }

    static func testRankingRespectsMaxLimit() -> Bool {
        let cooldownManager = CooldownManager(userDefaults: UserDefaults(suiteName: "test")!)
        cooldownManager.clearAllCooldowns()

        // Create more cards than the limit
        let cards = (0..<10).map { i in
            CoachCard(
                id: "card-\(i)",
                childId: TestHelpers.testChildId,
                priority: i,
                title: "Card \(i)",
                oneLiner: "Test",
                steps: [],
                whySummary: "Test",
                evidenceEventIds: [],
                cta: .openAddMoment(childId: TestHelpers.testChildId),
                expiresAt: Date().addingTimeInterval(86400),
                templateId: "template-\(i)",
                evidenceWindow: 7,
                primaryEntityId: nil,
                localizedContent: nil
            )
        }

        let ranked = CardRanker.rankAndFilter(
            cards: cards,
            cooldownManager: cooldownManager
        )

        return ranked.count <= InsightsEngineConstants.maxCardsOutput
    }

    // MARK: - A: Cooldown Separation Tests

    /// Test that generateCards() is pure and doesn't record cooldowns
    static func testGenerateCardsDoesNotRecordCooldowns() -> Bool {
        let testDefaults = UserDefaults(suiteName: "test-cooldown-separation")!
        let cooldownManager = CooldownManager(userDefaults: testDefaults)
        cooldownManager.clearAllCooldowns()

        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()

        // Create enough events to trigger high challenge week
        var events: [UnifiedEvent] = []
        let now = Date()
        for i in 0..<6 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }
        dataProvider.mockEvents = events
        dataProvider.mockGoals = []
        dataProvider.mockRoutineBehaviors = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider, cooldownManager: cooldownManager)

        // Generate cards twice - should return same cards since cooldowns not recorded
        let cards1 = engine.generateCards(childId: TestHelpers.testChildId, now: now)
        let cards2 = engine.generateCards(childId: TestHelpers.testChildId, now: now)

        // If cooldowns were recorded, second call would return fewer/different cards
        return cards1.count == cards2.count
    }

    /// Test that recordCardsDisplayed() does record cooldowns
    static func testRecordCardsDisplayedRecordsCooldowns() -> Bool {
        let testDefaults = UserDefaults(suiteName: "test-cooldown-recording")!
        let cooldownManager = CooldownManager(userDefaults: testDefaults)
        cooldownManager.clearAllCooldowns()

        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()

        // Create events to trigger high challenge week
        var events: [UnifiedEvent] = []
        let now = Date()
        for i in 0..<6 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }
        dataProvider.mockEvents = events
        dataProvider.mockGoals = []
        dataProvider.mockRoutineBehaviors = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider, cooldownManager: cooldownManager)

        let cards1 = engine.generateCards(childId: TestHelpers.testChildId, now: now)
        guard !cards1.isEmpty else { return false }

        // Record that cards were displayed
        engine.recordCardsDisplayed(cards1, at: now)

        // Now the same templates should be on cooldown
        let cards2 = engine.generateCards(childId: TestHelpers.testChildId, now: now)

        // Cards should be different (fewer) because cooldowns are now active
        return cards2.count < cards1.count || cards2.isEmpty
    }

    // MARK: - B: Determinism Tests

    /// Test that sorting is deterministic with same priority
    static func testDeterministicSortingWithTieBreakers() -> Bool {
        let cooldownManager = CooldownManager(userDefaults: UserDefaults(suiteName: "test-determinism")!)
        cooldownManager.clearAllCooldowns()

        // Create cards with same priority but different tie-breaker values
        let cards = [
            CoachCard(
                id: "card-a",
                childId: TestHelpers.testChildId,
                priority: 3,
                title: "Card A",
                oneLiner: "Test",
                steps: [],
                whySummary: "Test",
                evidenceEventIds: ["e1", "e2", "e3"],
                cta: .openAddMoment(childId: TestHelpers.testChildId),
                expiresAt: Date().addingTimeInterval(86400),
                templateId: "zebra",  // Lexicographically last
                evidenceWindow: 14,    // Longer window
                primaryEntityId: nil,
                localizedContent: nil
            ),
            CoachCard(
                id: "card-b",
                childId: TestHelpers.testChildId,
                priority: 3,
                title: "Card B",
                oneLiner: "Test",
                steps: [],
                whySummary: "Test",
                evidenceEventIds: ["e1", "e2"],
                cta: .openAddMoment(childId: TestHelpers.testChildId),
                expiresAt: Date().addingTimeInterval(86400),
                templateId: "alpha",  // Lexicographically first
                evidenceWindow: 7,     // Shorter window (more recent = higher priority)
                primaryEntityId: nil,
                localizedContent: nil
            ),
            CoachCard(
                id: "card-c",
                childId: TestHelpers.testChildId,
                priority: 3,
                title: "Card C",
                oneLiner: "Test",
                steps: [],
                whySummary: "Test",
                evidenceEventIds: ["e1", "e2"],
                cta: .openAddMoment(childId: TestHelpers.testChildId),
                expiresAt: Date().addingTimeInterval(86400),
                templateId: "beta",
                evidenceWindow: 7,
                primaryEntityId: nil,
                localizedContent: nil
            )
        ]

        // Run multiple times - should always get same order
        let ranked1 = CardRanker.rankAndFilter(cards: cards, cooldownManager: cooldownManager)
        let ranked2 = CardRanker.rankAndFilter(cards: cards, cooldownManager: cooldownManager)
        let ranked3 = CardRanker.rankAndFilter(cards: cards.reversed(), cooldownManager: cooldownManager)

        let ids1 = ranked1.map { $0.id }
        let ids2 = ranked2.map { $0.id }
        let ids3 = ranked3.map { $0.id }

        // All should be identical
        return ids1 == ids2 && ids2 == ids3
    }

    /// Test that stableKey is deterministic
    static func testStableKeyIsDeterministic() -> Bool {
        let card1 = CoachCard(
            id: "unique-1",
            childId: "child-123",
            priority: 3,
            title: "Test",
            oneLiner: "Test",
            steps: [],
            whySummary: "Test",
            evidenceEventIds: [],
            cta: .openAddMoment(childId: "child-123"),
            expiresAt: Date().addingTimeInterval(86400),
            templateId: "goal_at_risk",
            evidenceWindow: 7,
            primaryEntityId: "goal-456",
            localizedContent: nil
        )

        let card2 = CoachCard(
            id: "unique-2",  // Different runtime ID
            childId: "child-123",
            priority: 5,    // Different priority
            title: "Different Title",
            oneLiner: "Different",
            steps: ["step1"],
            whySummary: "Different",
            evidenceEventIds: ["e1", "e2"],
            cta: .openGoalDetail(goalId: "goal-456"),
            expiresAt: Date().addingTimeInterval(86400 * 2),
            templateId: "goal_at_risk",
            evidenceWindow: 7,
            primaryEntityId: "goal-456",
            localizedContent: nil
        )

        // Same stableKey despite different instance details
        return card1.stableKey == card2.stableKey
    }

    /// Test that card IDs from CardBuilder are deterministic
    static func testCardBuilderGeneratesDeterministicIds() -> Bool {
        let template = CardTemplateLibrary.goalAtRisk
        let signal = SignalResult(
            signalType: .goalAtRisk,
            triggered: true,
            confidence: 0.8,
            evidence: InsightEvidence(eventIds: ["e1", "e2"], window: .sevenDays, count: 2),
            explanation: "Test",
            metadata: SignalMetadata(
                goalId: "goal-123",
                goalName: "Test Goal",
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: 5,
                progress: 0.3,
                count: nil,
                daysSinceOccurrence: nil
            )
        )
        let variables = TemplateVariables(
            childName: "Emma",
            childId: "child-456",
            goalName: "Test Goal",
            goalId: "goal-123",
            behaviorName: nil,
            behaviorId: nil,
            count: 2,
            days: 7,
            daysRemaining: 5,
            progress: 0.3
        )
        let expiresAt = Date().addingTimeInterval(86400)

        let card1 = CardBuilder.build(template: template, signal: signal, variables: variables, expiresAt: expiresAt)
        let card2 = CardBuilder.build(template: template, signal: signal, variables: variables, expiresAt: expiresAt)

        // IDs should be identical
        return card1.id == card2.id
    }

    // MARK: - C: Evidence Validator Tests

    /// Test that evidence validator filters invalid evidence
    static func testEvidenceValidatorFiltersInvalidEvidence() -> Bool {
        let canonicalIds: Set<String> = ["e1", "e2", "e3"]

        let validCard = CoachCard(
            id: "valid",
            childId: TestHelpers.testChildId,
            priority: 3,
            title: "Valid",
            oneLiner: "Test",
            steps: [],
            whySummary: "Test",
            evidenceEventIds: ["e1", "e2"],  // All exist in canonical
            cta: .openAddMoment(childId: TestHelpers.testChildId),
            expiresAt: Date().addingTimeInterval(86400),
            templateId: "goal_at_risk",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        )

        let invalidCard = CoachCard(
            id: "invalid",
            childId: TestHelpers.testChildId,
            priority: 3,
            title: "Invalid",
            oneLiner: "Test",
            steps: [],
            whySummary: "Test",
            evidenceEventIds: ["e1", "phantom-id"],  // phantom-id doesn't exist
            cta: .openAddMoment(childId: TestHelpers.testChildId),
            expiresAt: Date().addingTimeInterval(86400),
            templateId: "goal_stalled",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        )

        let (valid, invalid) = EvidenceValidator.filterValid(
            cards: [validCard, invalidCard],
            canonicalEventIds: canonicalIds
        )

        return valid.count == 1 && valid[0].id == "valid" && invalid.count == 1 && invalid[0].card.id == "invalid"
    }

    /// Test evidence validation result details
    static func testEvidenceValidationResultDetails() -> Bool {
        let canonicalIds: Set<String> = ["e1", "e2"]

        let card = CoachCard(
            id: "test",
            childId: TestHelpers.testChildId,
            priority: 3,
            title: "Test",
            oneLiner: "Test",
            steps: [],
            whySummary: "Test",
            evidenceEventIds: ["e1", "phantom"],
            cta: .openAddMoment(childId: TestHelpers.testChildId),
            expiresAt: Date().addingTimeInterval(86400),
            templateId: "goal_at_risk",
            evidenceWindow: 7,
            primaryEntityId: nil,
            localizedContent: nil
        )

        let result = EvidenceValidator.validate(card: card, canonicalEventIds: canonicalIds)

        // Result should be invalid with a reason mentioning the phantom ID
        return !result.isValid && (result.reason?.contains("phantom") ?? false)
    }

    // MARK: - D: Signal Registry Tests

    /// Test isRiskSignal property
    static func testSignalTypeRiskClassification() -> Bool {
        let riskSignals: [SignalType] = [.goalAtRisk, .highChallengeWeek]
        let nonRiskSignals: [SignalType] = [.goalStalled, .routineForming, .routineSlipping]

        let riskCorrect = riskSignals.allSatisfy { $0.isRiskSignal }
        let nonRiskCorrect = nonRiskSignals.allSatisfy { !$0.isRiskSignal }

        return riskCorrect && nonRiskCorrect
    }

    /// Test isImprovementSignal property
    static func testSignalTypeImprovementClassification() -> Bool {
        let improvementSignals: [SignalType] = [.goalStalled, .routineForming, .routineSlipping]
        let nonImprovementSignals: [SignalType] = [.goalAtRisk, .highChallengeWeek]

        let improvementCorrect = improvementSignals.allSatisfy { $0.isImprovementSignal }
        let nonImprovementCorrect = nonImprovementSignals.allSatisfy { !$0.isImprovementSignal }

        return improvementCorrect && nonImprovementCorrect
    }

    // MARK: - E: Debug Report Tests

    /// Test that debug report tracks dropped cards
    static func testDebugReportTracksDroppedCards() -> Bool {
        let testDefaults = UserDefaults(suiteName: "test-debug-report")!
        let cooldownManager = CooldownManager(userDefaults: testDefaults)
        cooldownManager.clearAllCooldowns()

        // Record a cooldown to force a drop
        cooldownManager.recordShown(templateId: "high_challenge_week", childId: TestHelpers.testChildId, at: Date())

        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()

        var events: [UnifiedEvent] = []
        let now = Date()
        for i in 0..<6 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }
        dataProvider.mockEvents = events
        dataProvider.mockGoals = []
        dataProvider.mockRoutineBehaviors = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider, cooldownManager: cooldownManager)
        let report = engine.debugReport(childId: TestHelpers.testChildId, now: now)

        // Should have at least one dropped card (due to cooldown)
        let hasDroppedCards = !report.droppedCards.isEmpty
        let hasCooldownDrop = report.droppedCards.contains { $0.reason == .cooldownActive }

        return hasDroppedCards && hasCooldownDrop
    }

    /// Test debug report has built cards
    static func testDebugReportHasBuiltCards() -> Bool {
        let testDefaults = UserDefaults(suiteName: "test-debug-built")!
        let cooldownManager = CooldownManager(userDefaults: testDefaults)
        cooldownManager.clearAllCooldowns()

        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()

        var events: [UnifiedEvent] = []
        let now = Date()
        for i in 0..<6 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }
        dataProvider.mockEvents = events
        dataProvider.mockGoals = []
        dataProvider.mockRoutineBehaviors = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider, cooldownManager: cooldownManager)
        let report = engine.debugReport(childId: TestHelpers.testChildId, now: now)

        // builtCards should track cards before filtering
        return report.builtCards.count >= report.selectedCards.count
    }

    // MARK: - F: Localization Tests

    /// Test that cards have localized content
    static func testCardsHaveLocalizedContent() -> Bool {
        let template = CardTemplateLibrary.goalAtRisk
        let signal = SignalResult(
            signalType: .goalAtRisk,
            triggered: true,
            confidence: 0.8,
            evidence: InsightEvidence(eventIds: ["e1", "e2"], window: .sevenDays, count: 2),
            explanation: "Test",
            metadata: SignalMetadata(
                goalId: "goal-123",
                goalName: "Test Goal",
                behaviorId: nil,
                behaviorName: nil,
                daysRemaining: 5,
                progress: 0.3,
                count: nil,
                daysSinceOccurrence: nil
            )
        )
        let variables = TemplateVariables(
            childName: "Emma",
            childId: "child-456",
            goalName: "Test Goal",
            goalId: "goal-123",
            behaviorName: nil,
            behaviorId: nil,
            count: 2,
            days: 7,
            daysRemaining: 5,
            progress: 0.3
        )

        let card = CardBuilder.build(
            template: template,
            signal: signal,
            variables: variables,
            expiresAt: Date().addingTimeInterval(86400)
        )

        guard let localized = card.localizedContent else { return false }

        // Check that keys are properly formatted
        let hasCorrectTitleKey = localized.titleKey == "insights.goal_at_risk.title"
        let hasCorrectOneLinerKey = localized.oneLinerKey == "insights.goal_at_risk.one_liner"
        let hasArgs = !localized.titleArgs.isEmpty
        let hasStepsKeys = localized.stepsKeys.count == template.steps.count

        return hasCorrectTitleKey && hasCorrectOneLinerKey && hasArgs && hasStepsKeys
    }

    /// Test insufficient data card has localized content
    static func testInsufficientDataCardHasLocalizedContent() -> Bool {
        let card = CoachCard.insufficientData(
            childId: "child-123",
            childName: "Emma",
            reason: "Not enough data"
        )

        guard let localized = card.localizedContent else { return false }

        return localized.titleKey == "insights.insufficient_data.title" &&
               localized.oneLinerArgs["childName"] == "Emma"
    }

    // MARK: - G: Safety Rails Tests

    /// Test that max risk cards limit is enforced
    static func testSafetyRailsLimitRiskCards() -> Bool {
        let testDefaults = UserDefaults(suiteName: "test-safety-risk")!
        let cooldownManager = CooldownManager(userDefaults: testDefaults)
        cooldownManager.clearAllCooldowns()

        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()

        // Create events that trigger multiple risk signals
        var events: [UnifiedEvent] = []
        let now = Date()

        // Events for high challenge week
        for i in 0..<6 {
            events.append(TestHelpers.makeEvent(
                id: "challenge-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .negative,
                starsDelta: -1
            ))
        }
        for i in 0..<2 {
            events.append(TestHelpers.makeEvent(
                id: "positive-\(i)",
                timestamp: now.addingTimeInterval(-86400 * Double(i)),
                category: .positive,
                starsDelta: 1
            ))
        }
        dataProvider.mockEvents = events

        // Add goal at risk
        let goal = TestHelpers.makeGoal(
            targetPoints: 100,
            currentPoints: 10,
            dueDate: now.addingTimeInterval(86400 * 3)  // 3 days left, way behind
        )
        dataProvider.mockGoals = [goal]
        dataProvider.mockRoutineBehaviors = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider, cooldownManager: cooldownManager)
        let cards = engine.generateCards(childId: TestHelpers.testChildId, now: now)

        // Count risk cards
        let riskTemplates: Set<String> = ["goal_at_risk", "high_challenge_week"]
        let riskCards = cards.filter { riskTemplates.contains($0.templateId) }

        return riskCards.count <= InsightsEngineConstants.maxRiskCards
    }

    /// Test that max improvement cards limit is enforced
    static func testSafetyRailsLimitImprovementCards() -> Bool {
        let testDefaults = UserDefaults(suiteName: "test-safety-improvement")!
        let cooldownManager = CooldownManager(userDefaults: testDefaults)
        cooldownManager.clearAllCooldowns()

        let dataProvider = MockInsightsDataProvider()
        dataProvider.mockChild = TestHelpers.makeChild()

        let now = Date()
        var events: [UnifiedEvent] = []

        // Create multiple routines that could trigger forming signals
        let behaviors = (0..<5).map { i in
            TestHelpers.makeRoutineBehavior(id: "routine-\(i)", name: "Routine \(i)")
        }
        dataProvider.mockRoutineBehaviors = behaviors

        // Create events for each routine (5 events each across 4 days to trigger forming)
        for behavior in behaviors {
            for j in 0..<5 {
                events.append(TestHelpers.makeEvent(
                    id: "event-\(behavior.id)-\(j)",
                    timestamp: now.addingTimeInterval(-86400 * Double(j % 4)),
                    category: .routinePositive,
                    behaviorTypeId: behavior.id,
                    behaviorName: behavior.name
                ))
            }
        }
        dataProvider.mockEvents = events
        dataProvider.mockGoals = []

        let engine = CoachingEngineImpl(dataProvider: dataProvider, cooldownManager: cooldownManager)
        let cards = engine.generateCards(childId: TestHelpers.testChildId, now: now)

        // Count improvement cards
        let improvementTemplates: Set<String> = ["goal_stalled", "routine_forming", "routine_slipping"]
        let improvementCards = cards.filter { improvementTemplates.contains($0.templateId) }

        return improvementCards.count <= InsightsEngineConstants.maxImprovementCards
    }

    // MARK: - Run All Tests

    static func runAllTests() -> [(name: String, passed: Bool)] {
        [
            // Signal threshold tests
            ("Goal at risk triggers with deadline", testGoalAtRiskTriggersWithDeadline()),
            ("Goal at risk does not trigger without deadline", testGoalAtRiskDoesNotTriggerWithoutDeadline()),
            ("Goal stalled triggers after gap", testGoalStalledTriggersAfterGap()),
            ("Goal stalled does not trigger with recent activity", testGoalStalledDoesNotTriggerWithRecentActivity()),
            ("Routine forming triggers with consistency", testRoutineFormingTriggersWithConsistency()),
            ("Routine forming does not trigger with few events", testRoutineFormingDoesNotTriggerWithFewEvents()),
            ("Routine slipping triggers after gap", testRoutineSlippingTriggersAfterGap()),
            ("High challenge week triggers when challenges exceed positives", testHighChallengeWeekTriggersWhenChallengesExceedPositives()),
            ("High challenge week does not trigger when positives dominate", testHighChallengeWeekDoesNotTriggerWhenPositivesDominate()),

            // Evidence tests
            ("Evidence event IDs are correct", testEvidenceEventIdsAreCorrect()),

            // Insufficient data tests
            ("Insufficient data returns special card", testInsufficientDataReturnsSpecialCard()),

            // Cooldown tests
            ("Cooldown prevents repeat cards", testCooldownPreventsRepeatCards()),

            // Ranking tests
            ("Ranking prioritizes higher priority", testRankingPrioritizesHigherPriority()),
            ("Ranking respects max limit", testRankingRespectsMaxLimit()),

            // A: Cooldown separation tests
            ("A: generateCards() does not record cooldowns", testGenerateCardsDoesNotRecordCooldowns()),
            ("A: recordCardsDisplayed() records cooldowns", testRecordCardsDisplayedRecordsCooldowns()),

            // B: Determinism tests
            ("B: Sorting is deterministic with tie-breakers", testDeterministicSortingWithTieBreakers()),
            ("B: stableKey is deterministic", testStableKeyIsDeterministic()),
            ("B: CardBuilder generates deterministic IDs", testCardBuilderGeneratesDeterministicIds()),

            // C: Evidence validator tests
            ("C: Evidence validator filters invalid evidence", testEvidenceValidatorFiltersInvalidEvidence()),
            ("C: Evidence validation result details", testEvidenceValidationResultDetails()),

            // D: Signal registry tests
            ("D: SignalType risk classification", testSignalTypeRiskClassification()),
            ("D: SignalType improvement classification", testSignalTypeImprovementClassification()),

            // E: Debug report tests
            ("E: Debug report tracks dropped cards", testDebugReportTracksDroppedCards()),
            ("E: Debug report has built cards", testDebugReportHasBuiltCards()),

            // F: Localization tests
            ("F: Cards have localized content", testCardsHaveLocalizedContent()),
            ("F: Insufficient data card has localized content", testInsufficientDataCardHasLocalizedContent()),

            // G: Safety rails tests
            ("G: Safety rails limit risk cards", testSafetyRailsLimitRiskCards()),
            ("G: Safety rails limit improvement cards", testSafetyRailsLimitImprovementCards())
        ]
    }

    static func printTestResults() {
        print("\n=== INSIGHTS ENGINE TESTS ===\n")

        let results = runAllTests()
        var passedCount = 0
        var failedCount = 0

        for (name, passed) in results {
            let status = passed ? "PASS" : "FAIL"
            let emoji = passed ? "✓" : "✗"
            print("\(emoji) [\(status)] \(name)")

            if passed {
                passedCount += 1
            } else {
                failedCount += 1
            }
        }

        print("\n--- SUMMARY ---")
        print("Total: \(results.count)")
        print("Passed: \(passedCount)")
        print("Failed: \(failedCount)")
        print("")
    }
}

#endif
