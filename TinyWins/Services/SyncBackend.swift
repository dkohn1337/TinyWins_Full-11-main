import Foundation

// MARK: - SyncBackend Protocol

/// Protocol that abstracts AppData-level persistence operations.
/// This allows Repository to work with different storage backends:
/// - LocalSyncBackend: JSON file on device (current behavior)
/// - FirebaseSyncBackend: Firestore cloud storage (future)
///
/// Design decisions:
/// - Synchronous API to match existing DataStore behavior and avoid
///   breaking changes to Repository's internal flow.
/// - Whole-AppData operations rather than per-entity to keep the
///   interface simple and match how local persistence works.
/// - Future backends (e.g., Firebase) will implement async internally
///   but can use completion handlers or Tasks to bridge to this interface.
protocol SyncBackend {

    /// Load the entire AppData from storage.
    /// Returns nil if no data exists (first launch).
    func loadAppData() throws -> AppData?

    /// Save the entire AppData to storage.
    func saveAppData(_ data: AppData) throws

    /// Clear all data from storage.
    /// Used for factory reset functionality.
    func clearAllData() throws

    /// Whether this backend syncs to a remote server.
    /// LocalSyncBackend returns false; FirebaseSyncBackend would return true.
    var isRemote: Bool { get }

    /// A human-readable name for logging/debugging.
    var backendName: String { get }

    /// Set the family ID for remote backends.
    /// This allows updating the familyId after the backend is created,
    /// which is needed when the familyId is discovered after sign-in.
    func setFamilyId(_ familyId: String)
}

// MARK: - Default Implementation

extension SyncBackend {
    var isRemote: Bool { false }
    var backendName: String { "Unknown" }

    /// Default implementation does nothing (for local backends)
    func setFamilyId(_ familyId: String) {
        // No-op for local backends
    }
}

// MARK: - SyncBackend Errors

enum SyncBackendError: LocalizedError {
    case loadFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case clearFailed(underlying: Error)
    case notImplemented(feature: String)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .clearFailed(let error):
            return "Failed to clear data: \(error.localizedDescription)"
        case .notImplemented(let feature):
            return "\(feature) is not implemented in this backend."
        }
    }
}

// MARK: - LocalSyncBackend

/// Local-only sync backend that uses JSON file storage.
/// This replicates the existing DataStore-based persistence behavior.
///
/// This is the default backend when:
/// - Firebase SDK is not installed
/// - Firebase is not configured (no GoogleService-Info.plist)
/// - User is not signed in
final class LocalSyncBackend: SyncBackend {
    
    // MARK: - Properties
    
    private let dataStore: DataStoreProtocol
    
    var isRemote: Bool { false }
    var backendName: String { "LocalSyncBackend" }
    
    // MARK: - Initialization
    
    /// Initialize with a specific DataStore implementation.
    /// - Parameter dataStore: The underlying storage (defaults to JSONDataStore)
    init(dataStore: DataStoreProtocol = JSONDataStore()) {
        self.dataStore = dataStore
    }
    
    // MARK: - SyncBackend Implementation
    
    func loadAppData() throws -> AppData? {
        do {
            return try dataStore.load()
        } catch {
            // If load fails due to missing file, return nil (first launch)
            // Otherwise, propagate the error
            if (error as NSError).domain == NSCocoaErrorDomain,
               (error as NSError).code == NSFileReadNoSuchFileError {
                return nil
            }
            throw SyncBackendError.loadFailed(underlying: error)
        }
    }
    
    func saveAppData(_ data: AppData) throws {
        do {
            try dataStore.save(data)
        } catch {
            throw SyncBackendError.saveFailed(underlying: error)
        }
    }
    
    func clearAllData() throws {
        do {
            try dataStore.clear()
        } catch {
            throw SyncBackendError.clearFailed(underlying: error)
        }
    }
}

// MARK: - Preview/Testing Support

extension LocalSyncBackend {
    
    /// Create a LocalSyncBackend with in-memory storage for previews/tests.
    static var inMemory: LocalSyncBackend {
        LocalSyncBackend(dataStore: InMemoryDataStore())
    }
    
    /// Create a LocalSyncBackend with pre-populated test data.
    static func withTestData(_ data: AppData) -> LocalSyncBackend {
        let store = InMemoryDataStore(initialData: data)
        return LocalSyncBackend(dataStore: store)
    }
}
