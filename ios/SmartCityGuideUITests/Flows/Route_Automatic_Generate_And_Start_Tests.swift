import XCTest

final class Route_Automatic_Generate_And_Start_Tests: XCTestCase {
    func test_automatic_route_generation_and_start() {
        let app = TestApp.launch(uitest: true)

        // 1) Planung öffnen
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found on home")
        planButton.tap()

        // 2) Stadt setzen (wenn nicht bereits durch Seed)
        let cityField = app.textFields["route.city.textfield"]
        if cityField.waitForExists() {
            cityField.tap()
            cityField.clearAndType(text: "Nürnberg")
            app.keyboards.buttons["Return"].tap()
        }

        // 3) Automatisch wählen (Planungsmodus ist default automatic, aber wir sichern)
        let automaticMode = app.buttons["Planungsmodus.Automatisch"]
        if automaticMode.waitForExists() && !automaticMode.isSelected {
            automaticMode.tap()
        }

        // 4) Generieren (unterer Call-To-Action)
        let cta = app.buttons["Los geht's!"]
        XCTAssertTrue(cta.waitForExists(), "Generate CTA not found")
        cta.tap()

        // 5) Warten bis Route sichtbar (Summary mit Stops)
        let summaryStops = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Coole Stopps'"))
        XCTAssertTrue(summaryStops.firstMatch.waitForExists(timeout: 15), "Route summary not shown")

        // 6) Starten (im RouteBuilder 'Zeig mir die Tour!')
        let startButton = app.buttons["Zeig mir die Tour!"]
        XCTAssertTrue(startButton.waitForExists(), "Start button not found")
        startButton.tap()

        // 7) Karte mit Polyline sichtbar (Map overlay existiert durch aktive Route)
        // Wir prüfen heuristisch über einen Text aus der Bottom-Overlay-Karte
        let runningLabel = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(runningLabel.waitForExists(), "Active route overlay not visible")
    }
}


