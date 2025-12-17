# TinyWins Complete Refactoring Plan

## Document Overview

**Purpose:** Transform TinyWins from a functional but monolithic codebase into a maintainable, testable, and scalable architecture.

**Timeline:** 8-12 weeks (part-time) or 4-6 weeks (full-time)

**Risk Level:** Medium — Changes are incremental; app remains functional throughout

---

# Part 1: Current State Analysis

## 1.1 Codebase Metrics

| Category | Files | Lines of Code | Largest File |
|----------|-------|---------------|--------------|
| **ViewModels** | 1 | 1,979 | FamilyViewModel.swift |
| **Services** | 12 | 2,622 | Repository.swift (612) |
| **Models** | 14 | 2,302 | ProgressionSystem.swift (449) |
| **Views** | 32 | 18,500+ | ContentView.swift (1,934) |
| **Total** | ~60 | ~25,000 | — |

## 1.2 FamilyViewModel Responsibilities (The "God Object")

The single ViewModel currently handles **26 distinct domains**:

```
FamilyViewModel (1,979 lines)
├── Published State (12 @Published properties)
├── Cloud Backup State (4 @Published properties)
├── Progression System State (6 @Published properties)
├── Celebration State (4 structs + @Published)
├── Computed Properties (15+ computed vars)
├── Child Methods (145 lines)
├── Behavior Type Methods (34 lines)
├── Behavior Event Methods (173 lines)
├── Reward Methods (189 lines)
├── History Methods (118 lines)
├── Age-based Suggestions (16 lines)
├── Allowance Methods (16 lines)
├── Analytics & Insights (53 lines)
├── Timed Rewards Check (29 lines)
├── Allowance Settings (28 lines)
├── Parent Notes (11 lines)
├── Behavior Consistency (11 lines)
├── Agreement System (219 lines)
├── Insights Data (65 lines)
├── Activity Tracking (21 lines)
├── Daily Prompt (23 lines)
├── Bonus Star (23 lines)
├── Skill Badges (61 lines)
├── Special Moments (41 lines)
├── Parent Reinforcement Analytics (150 lines)
├── Yearly Summary (9 lines)
├── Kid Goal Options Generation (10 lines)
├── Data Export/Import (37 lines)
└── Cloud Backup Methods (6 lines)
```

## 1.3 View Complexity Analysis

**Files exceeding 500 lines (excessive for SwiftUI):**

| File | Lines | Primary Issues |
|------|-------|----------------|
| ContentView.swift | 1,934 | Onboarding, tab management, celebration handling, goal prompts all mixed |
| InsightsView.swift | 1,354 | Child insights + analytics calculations inline |
| RewardsView.swift | 1,287 | List, detail, editing, templates all in one |
| KidView.swift | 1,234 | Child-facing view with achievement calculations |
| LogBehaviorSheet.swift | 1,170 | Complex form with suggestions, interceptors |
| HistoryView.swift | 1,163 | Timeline + filtering + grouping logic |
| TodayView.swift | 1,116 | Main screen with coaching, banners, recap |
| ChildDetailView.swift | 929 | Parent view of child with multiple sections |

## 1.4 @AppStorage Scatter

17+ `@AppStorage` declarations spread across 6 files:

```
TodayView.swift (10)
├── hasSeenTodayCoachMarks
├── onboardingCompletedDate  
├── first48Day1Shown
├── first48Day2Shown
├── lastFirstPositiveBannerDate
├── lastWeeklyRecapDate
├── lastConsistencyBannerDate
├── lastReturnBannerDate
├── hasSeenGoalTooltip
└── (more...)

KidView.swift (1)
└── selectedThemeRaw

RewardsView.swift (1)
└── selectedRewardsChildId

LogBehaviorSheet.swift (1)
└── hasSeenGoalInterception

AppearanceSettingsView.swift (2)
├── appTheme
└── accentColorName

FeatureFlags.swift (2)
├── debugUnlockPlus
└── showDebugInfo
```

## 1.5 Dependency Graph (Current)

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ TodayView│ │ KidsView │ │RewardsView│ │InsightsView│     │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
│       │            │            │            │              │
│       └────────────┴─────┬──────┴────────────┘              │
│                          │                                   │
│                          ▼                                   │
│              ┌───────────────────────┐                      │
│              │   FamilyViewModel     │ ◄── God Object       │
│              │     (1,979 lines)     │                      │
│              └───────────┬───────────┘                      │
│                          │                                   │
│       ┌──────────────────┼──────────────────┐               │
│       │                  │                  │               │
│       ▼                  ▼                  ▼               │
│ ┌───────────┐    ┌───────────────┐   ┌───────────┐         │
│ │Repository │    │Singletons     │   │@AppStorage│         │
│ └─────┬─────┘    │.shared        │   │(scattered)│         │
│       │          └───────────────┘   └───────────┘         │
│       ▼                                                     │
│ ┌───────────┐                                              │
│ │SyncBackend│                                              │
│ └───────────┘                                              │
└─────────────────────────────────────────────────────────────┘
```

---

# Part 2: Target Architecture

## 2.1 Architecture Pattern: Feature-Based MVVM + Coordinator

```
┌─────────────────────────────────────────────────────────────────┐
│                           App Layer                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    AppCoordinator                        │    │
│  │  (Navigation, Tab State, Deep Links, Sheet Presentation) │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Today Module │    │  Kids Module  │    │ Rewards Module│
├───────────────┤    ├───────────────┤    ├───────────────┤
│ TodayView     │    │ KidsView      │    │ RewardsView   │
│ TodayViewModel│    │ ChildViewModel│    │ RewardsVM     │
└───────┬───────┘    └───────┬───────┘    └───────┬───────┘
        │                    │                     │
        └────────────────────┼─────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Domain Layer                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐             │
│  │ChildrenStore│ │BehaviorsStore│ │ RewardsStore │             │
│  └──────────────┘ └──────────────┘ └──────────────┘             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐             │
│  │InsightsStore │ │ProgressStore │ │SettingsStore│             │
│  └──────────────┘ └──────────────┘ └──────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                      Repository                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐             │
│  │ SyncBackend  │ │UserPrefsStore│ │ CloudBackup  │             │
│  └──────────────┘ └──────────────┘ └──────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

## 2.2 New File Structure

