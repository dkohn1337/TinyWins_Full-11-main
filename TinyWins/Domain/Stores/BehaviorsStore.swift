import Foundation
import Combine

/// Store responsible for managing behavior types and behavior events.
/// Extracted from FamilyViewModel to provide focused state management for all behavior-related operations.
///
/// PERFORMANCE: Uses single Snapshot pattern to batch all state updates into one objectWillChange.
/// This prevents multiple view invalidations during loadData() which caused tab switch jank.
@MainActor
final class BehaviorsStore: ObservableObject {

    // MARK: - Snapshot (single publish for all state)

    struct Snapshot: Equatable {
        var behaviorTypes: [BehaviorType] = []
        var behaviorEvents: [BehaviorEvent] = []
        var behaviorStreaks: [BehaviorStreak] = []
    }

    // MARK: - Dependencies

    private let repository: RepositoryProtocol

    // MARK: - Published State (single snapshot = single objectWillChange)

    @Published private(set) var snapshot = Snapshot()

    // MARK: - Convenience Accessors (no additional publishes)

    var behaviorTypes: [BehaviorType] { snapshot.behaviorTypes }
    var behaviorEvents: [BehaviorEvent] { snapshot.behaviorEvents }
    var behaviorStreaks: [BehaviorStreak] { snapshot.behaviorStreaks }

    // MARK: - Cached Computed Values (for performance)

    /// Cached today's events - invalidated when behaviorEvents changes
    private var _cachedTodayEvents: [BehaviorEvent]?
    private var _cachedTodayDate: Date?
    private var _cachedEventCount: Int = -1  // Track event count to detect changes

    // MARK: - Computed Properties

    var activeBehaviorTypes: [BehaviorType] {
        behaviorTypes.filter { $0.isActive }
    }

