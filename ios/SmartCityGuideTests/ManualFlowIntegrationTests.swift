//
//  ManualFlowIntegrationTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-22
//  Integration tests for UnifiedSwipeView in Manual flow
//

import XCTest
import SwiftUI
@testable import SmartCityGuide

@MainActor
class ManualFlowIntegrationTests: XCTestCase {
    
    var mockSelection: ManualPOISelection!
    var testPOIs: [POI]!
    var testConfig: ManualRouteConfig!
    
    override func setUp() {
        super.setUp()
        mockSelection = ManualPOISelection()
        testPOIs = createSamplePOIs(count: 5)
        testConfig = ManualRouteConfig(
            startingCity: "Test City",
            startingCoordinates: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767),
            usingCurrentLocation: false,
            endpointOption: .roundtrip,
            customEndpoint: "",
            customEndpointCoordinates: nil
        )
    }
    
    override func tearDown() {
        mockSelection = nil
        testPOIs = nil
        testConfig = nil
        super.tearDown()
    }
    
    // MARK: - Manual Flow Configuration Tests
    
    func testManualFlowUsesCorrectConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.manual
        
        // Then
        XCTAssertTrue(config.showSelectionCounter, "Manual flow should show selection counter")
        XCTAssertTrue(config.showConfirmButton, "Manual flow should show confirm button")
        XCTAssertFalse(config.autoConfirmSelection, "Manual flow should not auto-confirm")
        XCTAssertTrue(config.allowContinuousSwipe, "Manual flow should allow continuous swiping")
        XCTAssertEqual(config.onAbortBehavior, .clearSelections, "Manual flow should clear selections on abort")
    }
    
    // MARK: - POI Selection Integration Tests
    
    func testManualFlowPOISelection() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When selecting POIs
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertEqual(mockSelection.selectedPOIs.count, 3, "Should accumulate selected POIs")
        XCTAssertTrue(service.allowsContinuousSwipe, "Should allow continuous selection")
        XCTAssertTrue(service.hasCurrentCard(), "Should still have cards available")
    }
    
    func testManualFlowSelectionCounter() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        service.selectCurrentCard(selection: mockSelection)
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        let selectionCount = service.getSelectionCount(selection: mockSelection)
        XCTAssertEqual(selectionCount, 2, "Should track selection count correctly")
        XCTAssertTrue(service.shouldShowSelectionCounter, "Should show selection counter in manual flow")
    }
    
    func testManualFlowConfirmButtonVisibility() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When no selections
        XCTAssertFalse(mockSelection.hasSelections, "Should not have selections initially")
        
        // When has selections
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(mockSelection.hasSelections, "Should have selections after selection")
        XCTAssertTrue(service.shouldShowConfirmButton, "Should show confirm button in manual flow")
    }
    
    // MARK: - Card Recycling Integration Tests
    
    func testManualFlowCardRecycling() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When rejecting cards
        service.rejectCurrentCard(selection: mockSelection)
        service.rejectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(service.canRecycleCards(), "Should have recyclable cards")
        
        // When recycling
        service.recycleRejectedCards()
        
        // Then
        XCTAssertTrue(service.hasCurrentCard(), "Should have cards available after recycling")
        XCTAssertEqual(mockSelection.rejectedPOIs.count, 2, "Should preserve rejected POI tracking")
    }
    
    // MARK: - Progress Tracking Integration Tests
    
    func testManualFlowProgressTracking() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let initialProgress = service.getProgress()
        service.selectCurrentCard(selection: mockSelection)
        let updatedProgress = service.getProgress()
        
        // Then
        XCTAssertEqual(initialProgress.current, 0, "Should start at index 0")
        XCTAssertEqual(initialProgress.total, testPOIs.count, "Should track total POI count")
        XCTAssertEqual(updatedProgress.current, 1, "Should advance progress after selection")
    }
    
    // MARK: - Toast Message Integration Tests
    
    func testManualFlowToastMessages() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When selecting POI
        service.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(config.showToastMessages, "Manual flow should show toast messages")
        // Note: Toast visibility is time-based and tested in UnifiedSwipeServiceTests
    }
    
    // MARK: - Route Generation Integration Tests
    
    func testManualFlowRouteGenerationReadiness() {
        // Given
        mockSelection.selectPOI(testPOIs[0])
        mockSelection.selectPOI(testPOIs[1])
        
        // Then
        XCTAssertTrue(mockSelection.canGenerateRoute, "Should be able to generate route with selections")
        XCTAssertEqual(mockSelection.selectedPOIs.count, 2, "Should have correct selection count for route generation")
    }
    
    func testManualFlowEmptySelectionHandling() {
        // Given - no selections
        
        // Then
        XCTAssertFalse(mockSelection.canGenerateRoute, "Should not be able to generate route without selections")
        XCTAssertFalse(mockSelection.hasSelections, "Should not have selections initially")
    }
    
    // MARK: - Reset Functionality Integration Tests
    
    func testManualFlowResetPreservesConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When making selections and resetting
        service.selectCurrentCard(selection: mockSelection)
        service.resetToBeginning()
        
        // Then
        XCTAssertEqual(service.currentCardIndex, 0, "Should reset to first card")
        XCTAssertTrue(service.shouldShowSelectionCounter, "Should preserve flow configuration after reset")
        XCTAssertTrue(service.shouldShowConfirmButton, "Should preserve flow configuration after reset")
    }
    
    // MARK: - Abort Behavior Integration Tests
    
    func testManualFlowAbortBehavior() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockSelection.selectPOI(testPOIs[0])
        mockSelection.selectPOI(testPOIs[1])
        
        // When aborting (simulated by clearing according to config)
        if config.onAbortBehavior == .clearSelections {
            mockSelection.reset()
        }
        
        // Then
        XCTAssertFalse(mockSelection.hasSelections, "Should clear selections on abort")
        XCTAssertEqual(mockSelection.selectedPOIs.count, 0, "Should have no selected POIs after abort")
    }
    
    // MARK: - Wikipedia Enrichment Integration Tests
    
    func testManualFlowWithWikipediaEnrichment() {
        // Given
        let enrichedData = createMockWikipediaData()
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        
        // When
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: enrichedData)
        
        // Then
        XCTAssertEqual(service.swipeCards.count, testPOIs.count, "Should create cards for all POIs")
        
        // Check that enrichment data is available
        let firstCard = service.swipeCards.first
        XCTAssertNotNil(firstCard?.enrichedData, "Should have enriched data for cards")
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testManualFlowAccessibilityConfiguration() {
        // Test that manual flow maintains required accessibility identifiers
        // This is important for UI tests to continue working
        
        // Given
        let config = SwipeFlowConfiguration.manual
        
        // Then - verify expected accessibility properties exist
        XCTAssertTrue(config.showSelectionCounter, "Selection counter should be accessible")
        XCTAssertTrue(config.showConfirmButton, "Confirm button should be accessible")
        
        // Note: Actual accessibility identifier testing would be done in UI tests
        // This test just verifies the configuration supports the required UI elements
    }
    
    // MARK: - Performance Integration Tests
    
    func testManualFlowWithLargePOISet() {
        // Given
        let largePOISet = createSamplePOIs(count: 100)
        let config = SwipeFlowConfiguration.manual
        let service = UnifiedSwipeService()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        service.configure(with: config, availablePOIs: largePOISet, enrichedPOIs: [:])
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        let configurationTime = endTime - startTime
        XCTAssertLessThan(configurationTime, 1.0, "Configuration should complete within 1 second for 100 POIs")
        XCTAssertEqual(service.swipeCards.count, 100, "Should handle large POI sets")
        
        // Verify visible cards optimization
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
            latitude: 49.4521,
            longitude: 11.0767,
            category: .attraction,
            description: "Test POI for integration testing",
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
