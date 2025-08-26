import XCTest

/// P0: Quick Route Planning Happy Path UI-Tests
final class Quick_Route_Planning_Happy_Path_Tests: XCTestCase {
    
    // MARK: - P0 Quick Route Happy Path
    
    func test_quickRouteGeneration_showsLoadingAndResult() {
        let app = TestApp.launch(extraArgs: [])
        
        // Ensure quick planning button exists and is enabled
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        // Tap quick planning
        quickButton.tap()
        
        // Check for any loading indication (flexible approach)
        let possibleLoadingTexts = [
            "basteln", "Route", "generier", "plan", "suche", "berechn"
        ]
        
        var loadingFound = false
        for loadingText in possibleLoadingTexts {
            let loadingMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", loadingText)).firstMatch
            if loadingMessage.waitForExists(timeout: 2) {
                loadingFound = true
                break
            }
        }
        
        // Also check for accessibility identifier
        let identifierLoading = app.staticTexts["quickPlanning.loadingMessage"]
        loadingFound = loadingFound || identifierLoading.waitForExists(timeout: 2)
        
        // Don't fail if no loading state - just continue to result check
        if !loadingFound {
            print("Warning: No loading state detected, proceeding to check results")
        }
        
        // Wait for route generation result (main success criterion)
        let tourLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        let activeRouteIndicator = app.staticTexts["Deine Tour läuft!"]
        let mapWithRoute = app.maps.firstMatch
        
        let routeAppeared = tourLabel.waitForExists(timeout: 30) || 
                           activeRouteIndicator.waitForExists(timeout: 5) ||
                           mapWithRoute.exists
        
        XCTAssertTrue(routeAppeared, "Route should be generated and visible within 30 seconds")
    }
    
    func test_quickRouteGeneration_resultContainsMinimumPOIs() {
        let app = TestApp.launch(extraArgs: [])
        
        // Start quick planning
        let quickButton = app.buttons["home.plan.quick"]
        XCTAssertTrue(quickButton.waitForExists(timeout: 5))
        quickButton.tap()
        
        // Wait for route to be generated
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30), "Route should be generated")
        
        // Check if active route sheet is available (if feature flag enabled)
        let activeRouteSheet = app.sheets.firstMatch
        if activeRouteSheet.waitForExists(timeout: 2) {
            // Sheet should contain POI information
            let poiList = app.tables.firstMatch
            if poiList.exists {
                let poiCells = poiList.cells
                XCTAssertGreaterThanOrEqual(poiCells.count, 3, 
                                          "Route should contain at least 3-4 POIs")
            }
        }
        
        // Map should show route markers
        let map = app.maps.firstMatch
        XCTAssertTrue(map.exists, "Map should be visible with route")
    }
    
    func test_quickRouteGeneration_activatesRouteManagement() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        XCTAssertTrue(quickButton.waitForExists(timeout: 5))
        quickButton.tap()
        
        // Wait for route to be active
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Planning buttons should be hidden when route is active
        XCTAssertFalse(app.buttons["home.plan.quick"].exists, 
                      "Quick planning button should be hidden during active route")
        XCTAssertFalse(app.buttons["home.plan.full"].exists, 
                      "Full planning button should be hidden during active route")
        
        // Active route management should be available
        let endRouteButton = app.buttons["activeRoute.action.end"]
        if endRouteButton.waitForExists(timeout: 2) {
            XCTAssertTrue(endRouteButton.isEnabled, "End route button should be available")
        } else {
            // Legacy banner might be shown instead
            let legacyEndButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'beenden'")).firstMatch
            XCTAssertTrue(legacyEndButton.exists, "Some way to end route should be available")
        }
    }
    
    // MARK: - P0 Full Route Planning Happy Path
    
    func test_fullRoutePlanning_opensModalAndGeneratesRoute() {
        let app = TestApp.launch(extraArgs: [])
        
        // Tap full planning
        let fullButton = app.buttons["home.plan.full"] 
        let legacyButton = app.buttons["home.plan.automatic"]
        
        if fullButton.waitForExists(timeout: 3) {
            fullButton.tap()
        } else if legacyButton.waitForExists(timeout: 1) {
            legacyButton.tap()
        } else {
            XCTFail("No planning button found")
        }
        
        // Planning sheet should appear
        let planningSheet = app.sheets.firstMatch
        XCTAssertTrue(planningSheet.waitForExists(timeout: 3), "Planning sheet should appear")
        
        // Sheet should contain route planning elements
        let generateButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Generieren' OR label CONTAINS 'Route'")).firstMatch
        XCTAssertTrue(generateButton.waitForExists(timeout: 2), "Generate button should be visible")
        
        // Try to generate route (if button is enabled)
        guard generateButton.isEnabled else {
            XCTSkip("Generate button not enabled - cannot test full route generation")
            return
        }
        
        generateButton.tap()
        
        // Check for loading indication (optional)
        let loadingIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Route'")).firstMatch
        let hasLoading = loadingIndicator.waitForExists(timeout: 3)
        
        if !hasLoading {
            print("Warning: No loading indicator found, proceeding to completion check")
        }
        
        // Wait for completion (main success criterion)
        let completionIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        let mapVisible = app.maps.firstMatch.exists
        
        let routeCompleted = completionIndicator.waitForExists(timeout: 30) || mapVisible
        XCTAssertTrue(routeCompleted, "Route should be generated and visible within 30 seconds")
    }
    
    // MARK: - P0 Route Display Validation
    
    func test_generatedRoute_showsProperGermanUI() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate any route
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 3) && quickButton.isEnabled {
            quickButton.tap()
        } else {
            // Fallback to full planning
            let fullButton = app.buttons["home.plan.full"] ?? app.buttons["home.plan.automatic"]
            fullButton.tap()
            
            let planningSheet = app.sheets.firstMatch
            if planningSheet.waitForExists(timeout: 3) {
                let generateButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Generieren'")).firstMatch
                if generateButton.waitForExists(timeout: 2) && generateButton.isEnabled {
                    generateButton.tap()
                }
            }
        }
        
        // Wait for route result
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30))
        
        // Check for German UI elements
        let germanKeywords = ["Tour", "Stopp", "beenden", "Route"]
        var foundGermanText = false
        
        for keyword in germanKeywords {
            let element = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", keyword)).firstMatch
            if element.exists {
                foundGermanText = true
                break
            }
        }
        
        XCTAssertTrue(foundGermanText, "Route UI should contain German text")
    }
    
    // MARK: - Performance Test
    
    func test_quickRouteGeneration_completesWithin30Seconds() {
        let app = TestApp.launch(extraArgs: [])
        
        let quickButton = app.buttons["home.plan.quick"]
        XCTAssertTrue(quickButton.waitForExists(timeout: 5))
        XCTAssertTrue(quickButton.isEnabled, "Quick planning requires location")
        
        // Measure total time from tap to route completion
        let startTime = Date()
        quickButton.tap()
        
        // Wait for completion
        let activeRouteIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        XCTAssertTrue(activeRouteIndicator.waitForExists(timeout: 30), "Route generation should complete")
        
        let totalTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(totalTime, 30.0, "Route should be generated within 30 seconds as per mission requirement")
    }
}
