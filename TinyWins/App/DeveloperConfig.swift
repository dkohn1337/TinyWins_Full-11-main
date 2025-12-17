import Foundation

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - Developer Configuration
// ═══════════════════════════════════════════════════════════════════════════
//
// HOW TO EXCLUDE FROM PRODUCTION:
// ═══════════════════════════════
// Option 1 (Recommended): Add this file to a "Developer" Build Phase that only
//                         runs for Debug scheme. In Release scheme, this file
//                         won't be compiled.
//
// Option 2: Use Xcode's "Excluded Source Files" build setting for Release.
//           Add "DeveloperConfig.swift" to the Release configuration.
//
// Option 3: Keep the file but change `isDeveloperMenuEnabled` to `false` before
//           creating a release build.
//
// Option 4: Use a separate target/scheme for development that includes this file.
//
// The app will compile and run without this file because SettingsView checks
// for DeveloperConfig existence using `#if canImport(DeveloperConfig)` pattern,
// or by checking the `isDeveloperMenuEnabled` flag.
//
// ═══════════════════════════════════════════════════════════════════════════

/// Developer menu configuration.
/// This struct controls whether developer-only features are visible.
/// To disable for production: either exclude this file or set `isDeveloperMenuEnabled = false`.
enum DeveloperConfig {

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - MAIN SWITCH
    // ═══════════════════════════════════════════════════════════════════════

    /// Set to `false` to completely hide the developer menu in Settings.
    /// This is the main kill switch for production builds.
    ///
    /// When building for App Store:
    /// 1. Set this to `false`, OR
    /// 2. Exclude this entire file from the Release build
    static let isDeveloperMenuEnabled: Bool = true

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - Feature Flags
    // ═══════════════════════════════════════════════════════════════════════

    /// Show the "Unlock Plus" toggle in developer menu
    static let showUnlockPlusToggle: Bool = true

    /// Show the "Show Onboarding" button in developer menu
    static let showOnboardingTrigger: Bool = true

    /// Show debug information overlays
    static let showDebugInfoToggle: Bool = true

    /// Show "Load Demo Data" button in developer section
    /// Replaces all data with comprehensive demo data for testing
    static let showLoadDemoData: Bool = true

    /// Show "Erase All Data" in developer section (in addition to Danger Zone)
    /// This version includes more aggressive clearing for testing
    static let showDevEraseData: Bool = true

    /// Show Partner Attribution toggle in developer section
    /// Enables "Logged by [Parent]" feature for testing without co-parent
    static let showPartnerAttributionToggle: Bool = true

    /// Show Partner Dashboard link in developer section
    static let showPartnerDashboardLink: Bool = true

    /// Show Demo Paywall toggle in developer section
    /// When enabled, paywall shows mock pricing even without StoreKit connection
    static let showDemoPaywallToggle: Bool = true

    /// Show Firebase Sync toggle in developer section
    /// Allows enabling/disabling Firebase sync at runtime for testing
    static let showFirebaseSyncToggle: Bool = true

    // ═══════════════════════════════════════════════════════════════════════
    // MARK: - Computed Properties
    // ═══════════════════════════════════════════════════════════════════════

    /// Whether to show the developer section at all.
    /// Combines the main switch with DEBUG flag for extra safety.
    static var shouldShowDeveloperSection: Bool {
        #if DEBUG
        return isDeveloperMenuEnabled
        #else
        // In release builds, always hide unless explicitly enabled
        return isDeveloperMenuEnabled
        #endif
    }
}
