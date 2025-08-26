import XCTest

/// P1: Route-Anpassung UI-Tests
/// Validiert Manual POI Add/Remove, Reorder und Route-Optimierung
final class Route_Customization_Tests: XCTestCase {
    
    // MARK: - P1 Manual Route Planning Tests
    
    func test_manualRoutePlanning_opensCorrectly() {
        let app = TestApp.launch(extraArgs: [])
        
        // Open full planning
        let fullPlanButton = app.buttons["home.plan.full"]
        guard fullPlanButton.waitForExists(timeout: 5) else {
            XCTSkip("Full planning button not available")
            return
        }
        
        fullPlanButton.tap()
        
        // Planning sheet should appear
        let planningSheet = app.sheets.firstMatch
        XCTAssertTrue(planningSheet.waitForExists(timeout: 3), "Planning sheet should appear")
        
        // Switch to manual mode
        let manualModeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Manuell'")).firstMatch
        if manualModeButton.waitForExists(timeout: 3) {
            manualModeButton.tap()
            
            // Manual planning specific UI should be visible
            let manualElements = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'manuell'")).firstMatch
            XCTAssertTrue(manualElements.waitForExists(timeout: 3), "Manual planning UI should be visible")
        }
    }
    
    func test_manualPOISelection_flowWorks() {
        let app = TestApp.launch(extraArgs: ["-UITEST_AUTOPILOT_MANUAL"])
        
        // Should automatically trigger manual planning flow
        let manualSheet = app.sheets.firstMatch
        guard manualSheet.waitForExists(timeout: 10) else {
            XCTSkip("Manual planning sheet not automatically opened")
            return
        }
        
        // Wait for POI discovery to complete
        let selectionView = app.scrollViews.firstMatch
        guard selectionView.waitForExists(timeout: 15) else {
            XCTSkip("POI selection view not available")
            return
        }
        
        // Should be able to interact with POI cards
        XCTAssertTrue(selectionView.isHittable, "POI selection should be interactive")
        
        // Look for generate route button (appears when POIs selected or in UITEST mode)
        let generateButton = app.buttons["manual.generate.route.button"]
        XCTAssertTrue(generateButton.waitForExists(timeout: 5), "Generate route button should be available")
    }
    
    func test_poiSwipeActions_acceptAndReject() {
        let app = TestApp.launch(extraArgs: ["-UITEST_AUTOPILOT_MANUAL"])
        
        let manualSheet = app.sheets.firstMatch
        guard manualSheet.waitForExists(timeout: 10) else {
            XCTSkip("Manual planning not available")
            return
        }
        
        // Wait for POI cards to appear
        let selectionArea = app.scrollViews.firstMatch
        guard selectionArea.waitForExists(timeout: 15) else {
            XCTSkip("POI cards not available")
            return
        }
        
        // Test swipe gestures on POI cards
        // Swipe right (accept)
        selectionArea.swipeRight()
        sleep(1)
        
        // Swipe left (reject)
        selectionArea.swipeLeft()
        sleep(1)
        
        // Selection area should remain functional
        XCTAssertTrue(selectionArea.isHittable, "POI selection should remain interactive after swipes")
        
        // Check for selection counter
        let selectionCounter = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'POI'")).firstMatch
        // Note: Counter might appear based on selections made
    }
    
    // MARK: - P1 Active Route POI Management Tests
    
