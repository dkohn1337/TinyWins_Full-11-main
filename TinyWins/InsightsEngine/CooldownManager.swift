import Foundation

// MARK: - Cooldown Manager

/// Manages cooldown periods for coaching cards to prevent spam.
/// Stores state in UserDefaults with in-memory caching for performance.
final class CooldownManager {

    private let userDefaults: UserDefaults
    private let cooldownKey = "insightsEngine.cooldowns"

    /// In-memory cache to avoid repeated JSON decoding from UserDefaults.
    /// Invalidated on write operations.
    private var cachedRecords: [CooldownRecord]?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Cooldown Record

    private struct CooldownRecord: Codable {
        let templateId: String
        let childId: String
        let lastShownAt: Date
    }

    // MARK: - Public API

    /// Check if a template is on cooldown for a specific child.
    func isOnCooldown(templateId: String, childId: String, now: Date = Date()) -> Bool {
        let records = loadRecords()
        guard let record = records.first(where: {
            $0.templateId == templateId && $0.childId == childId
        }) else {
            return false
        }

        let cooldownEnd = Calendar.current.date(
            byAdding: .day,
            value: InsightsEngineConstants.cooldownDays,
            to: record.lastShownAt
        ) ?? record.lastShownAt

        return now < cooldownEnd
    }

    /// Record that a template was shown for a child.
    func recordShown(templateId: String, childId: String, at date: Date = Date()) {
        var records = loadRecords()

        // Remove existing record for this template/child combo
        records.removeAll { $0.templateId == templateId && $0.childId == childId }

        // Add new record
        records.append(CooldownRecord(
            templateId: templateId,
            childId: childId,
            lastShownAt: date
        ))

        // Clean up old records (older than 30 days)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: date) ?? date
        records = records.filter { $0.lastShownAt > cutoff }

        saveRecords(records)
    }

    /// Get cooldown end date for a template/child combo.
    func cooldownEndDate(templateId: String, childId: String) -> Date? {
        let records = loadRecords()
        guard let record = records.first(where: {
            $0.templateId == templateId && $0.childId == childId
        }) else {
            return nil
        }

        return Calendar.current.date(
            byAdding: .day,
            value: InsightsEngineConstants.cooldownDays,
            to: record.lastShownAt
        )
    }

    /// Clear all cooldowns (for testing).
    func clearAllCooldowns() {
        cachedRecords = nil
        userDefaults.removeObject(forKey: cooldownKey)
    }

    /// Clear cooldowns for a specific child (for testing).
    func clearCooldowns(forChild childId: String) {
        var records = loadRecords()
        records.removeAll { $0.childId == childId }
        saveRecords(records)
    }

    // MARK: - Debug

    /// Get all active cooldowns for debugging.
    func activeCooldowns(now: Date = Date()) -> [(templateId: String, childId: String, endsAt: Date)] {
        let records = loadRecords()
        return records.compactMap { record in
            guard let endDate = Calendar.current.date(
                byAdding: .day,
                value: InsightsEngineConstants.cooldownDays,
                to: record.lastShownAt
            ), endDate > now else {
                return nil
            }
            return (record.templateId, record.childId, endDate)
        }
    }

    // MARK: - Private

    private func loadRecords() -> [CooldownRecord] {
        // Return cached records if available
        if let cached = cachedRecords {
            return cached
        }

        // Load from UserDefaults and cache
        guard let data = userDefaults.data(forKey: cooldownKey) else {
            cachedRecords = []
            return []
        }
        do {
            let records = try JSONDecoder().decode([CooldownRecord].self, from: data)
            cachedRecords = records
            return records
        } catch {
            cachedRecords = []
            return []
        }
    }

    private func saveRecords(_ records: [CooldownRecord]) {
        // Invalidate cache and save
        cachedRecords = records
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: cooldownKey)
        } catch {
            // Silently fail - cooldowns are not critical
        }
    }

    /// Invalidate the in-memory cache (for testing or external changes)
    func invalidateCache() {
        cachedRecords = nil
    }
}

// MARK: - Card Ranker

/// Ranks and filters cards according to priority rules.
enum CardRanker {

    /// Rank and filter cards, respecting cooldowns and limits.
    /// Uses deterministic tie-breakers for stable ordering:
    /// 1. priority DESC
    /// 2. confidence DESC (via evidenceWindow as proxy - shorter = more recent = higher confidence)
    /// 3. evidence count DESC
    /// 4. templateId ASC (lexicographic stability)
    static func rankAndFilter(
        cards: [CoachCard],
        cooldownManager: CooldownManager,
        now: Date = Date()
    ) -> [CoachCard] {
        // Filter out cards on cooldown
        let availableCards = cards.filter { card in
            !cooldownManager.isOnCooldown(
                templateId: card.templateId,
                childId: card.childId,
                now: now
            )
        }

        // Sort with deterministic tie-breakers
        let sortedCards = availableCards.sorted { a, b in
            // 1. Priority (descending - higher priority first)
            if a.priority != b.priority {
                return a.priority > b.priority
            }
            // 2. Evidence window (ascending - shorter window = more recent = prefer)
            if a.evidenceWindow != b.evidenceWindow {
                return a.evidenceWindow < b.evidenceWindow
            }
            // 3. Evidence count (descending - more evidence = stronger signal)
            if a.evidenceEventIds.count != b.evidenceEventIds.count {
                return a.evidenceEventIds.count > b.evidenceEventIds.count
            }
            // 4. Template ID (ascending - lexicographic stability)
            return a.templateId < b.templateId
        }

        // Take top N cards
        let topCards = Array(sortedCards.prefix(InsightsEngineConstants.maxCardsOutput))

        return topCards
    }

    /// Record that cards were shown (for cooldown tracking).
    static func recordCardsShown(
        cards: [CoachCard],
        cooldownManager: CooldownManager,
        at date: Date = Date()
    ) {
        for card in cards {
            cooldownManager.recordShown(
                templateId: card.templateId,
                childId: card.childId,
                at: date
            )
        }
    }
}

// MARK: - Priority Calculation

extension CardRanker {

    /// Calculate priority for a signal result.
    /// Factors: base priority, deadline risk, recency, ease of action.
    static func calculatePriority(
        signal: SignalResult,
        template: CardTemplate
    ) -> Int {
        var priority = template.basePriority.rawValue

        // Boost for goal deadline risk
        if signal.signalType == .goalAtRisk {
            if let daysRemaining = signal.metadata.daysRemaining, daysRemaining <= 3 {
                priority += 2  // Critical deadline
            } else if let daysRemaining = signal.metadata.daysRemaining, daysRemaining <= 7 {
                priority += 1  // Approaching deadline
            }
        }

        // Boost for high confidence
        if signal.confidence > 0.8 {
            priority += 1
        }

        // Boost for 7-day evidence (more recent = more relevant)
        if signal.evidence.window == .sevenDays {
            priority += 1
        }

        // Ease factor: addMoment CTAs are quick actions
        if case .addMoment = template.ctaType {
            priority += 1
        }

        // Cap at max priority
        return min(priority, CardPriority.critical.rawValue + 2)
    }
}