    var todayEvents: [BehaviorEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentCount = behaviorEvents.count

        // Return cached if valid (same day, cache exists, AND event count unchanged)
        if let cached = _cachedTodayEvents,
           let cachedDate = _cachedTodayDate,
           calendar.isDate(cachedDate, inSameDayAs: today),
           _cachedEventCount == currentCount {
            return cached
        }

        // Recompute and cache
        let events = behaviorEvents
            .filter { calendar.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
        _cachedTodayEvents = events
        _cachedTodayDate = today
        _cachedEventCount = currentCount
        return events
    }

    var todayPositiveCount: Int {
        todayEvents.filter { $0.pointsApplied > 0 }.count
    }

    var todayNegativeCount: Int {
        todayEvents.filter { $0.pointsApplied < 0 }.count
    }

    var todaySummaryText: String {
        let positive = todayPositiveCount
        let negative = todayNegativeCount

        if positive == 0 && negative == 0 {
            return "No events logged today"
        }

        var parts: [String] = []
        if positive > 0 {
            parts.append("\(positive) positive moment\(positive == 1 ? "" : "s")")
        }
        if negative > 0 {
            parts.append("\(negative) challenge\(negative == 1 ? "" : "s")")
        }

        return parts.joined(separator: ", ") + " today"
    }

    // MARK: - Initialization

    init(repository: RepositoryProtocol) {
        self.repository = repository
        loadData()
    }

    // MARK: - Data Loading

    /// PERFORMANCE: Single snapshot assignment = single objectWillChange notification
    func loadData() {
        #if DEBUG
        FrameStallMonitor.shared.markBlockReason(.storeRecompute)
        defer { FrameStallMonitor.shared.clearBlockReason() }
        #endif

        snapshot = Snapshot(
            behaviorTypes: repository.getBehaviorTypes(),
            behaviorEvents: repository.getBehaviorEvents(),
            behaviorStreaks: repository.getBehaviorStreaks()
        )
        invalidateTodayCache()
    }

    /// Invalidate cached today events - call when data changes
    private func invalidateTodayCache() {
        _cachedTodayEvents = nil
        _cachedTodayDate = nil
        _cachedEventCount = -1
    }

    // MARK: - Behavior Type Queries

    func behaviorType(id: UUID) -> BehaviorType? {
        behaviorTypes.first { $0.id == id }
    }

    func behaviorTypes(forCategory category: BehaviorCategory) -> [BehaviorType] {
        activeBehaviorTypes.filter { $0.category == category }
    }

    // MARK: - Behavior Type CRUD

    func addBehaviorType(_ behaviorType: BehaviorType) {
        repository.addBehaviorType(behaviorType)
        loadData()
    }

    func updateBehaviorType(_ behaviorType: BehaviorType) {
        guard behaviorTypes.contains(where: { $0.id == behaviorType.id }) else {
            #if DEBUG
            print("⚠️ BehaviorsStore: Attempted to update non-existent behavior type: \(behaviorType.id)")
            #endif
            return
        }
        repository.updateBehaviorType(behaviorType)
        loadData()
    }

    func deleteBehaviorType(id: UUID) {
        guard behaviorTypes.contains(where: { $0.id == id }) else {
            #if DEBUG
            print("⚠️ BehaviorsStore: Attempted to delete non-existent behavior type: \(id)")
            #endif
            return
        }
        repository.deleteBehaviorType(id: id)
        loadData()
    }

    func toggleBehaviorTypeActive(id: UUID) {
        if var behaviorType = behaviorType(id: id) {
            behaviorType.isActive.toggle()
            updateBehaviorType(behaviorType)
        }
    }

    // MARK: - Behavior Event Queries

    func todayPoints(forChild childId: UUID) -> Int {
        todayEvents
            .filter { $0.childId == childId }
            .reduce(0) { $0 + $1.pointsApplied }
    }

    func recentEvents(forChild childId: UUID, limit: Int = 20) -> [BehaviorEvent] {
        behaviorEvents
            .filter { $0.childId == childId }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }

    /// Get the most recent event for a child (for "repeat last" feature)
    func lastEvent(forChild childId: UUID) -> BehaviorEvent? {
        behaviorEvents
            .filter { $0.childId == childId }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    /// Get recently used behavior types for a child (for quick access in Log Behavior sheet)
    func recentBehaviorTypes(forChild childId: UUID, limit: Int = 5) -> [BehaviorType] {
        let childEvents = behaviorEvents
            .filter { $0.childId == childId }
            .sorted { $0.timestamp > $1.timestamp }

        var seen = Set<UUID>()
        var result: [BehaviorType] = []

        for event in childEvents {
            if !seen.contains(event.behaviorTypeId),
               let behaviorType = behaviorType(id: event.behaviorTypeId),
               behaviorType.isActive {
                seen.insert(event.behaviorTypeId)
                result.append(behaviorType)
                if result.count >= limit {
                    break
                }
            }
        }

        return result
    }

    // MARK: - Behavior Event CRUD

    /// Add a behavior event (note: milestone and badge checking is handled by FamilyViewModel)
    func addBehaviorEvent(_ event: BehaviorEvent) {
        repository.addBehaviorEvent(event)
        loadData()
    }

    func updateEvent(_ event: BehaviorEvent) {
        guard behaviorEvents.contains(where: { $0.id == event.id }) else {
            #if DEBUG
            print("⚠️ BehaviorsStore: Attempted to update non-existent event: \(event.id)")
            #endif
            return
        }
        repository.updateBehaviorEvent(event)
        loadData()
    }

    func deleteEvent(id: UUID) {
        guard behaviorEvents.contains(where: { $0.id == id }) else {
            #if DEBUG
            print("⚠️ BehaviorsStore: Attempted to delete non-existent event: \(id)")
            #endif
            return
        }
        repository.deleteBehaviorEvent(id: id)
        loadData()
    }

    // MARK: - History Methods

    func events(forChild childId: UUID, period: TimePeriod) -> [BehaviorEvent] {
        let (start, end) = period.dateRange
        return behaviorEvents.filter {
            $0.childId == childId &&
            $0.timestamp >= start &&
            $0.timestamp <= end
        }.sorted { $0.timestamp > $1.timestamp }
    }

    func allEvents(forPeriod period: TimePeriod) -> [BehaviorEvent] {
        let (start, end) = period.dateRange
        return behaviorEvents.filter {
            $0.timestamp >= start &&
            $0.timestamp <= end
        }.sorted { $0.timestamp > $1.timestamp }
    }

    func points(forChild childId: UUID, period: TimePeriod) -> Int {
        events(forChild: childId, period: period)
            .reduce(0) { $0 + $1.pointsApplied }
    }

    // MARK: - Age-based Suggestions

    func suggestedBehaviors(forChild child: Child) -> [BehaviorType] {
        // Start with active behaviors, falling back to defaults if none exist
        var behaviors = activeBehaviorTypes
        if behaviors.isEmpty {
            // No custom behaviors - use defaults
            behaviors = BehaviorType.defaultBehaviors.filter { $0.isActive }
        }

        guard let age = child.age else {
            return behaviors
        }

        // Filter by age, but fall back to all active if nothing matches
        let ageFiltered = behaviors.filter { $0.suggestedAgeRange.contains(age: age) }
        return ageFiltered.isEmpty ? behaviors : ageFiltered
    }

    func suggestedBehaviors(forChild child: Child, category: BehaviorCategory) -> [BehaviorType] {
        suggestedBehaviors(forChild: child).filter { $0.category == category }
    }

    // MARK: - Allowance Calculations

    func totalAllowanceEarned(forChild childId: UUID) -> Double {
        behaviorEvents
            .filter { $0.childId == childId }
            .compactMap { $0.earnedAllowance }
            .reduce(0, +)
    }

    func allowanceEarned(forChild childId: UUID, period: TimePeriod?, allowanceSettings: AllowanceSettings) -> Double {
        guard allowanceSettings.isEnabled else { return 0 }

        let events: [BehaviorEvent]
        if let period = period {
            events = self.events(forChild: childId, period: period)
        } else {
            events = behaviorEvents.filter { $0.childId == childId }
        }

        var totalPoints = 0
        for event in events where event.pointsApplied > 0 {
            if let behavior = behaviorType(id: event.behaviorTypeId), behavior.isMonetized {
                totalPoints += event.pointsApplied
            }
        }

        return allowanceSettings.pointsToMoney(totalPoints)
    }

    // MARK: - Behavior Consistency (Internal Analytics)

    func updateStreak(childId: UUID, behaviorTypeId: UUID) {
        repository.updateStreak(childId: childId, behaviorTypeId: behaviorTypeId)
        // Update only streaks in snapshot (single publish)
        snapshot.behaviorStreaks = repository.getBehaviorStreaks()
    }

    func streak(forChild childId: UUID, behaviorType behaviorTypeId: UUID) -> BehaviorStreak? {
        behaviorStreaks.first { $0.childId == childId && $0.behaviorTypeId == behaviorTypeId }
    }
}
