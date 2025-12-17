import Foundation
import Combine

// MARK: - Sync Operation

/// A queued sync operation with retry support
struct SyncOperation: Identifiable, Equatable {
    let id: UUID
    let type: OperationType
    let priority: Priority
    let createdAt: Date
    var attemptCount: Int
    var lastAttemptAt: Date?
    var lastError: String?

    enum OperationType: Equatable {
        case fullSync
        case incrementalSync
        case pushOnly
    }

    enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case immediate = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    init(type: OperationType, priority: Priority = .normal) {
        self.id = UUID()
        self.type = type
        self.priority = priority
        self.createdAt = Date()
        self.attemptCount = 0
        self.lastAttemptAt = nil
        self.lastError = nil
    }

    /// Calculate backoff delay based on attempt count
    var backoffDelay: TimeInterval {
        // Exponential backoff: 1s, 2s, 4s, 8s, max 30s
        let baseDelay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 30.0
        let delay = baseDelay * pow(2.0, Double(attemptCount - 1))
        return min(delay, maxDelay)
    }

    /// Whether this operation can be retried
    var canRetry: Bool {
        attemptCount < SyncQueue.maxRetries
    }
}

// MARK: - Sync Queue Configuration

/// Configuration for sync queue behavior
struct SyncQueueConfig {
    /// Initial timeout for sync operations (reduced from 10s)
    var operationTimeout: TimeInterval = 3.0

    /// Maximum retries before giving up
    var maxRetries: Int = 3

    /// Debounce interval for coalescing rapid changes
    var debounceInterval: TimeInterval = 0.5

    /// Minimum interval between sync attempts
    var minSyncInterval: TimeInterval = 2.0

    /// Whether to use optimistic updates
    var enableOptimisticUpdates: Bool = true

    /// Whether to batch writes when possible
    var enableBatchWrites: Bool = true

    static let `default` = SyncQueueConfig()

    static let aggressive = SyncQueueConfig(
        operationTimeout: 5.0,
        maxRetries: 5,
        debounceInterval: 0.3,
        minSyncInterval: 1.0
    )

    static let conservative = SyncQueueConfig(
        operationTimeout: 10.0,
        maxRetries: 2,
        debounceInterval: 1.0,
        minSyncInterval: 5.0
    )
}

// MARK: - Sync Queue

/// Background sync queue with retry, batching, and optimistic updates.
///
/// Key features:
/// - Coalesces rapid changes to reduce network calls
/// - Exponential backoff on failures
/// - Priority queue for urgent operations
/// - Connection-aware (pauses when offline)
/// - Optimistic UI updates with rollback on failure
@MainActor
final class SyncQueue: ObservableObject {

    // MARK: - Singleton

    static let shared = SyncQueue()

    // MARK: - Configuration

    static let maxRetries = 3
    private var config: SyncQueueConfig

    // MARK: - Published State

    @Published private(set) var pendingOperations: [SyncOperation] = []
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var lastSuccessfulSync: Date?
    @Published private(set) var consecutiveFailures: Int = 0

    /// Current sync health status
    var syncHealth: SyncHealth {
        if consecutiveFailures >= 3 {
            return .degraded
        } else if consecutiveFailures >= 1 {
            return .warning
        } else {
            return .healthy
        }
    }

