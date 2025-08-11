import XCTest

final class Route_Manual_Select_Generate_And_Start_Tests: XCTestCase {
    func test_manual_route_selection_generate_and_start() {
        let app = TestApp.launch(uitest: true)

        // 1) Planung öffnen
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found on home")
        planButton.tap()

        // 2) Stadt setzen nur wenn das Feld leer ist (vermeidet ScrollToVisible-Probleme)
        let cityField = app.textFields["route.city.textfield"]
        if cityField.waitForExists() {
            if let val = cityField.value as? String, val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cityField.tap()
                cityField.clearAndType(text: "Nürnberg")
                if app.keyboards.buttons["Return"].waitForExists() {
                    app.keyboards.buttons["Return"].tap()
                } else if app.keyboards.buttons["Fertig"].waitForExists() {
                    app.keyboards.buttons["Fertig"].tap()
                }
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
        let selectBtn = app.buttons["manual.select.button"]
        XCTAssertTrue(selectBtn.waitForExists(timeout: 60), "Select button not visible")
        selectBtn.tap()

        let rejectBtn = app.buttons["manual.reject.button"]
        if rejectBtn.waitForExists() { rejectBtn.tap() }

        XCTAssertTrue(selectBtn.waitForExists(), "Select button disappeared unexpectedly")
        selectBtn.tap()

        // 6) Route erstellen (NavigationBar Trailing Button)
        let createButton = app.navigationBars["POI Auswahl"].buttons["Route erstellen"]
        XCTAssertTrue(createButton.waitForExists(), "Create route button not found")
        createButton.tap()

        // 7) RouteBuilder oder Completion-CTA abwarten
        let builderNav = app.navigationBars["Deine manuelle Route!"]
        let routeAnzeigen = app.buttons["manual.route.show.builder.button"]
        if !builderNav.waitForExists(timeout: 8) {
            // Falls der Builder nicht direkt erscheint, über Completion-CTA öffnen
            XCTAssertTrue(routeAnzeigen.waitForExists(timeout: 60), "Completion CTA 'Route anzeigen' not found")
            routeAnzeigen.tap()
            // Warte alternativ auf Builder-Screen-Anker
            let builderScreen = app.otherElements["route.builder.screen"]
            let appeared = builderNav.waitForExists(timeout: 60) || builderScreen.waitForExists(timeout: 60)
            XCTAssertTrue(appeared, "RouteBuilder did not appear after tapping 'Route anzeigen'")
        }

        // 8) Im RouteBuilder "Zeig mir die Tour!" starten
        let startButton = app.buttons["route.start.button"]
        // Robust: Falls Button nicht sofort sichtbar, mehrfach scrollen und erneut prüfen
        var foundStart = startButton.waitForExists(timeout: 10)
        var attempts = 0
        while !foundStart && attempts < 8 {
            app.swipeUp()
            foundStart = startButton.waitForExists(timeout: 5)
            attempts += 1
        }
        // Fallback-Check auf inhaltlichen Text im Builder
        if !foundStart {
            let details = app.staticTexts["Deine Tour im Detail"]
            foundStart = details.waitForExists(timeout: 5)
        }
        XCTAssertTrue(foundStart, "Builder content not visible (no start button or details)")
        if startButton.exists { startButton.tap() }

        // 9) Laufende Tour Overlay prüfen
        let runningLabel = app.staticTexts["Deine Tour läuft!"]
        XCTAssertTrue(runningLabel.waitForExists(), "Active route overlay not visible")
    }
}


