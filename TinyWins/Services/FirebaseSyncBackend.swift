import Foundation
import Combine

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseFirestore
#endif

// MARK: - FirebaseSyncBackend

/// Firebase Firestore-backed sync backend for cloud storage.
///
/// This service:
/// - Implements the SyncBackend protocol for Firestore
/// - Provides realtime sync across devices
/// - Supports offline persistence automatically
/// - Organizes data by family for co-parent sharing
///
/// Data Structure:
/// ```
/// families/{familyId}
///   ├── familyData (Family document)
///   ├── children/{childId}
///   ├── behaviorTypes/{typeId}
///   ├── behaviorEvents/{eventId}
///   ├── rewards/{rewardId}
///   └── settings (AllowanceSettings, etc.)
/// ```
///
/// Requirements:
/// - Firebase SDK must be installed via SPM
/// - FirebaseApp.configure() must be called before use
/// - User must be signed in with valid familyId
final class FirebaseSyncBackend: SyncBackend {

    // MARK: - Properties

    private let userId: String
    private var familyId: String?
    private var cancellables = Set<AnyCancellable>()

    #if canImport(FirebaseCore)
    private let db: Firestore
    #endif

    var isRemote: Bool { true }
    var backendName: String { "FirebaseSyncBackend" }

    // MARK: - Publishers for Realtime Updates

    private let dataSubject = PassthroughSubject<AppData, Never>()

    /// Publisher that emits whenever remote data changes.
    var dataPublisher: AnyPublisher<AppData, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    /// Initialize with the current user's ID.
    /// - Parameter userId: The Firebase Auth user ID
    /// - Parameter familyId: Optional family ID (will be fetched from user profile if nil)
    init(userId: String, familyId: String? = nil) {
        self.userId = userId
        self.familyId = familyId

        #if canImport(FirebaseCore)
        self.db = Firestore.firestore()
        // Note: Firestore settings (offline persistence) are configured once at app startup
        // in AppConfiguration.configureFirebaseIfNeeded() - do not set them here

        #if DEBUG
        print("[Sync] FirebaseSyncBackend initialized for user: \(userId)")
        #endif
        #endif
    }

    // MARK: - SyncBackend Implementation

    /// Timeout for sync operations (reduced from 10s for snappier UX)
    private static let operationTimeout: TimeInterval = 3.0

    /// Extended timeout for initial loads
    private static let initialLoadTimeout: TimeInterval = 5.0

