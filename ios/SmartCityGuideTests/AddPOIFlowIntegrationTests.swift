//
//  AddPOIFlowIntegrationTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-22
//  Integration tests for UnifiedSwipeView in Add POI flow
//

import XCTest
import SwiftUI
import CoreLocation
@testable import SmartCityGuide

@MainActor
class AddPOIFlowIntegrationTests: XCTestCase {
    
    var mockSelection: ManualPOISelection!
    var testPOIs: [POI]!
    var testRoute: GeneratedRoute!
    var routeWaypoints: [RoutePoint]!
    
    override func setUp() {
        super.setUp()
        mockSelection = ManualPOISelection()
        testPOIs = createSamplePOIs(count: 5)
        routeWaypoints = createSampleRoutePoints(count: 3)
        testRoute = createSampleRoute(waypoints: routeWaypoints)
    }
    
    override func tearDown() {
        mockSelection = nil
        testPOIs = nil
        testRoute = nil
        routeWaypoints = nil
        super.tearDown()
    }
    
    // MARK: - Add POI Flow Configuration Tests
    
    func testAddPOIFlowUsesCorrectConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        
        // Then
        XCTAssertTrue(config.showSelectionCounter, "Add POI flow should show selection counter")
        XCTAssertTrue(config.showConfirmButton, "Add POI flow should show confirm button")
        XCTAssertFalse(config.autoConfirmSelection, "Add POI flow should not auto-confirm")
        XCTAssertTrue(config.allowContinuousSwipe, "Add POI flow should allow continuous swiping")
        XCTAssertEqual(config.onAbortBehavior, .clearSelections, "Add POI flow should clear selections on abort")
    }
    
    // MARK: - POI Filtering Integration Tests
    
    func testAddPOIFlowWithExistingRoutePOIs() {
        // Given - Create POIs where some match existing route waypoints
        let existingPOI = POI(
            id: "existing",
            name: routeWaypoints[0].name, // Same name as first waypoint
            latitude: routeWaypoints[0].coordinate.latitude,
            longitude: routeWaypoints[0].coordinate.longitude,
            category: .attraction,
            description: "Existing POI",
            tags: [:],
            sourceType: "test",
            sourceId: 1,
            address: POIAddress(
                street: "Existing Street",
                houseNumber: "1",
                city: "Test City",
                postcode: "12345",
                country: "Deutschland"
            ),
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
        
        let allPOIs = testPOIs + [existingPOI]
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        
        // When
        service.configure(with: config, availablePOIs: allPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertEqual(service.swipeCards.count, allPOIs.count, "Add POI flow should not filter POIs by default")
        
        // Note: POI filtering logic for existing route POIs would be handled
        // by the RouteBuilderView's isAlreadyInRoute closure, not the config
    }
    
    // MARK: - Selection Management Integration Tests
    
    func testAddPOIFlowAccumulatesSelections() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When selecting multiple POIs
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertEqual(mockSelection.selectedPOIs.count, 3, "Should accumulate selected POIs")
        XCTAssertTrue(service.allowsContinuousSwipe, "Should allow continuous selection")
        XCTAssertTrue(service.hasCurrentCard(), "Should still have cards available")
    }
    
    func testAddPOIFlowSelectionCounter() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        let selectionCount = service.getSelectionCount(selection: mockSelection)
        XCTAssertEqual(selectionCount, 2, "Should track selection count correctly")
        XCTAssertTrue(service.shouldShowSelectionCounter, "Should show selection counter in add POI flow")
    }
    
    // MARK: - Confirm Button Integration Tests
    
    func testAddPOIFlowConfirmButtonBehavior() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When no selections
        XCTAssertFalse(mockSelection.hasSelections, "Should not have selections initially")
        XCTAssertTrue(service.shouldShowConfirmButton, "Should show confirm button even without selections")
        
        // When has selections
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(mockSelection.hasSelections, "Should have selections after selection")
        XCTAssertFalse(service.shouldAutoConfirm, "Should not auto-confirm in add POI flow")
    }
    
    // MARK: - Route Integration Tests
    
    func testAddPOIFlowWithExistingRoute() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Simulate adding POIs to existing route
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertEqual(mockSelection.selectedPOIs.count, 2, "Should have selected POIs for route addition")
        
        // Verify these POIs can be added to the existing route
        let existingWaypointCount = testRoute.waypoints.count
        let newTotalWaypoints = existingWaypointCount + mockSelection.selectedPOIs.count
        XCTAssertEqual(newTotalWaypoints, 5, "Should calculate correct new waypoint count")
    }
    
    // MARK: - Distance Calculation Integration Tests
    
    func testAddPOIFlowDistanceCalculations() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When cards are created
        let cards = service.getVisibleCards()
        
        // Then
        XCTAssertFalse(cards.isEmpty, "Should have visible cards")
        
        // Verify distance calculations are available
        // Note: In actual implementation, distance would be calculated relative to route
        for card in cards {
            XCTAssertGreaterThanOrEqual(card.distanceFromOriginal, 0, "Should have non-negative distance")
        }
    }
    
    // MARK: - Sheet Presentation Integration Tests
    
    func testAddPOIFlowSheetBehavior() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        
        // Then - verify configuration supports sheet presentation
        XCTAssertEqual(config.onAbortBehavior, .clearSelections, "Should clear selections when sheet is dismissed")
        XCTAssertFalse(config.autoConfirmSelection, "Should not auto-close sheet")
        
        // Simulate sheet dismissal
        mockSelection.selectPOI(testPOIs[0])
        mockSelection.selectPOI(testPOIs[1])
        
        // When dismissed with clearSelections behavior
        if config.onAbortBehavior == .clearSelections {
            mockSelection.reset()
        }
        
        // Then
        XCTAssertFalse(mockSelection.hasSelections, "Should clear selections on sheet dismissal")
    }
    
    // MARK: - Route Optimization Integration Tests
    
    func testAddPOIFlowPreparesForOptimization() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When selecting POIs
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        
        // Then - verify selections are ready for route optimization
        XCTAssertTrue(mockSelection.hasSelections, "Should have selections for optimization")
        XCTAssertEqual(mockSelection.selectedPOIs.count, 2, "Should have specific count for optimization")
        
        // Verify POI data is complete for route generation
        for poi in mockSelection.selectedPOIs {
            XCTAssertFalse(poi.name.isEmpty, "POI should have name for route generation")
            XCTAssertNotEqual(poi.coordinate.latitude, 0, "POI should have valid coordinates")
            XCTAssertNotEqual(poi.coordinate.longitude, 0, "POI should have valid coordinates")
        }
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testAddPOIFlowAccessibilitySupport() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        
        // Then - verify accessibility support is maintained
        XCTAssertTrue(config.showSelectionCounter, "Selection counter should be accessible")
        XCTAssertTrue(config.showConfirmButton, "Confirm button should be accessible")
        
        // Note: Specific accessibility identifiers are tested in UI tests
        // This just verifies the configuration supports accessible UI elements
    }
    
    // MARK: - Performance Integration Tests
    
    func testAddPOIFlowPerformanceWithLargePOISet() {
        // Given
        let largePOISet = createSamplePOIs(count: 50)
        let config = SwipeFlowConfiguration.addPOI
        let service = UnifiedSwipeService()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        service.configure(with: config, availablePOIs: largePOISet, enrichedPOIs: [:])
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        let configurationTime = endTime - startTime
        XCTAssertLessThan(configurationTime, 0.5, "Configuration should be fast for add POI flow")
        
        // Verify memory optimization
        let visibleCards = service.getVisibleCards()
        XCTAssertLessThanOrEqual(visibleCards.count, 3, "Should limit visible cards for performance")
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePOIs(count: Int) -> [POI] {
        return (0..<count).map { index in
            createSamplePOI(name: "Test POI \(index)")
        }
    }
    
    private func createSamplePOI(name: String) -> POI {
        return POI(
            id: UUID().uuidString,
            name: name,
            latitude: 49.4521 + Double(Int.random(in: -100...100)) * 0.001,
            longitude: 11.0767 + Double(Int.random(in: -100...100)) * 0.001,
            category: .attraction,
            description: "Test POI for add POI integration testing",
            tags: [:],
            sourceType: "test",
            sourceId: 1,
            address: POIAddress(
                street: "Test Street",
                houseNumber: "1",
                city: "Test City",
                postcode: "12345",
                country: "Deutschland"
            ),
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
    }
    
    private func createSampleRoutePoints(count: Int) -> [RoutePoint] {
        return (0..<count).map { index in
            RoutePoint(
                name: "Route Point \(index)",
                coordinate: CLLocationCoordinate2D(
                    latitude: 49.4521 + Double(index) * 0.01,
                    longitude: 11.0767 + Double(index) * 0.01
                ),
                address: "Address \(index)",
                category: .attraction
            )
        }
    }
    
    private func createSampleRoute(waypoints: [RoutePoint]) -> GeneratedRoute {
        return GeneratedRoute(
            waypoints: waypoints,
            totalDistance: 5000.0,
            totalWalkingTime: 3600.0,
            totalExperienceTime: 7200.0,
            directions: [],
            mapRoute: nil
        )
    }
}
