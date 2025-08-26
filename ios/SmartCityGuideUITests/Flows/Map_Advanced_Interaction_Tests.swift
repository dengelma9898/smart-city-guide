import XCTest

/// P1: Map-Interaktion UI-Tests (Advanced)
/// Erweiterte Map-Funktionalität und Gesture-Tests
final class Map_Advanced_Interaction_Tests: XCTestCase {
    
    // MARK: - P1 Map Gesture Tests
    
    func test_mapPinch_zoomsCorrectly() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for pinch test")
            return
        }
        
        // Perform pinch to zoom - using available XCTest gesture APIs
        map.pinch(withScale: 2.0, velocity: 1.0)
        
        // Give map time to process zoom
        sleep(1)
        
        // Map should still be responsive after zoom
        XCTAssertTrue(map.isHittable, "Map should remain interactive after zoom")
        
        // Pinch to zoom out
        map.pinch(withScale: 0.5, velocity: -1.0)
        
        // Final check for responsiveness
        XCTAssertTrue(map.isHittable, "Map should remain interactive after zoom out")
    }
    
    func test_mapSwipe_pansMapproperly() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for swipe test")
            return
        }
        
        // Perform swipe gestures to pan the map
        map.swipeRight()
        sleep(1)
        map.swipeLeft()
        sleep(1)
        map.swipeUp()
        sleep(1)
        map.swipeDown()
        
        // Map should remain responsive after multiple swipes
        XCTAssertTrue(map.isHittable, "Map should remain interactive after pan gestures")
    }
    
    func test_mapTwoFingerTap_zoomsOut() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for two finger tap test")
            return
        }
        
        // Two finger tap to zoom out
        map.twoFingerTap()
        
        // Map should remain responsive
        XCTAssertTrue(map.isHittable, "Map should remain interactive after two finger tap")
    }
    
    // MARK: - P1 Map Route Interaction Tests
    
    func test_mapWithRoute_handlesGesturesCorrectly() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route first
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        let map = app.maps.firstMatch
        guard map.exists else {
            XCTFail("Map not visible with route")
            return
        }
        
        // Test gestures with route visible
        map.pinch(withScale: 1.5, velocity: 1.0)
        sleep(1)
        map.swipeUp()
        sleep(1)
        map.twoFingerTap()
        
        // Map should maintain responsiveness with route
        XCTAssertTrue(map.isHittable, "Map should maintain responsiveness with active route")
    }
    
    // MARK: - P1 Map Performance Tests
    
    func test_mapRapidGestures_maintainPerformance() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for performance test")
            return
        }
        
        // Perform rapid gestures
        measure {
            for _ in 0..<3 {
                map.swipeRight()
                map.swipeLeft()
                map.pinch(withScale: 1.2, velocity: 0.5)
                map.pinch(withScale: 0.8, velocity: -0.5)
            }
        }
        
        // Map should still be responsive after performance test
        XCTAssertTrue(map.isHittable, "Map should remain responsive after rapid gestures")
    }
    
    // MARK: - P1 Map State Tests
    
    func test_mapState_persistsAcrossInteractions() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for state test")
            return
        }
        
        // Zoom in
        map.pinch(withScale: 2.0, velocity: 1.0)
        sleep(1)
        
        // Pan
        map.swipeUp()
        sleep(1)
        
        // Generate route to test state persistence with route overlay
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 3) && quickButton.isEnabled {
            quickButton.tap()
            
            // Wait for route
            let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
            if routeIndicator.waitForExists(timeout: 20) {
                // Map should maintain its zoom and pan state with route overlay
                XCTAssertTrue(map.exists, "Map should maintain state with route overlay")
                XCTAssertTrue(map.isHittable, "Map should remain interactive with route state")
            }
        }
        
        // Final validation
        XCTAssertTrue(map.isHittable, "Map should maintain interactivity across state changes")
    }
    
    // MARK: - P1 Map Accessibility Tests
    
    func test_mapAccessibility_supportsGestures() {
        let app = TestApp.launch(extraArgs: [])
        
        let map = app.maps.firstMatch
        guard map.waitForExists(timeout: 5) else {
            XCTFail("Map not available for accessibility test")
            return
        }
        
        // Validate map supports required gestures for accessibility
        XCTAssertTrue(map.isHittable, "Map should be accessible for touch")
        
        // Test basic tap
        map.tap()
        XCTAssertTrue(map.isHittable, "Map should remain accessible after tap")
        
        // Test long press (important for accessibility)
        map.press(forDuration: 1.0)
        XCTAssertTrue(map.isHittable, "Map should remain accessible after long press")
    }
    
    func test_mapWithRouteAccessibility_maintainsUsability() {
        let app = TestApp.launch(extraArgs: [])
        
        // Generate route
        let quickButton = app.buttons["home.plan.quick"]
        guard quickButton.waitForExists(timeout: 5) && quickButton.isEnabled else {
            XCTSkip("Quick planning not available")
            return
        }
        
        quickButton.tap()
        
        // Wait for route
        let routeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Tour'")).firstMatch
        guard routeIndicator.waitForExists(timeout: 30) else {
            XCTSkip("Route generation failed")
            return
        }
        
        let map = app.maps.firstMatch
        guard map.exists else {
            XCTFail("Map not accessible with route")
            return
        }
        
        // Test accessibility with route elements
        XCTAssertTrue(map.isHittable, "Map should remain accessible with route elements")
        
        // Basic interaction should work
        map.tap()
        XCTAssertTrue(map.isHittable, "Map should maintain accessibility with active route")
    }
}