    func loadAppData() throws -> AppData? {
        #if canImport(FirebaseCore)
        guard let familyId = familyId else {
            #if DEBUG
            print("[Sync] No family ID set, returning nil")
            #endif
            return nil
        }

        // Use synchronous wrapper for protocol conformance
        // Real-time updates use the async listener methods
        var result: AppData?
        var loadError: Error?

        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                result = try await loadAppDataAsync(familyId: familyId)
            } catch {
                loadError = error
            }
            semaphore.signal()
        }

        // Reduced timeout (3s) - SyncQueue handles retries
        let timeout = semaphore.wait(timeout: .now() + Self.operationTimeout)
        if timeout == .timedOut {
            #if DEBUG
            print("[Sync] Load timed out after \(Self.operationTimeout)s - SyncQueue will retry")
            #endif
            throw SyncBackendError.loadFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1001,
                userInfo: [NSLocalizedDescriptionKey: "Load operation timed out - will retry"]
            ))
        }

        if let error = loadError {
            throw SyncBackendError.loadFailed(underlying: error)
        }

        return result
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }

    func saveAppData(_ data: AppData) throws {
        #if canImport(FirebaseCore)
        guard let familyId = familyId else {
            throw SyncBackendError.saveFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No family ID set"]
            ))
        }

        // Use synchronous wrapper for protocol conformance
        var saveError: Error?

        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                try await saveAppDataAsync(data, familyId: familyId)
            } catch {
                saveError = error
            }
            semaphore.signal()
        }

        // Reduced timeout (3s) - SyncQueue handles retries
        let timeout = semaphore.wait(timeout: .now() + Self.operationTimeout)
        if timeout == .timedOut {
            #if DEBUG
            print("[Sync] Save timed out after \(Self.operationTimeout)s - SyncQueue will retry")
            #endif
            throw SyncBackendError.saveFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1001,
                userInfo: [NSLocalizedDescriptionKey: "Save operation timed out - will retry"]
            ))
        }

        if let error = saveError {
            throw SyncBackendError.saveFailed(underlying: error)
        }
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }

    func clearAllData() throws {
        #if canImport(FirebaseCore)
        guard let familyId = familyId else {
            throw SyncBackendError.clearFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No family ID set"]
            ))
        }

        // Clear is dangerous - we only clear sub-collections, not the family itself
        #if DEBUG
        print("[Sync] WARNING: clearAllData called for family: \(familyId)")
        #endif

        var clearError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                try await clearFamilyDataAsync(familyId: familyId)
            } catch {
                clearError = error
            }
            semaphore.signal()
        }

        // Clear can take longer since it deletes multiple collections
        let timeout = semaphore.wait(timeout: .now() + Self.initialLoadTimeout)
        if timeout == .timedOut {
            #if DEBUG
            print("[Sync] Clear timed out after \(Self.initialLoadTimeout)s")
            #endif
            throw SyncBackendError.clearFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1001,
                userInfo: [NSLocalizedDescriptionKey: "Clear operation timed out"]
            ))
        }

        if let error = clearError {
            throw SyncBackendError.clearFailed(underlying: error)
        }
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }

    // MARK: - Async Implementation

    #if canImport(FirebaseCore)

    private func loadAppDataAsync(familyId: String) async throws -> AppData {
        let familyRef = db.collection("families").document(familyId)

        // Load all data in parallel
        async let familyDoc = familyRef.getDocument()
        async let childrenQuery = familyRef.collection("children").getDocuments()
        async let behaviorTypesQuery = familyRef.collection("behaviorTypes").getDocuments()
        async let behaviorEventsQuery = familyRef.collection("behaviorEvents").getDocuments()
        async let rewardsQuery = familyRef.collection("rewards").getDocuments()
        async let parentNotesQuery = familyRef.collection("parentNotes").getDocuments()
        async let streaksQuery = familyRef.collection("behaviorStreaks").getDocuments()
        async let agreementsQuery = familyRef.collection("agreementVersions").getDocuments()
        async let rewardHistoryQuery = familyRef.collection("rewardHistoryEvents").getDocuments()
        async let parentsQuery = familyRef.collection("parents").getDocuments()

        // Await all queries
        let (familySnapshot, childrenSnapshot, typesSnapshot, eventsSnapshot,
             rewardsSnapshot, notesSnapshot, streaksSnapshot, agreementsSnapshot,
             historySnapshot, parentsSnapshot) = try await (
            familyDoc, childrenQuery, behaviorTypesQuery, behaviorEventsQuery,
            rewardsQuery, parentNotesQuery, streaksQuery, agreementsQuery,
            rewardHistoryQuery, parentsQuery
        )

        // Decode family
        let family: Family
        if let data = familySnapshot.data() {
            family = try Firestore.Decoder().decode(Family.self, from: data)
        } else {
            family = Family(id: UUID(uuidString: familyId) ?? UUID())
        }

        // Decode collections
        let children = try childrenSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(Child.self, from: doc.data())
        }

        let behaviorTypes = try typesSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(BehaviorType.self, from: doc.data())
        }

        let behaviorEvents = try eventsSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(BehaviorEvent.self, from: doc.data())
        }

        let rewards = try rewardsSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(Reward.self, from: doc.data())
        }

        let parentNotes = try notesSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(ParentNote.self, from: doc.data())
        }

        let streaks = try streaksSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(BehaviorStreak.self, from: doc.data())
        }

        let agreements = try agreementsSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(AgreementVersion.self, from: doc.data())
        }

        let rewardHistory = try historySnapshot.documents.map { doc in
            try Firestore.Decoder().decode(RewardHistoryEvent.self, from: doc.data())
        }

        let parents = try parentsSnapshot.documents.map { doc in
            try Firestore.Decoder().decode(Parent.self, from: doc.data())
        }

        // Load settings from family document
        let allowanceSettings: AllowanceSettings
        if let settingsData = familySnapshot.data()?["allowanceSettings"] as? [String: Any] {
            allowanceSettings = try Firestore.Decoder().decode(AllowanceSettings.self, from: settingsData)
        } else {
            allowanceSettings = AllowanceSettings()
        }

        let hasCompletedOnboarding = familySnapshot.data()?["hasCompletedOnboarding"] as? Bool ?? false
        let currentParentId = familySnapshot.data()?["currentParentId"] as? String

        return AppData(
            family: family,
            children: children,
            behaviorTypes: behaviorTypes.isEmpty ? BehaviorType.defaultBehaviors : behaviorTypes,
            behaviorEvents: behaviorEvents,
            rewards: rewards,
            hasCompletedOnboarding: hasCompletedOnboarding,
            allowanceSettings: allowanceSettings,
            parentNotes: parentNotes,
            behaviorStreaks: streaks,
            agreementVersions: agreements,
            rewardHistoryEvents: rewardHistory,
            parents: parents,
            currentParentId: currentParentId
        )
    }

    private func saveAppDataAsync(_ data: AppData, familyId: String) async throws {
        let familyRef = db.collection("families").document(familyId)
        let batch = db.batch()

        // Save family document with settings
        var familyData = try Firestore.Encoder().encode(data.family)
        familyData["hasCompletedOnboarding"] = data.hasCompletedOnboarding
        familyData["allowanceSettings"] = try Firestore.Encoder().encode(data.allowanceSettings)
        familyData["currentParentId"] = data.currentParentId

        // IMPORTANT: Ensure memberIds includes current user for security rules
        // First, get the existing memberIds from the encoded family, then ensure userId is included
        var existingMemberIds = data.family.memberIds
        if !existingMemberIds.contains(userId) {
            existingMemberIds.append(userId)
        }
        familyData["memberIds"] = existingMemberIds

        #if DEBUG
        print("[Sync] Saving family \(familyId) with memberIds: \(existingMemberIds), userId: \(userId)")
        #endif

        batch.setData(familyData, forDocument: familyRef, merge: true)

        // Save children
        for child in data.children {
            let childRef = familyRef.collection("children").document(child.id.uuidString)
            let childData = try Firestore.Encoder().encode(child)
            batch.setData(childData, forDocument: childRef)
        }

        // Save behavior types
        for behaviorType in data.behaviorTypes {
            let typeRef = familyRef.collection("behaviorTypes").document(behaviorType.id.uuidString)
            let typeData = try Firestore.Encoder().encode(behaviorType)
            batch.setData(typeData, forDocument: typeRef)
        }

        // Save behavior events
        for event in data.behaviorEvents {
            let eventRef = familyRef.collection("behaviorEvents").document(event.id.uuidString)
            let eventData = try Firestore.Encoder().encode(event)
            batch.setData(eventData, forDocument: eventRef)
        }

        // Save rewards
        for reward in data.rewards {
            let rewardRef = familyRef.collection("rewards").document(reward.id.uuidString)
            let rewardData = try Firestore.Encoder().encode(reward)
            batch.setData(rewardData, forDocument: rewardRef)
        }

        // Save parent notes
        for note in data.parentNotes {
            let noteRef = familyRef.collection("parentNotes").document(note.id.uuidString)
            let noteData = try Firestore.Encoder().encode(note)
            batch.setData(noteData, forDocument: noteRef)
        }

        // Save streaks
        for streak in data.behaviorStreaks {
            let streakRef = familyRef.collection("behaviorStreaks").document(streak.id.uuidString)
            let streakData = try Firestore.Encoder().encode(streak)
            batch.setData(streakData, forDocument: streakRef)
        }

        // Save agreements
        for agreement in data.agreementVersions {
            let agreementRef = familyRef.collection("agreementVersions").document(agreement.id.uuidString)
            let agreementData = try Firestore.Encoder().encode(agreement)
            batch.setData(agreementData, forDocument: agreementRef)
        }

        // Save reward history
        for historyEvent in data.rewardHistoryEvents {
            let historyRef = familyRef.collection("rewardHistoryEvents").document(historyEvent.id.uuidString)
            let historyData = try Firestore.Encoder().encode(historyEvent)
            batch.setData(historyData, forDocument: historyRef)
        }

        // Save parents
        for parent in data.parents {
            let parentRef = familyRef.collection("parents").document(parent.id)
            let parentData = try Firestore.Encoder().encode(parent)
            batch.setData(parentData, forDocument: parentRef)
        }

        // Commit the batch
        try await batch.commit()
        #if DEBUG
        print("[Sync] Saved all data to Firestore for family: \(familyId)")
        #endif
    }

    private func clearFamilyDataAsync(familyId: String) async throws {
        let familyRef = db.collection("families").document(familyId)

        // Get and delete all sub-collections
        let collections = ["children", "behaviorTypes", "behaviorEvents", "rewards",
                          "parentNotes", "behaviorStreaks", "agreementVersions",
                          "rewardHistoryEvents", "parents"]

        for collectionName in collections {
            let snapshot = try await familyRef.collection(collectionName).getDocuments()
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
        }

        #if DEBUG
        print("[Sync] Cleared all data for family: \(familyId)")
        #endif
    }

    #endif

    // MARK: - Realtime Listeners

    #if canImport(FirebaseCore)

    /// Start listening for realtime updates to family data.
    /// - Parameter onChange: Callback invoked when data changes
    /// - Returns: A cancellable to stop listening
    func startRealtimeSync(onChange: @escaping (AppData) -> Void) -> AnyCancellable? {
        guard let familyId = familyId else {
            #if DEBUG
            print("[Sync] Cannot start realtime sync without family ID")
            #endif
            return nil
        }

        let familyRef = db.collection("families").document(familyId)

        // Listen to the family document
        let listener = familyRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                #if DEBUG
                print("[Sync] Realtime sync error: \(error.localizedDescription)")
                #endif
                return
            }

            // Fetch full data when family doc changes
            Task {
                do {
                    let data = try await self.loadAppDataAsync(familyId: familyId)
                    await MainActor.run {
                        onChange(data)
                        self.dataSubject.send(data)
                    }
                } catch {
                    #if DEBUG
                    print("[Sync] Failed to load data on change: \(error)")
                    #endif
                }
            }
        }

        return AnyCancellable {
            listener.remove()
        }
    }

    #endif

    // MARK: - Family Management

    /// Set the family ID for this backend.
    /// Call this after the user creates or joins a family.
    func setFamilyId(_ familyId: String) {
        self.familyId = familyId
        #if DEBUG
        print("[Sync] Family ID set to: \(familyId)")
        #endif
    }

    /// Create a new family in Firestore.
    /// - Parameter family: The family to create
    /// - Returns: The family ID
    func createFamily(_ family: Family) async throws -> String {
        #if canImport(FirebaseCore)
        let familyId = family.id.uuidString
        let familyRef = db.collection("families").document(familyId)

        var familyData = try Firestore.Encoder().encode(family)
        familyData["createdAt"] = FieldValue.serverTimestamp()
        // IMPORTANT: Add the creator's userId to memberIds for security rules
        familyData["memberIds"] = [userId]

        try await familyRef.setData(familyData)

        self.familyId = familyId
        #if DEBUG
        print("[Sync] Created family: \(familyId) with memberIds: [\(userId)]")
        #endif

        return familyId
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }

    /// Look up the family ID for a user by querying families where they are a member.
    /// - Parameter userId: The user's Firebase Auth UID
    /// - Returns: The family ID if found, nil otherwise
    func lookupFamilyId(forUserId userId: String) async throws -> String? {
        #if canImport(FirebaseCore)
        let snapshot = try await db.collection("families")
            .whereField("memberIds", arrayContains: userId)
            .limit(to: 1)
            .getDocuments()

        if let familyDoc = snapshot.documents.first {
            let foundFamilyId = familyDoc.documentID
            self.familyId = foundFamilyId
            #if DEBUG
            print("[Sync] Found family for user \(userId): \(foundFamilyId)")
            #endif
            return foundFamilyId
        }

        #if DEBUG
        print("[Sync] No family found for user: \(userId)")
        #endif
        return nil
        #else
        return nil
        #endif
    }

    /// Join an existing family by invite code.
    /// - Parameter inviteCode: The 6-character invite code
    /// - Returns: The family ID if successful
    func joinFamily(inviteCode: String) async throws -> String {
        #if canImport(FirebaseCore)
        // Find family with this invite code
        let snapshot = try await db.collection("families")
            .whereField("inviteCode", isEqualTo: inviteCode.uppercased())
            .limit(to: 1)
            .getDocuments()

        guard let familyDoc = snapshot.documents.first else {
            throw SyncBackendError.loadFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"]
            ))
        }

        // Check if invite code is expired
        if let expiresAt = familyDoc.data()["inviteCodeExpiresAt"] as? Timestamp {
            if expiresAt.dateValue() < Date() {
                throw SyncBackendError.loadFailed(underlying: NSError(
                    domain: "FirebaseSync",
                    code: 410,
                    userInfo: [NSLocalizedDescriptionKey: "Invite code has expired"]
                ))
            }
        }

        let familyId = familyDoc.documentID
        self.familyId = familyId

        // Add current user to family members
        try await familyDoc.reference.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])

        #if DEBUG
        print("[Sync] Joined family: \(familyId)")
        #endif
        return familyId
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }

    /// Generate a new invite code for the current family.
    /// - Parameter validForDays: Number of days the code is valid (default 7)
    /// - Returns: The generated invite code
    func generateInviteCode(validForDays: Int = 7) async throws -> String {
        #if canImport(FirebaseCore)
        guard let familyId = familyId else {
            throw SyncBackendError.saveFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No family ID set"]
            ))
        }

        let inviteCode = Family.randomInviteCode()
        let expiresAt = Calendar.current.date(byAdding: .day, value: validForDays, to: Date())!

        let familyRef = db.collection("families").document(familyId)
        try await familyRef.updateData([
            "inviteCode": inviteCode,
            "inviteCodeExpiresAt": Timestamp(date: expiresAt)
        ])

        #if DEBUG
        print("[Sync] Generated invite code: \(inviteCode) for family: \(familyId)")
        #endif
        return inviteCode
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }
}