    enum SyncHealth {
        case healthy
        case warning
        case degraded

        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .degraded: return "xmark.circle.fill"
            }
        }
    }

    // MARK: - Private State

    private var processingTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var isConnected: Bool = true

    // Optimistic update tracking
    private var pendingOptimisticUpdates: [UUID: AppData] = [:]

    // MARK: - Initialization

    private init(config: SyncQueueConfig = .default) {
        self.config = config
    }

    // MARK: - Public API

    /// Enqueue a sync operation
    func enqueue(_ operation: SyncOperation) {
        // Check for duplicate operations of same type
        if let existingIndex = pendingOperations.firstIndex(where: { $0.type == operation.type }) {
            // If new operation has higher priority, replace
            if operation.priority > pendingOperations[existingIndex].priority {
                pendingOperations[existingIndex] = operation
            }
            // Otherwise, ignore duplicate
            return
        }

        pendingOperations.append(operation)

        // Sort by priority (highest first)
        pendingOperations.sort { $0.priority > $1.priority }

        // Trigger processing with debounce
        scheduleProcessing()

        #if DEBUG
        print("[SyncQueue] Enqueued \(operation.type), queue size: \(pendingOperations.count)")
        #endif
    }

    /// Enqueue a sync with debouncing for rapid changes
    func enqueueDebouncedSync(priority: SyncOperation.Priority = .normal) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(config.debounceInterval * 1_000_000_000))
            if !Task.isCancelled {
                enqueue(SyncOperation(type: .pushOnly, priority: priority))
            }
        }
    }

    /// Immediately process the queue (skips debounce)
    func processNow() {
        debounceTask?.cancel()
        processingTask?.cancel()
        processingTask = Task {
            await processQueue()
        }
    }

    /// Update connection status
    func setConnectionStatus(_ connected: Bool) {
        let wasOffline = !isConnected
        isConnected = connected

        if wasOffline && connected && !pendingOperations.isEmpty {
            // Just came online with pending operations - process immediately
            processNow()
        }
    }

    /// Clear the queue (use with caution)
    func clearQueue() {
        pendingOperations.removeAll()
        processingTask?.cancel()
        debounceTask?.cancel()
    }

    /// Update configuration
    func updateConfig(_ newConfig: SyncQueueConfig) {
        config = newConfig
    }

    // MARK: - Optimistic Updates

    /// Record an optimistic update that will be rolled back on failure
    func recordOptimisticUpdate(operationId: UUID, previousState: AppData) {
        guard config.enableOptimisticUpdates else { return }
        pendingOptimisticUpdates[operationId] = previousState
    }

    /// Confirm an optimistic update succeeded
    func confirmOptimisticUpdate(operationId: UUID) {
        pendingOptimisticUpdates.removeValue(forKey: operationId)
    }

    /// Rollback an optimistic update
    func rollbackOptimisticUpdate(operationId: UUID) -> AppData? {
        return pendingOptimisticUpdates.removeValue(forKey: operationId)
    }

    // MARK: - Private Methods

    private func scheduleProcessing() {
        // Don't schedule if already processing
        guard processingTask == nil || processingTask?.isCancelled == true else { return }

        processingTask = Task {
            // Wait for debounce interval
            try? await Task.sleep(nanoseconds: UInt64(config.minSyncInterval * 1_000_000_000))
            if !Task.isCancelled {
                await processQueue()
            }
        }
    }

    private func processQueue() async {
        guard !pendingOperations.isEmpty else {
            isProcessing = false
            return
        }

        guard isConnected else {
            #if DEBUG
            print("[SyncQueue] Offline - deferring \(pendingOperations.count) operations")
            #endif
            isProcessing = false
            return
        }

        isProcessing = true

        // Double-check array is not empty (defensive - actor isolation should prevent races)
        guard !pendingOperations.isEmpty else {
            isProcessing = false
            return
        }

        // Take the highest priority operation atomically
        var operation = pendingOperations.removeFirst()
        operation.attemptCount += 1
        operation.lastAttemptAt = Date()

        #if DEBUG
        print("[SyncQueue] Processing \(operation.type), attempt \(operation.attemptCount)")
        #endif

        do {
            try await executeOperation(operation)

            // Success!
            lastSuccessfulSync = Date()
            consecutiveFailures = 0
            confirmOptimisticUpdate(operationId: operation.id)

            #if DEBUG
            print("[SyncQueue] Operation succeeded")
            #endif

        } catch {
            operation.lastError = error.localizedDescription
            consecutiveFailures += 1

            #if DEBUG
            print("[SyncQueue] Operation failed: \(error.localizedDescription)")
            #endif

            if operation.canRetry {
                // Re-queue with backoff
                pendingOperations.append(operation)

                // Wait for backoff delay before processing next
                let backoff = operation.backoffDelay
                #if DEBUG
                print("[SyncQueue] Will retry in \(backoff)s")
                #endif
                try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
            } else {
                // Max retries exceeded - rollback optimistic update if any
                if let previousState = rollbackOptimisticUpdate(operationId: operation.id) {
                    // Notify that rollback is needed
                    NotificationCenter.default.post(
                        name: .syncRollbackNeeded,
                        object: nil,
                        userInfo: ["previousState": previousState]
                    )
                }

                #if DEBUG
                print("[SyncQueue] Operation abandoned after \(operation.attemptCount) attempts")
                #endif
            }
        }

        isProcessing = false

        // Continue processing if more operations queued
        if !pendingOperations.isEmpty {
            scheduleProcessing()
        }
    }

    private func executeOperation(_ operation: SyncOperation) async throws {
        // This calls into SyncManager to do the actual work
        // The timeout is handled here to keep control in the queue

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(config.operationTimeout * 1_000_000_000))
            throw SyncQueueError.timeout
        }

        let syncTask = Task {
            try await performSync(operation)
        }

        // Race between sync and timeout
        do {
            try await syncTask.value
            timeoutTask.cancel()
        } catch is CancellationError {
            throw SyncQueueError.cancelled
        } catch {
            timeoutTask.cancel()
            throw error
        }
    }

    private func performSync(_ operation: SyncOperation) async throws {
        // Delegate to SyncManager for actual Firebase operations
        await SyncManager.shared.performQueuedSync(operation: operation)
    }
}

// MARK: - Sync Queue Errors

enum SyncQueueError: LocalizedError {
    case timeout
    case cancelled
    case offline
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Sync operation timed out"
        case .cancelled:
            return "Sync operation was cancelled"
        case .offline:
            return "Cannot sync while offline"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let syncRollbackNeeded = Notification.Name("syncRollbackNeeded")
    static let syncQueueHealthChanged = Notification.Name("syncQueueHealthChanged")
}

// MARK: - SyncManager Extension for Queue Integration

extension SyncManager {

    /// Called by SyncQueue to perform the actual sync operation
    func performQueuedSync(operation: SyncOperation) async {
        // Use the existing syncIfNeeded but with queue awareness
        await syncIfNeeded()
    }

    /// Enqueue a debounced sync (called by Repository)
    func enqueueDebouncedSync() {
        Task { @MainActor in
            SyncQueue.shared.enqueueDebouncedSync()
        }
    }
}
