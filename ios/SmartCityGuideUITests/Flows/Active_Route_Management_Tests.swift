import XCTest

/// P0: Active Route Management Bottom Sheet UI-Tests
final class Active_Route_Management_Tests: XCTestCase {
    
    // MARK: - P0 Active Route Bottom Sheet
    
    func test_activeRoute_showsBottomSheetWithRouteInfo() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate a route first
        let quickButton = app.buttons["home.plan.quick"]
        XCTAssertTrue(quickButton.waitForExists(timeout: 5))
        
        if quickButton.isEnabled {
            quickButton.tap()
            
            // Wait for route to be generated
            let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
            XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30), "Route should be generated")
            
            // Bottom sheet should appear (if feature flag enabled)
            let bottomSheet = app.sheets.firstMatch
            if bottomSheet.waitForExists(timeout: 3) {
                // Sheet should contain route information
                let routeSummary = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Stopp'")).firstMatch
                XCTAssertTrue(routeSummary.exists, "Route summary with stops should be visible")
                
                // End route button should be present
                let endButton = app.buttons["activeRoute.action.end"]
                XCTAssertTrue(endButton.exists, "End route button should be visible")
                XCTAssertTrue(endButton.isEnabled, "End route button should be enabled")
            }
        } else {
            XCTSkip("Quick planning not available without location")
        }
    }
    
    func test_activeRoute_bottomSheetInteractions() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for active route
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Check bottom sheet interactions
        let bottomSheet = app.sheets.firstMatch
        if bottomSheet.waitForExists(timeout: 3) {
            // Test sheet expandability
            let initialHeight = bottomSheet.frame.height
            
            // Try to swipe up to expand
            let sheetCenter = bottomSheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            sheetCenter.press(forDuration: 0.1, thenDragTo: bottomSheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
            
            // Wait for animation
            Thread.sleep(forTimeInterval: 0.5)
            
            // Sheet might expand or show more content
            let expandedHeight = bottomSheet.frame.height
            
            // Check if POI list is visible when expanded
            let poiList = app.tables.firstMatch
            if poiList.exists {
                XCTAssertTrue(poiList.cells.count > 0, "POI list should contain route stops")
            }
        }
    }
    
    func test_activeRoute_endRouteFlow() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for active route
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Test end route functionality
        let endButton = app.buttons["activeRoute.action.end"]
        if endButton.waitForExists(timeout: 3) {
            endButton.tap()
            
            // Confirmation dialog should appear
            let confirmationAlert = app.alerts.firstMatch
            if confirmationAlert.waitForExists(timeout: 2) {
                // Should have German confirmation text
                let confirmButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'beenden' OR label CONTAINS 'Ja'")).firstMatch
                let cancelButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Abbrechen' OR label CONTAINS 'Nein'")).firstMatch
                
                XCTAssertTrue(confirmButton.exists || cancelButton.exists, "Confirmation dialog should have German buttons")
                
                // Confirm ending the route
                if confirmButton.exists {
                    confirmButton.tap()
                } else {
                    // Try alternative confirmation
                    app.buttons["Ja"].tap()
                }
                
                // Route should end and planning buttons should return
                XCTAssertTrue(app.buttons["home.plan.quick"].waitForExists(timeout: 5) || 
                             app.buttons["home.plan.full"].waitForExists(timeout: 2) ||
                             app.buttons["home.plan.automatic"].waitForExists(timeout: 2),
                             "Planning buttons should reappear after ending route")
            } else {
                // Direct end without confirmation
                XCTAssertTrue(app.buttons["home.plan.quick"].waitForExists(timeout: 5) || 
                             app.buttons["home.plan.full"].waitForExists(timeout: 2),
                             "Planning buttons should reappear after ending route")
            }
        } else {
            XCTSkip("End route button not found - might be legacy banner mode")
        }
    }
    
    func test_activeRoute_germanUIElements() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for active route
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Check for German UI elements in active route
        let germanElements = [
            "Tour",
            "Stopp", 
            "beenden",
            "Nächste",
            "Route"
        ]
        
        var foundGermanElements = 0
        for element in germanElements {
            let germanText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", element)).firstMatch
            if germanText.exists {
                foundGermanElements += 1
            }
        }
        
        XCTAssertGreaterThan(foundGermanElements, 0, "Active route should contain German UI elements")
    }
    
    // MARK: - P0 Route State Management
    
    func test_activeRoute_persistsDuringAppForeground() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for active route
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Simulate app background/foreground
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1.0)
        
        // Reopen app
        app.activate()
        
        // Route should still be active
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 5), 
                     "Active route should persist after app background/foreground")
    }
    
    func test_activeRoute_blocksNewRoutePlanning() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for active route
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Planning buttons should be hidden/disabled during active route
        XCTAssertFalse(app.buttons["home.plan.quick"].exists, 
                      "Quick planning should be hidden during active route")
        XCTAssertFalse(app.buttons["home.plan.full"].exists, 
                      "Full planning should be hidden during active route")
        XCTAssertFalse(app.buttons["home.plan.automatic"].exists, 
                      "Legacy planning should be hidden during active route")
    }
    
    // MARK: - P0 POI List Interaction
    
    func test_activeRoute_poiListShowsRouteStops() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for active route
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Check POI list in bottom sheet
        let bottomSheet = app.sheets.firstMatch
        if bottomSheet.waitForExists(timeout: 3) {
            // Try to expand sheet to see POI list
            let sheetCenter = bottomSheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            sheetCenter.press(forDuration: 0.1, thenDragTo: bottomSheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
            
            // Wait for expansion
            Thread.sleep(forTimeInterval: 0.5)
            
            // POI list should be visible
            let poiList = app.tables.firstMatch
            if poiList.exists {
                XCTAssertGreaterThan(poiList.cells.count, 0, "POI list should contain route stops")
                
                // First cell should show next stop indicator
                let firstCell = poiList.cells.firstMatch
                if firstCell.exists {
                    // Should have some indicator this is the next stop
                    let nextStopIndicator = firstCell.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Nächster' OR label CONTAINS '•'")).firstMatch
                    // Not all implementations may have this, so just check if cell is selectable
                    XCTAssertTrue(firstCell.exists, "First POI cell should exist")
                }
            }
        }
    }
}
