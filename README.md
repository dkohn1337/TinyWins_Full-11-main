# TinyWins

**Make parenting easier, one tiny win at a time.**

---

## What is TinyWins?

TinyWins is an iOS app designed to help parents encourage positive behaviors in their children through a simple, reward-based system. Instead of focusing on what goes wrong, TinyWins helps families celebrate what goes right—one moment at a time.

**For parents:** Track your children's behaviors, set up meaningful rewards, and get insights into patterns that help you parent with clarity and confidence.

**For kids:** See progress toward fun rewards, celebrate achievements, and understand expectations in a kid-friendly way.

TinyWins is built for modern families who want to foster positive habits without the stress—transforming daily parenting into a series of tiny wins worth celebrating.

---

## Key Features

- **Star-Based Reward System:** Log positive moments and challenges, assign star values, and track progress toward goals
- **Kid-Facing Views:** Let your child see their progress in fun, themed interfaces (space, ocean, forest themes)
- **Smart Insights & Analytics:** Understand patterns, get coaching suggestions, and celebrate weekly progress
- **Customizable Behaviors:** Define behaviors that matter to your family—from "Good Listening" to "Homework Done"
- **Flexible Rewards:** Set up time-limited or open-ended rewards (e.g., "20 stars for Ice Cream Party in 7 days")
- **Family Agreements:** Create behavior contracts your child can review and "sign"
- **Allowance Tracking:** Convert stars into allowance dollars and manage payouts
- **Parent Reflection Tools:** Daily check-ins and coaching to support your parenting journey
- **Progression & Streaks:** Track consistency, unlock milestones, and celebrate long-term growth
- **Cloud Backup & Sync (Plus):** Back up your family's data to iCloud (for TinyWins Plus subscribers)
- **Multiple Children Support:** Manage rewards, behaviors, and insights for multiple kids in one app

---

## Tech Stack

TinyWins is a native iOS app built with modern Swift and SwiftUI:

- **Language:** Swift 5.0+
- **UI Framework:** SwiftUI
- **Architecture:** Feature-based MVVM with layered domain separation
  - **App Layer:** Dependency injection (`DependencyContainer`), navigation (`AppCoordinator`)
  - **Features Layer:** Presentation ViewModels (focused on specific screens)
  - **Domain Layer:** Domain Stores (business logic owners) and Use Cases (transaction coordinators)
  - **Data Layer:** Repository pattern, local JSON persistence (`LocalSyncBackend`)
  - **Services Layer:** Analytics, notifications, subscriptions, media, cloud backups
- **State Management:** Combine framework with `@Published` properties, SwiftUI environment objects
- **Persistence:** Local JSON file storage, iCloud document backups for Plus subscribers
- **In-App Purchases:** StoreKit 2 for TinyWins Plus subscriptions
- **Notifications:** UserNotifications framework for daily reminders
- **Photos & Media:** PhotosUI for attaching images to behavior events

**Future-Ready:**
- Abstraction layer for Firebase sync (`SyncBackend` protocol, `AuthService` protocol)
- Designed for multi-device cloud sync when Firebase is integrated

---

## Requirements

- **Xcode:** 15.0 or later
- **iOS Deployment Target:** 17.0+
- **Swift Version:** 5.0+
- **macOS:** Running macOS compatible with Xcode 15+

---

## Getting Started

### For Users (Running the App)

1. **Open the project:** Double-click `TinyWins.xcodeproj` in Xcode
2. **Set your development team:**
   - Select the TinyWins project in the navigator
   - Go to Signing & Capabilities
   - Choose your Apple Developer team
3. **Build and run:**
   - Select a simulator (e.g., iPhone 15) or connect a physical device
   - Press `Cmd + R` or click the Play button to build and run
4. **First launch:**
   - Complete the onboarding flow
   - Add your first child
   - Create a few behaviors (or use defaults)
   - Set up a reward and start logging moments!

### For Developers (Contributing or Extending)

1. **Clone or download** the repository
2. **Install dependencies:** No external dependencies—pure SwiftUI and native frameworks
3. **Understand the architecture:** Read [TinyWinsArchitecture.md](TinyWinsArchitecture.md) for a complete guide to the codebase structure
4. **Run tests (if available):** Select the test target and run unit tests (`Cmd + U`)
5. **Make changes:** Follow the feature-based architecture—add new features in `Features/`, domain logic in `Domain/Stores/`, and reusable UI in `Views/Components/`
6. **Test locally:** Build and run on simulator or device to verify your changes
7. **Review architecture docs:** Before making structural changes, consult the architecture documentation to maintain consistency

---

## Documentation

- **[TinyWinsArchitecture.md](TinyWinsArchitecture.md)** — Comprehensive architecture documentation covering:
  - Overview of the recent refactor (old vs new architecture)
  - Benefits of the feature-based MVVM design
  - High-level architecture with layer diagrams
  - File-by-file documentation for all 85 Swift files
  - State ownership model and data flow examples

This is the **primary reference** for understanding how TinyWins is built and how to contribute.

---

## Project Structure

TinyWins follows a **feature-based, layered architecture** for clarity and maintainability:

