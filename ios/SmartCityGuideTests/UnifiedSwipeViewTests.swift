//
//  UnifiedSwipeViewTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-22
//  Unit tests for UnifiedSwipeView SwiftUI component
//

import XCTest
import SwiftUI
@testable import SmartCityGuide

@MainActor
class UnifiedSwipeViewTests: XCTestCase {
    
    var mockService: UnifiedSwipeService!
    var mockSelection: ManualPOISelection!
    var testPOIs: [POI]!
    
    override func setUp() {
        super.setUp()
        mockService = UnifiedSwipeService()
        mockSelection = ManualPOISelection()
        testPOIs = createSamplePOIs(count: 5)
    }
    
    override func tearDown() {
        mockService = nil
        mockSelection = nil
        testPOIs = nil
        super.tearDown()
    }
    
    // MARK: - Component Configuration Tests
    
    func testUnifiedSwipeViewManualConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertTrue(mockService.shouldShowSelectionCounter, "Manual flow should show selection counter")
        XCTAssertTrue(mockService.shouldShowConfirmButton, "Manual flow should show confirm button")
        XCTAssertFalse(mockService.shouldAutoConfirm, "Manual flow should not auto-confirm")
        XCTAssertTrue(mockService.allowsContinuousSwipe, "Manual flow should allow continuous swiping")
    }
    
    func testUnifiedSwipeViewEditConfiguration() {
        // Given
        let excludedPOI = testPOIs[0]
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [excludedPOI])
        let filteredPOIs = Array(testPOIs.dropFirst()) // Remove first POI
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertFalse(mockService.shouldShowSelectionCounter, "Edit flow should not show selection counter")
        XCTAssertFalse(mockService.shouldShowConfirmButton, "Edit flow should not show confirm button")
        XCTAssertTrue(mockService.shouldAutoConfirm, "Edit flow should auto-confirm")
        XCTAssertFalse(mockService.allowsContinuousSwipe, "Edit flow should not allow continuous swiping")
        XCTAssertEqual(mockService.swipeCards.count, 4, "Should filter out excluded POI")
    }
    
    // MARK: - Card Display Tests
    
    func testVisibleCardsLimit() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let visibleCards = mockService.getVisibleCards()
        
        // Then
        XCTAssertLessThanOrEqual(visibleCards.count, 3, "Should display maximum 3 visible cards")
        XCTAssertGreaterThan(visibleCards.count, 0, "Should display at least 1 card")
    }
    
    func testCardStackOrdering() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let visibleCards = mockService.getVisibleCards()
        
        // Then
        XCTAssertEqual(visibleCards.first?.poi.id, testPOIs[0].id, "First visible card should match first POI")
        if visibleCards.count > 1 {
            XCTAssertEqual(visibleCards[1].poi.id, testPOIs[1].id, "Second visible card should match second POI")
        }
    }
    
    // MARK: - Action Button Tests
    
    func testManualAcceptAction() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        let initialIndex = mockService.currentCardIndex
        let initialSelectionCount = mockSelection.selectedPOIs.count
        
        // When
        mockService.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertEqual(mockService.currentCardIndex, initialIndex + 1, "Should advance card index")
        XCTAssertEqual(mockSelection.selectedPOIs.count, initialSelectionCount + 1, "Should add POI to selection")
        XCTAssertTrue(mockSelection.selectedPOIs.contains(where: { $0.id == testPOIs[0].id }), "Should select first POI")
    }
    
    func testManualRejectAction() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        let initialIndex = mockService.currentCardIndex
        let initialRejectionCount = mockSelection.rejectedPOIs.count
        
        // When
        mockService.rejectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertEqual(mockService.currentCardIndex, initialIndex + 1, "Should advance card index")
        XCTAssertEqual(mockSelection.rejectedPOIs.count, initialRejectionCount + 1, "Should add POI to rejected list")
        XCTAssertTrue(mockSelection.rejectedPOIs.contains(where: { $0.id == testPOIs[0].id }), "Should reject first POI")
    }
    
    func testManualSkipAction() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        let initialIndex = mockService.currentCardIndex
        let initialSelectionCount = mockSelection.selectedPOIs.count
        let initialRejectionCount = mockSelection.rejectedPOIs.count
        
        // When
        mockService.skipCurrentCard()
        
        // Then
        XCTAssertEqual(mockService.currentCardIndex, initialIndex + 1, "Should advance card index")
        XCTAssertEqual(mockSelection.selectedPOIs.count, initialSelectionCount, "Should not change selection count")
        XCTAssertEqual(mockSelection.rejectedPOIs.count, initialRejectionCount, "Should not change rejection count")
    }
    
    // MARK: - Flow-Specific Behavior Tests
    
    func testEditFlowAutoConfirm() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        mockService.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(mockService.shouldAutoConfirm, "Edit flow should auto-confirm")
        XCTAssertEqual(mockSelection.selectedPOIs.count, 1, "Should select POI in edit flow")
    }
    
    func testManualFlowContinuousSwipe() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When selecting multiple POIs
        mockService.selectCurrentCard(selection: mockSelection)
        mockService.selectCurrentCard(selection: mockSelection)
        mockService.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(mockService.allowsContinuousSwipe, "Manual flow should allow continuous swiping")
        XCTAssertEqual(mockSelection.selectedPOIs.count, 3, "Should allow multiple selections")
        XCTAssertTrue(mockService.hasCurrentCard(), "Should still have cards available")
    }
    
    // MARK: - Selection Counter Tests
    
    func testSelectionCountDisplay() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        mockService.selectCurrentCard(selection: mockSelection)
        mockService.selectCurrentCard(selection: mockSelection)
        
        // Then
        let selectionCount = mockService.getSelectionCount(selection: mockSelection)
        XCTAssertEqual(selectionCount, 2, "Should return correct selection count")
        XCTAssertTrue(mockService.shouldShowSelectionCounter, "Manual flow should show selection counter")
    }
    
    func testEditFlowHidesSelectionCounter() {
        // Given
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertFalse(mockService.shouldShowSelectionCounter, "Edit flow should hide selection counter")
    }
    
    // MARK: - Progress Tracking Tests
    
    func testProgressTracking() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let initialProgress = mockService.getProgress()
        mockService.advanceToNextCard()
        let updatedProgress = mockService.getProgress()
        
        // Then
        XCTAssertEqual(initialProgress.current, 0, "Should start at index 0")
        XCTAssertEqual(initialProgress.total, testPOIs.count, "Should have correct total count")
        XCTAssertEqual(updatedProgress.current, 1, "Should advance progress")
        XCTAssertEqual(updatedProgress.total, testPOIs.count, "Should maintain total count")
    }
    
    // MARK: - Card Recycling Integration Tests
    
    func testCardRecyclingIntegration() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When rejecting cards to enable recycling
        mockService.rejectCurrentCard(selection: mockSelection)
        mockService.rejectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertTrue(mockService.canRecycleCards(), "Should have recyclable cards")
        
        // When recycling
        mockService.recycleRejectedCards()
        
        // Then
        XCTAssertTrue(mockService.hasCurrentCard(), "Should have cards available after recycling")
    }
    
    // MARK: - Empty Stack Handling Tests
    
    func testEmptyStackBehavior() {
        // Given
        let singlePOI = [testPOIs[0]]
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: singlePOI, enrichedPOIs: [:])
        
        // When processing the only card
        mockService.selectCurrentCard(selection: mockSelection)
        
        // Then
        XCTAssertFalse(mockService.hasCurrentCard(), "Should not have current card after processing all")
        XCTAssertEqual(mockService.getVisibleCards().count, 0, "Should have no visible cards")
    }
    
    // MARK: - Reset Functionality Tests
    
    func testResetToBeginning() {
        // Given
        let config = SwipeFlowConfiguration.manual
        mockService.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When advancing and then resetting
        mockService.selectCurrentCard(selection: mockSelection)
        mockService.selectCurrentCard(selection: mockSelection)
        mockService.resetToBeginning()
        
        // Then
        XCTAssertEqual(mockService.currentCardIndex, 0, "Should reset to beginning")
        XCTAssertTrue(mockService.hasCurrentCard(), "Should have current card after reset")
        XCTAssertEqual(mockService.getVisibleCards().count, min(3, testPOIs.count), "Should have visible cards after reset")
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
            description: "Test POI for unit testing",
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
}
