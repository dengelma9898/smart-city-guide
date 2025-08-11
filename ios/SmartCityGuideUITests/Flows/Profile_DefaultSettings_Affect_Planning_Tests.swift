import XCTest

final class Profile_DefaultSettings_Affect_Planning_Tests: XCTestCase {
    func test_profile_defaults_propagate_to_planning() {
        let app = TestApp.launch(uitest: true)

        // 1) Profil öffnen
        let profileButton = app.buttons["home.profile.button"]
        XCTAssertTrue(profileButton.waitForExists(), "Profile button not found")
        profileButton.tap()

        // 2) Einstellungen öffnen (direkt über Accessibility-ID)
        let preferencesButton = app.buttons["profile.open.settings.button"]
        XCTAssertTrue(preferencesButton.waitForExists(), "Preferences button not found")
        preferencesButton.tap()

        // 3) Defaults setzen – eindeutige Werte wählen
        tapId(app, id: "settings.stops.8")
        tapId(app, id: "settings.walktime.90min")
        tapId(app, id: "settings.distance.750m")
        tapId(app, id: "settings.endpoint.Stopp")

        // 4) Einstellungen schließen (gezielt in 'Deine Präferenzen')
        let settingsDone = app.navigationBars["Deine Präferenzen"].buttons["Fertig"]
        XCTAssertTrue(settingsDone.waitForExists(), "Settings Done button not found")
        settingsDone.tap()

        // 5) Profil schließen (zurück zur Karte) – gezielt in 'Dein Profil'
        let profileDone = app.navigationBars["Dein Profil"].buttons["Fertig"]
        if profileDone.waitForExists() {
            profileDone.tap()
        }

        // 6) Planung öffnen
        let planButton = app.buttons["Los, planen wir!"]
        XCTAssertTrue(planButton.waitForExists(), "Plan button not found on home")
        planButton.tap()

        // Stelle sicher, dass der Automatik‑Modus aktiv ist, damit die Parameter sichtbar sind
        let autoMode = app.buttons["Automatisch Modus"]
        if autoMode.waitForExists(timeout: 5) && !autoMode.isSelected { autoMode.tap() }

        // 7) Prüfe, dass Defaults übernommen wurden (Buttons mit isSelected)
        // Kurze Wartezeit, bis Defaults aus dem SettingsManager animiert angewendet sind
        _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Gehzeit'"))
            .firstMatch.waitForExists(timeout: 2)
        assertSelected(app, id: "Maximale Stopps.8")
        assertSelected(app, id: "Maximale Gehzeit.90min")
        assertSelected(app, id: "Mindestabstand.750m")
    }

    // MARK: - Helpers
    private func tapOption(_ app: XCUIApplication, label: String) {
        let button = app.buttons[label]
        if !button.waitForExists() || !button.isHittable {
            // Scroll in Formularen nach unten, falls nötig
            app.swipeUp()
        }
        XCTAssertTrue(button.waitForExists(), "Option not found: \(label)")
        button.tap()
    }

    private func tapId(_ app: XCUIApplication, id: String) {
        let button = app.buttons[id]
        if !button.waitForExists() || !button.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(button.waitForExists(), "Option not found: \(id)")
        button.tap()
    }

    private func assertSelected(_ app: XCUIApplication, id: String, file: StaticString = #file, line: UInt = #line) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExists(timeout: 10), "Option not found: \(id)", file: file, line: line)
        let isTraitSelected = button.isSelected
        let value = (button.value as? String)?.lowercased()
        let isValueSelected = (value == "selected")
        XCTAssertTrue(isTraitSelected || isValueSelected, "Option is not selected: \(id)", file: file, line: line)
    }
}


