import Foundation
import SwiftUI

/// Use case for determining and queueing celebrations based on behavior events.
/// Encapsulates the business logic for Gold Star Day detection, pattern insights,
/// and coordinates with CelebrationManager for display.
/// Performs no UI work - returns celebration data only.
@MainActor
final class CelebrationQueueUseCase {

    // MARK: - Dependencies

    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore
    private let insightsStore: InsightsStore

    // MARK: - Initialization

    init(
        behaviorsStore: BehaviorsStore,
        childrenStore: ChildrenStore,
        insightsStore: InsightsStore
    ) {
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
        self.insightsStore = insightsStore
    }

    // MARK: - Result Types

    /// Result containing celebrations to queue for an event
    struct CelebrationResult {
        let goldStarDay: GoldStarDayData?
        let patternInsight: PatternInsightData?
    }

    /// Data for Gold Star Day celebration
    struct GoldStarDayData {
        let childId: UUID
        let childName: String
        let momentCount: Int
    }

    /// Data for pattern insight celebration
    struct PatternInsightData {
        let childId: UUID
        let childName: String
        let behaviorId: UUID
        let behaviorName: String
        let count: Int
        let insight: BonusInsight
    }

    // MARK: - Execute

    /// Determine which celebrations should be queued for a behavior event.
    /// Returns celebration data without performing any UI operations.
    /// - Parameter event: The behavior event that was just logged
    /// - Returns: CelebrationResult containing any celebrations to queue
    func execute(for event: BehaviorEvent) -> CelebrationResult {
        let childId = event.childId

        // Check for Gold Star Day
        let goldStarDay = checkGoldStarDay(childId: childId)

        // Check for pattern insight
        let patternInsight = checkPatternInsight(childId: childId, event: event)

        return CelebrationResult(
            goldStarDay: goldStarDay,
            patternInsight: patternInsight
        )
    }

    // MARK: - Private Helpers

    /// Check if child has achieved Gold Star Day (5+ positive moments today)
    private func checkGoldStarDay(childId: UUID) -> GoldStarDayData? {
        let todayPositiveCount = behaviorsStore.todayEvents.filter {
            $0.childId == childId && $0.pointsApplied > 0
        }.count

        // Only trigger exactly at 5 to avoid re-triggering
        guard todayPositiveCount == 5,
              let child = childrenStore.child(id: childId) else {
            return nil
        }

        return GoldStarDayData(
            childId: childId,
            childName: child.name,
            momentCount: todayPositiveCount
        )
    }

    /// Check for bonus pattern insight
    private func checkPatternInsight(childId: UUID, event: BehaviorEvent) -> PatternInsightData? {
        // Check for bonus insight - currently disabled per ContentViewModel.checkForBonusInsight
        // This preserves the exact behavior from the original implementation
        guard let insight = checkForBonusInsight(childId: childId),
              let child = childrenStore.child(id: childId) else {
            return nil
        }

        let behaviorName = behaviorsStore.behaviorType(id: event.behaviorTypeId)?.name ?? "Behavior"

        return PatternInsightData(
            childId: childId,
            childName: child.name,
            behaviorId: event.behaviorTypeId,
            behaviorName: behaviorName,
            count: 3,
            insight: insight
        )
    }

    /// Check for bonus insight (pattern detection)
    /// Returns nil if no pattern is found
    /// NOTE: Currently disabled - matches ContentViewModel.checkForBonusInsight
    private func checkForBonusInsight(childId: UUID) -> BonusInsight? {
        // Pattern detection logic - currently disabled
        // This matches the ContentViewModel.checkForBonusInsight implementation
        return nil
    }
}
