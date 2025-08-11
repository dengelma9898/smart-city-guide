import XCTest

final class Route_Manual_Select_Generate_And_Start_Tests: XCTestCase {
    func test_manual_route_selection_generate_and_start() {
        let app = TestApp.launch(uitest: true)

        // 1) Planung öffnen
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found on home")
        planButton.tap()

        // 2) Stadt zuverlässig setzen (Platzhalter kann als value erscheinen → immer schreiben)
        let cityField = app.textFields["route.city.textfield"]
        if cityField.waitForExists() {
            var tries = 0
            while !cityField.isHittable && tries < 4 { app.swipeUp(); tries += 1 }
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
        // Sicherstellen, dass CTA tappable (aktiv) ist
        var attempts = 0
        while !cta.isHittable && attempts < 5 {
            _ = cta.waitForExists(timeout: 1)
            attempts += 1
        }
        XCTAssertTrue(cta.isEnabled, "Manual CTA is disabled")
        cta.tap()

        // Warte bis die manuelle Auswahl-Ansicht erscheint
        let manualNav = app.navigationBars["POI Auswahl"]
        var appearedManual = manualNav.waitForExists(timeout: 20)
        if !appearedManual {
            let selectAnchor = app.buttons["manual.select.button"]
            appearedManual = selectAnchor.waitForExists(timeout: 40)
        }
        XCTAssertTrue(appearedManual, "Manual selection view did not appear")

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

        // 7) RouteBuilder oder Completion-CTA abwarten (OR-Strategie)
        let builderNav = app.navigationBars["Deine manuelle Route!"]
        let builderScreen = app.otherElements["route.builder.screen"]
        let routeAnzeigen = app.buttons["manual.route.show.builder.button"]
        let completionAnchor = app.staticTexts["Route erstellt!"]
        let completionAnchorId = app.staticTexts["manual.completion.anchor"]
        var appearedBuilder = builderNav.waitForExists(timeout: 8)
        if !appearedBuilder {
            // Warte bis entweder Builder oder CTA erscheint
            appearedBuilder = builderNav.waitForExists(timeout: 30) || builderScreen.waitForExists(timeout: 30) || routeAnzeigen.waitForExists(timeout: 30) || completionAnchor.waitForExists(timeout: 30) || completionAnchorId.waitForExists(timeout: 30)
            XCTAssertTrue(appearedBuilder, "Neither builder nor completion CTA appeared")
            if routeAnzeigen.exists {
                routeAnzeigen.tap()
                // Nach Tap auf CTA auf Builder warten
                let builderAppeared = builderNav.waitForExists(timeout: 60) || builderScreen.waitForExists(timeout: 60)
                XCTAssertTrue(builderAppeared, "RouteBuilder did not appear after tapping 'Route anzeigen'")
            }
        }

        // 8) Im RouteBuilder "Zeig mir die Tour!" starten
        let startButton = app.buttons["route.start.button"]
        // Robust: Falls Button nicht sofort sichtbar, mehrfach scrollen und erneut prüfen
        var foundStart = startButton.waitForExists(timeout: 10)
        var attemptsStart = 0
        while !foundStart && attemptsStart < 8 {
            app.swipeUp()
            foundStart = startButton.waitForExists(timeout: 5)
            attemptsStart += 1
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


