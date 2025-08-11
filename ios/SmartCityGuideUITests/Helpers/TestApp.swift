import XCTest

struct TestApp {
    static func launch(uitest: Bool = true, extraEnv: [String: String] = [:], extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        if uitest { app.launchEnvironment["UITEST"] = "1" }
        extraEnv.forEach { key, value in app.launchEnvironment[key] = value }
        app.launchArguments += ["-ui-tests"] + extraArgs
        app.launch()

        // Handle first-launch system alerts (e.g., location permission)
        let _ = addUIInterruptionMonitor(withDescription: "System Alerts") { alert in
            if alert.buttons["Beim Verwenden der App erlauben"].exists {
                alert.buttons["Beim Verwenden der App erlauben"].tap()
                return true
            }
            if alert.buttons["Allow While Using App"].exists {
                alert.buttons["Allow While Using App"].tap()
                return true
            }
            if alert.buttons["Einmal erlauben"].exists {
                alert.buttons["Einmal erlauben"].tap()
                return true
            }
            if alert.buttons["Allow Once"].exists {
                alert.buttons["Allow Once"].tap()
                return true
            }
            return false
        }
        // Trigger the interruption monitor
        app.activate()
        return app
    }
}

extension XCUIElement {
    @discardableResult
    func waitForExists(timeout: TimeInterval = 5.0) -> Bool {
        return self.waitForExistence(timeout: timeout)
    }
    
    func clearAndType(text: String) {
        self.tap()
        if let stringValue = self.value as? String, !stringValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            self.typeText(deleteString)
        }
        self.typeText(text)
    }
}


