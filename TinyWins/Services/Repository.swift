import Foundation

/// Repository protocol for clean data access abstraction
/// This can be swapped for a network-backed implementation in the future
protocol RepositoryProtocol: AnyObject {
    // Family
    func getFamily() -> Family
    func updateFamily(_ family: Family)
    
    // Children
    func getChildren() -> [Child]
    func getChild(id: UUID) -> Child?
    func addChild(_ child: Child)
    func updateChild(_ child: Child)
    func deleteChild(id: UUID)
    
    // Behavior Types
    func getBehaviorTypes() -> [BehaviorType]
    func getActiveBehaviorTypes() -> [BehaviorType]
    func getBehaviorType(id: UUID) -> BehaviorType?
    func addBehaviorType(_ behaviorType: BehaviorType)
    func updateBehaviorType(_ behaviorType: BehaviorType)
    func deleteBehaviorType(id: UUID)
    
    // Behavior Events
    func getBehaviorEvents() -> [BehaviorEvent]
    func getBehaviorEvents(forChild childId: UUID) -> [BehaviorEvent]
    func getTodayEvents() -> [BehaviorEvent]
    func getTodayEvents(forChild childId: UUID) -> [BehaviorEvent]
    func addBehaviorEvent(_ event: BehaviorEvent)
    func updateBehaviorEvent(_ event: BehaviorEvent)
    func deleteBehaviorEvent(id: UUID)
    
    // Rewards
    func getRewards() -> [Reward]
    func getRewards(forChild childId: UUID) -> [Reward]
    func getActiveReward(forChild childId: UUID) -> Reward?
    func getReward(id: UUID) -> Reward?
    func addReward(_ reward: Reward)
    func updateReward(_ reward: Reward)
    func deleteReward(id: UUID)
    
    // Allowance Settings
    func getAllowanceSettings() -> AllowanceSettings
    func updateAllowanceSettings(_ settings: AllowanceSettings)
    
    // Parent Notes
    func getParentNotes() -> [ParentNote]
    func addParentNote(_ note: ParentNote)
    
    // Behavior Consistency (Internal Analytics)
    func getBehaviorStreaks() -> [BehaviorStreak]
    func updateStreak(childId: UUID, behaviorTypeId: UUID)
    
    // Agreement Versions
    func getAgreementVersions() -> [AgreementVersion]
    func getAgreementVersions(forChild childId: UUID) -> [AgreementVersion]
    func getCurrentAgreement(forChild childId: UUID) -> AgreementVersion?
    func addAgreementVersion(_ agreement: AgreementVersion)
    func updateAgreementVersion(_ agreement: AgreementVersion)
    
    // Reward History Events
    func getRewardHistoryEvents() -> [RewardHistoryEvent]
    func getRewardHistoryEvents(forChild childId: UUID) -> [RewardHistoryEvent]
    func addRewardHistoryEvent(_ event: RewardHistoryEvent)
    
    // Onboarding
    var hasCompletedOnboarding: Bool { get set }
    
    // Persistence
    func save()
    func reload()
    
    // Bulk Save (for backup restore)
    func save(family: Family)
    func save(children: [Child])
    func save(behaviorTypes: [BehaviorType])
    func save(behaviorEvents: [BehaviorEvent])
    func save(rewards: [Reward])
    func save(allowanceSettings: AllowanceSettings)
    func save(parentNotes: [ParentNote])
    func save(behaviorStreaks: [BehaviorStreak])
    func save(agreementVersions: [AgreementVersion])
    func save(rewardHistoryEvents: [RewardHistoryEvent])
    
    // Data Reset
    func clearAllData()
}

/// Main repository implementation using a SyncBackend for persistence.
///
/// Architecture:
/// - Repository holds in-memory AppData for fast access
/// - SyncBackend handles persistence (local JSON or future Firebase)
/// - All mutations go through Repository methods, which update in-memory
///   state and then persist via SyncBackend
///
/// This design allows:
/// - Swapping LocalSyncBackend for FirebaseSyncBackend without changing Repository logic
/// - Future support for offline-first with background sync
final class Repository: RepositoryProtocol, ObservableObject {

