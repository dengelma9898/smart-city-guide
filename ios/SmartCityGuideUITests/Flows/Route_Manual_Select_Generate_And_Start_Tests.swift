import XCTest

final class Route_Manual_Select_Generate_And_Start_Tests: XCTestCase {
    func test_manual_route_selection_generate_and_start() {
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
            if app.keyboards.buttons["Return"].waitForExists() {
                app.keyboards.buttons["Return"].tap()
            } else if app.keyboards.buttons["Fertig"].waitForExists() {
                app.keyboards.buttons["Fertig"].tap()
            }
        }

        // 3) Planungsmodus manuell wählen
        let manualMode = app.buttons["Manuell erstellen Modus"]
        XCTAssertTrue(manualMode.waitForExists(), "Manual mode button not found")
        if !manualMode.isSelected { manualMode.tap() }

        // 4) Manuelle Auswahl starten über CTA "POIs entdecken!"
        let cta = app.buttons["POIs entdecken!"]
        XCTAssertTrue(cta.waitForExists(), "Manual CTA not found")
        cta.tap()

        // Warte bis die manuelle Auswahl-Ansicht erscheint
        let manualNav = app.navigationBars["POI Auswahl"]
        XCTAssertTrue(manualNav.waitForExists(timeout: 60), "Manual selection view did not appear")

        // 5) Mindestens 2 POIs auswählen (Bottom Action Bar Buttons)
        //    Wir tippen zweimal auf "POI auswählen" und einmal auf "POI ablehnen" dazwischen
        let selectBtn = app.buttons["POI auswählen"]
        XCTAssertTrue(selectBtn.waitForExists(timeout: 60), "Select button not visible")
        selectBtn.tap()

        let rejectBtn = app.buttons["POI ablehnen"]
        if rejectBtn.waitForExists() { rejectBtn.tap() }

        XCTAssertTrue(selectBtn.waitForExists(), "Select button disappeared unexpectedly")
        selectBtn.tap()

        // 6) Route erstellen (NavigationBar Trailing Button)
        let createButton = app.navigationBars["POI Auswahl"].buttons["Route erstellen"]
        XCTAssertTrue(createButton.waitForExists(), "Create route button not found")
        createButton.tap()

        // 7) Auf RouteBuilder warten
        let builderNav = app.navigationBars["Deine manuelle Route!"]
        XCTAssertTrue(builderNav.waitForExists(timeout: 60), "RouteBuilder did not appear")

        // 8) Im RouteBuilder "Zeig mir die Tour!" starten
        let startButton = app.buttons["Zeig mir die Tour!"]
        XCTAssertTrue(startButton.waitForExists(timeout: 60), "Start button not found in builder")
        startButton.tap()

        // 9) Laufende Tour Overlay prüfen
        let runningLabel = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(runningLabel.waitForExists(), "Active route overlay not visible")
    }
}


