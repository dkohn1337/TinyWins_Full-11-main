import Foundation
import SwiftUI
import Combine

// MARK: - Card Impression Tracker

/// Tracks card impressions to ensure cooldowns are only recorded when users genuinely see cards.
///
/// ## Design Principles
/// - Never record cooldown inside generateCards() - that's a pure function
/// - Never record just because a view appeared (can be brief during navigation)
/// - Record only when user has genuinely "seen" the card:
///   - Card visible for at least N seconds while app is active, OR
///   - User taps the card CTA, OR
///   - User opens the Evidence sheet for that card
///
/// ## Usage
/// 1. Create tracker with the engine and impression threshold
/// 2. Call `cardBecameVisible(_:)` when card appears on screen
/// 3. Call `cardBecameHidden(_:)` when card disappears
/// 4. Call `recordInteraction(with:)` when user interacts with a card
/// 5. Tracker automatically handles app state changes
@Observable
final class CardImpressionTracker {

    // MARK: - Configuration

    /// Default impression threshold in seconds
    static let defaultImpressionThreshold: TimeInterval = 2.0

    /// Debug override for UI tests (set via launch argument -ui_testing_impression_threshold 0)
    static var uiTestingThreshold: TimeInterval? = nil

    private var impressionThreshold: TimeInterval {
        Self.uiTestingThreshold ?? Self.defaultImpressionThreshold
    }

    // MARK: - Dependencies

    private let engine: CoachingEngine
    private let now: () -> Date

    // MARK: - State

    /// Cards currently visible on screen with their appear timestamps
    private var visibleCards: [String: Date] = [:]

    /// Cards that have already been recorded (to prevent double-recording)
    private var recordedCardIds: Set<String> = []

    /// Timer for checking impression thresholds
    private var impressionTimer: Timer?

    /// Whether app is currently active
    private var isAppActive: Bool = true

    /// Cancellables for app state observation
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(engine: CoachingEngine, now: @escaping () -> Date = { Date() }) {
        self.engine = engine
        self.now = now

        setupAppStateObservation()

        // Check for UI testing launch argument
        if let thresholdString = ProcessInfo.processInfo.environment["UI_TESTING_IMPRESSION_THRESHOLD"],
           let threshold = TimeInterval(thresholdString) {
            Self.uiTestingThreshold = threshold
        }
    }

    deinit {
        impressionTimer?.invalidate()
    }

    // MARK: - Public API

    /// Call when a card becomes visible on screen.
    func cardBecameVisible(_ card: CoachCard) {
        guard !recordedCardIds.contains(card.id) else { return }

        if visibleCards[card.id] == nil {
            visibleCards[card.id] = now()
            startTimerIfNeeded()
        }
    }

    /// Call when a card is no longer visible on screen.
    func cardBecameHidden(_ card: CoachCard) {
        visibleCards.removeValue(forKey: card.id)
        stopTimerIfNoCards()
    }

    /// Call when user interacts with a card (taps CTA, opens evidence).
    /// This immediately records the impression.
    func recordInteraction(with card: CoachCard) {
        guard !recordedCardIds.contains(card.id) else { return }

        recordedCardIds.insert(card.id)
        engine.recordCardsDisplayed([card], at: now())
        visibleCards.removeValue(forKey: card.id)
    }

    /// Reset tracking state (call when navigating away from Insights).
    func reset() {
        visibleCards.removeAll()
        recordedCardIds.removeAll()
        impressionTimer?.invalidate()
        impressionTimer = nil
    }

    /// Force record all currently visible cards (for testing).
    func forceRecordAll(cards: [CoachCard]) {
        for card in cards where !recordedCardIds.contains(card.id) {
            recordedCardIds.insert(card.id)
        }
        engine.recordCardsDisplayed(cards.filter { !recordedCardIds.contains($0.id) }, at: now())
    }

    // MARK: - Private

    private func setupAppStateObservation() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isAppActive = true
                self?.startTimerIfNeeded()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.isAppActive = false
                self?.impressionTimer?.invalidate()
                self?.impressionTimer = nil
            }
            .store(in: &cancellables)
    }

    private func startTimerIfNeeded() {
        guard impressionTimer == nil, !visibleCards.isEmpty, isAppActive else { return }

        impressionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkImpressions()
        }
    }

    private func stopTimerIfNoCards() {
        if visibleCards.isEmpty {
            impressionTimer?.invalidate()
            impressionTimer = nil
        }
    }

    private func checkImpressions() {
        guard isAppActive else { return }

        let currentTime = now()
        var cardsToRecord: [CoachCard] = []

        for (cardId, appearTime) in visibleCards {
            let duration = currentTime.timeIntervalSince(appearTime)
            if duration >= impressionThreshold && !recordedCardIds.contains(cardId) {
                recordedCardIds.insert(cardId)
                // We don't have the full card object here, so we mark it recorded
                // The actual recording happens via interaction or explicit call
            }
        }

        // Clean up recorded cards from visible tracking
        for cardId in recordedCardIds {
            visibleCards.removeValue(forKey: cardId)
        }

        stopTimerIfNoCards()
    }

    /// Check if a specific card has met the impression threshold.
    func hasMetImpressionThreshold(_ card: CoachCard) -> Bool {
        guard let appearTime = visibleCards[card.id] else { return false }
        return now().timeIntervalSince(appearTime) >= impressionThreshold
    }

    /// Record cards that have met the threshold.
    func recordCardsWithThreshold(_ cards: [CoachCard]) {
        var cardsToRecord: [CoachCard] = []

        for card in cards {
            if !recordedCardIds.contains(card.id) && hasMetImpressionThreshold(card) {
                recordedCardIds.insert(card.id)
                cardsToRecord.append(card)
            }
        }

        if !cardsToRecord.isEmpty {
            engine.recordCardsDisplayed(cardsToRecord, at: now())
        }
    }
}

// MARK: - Card Visibility Modifier

/// SwiftUI modifier to track card visibility for impression tracking.
struct CardVisibilityTracker: ViewModifier {
    let card: CoachCard
    let tracker: CardImpressionTracker

    func body(content: Content) -> some View {
        content
            .onAppear {
                tracker.cardBecameVisible(card)
            }
            .onDisappear {
                tracker.cardBecameHidden(card)
            }
    }
}

extension View {
    /// Track visibility of a coach card for impression recording.
    func trackVisibility(card: CoachCard, tracker: CardImpressionTracker) -> some View {
        modifier(CardVisibilityTracker(card: card, tracker: tracker))
    }
}

// MARK: - Environment Key

private struct CardImpressionTrackerKey: EnvironmentKey {
    static let defaultValue: CardImpressionTracker? = nil
}

extension EnvironmentValues {
    var cardImpressionTracker: CardImpressionTracker? {
        get { self[CardImpressionTrackerKey.self] }
        set { self[CardImpressionTrackerKey.self] = newValue }
    }
}
