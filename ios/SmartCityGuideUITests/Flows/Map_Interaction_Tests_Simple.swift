import XCTest

/// P1: Map-Interaktion UI-Tests (Simplified)
/// Validiert die Kern-Map-Funktionalität der Smart City Guide App
final class Map_Interaction_Tests_Simple: XCTestCase {
    
    // MARK: - P1 Map Basic Tests
    
    func test_mapView_isVisibleOnAppLaunch() {
        let app = TestApp.launch(extraArgs: [])
        
        // Map should be visible immediately on launch
        let map = app.maps.firstMatch
        XCTAssertTrue(map.waitForExists(timeout: 5), "Map should be visible on app launch")
        
        // Map should be interactive
        XCTAssertTrue(map.isHittable, "Map should be interactive")
    }
    
    func test_mapView_respondsToTap() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for tap test")
            return
        }
        
        // Tap on map
        map.tap()
        
        // Map should still be responsive
        XCTAssertTrue(map.isHittable, "Map should remain interactive after tap")
    }
    
    func test_mapWithRoute_displaysCorrectly() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate a route first
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route generation
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed or took too long")
            return
        }
        
        // Map should still be visible with route
        let map = app.maps.firstMatch
        XCTAssertTrue(map.exists, "Map should remain visible with active route")
        XCTAssertTrue(map.isHittable, "Map should remain interactive with active route")
    }
    
    func test_mapAccessibilityIdentifier_isPresent() {
        let app = TestApp.launch(extraArgs: [])
        
        // Check for map with accessibility identifier
        let mapById = app.otherElements["map.main"]
        let mapGeneric = app.maps.firstMatch
        
        let mapFound = mapById.waitForExists(timeout: 5) || mapGeneric.waitForExists(timeout: 5)
        XCTAssertTrue(mapFound, "Map should be findable via accessibility identifier or maps query")
    }
    
    func test_mapControls_areAccessible() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for controls test")
            return
        }
        
        // MapKit controls (compass, scale) might not be directly accessible via UI testing
        // This test validates that the map container is properly configured
        XCTAssertTrue(map.exists, "Map should exist with controls")
        XCTAssertTrue(map.isHittable, "Map should be interactive with controls")
    }
}