// MARK: - Data Merge Support

extension FirebaseSyncBackend {

    /// Merge local data into the family's cloud data.
    /// Used when a user with existing local data creates or joins a family.
    /// - Parameter localData: The local AppData to merge
    /// - Parameter parentId: The ID of the parent merging data
    /// - Parameter parentName: The name of the parent (for attribution)
    func mergeLocalData(_ localData: AppData, parentId: String, parentName: String) async throws {
        #if canImport(FirebaseCore)
        guard let familyId = familyId else {
            throw SyncBackendError.saveFailed(underlying: NSError(
                domain: "FirebaseSync",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No family ID set"]
            ))
        }

        // Load existing cloud data
        let cloudData = try await loadAppDataAsync(familyId: familyId)

        // Merge children (avoid duplicates by name)
        var mergedChildren = cloudData.children
        for localChild in localData.children {
            if !mergedChildren.contains(where: { $0.name == localChild.name }) {
                mergedChildren.append(localChild)
            }
        }

        // Merge behavior events with parent attribution
        var mergedEvents = cloudData.behaviorEvents
        for localEvent in localData.behaviorEvents {
            // Check for duplicates by timestamp + childId + behaviorTypeId
            let isDuplicate = mergedEvents.contains { existing in
                existing.timestamp == localEvent.timestamp &&
                existing.childId == localEvent.childId &&
                existing.behaviorTypeId == localEvent.behaviorTypeId
            }

            if !isDuplicate {
                // Add parent attribution to local events
                let attributedEvent = localEvent.withParentAttribution(
                    parentId: parentId,
                    parentName: parentName
                )
                mergedEvents.append(attributedEvent)
            }
        }

        // Merge rewards (avoid duplicates by name)
        var mergedRewards = cloudData.rewards
        for localReward in localData.rewards {
            if !mergedRewards.contains(where: { $0.name == localReward.name }) {
                mergedRewards.append(localReward)
            }
        }

        // Merge behavior types (avoid duplicates by name)
        var mergedTypes = cloudData.behaviorTypes
        for localType in localData.behaviorTypes {
            if !mergedTypes.contains(where: { $0.name == localType.name }) {
                mergedTypes.append(localType)
            }
        }

        // Create merged AppData
        let mergedData = AppData(
            family: cloudData.family,
            children: mergedChildren,
            behaviorTypes: mergedTypes,
            behaviorEvents: mergedEvents,
            rewards: mergedRewards,
            hasCompletedOnboarding: cloudData.hasCompletedOnboarding || localData.hasCompletedOnboarding,
            allowanceSettings: cloudData.allowanceSettings,
            parentNotes: cloudData.parentNotes + localData.parentNotes,
            behaviorStreaks: cloudData.behaviorStreaks,
            agreementVersions: cloudData.agreementVersions,
            rewardHistoryEvents: cloudData.rewardHistoryEvents + localData.rewardHistoryEvents,
            parents: cloudData.parents,
            currentParentId: cloudData.currentParentId
        )

        // Save merged data
        try await saveAppDataAsync(mergedData, familyId: familyId)
        #if DEBUG
        print("[Sync] Merged local data into family: \(familyId)")
        #endif
        #else
        throw SyncBackendError.notImplemented(feature: "Firebase sync")
        #endif
    }
}