```
TinyWins/
├── App/
│   ├── TinyWinsApp.swift
│   ├── AppCoordinator.swift          # NEW: Navigation coordinator
│   └── DependencyContainer.swift     # NEW: DI container
│
├── Core/
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   └── View+Extensions.swift
│   ├── Utilities/
│   │   ├── DateFormatters.swift
│   │   └── Validators.swift
│   └── Protocols/
│       ├── Identifiable+Hashable.swift
│       └── Store.swift               # NEW: Base store protocol
│
├── Domain/
│   ├── Stores/                       # NEW: Feature-specific state
│   │   ├── ChildrenStore.swift
│   │   ├── BehaviorsStore.swift
│   │   ├── RewardsStore.swift
│   │   ├── InsightsStore.swift
│   │   ├── ProgressionStore.swift
│   │   ├── AgreementsStore.swift
│   │   └── CelebrationStore.swift
│   │
│   ├── UseCases/                     # NEW: Complex business logic
│   │   ├── LogBehaviorUseCase.swift
│   │   ├── RedeemRewardUseCase.swift
│   │   ├── CalculateInsightsUseCase.swift
│   │   └── CheckMilestonesUseCase.swift
│   │
│   └── Models/                       # MOVE: From Models/
│       ├── Child.swift
│       ├── BehaviorType.swift
│       ├── BehaviorEvent.swift
│       ├── Reward.swift
│       └── ... (other models)
│
├── Data/
│   ├── Repository/
│   │   ├── RepositoryProtocol.swift  # EXTRACT: From Repository.swift
│   │   └── Repository.swift
│   ├── Storage/
│   │   ├── SyncBackend.swift
│   │   ├── LocalSyncBackend.swift
│   │   └── DataStore.swift
│   ├── Preferences/
│   │   └── UserPreferencesStore.swift  # NEW: Centralized @AppStorage
│   └── Cloud/
│       ├── CloudBackupService.swift
│       └── AuthService.swift
│
├── Features/                         # NEW: Feature modules
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── TodayViewModel.swift      # NEW
│   │   ├── Components/
│   │   │   ├── TodaySummaryCard.swift
│   │   │   ├── QuickLogButton.swift
│   │   │   └── CoachingBanner.swift
│   │   └── TodayCoordinator.swift    # NEW: Optional
│   │
│   ├── Kids/
│   │   ├── KidsView.swift
│   │   ├── KidsViewModel.swift       # NEW
│   │   ├── ChildDetailView.swift
│   │   ├── ChildDetailViewModel.swift # NEW
│   │   ├── KidView.swift
│   │   ├── KidViewModel.swift        # NEW
│   │   └── AddEditChildView.swift
│   │
│   ├── Rewards/
│   │   ├── RewardsView.swift
│   │   ├── RewardsViewModel.swift    # NEW
│   │   ├── AddRewardView.swift
│   │   ├── RewardDetailView.swift    # EXTRACT
│   │   └── RewardTemplatePickerView.swift
│   │
│   ├── Insights/
│   │   ├── FamilyInsightsView.swift
│   │   ├── InsightsViewModel.swift   # NEW
│   │   ├── ChildInsightsView.swift
│   │   ├── ChildInsightsViewModel.swift # NEW
│   │   ├── HistoryView.swift
│   │   ├── HistoryViewModel.swift    # NEW
│   │   └── PremiumAnalyticsDashboard.swift
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── SettingsViewModel.swift   # NEW
│   │   ├── NotificationsSettingsView.swift
│   │   ├── BehaviorManagementView.swift
│   │   ├── BackupSettingsView.swift
│   │   └── AppearanceSettingsView.swift
│   │
│   ├── Onboarding/
│   │   ├── OnboardingFlowView.swift  # EXTRACT from ContentView
│   │   └── OnboardingViewModel.swift # NEW
│   │
│   └── LogBehavior/
│       ├── LogBehaviorSheet.swift
│       ├── LogBehaviorViewModel.swift # NEW
│       └── Components/
│           ├── BehaviorPicker.swift
│           ├── StarsPicker.swift
│           └── NoteEditor.swift
│
├── Shared/
│   ├── Components/
│   │   ├── DesignSystem.swift
│   │   ├── ChildAvatar.swift
│   │   ├── CelebrationOverlay.swift
│   │   ├── PlusPaywallView.swift
│   │   └── PlusUpsellCard.swift
│   └── Modifiers/
│       └── ... (view modifiers)
│
└── Services/
    ├── SubscriptionManager.swift
    ├── NotificationService.swift
    ├── CelebrationManager.swift
    ├── MediaManager.swift
    ├── AnalyticsService.swift
    └── FeatureFlags.swift
```

## 2.3 Dependency Injection Strategy

**Before (Singletons + Environment):**
```swift
// Scattered singleton access
let isPlus = SubscriptionManager.shared.effectiveIsPlusSubscriber
NotificationService.shared.scheduleDailyReminder()
```

**After (Explicit DI via Container):**
```swift
// DependencyContainer.swift
@MainActor
final class DependencyContainer: ObservableObject {
    // Stores (state containers)
    let childrenStore: ChildrenStore
    let behaviorsStore: BehaviorsStore
    let rewardsStore: RewardsStore
    let insightsStore: InsightsStore
    let progressionStore: ProgressionStore
    let celebrationStore: CelebrationStore
    
    // Services
    let subscriptionManager: SubscriptionManager
    let notificationService: NotificationService
    let cloudBackupService: CloudBackupService
    
    // Preferences
    let userPreferences: UserPreferencesStore
    
    // Repository
    let repository: RepositoryProtocol
    
    init(backend: SyncBackend = LocalSyncBackend()) {
        // Initialize in dependency order
        self.repository = Repository(backend: backend)
        self.userPreferences = UserPreferencesStore()
        
        // Initialize stores with repository
        self.childrenStore = ChildrenStore(repository: repository)
        self.behaviorsStore = BehaviorsStore(repository: repository)
        self.rewardsStore = RewardsStore(repository: repository)
        self.insightsStore = InsightsStore(repository: repository)
        self.progressionStore = ProgressionStore(repository: repository)
        self.celebrationStore = CelebrationStore()
        
        // Initialize services
        self.subscriptionManager = SubscriptionManager()
        self.notificationService = NotificationService()
        self.cloudBackupService = CloudBackupService(repository: repository)
    }
}

// Usage in App
@main
struct TinyWinsApp: App {
    @StateObject private var container = DependencyContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(container.childrenStore)
                .environmentObject(container.rewardsStore)
                // ... inject what's needed
        }
    }
}
```

