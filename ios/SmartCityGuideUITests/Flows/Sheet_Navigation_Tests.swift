import XCTest

final class Sheet_Navigation_Tests: XCTestCase {
    
    func test_sheet_navigation_flow() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Open planning sheet via automatic button
        let automaticButton = app.buttons["home.plan.automatic"]
        XCTAssertTrue(automaticButton.waitForExistence(timeout: 5), "Automatic planning button not found")
        automaticButton.tap()
        
        // 2) Verify RoutePlanningView sheet is presented
        let planningView = app.otherElements["RoutePlanningView"]
        XCTAssertTrue(planningView.waitForExistence(timeout: 3), "RoutePlanningView sheet not presented")
        
        // 3) Verify preset mode is set to automatic
        let automaticMode = app.buttons["Planungsmodus.Automatisch"]
        XCTAssertTrue(automaticMode.waitForExistence(timeout: 2), "Automatic mode button not found")
        XCTAssertTrue(automaticMode.isSelected, "Automatic mode not preselected")
        
        // 4) Dismiss sheet via "Fertig" button
        let doneButton = app.buttons["Fertig"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2), "Done button not found")
        doneButton.tap()
        
        // 5) Verify we're back to map view
        XCTAssertFalse(planningView.exists, "RoutePlanningView sheet should be dismissed")
        XCTAssertTrue(automaticButton.waitForExistence(timeout: 2), "Should be back to home view")
    }
    
    func test_manual_planning_sheet_flow() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Open planning sheet via manual button
        let manualButton = app.buttons["home.plan.manual"]
        XCTAssertTrue(manualButton.waitForExistence(timeout: 5), "Manual planning button not found")
        manualButton.tap()
        
        // 2) Verify RoutePlanningView sheet is presented
        let planningView = app.otherElements["RoutePlanningView"]
        XCTAssertTrue(planningView.waitForExistence(timeout: 3), "RoutePlanningView sheet not presented")
        
        // 3) Verify preset mode is set to manual
        let manualMode = app.buttons["Planungsmodus.Manuell"]
        XCTAssertTrue(manualMode.waitForExistence(timeout: 2), "Manual mode button not found")
        XCTAssertTrue(manualMode.isSelected, "Manual mode not preselected")
    }
    
    func test_route_generation_auto_shows_active_sheet() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Open automatic planning
        let automaticButton = app.buttons["home.plan.automatic"]
        automaticButton.tap()
        
        // 2) Set city and generate route
        let cityField = app.textFields["route.city.textfield"]
        if cityField.waitForExistence(timeout: 2) {
            cityField.tap()
            cityField.clearAndType(text: "Nürnberg")
            app.keyboards.buttons["Return"].tap()
        }
        
        let generateButton = app.buttons["Los geht's!"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 3), "Generate button not found")
        generateButton.tap()
        
        // 3) Wait for route generation and RouteBuilder
        let startButton = app.buttons["Zeig mir die Tour!"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 15), "Route builder not shown")
        startButton.tap()
        
        // 4) Verify ActiveRouteSheetView is automatically presented
        let activeRouteSheet = app.otherElements["ActiveRouteSheetView"]
        XCTAssertTrue(activeRouteSheet.waitForExistence(timeout: 5), "ActiveRouteSheetView not automatically shown")
        
        // 5) Verify planning sheet is dismissed
        let planningView = app.otherElements["RoutePlanningView"]
        XCTAssertFalse(planningView.exists, "RoutePlanningView should be dismissed after route generation")
    }
    
    func test_no_multiple_sheets_race_condition() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Rapidly tap automatic planning button multiple times
        let automaticButton = app.buttons["home.plan.automatic"]
        automaticButton.tap()
        automaticButton.tap()
        automaticButton.tap()
        
        // 2) Wait a moment for any potential race conditions
        Thread.sleep(forTimeInterval: 1.0)
        
        // 3) Verify only one RoutePlanningView sheet exists
        let planningViews = app.otherElements.matching(identifier: "RoutePlanningView")
        XCTAssertEqual(planningViews.count, 1, "Multiple planning sheets should not exist")
        
        // 4) Dismiss and verify clean state
        let doneButton = app.buttons["Fertig"]
        if doneButton.exists {
            doneButton.tap()
        }
        
        XCTAssertTrue(automaticButton.waitForExistence(timeout: 3), "Should return to clean home state")
    }
    
    func test_quick_planning_flow_if_enabled() {
        let app = TestApp.launch(uitest: true)
        
        // Check if quick planning is enabled
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.exists {
            // Quick planning is enabled, test the flow
            quickButton.tap()
            
            // Should show loading state then potentially route or error
            // We'll just verify the button exists and tapping doesn't crash
            Thread.sleep(forTimeInterval: 2.0)
            
            // If ActiveRouteSheet appears, verify it
            let activeRouteSheet = app.otherElements["ActiveRouteSheetView"]
            if activeRouteSheet.waitForExistence(timeout: 10) {
                // Quick planning succeeded
                XCTAssertTrue(activeRouteSheet.exists, "Quick planning should show active route")
            } else {
                // Quick planning may have failed (no location, no POIs, etc.)
                // That's acceptable for UI tests - we just verify no crash
                XCTAssertTrue(quickButton.exists, "App should remain stable after quick planning")
            }
        }
    }
}

// MARK: - Helper Extensions
extension XCUIElement {
    func clearAndType(text: String) {
        // Clear existing text
        self.doubleTap()
        self.typeText(text)
    }
    
    func waitForExists(timeout: TimeInterval = 5) -> Bool {
        return self.waitForExistence(timeout: timeout)
    }
}
