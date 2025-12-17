import Foundation
import Combine

/// ViewModel for the main Insights screen.
/// Manages child selection and insights filters.
@MainActor
final class InsightsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let childrenStore: ChildrenStore
    private let userPreferences: UserPreferencesStore

    // MARK: - Published State

    @Published var selectedChildId: UUID?

    // MARK: - Computed Properties

    var activeChildren: [Child] {
        childrenStore.children.filter { !$0.isArchived }
    }

    var selectedChild: Child? {
        guard let id = selectedChildId else { return nil }
        return childrenStore.children.first { $0.id == id }
    }

    var effectiveSelectedChild: Child? {
        if let child = selectedChild {
            return child
        }
        return activeChildren.first
    }

    // MARK: - Initialization

    init(
        childrenStore: ChildrenStore,
        userPreferences: UserPreferencesStore
    ) {
        self.childrenStore = childrenStore
        self.userPreferences = userPreferences

        // Load persisted selection from UserDefaults directly
        // Note: selectedInsightsChildId not yet added to UserPreferencesStore
    }

    // MARK: - Selection Management

    func selectChild(_ child: Child) {
        selectedChildId = child.id
        // Note: selectedInsightsChildId not yet added to UserPreferencesStore
    }
}
