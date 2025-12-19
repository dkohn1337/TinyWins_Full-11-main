import Foundation
import SwiftUI
import Combine

/// ViewModel for InsightsHomeView with Combine-based state precomputation.
/// Implements visibility gate pattern to avoid heavy computation when tab is hidden.
///
/// PERFORMANCE: This ViewModel eliminates computed properties in the view body by:
/// 1. Using Combine to precompute habitFormingCards, otherCards, hasEvidence
/// 2. Batching all state into a single @Published struct
/// 3. Gating heavy work behind visibility state
@MainActor
final class InsightsHomeViewModel: ObservableObject {

    // MARK: - Precomputed State

    struct ViewState: Equatable {
        var cards: [CoachCard] = []
        var habitFormingCards: [CoachCard] = []
        var otherCards: [CoachCard] = []
        var hasEvidence: Bool = false
        var totalEvidence: Int = 0
        var evidenceWindow: Int = 7
        var isLoading: Bool = true

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            lhs.cards.map { $0.id } == rhs.cards.map { $0.id } &&
            lhs.habitFormingCards.map { $0.id } == rhs.habitFormingCards.map { $0.id } &&
            lhs.otherCards.map { $0.id } == rhs.otherCards.map { $0.id } &&
            lhs.hasEvidence == rhs.hasEvidence &&
            lhs.totalEvidence == rhs.totalEvidence &&
            lhs.evidenceWindow == rhs.evidenceWindow &&
            lhs.isLoading == rhs.isLoading
        }
    }

    @Published private(set) var state = ViewState()

    // MARK: - Dependencies

    private let repository: Repository
    private let childrenStore: ChildrenStore
    private let navigation: InsightsNavigationState

    // MARK: - Visibility Gate

    private var isVisible = false
    private var pendingState: ViewState?
    private var lastChildId: UUID?

    // MARK: - Coaching Engine (Cached)

    private var _engine: CoachingEngine?

    private func getOrCreateEngine() -> CoachingEngine {
        if _engine == nil {
            let dataProvider = RepositoryDataProvider(repository: repository)
            _engine = CoachingEngineImpl(dataProvider: dataProvider)
        }
        return _engine!
    }

    // MARK: - Impression Tracking

    private(set) var impressionTracker: CardImpressionTracker?

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        repository: Repository,
        childrenStore: ChildrenStore,
        navigation: InsightsNavigationState
    ) {
        self.repository = repository
        self.childrenStore = childrenStore
        self.navigation = navigation

        #if DEBUG
        print("🟢 INIT InsightsHomeViewModel", ObjectIdentifier(self))
        #endif

        setupObservers()
    }

    deinit {
        #if DEBUG
        print("🔴 DEINIT InsightsHomeViewModel", ObjectIdentifier(self))
        #endif
    }

    // MARK: - Combine Observers

    private func setupObservers() {
        // Observe child selection changes
        navigation.$selectedChildId
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] childId in
                self?.handleChildSelectionChange(childId)
            }
            .store(in: &cancellables)

        // PHASE 2: Observe children snapshot (child added/deleted)
        // Uses precomputed activeChildren count from snapshot
        childrenStore.$snapshot
            .dropFirst()
            .map { $0.activeChildren.count }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.validateAndLoadCards()
            }
            .store(in: &cancellables)

        // Observe demo data loaded notification
        NotificationCenter.default.publisher(for: .demoDataDidLoad)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleDemoDataLoaded(notification: notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - Visibility Gate

    func setVisible(_ visible: Bool) {
        isVisible = visible

        guard visible else { return }

        // When becoming visible, apply any pending state
        Task { @MainActor in
            await Task.yield()

            if let pending = pendingState {
                pendingState = nil
                applyState(pending)
            } else if state.isLoading || lastChildId != navigation.selectedChildId {
                // If still loading or child changed while hidden, load now
                validateAndLoadCards()
            }
        }
    }

    private func applyState(_ newState: ViewState) {
        guard isVisible else {
            pendingState = newState
            return
        }

        state = newState
    }

    // MARK: - Child Selection

    private func handleChildSelectionChange(_ childId: UUID?) {
        guard childId != lastChildId else { return }
        lastChildId = childId

        if isVisible {
            loadCards()
        } else {
            // Mark as loading so we reload when visible
            pendingState = ViewState(isLoading: true)
        }
    }

    // MARK: - Card Loading

    /// Validates child selection and loads cards.
    /// This is the primary entry point.
    func validateAndLoadCards() {
        // PHASE 2: Use precomputed activeChildren from snapshot
        let activeChildren = childrenStore.activeChildren

        let selectionState = navigation.validateSelection(against: activeChildren)

        switch selectionState {
        case .noChildren:
            applyState(ViewState(isLoading: false))
            return

        case .validSelection:
            break

        case .invalidSelection(let fallback):
            if fallback == nil {
                applyState(ViewState(isLoading: false))
                return
            }

        case .noSelection(let firstChild):
            if let child = firstChild {
                navigation.selectChild(child.id)
            } else {
                applyState(ViewState(isLoading: false))
                return
            }
        }

        // Prune any stale recent IDs
        let validIds = Set(activeChildren.map { $0.id })
        navigation.pruneStaleRecentIds(validIds: validIds)

        loadCards()
    }

    private func loadCards() {
        guard let selectedId = navigation.selectedChildId else {
            applyState(ViewState(isLoading: false))
            return
        }

        lastChildId = selectedId

        // Show loading state
        var loadingState = state
        loadingState.isLoading = true
        applyState(loadingState)

        // Generate cards using deterministic engine
        let childIdString = selectedId.uuidString
        let currentEngine = getOrCreateEngine()
        let generatedCards = currentEngine.generateCards(childId: childIdString, now: Date())

        // Precompute derived state
        let habitForming = generatedCards.filter { card in
            card.templateId == "routine_forming" || card.templateId == "positive_pattern"
        }
        let other = generatedCards.filter { card in
            card.templateId != "routine_forming" && card.templateId != "positive_pattern"
        }
        let evidence = generatedCards.contains { $0.hasValidEvidence }
        let total = generatedCards.reduce(0) { $0 + $1.evidenceEventIds.count }
        let window = generatedCards.first?.evidenceWindow ?? 7

        // Initialize impression tracker if needed
        if impressionTracker == nil {
            impressionTracker = CardImpressionTracker(engine: currentEngine)
        }

        // Apply computed state
        let newState = ViewState(
            cards: generatedCards,
            habitFormingCards: habitForming,
            otherCards: other,
            hasEvidence: evidence,
            totalEvidence: total,
            evidenceWindow: window,
            isLoading: false
        )

        applyState(newState)
    }

    // MARK: - Demo Data Handling

    private func handleDemoDataLoaded(notification: Notification) {
        // Reset cached engine so a new one is created with fresh data
        _engine = nil
        impressionTracker = nil

        // Select the first demo child
        if let firstChildId = notification.userInfo?["firstChildId"] as? UUID {
            navigation.selectChild(firstChildId)
        } else {
            // PHASE 2: Use precomputed activeChildren from snapshot
            if let firstChild = childrenStore.activeChildren.first {
                navigation.selectChild(firstChild.id)
            }
        }

        // Reload cards with fresh data
        validateAndLoadCards()

        #if DEBUG
        print("[InsightsHomeViewModel] Demo data loaded - engine reset")
        #endif
    }

    // MARK: - Impression Recording

    func recordCardInteraction(_ card: CoachCard) {
        impressionTracker?.recordInteraction(with: card)
    }

    func cardBecameVisible(_ card: CoachCard) {
        impressionTracker?.cardBecameVisible(card)
    }

    func cardBecameHidden(_ card: CoachCard) {
        impressionTracker?.cardBecameHidden(card)
    }
}