---

# Part 3: Phased Implementation Plan

## Phase 0: Preparation (1-2 days)

### 0.1 Create Safety Net

```
Tasks:
□ Create Git branch: refactor/architecture-v2
□ Add comprehensive UI tests for critical flows
□ Document current behavior with screenshots
□ Create regression test checklist
```

### 0.2 Set Up New Structure

```
Tasks:
□ Create folder structure (empty files OK)
□ Add DependencyContainer.swift (skeleton)
□ Add Store.swift protocol
□ Add AppCoordinator.swift (skeleton)
```

---

## Phase 1: Extract UserPreferencesStore (2-3 days)

**Goal:** Centralize all @AppStorage into one observable store.

**Risk:** Low — Non-breaking, additive change

### 1.1 Create UserPreferencesStore

```swift
// Data/Preferences/UserPreferencesStore.swift

import SwiftUI

@MainActor
final class UserPreferencesStore: ObservableObject {
    
    // MARK: - Onboarding & First-Time Experience
    
    @AppStorage("hasCompletedOnboarding") 
    var hasCompletedOnboarding: Bool = false
    
    @AppStorage("onboardingCompletedDate") 
    private var onboardingCompletedDateString: String = ""
    
    var onboardingCompletedDate: Date? {
        get {
            guard !onboardingCompletedDateString.isEmpty else { return nil }
            return Self.dateFormatter.date(from: onboardingCompletedDateString)
        }
        set {
            if let date = newValue {
                onboardingCompletedDateString = Self.dateFormatter.string(from: date)
            } else {
                onboardingCompletedDateString = ""
            }
        }
    }
    
    // MARK: - Coach Marks & Tooltips
    
    @AppStorage("hasSeenTodayCoachMarks") 
    var hasSeenTodayCoachMarks: Bool = false
    
    @AppStorage("first48Day1Shown") 
    var first48Day1Shown: Bool = false
    
    @AppStorage("first48Day2Shown") 
    var first48Day2Shown: Bool = false
    
    @AppStorage("hasSeenGoalTooltip") 
    var hasSeenGoalTooltip: Bool = false
    
    @AppStorage("hasSeenGoalInterception") 
    var hasSeenGoalInterception: Bool = false
    
    // MARK: - Banner Tracking
    
    @AppStorage("lastFirstPositiveBannerDate") 
    private var lastFirstPositiveBannerDateString: String = ""
    
    @AppStorage("lastWeeklyRecapDate") 
    private var lastWeeklyRecapDateString: String = ""
    
    @AppStorage("lastConsistencyBannerDate") 
    private var lastConsistencyBannerDateString: String = ""
    
    @AppStorage("lastReturnBannerDate") 
    private var lastReturnBannerDateString: String = ""
    
    // Computed date accessors
    var lastFirstPositiveBannerDate: Date? {
        get { Self.dateFormatter.date(from: lastFirstPositiveBannerDateString) }
        set { lastFirstPositiveBannerDateString = newValue.map { Self.dateFormatter.string(from: $0) } ?? "" }
    }
    
    // ... similar for other dates
    
    // MARK: - Appearance
    
    @AppStorage("appTheme") 
    var appTheme: AppTheme = .calm
    
    @AppStorage("accentColorName") 
    var accentColorName: String = "blue"
    
    // MARK: - Selection State
    
    @AppStorage("selectedRewardsChildId") 
    var selectedRewardsChildId: String = ""
    
    @AppStorage("selectedKidTheme") 
    var selectedKidTheme: String = "default"
    
    // MARK: - Debug
    
    #if DEBUG
    @AppStorage("debug.unlockPlus") 
    var debugUnlockPlus: Bool = false
    
    @AppStorage("debug.showDebugInfo") 
    var showDebugInfo: Bool = false
    #endif
    
    // MARK: - Helpers
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    // MARK: - Reset Methods
    
    func resetAllCoachMarks() {
        hasSeenTodayCoachMarks = false
        first48Day1Shown = false
        first48Day2Shown = false
        hasSeenGoalTooltip = false
        hasSeenGoalInterception = false
    }
    
    func resetAllBannerDates() {
        lastFirstPositiveBannerDateString = ""
        lastWeeklyRecapDateString = ""
        lastConsistencyBannerDateString = ""
        lastReturnBannerDateString = ""
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        onboardingCompletedDateString = ""
        resetAllCoachMarks()
    }
}
```

### 1.2 Migration Steps

```
Tasks:
□ Create UserPreferencesStore.swift
□ Add to DependencyContainer
□ Inject into TinyWinsApp via .environmentObject()
□ Update TodayView to use @EnvironmentObject var prefs: UserPreferencesStore
□ Update KidView to use prefs
□ Update RewardsView to use prefs
□ Update LogBehaviorSheet to use prefs
□ Update AppearanceSettingsView to use prefs
□ Update FeatureFlags to delegate to prefs (DEBUG only)
□ Remove old @AppStorage declarations from views
□ Test: Verify all persistence still works
□ Test: Verify reset functions work
```

### 1.3 Verification

```swift
// Add to SettingsView for testing
#if DEBUG
Button("Reset All Coach Marks") {
    prefs.resetAllCoachMarks()
}
Button("Reset Onboarding") {
    prefs.resetOnboarding()
}
#endif
```

---

## Phase 2: Extract ChildrenStore (3-4 days)

**Goal:** Move child-related state and logic out of FamilyViewModel.

**Risk:** Medium — Touches core data flow

### 2.1 Create ChildrenStore