    // MARK: - Properties

    /// The sync backend used for persistence.
    /// This abstracts whether we're using local JSON or cloud storage.
    private let backend: SyncBackend

    /// In-memory cache of all app data.
    /// Loaded from backend on init, persisted on changes.
    @Published private(set) var appData: AppData

    // MARK: - Save Serialization

    /// Serial queue for save operations to prevent race conditions
    private let saveQueue = DispatchQueue(label: "com.tinywins.repository.save")

    /// Debounce task for coalescing rapid saves
    private var saveDebounceTask: DispatchWorkItem?

    /// Debounce interval for save coalescing (100ms)
    private let saveDebounceInterval: TimeInterval = 0.1

    /// Whether a save is pending
    private var hasPendingSave: Bool = false
    
    /// For backwards compatibility with code that uses DataStore directly.
    /// This property is deprecated - use SyncBackend instead.
    @available(*, deprecated, message: "Use SyncBackend instead of DataStore")
    var dataStore: DataStoreProtocol {
        // Create a wrapper that delegates to the backend
        return SyncBackendDataStoreWrapper(backend: backend)
    }
    
    // MARK: - Initialization
    
    /// Primary initializer with SyncBackend.
    /// - Parameter backend: The sync backend to use for persistence
    init(backend: SyncBackend) {
        self.backend = backend
        
        // Load initial data from backend
        self.appData = (try? backend.loadAppData()) ?? .empty

        #if DEBUG
        print("[Repository] Initialized with \(backend.backendName)")
        print("[Repository] Loaded \(appData.children.count) children, \(appData.behaviorEvents.count) events")
        #endif
    }
    
    /// Convenience initializer using LocalSyncBackend.
    /// This preserves existing behavior for call sites that use Repository().
    convenience init() {
        let localBackend = LocalSyncBackend()
        self.init(backend: localBackend)
    }
    
    /// Backwards-compatible initializer that accepts a DataStore.
    /// - Parameter dataStore: The data store to use (wrapped in LocalSyncBackend)
    @available(*, deprecated, message: "Use init(backend:) instead")
    convenience init(dataStore: DataStoreProtocol) {
        let localBackend = LocalSyncBackend(dataStore: dataStore)
        self.init(backend: localBackend)
    }
    
    // MARK: - Family
    
    func getFamily() -> Family {
        appData.family
    }
    
    func updateFamily(_ family: Family) {
        appData.family = family
        save()
    }
    
    // MARK: - Children
    
    func getChildren() -> [Child] {
        appData.children
    }
    
    func getChild(id: UUID) -> Child? {
        appData.children.first { $0.id == id }
    }
    
    func addChild(_ child: Child) {
        appData.children.append(child)
        save()
    }
    
    func updateChild(_ child: Child) {
        if let index = appData.children.firstIndex(where: { $0.id == child.id }) {
            appData.children[index] = child
            save()
        }
    }
    
    func deleteChild(id: UUID) {
        appData.children.removeAll { $0.id == id }
        appData.behaviorEvents.removeAll { $0.childId == id }
        appData.rewards.removeAll { $0.childId == id }
        save()
    }
    
    // MARK: - Behavior Types
    
    func getBehaviorTypes() -> [BehaviorType] {
        appData.behaviorTypes
    }
    
    func getActiveBehaviorTypes() -> [BehaviorType] {
        appData.behaviorTypes.filter { $0.isActive }
    }
    
    func getBehaviorType(id: UUID) -> BehaviorType? {
        appData.behaviorTypes.first { $0.id == id }
    }
    
    func addBehaviorType(_ behaviorType: BehaviorType) {
        appData.behaviorTypes.append(behaviorType)
        save()
    }
    
    func updateBehaviorType(_ behaviorType: BehaviorType) {
        if let index = appData.behaviorTypes.firstIndex(where: { $0.id == behaviorType.id }) {
            appData.behaviorTypes[index] = behaviorType
            save()
        }
    }
    
