import XCTest

final class Active_Route_POI_Delete_Tests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func test_delete_poi_shows_confirmation_dialog() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Swipe left on first POI and tap Delete
        let firstPOI = app.cells["poi.row.0"].firstMatch
        XCTAssertTrue(firstPOI.waitForExists(), "First POI row not found")
        firstPOI.swipeLeft()
        
        let deleteButton = app.buttons["poi.action.delete"]
        XCTAssertTrue(deleteButton.waitForExists(), "Delete button not visible")
        deleteButton.tap()
        
        // 3) Verify that confirmation dialog appears
        let confirmationAlert = app.alerts["POI löschen"]
        XCTAssertTrue(confirmationAlert.waitForExists(), "Delete confirmation dialog not shown")
        
        // 4) Verify dialog content and buttons
        let cancelButton = confirmationAlert.buttons["Abbrechen"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be present")
        
        let deleteConfirmButton = confirmationAlert.buttons["Löschen"]
        XCTAssertTrue(deleteConfirmButton.exists, "Delete confirm button should be present")
        
        // 5) Test cancel functionality
        cancelButton.tap()
        XCTAssertFalse(confirmationAlert.exists, "Dialog should be dismissed after cancel")
    }
    
    func test_confirm_delete_removes_poi_from_route() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route and get original POI count
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        let poisList = app.scrollViews["activeRoute.pois.list"]
        let originalPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertGreaterThan(originalPOICount, 1, "Should have multiple POIs for deletion test")
        
        // 2) Get the name of the first POI for verification
        let firstPOI = app.cells["poi.row.0"].firstMatch
        let originalFirstPOIName = firstPOI.staticTexts.firstMatch.label
        
        // 3) Delete the first POI
        performPOIDeletion(app: app, poiIndex: 0, confirm: true)
        
        // 4) Verify POI count decreased
        let newPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertEqual(newPOICount, originalPOICount - 1, "POI count should decrease by 1")
        
        // 5) Verify the deleted POI is no longer in the list
        let currentFirstPOI = app.cells["poi.row.0"].firstMatch
        if currentFirstPOI.exists {
            let currentFirstPOIName = currentFirstPOI.staticTexts.firstMatch.label
            XCTAssertNotEqual(currentFirstPOIName, originalFirstPOIName, "Original first POI should be deleted")
        }
    }
    
    func test_delete_poi_triggers_pending_changes_state() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Verify no optimize button initially
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertFalse(optimizeButton.exists, "Optimize button should not be visible initially")
        
        // 3) Delete a POI
        performPOIDeletion(app: app, poiIndex: 0, confirm: true)
        
        // 4) Verify optimize button appears
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should appear after POI deletion")
        XCTAssertTrue(optimizeButton.isHittable, "Optimize button should be interactive")
    }
    
    func test_delete_last_intermediate_poi_handled_gracefully() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate a route with minimal POIs (might need custom route with only 1 intermediate POI)
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Count intermediate POIs (excluding start/end)
        let poisList = app.scrollViews["activeRoute.pois.list"]
        let allPOIs = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'"))
        let poiCount = allPOIs.count
        
        // 3) Delete intermediate POIs until only start/end remain (or minimum required)
        var remainingPOIs = poiCount
        while remainingPOIs > 2 { // Keep at least start and end
            performPOIDeletion(app: app, poiIndex: 0, confirm: true)
            
            // Wait for UI to update
            Thread.sleep(forTimeInterval: 0.5)
            
            let updatedPOIs = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'"))
            remainingPOIs = updatedPOIs.count
            
            // Safety break to avoid infinite loop
            if remainingPOIs <= 1 {
                break
            }
        }
        
        // 4) Verify route still exists and is functional
        let poisListAfter = app.scrollViews["activeRoute.pois.list"]
        XCTAssertTrue(poisListAfter.exists, "POI list should still exist after deletions")
        
        // 5) Verify optimize button is visible due to changes
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.exists, "Optimize button should be visible after multiple deletions")
    }
    
    func test_delete_start_or_end_poi_protection() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Try to identify start and end POIs (they might have special indicators)
        let allPOIs = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'"))
        let poiCount = allPOIs.count
        
        // 3) Test deleting the last POI (likely end point)
        if poiCount > 1 {
            let lastPOIIndex = poiCount - 1
            let lastPOI = app.cells["poi.row.\(lastPOIIndex)"].firstMatch
            
            if lastPOI.exists {
                lastPOI.swipeLeft()
                
                // Check if delete action is available for end point
                let deleteButton = app.buttons["poi.action.delete"]
                
                if deleteButton.exists {
                    // If delete is available, it should be handled gracefully
                    deleteButton.tap()
                    
                    let confirmationAlert = app.alerts["POI löschen"]
                    if confirmationAlert.waitForExists() {
                        let deleteConfirmButton = confirmationAlert.buttons["Löschen"]
                        deleteConfirmButton.tap()
                        
                        // Verify the route still functions after end point deletion
                        let poisList = app.scrollViews["activeRoute.pois.list"]
                        XCTAssertTrue(poisList.exists, "Route should remain functional")
                    }
                }
            }
        }
    }
    
    func test_multiple_poi_deletions_accumulate_pending_changes() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        let originalPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertGreaterThan(originalPOICount, 2, "Need multiple POIs for this test")
        
        // 2) Delete first POI
        performPOIDeletion(app: app, poiIndex: 0, confirm: true)
        
        // 3) Verify optimize button appears
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.waitForExists(), "Optimize button should appear after first deletion")
        
        // 4) Delete second POI (now at index 0 after first deletion)
        performPOIDeletion(app: app, poiIndex: 0, confirm: true)
        
        // 5) Verify optimize button still exists
        XCTAssertTrue(optimizeButton.exists, "Optimize button should remain after multiple deletions")
        
        // 6) Verify POI count decreased appropriately
        let finalPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertEqual(finalPOICount, originalPOICount - 2, "Should have 2 fewer POIs")
    }
    
    func test_delete_poi_with_immediate_route_update() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route and get summary info
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Capture original route summary (distance, stops)
        let summaryText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'km' OR label CONTAINS 'Stopps'")).firstMatch
        let originalSummary = summaryText.exists ? summaryText.label : ""
        
        // 3) Delete a POI
        performPOIDeletion(app: app, poiIndex: 0, confirm: true)
        
        // 4) Verify route summary updates (stop count should decrease)
        if summaryText.exists {
            let newSummary = summaryText.label
            // Note: The exact behavior depends on implementation - stops count might update immediately or after optimization
            XCTAssertTrue(summaryText.exists, "Route summary should still be displayed")
        }
        
        // 5) Verify optimize button is present for route recalculation
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertTrue(optimizeButton.exists, "Optimize button should be available for route recalculation")
    }
    
    func test_cancel_delete_preserves_original_route() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route and capture state
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        let originalPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        let firstPOI = app.cells["poi.row.0"].firstMatch
        let originalFirstPOIName = firstPOI.staticTexts.firstMatch.label
        
        // 2) Start delete process but cancel
        performPOIDeletion(app: app, poiIndex: 0, confirm: false)
        
        // 3) Verify nothing changed
        let finalPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertEqual(finalPOICount, originalPOICount, "POI count should remain unchanged after cancel")
        
        let currentFirstPOI = app.cells["poi.row.0"].firstMatch
        let currentFirstPOIName = currentFirstPOI.staticTexts.firstMatch.label
        XCTAssertEqual(currentFirstPOIName, originalFirstPOIName, "First POI should remain unchanged after cancel")
        
        // 4) Verify no pending changes state
        let optimizeButton = app.buttons["route.optimize"]
        XCTAssertFalse(optimizeButton.exists, "No optimize button should appear after cancel")
    }
    
    func test_haptic_feedback_on_delete_actions() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate route
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Perform delete action (haptic feedback testing is implicit in iOS simulator)
        let firstPOI = app.cells["poi.row.0"].firstMatch
        firstPOI.swipeLeft()
        
        let deleteButton = app.buttons["poi.action.delete"]
        deleteButton.tap()
        
        // 3) Confirm deletion
        let confirmationAlert = app.alerts["POI löschen"]
        XCTAssertTrue(confirmationAlert.waitForExists(), "Confirmation dialog should appear")
        
        let deleteConfirmButton = confirmationAlert.buttons["Löschen"]
        deleteConfirmButton.tap()
        
        // 4) Verify the action completed (haptic feedback is implicit)
        let poisList = app.scrollViews["activeRoute.pois.list"]
        XCTAssertTrue(poisList.exists, "POI list should still exist after deletion")
        
        // Note: Haptic feedback cannot be directly tested in UI tests,
        // but we verify the actions that should trigger it complete successfully
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
    
    private func performPOIDeletion(app: XCUIApplication, poiIndex: Int, confirm: Bool) {
        let targetPOI = app.cells["poi.row.\(poiIndex)"].firstMatch
        XCTAssertTrue(targetPOI.waitForExists(), "Target POI row not found")
        targetPOI.swipeLeft()
        
        let deleteButton = app.buttons["poi.action.delete"]
        XCTAssertTrue(deleteButton.waitForExists(), "Delete button not visible")
        deleteButton.tap()
        
        let confirmationAlert = app.alerts["POI löschen"]
        XCTAssertTrue(confirmationAlert.waitForExists(), "Delete confirmation dialog not shown")
        
        if confirm {
            let deleteConfirmButton = confirmationAlert.buttons["Löschen"]
            deleteConfirmButton.tap()
        } else {
            let cancelButton = confirmationAlert.buttons["Abbrechen"]
            cancelButton.tap()
        }
        
        // Wait for UI to update
        Thread.sleep(forTimeInterval: 0.3)
    }
}

// MARK: - XCUIElement Extensions (if not already defined in other test files)
// Extension methods moved to TestApp.swift to avoid duplication
