import Foundation
import Combine
import Network

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
#endif

// MARK: - Sync State

/// Represents the current sync status
enum SyncState: Equatable {
    case idle
    case syncing
    case synced(Date)
    case offline
    case error(String)

    var description: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .synced(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .offline: return "Offline"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "cloud"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.icloud"
        case .offline: return "icloud.slash"
        case .error: return "exclamationmark.icloud"
        }
    }
}

// MARK: - Sync Manager

/// Manages seamless offline-first data synchronization.
///
/// Key responsibilities:
/// - Local-first: Data is always saved locally first for instant access
/// - Background sync: Pushes local changes to cloud when connected
/// - Auto-migration: Migrates local data to cloud when user signs in
/// - Connectivity awareness: Monitors network and syncs when available
/// - Conflict resolution: Uses last-write-wins with parent attribution
///
/// Usage:
/// ```
/// syncManager.startMonitoring()
/// syncManager.onDataChanged() // Call after local changes
/// ```
@MainActor
final class SyncManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SyncManager()

    // MARK: - Published State

    @Published private(set) var syncState: SyncState = .idle
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var hasPendingChanges: Bool = false
    @Published private(set) var lastSyncDate: Date?

    // MARK: - Dependencies

    private var repository: Repository?
    private var subscriptionManager: SubscriptionManager?
    private var localBackend: LocalSyncBackend
    private var remoteBackend: FirebaseSyncBackend?

    // MARK: - Network Monitoring

    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.tinywins.network")

    // MARK: - Sync State

    private var syncTask: Task<Void, Never>?
    private var realtimeCancellable: AnyCancellable?
    private var authCancellable: AnyCancellable?
    private var pendingLocalChanges: Bool = false
    private var isInitialized = false

    // Debounce sync requests
    private var syncDebounceTask: Task<Void, Never>?
    private let syncDebounceInterval: TimeInterval = 2.0

    // Prevent duplicate auth handling
    private var lastHandledUserId: String?
    private var isMigrating: Bool = false

    // MARK: - Initialization

    private init() {
        self.localBackend = LocalSyncBackend()
    }

    // MARK: - Setup

    /// Initialize the sync manager with a repository.
    /// Call this early in app startup.
    /// - Parameters:
    ///   - repository: The app's data repository
    ///   - subscriptionManager: Optional subscription manager for co-parent features
    func initialize(repository: Repository, subscriptionManager: SubscriptionManager? = nil) {
        guard !isInitialized else { return }

        self.repository = repository
        self.subscriptionManager = subscriptionManager
        self.isInitialized = true

        // Start network monitoring
        startNetworkMonitoring()

        // Listen for auth state changes
        setupAuthStateListener()

        // Check initial auth state - cloud sync is FREE for all signed-in users
        checkAuthStateAndSetupSync()

        #if DEBUG
        print("[SyncManager] Initialized")
        #endif
    }

    /// Whether user has premium access for CO-PARENT features (not basic cloud sync)
    /// Cloud sync is FREE for all signed-in users.
    /// Premium is only required for: inviting a second parent, partner dashboard.
    private var hasPremiumAccess: Bool {
        subscriptionManager?.effectiveIsPlusSubscriber ?? false
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasConnected = self?.isConnected ?? true
                let isNowConnected = path.status == .satisfied

                self?.isConnected = isNowConnected

                // Also notify SyncQueue of connection status
                SyncQueue.shared.setConnectionStatus(isNowConnected)

                #if DEBUG
                print("[SyncManager] Network status: \(isNowConnected ? "Connected" : "Disconnected")")
                #endif

                // If we just came online and have pending changes, sync
                if !wasConnected && isNowConnected {
                    Task {
                        try? await self?.syncIfNeeded()
                    }
                }

                // Update sync state
                if !isNowConnected {
                    self?.syncState = .offline
                } else if self?.syncState == .offline {
                    self?.syncState = .idle
                }
            }
        }

        networkMonitor.start(queue: networkQueue)
    }

    // MARK: - Auth State Handling

    private func setupAuthStateListener() {
        #if canImport(FirebaseCore)
        // Listen for Firebase auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user: user)
            }
        }
        #endif
    }

    private func checkAuthStateAndSetupSync() {
        #if canImport(FirebaseCore)
        let user = Auth.auth().currentUser
        handleAuthStateChange(user: user)
        #endif
    }

    #if canImport(FirebaseCore)
    private func handleAuthStateChange(user: User?) {
        if let user = user {
            // Skip if already handling this user (prevents duplicate migrations)
            guard lastHandledUserId != user.uid || !isMigrating else {
                #if DEBUG
                print("[SyncManager] Skipping duplicate auth handling for: \(user.uid)")
                #endif
                return
            }
            lastHandledUserId = user.uid

            #if DEBUG
            print("[SyncManager] User signed in: \(user.uid)")
            #endif

            // Cloud sync is FREE for all signed-in users
            // No premium check here - anyone can sync their own data

            // Setup remote backend for cloud sync
            setupRemoteBackend(userId: user.uid)

            // Migrate local data to cloud
            migrateLocalDataToCloud(userId: user.uid, displayName: user.displayName)

        } else {
            #if DEBUG
            print("[SyncManager] User signed out")
            #endif

            // Clear handled user on sign out
            lastHandledUserId = nil

            // User signed out - tear down remote backend
            tearDownRemoteBackend()
        }
    }
    #endif

    /// Call this when user upgrades to premium to enable co-parent features.
    /// Note: Basic cloud sync is FREE - this is only for partner features.
    func onPremiumStatusChanged() {
        // Premium status change doesn't affect basic cloud sync
        // It only gates co-parent features in the UI (CoParentSettingsView)
        #if DEBUG
        print("[SyncManager] Premium status changed - co-parent features updated")
        #endif
    }

    // MARK: - Remote Backend Management

    private func setupRemoteBackend(userId: String, familyId: String? = nil) {
        // Stop existing realtime listener
        realtimeCancellable?.cancel()
        realtimeCancellable = nil

        // Use provided familyId, or fall back to stored familyId
        let effectiveFamilyId = familyId ?? AppConfiguration.storedFamilyId

        // Create new Firebase backend
        remoteBackend = FirebaseSyncBackend(userId: userId, familyId: effectiveFamilyId)

        // Start realtime sync listener
        startRealtimeSync()

        #if DEBUG
        print("[SyncManager] Remote backend setup for user: \(userId), familyId: \(effectiveFamilyId ?? "nil")")
        #endif
    }

    private func tearDownRemoteBackend() {
        realtimeCancellable?.cancel()
        realtimeCancellable = nil
        remoteBackend = nil
        syncState = .idle

        // Clear stored familyId on sign out
        AppConfiguration.storedFamilyId = nil

        #if DEBUG
        print("[SyncManager] Remote backend torn down, familyId cleared")
        #endif
    }

    // MARK: - Realtime Sync

    private func startRealtimeSync() {
        guard let remoteBackend = remoteBackend else { return }

        realtimeCancellable = remoteBackend.startRealtimeSync { [weak self] remoteData in
            Task { @MainActor in
                self?.handleRemoteDataUpdate(remoteData)
            }
        }

        #if DEBUG
        print("[SyncManager] Realtime sync started")
        #endif
    }

    private func handleRemoteDataUpdate(_ remoteData: AppData) {
        guard let repository = repository else { return }

        let currentAppData = repository.appData

        #if DEBUG
        print("[SyncManager] Received remote data update - remote children: \(remoteData.children.count), local children: \(currentAppData.children.count)")
        #endif

        // CRITICAL SAFETY CHECK: Never replace local data with empty/smaller remote data
        // This prevents data loss from timeouts or partial loads
        if remoteData.children.isEmpty && !currentAppData.children.isEmpty {
            #if DEBUG
            print("[SyncManager] ⚠️ BLOCKED: Remote data has 0 children but local has \(currentAppData.children.count). Keeping local data.")
            #endif
            return
        }

        if remoteData.children.count < currentAppData.children.count {
            #if DEBUG
            print("[SyncManager] ⚠️ BLOCKED: Remote has fewer children (\(remoteData.children.count)) than local (\(currentAppData.children.count)). Keeping local data.")
            #endif
            // Don't wipe local data - instead, push local data to cloud
            pendingLocalChanges = true
            return
        }

        // Merge remote data with local
        // Strategy: Remote wins for most data, preserve local pending changes
        var mergedData = remoteData

        // Preserve current parent ID (local state)
        mergedData.currentParentId = currentAppData.currentParentId

        // Preserve local behavior events that might not be in remote yet
        let localEventIds = Set(currentAppData.behaviorEvents.map { $0.id })
        let remoteEventIds = Set(remoteData.behaviorEvents.map { $0.id })
        let missingLocalEvents = currentAppData.behaviorEvents.filter { !remoteEventIds.contains($0.id) }
        if !missingLocalEvents.isEmpty {
            mergedData.behaviorEvents.append(contentsOf: missingLocalEvents)
            #if DEBUG
            print("[SyncManager] Preserved \(missingLocalEvents.count) local events not in remote")
            #endif
        }

        // Update repository with merged data
        repository.updateAppData(mergedData)

        // Also save to local backend for offline access
        try? localBackend.saveAppData(mergedData)

        lastSyncDate = Date()
        syncState = .synced(Date())
    }

    // MARK: - Data Migration (Local → Cloud)

    private func migrateLocalDataToCloud(userId: String, displayName: String?) {
        guard let repository = repository,
              let remoteBackend = remoteBackend else { return }

        // Prevent duplicate migrations
        guard !isMigrating else {
            #if DEBUG
            print("[SyncManager] Migration already in progress, skipping")
            #endif
            return
        }

        isMigrating = true

        Task {
            defer {
                Task { @MainActor in
                    self.isMigrating = false
                }
            }

            await MainActor.run {
                syncState = .syncing
            }

            do {
                // Load current local data
                let localData = repository.appData

                // If we don't have a familyId stored, try to look it up from Firebase
                if AppConfiguration.storedFamilyId == nil {
                    if let foundFamilyId = try await remoteBackend.lookupFamilyId(forUserId: userId) {
                        AppConfiguration.storedFamilyId = foundFamilyId
                        // Also update the Repository's backend so it can save to the correct family
                        await MainActor.run {
                            repository.setBackendFamilyId(foundFamilyId)
                        }
                        #if DEBUG
                        print("[SyncManager] Found and stored existing familyId: \(foundFamilyId)")
                        #endif
                    }
                } else if let storedId = AppConfiguration.storedFamilyId {
                    // We have a stored familyId - ensure the repository's backend has it
                    await MainActor.run {
                        repository.setBackendFamilyId(storedId)
                    }
                    #if DEBUG
                    print("[SyncManager] Using stored familyId: \(storedId)")
                    #endif
                }

                // Check if user already has cloud data
                let existingCloudData = try remoteBackend.loadAppData()

                if let cloudData = existingCloudData {
                    // User has existing cloud data - merge local into it
                    #if DEBUG
                    print("[SyncManager] Merging local data into existing cloud data")
                    #endif

                    // Store the familyId from cloud data if not already stored
                    let cloudFamilyId = cloudData.family.id.uuidString
                    if AppConfiguration.storedFamilyId == nil {
                        AppConfiguration.storedFamilyId = cloudFamilyId
                    }
                    // Ensure the repository's backend has the familyId
                    await MainActor.run {
                        repository.setBackendFamilyId(cloudFamilyId)
                    }

                    // Create parent record if needed
                    let parentName = displayName ?? "Parent"
                    try await remoteBackend.mergeLocalData(localData, parentId: userId, parentName: parentName)

                    // Load the merged data back
                    if let mergedData = try remoteBackend.loadAppData() {
                        await MainActor.run {
                            repository.updateAppData(mergedData)
                            try? self.localBackend.saveAppData(mergedData)
                        }
                    }

                } else {
                    // No cloud data - this is a new cloud user
                    // Upload all local data to cloud
                    #if DEBUG
                    print("[SyncManager] Uploading local data to cloud (new user)")
                    #endif

                    // Create/join a family first
                    let createdFamilyId = try await remoteBackend.createFamily(localData.family)

                    // Store the familyId for future app launches
                    AppConfiguration.storedFamilyId = createdFamilyId

                    // Update the Repository's backend so it can save to the correct family
                    await MainActor.run {
                        repository.setBackendFamilyId(createdFamilyId)
                    }

                    // Update local data with parent attribution
                    var updatedData = localData
                    let parent = Parent(
                        id: userId,
                        displayName: displayName ?? "Parent",
                        email: nil,
                        role: .parent1
                    )
                    updatedData.addParent(parent)
                    updatedData.currentParentId = userId

                    // Tag existing events with this parent
                    updatedData.behaviorEvents = updatedData.behaviorEvents.map { event in
                        var e = event
                        if e.loggedByParentId == nil {
                            e.loggedByParentId = userId
                            e.loggedByParentName = displayName ?? "Parent"
                        }
                        return e
                    }

                    // Save to cloud
                    try remoteBackend.saveAppData(updatedData)

                    // Update local
                    await MainActor.run {
                        repository.updateAppData(updatedData)
                        try? self.localBackend.saveAppData(updatedData)
                    }
                }

                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.syncState = .synced(Date())
                    self.hasPendingChanges = false
                }

                #if DEBUG
                print("[SyncManager] Migration complete")
                #endif

            } catch {
                #if DEBUG
                print("[SyncManager] Migration error: \(error)")
                #endif

                await MainActor.run {
                    self.syncState = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Manual Sync Triggers

    /// Call this after any local data change to trigger background sync.
    /// Uses SyncQueue for smart batching, retry, and optimistic updates.
    func onDataChanged() {
        // Always save locally first (already done by Repository)
        pendingLocalChanges = true
        hasPendingChanges = true

        // Use SyncQueue for smarter debouncing and retry logic
        Task { @MainActor in
            SyncQueue.shared.enqueueDebouncedSync()
        }
    }

    /// Force an immediate sync attempt.
    func syncNow() {
        syncDebounceTask?.cancel()
        Task { @MainActor in
            SyncQueue.shared.processNow()
        }
    }

    /// Internal sync method called by SyncQueue
    func syncIfNeeded() async {
        guard let repository = repository,
              let remoteBackend = remoteBackend,
              isConnected,
              pendingLocalChanges else {
            return
        }

        await MainActor.run {
            syncState = .syncing
        }

        do {
            let localData = repository.appData

            // Push to cloud (SyncQueue handles retries on timeout)
            try remoteBackend.saveAppData(localData)

            // Also ensure local backup is current
            try localBackend.saveAppData(localData)

            await MainActor.run {
                self.pendingLocalChanges = false
                self.hasPendingChanges = false
                self.lastSyncDate = Date()
                self.syncState = .synced(Date())
            }

            #if DEBUG
            print("[SyncManager] Sync completed successfully")
            #endif

        } catch {
            #if DEBUG
            print("[SyncManager] Sync error: \(error)")
            #endif

            // Don't show error state for timeouts - SyncQueue will retry
            let nsError = error as NSError
            let isTimeout = nsError.code == -1001

            await MainActor.run {
                if isTimeout {
                    // Keep syncing state - SyncQueue will retry
                    self.syncState = .syncing
                } else {
                    self.syncState = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Public API

    /// Check if cloud sync is available (user signed in + network connected).
    var isCloudSyncAvailable: Bool {
        remoteBackend != nil && isConnected
    }

    /// Check if user is signed in.
    var isSignedIn: Bool {
        #if canImport(FirebaseCore)
        return Auth.auth().currentUser != nil
        #else
        return false
        #endif
    }

    /// Get the current user ID.
    var currentUserId: String? {
        #if canImport(FirebaseCore)
        return Auth.auth().currentUser?.uid
        #else
        return nil
        #endif
    }

    // MARK: - Cleanup

    func stopMonitoring() {
        networkMonitor.cancel()
        realtimeCancellable?.cancel()
        syncTask?.cancel()
        syncDebounceTask?.cancel()

        #if DEBUG
        print("[SyncManager] Monitoring stopped")
        #endif
    }

    deinit {
        networkMonitor.cancel()
        realtimeCancellable?.cancel()
    }
}

// MARK: - Repository Extension

extension Repository {
    /// Notify sync manager of data changes.
    /// Call this after mutations for automatic cloud sync.
    func notifySyncManager() {
        Task { @MainActor in
            SyncManager.shared.onDataChanged()
        }
    }
}
