import XCTest

struct TestApp {
    static func launch(uitest: Bool = true, extraEnv: [String: String] = [:], extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        if uitest { app.launchEnvironment["UITEST"] = "1" }
        extraEnv.forEach { key, value in app.launchEnvironment[key] = value }
        app.launchArguments += ["-ui-tests"] + extraArgs
        app.launch()

        // Handle first-launch system alerts (e.g., location permission) via SpringBoard
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Short waits to avoid slowing down happy-path runs
        if springboard.buttons["Beim Verwenden der App erlauben"].waitForExists(timeout: 2) {
            springboard.buttons["Beim Verwenden der App erlauben"].tap()
        } else if springboard.buttons["Allow While Using App"].waitForExists(timeout: 2) {
            springboard.buttons["Allow While Using App"].tap()
        } else if springboard.buttons["Einmal erlauben"].waitForExists(timeout: 2) {
            springboard.buttons["Einmal erlauben"].tap()
        } else if springboard.buttons["Allow Once"].waitForExists(timeout: 2) {
            springboard.buttons["Allow Once"].tap()
        }
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