    func deleteBehaviorType(id: UUID) {
        appData.behaviorTypes.removeAll { $0.id == id }
        // Also remove related events
        appData.behaviorEvents.removeAll { $0.behaviorTypeId == id }
        save()
    }
    
    // MARK: - Behavior Events
    
    func getBehaviorEvents() -> [BehaviorEvent] {
        appData.behaviorEvents
    }
    
    func getBehaviorEvents(forChild childId: UUID) -> [BehaviorEvent] {
        appData.behaviorEvents.filter { $0.childId == childId }
    }
    
    func getTodayEvents() -> [BehaviorEvent] {
        let calendar = Calendar.current
        return appData.behaviorEvents.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    func getTodayEvents(forChild childId: UUID) -> [BehaviorEvent] {
        let calendar = Calendar.current
        return appData.behaviorEvents.filter {
            $0.childId == childId && calendar.isDateInToday($0.timestamp)
        }
    }
    
    func addBehaviorEvent(_ event: BehaviorEvent) {
        appData.behaviorEvents.append(event)
        
        // Update child's total points
        if let index = appData.children.firstIndex(where: { $0.id == event.childId }) {
            appData.children[index].totalPoints += event.pointsApplied
        }
        
        save()
    }
    
    func updateBehaviorEvent(_ event: BehaviorEvent) {
        if let index = appData.behaviorEvents.firstIndex(where: { $0.id == event.id }) {
            appData.behaviorEvents[index] = event
            save()
        }
    }
    
    func deleteBehaviorEvent(id: UUID) {
        if let event = appData.behaviorEvents.first(where: { $0.id == id }) {
            // Update child's total points
            if let index = appData.children.firstIndex(where: { $0.id == event.childId }) {
                appData.children[index].totalPoints -= event.pointsApplied
                // Also subtract any allowance earned
                if let allowance = event.earnedAllowance {
                    appData.children[index].totalAllowanceEarned -= allowance
                }
            }
            
            // Delete associated media
            for attachment in event.mediaAttachments {
                MediaManager.shared.deleteMedia(attachment)
            }
            
            appData.behaviorEvents.removeAll { $0.id == id }
            save()
        }
    }
    
    // MARK: - Events by Time Period
    
    func getEvents(forChild childId: UUID, period: TimePeriod) -> [BehaviorEvent] {
        let (start, end) = period.dateRange
        return appData.behaviorEvents.filter {
            $0.childId == childId &&
            $0.timestamp >= start &&
            $0.timestamp <= end
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getAllEvents(forPeriod period: TimePeriod) -> [BehaviorEvent] {
        let (start, end) = period.dateRange
        return appData.behaviorEvents.filter {
            $0.timestamp >= start &&
            $0.timestamp <= end
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Allowance
    
    func recordAllowancePayout(childId: UUID, amount: Double) {
        if let index = appData.children.firstIndex(where: { $0.id == childId }) {
            appData.children[index].allowancePaidOut += amount
            save()
        }
    }
    
    // MARK: - Rewards
    
    func getRewards() -> [Reward] {
        appData.rewards
    }
    
    func getRewards(forChild childId: UUID) -> [Reward] {
        appData.rewards.filter { $0.childId == childId }
    }
    
    func getActiveReward(forChild childId: UUID) -> Reward? {
        guard let child = getChild(id: childId),
              let rewardId = child.activeRewardId else {
            return nil
        }
        return getReward(id: rewardId)
    }
    
    func getReward(id: UUID) -> Reward? {
        appData.rewards.first { $0.id == id }
    }
    
    func addReward(_ reward: Reward) {
        appData.rewards.append(reward)
        
        // Set as active reward for the child
        if let index = appData.children.firstIndex(where: { $0.id == reward.childId }) {
            appData.children[index].activeRewardId = reward.id
        }
        
        save()
    }
    
    func updateReward(_ reward: Reward) {
        if let index = appData.rewards.firstIndex(where: { $0.id == reward.id }) {
            appData.rewards[index] = reward
            
            // If completed, clear activeRewardId from child
            if reward.isRedeemed {
                if let childIndex = appData.children.firstIndex(where: { $0.id == reward.childId }) {
                    if appData.children[childIndex].activeRewardId == reward.id {
                        appData.children[childIndex].activeRewardId = nil
                    }
                }
            }
            
            save()
        }
    }
    
    func deleteReward(id: UUID) {
        if let reward = appData.rewards.first(where: { $0.id == id }) {
            // Clear activeRewardId if this was the active reward
            if let childIndex = appData.children.firstIndex(where: { $0.id == reward.childId }) {
                if appData.children[childIndex].activeRewardId == id {
                    appData.children[childIndex].activeRewardId = nil
                }
            }
        }
        appData.rewards.removeAll { $0.id == id }
        save()
    }
    
    // MARK: - Onboarding
    
    var hasCompletedOnboarding: Bool {
        get { appData.hasCompletedOnboarding }
        set {
            appData.hasCompletedOnboarding = newValue
            save()
        }
    }
    
    // MARK: - Allowance Settings
    
    func getAllowanceSettings() -> AllowanceSettings {
        appData.allowanceSettings
    }
    
    func updateAllowanceSettings(_ settings: AllowanceSettings) {
        appData.allowanceSettings = settings
        save()
    }
    
    // MARK: - Parent Notes

    func getParentNotes() -> [ParentNote] {
        appData.parentNotes.sorted { $0.date > $1.date }
    }

    func getParentNotes(from startDate: Date, to endDate: Date) -> [ParentNote] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate

        return appData.parentNotes.filter { note in
            note.date >= start && note.date < end
        }.sorted { $0.date > $1.date }
    }

    func getParentNotes(forDay date: Date) -> [ParentNote] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return appData.parentNotes.filter { note in
            note.date >= startOfDay && note.date < endOfDay
        }.sorted { $0.date > $1.date }
    }

    func getDaysWithReflections(from startDate: Date, to endDate: Date) -> Set<Date> {
        let calendar = Calendar.current
        let notes = getParentNotes(from: startDate, to: endDate)
        return Set(notes.map { calendar.startOfDay(for: $0.date) })
    }

    func addParentNote(_ note: ParentNote) {
        appData.parentNotes.append(note)
        save()
    }

    func updateParentNote(_ note: ParentNote) {
        if let index = appData.parentNotes.firstIndex(where: { $0.id == note.id }) {
            appData.parentNotes[index] = note
            save()
        }
    }
    
    // MARK: - Behavior Consistency (Internal Analytics - NOT user-facing)
    
    func getBehaviorStreaks() -> [BehaviorStreak] {
        appData.behaviorStreaks
    }
    
    func updateStreak(childId: UUID, behaviorTypeId: UUID) {
        if let index = appData.behaviorStreaks.firstIndex(where: {
            $0.childId == childId && $0.behaviorTypeId == behaviorTypeId
        }) {
            appData.behaviorStreaks[index].updateStreak()
        } else {
            var newStreak = BehaviorStreak(childId: childId, behaviorTypeId: behaviorTypeId)
            newStreak.updateStreak()
            appData.behaviorStreaks.append(newStreak)
        }
        save()
    }
    
    // MARK: - Agreement Versions
    
    func getAgreementVersions() -> [AgreementVersion] {
        appData.agreementVersions
    }
    
    func getAgreementVersions(forChild childId: UUID) -> [AgreementVersion] {
        appData.agreementVersions.filter { $0.childId == childId }
    }
    
    func getCurrentAgreement(forChild childId: UUID) -> AgreementVersion? {
        appData.agreementVersions.first { $0.childId == childId && $0.isCurrent }
    }
    
    func addAgreementVersion(_ agreement: AgreementVersion) {
        appData.agreementVersions.append(agreement)
        save()
    }
    
    func updateAgreementVersion(_ agreement: AgreementVersion) {
        if let index = appData.agreementVersions.firstIndex(where: { $0.id == agreement.id }) {
            appData.agreementVersions[index] = agreement
            save()
        }
    }
    
    // MARK: - Reward History Events
    
    func getRewardHistoryEvents() -> [RewardHistoryEvent] {
        appData.rewardHistoryEvents
    }
    
    func getRewardHistoryEvents(forChild childId: UUID) -> [RewardHistoryEvent] {
        appData.rewardHistoryEvents.filter { $0.childId == childId }
    }
    
    func addRewardHistoryEvent(_ event: RewardHistoryEvent) {
        appData.rewardHistoryEvents.append(event)
        save()
    }
    
    // MARK: - Persistence

    func save() {
        // Mark that we have pending changes
        hasPendingSave = true

        // Cancel any existing debounce task
        saveDebounceTask?.cancel()

        // Create new debounced save task
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        saveDebounceTask = workItem

        // Schedule the save after debounce interval
        saveQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
    }

    /// Perform the actual save operation (called after debounce)
    private func performSave() {
        guard hasPendingSave else { return }
        hasPendingSave = false

        // Capture appData on the calling thread
        let dataToSave = appData

        // Perform save on the serial queue to prevent races
        saveQueue.sync {
            do {
                try backend.saveAppData(dataToSave)
            } catch {
                #if DEBUG
                print("[Repository] Save failed: \(error.localizedDescription)")
                #endif
            }
        }

        // Notify sync manager for background cloud sync (on main thread)
        DispatchQueue.main.async { [weak self] in
            self?.notifySyncManager()
        }
    }

    /// Force an immediate save without debouncing (for critical operations)
    func saveImmediately() {
        saveDebounceTask?.cancel()
        hasPendingSave = true
        performSave()
    }

    /// Update the entire app data and save.
    /// Used for bulk updates like co-parent sync.
    func updateAppData(_ newData: AppData) {
        appData = newData
        save()
    }
    
    func reload() {
        appData = (try? backend.loadAppData()) ?? .empty
    }
    
    // MARK: - Bulk Save (for Backup Restore)
    
    func save(family: Family) {
        appData.family = family
        save()
    }
    
    func save(children: [Child]) {
        appData.children = children
        save()
    }
    
    func save(behaviorTypes: [BehaviorType]) {
        appData.behaviorTypes = behaviorTypes
        save()
    }
    
    func save(behaviorEvents: [BehaviorEvent]) {
        appData.behaviorEvents = behaviorEvents
        save()
    }
    
    func save(rewards: [Reward]) {
        appData.rewards = rewards
        save()
    }
    
    func save(allowanceSettings: AllowanceSettings) {
        appData.allowanceSettings = allowanceSettings
        save()
    }
    
    func save(parentNotes: [ParentNote]) {
        appData.parentNotes = parentNotes
        save()
    }
    
    func save(behaviorStreaks: [BehaviorStreak]) {
        appData.behaviorStreaks = behaviorStreaks
        save()
    }
    
    func save(agreementVersions: [AgreementVersion]) {
        appData.agreementVersions = agreementVersions
        save()
    }
    
    func save(rewardHistoryEvents: [RewardHistoryEvent]) {
        appData.rewardHistoryEvents = rewardHistoryEvents
        save()
    }
    
    func clearAllData() {
        appData = .empty
        hasCompletedOnboarding = false

        do {
            try backend.clearAllData()
        } catch {
            #if DEBUG
            print("[Repository] Clear failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Load demo data, replacing all existing data
    func loadDemoData() {
        let demoData = DemoDataGenerator.shared.generateDemoData()

        // Clear existing data first
        clearAllData()

        // Set all the demo data
        appData = demoData
        hasCompletedOnboarding = true

        // Save to backend
        save()

        // Reload to ensure stores are updated
        reload()

        #if DEBUG
        print("[Repository] Demo data loaded successfully")
        print("  - Children: \(demoData.children.count)")
        print("  - Behavior Events: \(demoData.behaviorEvents.count)")
        print("  - Rewards: \(demoData.rewards.count)")
        print("  - Parents: \(demoData.parents.count)")
        #endif
    }

    // MARK: - Backend Info

    /// Whether the repository is using a remote sync backend.
    var isUsingRemoteBackend: Bool {
        backend.isRemote
    }

    /// The name of the current backend (for debugging).
    var backendName: String {
        backend.backendName
    }

    /// Set the family ID on the backend.
    /// This is called by SyncManager after discovering the familyId.
    func setBackendFamilyId(_ familyId: String) {
        backend.setFamilyId(familyId)
        #if DEBUG
        print("[Repository] Backend familyId set to: \(familyId)")
        #endif
    }

    // MARK: - Data Export

    /// Export all user data as JSON for GDPR/CCPA compliance.
    /// Returns a URL to a temporary file containing the exported data.
    func exportDataAsJSON() throws -> URL {
        // Create export data structure (privacy-safe version)
        let exportData = ExportableData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            family: appData.family,
            children: appData.children.map { child in
                // Remove signature image data for privacy (it's just decorative drawings anyway)
                var exportChild = child
                exportChild.childSignature = AgreementSignature()
                exportChild.parentSignature = AgreementSignature()
                return exportChild
            },
            behaviorTypes: appData.behaviorTypes,
            behaviorEvents: appData.behaviorEvents,
            rewards: appData.rewards,
            parentNotes: appData.parentNotes,
            rewardHistory: appData.rewardHistoryEvents
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)

        // Write to temp file with family name in filename
        let sanitizedFamilyName = sanitizeForFilename(appData.family.name)
        let fileName = "TinyWins_\(sanitizedFamilyName)_\(formattedExportDate()).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)

        return tempURL
    }

    private func formattedExportDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }

    /// Sanitize a string for use in a filename
    private func sanitizeForFilename(_ name: String) -> String {
        // Remove or replace characters that are invalid in filenames
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>: ")
        let sanitized = name.components(separatedBy: invalidCharacters).joined(separator: "")
        // Limit length and provide fallback
        let trimmed = String(sanitized.prefix(30))
        return trimmed.isEmpty ? "Family" : trimmed
    }
}

// MARK: - Exportable Data Structure

/// Privacy-safe data structure for user export (GDPR/CCPA compliance)
struct ExportableData: Codable {
    let exportDate: Date
    let appVersion: String
    let family: Family
    let children: [Child]
    let behaviorTypes: [BehaviorType]
    let behaviorEvents: [BehaviorEvent]
    let rewards: [Reward]
    let parentNotes: [ParentNote]
    let rewardHistory: [RewardHistoryEvent]
}

// MARK: - Preview Repository

extension Repository {
    static var preview: Repository {
        let backend = LocalSyncBackend.inMemory
        let repo = Repository(backend: backend)
        
        // Add sample children
        let child1 = Child(name: "Emma", age: 8, colorTag: .purple, totalPoints: 45)
        let child2 = Child(name: "Lucas", age: 6, colorTag: .blue, totalPoints: 28)
        
        repo.addChild(child1)
        repo.addChild(child2)
        
        // Add sample reward
        let reward = Reward(childId: child1.id, name: "Movie Night", targetPoints: 50)
        repo.addReward(reward)
        
        // Add sample events
        let behaviors = repo.getActiveBehaviorTypes()
        if let morningRoutine = behaviors.first(where: { $0.name.contains("Morning") }) {
            repo.addBehaviorEvent(BehaviorEvent(
                childId: child1.id,
                behaviorTypeId: morningRoutine.id,
                pointsApplied: morningRoutine.defaultPoints
            ))
        }
        
        return repo
    }
}

// MARK: - DataStore Wrapper (for backwards compatibility)

/// Wrapper that adapts SyncBackend to DataStoreProtocol.
/// This is for backwards compatibility only - new code should use SyncBackend directly.
private final class SyncBackendDataStoreWrapper: DataStoreProtocol {
    private let backend: SyncBackend
    
    init(backend: SyncBackend) {
        self.backend = backend
    }
    
    func load() throws -> AppData {
        try backend.loadAppData() ?? .empty
    }
    
    func save(_ data: AppData) throws {
        try backend.saveAppData(data)
    }
    
    func clear() throws {
        try backend.clearAllData()
    }
}
