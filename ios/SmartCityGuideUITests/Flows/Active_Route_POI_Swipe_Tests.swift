import XCTest

final class Active_Route_POI_Swipe_Tests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func test_poi_swipe_left_shows_edit_delete_actions() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start an automatic route to get to active state
        generateAndStartRoute(app: app)
        
        // 2) Open the active route bottom sheet by tapping on it
        let activeRouteBanner = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(activeRouteBanner.waitForExists(), "Active route banner not found")
        activeRouteBanner.tap()
        
        // 3) Wait for sheet to expand and POI list to be visible
        let poisList = app.scrollViews["activeRoute.pois.list"]
        XCTAssertTrue(poisList.waitForExists(), "POI list not found in active route sheet")
        
        // 4) Find the first POI row in the list
        let firstPOI = app.cells["poi.row.0"].firstMatch
        XCTAssertTrue(firstPOI.waitForExists(), "First POI row not found")
        
        // 5) Perform left swipe gesture on the POI to reveal swipe actions
        firstPOI.swipeLeft()
        
        // 6) Verify that Edit and Delete buttons appear
        let editButton = app.buttons["poi.action.edit"]
        let deleteButton = app.buttons["poi.action.delete"]
        
        XCTAssertTrue(editButton.waitForExists(timeout: 2), "Edit button not visible after swipe")
        XCTAssertTrue(deleteButton.waitForExists(timeout: 2), "Delete button not visible after swipe")
        
        // 7) Verify button labels and icons
        XCTAssertTrue(editButton.label.contains("Bearbeiten"), "Edit button should contain 'Bearbeiten'")
        XCTAssertTrue(deleteButton.label.contains("Löschen"), "Delete button should contain 'Löschen'")
    }
    
    func test_poi_edit_button_tap_presents_alternatives() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route, open bottom sheet
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Swipe left on first POI and tap Edit
        let firstPOI = app.cells["poi.row.0"].firstMatch
        XCTAssertTrue(firstPOI.waitForExists(), "First POI row not found")
        firstPOI.swipeLeft()
        
        let editButton = app.buttons["poi.action.edit"]
        XCTAssertTrue(editButton.waitForExists(), "Edit button not visible")
        editButton.tap()
        
        // 3) Verify that POI alternatives sheet/modal appears
        let alternativesSheet = app.sheets["poi.alternatives.sheet"]
        XCTAssertTrue(alternativesSheet.waitForExists(), "POI alternatives sheet not presented")
        
        // 4) Verify that alternative POIs are shown in swipe card format
        let alternativeCard = app.otherElements["poi.alternative.unified"].firstMatch
        XCTAssertTrue(alternativeCard.waitForExists(), "Alternative POI card not found")
    }
    
    func test_poi_delete_button_shows_confirmation() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route, open bottom sheet
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Swipe left on first POI and tap Delete
        let firstPOI = app.cells["poi.row.0"].firstMatch
        XCTAssertTrue(firstPOI.waitForExists(), "First POI row not found")
        firstPOI.swipeLeft()
        
        let deleteButton = app.buttons["poi.action.delete"]
        XCTAssertTrue(deleteButton.waitForExists(), "Delete button not visible")
        deleteButton.tap()
        
        // 3) Verify that confirmation alert appears
        let deleteAlert = app.alerts["POI löschen"]
        XCTAssertTrue(deleteAlert.waitForExists(), "Delete confirmation alert not shown")
        
        // 4) Verify alert message and buttons
        let alertMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'wirklich löschen'")).firstMatch
        XCTAssertTrue(alertMessage.exists, "Delete confirmation message not found")
        
        let cancelButton = app.buttons["Abbrechen"]
        let confirmButton = app.buttons["Löschen"]
        XCTAssertTrue(cancelButton.exists, "Cancel button not found in alert")
        XCTAssertTrue(confirmButton.exists, "Confirm delete button not found in alert")
    }
    
    func test_poi_delete_confirmation_removes_poi_from_list() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route, open bottom sheet
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Count initial POI rows
        let poisList = app.scrollViews["activeRoute.pois.list"]
        let initialPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertGreaterThan(initialPOICount, 0, "No POI rows found initially")
        
        // 3) Get the name of the first POI to verify deletion
        let firstPOI = app.cells["poi.row.0"].firstMatch
        let firstPOIName = firstPOI.staticTexts.firstMatch.label
        
        // 4) Swipe left and delete first POI
        firstPOI.swipeLeft()
        let deleteButton = app.buttons["poi.action.delete"]
        deleteButton.tap()
        
        // 5) Confirm deletion
        let deleteAlert = app.alerts["POI löschen"]
        let confirmButton = deleteAlert.buttons["Löschen"]
        confirmButton.tap()
        
        // 6) Verify POI is removed from list
        let updatedPOICount = app.cells.matching(NSPredicate(format: "identifier BEGINSWITH 'poi.row.'")).count
        XCTAssertEqual(updatedPOICount, initialPOICount - 1, "POI count should decrease by 1 after deletion")
        
        // 7) Verify the specific POI is no longer in the list
        let deletedPOI = app.staticTexts[firstPOIName]
        XCTAssertFalse(deletedPOI.exists, "Deleted POI should no longer be visible in list")
    }
    
    func test_poi_swipe_actions_close_on_tap_outside() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route, open bottom sheet
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Swipe left on first POI to show actions
        let firstPOI = app.cells["poi.row.0"].firstMatch
        firstPOI.swipeLeft()
        
        let editButton = app.buttons["poi.action.edit"]
        XCTAssertTrue(editButton.waitForExists(), "Edit button should be visible after swipe")
        
        // 3) Tap on another area to close swipe actions
        let secondPOI = app.cells["poi.row.1"].firstMatch
        if secondPOI.exists {
            secondPOI.tap()
        } else {
            // Fallback: tap on the list background
            let poisList = app.scrollViews["activeRoute.pois.list"]
            poisList.tap()
        }
        
        // 4) Verify swipe actions are hidden
        XCTAssertFalse(editButton.exists, "Edit button should be hidden after tapping outside")
    }
    
    func test_poi_tap_does_not_trigger_actions() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route, open bottom sheet
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Tap directly on POI (should not trigger edit/delete)
        let firstPOI = app.cells["poi.row.0"].firstMatch
        XCTAssertTrue(firstPOI.waitForExists(), "First POI row not found")
        firstPOI.tap()
        
        // 3) Verify that no edit/delete actions appear
        let editButton = app.buttons["poi.action.edit"]
        let deleteButton = app.buttons["poi.action.delete"]
        
        XCTAssertFalse(editButton.exists, "Edit button should not appear on POI tap")
        XCTAssertFalse(deleteButton.exists, "Delete button should not appear on POI tap")
        
        // 4) Verify no additional sheets or modals are presented
        let alternativesSheet = app.sheets["poi.alternatives.sheet"]
        XCTAssertFalse(alternativesSheet.exists, "No sheets should be presented on POI tap")
    }
    
    func test_multiple_poi_swipe_actions_only_one_visible() {
        let app = TestApp.launch(uitest: true)
        
        // 1) Generate and start route, open bottom sheet
        generateAndStartRoute(app: app)
        openActiveRouteSheet(app: app)
        
        // 2) Swipe left on first POI
        let firstPOI = app.cells["poi.row.0"].firstMatch
        firstPOI.swipeLeft()
        
        let firstEditButton = app.buttons["poi.action.edit"].firstMatch
        XCTAssertTrue(firstEditButton.waitForExists(), "First POI edit button should be visible")
        
        // 3) Swipe left on second POI
        let secondPOI = app.cells["poi.row.1"].firstMatch
        if secondPOI.exists {
            secondPOI.swipeLeft()
            
            // 4) Verify that only second POI actions are visible (iOS native behavior)
            let visibleEditButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'poi.action.edit'"))
            XCTAssertEqual(visibleEditButtons.count, 1, "Only one POI should have visible swipe actions at a time")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateAndStartRoute(app: XCUIApplication) {
        // 1) Open planning
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found")
        planButton.tap()
        
        // 2) Set city if needed
        let cityField = app.textFields["route.city.textfield"]
        if cityField.waitForExists() {
            cityField.tap()
            cityField.clearAndType(text: "Nürnberg")
            app.keyboards.buttons["Return"].tap()
        }
        
        // 3) Ensure automatic mode is selected
        let automaticMode = app.buttons["Planungsmodus.Automatisch"]
        if automaticMode.waitForExists() && !automaticMode.isSelected {
            automaticMode.tap()
        }
        
        // 4) Generate route
        let generateButton = app.buttons["Los geht's!"]
        XCTAssertTrue(generateButton.waitForExists(), "Generate button not found")
        generateButton.tap()
        
        // 5) Wait for route and start it
        let startButton = app.buttons["Zeig mir die Tour!"]
        XCTAssertTrue(startButton.waitForExists(timeout: 15), "Start button not found")
        startButton.tap()
        
        // 6) Verify active route is running
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
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    func clearAndType(text: String) {
        guard self.exists else { return }
        self.tap()
        
        // Clear existing text
        let selectAll = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        selectAll.press(forDuration: 1.0)
        
        if self.value as? String != nil {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (self.value as? String)?.count ?? 0)
            self.typeText(deleteString)
        }
        
        self.typeText(text)
    }
    
    func waitForExists(timeout: TimeInterval = 5.0) -> Bool {
        return self.waitForExistence(timeout: timeout)
    }
}