```swift
// Domain/Stores/ChildrenStore.swift

import Foundation
import Combine

@MainActor
final class ChildrenStore: ObservableObject {
    
    // MARK: - Dependencies
    
    private let repository: RepositoryProtocol
    
    // MARK: - Published State
    
    @Published private(set) var children: [Child] = []
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    var activeChildren: [Child] {
        children.filter { !$0.isArchived }
    }
    
    var archivedChildren: [Child] {
        children.filter { $0.isArchived }
    }
    
    var hasChildren: Bool {
        !children.isEmpty
    }
    
    // MARK: - Initialization
    
    init(repository: RepositoryProtocol) {
        self.repository = repository
        loadChildren()
    }
    
    // MARK: - CRUD Operations
    
    func loadChildren() {
        children = repository.getChildren()
    }
    
    func child(id: UUID) -> Child? {
        children.first { $0.id == id }
    }
    
    func addChild(_ child: Child) {
        repository.addChild(child)
        loadChildren()
    }
    
    func updateChild(_ child: Child) {
        repository.updateChild(child)
        loadChildren()
    }
    
    func deleteChild(id: UUID) {
        repository.deleteChild(id: id)
        loadChildren()
    }
    
    func archiveChild(id: UUID) {
        guard var child = child(id: id) else { return }
        child.isArchived = true
        child.archivedDate = Date()
        updateChild(child)
    }
    
    func unarchiveChild(id: UUID) {
        guard var child = child(id: id) else { return }
        child.isArchived = false
        child.archivedDate = nil
        updateChild(child)
    }
    
    // MARK: - Child Queries
    
    func stars(forChild childId: UUID, from events: [BehaviorEvent]) -> Int {
        events
            .filter { $0.childId == childId }
            .reduce(0) { $0 + $1.pointsApplied }
    }
    
    func childAge(_ child: Child) -> Int? {
        guard let birthDate = child.birthDate else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
}
```

### 2.2 Migration Steps

```
Tasks:
□ Create ChildrenStore.swift
□ Add to DependencyContainer
□ Update FamilyViewModel to delegate to ChildrenStore internally
□ Add bridge computed property: var children: [Child] { childrenStore.children }
□ Test: Add child flow
□ Test: Edit child flow
□ Test: Archive/unarchive child
□ Update KidsView to use ChildrenStore directly (optional - can defer)
□ Update AddEditChildView to use ChildrenStore (optional)
```

### 2.3 Bridge Pattern (Temporary)

During migration, FamilyViewModel can delegate to the new store:

```swift
// In FamilyViewModel
private let childrenStore: ChildrenStore

// Computed property for backwards compatibility
var children: [Child] { childrenStore.children }

// Delegate methods
func addChild(_ child: Child) {
    childrenStore.addChild(child)
}
```

---

## Phase 3: Extract BehaviorsStore (3-4 days)

**Goal:** Move behavior types and events to dedicated store.

### 3.1 Create BehaviorsStore

```swift
// Domain/Stores/BehaviorsStore.swift

@MainActor
final class BehaviorsStore: ObservableObject {
    
    private let repository: RepositoryProtocol
    
    @Published private(set) var behaviorTypes: [BehaviorType] = []
    @Published private(set) var behaviorEvents: [BehaviorEvent] = []
    
    // MARK: - Computed
    
    var activeBehaviorTypes: [BehaviorType] {
        behaviorTypes.filter { $0.isActive }
    }
    
    var todayEvents: [BehaviorEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return behaviorEvents.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }
    
    func events(forChild childId: UUID) -> [BehaviorEvent] {
        behaviorEvents.filter { $0.childId == childId }
    }
    
    func todayEvents(forChild childId: UUID) -> [BehaviorEvent] {
        todayEvents.filter { $0.childId == childId }
    }
    
    // MARK: - Behavior Types CRUD
    
    func behaviorType(id: UUID) -> BehaviorType? {
        behaviorTypes.first { $0.id == id }
    }
    
    func addBehaviorType(_ type: BehaviorType) {
        repository.addBehaviorType(type)
        reload()
    }
    
    func updateBehaviorType(_ type: BehaviorType) {
        repository.updateBehaviorType(type)
        reload()
    }
    
    func deleteBehaviorType(id: UUID) {
        repository.deleteBehaviorType(id: id)
        reload()
    }
    
    // MARK: - Events CRUD
    
    func addEvent(_ event: BehaviorEvent) {
        repository.addBehaviorEvent(event)
        reload()
    }
    
    func updateEvent(_ event: BehaviorEvent) {
        repository.updateBehaviorEvent(event)
        reload()
    }
    
    func deleteEvent(id: UUID) {
        repository.deleteBehaviorEvent(id: id)
        reload()
    }
    
    // MARK: - Suggestions
    
    func suggestedBehaviors(forChild child: Child, recentEvents: [BehaviorEvent]) -> [BehaviorType] {
        // Extract suggestion logic from FamilyViewModel
        // ...
    }
    
    private func reload() {
        behaviorTypes = repository.getBehaviorTypes()
        behaviorEvents = repository.getBehaviorEvents()
    }
}
```

### 3.2 Migration Steps

```
Tasks:
□ Create BehaviorsStore.swift
□ Move suggestion logic from FamilyViewModel
□ Add to DependencyContainer
□ Bridge in FamilyViewModel
□ Test: Log behavior flow
□ Test: Edit behavior type
□ Test: Suggestions appear correctly
□ Test: Today events compute correctly
```

---

## Phase 4: Extract RewardsStore (3-4 days)

**Goal:** Move rewards/goals state and logic.

### 4.1 Create RewardsStore

```swift
// Domain/Stores/RewardsStore.swift

@MainActor
final class RewardsStore: ObservableObject {
    
    private let repository: RepositoryProtocol
    
    @Published private(set) var rewards: [Reward] = []
    @Published private(set) var rewardHistory: [RewardHistoryEvent] = []
    
    // MARK: - Queries
    
    func rewards(forChild childId: UUID) -> [Reward] {
        rewards.filter { $0.childId == childId }
    }
    
    func activeRewards(forChild childId: UUID) -> [Reward] {
        rewards(forChild: childId).filter { !$0.isRedeemed }
    }
    
    func currentGoal(forChild childId: UUID) -> Reward? {
        activeRewards(forChild: childId)
            .sorted { $0.priority < $1.priority }
            .first
    }
    
    func progress(for reward: Reward, currentStars: Int) -> Double {
        guard reward.targetPoints > 0 else { return 0 }
        return min(1.0, Double(currentStars) / Double(reward.targetPoints))
    }
    
    // MARK: - CRUD
    
    func addReward(_ reward: Reward) {
        repository.addReward(reward)
        reload()
    }
    
    func updateReward(_ reward: Reward) {
        repository.updateReward(reward)
        reload()
    }
    
    func deleteReward(id: UUID) {
        repository.deleteReward(id: id)
        reload()
    }
    
    func redeemReward(_ reward: Reward) {
        var updated = reward
        updated.isRedeemed = true
        updated.redeemedDate = Date()
        updateReward(updated)
        
        // Record history
        let historyEvent = RewardHistoryEvent(
            childId: reward.childId,
            rewardName: reward.name,
            targetPoints: reward.targetPoints,
            redeemedDate: Date()
        )
        repository.addRewardHistoryEvent(historyEvent)
        reload()
    }
    
    private func reload() {
        rewards = repository.getRewards()
        rewardHistory = repository.getRewardHistoryEvents()
    }
}
```

