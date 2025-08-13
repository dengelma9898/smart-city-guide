import XCTest

final class Route_Quick_Generate_And_Start_Tests: XCTestCase {
    func test_quickPlanning_showsRouteWithoutIntermediateScreens() {
        let app = TestApp.launch(extraArgs: [])

        // Ensure start buttons exist
        let quickButton = app.buttons["home.plan.quick"]
        XCTAssertTrue(quickButton.waitForExists(timeout: 5))

        // Tap quick planning
        quickButton.tap()

        // Loader should appear
        let loadingText = app.staticTexts["Wir basteln deine Route!"]
        XCTAssertTrue(loadingText.waitForExists(timeout: 3))

        // After planning, we expect the map with a route (verify with one of the route UI labels)
        // We assert that the planning sheet is NOT shown
        XCTAssertFalse(app.sheets.firstMatch.waitForExists(timeout: 1))

        // A simple heuristic: the active route bottom card shows “Deine Tour läuft!”
        let tourLabel = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(tourLabel.waitForExists(timeout: 20))
    }
}


