import XCTest

final class Profile_DefaultName_Tests: XCTestCase {
    func test_default_name_is_seeded_in_uitest_mode() {
        let app = TestApp.launch(uitest: true)
        let profile = ProfilePage(app: app).open()
        XCTAssertEqual(profile.visibleName(), "Max Mustermann")
    }
}