---

## Phase 5: Extract InsightsStore (4-5 days)

**Goal:** Move analytics calculations out of views and ViewModel.

### 5.1 Create InsightsStore

```swift
// Domain/Stores/InsightsStore.swift

@MainActor
final class InsightsStore: ObservableObject {
    
    private let repository: RepositoryProtocol
    
    @Published private(set) var familyInsights: FamilyInsightsData?
    @Published private(set) var childInsights: [UUID: ChildInsightsData] = [:]
    @Published private(set) var isCalculating: Bool = false
    
    // MARK: - Calculate Family Insights
    
    func calculateFamilyInsights(
        children: [Child],
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        period: InsightsPeriod
    ) {
        isCalculating = true
        
        // Move calculation logic from InsightsView
        let dateRange = period.dateRange
        let filteredEvents = events.filter { dateRange.contains($0.timestamp) }
        
        let insights = FamilyInsightsData(
            totalMoments: filteredEvents.count,
            positiveMoments: filteredEvents.filter { $0.pointsApplied > 0 }.count,
            challengeMoments: filteredEvents.filter { $0.pointsApplied < 0 }.count,
            mostActiveChild: calculateMostActiveChild(events: filteredEvents, children: children),
            topBehavior: calculateTopBehavior(events: filteredEvents, types: behaviorTypes),
            activityByDay: calculateActivityByDay(events: filteredEvents),
            activityByHour: calculateActivityByHour(events: filteredEvents)
        )
        
        self.familyInsights = insights
        isCalculating = false
    }
    
    func calculateChildInsights(
        childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType],
        period: InsightsPeriod
    ) {
        // Similar calculation for single child
    }
    
    // MARK: - Calculation Helpers
    
    private func calculateMostActiveChild(events: [BehaviorEvent], children: [Child]) -> Child? {
        let counts = Dictionary(grouping: events, by: { $0.childId })
            .mapValues { $0.count }
        
        guard let maxChildId = counts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        return children.first { $0.id == maxChildId }
    }
    
    // ... other calculation methods
}

// Supporting types
struct FamilyInsightsData {
    let totalMoments: Int
    let positiveMoments: Int
    let challengeMoments: Int
    let mostActiveChild: Child?
    let topBehavior: BehaviorType?
    let activityByDay: [DayActivity]
    let activityByHour: [HourActivity]
}

enum InsightsPeriod: String, CaseIterable {
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    
    var dateRange: ClosedRange<Date> {
        // Calculate date range
    }
}
```

---

## Phase 6: Extract ProgressionStore (3-4 days)

**Goal:** Move badges, milestones, and parent activity tracking.

### 6.1 Create ProgressionStore

```swift
// Domain/Stores/ProgressionStore.swift

@MainActor
final class ProgressionStore: ObservableObject {
    
    private let repository: RepositoryProtocol
    
    @Published private(set) var parentActivity: ParentActivity = ParentActivity()
    @Published private(set) var skillBadges: [SkillBadge] = []
    @Published private(set) var specialMoments: [SpecialMoment] = []
    
    // MARK: - Parent Activity
    
    func recordActivity() {
        parentActivity.recordActivity()
        saveParentActivity()
    }
    
    var activeDaysThisWeek: Int {
        parentActivity.activeDaysThisWeek
    }
    
    var activityStatus: ActivityStatus {
        parentActivity.activityStatus
    }
    
    var coachLevel: CoachLevel {
        parentActivity.coachLevel
    }
    
    // MARK: - Badges
    
    func badges(forChild childId: UUID) -> [SkillBadge] {
        skillBadges.filter { $0.childId == childId }
    }
    
    func checkAndAwardBadges(
        forChild childId: UUID,
        events: [BehaviorEvent],
        behaviorTypes: [BehaviorType]
    ) {
        // Move badge logic from FamilyViewModel
    }
    
    // MARK: - Milestones
    
    func checkForMilestone(
        childId: UUID,
        childName: String,
        currentStars: Int,
        reward: Reward?
    ) -> MilestoneCelebration? {
        // Move milestone logic
    }
    
    // MARK: - Persistence
    
    private func saveParentActivity() {
        if let data = try? JSONEncoder().encode(parentActivity) {
            UserDefaults.standard.set(data, forKey: "parentActivity")
        }
    }
    
    private func loadParentActivity() {
        if let data = UserDefaults.standard.data(forKey: "parentActivity"),
           let activity = try? JSONDecoder().decode(ParentActivity.self, from: data) {
            parentActivity = activity
        }
    }
}
```

---

## Phase 7: Create Feature ViewModels (5-7 days)

**Goal:** Give each major view its own ViewModel.

### 7.1 TodayViewModel

```swift
// Features/Today/TodayViewModel.swift

@MainActor
final class TodayViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let childrenStore: ChildrenStore
    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore
    private let progressionStore: ProgressionStore
    private let preferences: UserPreferencesStore
    
    // MARK: - Local State
    
    @Published var selectedChildForLogging: Child?
    @Published var showingCoachMarks: Bool = false
    @Published var showingFirst48Coaching: Bool = false
    @Published var first48Message: (title: String, message: String)?
    
    // Banner states
    @Published var showingFirstPositiveBanner: Bool = false
    @Published var showingWeeklyRecap: Bool = false
    @Published var showingConsistencyBanner: Bool = false
    @Published var showingReturnBanner: Bool = false
    
    // MARK: - Computed
    
    var activeChildren: [Child] {
        childrenStore.activeChildren
    }
    
    var todayEvents: [BehaviorEvent] {
        behaviorsStore.todayEvents
    }
    
    var hasMomentsToday: Bool {
        !todayEvents.isEmpty
    }
    
    // MARK: - First 48 Hours Logic
    
    var isInFirst48Hours: Bool {
        guard let completedDate = preferences.onboardingCompletedDate else { return false }
        let hoursSince = Date().timeIntervalSince(completedDate) / 3600
        return hoursSince <= 48
    }
    
    var first48DayNumber: Int {
        guard let completedDate = preferences.onboardingCompletedDate else { return 0 }
        let daysSince = Calendar.current.dateComponents([.day], from: completedDate, to: Date()).day ?? 0
        return daysSince + 1
    }
    
    func checkFirst48Coaching() {
        guard isInFirst48Hours else { return }
        
        if first48DayNumber == 1 && !preferences.first48Day1Shown {
            first48Message = (
                title: "Your first day!",
                message: "Just try noticing one good moment today."
            )
            withAnimation { showingFirst48Coaching = true }
            preferences.first48Day1Shown = true
        } else if first48DayNumber == 2 && !preferences.first48Day2Shown {
            first48Message = (
                title: "Day 2—you're building a habit!",
                message: "Keep going. Small wins really do add up."
            )
            withAnimation { showingFirst48Coaching = true }
            preferences.first48Day2Shown = true
        }
    }
    
    // ... other methods moved from TodayView
}
```

