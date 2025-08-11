import XCTest

struct TestApp {
    static func launch(uitest: Bool = true, extraEnv: [String: String] = [:], extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        if uitest { app.launchEnvironment["UITEST"] = "1" }
        extraEnv.forEach { key, value in app.launchEnvironment[key] = value }
        app.launchArguments += ["-ui-tests"] + extraArgs
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


