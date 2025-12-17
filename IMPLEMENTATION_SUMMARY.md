# TinyWins Backend Foundation Layer

## Summary

This iteration introduces a clean backend foundation layer that supports:
- **Local-only mode** (current behavior, unchanged)
- **Future Firebase mode** via SyncBackend + AuthService abstractions

No user-visible behavior has changed. The app still uses local JSON persistence.

---

## Files Summary

| File | Status | Purpose |
|------|--------|---------|
| `Services/SyncBackend.swift` | **NEW** | SyncBackend protocol + LocalSyncBackend implementation |
| `Services/AuthService.swift` | **NEW** | AuthService protocol + AuthUser model + LocalAuthService stub |
| `Services/BackendModeDetector.swift` | **NEW** | Helper for detecting/creating backend components |
| `Services/Repository.swift` | **MODIFIED** | Refactored to use SyncBackend instead of DataStore directly |
| `App/TinyWinsApp.swift` | **MODIFIED** | Composition root with explicit dependency creation |
| `ViewModels/FamilyViewModel+Preview.swift` | **NEW** | Preview helpers using new backend architecture |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     TinyWinsApp (Composition Root)              │
│                                                                 │
│  ┌─────────────────┐  ┌──────────────────┐                     │
│  │  AuthService    │  │   SyncBackend    │                     │
│  │  (protocol)     │  │   (protocol)     │                     │
│  │       │         │  │        │         │                     │
│  │       ▼         │  │        ▼         │                     │
│  │ LocalAuthService│  │ LocalSyncBackend │                     │
│  │ (stub - no auth)│  │ (JSON file)      │                     │
│  └─────────────────┘  └────────┬─────────┘                     │
│                                │                               │
│                                ▼                               │
│                       ┌────────────────┐                       │
│                       │   Repository   │                       │
│                       │ (uses backend) │                       │
│                       └────────┬───────┘                       │
│                                │                               │
│                                ▼                               │
│                       ┌────────────────┐                       │
│                       │FamilyViewModel │                       │
│                       └────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Synchronous SyncBackend API

The SyncBackend protocol uses synchronous methods (`throws` rather than `async throws`) to match the existing DataStore behavior and avoid breaking changes to Repository's internal flow.

```swift
protocol SyncBackend {
    func loadAppData() throws -> AppData?
    func saveAppData(_ data: AppData) throws
    func clearAllData() throws
}
```

**Rationale**: Repository expects synchronous persistence. Future Firebase backends can use internal async handling with semaphores or completion handlers when needed.

### 2. LocalSyncBackend Wraps DataStore

LocalSyncBackend delegates to the existing DataStoreProtocol:

```swift
final class LocalSyncBackend: SyncBackend {
    private let dataStore: DataStoreProtocol
    
    func loadAppData() throws -> AppData? {
        try dataStore.load()
    }
    // ...
}
```

**Rationale**: Reuses existing, tested persistence code. No duplication.

### 3. Repository Backward Compatibility

Repository maintains backward compatibility:

```swift
// New primary initializer
init(backend: SyncBackend)

// Convenience initializer (existing behavior)
convenience init() {
    self.init(backend: LocalSyncBackend())
}

// Deprecated but still works
@available(*, deprecated)
convenience init(dataStore: DataStoreProtocol)
```

**Rationale**: Existing call sites like `Repository()` continue to work without modification.

### 4. AuthService is a Stub

LocalAuthService always reports `currentUser == nil` and throws errors on sign-in attempts:

```swift
func signInWithApple() async throws {
    throw AuthError.notAvailable
}
```

**Rationale**: Provides a clean interface for views to check auth state without breaking when Firebase isn't available.

### 5. TinyWinsApp as Composition Root

All dependencies are created explicitly in TinyWinsApp:

```swift
let auth = LocalAuthService()
let backend = BackendModeDetector.createSyncBackend()
let repository = Repository(backend: backend)
let viewModel = FamilyViewModel(repository: repository)
```

**Rationale**: Makes the dependency graph explicit and easy to modify for future Firebase integration.

---

## Verification Checklist

After applying these changes, verify:

- [ ] App builds without Firebase SDKs installed
- [ ] App runs normally with all existing features
- [ ] Children can be added/edited/deleted
- [ ] Behaviors can be logged
- [ ] Rewards work correctly
- [ ] Insights display properly
- [ ] iCloud backup (CloudBackupService) still works
- [ ] Plus subscription features work
- [ ] Factory reset clears all data
- [ ] Console shows "LocalSyncBackend" and "LocalAuthService" logs

---

## Next Steps

After this foundation is verified, the next iteration will implement:

1. **FirebaseAuthService** - Apple/Google Sign-In via Firebase Auth
2. **FirebaseSyncBackend** - Firestore storage for AppData
3. **AccountSettingsSection** - Sign-in/sign-out UI
4. **Mode switching** - Automatic backend selection based on auth state

The foundation layer makes these additions straightforward without modifying existing code.

---

## Console Output Example

When the app starts, you should see:

```
═══════════════════════════════════════
TinyWins Backend Mode: Local Only
═══════════════════════════════════════
Firebase SDK available: false
Mode description: Data stored locally on this device only
═══════════════════════════════════════
[Auth] Using LocalAuthService (no sign-in available yet)
[Backend] Creating LocalSyncBackend
[Backend] Initialized LocalSyncBackend (Firebase not yet implemented)
[Repository] Initialized with LocalSyncBackend
[Repository] Loaded 2 children, 15 events
[App] Composition root initialized
```