### 7.2 RewardsViewModel

```swift
// Features/Rewards/RewardsViewModel.swift

@MainActor
final class RewardsViewModel: ObservableObject {
    
    private let childrenStore: ChildrenStore
    private let rewardsStore: RewardsStore
    private let behaviorsStore: BehaviorsStore
    private let subscriptionManager: SubscriptionManager
    
    @Published var selectedChildId: UUID?
    @Published var showingAddReward: Bool = false
    @Published var editingReward: Reward?
    @Published var showingPaywall: Bool = false
    
    // MARK: - Computed
    
    var activeChildren: [Child] {
        childrenStore.activeChildren
    }
    
    var selectedChild: Child? {
        guard let id = selectedChildId else { return nil }
        return childrenStore.child(id: id)
    }
    
    var rewardsForSelectedChild: [Reward] {
        guard let id = selectedChildId else { return [] }
        return rewardsStore.rewards(forChild: id)
    }
    
    var currentGoal: Reward? {
        guard let id = selectedChildId else { return nil }
        return rewardsStore.currentGoal(forChild: id)
    }
    
    var currentStars: Int {
        guard let id = selectedChildId else { return 0 }
        let events = behaviorsStore.events(forChild: id)
        return events.reduce(0) { $0 + $1.pointsApplied }
    }
    
    // MARK: - Actions
    
    func selectChild(_ child: Child) {
        selectedChildId = child.id
    }
    
    func addReward(_ reward: Reward) {
        // Check limits
        let currentCount = rewardsStore.activeRewards(forChild: reward.childId).count
        guard subscriptionManager.canAddActiveGoal(currentActiveCount: currentCount) else {
            showingPaywall = true
            return
        }
        
        rewardsStore.addReward(reward)
    }
    
    func redeemReward(_ reward: Reward) {
        rewardsStore.redeemReward(reward)
    }
}
```

### 7.3 Additional ViewModels

Create similar ViewModels for:
- `InsightsViewModel`
- `ChildInsightsViewModel`
- `HistoryViewModel`
- `LogBehaviorViewModel`
- `SettingsViewModel`
- `OnboardingViewModel`

---

## Phase 8: Create Use Cases (4-5 days)

**Goal:** Extract complex cross-store operations.

### 8.1 LogBehaviorUseCase

```swift
// Domain/UseCases/LogBehaviorUseCase.swift

@MainActor
final class LogBehaviorUseCase {
    
    private let behaviorsStore: BehaviorsStore
    private let rewardsStore: RewardsStore
    private let progressionStore: ProgressionStore
    private let childrenStore: ChildrenStore
    private let celebrationStore: CelebrationStore
    
    struct Input {
        let childId: UUID
        let behaviorTypeId: UUID
        let pointsApplied: Int
        let note: String?
        let mediaUrls: [String]
    }
    
    struct Output {
        let event: BehaviorEvent
        let newStarTotal: Int
        let earnedBadge: SkillBadge?
        let milestone: MilestoneCelebration?
        let goalReached: Bool
    }
    
    func execute(_ input: Input) -> Output {
        // 1. Create and save event
        let event = BehaviorEvent(
            childId: input.childId,
            behaviorTypeId: input.behaviorTypeId,
            pointsApplied: input.pointsApplied,
            note: input.note,
            mediaUrls: input.mediaUrls
        )
        behaviorsStore.addEvent(event)
        
        // 2. Update parent activity
        if input.pointsApplied > 0 {
            progressionStore.recordActivity()
        }
        
        // 3. Calculate new star total
        let allEvents = behaviorsStore.events(forChild: input.childId)
        let newTotal = allEvents.reduce(0) { $0 + $1.pointsApplied }
        
        // 4. Check for badges
        let earnedBadge = progressionStore.checkAndAwardBadges(
            forChild: input.childId,
            events: allEvents,
            behaviorTypes: behaviorsStore.behaviorTypes
        )
        
        // 5. Check for milestones
        let childName = childrenStore.child(id: input.childId)?.name ?? ""
        let currentGoal = rewardsStore.currentGoal(forChild: input.childId)
        let milestone = progressionStore.checkForMilestone(
            childId: input.childId,
            childName: childName,
            currentStars: newTotal,
            reward: currentGoal
        )
        
        // 6. Check if goal reached
        var goalReached = false
        if let goal = currentGoal, newTotal >= goal.targetPoints {
            goalReached = true
            celebrationStore.queueGoalReachedCelebration(
                childId: input.childId,
                childName: childName,
                reward: goal
            )
        }
        
        return Output(
            event: event,
            newStarTotal: newTotal,
            earnedBadge: earnedBadge,
            milestone: milestone,
            goalReached: goalReached
        )
    }
}
```

### 8.2 Additional Use Cases

- `RedeemRewardUseCase` — handles redemption, history, next goal prompt
- `CalculateInsightsUseCase` — complex analytics calculations
- `ExportDataUseCase` — backup export logic
- `RestoreDataUseCase` — backup restore with validation

---

## Phase 9: Implement AppCoordinator (3-4 days)

**Goal:** Centralize navigation logic.

### 9.1 Create AppCoordinator

