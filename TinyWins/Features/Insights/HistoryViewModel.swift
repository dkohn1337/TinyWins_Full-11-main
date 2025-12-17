import Foundation
import Combine

/// ViewModel for the History screen.
/// Manages event history filtering and display.
@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Dependencies

    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore
    private let childrenStore: ChildrenStore
    private let userPreferences: UserPreferencesStore

    // MARK: - Published State

    @Published var selectedChildId: UUID?
    @Published var selectedTypeFilter: HistoryTypeFilter = .allMoments
    @Published var selectedTimeFilter: TimePeriod = .today

    // MARK: - Computed Properties

    var activeChildren: [Child] {
        childrenStore.children.filter { !$0.isArchived }
    }

    var selectedChild: Child? {
        guard let id = selectedChildId else { return nil }
        return childrenStore.children.first { $0.id == id }
    }

    func historyItems() -> [HistoryItem] {
        let events = behaviorsStore.behaviorEvents
        let rewardEvents = rewardsStore.rewardHistoryEvents

        let range = selectedTimeFilter.dateRange
        let childId = selectedChildId

        var items: [HistoryItem] = []

        switch selectedTypeFilter {
        case .allMoments:
            let behaviorItems = events
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = childId == nil || event.childId == childId
                    return matchesTime && matchesChild
                }
                .map { HistoryItem.behavior($0) }

            let rewardItems = rewardEvents
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = childId == nil || event.childId == childId
                    return matchesTime && matchesChild
                }
                .map { HistoryItem.reward($0) }

            items = behaviorItems + rewardItems

        case .positiveOnly:
            items = events
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = childId == nil || event.childId == childId
                    return matchesTime && matchesChild && event.pointsApplied > 0
                }
                .map { HistoryItem.behavior($0) }

        case .challengesOnly:
            items = events
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = childId == nil || event.childId == childId
                    return matchesTime && matchesChild && event.pointsApplied < 0
                }
                .map { HistoryItem.behavior($0) }

        case .goalsOnly:
            items = rewardEvents
                .filter { event in
                    let matchesTime = event.timestamp >= range.start && event.timestamp <= range.end
                    let matchesChild = childId == nil || event.childId == childId
                    return matchesTime && matchesChild
                }
                .map { HistoryItem.reward($0) }
        }

        return items.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Initialization

    init(
        behaviorsStore: BehaviorsStore,
        rewardsStore: RewardsStore,
        childrenStore: ChildrenStore,
        userPreferences: UserPreferencesStore
    ) {
        self.behaviorsStore = behaviorsStore
        self.rewardsStore = rewardsStore
        self.childrenStore = childrenStore
        self.userPreferences = userPreferences

        // Load persisted selection from UserDefaults directly
        // Note: selectedHistoryChildId not yet added to UserPreferencesStore
    }

    // MARK: - Selection Management

    func selectChild(_ child: Child?) {
        selectedChildId = child?.id
        // Note: selectedHistoryChildId not yet added to UserPreferencesStore
    }

    // MARK: - Event Actions
    // Note: Delete/update methods should be added to BehaviorsStore if needed
}
