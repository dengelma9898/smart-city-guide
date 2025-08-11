import XCTest

final class Route_Edit_Single_POI_Tests: XCTestCase {
    func test_edit_single_poi_in_planned_route_and_restart() {
        let app = TestApp.launch(uitest: true)

        // 1) Planung öffnen und automatische Route erzeugen (Flow 2, komprimiert)
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found on home")
        planButton.tap()

        // Setze Startstadt, damit der Generate-Button aktiv ist
        let cityField = app.textFields["route.city.textfield"]
        XCTAssertTrue(cityField.waitForExists(timeout: 10), "City text field not found")
        cityField.clearAndType(text: "Nürnberg")
        if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
        else if app.buttons["Fertig"].exists { app.buttons["Fertig"].tap() }

        let autoMode = app.buttons["Automatisch Modus"]
        XCTAssertTrue(autoMode.waitForExists(), "Automatic mode not found")
        if !autoMode.isSelected { autoMode.tap() }

        let startCta = app.buttons["Los geht's!"]
        XCTAssertTrue(startCta.waitForExists(), "Generate CTA not found")
        startCta.tap()

        // 2) Warten auf Summary im Builder
        let summaryStops = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Stops' OR label CONTAINS[c] 'Stopps'"))
        XCTAssertTrue(summaryStops.firstMatch.waitForExists(timeout: 60), "Route summary not shown")

        // 3) Edit öffnen (Scroll-Fallback, firstMatch)
        // Versuche in mehreren Scroll-Schritten mindestens einen Edit-Button sichtbar zu machen
        var editButton = app.buttons.matching(identifier: "route.edit.button").firstMatch
        var attempts = 0
        while !editButton.waitForExists(timeout: 2) && attempts < 6 {
            app.swipeUp()
            attempts += 1
            editButton = app.buttons.matching(identifier: "route.edit.button").firstMatch
        }
        XCTAssertTrue(editButton.exists, "Edit button not found")
        if !editButton.isHittable { app.swipeUp() }
        editButton.tap()

        // 4) In Edit-View: Alternativen laden, Top‑Card annehmen
        // Warte bis ein Element aus dem Edit‑UI sichtbar ist (z. B. Titel)
        let editNav = app.navigationBars["Stopp bearbeiten"]
        XCTAssertTrue(editNav.waitForExists(timeout: 60), "RouteEditView did not appear")

        // Tippe bis zu 2x auf "Nehmen" (falls Laden träge ist)
        let takeLabel = app.staticTexts["Nehmen"]
        if takeLabel.waitForExists(timeout: 5) {
            takeLabel.tap()
            // Falls Overlay kurz erscheint, warte kurz und versuche einmal nach
            if app.staticTexts["Route wird erstellt…"].waitForExists(timeout: 2) {
                _ = app.staticTexts["Route wird erstellt…"].waitForExists(timeout: 2)
            } else {
                // kurzer Fallback-Tap
                takeLabel.tap()
            }
        }

        // Falls ein Blocker‑Overlay „Route wird erstellt…“ erscheint, warte bis es verschwindet


        // 5) Zurück im Builder: Summary vorhanden
        XCTAssertTrue(summaryStops.firstMatch.waitForExists(timeout: 60), "Route summary after edit not shown")

        // 6) Starten
        let startButton = app.buttons["route.start.button"]
        XCTAssertTrue(startButton.waitForExists(timeout: 20), "Start button not found")
        startButton.tap()

        // 7) Verifiziere Karte (Overlay‑Text)
        let runningLabel = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(runningLabel.waitForExists(timeout: 20), "Active route overlay not visible after edit")
    }
}