```swift
// App/AppCoordinator.swift

@MainActor
final class AppCoordinator: ObservableObject {
    
    // MARK: - Navigation State
    
    @Published var selectedTab: Tab = .today
    @Published var navigationPath = NavigationPath()
    
    // Sheet presentations
    @Published var presentedSheet: Sheet?
    @Published var presentedFullScreenCover: FullScreenCover?
    
    // Alert
    @Published var alertItem: AlertItem?
    
    // MARK: - Tab Enum
    
    enum Tab: String, CaseIterable {
        case today
        case kids
        case rewards
        case insights
        case more
        
        var title: String {
            switch self {
            case .today: return "Today"
            case .kids: return "Kids"
            case .rewards: return "Goals"
            case .insights: return "Insights"
            case .more: return "More"
            }
        }
        
        var icon: String {
            switch self {
            case .today: return "star.fill"
            case .kids: return "figure.2.and.child.holdinghands"
            case .rewards: return "gift.fill"
            case .insights: return "chart.bar.fill"
            case .more: return "ellipsis"
            }
        }
    }
    
    // MARK: - Sheet Enum
    
    enum Sheet: Identifiable {
        case logBehavior(child: Child)
        case addChild
        case editChild(Child)
        case addReward(childId: UUID)
        case editReward(Reward)
        case settings
        case notifications
        case feedback
        
        var id: String {
            switch self {
            case .logBehavior(let child): return "log-\(child.id)"
            case .addChild: return "add-child"
            case .editChild(let child): return "edit-\(child.id)"
            case .addReward(let id): return "add-reward-\(id)"
            case .editReward(let reward): return "edit-reward-\(reward.id)"
            case .settings: return "settings"
            case .notifications: return "notifications"
            case .feedback: return "feedback"
            }
        }
    }
    
    // MARK: - Full Screen Cover Enum
    
    enum FullScreenCover: Identifiable {
        case onboarding
        case kidView(Child)
        case paywall(source: String)
        case celebration(CelebrationData)
        
        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .kidView(let child): return "kid-\(child.id)"
            case .paywall(let source): return "paywall-\(source)"
            case .celebration(let data): return "celebration-\(data.id)"
            }
        }
    }
    
    // MARK: - Navigation Actions
    
    func showTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func showLogBehavior(for child: Child) {
        presentedSheet = .logBehavior(child: child)
    }
    
    func showAddChild() {
        presentedSheet = .addChild
    }
    
    func showEditChild(_ child: Child) {
        presentedSheet = .editChild(child)
    }
    
    func showKidView(_ child: Child) {
        presentedFullScreenCover = .kidView(child)
    }
    
    func showPaywall(source: String) {
        presentedFullScreenCover = .paywall(source: source)
    }
    
    func showCelebration(_ data: CelebrationData) {
        presentedFullScreenCover = .celebration(data)
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    // MARK: - Deep Links
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }
        
        switch host {
        case "child":
            if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idString) {
                // Navigate to child
            }
        case "reward":
            // Handle reward deep link
            break
        default:
            break
        }
    }
}
```

### 9.2 Update ContentView to Use Coordinator

```swift
// Features/Today/ContentView.swift (simplified)

struct ContentView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var preferences: UserPreferencesStore
    
    var body: some View {
        Group {
            if preferences.hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingFlowView()
            }
        }
        .sheet(item: $coordinator.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { cover in
            fullScreenContent(for: cover)
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "star.fill") }
                .tag(AppCoordinator.Tab.today)
            
            KidsView()
                .tabItem { Label("Kids", systemImage: "figure.2.and.child.holdinghands") }
                .tag(AppCoordinator.Tab.kids)
            
            RewardsView()
                .tabItem { Label("Goals", systemImage: "gift.fill") }
                .tag(AppCoordinator.Tab.rewards)
            
            FamilyInsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(AppCoordinator.Tab.insights)
            
            SettingsView()
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(AppCoordinator.Tab.more)
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: AppCoordinator.Sheet) -> some View {
        switch sheet {
        case .logBehavior(let child):
            LogBehaviorSheet(child: child)
        case .addChild:
            AddEditChildView(child: nil)
        // ... other cases
        }
    }
}
```

---

## Phase 10: Deprecate FamilyViewModel (2-3 days)

**Goal:** Remove the God Object once all stores are working.

### 10.1 Final Migration

```
Tasks:
□ Verify all stores are fully functional
□ Update any remaining views using FamilyViewModel
□ Remove bridge properties from FamilyViewModel
□ Delete FamilyViewModel.swift
□ Update DependencyContainer to not include FamilyViewModel
□ Full regression test
```

### 10.2 FamilyViewModel Replacement Map

| FamilyViewModel Property/Method | New Location |
|--------------------------------|--------------|
| `children`, `addChild()`, etc. | ChildrenStore |
| `behaviorTypes`, `behaviorEvents` | BehaviorsStore |
| `rewards`, `addReward()`, etc. | RewardsStore |
| `parentActivity`, `skillBadges` | ProgressionStore |
| `agreementVersions` | AgreementsStore |
| `recentMilestone`, celebrations | CelebrationStore |
| Analytics methods | InsightsStore |
| Cloud backup state | CloudBackupService |
| `hasCompletedOnboarding` | UserPreferencesStore |

---

# Part 4: Testing Strategy

## 4.1 Unit Tests for Stores

```swift
// Tests/Stores/ChildrenStoreTests.swift

@MainActor
final class ChildrenStoreTests: XCTestCase {
    
    var sut: ChildrenStore!
    var mockRepository: MockRepository!
    
    override func setUp() async throws {
        mockRepository = MockRepository()
        sut = ChildrenStore(repository: mockRepository)
    }
    
    func test_addChild_savesToRepository() {
        let child = Child(name: "Test")
        
        sut.addChild(child)
        
        XCTAssertEqual(mockRepository.addChildCallCount, 1)
        XCTAssertEqual(sut.children.count, 1)
    }
    
    func test_activeChildren_excludesArchived() {
        let active = Child(name: "Active")
        var archived = Child(name: "Archived")
        archived.isArchived = true
        
        mockRepository.mockChildren = [active, archived]
        sut.loadChildren()
        
        XCTAssertEqual(sut.activeChildren.count, 1)
        XCTAssertEqual(sut.activeChildren.first?.name, "Active")
    }
}
```

## 4.2 Integration Tests

