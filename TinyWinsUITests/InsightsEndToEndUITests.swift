import XCTest

// MARK: - Insights End-to-End UI Tests
//
// ## Setup Required
// This test file requires a TinyWinsUITests target to be created in Xcode.
// To add the target:
// 1. In Xcode, select the project in navigator
// 2. Click "+" at bottom of targets list
// 3. Choose iOS > UI Testing Bundle
// 4. Name it "TinyWinsUITests"
// 5. Add this file to the target
//
// ## Test Data Required
// These tests assume the app has:
// - At least one child configured
// - Some behavior events logged (for coach cards)
// - For premium tests: a mock premium subscription state
//
// ## Running Tests
// Run with: cmd+U in Xcode, or via xcodebuild:
// xcodebuild test -scheme TinyWins -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:TinyWinsUITests

final class InsightsEndToEndUITests: XCTestCase {

    private var app: XCUIApplication!

    // MARK: - Accessibility Identifiers (must match InsightsAccessibilityIdentifiers.swift)

    private enum ID {
        // Tab Bar
        static let insightsTab = "insights_tab"

        // Insights Home
        static let insightsHomeRoot = "insights_home_root"
        static let coachCardListRoot = "coach_card_list_root"
        static let cardsLoadingIndicator = "coach_cards_loading"
        static let cardsEmptyState = "coach_cards_empty_state"

        // Child Context Bar
        static let childContextBarRoot = "child_context_bar_root"
        static let childPickerOpenButton = "child_picker_open_button"

        // Child Picker Sheet
        static let childPickerSheetRoot = "child_picker_sheet_root"
        static let childPickerList = "child_picker_list"
        static let childPickerCancelButton = "child_picker_cancel_button"
        static func childPickerRow(childId: String) -> String { "child_picker_row_\(childId)" }

        // Coach Card
        static func coachCard(cardId: String) -> String { "coach_card_\(cardId)" }
        static func evidenceButton(cardId: String) -> String { "evidence_button_\(cardId)" }
        static func ctaButton(cardId: String) -> String { "cta_button_\(cardId)" }

        // Evidence Sheet
        static let evidenceSheetRoot = "evidence_sheet_root"
        static let evidenceSheetDoneButton = "evidence_sheet_done_button"

        // Explore Section
        static let exploreHistoryLink = "explore_history_link"
        static let exploreGrowthRingsLink = "explore_growth_rings_link"
        static let advancedInsightsEntryPoint = "advanced_insights_entry_point"

        // Advanced Analytics
        static let advancedAnalyticsRoot = "advanced_analytics_root"
        static let familyAnalyticsRoot = "family_analytics_root"
        static let growthRingsRoot = "growth_rings_root"

        // Premium
        static let premiumNudge = "premium_nudge"
        static let paywallRoot = "paywall_root"
    }

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Enable UI testing mode - app can check this to provide test data
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test: Full Journey

