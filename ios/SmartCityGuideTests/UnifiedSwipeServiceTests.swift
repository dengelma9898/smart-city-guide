//
//  UnifiedSwipeServiceTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-22
//  Unit tests for UnifiedSwipeService
//

import XCTest
@testable import SmartCityGuide

@MainActor
class UnifiedSwipeServiceTests: XCTestCase {
    
    var service: UnifiedSwipeService!
    var mockManualSelection: ManualPOISelection!
    
    override func setUp() {
        super.setUp()
        service = UnifiedSwipeService()
        mockManualSelection = ManualPOISelection()
    }
    
    override func tearDown() {
        service = nil
        mockManualSelection = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testServiceInitialization() {
        // Then
        XCTAssertNotNil(service, "Service should initialize successfully")
        XCTAssertTrue(service.swipeCards.isEmpty, "Service should start with empty cards")
        XCTAssertEqual(service.currentCardIndex, 0, "Service should start with index 0")
        XCTAssertNil(service.currentConfiguration, "Service should start without configuration")
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureWithManualFlow() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        
        // When
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertEqual(service.currentConfiguration?.description, config.description, "Should store configuration")
        XCTAssertEqual(service.swipeCards.count, 3, "Should create cards for all POIs")
        XCTAssertEqual(service.currentCardIndex, 0, "Should reset to first card")
    }
    
    func testConfigureWithEditFlow() {
        // Given
        let excludedPOI = createSamplePOI(name: "Excluded POI")
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [excludedPOI])
        let allPOIs = createSamplePOIs(count: 3) + [excludedPOI]
        
        // When
        service.configure(with: config, availablePOIs: allPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertEqual(service.swipeCards.count, 3, "Should filter out excluded POI")
        XCTAssertFalse(service.swipeCards.contains(where: { $0.poi.id == excludedPOI.id }), "Should not include excluded POI")
    }
    
    // MARK: - Card Stack Management Tests
    
    func testGetVisibleCards() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 5)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let visibleCards = service.getVisibleCards()
        
        // Then
        XCTAssertLessthan(visibleCards.count, 4, "Should return max 3 visible cards")
        XCTAssertEqual(visibleCards.first?.poi.id, testPOIs.first?.id, "First visible card should match first POI")
    }
    
    func testHasCurrentCard() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 2)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // Then
        XCTAssertTrue(service.hasCurrentCard(), "Should have current card at start")
        
        // When advancing past all cards
        service.currentCardIndex = 2
        
        // Then
        XCTAssertFalse(service.hasCurrentCard(), "Should not have current card after all processed")
    }
    
    func testGetCurrentPOI() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let currentPOI = service.getCurrentPOI()
        
        // Then
        XCTAssertNotNil(currentPOI, "Should return current POI")
        XCTAssertEqual(currentPOI?.id, testPOIs[0].id, "Should return first POI initially")
        
        // When advancing
        service.advanceToNextCard()
        let nextPOI = service.getCurrentPOI()
        
        // Then
        XCTAssertEqual(nextPOI?.id, testPOIs[1].id, "Should return next POI after advancing")
    }
    
    // MARK: - Card Action Handling Tests
    
    func testHandleAcceptAction() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        let initialIndex = service.currentCardIndex
        
        // When
        service.handleCardAction(.accept(testPOIs[0]), selection: mockManualSelection)
        
        // Then
        XCTAssertEqual(service.currentCardIndex, initialIndex + 1, "Should advance to next card")
        XCTAssertTrue(mockManualSelection.selectedPOIs.contains(where: { $0.id == testPOIs[0].id }), "Should add POI to selection")
    }
    
    func testHandleRejectAction() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        let initialIndex = service.currentCardIndex
        
        // When
        service.handleCardAction(.reject(testPOIs[0]), selection: mockManualSelection)
        
        // Then
        XCTAssertEqual(service.currentCardIndex, initialIndex + 1, "Should advance to next card")
        XCTAssertTrue(mockManualSelection.rejectedPOIs.contains(where: { $0.id == testPOIs[0].id }), "Should add POI to rejected list")
    }
    
    func testHandleSkipAction() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        let initialIndex = service.currentCardIndex
        
        // When
        service.handleCardAction(.skip, selection: mockManualSelection)
        
        // Then
        XCTAssertEqual(service.currentCardIndex, initialIndex + 1, "Should advance to next card")
        XCTAssertFalse(mockManualSelection.selectedPOIs.contains(where: { $0.id == testPOIs[0].id }), "Should not add POI to selection")
        XCTAssertFalse(mockManualSelection.rejectedPOIs.contains(where: { $0.id == testPOIs[0].id }), "Should not add POI to rejected list")
    }
    
    // MARK: - Card Recycling Tests
    
    func testCardRecycling() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When rejecting all cards
        for poi in testPOIs {
            service.handleCardAction(.reject(poi), selection: mockManualSelection)
        }
        
        // Then
        XCTAssertFalse(service.hasCurrentCard(), "Should not have current card after processing all")
        
        // When recycling
        service.recycleRejectedCards()
        
        // Then
        XCTAssertTrue(service.hasCurrentCard(), "Should have current card after recycling")
        XCTAssertEqual(service.currentCardIndex, 0, "Should reset to first card")
        XCTAssertEqual(service.swipeCards.count, testPOIs.count, "Should have all cards available again")
    }
    
    func testCardRecyclingPreservesSelection() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When accepting one and rejecting others
        service.handleCardAction(.accept(testPOIs[0]), selection: mockManualSelection)
        service.handleCardAction(.reject(testPOIs[1]), selection: mockManualSelection)
        service.handleCardAction(.reject(testPOIs[2]), selection: mockManualSelection)
        
        // Then
        XCTAssertEqual(mockManualSelection.selectedPOIs.count, 1, "Should have one selected POI")
        
        // When recycling
        service.recycleRejectedCards()
        
        // Then
        XCTAssertEqual(mockManualSelection.selectedPOIs.count, 1, "Should preserve selected POIs after recycling")
        XCTAssertEqual(service.swipeCards.count, 2, "Should only recycle rejected cards")
    }
    
    // MARK: - Progress Tracking Tests
    
    func testGetProgress() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 5)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        
        // When
        let initialProgress = service.getProgress()
        
        // Then
        XCTAssertEqual(initialProgress.current, 0, "Should start at index 0")
        XCTAssertEqual(initialProgress.total, 5, "Should have total count of 5")
        
        // When advancing
        service.advanceToNextCard()
        let updatedProgress = service.getProgress()
        
        // Then
        XCTAssertEqual(updatedProgress.current, 1, "Should update current index")
        XCTAssertEqual(updatedProgress.total, 5, "Should keep same total")
    }
    
    // MARK: - Reset and Cleanup Tests
    
    func testResetToBeginning() {
        // Given
        let config = SwipeFlowConfiguration.manual
        let testPOIs = createSamplePOIs(count: 3)
        service.configure(with: config, availablePOIs: testPOIs, enrichedPOIs: [:])
        service.advanceToNextCard()
        service.showToastMessage("Test message")
        
        // When
        service.resetToBeginning()
        
        // Then
        XCTAssertEqual(service.currentCardIndex, 0, "Should reset card index")
        XCTAssertFalse(service.showToast, "Should clear toast")
        XCTAssertNil(service.toastMessage, "Should clear toast message")
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