```swift
// Tests/Integration/LogBehaviorFlowTests.swift

@MainActor
final class LogBehaviorFlowTests: XCTestCase {
    
    var container: DependencyContainer!
    
    override func setUp() async throws {
        container = DependencyContainer(backend: LocalSyncBackend.inMemory)
    }
    
    func test_logPositiveBehavior_updatesStarsAndChecksMilestones() async {
        // Setup
        let child = Child(name: "Test")
        container.childrenStore.addChild(child)
        
        let behavior = BehaviorType(name: "Helped", defaultPoints: 1)
        container.behaviorsStore.addBehaviorType(behavior)
        
        let reward = Reward(childId: child.id, name: "Ice Cream", targetPoints: 5)
        container.rewardsStore.addReward(reward)
        
        // Execute
        let useCase = LogBehaviorUseCase(/* dependencies */)
        let result = useCase.execute(LogBehaviorUseCase.Input(
            childId: child.id,
            behaviorTypeId: behavior.id,
            pointsApplied: 1,
            note: nil,
            mediaUrls: []
        ))
        
        // Verify
        XCTAssertEqual(result.newStarTotal, 1)
        XCTAssertFalse(result.goalReached)
    }
}
```

## 4.3 UI Tests

```swift
// UITests/TodayViewUITests.swift

final class TodayViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }
    
    func test_logBehavior_showsToast() {
        // Navigate and tap log button
        app.buttons["Log Moment"].tap()
        
        // Select behavior
        app.buttons["Helped with chores"].tap()
        
        // Confirm
        app.buttons["Save"].tap()
        
        // Verify toast
        XCTAssertTrue(app.staticTexts["Moment logged!"].waitForExistence(timeout: 2))
    }
}
```

---

# Part 5: Risk Mitigation

## 5.1 Rollback Strategy

Each phase should be a separate PR that can be reverted independently:

```
main
  └── PR #1: UserPreferencesStore (can revert cleanly)
      └── PR #2: ChildrenStore (can revert cleanly)
          └── PR #3: BehaviorsStore (can revert cleanly)
              └── ... and so on
```

## 5.2 Feature Flags for Gradual Rollout

```swift
// FeatureFlags.swift

extension FeatureFlags {
    @AppStorage("useNewStores") var useNewStores: Bool = false
    @AppStorage("useNewNavigation") var useNewNavigation: Bool = false
}

// Usage
if FeatureFlags.shared.useNewStores {
    // Use new ChildrenStore
} else {
    // Use legacy FamilyViewModel
}
```

## 5.3 Monitoring Checklist

After each phase:

```
□ App launches without crash
□ Onboarding flow works
□ Add child works
□ Log behavior works
□ Add goal works
□ Redeem goal works
□ Insights load correctly
□ Settings persist across launches
□ Cloud backup works (if applicable)
□ No memory leaks (Instruments check)
□ Performance acceptable (< 100ms for common operations)
```

---

# Part 6: Timeline Summary

| Phase | Description | Duration | Risk |
|-------|-------------|----------|------|
| 0 | Preparation | 1-2 days | Low |
| 1 | UserPreferencesStore | 2-3 days | Low |
| 2 | ChildrenStore | 3-4 days | Medium |
| 3 | BehaviorsStore | 3-4 days | Medium |
| 4 | RewardsStore | 3-4 days | Medium |
| 5 | InsightsStore | 4-5 days | Medium |
| 6 | ProgressionStore | 3-4 days | Medium |
| 7 | Feature ViewModels | 5-7 days | Medium |
| 8 | Use Cases | 4-5 days | Low |
| 9 | AppCoordinator | 3-4 days | Medium |
| 10 | Deprecate FamilyViewModel | 2-3 days | High |

**Total: 34-45 working days**

---

# Part 7: Success Criteria

## 7.1 Quantitative Goals

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Largest file | 1,979 lines | < 400 lines | ✓ |
| @AppStorage locations | 6 files | 1 file | ✓ |
| ViewModels | 1 | 8-10 | ✓ |
| Test coverage | ~0% | > 60% | ✓ |
| Build time | baseline | < +10% | ✓ |

## 7.2 Qualitative Goals

- [ ] New developer can understand feature in < 30 minutes
- [ ] Adding new feature touches < 5 files
- [ ] Bug fixes are isolated to single module
- [ ] Unit tests can run without UI
- [ ] Views are < 300 lines, mostly declarative

---

# Appendix A: Code Templates

## A.1 Store Template

```swift
// Domain/Stores/[Feature]Store.swift

import Foundation
import Combine

@MainActor
final class [Feature]Store: ObservableObject {
    
    // MARK: - Dependencies
    
    private let repository: RepositoryProtocol
    
    // MARK: - Published State
    
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    // MARK: - Initialization
    
    init(repository: RepositoryProtocol) {
        self.repository = repository
        load()
    }
    
    // MARK: - Public Methods
    
    func load() {
        // Load from repository
    }
    
    func add(_ item: Item) {
        // Add and reload
    }
    
    func update(_ item: Item) {
        // Update and reload
    }
    
    func delete(id: UUID) {
        // Delete and reload
    }
}
```

## A.2 ViewModel Template

```swift
// Features/[Feature]/[Feature]ViewModel.swift

import Foundation
import Combine

@MainActor
final class [Feature]ViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let store: [Feature]Store
    private let coordinator: AppCoordinator
    
    // MARK: - Published State
    
    @Published var selectedItem: Item?
    @Published var isEditing: Bool = false
    
    // MARK: - Computed Properties
    
    var items: [Item] {
        store.items
    }
    
    // MARK: - Initialization
    
    init(store: [Feature]Store, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }
    
    // MARK: - Actions
    
    func select(_ item: Item) {
        selectedItem = item
    }
    
    func save() {
        guard let item = selectedItem else { return }
        store.update(item)
        isEditing = false
    }
}
```

---

# Appendix B: Migration Checklist

Use this checklist for each store extraction:

```
## [StoreName] Migration Checklist

### Setup
- [ ] Create [StoreName].swift file
- [ ] Add to DependencyContainer
- [ ] Add @EnvironmentObject injection to App

### Migrate State
- [ ] Move @Published properties from FamilyViewModel
- [ ] Move computed properties
- [ ] Update property access modifiers

### Migrate Methods
- [ ] Move CRUD methods
- [ ] Move query methods
- [ ] Move business logic methods

### Update References
- [ ] Update Views to use new store
- [ ] Add bridge in FamilyViewModel (temporary)
- [ ] Update any singletons that referenced old code

### Testing
- [ ] Write unit tests for store
- [ ] Manual test: Create flow
- [ ] Manual test: Read/list flow
- [ ] Manual test: Update flow
- [ ] Manual test: Delete flow

### Cleanup
- [ ] Remove bridge from FamilyViewModel
- [ ] Remove old code from FamilyViewModel
- [ ] Update documentation
```

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**Author:** Architecture Review Panel
