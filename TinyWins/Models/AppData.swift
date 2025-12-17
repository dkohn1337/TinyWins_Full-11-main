import Foundation

/// Container for all app data, used for JSON serialization
struct AppData: Codable {
    var family: Family
    var children: [Child]
    var behaviorTypes: [BehaviorType]
    var behaviorEvents: [BehaviorEvent]
    var rewards: [Reward]
    var hasCompletedOnboarding: Bool
    var allowanceSettings: AllowanceSettings
    var parentNotes: [ParentNote]
    var behaviorStreaks: [BehaviorStreak]
    var agreementVersions: [AgreementVersion]
    var rewardHistoryEvents: [RewardHistoryEvent]

    // MARK: - Co-Parent Fields (NEW)
    var parents: [Parent]  // Parents in this family
    var currentParentId: String?  // Currently logged-in parent ID

    init(
        family: Family = Family(),
        children: [Child] = [],
        behaviorTypes: [BehaviorType] = BehaviorType.defaultBehaviors,
        behaviorEvents: [BehaviorEvent] = [],
        rewards: [Reward] = [],
        hasCompletedOnboarding: Bool = false,
        allowanceSettings: AllowanceSettings = AllowanceSettings(),
        parentNotes: [ParentNote] = [],
        behaviorStreaks: [BehaviorStreak] = [],
        agreementVersions: [AgreementVersion] = [],
        rewardHistoryEvents: [RewardHistoryEvent] = [],
        parents: [Parent] = [],
        currentParentId: String? = nil
    ) {
        self.family = family
        self.children = children
        self.behaviorTypes = behaviorTypes
        self.behaviorEvents = behaviorEvents
        self.rewards = rewards
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.allowanceSettings = allowanceSettings
        self.parentNotes = parentNotes
        self.behaviorStreaks = behaviorStreaks
        self.agreementVersions = agreementVersions
        self.rewardHistoryEvents = rewardHistoryEvents
        self.parents = parents
        self.currentParentId = currentParentId
    }

    static var empty: AppData {
        AppData()
    }
}

// MARK: - Migration support for new fields
extension AppData {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        family = try container.decode(Family.self, forKey: .family)
        children = try container.decode([Child].self, forKey: .children)
        behaviorTypes = try container.decode([BehaviorType].self, forKey: .behaviorTypes)
        behaviorEvents = try container.decode([BehaviorEvent].self, forKey: .behaviorEvents)
        rewards = try container.decode([Reward].self, forKey: .rewards)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)

        // Optional fields with defaults for migration
        allowanceSettings = try container.decodeIfPresent(AllowanceSettings.self, forKey: .allowanceSettings) ?? AllowanceSettings()
        parentNotes = try container.decodeIfPresent([ParentNote].self, forKey: .parentNotes) ?? []
        behaviorStreaks = try container.decodeIfPresent([BehaviorStreak].self, forKey: .behaviorStreaks) ?? []
        agreementVersions = try container.decodeIfPresent([AgreementVersion].self, forKey: .agreementVersions) ?? []
        rewardHistoryEvents = try container.decodeIfPresent([RewardHistoryEvent].self, forKey: .rewardHistoryEvents) ?? []

        // Co-Parent fields (NEW)
        parents = try container.decodeIfPresent([Parent].self, forKey: .parents) ?? []
        currentParentId = try container.decodeIfPresent(String.self, forKey: .currentParentId)
    }
}

// MARK: - Co-Parent Helpers

extension AppData {
    /// Get the current parent if logged in
    var currentParent: Parent? {
        guard let id = currentParentId else { return nil }
        return parents.first { $0.id == id }
    }

    /// Get the partner (other parent) if exists
    var partnerParent: Parent? {
        guard let currentId = currentParentId else { return nil }
        return parents.first { $0.id != currentId }
    }

    /// Whether this family has co-parent sync enabled
    var hasCoParentSync: Bool {
        parents.count >= 2
    }

    /// Add a parent to the family
    mutating func addParent(_ parent: Parent) {
        if !parents.contains(where: { $0.id == parent.id }) {
            parents.append(parent)
            family.addMember(parent.id)
        }
    }

    /// Get parent by ID
    func parent(byId id: String) -> Parent? {
        parents.first { $0.id == id }
    }

    /// Update a parent's last active time
    mutating func markParentActive(_ parentId: String) {
        if let index = parents.firstIndex(where: { $0.id == parentId }) {
            parents[index].markActive()
        }
    }

    /// Events logged by a specific parent
    func events(loggedBy parentId: String) -> [BehaviorEvent] {
        behaviorEvents.filter { $0.loggedByParentId == parentId }
    }

    /// Events logged by a specific parent in a time period
    func events(loggedBy parentId: String, in period: TimePeriod) -> [BehaviorEvent] {
        let range = period.dateRange
        return behaviorEvents.filter {
            $0.loggedByParentId == parentId &&
            $0.timestamp >= range.start &&
            $0.timestamp <= range.end
        }
    }
}

// MARK: - Reflection Streak

extension AppData {
    /// Calculate the current reflection streak (consecutive days with parent notes)
    func calculateReflectionStreak() -> Int {
        // Get notes sorted by date (newest first)
        let reflectionNotes = parentNotes
            .filter { $0.noteType == .parentWin || $0.noteType == .reflection }
            .sorted { $0.date > $1.date }

        guard !reflectionNotes.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Get unique days with reflections
        let daysWithReflections = Set(reflectionNotes.map { calendar.startOfDay(for: $0.date) })

        // Count consecutive days going backwards from today
        while daysWithReflections.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        return streak
    }
}