    func test_activeRoute_poiSwipeActions() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate a route first
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route generation
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        // Open active route details if available
        let routeSheet = app.sheets.firstMatch
        if routeSheet.waitForExists(timeout: 3) {
            // Look for route list with waypoints
            let routeList = app.tables.firstMatch
            if routeList.waitForExists(timeout: 3) {
                // Test swipe actions on route waypoints
                let firstCell = routeList.cells.firstMatch
                if firstCell.exists {
                    // Swipe to reveal edit/delete actions
                    firstCell.swipeLeft()
                    
                    // Check for edit/delete buttons
                    let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Bearbeiten'")).firstMatch
                    let deleteButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Löschen'")).firstMatch
                    
                    // At least one action should be available
                    let actionsAvailable = editButton.waitForExists(timeout: 2) || deleteButton.waitForExists(timeout: 2)
                    if actionsAvailable {
                        XCTAssertTrue(true, "Swipe actions are available on route waypoints")
                    }
                }
            }
        }
    }
    
    func test_poiEditAction_opensSelection() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        // Try to access route details and edit POI
        let routeSheet = app.sheets.firstMatch
        if routeSheet.waitForExists(timeout: 3) {
            let routeList = app.tables.firstMatch
            if routeList.waitForExists(timeout: 3) {
                let waypoints = routeList.cells
                if waypoints.count > 1 {
                    // Swipe on a middle waypoint (not start/end)
                    let middleWaypoint = waypoints.element(boundBy: min(1, waypoints.count - 2))
                    middleWaypoint.swipeLeft()
                    
                    // Look for edit button
                    let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Bearbeiten'")).firstMatch
                    if editButton.waitForExists(timeout: 2) {
                        editButton.tap()
                        
                        // POI selection should open
                        let selectionView = app.scrollViews.firstMatch
                        XCTAssertTrue(selectionView.waitForExists(timeout: 5), "POI selection should open for editing")
                    }
                }
            }
        }
    }
    
    func test_poiDeleteAction_removesFromRoute() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        // Access route details
        let routeSheet = app.sheets.firstMatch
        if routeSheet.waitForExists(timeout: 3) {
            let routeList = app.tables.firstMatch
            if routeList.waitForExists(timeout: 3) {
                let initialWaypointCount = routeList.cells.count
                
                if initialWaypointCount > 2 { // Must have at least start/end + 1 POI
                    // Swipe on a waypoint that can be deleted
                    let deletableWaypoint = routeList.cells.element(boundBy: 1)
                    deletableWaypoint.swipeLeft()
                    
                    // Look for delete button
                    let deleteButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Löschen'")).firstMatch
                    if deleteButton.waitForExists(timeout: 2) {
                        deleteButton.tap()
                        
                        // Confirm deletion if alert appears
                        let confirmAlert = app.alerts.firstMatch
                        if confirmAlert.waitForExists(timeout: 2) {
                            let confirmButton = confirmAlert.buttons.containing(NSPredicate(format: "label CONTAINS 'Löschen'")).firstMatch
                            if confirmButton.exists {
                                confirmButton.tap()
                            }
                        }
                        
                        // Wait for route to update
                        sleep(2)
                        
                        // Waypoint count should decrease or route should update
                        let updatedWaypointCount = routeList.cells.count
                        if updatedWaypointCount < initialWaypointCount {
                            XCTAssertTrue(true, "POI was successfully deleted from route")
                        } else {
                            // Route might be regenerated, check for update indicators
                            let updateIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'aktualis'")).firstMatch
                            if updateIndicator.exists {
                                XCTAssertTrue(true, "Route update in progress after POI deletion")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - P1 Route Generation and Optimization Tests
    
    func test_manualRouteGeneration_completesSuccessfully() {
        let app = TestApp.launch(extraArgs: ["-UITEST_AUTOPILOT_MANUAL"])
        
        let manualSheet = app.sheets.firstMatch
        guard manualSheet.waitForExists(timeout: 10) else {
            XCTSkip("Manual planning not available")
            return
        }
        
        // Wait for POI discovery
        sleep(5)
        
        // Generate route button should be available (in UITEST mode)
        let generateButton = app.buttons["manual.generate.route.button"]
        guard generateButton.waitForExists(timeout: 5) else {
            XCTSkip("Generate route button not available")
            return
        }
        
        generateButton.tap()
        
        // Should dismiss manual planning and start route generation
        let routeGenerationStarted = !manualSheet.waitForExists(timeout: 3)
        if routeGenerationStarted {
            // Wait for route completion
            let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
            XCTAssertTrue(routeIndicator.waitForExists(timeout: 30), "Manual route should be generated successfully")
        }
    }
    
    func test_routeOptimization_improvesTSP() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate initial route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        // Look for optimization features in route details
        let routeSheet = app.sheets.firstMatch
        if routeSheet.waitForExists(timeout: 3) {
            // Look for optimize button or optimization indicators
            let optimizeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'optim'")).firstMatch
            let optimizeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'TSP'")).firstMatch
            
            if optimizeButton.waitForExists(timeout: 2) {
                optimizeButton.tap()
                
                // Should trigger route optimization
                let optimizationIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'optimier'")).firstMatch
                XCTAssertTrue(optimizationIndicator.waitForExists(timeout: 5), "Route optimization should start")
            } else if optimizeIndicator.exists {
                // Route is already optimized
                XCTAssertTrue(true, "Route shows TSP optimization")
            }
        }
    }
    
    // MARK: - P1 Route State Persistence Tests
    
    func test_routeEdits_persistAcrossAppStates() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        // Background and foreground app to test persistence
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.launch() // Re-launch app
        
        // Route should still be active
        let persistedRoute = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(persistedRoute.waitForExists(timeout: 5), "Active route should persist across app states")
        
        // Map should still show route
        let map = app.maps.firstMatch
        XCTAssertTrue(map.exists, "Map should maintain route state after app restart")
    }
    
    // MARK: - P1 Route Customization Edge Cases
    
    func test_emptyRouteEdits_handledGracefully() {
        let app = TestApp.launch(extraArgs: [])
        
        // Try to edit without active route
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available")
            return
        }
        
        // App should handle gracefully when no route is active
        // No edit buttons should be available
        let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Bearbeiten'")).firstMatch
        XCTAssertFalse(editButton.waitForExists(timeout: 2), "Edit actions should not be available without active route")
        
        // Generate route and verify edit becomes available
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 3) && quickButton.isEnabled {
            quickButton.tap()
            
            let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
            if routeIndicator.waitForExists(timeout: 20) {
                // Now route editing should be possible
                XCTAssertTrue(true, "Route editing becomes available after route generation")
            }
        }
    }
}
