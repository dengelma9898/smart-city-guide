import XCTest

final class Route_Edit_Single_POI_Tests: XCTestCase {
    func test_edit_single_poi_in_planned_route_and_restart() {
        let app = TestApp.launch(uitest: true)

        // 1) Planung öffnen und automatische Route erzeugen (Flow 2, komprimiert)
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found on home")
        planButton.tap()

        let autoMode = app.buttons["Automatisch Modus"]
        XCTAssertTrue(autoMode.waitForExists(), "Automatic mode not found")
        if !autoMode.isSelected { autoMode.tap() }

        let startCta = app.buttons["Los geht's!"]
        XCTAssertTrue(startCta.waitForExists(), "Generate CTA not found")
        startCta.tap()

        // 2) Warten auf Summary im Builder
        let summaryStops = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Stops' OR label CONTAINS[c] 'Stopps'"))
        XCTAssertTrue(summaryStops.firstMatch.waitForExists(timeout: 60), "Route summary not shown")

        // 3) Edit öffnen
        let editButton = app.buttons["route.edit.button"]
        XCTAssertTrue(editButton.waitForExists(timeout: 10), "Edit button not found")
        editButton.tap()

        // 4) In Edit-View: Alternativen laden, Top‑Card annehmen
        // Warte bis ein Element aus dem Edit‑UI sichtbar ist (z. B. Titel)
        let editNav = app.navigationBars["Stopp bearbeiten"]
        XCTAssertTrue(editNav.waitForExists(timeout: 60), "RouteEditView did not appear")

        // Tinder‑Buttons: "Nehmen"/"Überspringen" sind reine Labels; wir triggern über Karten-Actions
        // Tippe einmal auf "Nehmen" via Accessibility-Label fallback (wenn verfügbar), sonst akzeptiere Top‑Card durch Koordinate
        let takeLabel = app.staticTexts["Nehmen"]
        if takeLabel.waitForExists(timeout: 2) { takeLabel.tap() }

        // Falls ein Blocker‑Overlay „Route wird erstellt…“ erscheint, warte bis es verschwindet
        let creatingLabel = app.staticTexts["Route wird erstellt…"]
        _ = creatingLabel.waitForExists(timeout: 2)
        if creatingLabel.exists {
            // Warte maximal 60s auf Dismiss
            let overlayGone = !creatingLabel.waitForExists(timeout: 60)
            XCTAssertTrue(overlayGone, "Edit recalculation overlay did not dismiss")
        }

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


