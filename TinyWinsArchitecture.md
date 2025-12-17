# TinyWins Architecture Documentation

**Last Updated:** December 2024
**Version:** Post-Refactor (FamilyViewModel Removed)

---

## Table of Contents

1. [Overview of the Refactor (Old vs New)](#overview-of-the-refactor-old-vs-new)
2. [Benefits of the Refactor](#benefits-of-the-refactor)
3. [High-Level Architecture](#high-level-architecture)
4. [Files by Folder](#files-by-folder)

---

## Overview of the Refactor (Old vs New)

### The Old Architecture: A Single Brain Running Everything

**Technical Explanation:**

Before the refactor, TinyWins used a monolithic architecture centered around a single "god object" called `FamilyViewModel`. This 1,979-line file was responsible for:
- Managing all application state (children, behaviors, rewards, insights, celebrations)
- Containing all business logic (logging behaviors, redeeming rewards, calculating analytics)
- Directly accessing the Repository and multiple services
- Holding 20+ `@Published` properties that views subscribed to
- Managing cloud backup, progression tracking, agreements, allowances, and more

Views were tightly coupled to this single ViewModel through `@EnvironmentObject`, and many views also scattered `@AppStorage` declarations throughout (17+ preferences spread across 6 files). There was no clear separation between features, making it difficult to:
- Test individual features in isolation
- Understand where specific logic lived
- Make changes without risking side effects
- Onboard new developers
- Navigate programmatically (navigation state was scattered)

**Non-Technical Explanation (Product/PM Perspective):**

Imagine your family's brain as a single person trying to remember and manage everything at once:
- What each child has done today
- All the rewards they're working toward
- Every behavior rule for every child
- The weekly analytics and insights
- Cloud backups and syncing
- Special celebrations and achievements
- Allowance tracking
- Family agreements

This "one brain" approach worked when the family was small, but as TinyWins grew more features, this single brain became overloaded. It was like having one person running a restaurant's kitchen, managing the cash register, greeting customers, AND doing the books—all at the same time.

**Result:** Any time you wanted to add a new feature or fix a bug, you risked breaking something else because everything was interconnected in one massive file.

---

### The New Architecture: Specialized Teams Working Together

**Technical Explanation:**

The refactored architecture follows a **feature-based, layered MVVM architecture** with clear separation of concerns:

1. **Domain Stores** (7 focused stores replacing the god object):
   - `ChildrenStore` - Child entity management
   - `BehaviorsStore` - Behavior types and events
   - `RewardsStore` - Rewards and reward history
   - `InsightsStore` - Analytics calculations
   - `ProgressionStore` - Progression system, goals, streaks
   - `AgreementsStore` - Family agreement system
   - `CelebrationStore` - Celebration state and triggers

2. **Feature ViewModels** (10+ specialized ViewModels):
   - `ContentViewModel` - Navigation and cross-cutting concerns
   - `TodayViewModel` - Today screen specific logic
   - `KidsViewModel` - Kids list management
   - `KidViewModel` - Individual child view (kid-facing)
   - `ChildDetailViewModel` - Child detail view (parent-facing)
   - `RewardsViewModel` - Rewards management
   - `InsightsViewModel` / `HistoryViewModel` - Analytics
   - `SettingsViewModel` - App settings
   - `LogBehaviorViewModel` - Behavior logging flow
   - `OnboardingViewModel` - Onboarding flow

3. **Use Cases** (2 core transaction coordinators):
   - `LogBehaviorUseCase` - Coordinates logging a behavior across stores
   - `RedeemRewardUseCase` - Coordinates reward redemption

4. **Centralized Infrastructure**:
   - `AppCoordinator` - Centralized navigation state
   - `DependencyContainer` - Single source of dependency injection
   - `UserPreferencesStore` - Centralized app preferences (no more scattered @AppStorage)

5. **Clean Dependency Flow**:
   ```
   Views → Feature ViewModels → Domain Stores → Repository → SyncBackend
   ```

**Non-Technical Explanation (Product/PM Perspective):**

Now imagine your family's brain as a well-organized team:
- **The Children Team** knows everything about each child
- **The Behaviors Team** tracks what happened and when
- **The Rewards Team** manages goals and achievements
- **The Insights Team** analyzes patterns and provides coaching
- **The Progression Team** tracks streaks and milestones
- **The Celebrations Team** knows when to celebrate
- **The Agreements Team** manages family rules

Each team has one specific job and does it well. When you want to log a behavior, the **Behavior Coordinator** talks to the right teams in the right order. When you need insights, you only ask the **Insights Team**—you don't have to wake up the whole family.

**Navigation** is now handled by a single **Coordinator** who decides what screen to show when, instead of each view trying to navigate on its own.

**Result:** Adding a new feature or fixing a bug is now safer and faster because each team (store/ViewModel) is focused and isolated. Changes to rewards don't accidentally break insights. New engineers can quickly understand what each file does.

---

## Benefits of the Refactor

### Technical Benefits

#### 1. **Testability**
- **Before:** Testing required mocking the entire FamilyViewModel with all 26 responsibilities
- **After:** Each store and ViewModel can be tested in isolation with minimal dependencies
- **Impact:** Unit tests can now be written for individual features (e.g., test LogBehaviorUseCase without loading the entire app state)

#### 2. **Separation of Concerns**
- **Before:** Business logic, UI logic, and data access were mixed in FamilyViewModel and large views
- **After:** Clear layers—Views handle UI, ViewModels handle presentation logic, Stores handle domain logic, Repository handles data
- **Impact:** Bugs are easier to locate and fix because each layer has a single responsibility

#### 3. **Dependency Injection**
- **Before:** Direct instantiation and singletons (`shared`) scattered throughout
- **After:** DependencyContainer provides all dependencies; everything flows through clean initializers
- **Impact:** Easy to swap implementations (e.g., swap Repository for tests, swap stores for preview data)

#### 4. **Reduced Coupling**
- **Before:** Views directly depended on FamilyViewModel; changing one part often broke others
- **After:** Views depend on focused interfaces (e.g., TodayView only needs TodayViewModel + stores)
- **Impact:** Parallel development is safer—multiple engineers can work on different features simultaneously

#### 5. **Navigation Control**
- **Before:** Navigation state scattered across views using `@State` and `@Binding`
- **After:** Centralized in AppCoordinator with clear navigation paths
- **Impact:** Deep linking, flow changes, and navigation debugging are now straightforward

#### 6. **Performance Improvements**
- **Before:** Any change to FamilyViewModel triggered re-renders across all subscribed views
- **After:** Views only subscribe to the stores/ViewModels they need; changes are scoped
- **Impact:** Fewer unnecessary re-renders, better app performance

#### 7. **Code Organization**
- **Before:** 1,979-line FamilyViewModel, 1,934-line ContentView
- **After:** Focused files averaging 100-300 lines, easy to navigate
- **Impact:** Faster code reviews, easier to find relevant code

---

### Non-Technical / Product and Team Benefits

#### 1. **Faster Feature Development**
**Before:** Adding a new reward type meant navigating through 1,979 lines of FamilyViewModel, understanding all the interconnected logic, and hoping your change didn't break insights or celebrations.

**After:** Adding a new reward type means updating RewardsStore (focused on rewards), RewardsViewModel (focused on rewards UI), and RewardsView. If it's a new type of celebration, you update CelebrationStore. Changes are scoped and predictable.

**Impact for PM:** Feature development velocity increases. An experiment like "add a new type of streak" or "try a different insights algorithm" becomes a same-day task instead of a multi-day investigation.

---

#### 2. **Lower Risk of Regressions**
**Before:** Changing how rewards are calculated could accidentally break how insights are displayed because they both lived in the same file and shared state.

**After:** Rewards logic lives in RewardsStore, insights logic lives in InsightsStore. They communicate through well-defined interfaces.

**Impact for PM:** You can ship faster with more confidence. AB testing a new feature in one area (e.g., trying a new onboarding flow) won't accidentally affect a different area (e.g., reward calculations).

---

#### 3. **Easier Onboarding for New Engineers**
**Before:** A new engineer or contractor had to understand the entire FamilyViewModel (1,979 lines) before they could safely make changes.

**After:** A new engineer can focus on one domain. "You're working on the Kids feature? Start with KidsViewModel and ChildrenStore—ignore the rest." They can become productive on day one.

**Impact for PM:** Hiring contractors for specific features (e.g., "improve insights") is now viable. You can point them to InsightsStore and InsightsViewModel and they can work independently.

---

#### 4. **Better Collaboration**
**Before:** Multiple engineers couldn't work on different features simultaneously without constant merge conflicts in FamilyViewModel.

**After:** One engineer works on RewardsViewModel, another on TodayViewModel, another on InsightsStore—minimal conflicts.

**Impact for PM:** You can parallelize work. Sprint planning becomes easier because you can assign features to different people without worrying about blocking.

---

#### 5. **Clearer Product Boundaries**
**Before:** It wasn't always clear where a feature's logic lived. Allowance logic was spread across views and FamilyViewModel.

**After:** Each feature has a clear home. Allowance logic? Check AllowanceView and the allowance methods in BehaviorsStore. Celebrations? Check CelebrationStore.

**Impact for PM:** When you need to understand how a feature works (for a sales demo, support ticket, or product spec), you know exactly where to look.

---

#### 6. **Easier Experimentation**
**Before:** Testing a new progression algorithm meant modifying the core FamilyViewModel and risking breaking live features.

**After:** Inject a new implementation of ProgressionStore for a subset of users. The rest of the app doesn't care.

**Impact for PM:** You can run experiments safely. Want to try a new reward algorithm for 10% of users? Easy. Want to test a different insights approach? Swap out InsightsStore for a test group.

---

#### 7. **Future-Proof for Platform Expansion**
**Before:** Adding an iPad-specific view or a Mac Catalyst version would require untangling UI from business logic.

**After:** Business logic is in stores; UI is in views. The same stores can power iOS, iPad, Mac, and even a hypothetical watchOS widget.

**Impact for PM:** Platform expansion becomes feasible. If you decide to build a "TinyWins for iPad with split views" or "TinyWins widgets," the hard work (domain logic) is already done and platform-agnostic.

---

## High-Level Architecture

### Architectural Layers

The TinyWins architecture is organized into five main layers:

```
┌─────────────────────────────────────────────────────────────┐
│                      App Layer                              │
│  (Entry point, dependency injection, navigation)            │
│                                                             │
│  • TinyWinsApp                                              │
│  • AppCoordinator (centralized navigation state)            │
│  • ContentViewModel (cross-cutting UI coordination)         │
│  • DependencyContainer (dependency injection)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Features Layer                           │
│  (Feature-specific presentation logic)                      │
│                                                             │
│  • TodayViewModel           • InsightsViewModel             │
│  • KidsViewModel            • HistoryViewModel              │
│  • KidViewModel             • SettingsViewModel             │
│  • ChildDetailViewModel     • OnboardingViewModel           │
│  • RewardsViewModel         • LogBehaviorViewModel          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                             │
│  (Business logic, domain state, use cases)                  │
│                                                             │
│  Stores (State Owners):                                     │
│  • ChildrenStore            • ProgressionStore              │
│  • BehaviorsStore           • AgreementsStore               │
│  • RewardsStore             • CelebrationStore              │
│  • InsightsStore                                            │
│                                                             │
│  Use Cases (Transaction Coordinators):                      │
│  • LogBehaviorUseCase                                       │
│  • RedeemRewardUseCase                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                              │
│  (Persistence, sync, preferences)                           │
│                                                             │
│  • Repository (data access facade)                          │
│  • SyncBackend (local JSON / future cloud)                  │
│  • UserPreferencesStore (centralized @AppStorage)           │
│  • CloudBackupService (iCloud backups)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Services Layer                           │
│  (Cross-cutting infrastructure)                             │
│                                                             │
│  • AnalyticsService         • MediaManager                  │
│  • NotificationService      • CelebrationManager            │
│  • SubscriptionManager      • FeatureFlags                  │
└─────────────────────────────────────────────────────────────┘
```

### Views Layer (Not Shown Above)

SwiftUI views organized by feature:
```
Views/
├── Today/          (Main screen, content coordination)
├── Kids/           (Child management, kid-facing views)
├── Rewards/        (Reward management, templates)
├── Insights/       (Analytics, history, reports)
├── Settings/       (App settings, backups, preferences)
└── Components/     (Reusable UI components, design system)
```

---

### State Ownership Model

**Who Owns What:**

| Layer | State Ownership | Business Logic | UI Logic |
|-------|----------------|----------------|----------|
| **Views** | Transient UI state only (`@State` for local UI) | ❌ None | ✅ Presentation |
| **Feature ViewModels** | Presentation state (`@Published`) | ✅ Presentation logic | ✅ UI coordination |
| **Domain Stores** | Domain state (`@Published`) | ✅ Core business logic | ❌ None |
| **Use Cases** | ❌ Stateless | ✅ Transaction coordination | ❌ None |
| **Repository** | ❌ Pass-through | ❌ None (data access only) | ❌ None |

**Data Flow:**

1. **User Action** → View triggers action (button tap, etc.)
2. **View** → Calls method on Feature ViewModel
3. **Feature ViewModel** → Orchestrates calls to Domain Stores or Use Cases
4. **Domain Stores / Use Cases** → Update domain state, call Repository
5. **Repository** → Persists data via SyncBackend
6. **State Updates** → `@Published` properties notify subscribers
7. **Views Re-render** → SwiftUI automatically updates UI

**Example: Logging a Behavior**

```
[User taps "Good Listening" in LogBehaviorSheet]
                │
                ▼
       LogBehaviorSheet (View)
                │
                ▼
       Calls logBehaviorUseCase.execute()
                │
                ▼
       LogBehaviorUseCase (Use Case)
                │
                ├─► BehaviorsStore.addBehaviorEvent()
                ├─► ChildrenStore.updatePoints()
                ├─► RewardsStore.checkForRewardCompletion()
                ├─► ProgressionStore.updateStreak()
                └─► CelebrationStore.triggerCelebration()
                │
                ▼
       Each store updates Repository
                │
                ▼
       Repository.save() → SyncBackend
                │
                ▼
       Stores publish state changes (@Published)
                │
                ▼
       Views re-render with new state
```

---

## Files by Folder

This section documents every Swift file in the project, grouped by folder. Each entry includes:
- **Technical purpose:** What the file does in technical terms
- **Non-technical purpose:** What it represents from a product/user perspective
- **Key interactions:** Which other types it depends on or collaborates with

---

### App/

#### TinyWinsApp.swift
- **Technical purpose:** SwiftUI app entry point. Initializes DependencyContainer and injects environment objects into the root ContentView. Sets up the app-level window group and handles app lifecycle.
- **Non-technical purpose:** The "on switch" for the entire app. When you launch TinyWins, this is what starts everything up and makes sure all the pieces are connected.
- **Key interactions:**
  - Creates `DependencyContainer` (which builds all stores, ViewModels, use cases)
  - Injects environment objects into `ContentView`
  - Uses `@UIApplicationDelegateAdaptor` for app delegate lifecycle

#### AppCoordinator.swift
- **Technical purpose:** Centralized navigation state manager. Holds `@Published` properties for navigation paths, sheet presentation, alerts, and deep linking. Provides methods to navigate between features programmatically.
- **Non-technical purpose:** The "traffic controller" that decides what screen you see. When you tap a child in the Kids list, the coordinator says "show the detail view." When you complete onboarding, it says "show the main app."
- **Key interactions:**
  - Used by `ContentViewModel` for navigation logic
  - Observed by views for presentation state (sheets, navigation)
  - No direct dependency on domain stores (delegates to ViewModels)

#### DependencyContainer.swift
- **Technical purpose:** Dependency injection container. Responsible for instantiating all stores, ViewModels, use cases, and services in the correct dependency order. Provides a single source of truth for object graph construction.
- **Non-technical purpose:** The "assembly line" that builds all the app's pieces in the right order. It makes sure the Rewards Team has access to the Repository before it starts working, and that the Today screen has all the teams it needs.
- **Key interactions:**
  - Creates `Repository`, `SyncBackend`, `UserPreferencesStore`
  - Creates all 7 domain stores
  - Creates all feature ViewModels
  - Creates use cases
  - Injected into `TinyWinsApp` at startup

---

### Features/

#### ContentViewModel.swift
- **Technical purpose:** Root-level ViewModel coordinating cross-cutting concerns. Handles celebration state, reward earned notifications, and provides methods for dismissing overlays. Acts as a bridge between AppCoordinator and domain stores.
- **Non-technical purpose:** The "main conductor" who makes sure celebrations happen at the right time and that the app shows the right banners or overlays when big moments happen (like earning a reward).
- **Key interactions:**
  - Depends on: `CelebrationStore`, `ChildrenStore`
  - Used by: `ContentView`, `AppCoordinator`
  - Provides methods: `dismissRewardEarnedCelebration()`, `checkForBonusInsight()`

---

#### Features/Today/

##### TodayViewModel.swift
- **Technical purpose:** Presentation logic for the Today screen. Manages selected child filter, provides daily coaching tips, checks for repair patterns, determines banner visibility (first positive, weekly recap, etc.). Encapsulates all Today-specific UI logic.
- **Non-technical purpose:** The "Today screen's brain." Decides what coaching message to show, whether to show a "good job" banner after the first positive moment, and which child is currently selected.
- **Key interactions:**
  - Depends on: `ProgressionStore`, `BehaviorsStore`, `ChildrenStore`, `RewardsStore`, `UserPreferencesStore`
  - Used by: `TodayView`, `ContentView`
  - Provides: `selectedChild`, `todayCoachingTip`, `showFirstPositiveBanner`, etc.

---

#### Features/Kids/

##### KidsViewModel.swift
- **Technical purpose:** Presentation logic for the Kids list screen. Manages child selection, handles adding/editing children, provides sorted lists of active children. Coordinates with SubscriptionManager for feature gating.
- **Non-technical purpose:** The "Kids list screen's brain." Knows which kids to show, whether you can add more (based on subscription), and handles when you tap to add or edit a child.
- **Key interactions:**
  - Depends on: `ChildrenStore`, `SubscriptionManager`
  - Used by: `KidsView`
  - Provides: `activeChildren`, `canAddChild()`

##### KidViewModel.swift
- **Technical purpose:** Presentation logic for the kid-facing child view (KidView). Manages theme selection, displays points and active rewards, provides kid-friendly messages based on progress. Separate from ChildDetailViewModel which is parent-facing.
- **Non-technical purpose:** The "kid's screen brain." When a child logs in and sees their rewards and progress, this decides what to show in a fun, kid-friendly way.
- **Key interactions:**
  - Depends on: `RewardsStore`, `BehaviorsStore`, `UserPreferencesStore`
  - Used by: `KidView`
  - Provides: `selectedTheme`, `activeRewardForChild()`, `kidFriendlyMessage()`

##### ChildDetailViewModel.swift
- **Technical purpose:** Presentation logic for the parent-facing child detail view (ChildDetailView). Manages tab selection (Overview, Kid View, Agreement, Insights), provides suggestions for improvement, coordinates reward creation.
- **Non-technical purpose:** The "parent view of a child's brain." When you tap a child's name to see all their details, agreements, insights, this decides what tabs to show and what suggestions to offer.
- **Key interactions:**
  - Depends on: `ChildrenStore`, `BehaviorsStore`, `RewardsStore`, `InsightsStore`, `ProgressionStore`
  - Used by: `ChildDetailView`
  - Provides: `selectedTab`, `improvementSuggestions`, `canCreateReward()`

---

#### Features/Rewards/

##### RewardsViewModel.swift
- **Technical purpose:** Presentation logic for rewards management. Handles child filtering, reward template selection, reward creation flow, reward redemption coordination, and reward history tracking.
- **Non-technical purpose:** The "rewards screen brain." Knows which rewards each child has, helps you pick reward templates, and handles when a reward is earned and needs to be celebrated.
- **Key interactions:**
  - Depends on: `ChildrenStore`, `RewardsStore`, `BehaviorsStore`, `UserPreferencesStore`, `SubscriptionManager`
  - Used by: `RewardsView`, `AddRewardView`
  - Provides: `selectedChild`, `availableTemplates`, `createReward()`, `redeemReward()`

---

#### Features/Insights/

##### InsightsViewModel.swift
- **Technical purpose:** Presentation logic for family-level insights (FamilyInsightsView). Manages time period selection, child filtering for insights, provides weekly summaries and pattern detection.
- **Non-technical purpose:** The "family insights brain." Decides what analytics and patterns to show for the whole family or a specific child over different time periods.
- **Key interactions:**
  - Depends on: `InsightsStore`, `BehaviorsStore`, `ChildrenStore`
  - Used by: `FamilyInsightsView`
  - Provides: `selectedPeriod`, `familySummary()`, `topBehaviors()`

##### ChildInsightsViewModel.swift
- **Technical purpose:** Presentation logic for individual child insights (ChildInsightsView). Provides child-specific analytics, improvement suggestions, streak information, and goal progress.
- **Non-technical purpose:** The "single child insights brain." When you view insights for just one child, this decides what to highlight—their strengths, patterns, what's working well.
- **Key interactions:**
  - Depends on: `InsightsStore`, `BehaviorsStore`, `RewardsStore`, `ProgressionStore`
  - Used by: `ChildInsightsView`
  - Provides: `childInsightsData()`, `improvementSuggestions()`, `streakInfo()`

##### HistoryViewModel.swift
- **Technical purpose:** Presentation logic for history/timeline view. Manages time range filtering (today, week, month), type filtering (all moments, positive, challenges, rewards), child filtering, and aggregates behavior events and reward history into a unified timeline.
- **Non-technical purpose:** The "timeline brain." When you want to see everything that happened today or this week, this decides what to show and how to filter it.
- **Key interactions:**
  - Depends on: `BehaviorsStore`, `RewardsStore`, `ChildrenStore`, `UserPreferencesStore`
  - Used by: `HistoryView`
  - Provides: `historyItems()`, `selectedTimeFilter`, `selectedChildId`

##### HistoryModels.swift
- **Technical purpose:** Data models for history display. Defines `HistoryItem` enum (behavior or reward), `HistoryTypeFilter`, `TimePeriod` for filtering.
- **Non-technical purpose:** The "definitions for history types." These are the types of events you can see in the timeline (behaviors vs. rewards) and the time periods you can filter by.
- **Key interactions:**
  - Used by: `HistoryViewModel`, `HistoryView`

---

#### Features/Settings/

##### SettingsViewModel.swift
- **Technical purpose:** Presentation logic for settings screen. Coordinates subscription management, backup triggers, behavior management, appearance settings, and feedback flows.
- **Non-technical purpose:** The "settings screen brain." Handles what options you see, whether backup is available, and coordinates when you change themes or manage behaviors.
- **Key interactions:**
  - Depends on: `UserPreferencesStore`, `SubscriptionManager`, `CloudBackupService`
  - Used by: `SettingsView`
  - Provides: `isPlusSubscriber`, `triggerBackup()`, `appVersion()`

---

#### Features/LogBehavior/

##### LogBehaviorViewModel.swift
- **Technical purpose:** Presentation logic for the behavior logging flow (LogBehaviorSheet). Manages behavior selection, note entry, media attachments, reward selection, and coordinates with LogBehaviorUseCase to execute the transaction.
- **Non-technical purpose:** The "log behavior screen brain." When you're adding a star or a challenge, this handles picking the behavior, adding a note, choosing which reward it goes toward.
- **Key interactions:**
  - Depends on: `BehaviorsStore`, `RewardsStore`, `LogBehaviorUseCase`
  - Used by: `LogBehaviorSheet`
  - Provides: `suggestedBehaviors()`, `availableRewards()`, `logBehavior()`

---

#### Features/Onboarding/

##### OnboardingViewModel.swift
- **Technical purpose:** Presentation logic for onboarding flow. Manages onboarding steps (welcome, add child, create first behaviors, set first reward), tracks completion state, and updates UserPreferencesStore when onboarding is done.
- **Non-technical purpose:** The "welcome flow brain." When you first open TinyWins, this guides you through setting up your family, adding a child, creating behaviors, and setting a first reward.
- **Key interactions:**
  - Depends on: `ChildrenStore`, `BehaviorsStore`, `RewardsStore`, `UserPreferencesStore`, `Repository`
  - Used by: Onboarding views (not explicitly named in file list, possibly embedded in ContentView)
  - Provides: `currentStep`, `completeOnboarding()`, `addFirstChild()`

---

### Domain/Stores/

#### ChildrenStore.swift
- **Technical purpose:** Domain store managing child entities. Owns `@Published var children: [Child]`. Provides methods to add, update, delete, archive children. Handles point updates and child lookups. Backed by Repository.
- **Non-technical purpose:** The "children team." Knows everything about each child—their name, age, points, archived status. If you want to add a child or update their points, you ask this team.
- **Key interactions:**
  - Depends on: `RepositoryProtocol`
  - Used by: All feature ViewModels, use cases
  - Provides: `children`, `activeChildren`, `child(id:)`, `updatePoints()`, `addChild()`, `deleteChild()`

#### BehaviorsStore.swift
- **Technical purpose:** Domain store managing behavior types and behavior events. Owns `@Published var behaviorTypes: [BehaviorType]` and `@Published var behaviorEvents: [BehaviorEvent]`. Provides methods to add/edit/delete behavior types, log behavior events, calculate allowance earnings, track today's events, and suggest behaviors based on age and category.
- **Non-technical purpose:** The "behaviors team." Knows all the rules (behavior types like "Good Listening") and everything that's happened (behavior events like "Emma listened at 3pm"). If you want to log a moment or see what happened today, you ask this team.
- **Key interactions:**
  - Depends on: `RepositoryProtocol`
  - Used by: All feature ViewModels, `LogBehaviorUseCase`
  - Provides: `behaviorTypes`, `behaviorEvents`, `addBehaviorEvent()`, `todayEvents`, `suggestedBehaviors()`, `allowanceEarned()`

#### RewardsStore.swift
- **Technical purpose:** Domain store managing rewards and reward history. Owns `@Published var rewards: [Reward]` and `@Published var rewardHistoryEvents: [RewardHistoryEvent]`. Provides methods to create rewards, redeem rewards, check for timed reward expirations, and retrieve active rewards for children.
- **Non-technical purpose:** The "rewards and goals team." Knows all the rewards each child is working toward, when they were earned, and when they expire. If you want to create a goal or redeem a reward, you ask this team.
- **Key interactions:**
  - Depends on: `RepositoryProtocol`
  - Used by: Feature ViewModels, `RedeemRewardUseCase`, `LogBehaviorUseCase`
  - Provides: `rewards`, `activeReward(forChild:)`, `createReward()`, `redeemReward()`, `checkTimedRewards()`

#### InsightsStore.swift
- **Technical purpose:** Domain store for analytics and insights calculations. Provides methods to calculate child insights data (positivity ratio, top behaviors, streaks), improvement suggestions, weekly summaries. Stateless calculations backed by data from other stores.
- **Non-technical purpose:** The "analytics and insights team." When you want to see patterns—what's working well, what needs attention, weekly summaries—this team crunches the numbers and gives you actionable insights.
- **Key interactions:**
  - Depends on: `RepositoryProtocol` (read-only for most operations)
  - Used by: `InsightsViewModel`, `ChildInsightsViewModel`, feature ViewModels
  - Provides: `insightsData(forChild:timeRange:)`, `improvementSuggestions()`, `weeklySummary()`

#### ProgressionStore.swift
- **Technical purpose:** Domain store managing progression system state. Owns `@Published var parentActivity: ParentActivity` and tracks streaks, skill badges, bonus star eligibility, repair patterns. Provides methods for updating streaks, checking bonus star offers, detecting consistency patterns.
- **Non-technical purpose:** The "progression and milestones team." Tracks how consistent you are, whether a child is on a streak, when to offer bonus stars, and detects when patterns are improving or need repair.
- **Key interactions:**
  - Depends on: `RepositoryProtocol` for streak data
  - Used by: Feature ViewModels, `LogBehaviorUseCase`, `TodayViewModel`
  - Provides: `parentActivity`, `canOfferBonusStar()`, `hasRepairPatternToday()`, `updateStreak()`

#### AgreementsStore.swift
- **Technical purpose:** Domain store managing family agreement system. Owns `@Published var agreementVersions: [AgreementVersion]`. Provides methods to create, update, view agreement versions, track when agreements are reviewed by children.
- **Non-technical purpose:** The "family agreements team." When you create a behavior agreement with your child and they review it, this team tracks all versions and when they were last seen.
- **Key interactions:**
  - Depends on: `RepositoryProtocol`
  - Used by: Feature ViewModels, `FamilyAgreementView`
  - Provides: `agreementVersions`, `currentAgreement(forChild:)`, `createAgreement()`, `markAgreementViewed()`

#### CelebrationStore.swift
- **Technical purpose:** Domain store managing celebration state. Owns `@Published var currentCelebration: CelebrationType?`, `@Published var showRewardEarnedNotification: Bool`. Provides methods to trigger celebrations (star celebration, level up, reward completion) and dismiss them.
- **Non-technical purpose:** The "celebrations team." When something awesome happens—earning a reward, getting a bonus star—this team says "time to celebrate!" and triggers the confetti or notification.
- **Key interactions:**
  - No direct repository dependency (ephemeral state)
  - Used by: `ContentViewModel`, `LogBehaviorUseCase`, `RedeemRewardUseCase`
  - Provides: `currentCelebration`, `triggerStarCelebration()`, `triggerRewardCompletedNotification()`, `dismissCelebration()`

---

### Domain/UseCases/

#### LogBehaviorUseCase.swift
- **Technical purpose:** Use case coordinating the behavior logging transaction. Takes childId, behaviorTypeId, note, timestamp; orchestrates calls to BehaviorsStore (add event), ChildrenStore (update points), RewardsStore (check completion), ProgressionStore (update streak), CelebrationStore (trigger celebration). Ensures atomicity of the multi-store transaction.
- **Non-technical purpose:** The "behavior logging coordinator." When you tap "Good Listening," this makes sure *everything* happens in the right order: log the event, add the points, check if a reward was earned, update the streak, trigger celebrations.
- **Key interactions:**
  - Depends on: `BehaviorsStore`, `ChildrenStore`, `RewardsStore`, `ProgressionStore`, `CelebrationStore`
  - Used by: Views (e.g., `TodayView`, `ChildDetailView`), `LogBehaviorViewModel`
  - Provides: `execute(childId:behaviorTypeId:note:timestamp:)`

#### RedeemRewardUseCase.swift
- **Technical purpose:** Use case coordinating reward redemption. Takes childId, rewardId; orchestrates calls to RewardsStore (redeem reward, add history), ChildrenStore (deduct points, update paidOut for allowance), CelebrationStore (trigger celebration). Ensures transactional consistency.
- **Non-technical purpose:** The "reward redemption coordinator." When a child earns a reward and you tap "Redeem," this makes sure the reward is marked as complete, points are deducted, allowance is updated, and a celebration happens.
- **Key interactions:**
  - Depends on: `RewardsStore`, `ChildrenStore`, `CelebrationStore`, `RepositoryProtocol`
  - Used by: `RewardsViewModel`, `RewardsView`
  - Provides: `execute(childId:rewardId:) async throws`

---

### Data/Preferences/

#### UserPreferencesStore.swift
- **Technical purpose:** Centralized store for app-wide user preferences. Wraps `@AppStorage` declarations in a single place. Provides properties for onboarding state, feature flags, coaching marks, selected filters, themes, and more. Replaces scattered `@AppStorage` across 6+ files.
- **Non-technical purpose:** The "app settings memory." Remembers what you've seen (like coaching tips), what filters you last used, whether you completed onboarding, and your theme preferences—all in one place.
- **Key interactions:**
  - No dependencies (leaf node)
  - Used by: All feature ViewModels, stores, views
  - Provides: `hasCompletedOnboarding`, `selectedTheme`, `hasSeenTodayCoachMarks`, etc.

---

### Models/

#### Child.swift
- **Technical purpose:** Data model representing a child entity. Conforms to `Identifiable`, `Codable`, `Equatable`. Includes properties: id, name, age, colorTag, totalPoints, allowancePaidOut, isArchived, createdDate. Provides computed properties for display (e.g., emoji avatar).
- **Non-technical purpose:** The definition of "what is a child" in TinyWins. Each child has a name, age, color, points, and whether they're archived.
- **Key interactions:**
  - Used by: `ChildrenStore`, all feature ViewModels
  - Referenced in: `BehaviorEvent`, `Reward`, etc.

#### BehaviorType.swift
- **Technical purpose:** Data model representing a behavior rule. Includes properties: id, name, category (positive/negative), iconName, defaultPoints, isActive, sortOrder, appliesToChildren (optional child IDs), createdDate.
- **Non-technical purpose:** The definition of a "rule" like "Good Listening" or "Hitting." Each rule has a name, icon, points value, and whether it's active.
- **Key interactions:**
  - Used by: `BehaviorsStore`, feature ViewModels
  - Referenced in: `BehaviorEvent`

#### BehaviorEvent.swift
- **Technical purpose:** Data model representing a logged behavior instance. Includes: id, childId, behaviorTypeId, timestamp, pointsApplied, note, mediaAttachments. Represents a moment in time when a behavior occurred.
- **Non-technical purpose:** A record of "Emma listened well at 3pm on Tuesday and earned 2 stars." Each event is one logged moment.
- **Key interactions:**
  - Used by: `BehaviorsStore`, analytics, history
  - Created by: `LogBehaviorUseCase`

#### Reward.swift
- **Technical purpose:** Data model representing a reward/goal. Includes: id, childId, name, targetPoints, windowDays (optional time limit), pointsEarned, status (active/completed/expired), createdDate, completedDate, imageName. Provides methods: `pointsEarnedInWindow()`, `progress()`, `status()`.
- **Non-technical purpose:** A goal like "Ice Cream Party - 20 stars in 7 days." Each reward tracks how many stars are needed, the deadline, and whether it's completed.
- **Key interactions:**
  - Used by: `RewardsStore`, feature ViewModels
  - Referenced in: `RewardHistoryEvent`

#### RewardTemplate.swift
- **Technical purpose:** Data model for pre-defined reward suggestions. Includes: category, name, description, suggestedPoints, suggestedDays, iconName, ageRange. Used for quick reward creation.
- **Non-technical purpose:** Template ideas like "Movie Night" or "Extra Screen Time" that help parents quickly create rewards without starting from scratch.
- **Key interactions:**
  - Used by: `RewardsViewModel`, `RewardTemplatePickerView`

#### RewardHistoryEvent.swift
- **Technical purpose:** Data model for reward redemption history. Includes: id, childId, rewardId, rewardName, pointsSpent, timestamp. Records when a reward was redeemed.
- **Non-technical purpose:** A record of "Emma redeemed Ice Cream Party on Saturday." Used in history and analytics.
- **Key interactions:**
  - Used by: `RewardsStore`, `HistoryViewModel`

#### Family.swift
- **Technical purpose:** Data model representing family metadata. Includes: id, name, createdDate, settings (optional). Currently minimal; placeholder for future multi-family support.
- **Non-technical purpose:** Information about the family using TinyWins. Currently just a name and creation date.
- **Key interactions:**
  - Used by: `Repository`, `AppData`

#### AppData.swift
- **Technical purpose:** Root data container for serialization/deserialization. Aggregates all domain entities: family, children, behaviorTypes, behaviorEvents, rewards, allowanceSettings, parentNotes, behaviorStreaks, agreementVersions, rewardHistoryEvents, hasCompletedOnboarding. Used for cloud backup and restore.
- **Non-technical purpose:** The "everything bundle." When backing up to iCloud or restoring, this is the single package containing all your family's data.
- **Key interactions:**
  - Used by: `Repository`, `CloudBackupService`, `BackupSettingsView`

#### AllowanceSettings.swift
- **Technical purpose:** Data model for allowance configuration. Includes: isEnabled, starsPerDollar, payoutFrequency, currencySymbol. Provides method `formatMoney()` for display.
- **Non-technical purpose:** The allowance rules—how many stars equal a dollar, how often you pay out, and what currency symbol to use.
- **Key interactions:**
  - Used by: `Repository`, `BehaviorsStore` (for calculating earnings), `AllowanceView`

#### ProgressionSystem.swift
- **Technical purpose:** Data models for progression features. Includes: `ParentActivity` (tracks active days, coach level), `BonusInsight`, `SkillBadge`, `SpecialMoment`, `YearlySummary`, enums for coaching levels and activity status. Large file (449 lines) defining all progression-related types.
- **Non-technical purpose:** The definitions for milestones like "you've been active 5 days this week," coaching levels, special moments you want to remember, and yearly summaries.
- **Key interactions:**
  - Used by: `ProgressionStore`, `InsightsStore`, insight views

#### AgreementVersion.swift
- **Technical purpose:** Data model representing a family agreement version. Includes: id, childId, behaviorTypeIds (behaviors in the agreement), createdDate, lastViewedByChild (optional). Tracks when a child has seen the agreement.
- **Non-technical purpose:** A snapshot of the behavior agreement with a child—which behaviors are included and when they last reviewed it.
- **Key interactions:**
  - Used by: `AgreementsStore`, `FamilyAgreementView`

#### ColorTag.swift
- **Technical purpose:** Enum representing child color tags for visual differentiation. Cases: blue, green, purple, orange, pink, red. Provides `color: Color` computed property for SwiftUI use.
- **Non-technical purpose:** The color each child picks for their avatar and UI elements—makes it easy to tell kids apart at a glance.
- **Key interactions:**
  - Used by: `Child` model, views for color-coding

#### PremiumFeature.swift
- **Technical purpose:** Enum representing features gated behind Plus subscription. Cases: cloudBackup, multipleChildren, advancedAnalytics, customThemes, etc. Used for feature flagging.
- **Non-technical purpose:** The list of features that are only available to subscribers (like iCloud backups or advanced insights).
- **Key interactions:**
  - Used by: `SubscriptionManager`, feature views for gating

#### PremiumTheme.swift
- **Technical purpose:** Enum representing visual themes for kid-facing views. Cases: default, ocean, forest, space. Provides color schemes and icon sets for each theme.
- **Non-technical purpose:** Fun themes kids can pick for their view—like space theme or ocean theme—to personalize their experience.
- **Key interactions:**
  - Used by: `KidViewModel`, `KidView`, `UserPreferencesStore`

---

### Services/

#### Repository.swift
- **Technical purpose:** Data access facade. Provides high-level CRUD methods for all domain entities (children, behaviors, rewards, etc.). Internally uses `SyncBackend` for persistence. Manages `AppData` instance. Serves as the single point of interaction between domain layer and data layer.
- **Non-technical purpose:** The "data librarian." When any team needs to save or load data, they ask the Repository, which knows how to talk to the database (JSON files or future cloud).
- **Key interactions:**
  - Depends on: `SyncBackend`, `AppData`
  - Used by: All domain stores
  - Provides: `getChildren()`, `save(children:)`, `getBehaviorTypes()`, `save(behaviorEvents:)`, etc.

#### SyncBackend.swift
- **Technical purpose:** Protocol defining sync backend abstraction. Provides `loadAppData() async throws -> AppData`, `saveAppData() async throws`. Current implementation: `LocalSyncBackend` (JSON file persistence). Future: `FirebaseSyncBackend` (Firestore).
- **Non-technical purpose:** The "storage system." Defines how data is saved and loaded. Right now it's local JSON files; in the future it could be cloud storage.
- **Key interactions:**
  - Implemented by: `LocalSyncBackend` (current), potentially `FirebaseSyncBackend` (future)
  - Used by: `Repository`

#### AuthService.swift
- **Technical purpose:** Protocol defining authentication abstraction. Provides `signIn() async throws`, `signOut() async throws`, `currentUser`, `isSignedIn`. Current implementation: `LocalAuthService` (no-op stub). Future: `FirebaseAuthService` (Apple/Google Sign-In).
- **Non-technical purpose:** The "login system." Defines how users sign in. Currently not active (local-only), but will enable multi-device sync when cloud is added.
- **Key interactions:**
  - Implemented by: `LocalAuthService` (current stub)
  - Used by: Future cloud sync features

#### BackendModeDetector.swift
- **Technical purpose:** Helper to detect whether the app is running in local mode or cloud mode. Checks for Firebase configuration files or environment variables to determine which backend to use.
- **Non-technical purpose:** The "mode switcher." Automatically detects whether to use local storage or cloud storage based on app configuration.
- **Key interactions:**
  - Used by: `DependencyContainer` to choose backend at startup

#### CloudBackupService.swift
- **Technical purpose:** Service for iCloud backup and restore. Uses iCloud Document Storage to save/load `AppData` JSON. Provides methods: `backup(appData:)`, `restore() -> AppData`, `lastBackupDate`, `iCloudAvailable`. Separate from main sync (this is for manual backups).
- **Non-technical purpose:** The "iCloud backup tool." When you tap "Back up to iCloud," this saves a snapshot. When you restore, it loads your saved family data from iCloud.
- **Key interactions:**
  - Used by: `BackupSettingsView`, `SettingsViewModel`
  - No dependency on Repository (operates independently)

#### SubscriptionManager.swift
- **Technical purpose:** Service managing in-app purchases and subscription state. Uses StoreKit 2. Provides `@Published var isPlusSubscriber: Bool`, methods to load products, purchase, restore purchases, check subscription status.
- **Non-technical purpose:** The "subscription manager." Knows whether you're a Plus subscriber and handles purchasing the subscription.
- **Key interactions:**
  - Used by: Feature ViewModels for feature gating (e.g., `canAddChild()`)
  - Observed by: Views for showing paywalls or Plus badges

#### NotificationService.swift
- **Technical purpose:** Service for scheduling local notifications. Provides methods to schedule reminder notifications (e.g., daily check-in prompts). Uses UserNotifications framework.
- **Non-technical purpose:** The "reminder system." Sends you notifications like "Time to log today's wins!" at the time you choose.
- **Key interactions:**
  - Used by: `NotificationsSettingsView`, potentially `TodayViewModel`

#### AnalyticsService.swift
- **Technical purpose:** Service providing analytics calculations. Stateless utility methods for calculating insights: `improvementSuggestions()`, `weeklySummary()`, pattern detection. Pure functions operating on behavior/reward data.
- **Non-technical purpose:** The "analytics calculator." Given a bunch of behavior events, it figures out patterns like "you're using too many negative behaviors" or "great week!"
- **Key interactions:**
  - Used by: `InsightsStore`, `ChildInsightsViewModel`
  - No state (pure functions)

#### CelebrationManager.swift
- **Technical purpose:** Service coordinating celebration animations and sounds. Provides methods to trigger confetti, play celebration sounds, choose celebration types based on context (e.g., reward tier).
- **Non-technical purpose:** The "party planner." When something great happens, this decides what kind of celebration to show (confetti, sounds, animations).
- **Key interactions:**
  - Used by: `CelebrationStore`, `CelebrationOverlay`

#### MediaManager.swift
- **Technical purpose:** Service for managing media attachments (photos, videos) associated with behavior events. Provides methods to save, load, delete media files from app document directory.
- **Non-technical purpose:** The "photo album manager." When you attach a photo to a behavior event, this saves it and retrieves it later.
- **Key interactions:**
  - Used by: `LogBehaviorSheet`, `MediaPickerView`, potentially `EditMomentView`

#### FeatureFlags.swift
- **Technical purpose:** Service or struct providing feature flag configuration. Likely provides static flags for enabling/disabling experimental features.
- **Non-technical purpose:** The "feature switch." Turns experimental features on or off without changing code—like a beta feature you can test with some users.
- **Key interactions:**
  - Used by: Various ViewModels and views for conditional feature visibility

#### DataStore.swift
- **Technical purpose:** Legacy or auxiliary data store (check actual contents; may be deprecated or used for specific caching). Potentially handles ephemeral state or in-memory caching.
- **Non-technical purpose:** (Context needed—could be legacy or supplementary storage)
- **Key interactions:**
  - (Depends on actual implementation)

---

### Views/Today/

#### ContentView.swift
- **Technical purpose:** Root SwiftUI view managing tab-based navigation. Displays bottom tab bar (Today, Kids, Rewards, Insights, Settings), coordinates onboarding overlay, manages celebration overlays, shows goal prompts and coaching tips. Acts as the main container for the app's UI.
- **Non-technical purpose:** The "main screen" with the bottom tabs. This is what you see when you open TinyWins—the tabs at the bottom and the ability to navigate between Today, Kids, Rewards, etc.
- **Key interactions:**
  - Observes: `ContentViewModel`, `AppCoordinator`
  - Uses environment objects: All stores and ViewModels
  - Displays child views: `TodayView`, `KidsView`, `RewardsView`, `FamilyInsightsView`, `SettingsView`

#### TodayView.swift
- **Technical purpose:** SwiftUI view for the Today screen. Displays daily coaching tips, child filter chips, quick-log behavior buttons, today's moments timeline, repair pattern banner, weekly recap card, first positive banner. Coordinates with TodayViewModel for presentation logic and LogBehaviorUseCase for logging actions.
- **Non-technical purpose:** The "Today tab"—your main screen each day. Shows coaching, lets you quickly log stars or challenges, and summarizes what's happened today.
- **Key interactions:**
  - Observes: `TodayViewModel`
  - Uses environment objects: `BehaviorsStore`, `ChildrenStore`, `RewardsStore`, `ProgressionStore`, `LogBehaviorUseCase`
  - Presents: `LogBehaviorSheet`, coaching banners, recap cards

---

### Views/Kids/

#### KidsView.swift
- **Technical purpose:** SwiftUI view listing all children. Displays child cards with avatar, name, points, active reward progress. Provides button to add new child (gated by subscription). Navigates to ChildDetailView on tap.
- **Non-technical purpose:** The "Kids tab"—shows all your children and their current progress. Tap a child to see details, or add a new child.
- **Key interactions:**
  - Observes: `KidsViewModel`
  - Uses environment objects: `ChildrenStore`
  - Navigates to: `ChildDetailView`, `AddEditChildView`

#### AddEditChildView.swift
- **Technical purpose:** SwiftUI form for adding or editing a child. Includes fields for name, age, color tag. Validates input and calls `ChildrenStore.addChild()` or `updateChild()`.
- **Non-technical purpose:** The "add/edit child screen." Fill in the child's name, age, pick a color, and save.
- **Key interactions:**
  - Uses environment objects: `ChildrenStore`
  - Dismisses on save

#### ChildDetailView.swift
- **Technical purpose:** SwiftUI view showing parent-facing child details. Displays tabs: Overview (summary, suggestions), Kid View (embed KidView), Agreement (FamilyAgreementView), Insights (ChildInsightsView). Provides navigation for adding rewards, editing child, viewing suggestions.
- **Non-technical purpose:** The "child detail screen for parents." Tap a child in the Kids list to see their insights, agreements, suggestions, and the kid-facing view.
- **Key interactions:**
  - Observes: `ChildDetailViewModel`
  - Uses environment objects: `ChildrenStore`, `BehaviorsStore`, `RewardsStore`, `InsightsStore`, `ProgressionStore`, `CelebrationStore`, `Repository`
  - Presents: `LogBehaviorSheet`, `AddRewardView`, `FamilyAgreementView`, `ChildInsightsView`

#### KidView.swift
- **Technical purpose:** SwiftUI view for kid-facing child display. Displays in kid-friendly theme (ocean, space, etc.), shows points, active reward progress, motivational messages, achievement badges. Allows theme selection.
- **Non-technical purpose:** The "kid's screen." When you hand the device to your child, they see their points, progress toward their reward, and fun themes they can pick.
- **Key interactions:**
  - Observes: `KidViewModel`
  - Uses environment objects: `RewardsStore`, `BehaviorsStore`, `UserPreferencesStore`
  - Embedded in: `ChildDetailView` (Kid View tab)

---

### Views/Rewards/

#### RewardsView.swift
- **Technical purpose:** SwiftUI view managing rewards. Displays child filter, list of active/completed rewards for selected child, reward templates picker, reward redemption flow. Coordinates with RewardsViewModel and RedeemRewardUseCase.
- **Non-technical purpose:** The "Rewards tab"—see all rewards each child is working toward, create new rewards from templates, and redeem earned rewards.
- **Key interactions:**
  - Observes: `RewardsViewModel`
  - Uses environment objects: `RewardsStore`, `ChildrenStore`, `BehaviorsStore`, `CelebrationStore`, `Repository`
  - Presents: `AddRewardView`, `RewardTemplatePickerView`, redemption flow

#### AddRewardView.swift
- **Technical purpose:** SwiftUI form for creating a new reward. Fields: child selection, reward name, target points, time limit (optional), icon picker. Calls `RewardsStore.createReward()` on save.
- **Non-technical purpose:** The "create reward screen." Pick a child, name the reward (e.g., "Ice Cream Party"), set how many stars they need, and optionally set a deadline.
- **Key interactions:**
  - Uses environment objects: `RewardsStore`, `ChildrenStore`
  - Dismisses on save

#### RewardTemplatePickerView.swift
- **Technical purpose:** SwiftUI picker view displaying reward template categories and suggestions. User selects a template to pre-fill AddRewardView.
- **Non-technical purpose:** The "reward ideas screen." Browse suggested rewards like "Movie Night" or "Extra Screen Time" to quickly create a reward without starting from scratch.
- **Key interactions:**
  - Uses template data (hardcoded or from service)
  - Passes selected template back to `AddRewardView`

---

### Views/Insights/

#### FamilyInsightsView.swift
- **Technical purpose:** SwiftUI view for family-level insights. Displays time period selector (this week, last week, etc.), child filter, weekly summary cards, top behaviors, positivity ratio, pattern detection. Uses InsightsViewModel.
- **Non-technical purpose:** The "Insights tab"—see analytics for the whole family or a specific child. Understand what's working well, what patterns emerge, and get coaching tips.
- **Key interactions:**
  - Observes: `InsightsViewModel`
  - Uses environment objects: `InsightsStore`, `BehaviorsStore`, `ChildrenStore`, `RewardsStore`, `ProgressionStore`
  - Links to: `ChildInsightsView`, `HistoryView`, `PremiumAnalyticsDashboard`

#### ChildInsightsView.swift
- **Technical purpose:** SwiftUI view for individual child insights. Displays child-specific analytics: goal progress card, top strengths, challenges, streak info, improvement suggestions. Embedded in ChildDetailView or shown from FamilyInsightsView.
- **Non-technical purpose:** The "insights for one child." Deep dive into Emma's patterns, what she's great at, where she struggles, and suggestions for improvement.
- **Key interactions:**
  - Observes: `ChildInsightsViewModel`
  - Uses environment objects: `InsightsStore`, `BehaviorsStore`, `RewardsStore`, `ProgressionStore`, `ChildrenStore`
  - Embedded in: `ChildDetailView`, linked from `FamilyInsightsView`

#### HistoryView.swift
- **Technical purpose:** SwiftUI view displaying timeline of all behavior events and reward redemptions. Provides filters: time range (today, week, month), type (all, positive, challenges, rewards), child. Uses HistoryViewModel for data aggregation.
- **Non-technical purpose:** The "timeline"—see everything that's happened (stars, challenges, rewards) filtered by time or child. Great for looking back at the week or a specific day.
- **Key interactions:**
  - Observes: `HistoryViewModel`
  - Uses environment objects: `BehaviorsStore`, `RewardsStore`, `ChildrenStore`, `UserPreferencesStore`
  - Displays: Timeline of `HistoryItem` (behavior or reward)

#### PremiumAnalyticsDashboard.swift
- **Technical purpose:** SwiftUI view for the Advanced screen (Plus feature). Displays deeper insights: momentum scores, balance index, heatmaps, weekly trajectory, peak performance times. Takes a `child` parameter for scoped data loading. Gated by subscription.
- **Non-technical purpose:** The "Advanced" screen (for Plus subscribers). See detailed patterns like "most challenges happen at bedtime" or "positive moments increased 30% this month."
- **Key interactions:**
  - Uses environment objects: `Repository`, `SubscriptionManager`
  - Gated by: `isPlusSubscriber`
  - Linked from: `FamilyInsightsView`, `ChildInsightsView`

#### InsightsView.swift
- **Technical purpose:** (DEPRECATED per file header comments). Legacy insights view no longer used in main app navigation. Kept for shared components like `SuggestionCard` and `InsightPeriod` enum until extracted.
- **Non-technical purpose:** Old insights screen (no longer shown to users). Some of its code is still used by other screens.
- **Key interactions:**
  - Not used directly in app flow
  - Provides: `SuggestionCard`, `InsightPeriod` enum used elsewhere

---

### Views/Settings/

#### SettingsView.swift
- **Technical purpose:** SwiftUI view for app settings. Displays sections: subscription management (Plus badge, upgrade button), backup settings (if Plus), behavior management, notifications, appearance, feedback. Navigates to sub-settings views.
- **Non-technical purpose:** The "Settings tab"—manage your subscription, back up to iCloud, customize behaviors, set notifications, change appearance, and send feedback.
- **Key interactions:**
  - Observes: `SettingsViewModel`
  - Uses environment objects: `SubscriptionManager`, `UserPreferencesStore`
  - Navigates to: `BackupSettingsView`, `BehaviorManagementView`, `NotificationsSettingsView`, `AppearanceSettingsView`, `FeedbackView`

#### BackupSettingsView.swift
- **Technical purpose:** SwiftUI view for iCloud backup management (Plus only). Displays last backup date, iCloud availability status, buttons to "Back up now" and "Restore from backup." Uses CloudBackupService.
- **Non-technical purpose:** The "backup screen" (Plus subscribers only). Manually back up your family's data to iCloud or restore from a previous backup.
- **Key interactions:**
  - Uses environment objects: `Repository`, `CloudBackupService`, `SubscriptionManager`
  - Calls: `cloudBackupService.backup()`, `restore()`

#### BehaviorManagementView.swift
- **Technical purpose:** SwiftUI view for managing behavior types. Lists all behaviors (positive and negative), allows adding/editing/deleting, toggling active status, reordering.
- **Non-technical purpose:** The "manage behaviors screen." Add new rules, edit existing ones, turn behaviors on/off, or delete ones you don't use.
- **Key interactions:**
  - Uses environment objects: `BehaviorsStore`
  - Displays: List of `BehaviorType`, edit forms

#### NotificationsSettingsView.swift
- **Technical purpose:** SwiftUI view for notification preferences. Allows enabling/disabling daily reminders, setting reminder time, managing notification permissions.
- **Non-technical purpose:** The "notifications screen." Turn on daily reminders to log moments and choose what time you want to be reminded.
- **Key interactions:**
  - Uses environment objects: `NotificationService`, `UserPreferencesStore`
  - Calls: `requestNotificationPermission()`, `scheduleReminder()`

#### AppearanceSettingsView.swift
- **Technical purpose:** SwiftUI view for appearance customization. Allows selecting app theme, kid view themes, possibly color scheme preferences.
- **Non-technical purpose:** The "appearance screen." Choose themes and colors for the app and kid views.
- **Key interactions:**
  - Uses environment objects: `UserPreferencesStore`
  - Updates: Theme preferences

#### FeedbackView.swift
- **Technical purpose:** SwiftUI form for submitting feedback. Includes text field for feedback message, category picker (bug, suggestion, praise), submit button.
- **Non-technical purpose:** The "send feedback screen." Tell us what you think, report bugs, or suggest new features.
- **Key interactions:**
  - Potentially uses: Email composition or feedback service
  - Dismisses on submit

---

### Views/Components/

#### LogBehaviorSheet.swift
- **Technical purpose:** SwiftUI sheet for logging a behavior. Displays behavior picker (suggested + all behaviors), note field, media attachment picker, reward selector (if applicable), confirmation screen. Coordinates with LogBehaviorViewModel and LogBehaviorUseCase.
- **Non-technical purpose:** The "log a moment screen." When you tap to add a star or challenge, this pops up so you can pick what happened, add a note, and choose which reward it goes toward.
- **Key interactions:**
  - Observes: `LogBehaviorViewModel` (if exists), otherwise uses stores directly
  - Uses environment objects: `BehaviorsStore`, `RewardsStore`, `ChildrenStore`, `LogBehaviorUseCase`, `ProgressionStore`, `UserPreferencesStore`
  - Calls: `logBehaviorUseCase.execute()`

#### FamilyAgreementView.swift
- **Technical purpose:** SwiftUI view for creating and displaying family behavior agreements. Shows selected behaviors, child name, date, allows child to "sign" (view agreement). Tracks agreement versions via AgreementsStore.
- **Non-technical purpose:** The "family agreement screen." Create a behavior contract with your child—show them the rules, let them review and "agree" by tapping.
- **Key interactions:**
  - Uses environment objects: `AgreementsStore`, `BehaviorsStore`, `Repository`
  - Calls: `createAgreement()`, `markAgreementViewed()`

#### AllowanceView.swift
- **Technical purpose:** SwiftUI view for allowance tracking. Displays each child's earned allowance, current balance, payout history, payout button. Uses allowance settings from Repository and calculations from BehaviorsStore.
- **Non-technical purpose:** The "allowance screen." See how much each child has earned in allowance (based on stars), their balance, and pay them out.
- **Key interactions:**
  - Uses environment objects: `Repository`, `ChildrenStore`, `BehaviorsStore`, `UserPreferencesStore`
  - Calls: `behaviorsStore.allowanceEarned()`, `repository.updateAllowancePaidOut()`

#### DailyCheckInView.swift
- **Technical purpose:** SwiftUI view for end-of-day parent reflection. Displays today's stats (positive/negative counts), parent win checklist (self-reflection prompts), custom note field, save button. Saves parent notes to Repository.
- **Non-technical purpose:** The "daily check-in screen." At the end of the day, reflect on what went well for you as a parent and save notes about your parenting wins.
- **Key interactions:**
  - Uses environment objects: `Repository`, `BehaviorsStore`
  - Calls: `repository.addParentNote()`

#### CelebrationOverlay.swift
- **Technical purpose:** SwiftUI overlay for displaying celebrations. Shows confetti animations, reward completion notifications, level-up messages, bonus star celebrations. Triggered by CelebrationStore state changes.
- **Non-technical purpose:** The "celebration animations." When something great happens, you see confetti or a "Reward Earned!" message.
- **Key interactions:**
  - Observes: `CelebrationStore`
  - Displays: Confetti, notifications based on `currentCelebration` type

#### EditMomentView.swift
- **Technical purpose:** SwiftUI sheet for editing an existing behavior event. Allows changing note, media attachments, possibly points. Updates event via BehaviorsStore.
- **Non-technical purpose:** The "edit moment screen." If you logged something by mistake or want to add a note later, you can edit it.
- **Key interactions:**
  - Uses environment objects: `Repository`
  - Calls: Update methods on `BehaviorsStore`

#### MediaPickerView.swift
- **Technical purpose:** SwiftUI view for picking photos/videos from photo library. Uses PhotosUI framework. Returns selected media attachments for behavior events.
- **Non-technical purpose:** The "photo picker." When logging a moment, you can attach a photo to remember it.
- **Key interactions:**
  - Used by: `LogBehaviorSheet`, `EditMomentView`
  - Returns: Media attachments to caller

#### ParentGreetingView.swift
- **Technical purpose:** SwiftUI view displaying personalized greeting to parent. Shows time-of-day greeting, motivational message, quick stats. Displayed on Today screen or ContentView.
- **Non-technical purpose:** The "welcome message"—like "Good morning! You've logged 5 moments this week."
- **Key interactions:**
  - Uses environment objects: `BehaviorsStore`, `ProgressionStore`
  - Displays: Greeting based on time, stats

#### PlusPaywallView.swift
- **Technical purpose:** SwiftUI sheet displaying Plus subscription benefits and purchase options. Shows feature comparison (free vs Plus), pricing, purchase button. Uses SubscriptionManager for purchase flow.
- **Non-technical purpose:** The "upgrade screen." When you tap a Plus feature, this shows what you get with Plus and lets you subscribe.
- **Key interactions:**
  - Uses environment objects: `SubscriptionManager`
  - Calls: `subscriptionManager.purchase()`

#### PlusUpsellCard.swift
- **Technical purpose:** SwiftUI card component for in-line Plus upsells. Displays brief feature description, Plus badge, tap action to open paywall. Used in various views to promote subscription.
- **Non-technical purpose:** The "upgrade teaser card." Appears in free tier to show what you can get with Plus (like "Unlock Advanced").
- **Key interactions:**
  - Tapping opens: `PlusPaywallView`

#### FeedbackPromptView.swift
- **Technical purpose:** SwiftUI view prompting user for feedback at appropriate times. Displays simple prompt like "Enjoying TinyWins? Tell us what you think!" with action buttons.
- **Non-technical purpose:** The "feedback prompt." After you've used the app a bit, we ask if you'd like to share feedback.
- **Key interactions:**
  - Opens: `FeedbackView` or app store review prompt

#### ChildAvatar.swift
- **Technical purpose:** SwiftUI reusable component for displaying child avatar. Shows child's color tag, emoji/initials, optionally child name. Used throughout app for child identification.
- **Non-technical purpose:** The "child icon"—the colorful circle with a letter or emoji that represents each child.
- **Key interactions:**
  - Used by: Many views (KidsView, TodayView, RewardsView, etc.)

#### DesignSystem.swift
- **Technical purpose:** SwiftUI design tokens and reusable components. Defines colors (AppColors), typography (AppFonts), spacing (AppSpacing), shared button styles, card styles, icon components. Ensures UI consistency.
- **Non-technical purpose:** The "style guide." All the colors, fonts, button styles used throughout the app so everything looks consistent.
- **Key interactions:**
  - Used by: All views
  - Provides: `AppColors.primary`, `AppStyles.cardCornerRadius`, `StyledButton`, etc.

---

## Summary

This architecture documentation provides a complete reference for the TinyWins codebase post-refactor. The transition from a monolithic FamilyViewModel to a feature-based, layered architecture has resulted in:

- **Better organization:** 85 focused files instead of a few massive ones
- **Clearer responsibilities:** Each store, ViewModel, and view has a single, well-defined purpose
- **Improved maintainability:** Changes are scoped and predictable
- **Enhanced testability:** Individual components can be tested in isolation
- **Faster onboarding:** New engineers can quickly understand and contribute to specific features
- **Lower risk:** Feature changes don't accidentally affect unrelated parts of the app

For detailed implementation context, see [TinyWins_Refactoring_Plan.md](TinyWins_Refactoring_Plan.md).

For app setup and development instructions, see [README.md](README.md).

---

**Document Version:** 1.0
**Last Updated:** December 2024
**Maintained By:** TinyWins Engineering Team
