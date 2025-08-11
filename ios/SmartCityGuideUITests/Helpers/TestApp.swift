import XCTest

struct TestApp {
    static func launch(uitest: Bool = true, extraEnv: [String: String] = [:], extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        if uitest { app.launchEnvironment["UITEST"] = "1" }
        extraEnv.forEach { key, value in app.launchEnvironment[key] = value }
        var args = ["-ui-tests"] + extraArgs
        // Auto-pilot flag to allow productive app to drive manual flow for simulator verification
        if !args.contains("-UITEST_AUTOPILOT_MANUAL") {
            args.append("-UITEST_AUTOPILOT_MANUAL")
        }
        app.launchArguments += args
        app.launch()
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


