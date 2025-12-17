import Foundation

// DEPRECATED: iCloud Backup feature has been removed from TinyWins.
// This file is kept as a stub to avoid Xcode project issues.
// All iCloud backup functionality is disabled.

@MainActor
final class CloudBackupService: ObservableObject {

    // MARK: - Singleton

    static let shared = CloudBackupService()

    // MARK: - Published State (stub properties)

    @Published private(set) var lastBackupDate: Date?
    @Published private(set) var isBusy = false
    @Published private(set) var lastError: String?
    @Published private(set) var iCloudAvailable = false

    // MARK: - Initialization

    private init() {
        // Stub initialization - no functionality
    }

    // MARK: - Public Interface (stub methods)

    func refreshICloudStatus() async {
        // Stub - always unavailable
        iCloudAvailable = false
    }

    func backup(appData: AppData) async throws {
        // Stub - throw error
        throw CloudBackupError.iCloudNotAvailable
    }

    func restore() async throws -> AppData {
        // Stub - throw error
        throw CloudBackupError.iCloudNotAvailable
    }

    func getBackupInfo() async -> BackupInfo? {
        // Stub - always return nil
        return nil
    }
}

// MARK: - Backup Info (stub)

struct BackupInfo {
    let date: Date?
    let appVersion: String?

    var formattedDate: String {
        return "Unknown"
    }
}

// MARK: - Errors

enum CloudBackupError: LocalizedError {
    case iCloudNotAvailable
    case backupFailed(Error)
    case restoreFailed(Error)
    case noBackupFound

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud backup is not available."
        case .backupFailed:
            return "Could not back up your data."
        case .restoreFailed:
            return "Could not restore your data."
        case .noBackupFound:
            return "No backup was found."
        }
    }
}