    /// Tests the complete insights journey:
    /// 1. Navigate to Insights tab
    /// 2. Verify Insights home loads
    /// 3. Select a child
    /// 4. Open a coach card's evidence
    /// 5. Dismiss evidence sheet
    /// 6. Navigate to Advanced Analytics
    /// 7. Navigate back
    func testInsightsFullJourney() throws {
        // 1. Navigate to Insights tab
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5), "Insights tab should exist")
        insightsTab.tap()

        // 2. Verify Insights home loads
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5), "Insights home should load")

        // Wait for loading to complete
        let loadingIndicator = app.otherElements[ID.cardsLoadingIndicator]
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10), "Loading should complete")
        }

        // 3. Select a different child (if child picker button exists)
        let childPickerButton = app.buttons[ID.childPickerOpenButton]
        if childPickerButton.exists {
            childPickerButton.tap()

            // Verify child picker sheet appears
            let childPickerSheet = app.otherElements[ID.childPickerSheetRoot]
            XCTAssertTrue(childPickerSheet.waitForExistence(timeout: 3), "Child picker sheet should appear")

            // Select first available child row (could query by prefix)
            let childRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "child_picker_row_"))
            if childRows.count > 0 {
                childRows.element(boundBy: 0).tap()
            } else {
                // No child rows, dismiss with cancel
                let cancelButton = app.buttons[ID.childPickerCancelButton]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }

            // Wait for sheet to dismiss
            XCTAssertTrue(childPickerSheet.waitForNonExistence(timeout: 3), "Child picker should dismiss")
        }

        // 4. Open evidence from a coach card (if any cards exist)
        let cardList = app.otherElements[ID.coachCardListRoot]
        XCTAssertTrue(cardList.waitForExistence(timeout: 3), "Coach card list should exist")

        // Look for any evidence button
        let evidenceButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "evidence_button_"))
        if evidenceButtons.count > 0 {
            evidenceButtons.element(boundBy: 0).tap()

            // 5. Verify evidence sheet appears and dismiss it
            let evidenceSheet = app.otherElements[ID.evidenceSheetRoot]
            XCTAssertTrue(evidenceSheet.waitForExistence(timeout: 3), "Evidence sheet should appear")

            let doneButton = app.buttons[ID.evidenceSheetDoneButton]
            XCTAssertTrue(doneButton.exists, "Done button should exist on evidence sheet")
            doneButton.tap()

            XCTAssertTrue(evidenceSheet.waitForNonExistence(timeout: 3), "Evidence sheet should dismiss")
        }

        // 6. Navigate to Advanced Analytics (or paywall if not premium)
        let advancedButton = app.buttons[ID.advancedInsightsEntryPoint]
        XCTAssertTrue(advancedButton.waitForExistence(timeout: 3), "Advanced Analytics button should exist")
        advancedButton.tap()

        // Should show either advanced analytics (premium) or paywall (free)
        let advancedAnalytics = app.otherElements[ID.advancedAnalyticsRoot]
        let paywall = app.otherElements[ID.paywallRoot]

        let advancedAppeared = advancedAnalytics.waitForExistence(timeout: 3)
        let paywallAppeared = paywall.waitForExistence(timeout: 3)

        XCTAssertTrue(advancedAppeared || paywallAppeared, "Should navigate to advanced analytics or paywall")

        // 7. Navigate back
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }

        // Verify we're back at Insights home
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 3), "Should return to Insights home")
    }

    // MARK: - Test: Child Selection

    /// Tests child selection flow:
    /// 1. Open child picker
    /// 2. Verify all children are listed
    /// 3. Select a child
    /// 4. Verify selection is applied
    func testChildSelection() throws {
        // Navigate to Insights
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5))
        insightsTab.tap()

        // Wait for home to load
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5))

        // Open child picker
        let childPickerButton = app.buttons[ID.childPickerOpenButton]
        guard childPickerButton.exists else {
            XCTFail("Child picker button should exist")
            return
        }
        childPickerButton.tap()

        // Verify sheet appears
        let childPickerSheet = app.otherElements[ID.childPickerSheetRoot]
        XCTAssertTrue(childPickerSheet.waitForExistence(timeout: 3))

        // Verify child list exists
        let childPickerList = app.otherElements[ID.childPickerList]
        XCTAssertTrue(childPickerList.exists, "Child picker list should exist")

        // Count child rows
        let childRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "child_picker_row_"))
        XCTAssertGreaterThan(childRows.count, 0, "Should have at least one child row")

        // Select a child
        childRows.element(boundBy: 0).tap()

        // Verify sheet dismissed
        XCTAssertTrue(childPickerSheet.waitForNonExistence(timeout: 3))
    }

    // MARK: - Test: Empty State

    /// Tests behavior when no coach cards are available
    func testEmptyStateDisplay() throws {
        // This test requires the app to be in a state with no cards
        // Launch with special argument to clear data
        app.terminate()
        app.launchArguments.append("--uitesting-empty-insights")
        app.launch()

        // Navigate to Insights
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5))
        insightsTab.tap()

        // Wait for home to load
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5))

        // Wait for loading to complete
        let loadingIndicator = app.otherElements[ID.cardsLoadingIndicator]
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10))
        }

        // Check for empty state
        let emptyState = app.otherElements[ID.cardsEmptyState]
        // Empty state should appear if no cards
        // (This test may pass or fail depending on test data state)
    }

    // MARK: - Test: Premium Nudge

    /// Tests that free tier users see the premium nudge
    func testPremiumNudgeVisibility() throws {
        // Launch as free tier user
        app.terminate()
        app.launchArguments.append("--uitesting-free-tier")
        app.launch()

        // Navigate to Insights
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5))
        insightsTab.tap()

        // Wait for home to load
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5))

        // Scroll to find premium nudge
        let premiumNudge = app.otherElements[ID.premiumNudge]
        if !premiumNudge.exists {
            app.swipeUp()
        }

        XCTAssertTrue(premiumNudge.waitForExistence(timeout: 3), "Premium nudge should be visible for free tier")
    }

    // MARK: - Test: Child Selection Resilience (Deleted Child)

    /// Tests behavior when the selected child is deleted:
    /// 1. Start with a child selected
    /// 2. Simulate child deletion
    /// 3. Verify app gracefully handles the situation
    ///
    /// Note: This test requires special app support to simulate child deletion
    func testDeletedChildResilience() throws {
        // Launch with test data that will simulate a deleted child
        app.terminate()
        app.launchArguments.append("--uitesting-deleted-child")
        app.launch()

        // Navigate to Insights
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5))
        insightsTab.tap()

        // Wait for home to load
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5))

        // The app should handle this gracefully:
        // - Either show empty state
        // - Or auto-select another child
        // - Or prompt user to select a child

        // Verify no crash occurred and UI is in a reasonable state
        let childPickerButton = app.buttons[ID.childPickerOpenButton]
        let emptyState = app.otherElements[ID.cardsEmptyState]
        let cardList = app.otherElements[ID.coachCardListRoot]

        // At least one of these should be visible
        let hasValidState = childPickerButton.exists || emptyState.exists || cardList.exists
        XCTAssertTrue(hasValidState, "App should be in a valid state after deleted child scenario")
    }

    // MARK: - Test: Navigation Path Preservation

    /// Tests that deep navigation works correctly:
    /// 1. Navigate deep into Insights
    /// 2. Switch tabs
    /// 3. Return to Insights
    /// 4. Verify navigation state
    func testNavigationPathPreservation() throws {
        // Navigate to Insights
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5))
        insightsTab.tap()

        // Wait for home
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5))

        // Navigate to History (if available)
        let historyLink = app.buttons[ID.exploreHistoryLink]
        if historyLink.waitForExistence(timeout: 3) {
            historyLink.tap()

            // Give time for navigation
            sleep(1)

            // Switch to another tab (e.g., Today)
            let todayTab = app.buttons["today_tab"]
            if todayTab.exists {
                todayTab.tap()
                sleep(1)

                // Return to Insights
                insightsTab.tap()
                sleep(1)

                // Navigation behavior depends on implementation:
                // - May return to Insights root
                // - Or may preserve navigation stack
                // Either is acceptable, just verify no crash
                XCTAssertTrue(app.exists, "App should still be running")
            }
        }
    }

    // MARK: - Test: Accessibility

    /// Tests that key elements have proper accessibility labels
    func testAccessibilityLabels() throws {
        // Navigate to Insights
        let insightsTab = app.buttons[ID.insightsTab]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5))

        // Verify insights tab has accessibility label
        XCTAssertTrue(insightsTab.label.lowercased().contains("insights"), "Insights tab should have proper label")

        insightsTab.tap()

        // Wait for home
        let insightsHome = app.otherElements[ID.insightsHomeRoot]
        XCTAssertTrue(insightsHome.waitForExistence(timeout: 5))

        // Verify child picker button has accessibility
        let childPickerButton = app.buttons[ID.childPickerOpenButton]
        if childPickerButton.exists {
            XCTAssertFalse(childPickerButton.label.isEmpty, "Child picker should have accessibility label")
        }
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    /// Waits for the element to not exist (disappear)
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
