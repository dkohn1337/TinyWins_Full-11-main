import Foundation

// MARK: - Insights Accessibility Identifiers

/// Centralized accessibility identifiers for Insights UI testing.
/// These identifiers are stable and should NOT change between releases.
/// Do NOT use visible text as identifiers.
enum InsightsAccessibilityIdentifiers {

    // MARK: - Tab Bar

    /// The Insights tab button in the floating tab bar
    static let insightsTab = "insights_tab"

    // MARK: - Insights Home

    /// The root view of InsightsHomeView
    static let insightsHomeRoot = "insights_home_root"

    /// The container for the coach cards list
    static let coachCardListRoot = "coach_card_list_root"

    /// The loading indicator when cards are loading
    static let cardsLoadingIndicator = "coach_cards_loading"

    /// The empty state when no cards are available
    static let cardsEmptyState = "coach_cards_empty_state"

    // MARK: - Child Context Bar

    /// The root view of ChildContextBar
    static let childContextBarRoot = "child_context_bar_root"

    /// The button to open the child picker sheet
    static let childPickerOpenButton = "child_picker_open_button"

    /// The time range picker menu
    static let timeRangePicker = "time_range_picker"

    // MARK: - Child Picker Sheet

    /// The root view of the child picker sheet
    static let childPickerSheetRoot = "child_picker_sheet_root"

    /// The list container for child rows
    static let childPickerList = "child_picker_list"

    /// Generates a stable identifier for a child row in the picker
    /// - Parameter childId: The UUID of the child
    /// - Returns: A stable identifier string
    static func childPickerRow(childId: UUID) -> String {
        "child_picker_row_\(childId.uuidString)"
    }

    /// The cancel button in the child picker sheet
    static let childPickerCancelButton = "child_picker_cancel_button"

    // MARK: - Coach Card

    /// Generates a stable identifier for a coach card
    /// - Parameter cardId: The ID of the card
    /// - Returns: A stable identifier string
    static func coachCard(cardId: String) -> String {
        "coach_card_\(cardId)"
    }

    /// The evidence button on a coach card
    /// - Parameter cardId: The ID of the card
    /// - Returns: A stable identifier string
    static func evidenceButton(cardId: String) -> String {
        "evidence_button_\(cardId)"
    }

    /// The CTA button on a coach card
    /// - Parameter cardId: The ID of the card
    /// - Returns: A stable identifier string
    static func ctaButton(cardId: String) -> String {
        "cta_button_\(cardId)"
    }

    // MARK: - Evidence Sheet

    /// The root view of the evidence sheet
    static let evidenceSheetRoot = "evidence_sheet_root"

    /// The done button in the evidence sheet
    static let evidenceSheetDoneButton = "evidence_sheet_done_button"

    // MARK: - Explore Section

    /// The history explore link
    static let exploreHistoryLink = "explore_history_link"

    /// The growth rings explore link
    static let exploreGrowthRingsLink = "explore_growth_rings_link"

    /// The advanced analytics explore link (entry point)
    static let advancedInsightsEntryPoint = "advanced_insights_entry_point"

    // MARK: - Advanced Analytics (Premium)

    /// The root view of the advanced analytics dashboard
    static let advancedAnalyticsRoot = "advanced_analytics_root"

    /// The root view of family analytics dashboard
    static let familyAnalyticsRoot = "family_analytics_root"

    /// The root view of growth rings
    static let growthRingsRoot = "growth_rings_root"

    // MARK: - Premium

    /// The premium upgrade nudge
    static let premiumNudge = "premium_nudge"

    /// The paywall view root
    static let paywallRoot = "paywall_root"
}
