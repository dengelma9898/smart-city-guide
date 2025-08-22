//
//  EditPOIFlowIntegrationTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-22
//  Integration tests for UnifiedSwipeView in Edit POI flow
//

import XCTest
import SwiftUI
import CoreLocation
@testable import SmartCityGuide

@MainActor
class EditPOIFlowIntegrationTests: XCTestCase {
    
    var mockSelection: ManualPOISelection!
    var testPOIs: [POI]!
    var testRoute: GeneratedRoute!
    var routeWaypoints: [RoutePoint]!
    var originalPOI: RoutePoint!
    
    override func setUp() {
        super.setUp()
        mockSelection = ManualPOISelection()
        testPOIs = createSamplePOIs(count: 5)
        routeWaypoints = createSampleRoutePoints(count: 3)
        testRoute = createSampleRoute(waypoints: routeWaypoints)
        originalPOI = routeWaypoints[1] // Middle waypoint to replace
    }
    
    override func tearDown() {
        mockSelection = nil
        testPOIs = nil
        testRoute = nil
        routeWaypoints = nil
        originalPOI = nil
        super.tearDown()
    }
    
    // MARK: - Edit POI Flow Configuration Tests
    
    func testEditPOIFlowUsesCorrectConfiguration() {
        // Given
        let excludedPOIs = [testPOIs[0]]
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: excludedPOIs)
        
