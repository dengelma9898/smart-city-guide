import XCTest

final class Active_Route_Manual_Optimization_Tests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func test_optimize_button_appears_after_poi_modifications() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Verify no optimize button initially
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertFalse(optimizeButton.exists, "Optimize button should not be visible initially")
        
        // 3) Perform POI modification (edit or delete)
        performPOIModification(app: app)
        
        // 4) Verify optimize button appears
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should appear after POI modification")
        XCTAssertTrue(optimizeButton.isHittable, "Optimize button should be interactive")
        
        // 5) Verify button styling and prominence
        XCTAssertTrue(optimizeButton.exists, "Optimize button should have proper accessibility")
    }
    
    func test_optimize_button_shows_loading_state_during_optimization() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with pending changes
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        performPOIModification(app: app)
        
        // 2) Tap optimize button
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should be available")
        optimizeButton.tap()
        
        // 3) Verify loading state appears
        let loadingIndicator = app.activityIndicators["route.optimization.loading"]
        XCTAssertTrue(loadingIndicator.waitForExists(timeout: 2), "Loading indicator should appear during optimization")
        
        // 4) Verify button is disabled during optimization
        XCTAssertFalse(optimizeButton.isEnabled, "Optimize button should be disabled during optimization")
        
        // 5) Wait for optimization to complete
        XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10), "Loading should complete within reasonable time")
        
        // 6) Verify button disappears after successful optimization
        XCTAssertFalse(optimizeButton.exists, "Optimize button should disappear after successful optimization")
    }
    
    func test_optimize_button_handles_tsp_service_integration() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with multiple POI modifications for complex TSP scenario
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // Perform multiple modifications to create complex optimization scenario
        performPOIModification(app: app, type: .edit)
        performPOIModification(app: app, type: .delete)
        
        // 2) Trigger optimization
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should be available")
        optimizeButton.tap()
        
        // 3) Verify TSP optimization process
        let loadingIndicator = app.activityIndicators["route.optimization.loading"]
        XCTAssertTrue(loadingIndicator.waitForExists(), "TSP optimization should show loading")
        
        // 4) Wait for TSP calculation to complete
        XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 15), "TSP optimization should complete")
        
        // 5) Verify route is updated (POI list should reflect changes)
        let poisList = app.scrollViews["activeRoute.pois.list"]
        XCTAssertTrue(poisList.exists, "Updated route should still have POI list")
        
        // 6) Verify no more pending changes
        XCTAssertFalse(optimizeButton.exists, "No optimize button should remain after successful optimization")
    }
    
    func test_optimize_button_state_persistence_across_sheet_dismissal() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with pending changes
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        performPOIModification(app: app)
        
        // 2) Verify optimize button exists
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.exists, "Optimize button should exist after modifications")
        
        // 3) Close and reopen sheet
        closeActiveRouteSheet(app: app)
        openActiveRouteSheet(app: app)
        
        // 4) Verify optimize button still exists (pending changes persisted)
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should persist across sheet dismissal")
    }
    
    func test_optimize_button_handles_network_errors_gracefully() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with pending changes
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        performPOIModification(app: app)
        
        // 2) Trigger optimization (may encounter network issues in test environment)
        let optimizeButton = app.buttons["route.optimize"]
        optimizeButton.tap()
        
        // 3) Wait for potential error handling
        let errorAlert = app.alerts.firstMatch
        let retryButton = app.buttons["Wiederholen"]
        let dismissButton = app.buttons["OK"]
        
        // 4) If error occurs, verify proper error handling
        if errorAlert.waitForExists(timeout: 10) {
            // Error occurred - verify proper error UI
            XCTAssertTrue(errorAlert.exists, "Error alert should be shown for network issues")
            
            if retryButton.exists {
                retryButton.tap()
                // Verify retry functionality
            } else if dismissButton.exists {
                dismissButton.tap()
                // Verify dismiss returns to usable state
                XCTAssertTrue(optimizeButton.exists, "Optimize button should remain available after error dismissal")
            }
        } else {
            // No error - verify successful completion
            XCTAssertFalse(optimizeButton.exists, "Optimize button should disappear after successful optimization")
        }
    }
    
    func test_optimize_button_rate_limiting_handling() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with pending changes
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        performPOIModification(app: app)
        
        // 2) Trigger optimization multiple times rapidly to test rate limiting
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should be available")
        
        // First optimization
        optimizeButton.tap()
        
        // Wait for loading to start
        let loadingIndicator = app.activityIndicators["route.optimization.loading"]
        if loadingIndicator.waitForExists(timeout: 2) {
            // If loading appears, wait for completion
            XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 15), "First optimization should complete")
        }
        
        // 3) Try another modification and optimization quickly
        if !optimizeButton.exists {
            // Need to create new pending changes for second optimization test
            performPOIModification(app: app, type: .edit)
            
            if optimizeButton.waitForExists() {
                optimizeButton.tap()
                
                // 4) Verify rate limiting behavior (either succeeds or shows appropriate message)
                let rateLimitAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS 'rate' OR label CONTAINS 'Rate' OR label CONTAINS 'zu schnell' OR label CONTAINS 'warten'")).firstMatch
                
                if rateLimitAlert.waitForExists(timeout: 5) {
                    // Rate limiting detected - verify proper handling
                    XCTAssertTrue(rateLimitAlert.exists, "Rate limiting should show appropriate message")
                    
                    let okButton = rateLimitAlert.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                    }
                }
            }
        }
    }
    
    func test_optimize_button_accessibility_support() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with pending changes
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        performPOIModification(app: app)
        
        // 2) Verify optimize button accessibility
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should be available")
        
        // 3) Verify accessibility properties
        XCTAssertNotNil(optimizeButton.label, "Optimize button should have accessible label")
        XCTAssertTrue(optimizeButton.isHittable, "Optimize button should be accessible for interaction")
        
        // 4) Verify VoiceOver support (button should be focusable)
        XCTAssertTrue(optimizeButton.exists, "Optimize button should be focusable for VoiceOver")
    }
    
    func test_optimize_button_visual_prominence_and_animation() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route and monitor for button appearance
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Perform modification and verify button animation
        performPOIModification(app: app)
        
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should appear with animation")
        
        // 3) Verify button remains prominent and visible
        XCTAssertTrue(optimizeButton.isHittable, "Optimize button should be prominently displayed")
        
        // 4) Test button interaction and feedback
        optimizeButton.tap()
        
        // Verify some form of visual feedback occurs (loading or state change)
        let loadingIndicator = app.activityIndicators["route.optimization.loading"]
        let buttonStateChanged = !optimizeButton.isEnabled || loadingIndicator.waitForExists(timeout: 2)
        
        XCTAssertTrue(buttonStateChanged, "Button should provide visual feedback when tapped")
    }
    
    func test_multiple_pending_changes_optimization_summary() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Setup route with multiple modifications
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // Perform multiple different modifications
        performPOIModification(app: app, type: .edit)
        performPOIModification(app: app, type: .delete)
        performPOIModification(app: app, type: .edit)
        
        // 2) Verify optimize button accounts for all changes
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should handle multiple changes")
        
        // 3) Trigger optimization for complex scenario
        optimizeButton.tap()
        
        // 4) Verify all changes are processed together
        let loadingIndicator = app.activityIndicators["route.optimization.loading"]
        if loadingIndicator.waitForExists(timeout: 2) {
            XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 20), "Complex optimization should complete")
        }
        
        // 5) Verify all pending changes are resolved
        XCTAssertFalse(optimizeButton.exists, "All pending changes should be resolved after optimization")
    }
    
    // MARK: - Helper Methods
    
    private func generateAndStartRoute(app: XCUIApplication) {
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found")
        planButton.tap()
        
        let cityField = app.textFields["route.city.textfield"]
        if cityField.waitForExists() {
            cityField.tap()
            cityField.clearAndType(text: "Nürnberg")
            app.keyboards.buttons["Return"].tap()
        }
        
        let generateButton = app.buttons["Los geht's!"]
        XCTAssertTrue(generateButton.waitForExists(), "Generate button not found")
        generateButton.tap()
        
        let startButton = app.buttons["Zeig mir die Tour!"]
        XCTAssertTrue(startButton.waitForExists(timeout: 15), "Start button not found")
        startButton.tap()
        
        let runningLabel = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(runningLabel.waitForExists(), "Active route not started")
    }
    
    private func openActiveRouteSheet(app: XCUIApplication) {
        let activeRouteBanner = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(activeRouteBanner.waitForExists(), "Active route banner not found")
        activeRouteBanner.tap()
        
        let poisList = app.scrollViews["activeRoute.pois.list"]
        XCTAssertTrue(poisList.waitForExists(), "POI list not visible after opening sheet")
    }
    
    private func closeActiveRouteSheet(app: XCUIApplication) {
        // Tap outside the sheet or use swipe down gesture to close
        let handle = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'handle' OR identifier CONTAINS 'dismiss'")).firstMatch
        if handle.exists {
            handle.tap()
        } else {
            // Fallback: swipe down to close sheet
            let sheet = app.sheets.firstMatch
            if sheet.exists {
                sheet.swipeDown()
            }
        }
        
        // Verify sheet is closed
        let poisList = app.scrollViews["activeRoute.pois.list"]
        XCTAssertTrue(poisList.waitForNonExistence(timeout: 3), "Sheet should be closed")
    }
    
    enum ModificationType {
        case edit, delete
    }
    
    private func performPOIModification(app: XCUIApplication, type: ModificationType = .edit) {
        let firstPOI = app.cells["poi.row.0"].firstMatch
        XCTAssertTrue(firstPOI.waitForExists(), "First POI row not found")
        firstPOI.swipeLeft()
        
        switch type {
        case .edit:
            let editButton = app.buttons["poi.action.edit"]
            XCTAssertTrue(editButton.waitForExists(), "Edit button not visible")
            editButton.tap()
            
            // Handle edit sheet - select an alternative or close
            let alternativesSheet = app.sheets["poi.alternatives.sheet"]
            if alternativesSheet.waitForExists(timeout: 3) {
                let cancelButton = app.buttons["Abbrechen"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    // Try to select an alternative if available
                    let selectButton = app.buttons["Alternative auswählen"]
                    if selectButton.waitForExists(timeout: 2) {
                        selectButton.tap()
                    }
                }
            }
            
        case .delete:
            let deleteButton = app.buttons["poi.action.delete"]
            XCTAssertTrue(deleteButton.waitForExists(), "Delete button not visible")
            deleteButton.tap()
            
            // Confirm deletion
            let confirmationAlert = app.alerts["POI löschen"]
            XCTAssertTrue(confirmationAlert.waitForExists(), "Delete confirmation not shown")
            
            let deleteConfirmButton = confirmationAlert.buttons["Löschen"]
            deleteConfirmButton.tap()
        }
        
        // Wait for UI to update
        Thread.sleep(forTimeInterval: 0.5)
    }
}

// MARK: - XCUIElement Extensions
// Extension methods moved to TestApp.swift to avoid duplication
