# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build from command line
xcodebuild -scheme TinyWins -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests (UI tests require TinyWinsUITests target)
xcodebuild test -scheme TinyWins -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific UI test class
xcodebuild test -scheme TinyWins -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:TinyWinsUITests/InsightsEndToEndUITests
```

Most development is done in Xcode: open `TinyWins.xcodeproj`, select a simulator, and press Cmd+R to build and run.

## Architecture Overview

TinyWins is a native iOS app (iOS 17+, Swift 5, SwiftUI) using a **feature-based, layered MVVM architecture**. The app helps parents track children's behaviors and rewards.

### Dependency Flow

```
Views → Feature ViewModels → Domain Stores → Repository → SyncBackend
```

All dependencies are injected via `DependencyContainer` (created in `TinyWinsApp.swift`) and passed to views through SwiftUI `@EnvironmentObject`.

### Key Architectural Layers

**App Layer** (`TinyWins/App/`):
- `TinyWinsApp.swift` - Entry point, creates DependencyContainer
- `DependencyContainer.swift` - Single source for all dependency injection
- `AppCoordinator.swift` - Centralized navigation state
- `AppConfiguration.swift` - Backend mode switch (local vs Firebase)

**Domain Stores** (`TinyWins/Domain/Stores/`):
- `ChildrenStore`, `BehaviorsStore`, `RewardsStore` - Core data owners
- `InsightsStore`, `ProgressionStore`, `CelebrationStore`, `AgreementsStore`
- Each store owns `@Published` domain state and calls Repository for persistence

**Use Cases** (`TinyWins/Domain/UseCases/`):
- `LogBehaviorUseCase` - Coordinates logging across multiple stores
- `RedeemRewardUseCase` - Coordinates reward redemption
- `CelebrationQueueUseCase`, `GoalPromptUseCase` - UI coordination

**Feature ViewModels** (`TinyWins/Features/`):
- `TodayViewModel`, `KidsViewModel`, `RewardsViewModel`, `InsightsViewModel`, etc.
- Presentation logic only, depend on stores

**Views** (`TinyWins/Views/`):
- Organized by feature: `Today/`, `Kids/`, `Rewards/`, `Insights/`, `Settings/`
- `Components/` contains reusable UI components

### Data Persistence

- **Repository** (`Services/Repository.swift`) - Data access facade
- **SyncBackend protocol** - Abstraction for storage
- **LocalSyncBackend** - JSON file persistence (default)
- **FirebaseSyncBackend** - Cloud sync (optional, see Backend Configuration)

### Backend Configuration

Toggle between local-only and Firebase mode in `TinyWins/App/AppConfiguration.swift`:
```swift
static let backendMode: BackendMode = .localOnly  // or .firebase
```

Feature gating for Firebase in views:
```swift
NavigationLink("Co-Parent Settings") { ... }.coParentOnly()
if AppConfiguration.isFirebaseEnabled { ... }
```

## Key Patterns

### Adding a New Feature
1. Create ViewModel in `Features/YourFeature/`
2. Add store if needed in `Domain/Stores/`
3. Register in `DependencyContainer`
4. Create view in `Views/YourFeature/`

### Multi-Store Transactions
Use a Use Case to coordinate changes across multiple stores (see `LogBehaviorUseCase` for pattern).

### Theme System
Two theme systems exist (being unified):
- Legacy: `ThemeProvider` + `AppTheme` enum in `Core/ThemeSystem.swift`
- New: `ThemeKit` in `Core/ThemeKit/` with semantic tokens

Themes are synced in `TinyWinsApp.swift`. Free themes: system, gentle, sunny, ocean. Premium themes require Plus subscription.

## Testing

Tests are minimal currently:
- `TinyWins/InsightsEngine/InsightsEngineTests.swift` - Unit tests for insights (run in DEBUG)
- `TinyWinsUITests/InsightsEndToEndUITests.swift` - UI tests for insights flow
- `TinyWins/Core/Tokens/TokenTests.swift` - Token system tests

## Models

Core models in `TinyWins/Models/`:
- `Child` - Child entity with points, color tag
- `BehaviorType` - Behavior rules (positive/negative)
- `BehaviorEvent` - Logged behavior instances
- `Reward` - Goals with target points and optional time limits
- `AppData` - Root container for all data (used for backup/restore)
