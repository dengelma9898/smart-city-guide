import XCTest

final class ProfilePage {
    private let app: XCUIApplication
    
    init(app: XCUIApplication) { self.app = app }
    
    // Elements
    var openProfileButton: XCUIElement { app.buttons["home.profile.button"] }
    var headerNameLabel: XCUIElement { app.staticTexts["profile.header.name.label"] }
    var openEditButton: XCUIElement { app.buttons["profile.open.edit.button"] }
    var nameTextField: XCUIElement { app.textFields["profile.name.textfield"] }
    var saveButton: XCUIElement { app.buttons["profile.save.button"] }
    
    // Actions
    @discardableResult
    func open() -> Self {
        XCTAssertTrue(openProfileButton.waitForExists(), "Profile button not found on home screen")
        openProfileButton.tap()
        XCTAssertTrue(headerNameLabel.waitForExists(), "Profile header name not visible")
        return self
    }
    
    @discardableResult
    func setName(_ name: String) -> Self {
        XCTAssertTrue(openEditButton.waitForExists(), "Open edit profile button not found")
        openEditButton.tap()
        XCTAssertTrue(nameTextField.waitForExists(), "Name textfield not found")
        nameTextField.clearAndType(text: name)
        return self
    }
    
    @discardableResult
    func save() -> Self {
        XCTAssertTrue(saveButton.waitForExists(), "Save button not found")
        saveButton.tap()
        XCTAssertTrue(headerNameLabel.waitForExists(), "Header name not visible after save")
        return self
    }
    
    func visibleName() -> String {
        return headerNameLabel.label
    }
}