```
TinyWins/
├── App/                            # App entry, DI, navigation
│   ├── TinyWinsApp.swift           # Entry point & environment setup
│   ├── AppCoordinator.swift        # Centralized navigation state
│   └── DependencyContainer.swift   # Dependency injection container
├── Features/                       # Feature-specific ViewModels
│   ├── Today/                      # Today screen presentation logic
│   ├── Kids/                       # Kids list & detail logic
│   ├── Rewards/                    # Rewards management logic
│   ├── Insights/                   # Analytics & insights logic
│   ├── Settings/                   # Settings logic
│   ├── LogBehavior/                # Behavior logging flow logic
│   ├── Onboarding/                 # Onboarding flow logic
│   └── ContentViewModel.swift      # Root-level coordination
├── Domain/                         # Business logic & domain models
│   ├── Stores/                     # Domain state owners (7 stores)
│   │   ├── ChildrenStore.swift
│   │   ├── BehaviorsStore.swift
│   │   ├── RewardsStore.swift
│   │   ├── InsightsStore.swift
│   │   ├── ProgressionStore.swift
│   │   ├── AgreementsStore.swift
│   │   └── CelebrationStore.swift
│   └── UseCases/                   # Transaction coordinators
│       ├── LogBehaviorUseCase.swift
│       └── RedeemRewardUseCase.swift
├── Data/                           # Persistence & data access
│   ├── Preferences/
│   │   └── UserPreferencesStore.swift  # Centralized @AppStorage
│   └── (Repository, SyncBackend)
├── Models/                         # Data models (14+ files)
│   ├── Child.swift
│   ├── BehaviorType.swift
│   ├── BehaviorEvent.swift
│   ├── Reward.swift
│   └── ... (other domain entities)
├── Services/                       # Cross-cutting infrastructure
│   ├── Repository.swift            # Data access facade
│   ├── SyncBackend.swift           # Persistence abstraction
│   ├── AuthService.swift           # Auth abstraction (future Firebase)
│   ├── CloudBackupService.swift    # iCloud backups
│   ├── SubscriptionManager.swift   # StoreKit IAP
│   ├── AnalyticsService.swift      # Insights calculations
│   ├── NotificationService.swift   # Local notifications
│   ├── CelebrationManager.swift    # Celebration animations
│   └── MediaManager.swift          # Photo/video attachments
├── Views/                          # SwiftUI views
│   ├── Today/                      # ContentView, TodayView
│   ├── Kids/                       # KidsView, ChildDetailView, KidView
│   ├── Rewards/                    # RewardsView, AddRewardView
│   ├── Insights/                   # FamilyInsightsView, ChildInsightsView, HistoryView
│   ├── Settings/                   # SettingsView, BackupSettingsView
│   └── Components/                 # Reusable UI components
│       ├── LogBehaviorSheet.swift
│       ├── FamilyAgreementView.swift
│       ├── AllowanceView.swift
│       ├── DailyCheckInView.swift
│       ├── CelebrationOverlay.swift
│       └── ... (design system, shared components)
├── Assets.xcassets/
└── Info.plist
```

For a **complete breakdown** of all 85 Swift files, see [TinyWinsArchitecture.md](TinyWinsArchitecture.md).

---

## Architecture Highlights

### Recent Refactor: From Monolith to Feature-Based Architecture

TinyWins recently underwent a major refactor, removing the 1,979-line `FamilyViewModel` "god object" and replacing it with:

- **7 Domain Stores:** Each owns a specific domain (children, behaviors, rewards, insights, progression, agreements, celebrations)
- **10+ Feature ViewModels:** Focused presentation logic for each screen
- **2 Use Cases:** Coordinate multi-store transactions (logging behaviors, redeeming rewards)
- **Centralized Navigation:** `AppCoordinator` manages all navigation state
- **Centralized DI:** `DependencyContainer` builds the entire object graph

**Benefits:**
- Faster feature development
- Lower risk of regressions
- Easier onboarding for new developers
- Better testability
- Clearer separation of concerns

For full details on the refactor rationale and benefits, see [TinyWinsArchitecture.md](TinyWinsArchitecture.md).

### Backend Foundation

TinyWins is built with a clean abstraction layer for future cloud sync:

- **Current Backend:** `LocalSyncBackend` (local JSON file persistence)
- **Current Auth:** `LocalAuthService` (no-op stub, no sign-in required)
- **Future-Ready:** `SyncBackend` and `AuthService` protocols enable drop-in Firebase integration

When Firebase is added, the app will seamlessly switch to:
- **Cloud Sync:** Firestore-backed `FirebaseSyncBackend`
- **User Auth:** Apple/Google Sign-In via `FirebaseAuthService`

---

## Build Info

- **85 Swift files** organized across 5 architectural layers
- **Xcode 15.0+** compatible
- **iOS 17.0+** deployment target
- **No external dependencies** (pure SwiftUI, native frameworks)

---

## Contributing

TinyWins is designed for extensibility. To contribute:

1. Read [TinyWinsArchitecture.md](TinyWinsArchitecture.md) to understand the structure
2. Follow the feature-based architecture pattern
3. Add new domain logic to `Domain/Stores/`
4. Add new presentation logic to `Features/`
5. Add new reusable UI to `Views/Components/`
6. Keep files focused and single-purpose (aim for 100-300 lines per file)

---

## License

(Add your license information here)

---

## Contact & Support

For questions, feedback, or support, contact us at:
- **Email:** (your support email)
- **GitHub Issues:** (if applicable)

---

**TinyWins** — Making parenting easier, one tiny win at a time.
