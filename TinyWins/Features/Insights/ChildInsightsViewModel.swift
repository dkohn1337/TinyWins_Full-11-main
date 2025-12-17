import Foundation
import Combine

/// ViewModel for the Child Insights screen.
/// Manages insights data calculation and time range selection.
@MainActor
final class ChildInsightsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let insightsStore: InsightsStore
    private let behaviorsStore: BehaviorsStore
    private let childrenStore: ChildrenStore

    // MARK: - State

    let childId: UUID

    // MARK: - Published State

    @Published var selectedTimeRange: InsightTimeRange = .thisWeek

    // MARK: - Computed Properties

    var child: Child? {
        childrenStore.children.first { $0.id == childId }
    }

    func insightsData() -> ChildInsightsData {
        insightsStore.insightsData(
            forChild: childId,
            timeRange: selectedTimeRange,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )
    }

    func improvementSuggestions() -> [ImprovementSuggestion] {
        guard let child = child else { return [] }
        return insightsStore.improvementSuggestions(
            forChild: child,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )
    }

    func weeklySummary() -> AnalyticsService.WeeklySummary? {
        insightsStore.weeklySummary(
            forChild: childId,
            behaviorEvents: behaviorsStore.behaviorEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )
    }

    // MARK: - Initialization

    init(
        childId: UUID,
        insightsStore: InsightsStore,
        behaviorsStore: BehaviorsStore,
        childrenStore: ChildrenStore
    ) {
        self.childId = childId
        self.insightsStore = insightsStore
        self.behaviorsStore = behaviorsStore
        self.childrenStore = childrenStore
    }
}