        // Then
        XCTAssertFalse(config.showSelectionCounter, "Edit POI flow should not show selection counter")
        XCTAssertFalse(config.showConfirmButton, "Edit POI flow should not show confirm button")
        XCTAssertTrue(config.autoConfirmSelection, "Edit POI flow should auto-confirm selection")
        XCTAssertFalse(config.allowContinuousSwipe, "Edit POI flow should not allow continuous swiping")
        XCTAssertEqual(config.onAbortBehavior, .keepSelections, "Edit POI flow should keep selections on abort")
    }
    
    // MARK: - POI Filtering Integration Tests
    
    func testEditPOIFlowExcludesRoutePOIs() {
        // Given - Create config that excludes current route POIs
        let config = SwipeFlowConfiguration.createEditPOIFlow(
            currentRouteWaypoints: routeWaypoints,
            poiToReplace: originalPOI
        )
        let service = UnifiedSwipeService()
        
        // When
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertGreaterThan(config.excludedPOIs.count, 0, "Should have excluded POIs")
        XCTAssertEqual(config.excludedPOIs.count, routeWaypoints.count, "Should exclude all route waypoints")
        
        // Verify POI filtering works
        let filteredPOIs = config.filterPOIs(testPOIs)
        XCTAssertEqual(filteredPOIs.count, testPOIs.count, "Test POIs should not be filtered (different from route)")
    }
    
    func testEditPOIFlowExcludesSpecificPOI() {
        // Given - Create POI that matches a route waypoint
        let matchingPOI = POI(
            id: "matching",
            name: originalPOI.name,
            latitude: originalPOI.coordinate.latitude,
            longitude: originalPOI.coordinate.longitude,
            category: originalPOI.category,
            description: "Matching POI",
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
        
        let allPOIs = testPOIs + [matchingPOI]
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [matchingPOI])
        
        // When
        let filteredPOIs = config.filterPOIs(allPOIs)
        
        // Then
        XCTAssertEqual(filteredPOIs.count, testPOIs.count, "Should filter out matching POI")
        XCTAssertFalse(filteredPOIs.contains(where: { $0.id == matchingPOI.id }), "Should not include excluded POI")
    }
    
    // MARK: - Auto-Confirm Selection Integration Tests
    
    func testEditPOIFlowAutoConfirmsSelection() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When selecting POI
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(service.shouldAutoConfirm, "Edit flow should auto-confirm")
        XCTAssertEqual(mockSelection.selectedPOIs.count, 1, "Should select POI in edit flow")
        XCTAssertFalse(service.allowsContinuousSwipe, "Should not allow continuous swiping")
    }
    
    func testEditPOIFlowImmediateClose() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        
        // Then
        XCTAssertEqual(config.autoCloseDelay, 0.3, "Should have brief delay for edit flow")
        XCTAssertTrue(config.autoConfirmSelection, "Should auto-confirm for immediate close")
    }
    
    // MARK: - UI Elements Configuration Tests
    
    func testEditPOIFlowHidesUIElements() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertFalse(service.shouldShowSelectionCounter, "Edit flow should hide selection counter")
        XCTAssertFalse(service.shouldShowConfirmButton, "Edit flow should hide confirm button")
    }
    
    // MARK: - Maximum Selection Tests
    
    func testEditPOIFlowMaxSelection() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        
        // Then
        XCTAssertEqual(config.maxSelectionsAllowed, 1, "Edit flow should allow only one selection")
    }
    
    // MARK: - Toast Message Integration Tests
    
    func testEditPOIFlowToastBehavior() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        
        // Then
        XCTAssertFalse(config.showToastMessages, "Edit flow should not show toast messages for quick UX")
    }
    
    // MARK: - Alternative POI Discovery Integration Tests
    
    func testEditPOIFlowWithAlternativePOIs() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        
        // Simulate alternatives discovered by coordinator
        let alternativePOIs = Array(testPOIs.prefix(3))
        
        // When
        service.configure(with: config, availablePOIs: alternativePOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertEqual(service.swipeCards.count, 3, "Should create cards for alternative POIs")
        XCTAssertTrue(service.hasCurrentCard(), "Should have cards available for replacement")
    }
    
    // MARK: - Route Coordinate Integration Tests
    
    func testEditPOIFlowWithRouteCoordinates() {
        // Given
        let config = SwipeFlowConfiguration.createEditPOIFlow(
            currentRouteWaypoints: routeWaypoints,
            poiToReplace: originalPOI
        )
        
        // Then
        XCTAssertEqual(config.excludedPOIs.count, routeWaypoints.count, "Should convert all route waypoints to excluded POIs")
        
        // Verify coordinate conversion
        for (index, excludedPOI) in config.excludedPOIs.enumerated() {
            let originalWaypoint = routeWaypoints[index]
            XCTAssertEqual(excludedPOI.name, originalWaypoint.name, "Should preserve POI name")
            XCTAssertEqual(excludedPOI.coordinate.latitude, originalWaypoint.coordinate.latitude, accuracy: 0.0001, "Should preserve latitude")
            XCTAssertEqual(excludedPOI.coordinate.longitude, originalWaypoint.coordinate.longitude, accuracy: 0.0001, "Should preserve longitude")
        }
    }
    
    // MARK: - HomeCoordinator Integration Tests
    
    func testEditPOIFlowReplacePOIIntegration() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        var selectedPOI: POI?
        var onPOISelectedCalled = false
        
        // Simulate UnifiedSwipeView onPOISelected callback
        let onPOISelected: (POI) -> Void = { poi in
            selectedPOI = poi
            onPOISelectedCalled = true
        }
        
        // When selecting POI
        service.selectCurrentCard(selection: mockSelection)
        
        // Simulate the callback that would be triggered
        if let firstSelected = mockSelection.selectedPOIs.first {
            onPOISelected(firstSelected)
        }
        
        // Then
        XCTAssertTrue(onPOISelectedCalled, "Should call onPOISelected callback")
        XCTAssertNotNil(selectedPOI, "Should provide selected POI for replacement")
        XCTAssertEqual(selectedPOI?.id, testPOIs[0].id, "Should select first available POI")
    }
    
    // MARK: - Empty Alternatives Handling Tests
    
    func testEditPOIFlowWithNoAlternatives() {
        // Given
        let emptyPOIs: [POI] = []
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        
        // When
        service.configure(with: config, availablePOIs: emptyPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertFalse(service.hasCurrentCard(), "Should not have cards when no alternatives")
        XCTAssertEqual(service.swipeCards.count, 0, "Should have empty card stack")
        XCTAssertEqual(service.getVisibleCards().count, 0, "Should have no visible cards")
    }
    
    // MARK: - Wikipedia Enrichment Integration Tests
    
    func testEditPOIFlowWithWikipediaData() {
        // Given
        let enrichedData = createMockWikipediaData()
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        
        // When
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: enrichedData)
        
        // Then
        XCTAssertEqual(service.swipeCards.count, testPOIs.count, "Should create cards with enrichment data")
        
        // Check that enrichment data is available
        let firstCard = service.swipeCards.first
        XCTAssertNotNil(firstCard?.enrichedData, "Should have enriched data for cards")
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testEditPOIFlowAccessibilityConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        
        // Then - verify configuration supports accessibility
        XCTAssertTrue(config.isEditFlow, "Should be identified as edit flow")
        XCTAssertFalse(config.isManualFlow, "Should not be identified as manual flow")
        
        // Note: Specific accessibility identifier testing would be done in UI tests
        // This test verifies the configuration supports the expected flow identification
    }
    
    // MARK: - Performance Integration Tests
    
    func testEditPOIFlowPerformanceOptimizations() {
        // Given
        let largePOISet = createSamplePOIs(count: 20)
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        service.configure(with: config, availablePOIs: largePOISet, enrichedPOIs: [:])
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        let configurationTime = endTime - startTime
        XCTAssertLessThan(configurationTime, 0.1, "Edit flow configuration should be very fast")
        
        // Verify optimization for edit flow
        let visibleCards = service.getVisibleCards()
        XCTAssertLessThanOrEqual(visibleCards.count, 3, "Should limit visible cards for performance")
    }
    
    // MARK: - Flow Transition Integration Tests
    
    func testEditPOIFlowTransitionBehavior() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When simulating immediate selection and dismissal
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertEqual(mockSelection.selectedPOIs.count, 1, "Should have one selection")
        XCTAssertEqual(config.autoCloseDelay, 0.3, "Should have brief animation delay before close")
        
        // Verify quick transition behavior
        XCTAssertTrue(config.autoConfirmSelection, "Should auto-confirm for quick transition")
        XCTAssertFalse(config.allowContinuousSwipe, "Should not allow additional swiping")
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePOIs(count: Int) -> [POI] {
        return (0..<count).map { index in
            createSamplePOI(name: "Alternative POI \(index)")
        }
    }
    
    private func createSamplePOI(name: String) -> POI {
        return POI(
            id: UUID().uuidString,
            name: name,
            latitude: 49.4521 + Double(Int.random(in: -100...100)) * 0.001,
            longitude: 11.0767 + Double(Int.random(in: -100...100)) * 0.001,
            category: .attraction,
            description: "Test POI for edit POI integration testing",
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
                category: .attraction,
                poiId: "route_poi_\(index)"
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
    
    private func createMockWikipediaData() -> [String: WikipediaEnrichedPOI] {
        let poi = testPOIs[0]
        let enrichedPOI = WikipediaEnrichedPOI(
            basePOI: poi,
            wikipediaTitle: "Test Wikipedia Title",
            shortDescription: "Test short description",
            enhancedDescription: "Test enhanced description",
            wikipediaImageURL: "https://example.com/image.jpg"
        )
        return [poi.id: enrichedPOI]
    }
}
