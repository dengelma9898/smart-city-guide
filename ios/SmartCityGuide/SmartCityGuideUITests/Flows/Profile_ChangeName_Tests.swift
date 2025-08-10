import XCTest

final class Profile_ChangeName_Tests: XCTestCase {
    func test_change_profile_name_updates_header() {
        let app = TestApp.launch(uitest: true)
        let profile = ProfilePage(app: app)
            .open()
            .setName("Erika Mustermann")
            .save()
        
        XCTAssertEqual(profile.visibleName(), "Erika Mustermann")
    }
}


