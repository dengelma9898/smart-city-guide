//
//  SwipeFlowConfigurationTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-22
//  Unit tests for SwipeFlowConfiguration enum
//

import XCTest
@testable import SmartCityGuide

class SwipeFlowConfigurationTests: XCTestCase {
    
    // MARK: - Manual Flow Configuration Tests
    
    func testManualFlowConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.manual
        
        // Then
        XCTAssertTrue(config.showSelectionCounter, "Manual flow should show selection counter")
        XCTAssertTrue(config.showConfirmButton, "Manual flow should show confirm button")
        XCTAssertFalse(config.autoConfirmSelection, "Manual flow should not auto-confirm selection")
        XCTAssertTrue(config.allowContinuousSwipe, "Manual flow should allow continuous swiping")
        XCTAssertEqual(config.onAbortBehavior, .clearSelections, "Manual flow should clear selections on abort")
        XCTAssertTrue(config.excludedPOIs.isEmpty, "Manual flow should not exclude any POIs")
    }
    
    // MARK: - Add POI Flow Configuration Tests
    
    func testAddPOIFlowConfiguration() {
        // Given
        let config = SwipeFlowConfiguration.addPOI
        
        // Then
        XCTAssertTrue(config.showSelectionCounter, "Add POI flow should show selection counter")
        XCTAssertTrue(config.showConfirmButton, "Add POI flow should show confirm button")
        XCTAssertFalse(config.autoConfirmSelection, "Add POI flow should not auto-confirm selection")
        XCTAssertTrue(config.allowContinuousSwipe, "Add POI flow should allow continuous swiping")
        XCTAssertEqual(config.onAbortBehavior, .clearSelections, "Add POI flow should clear selections on abort")
        XCTAssertTrue(config.excludedPOIs.isEmpty, "Add POI flow should not exclude POIs by default")
    }
    
    // MARK: - Edit POI Flow Configuration Tests
    
    func testEditPOIFlowConfiguration() {
        // Given
        let excludedPOI = createSamplePOI(name: "Test POI")
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: [excludedPOI])
        
        // Then
        XCTAssertFalse(config.showSelectionCounter, "Edit POI flow should not show selection counter")
        XCTAssertFalse(config.showConfirmButton, "Edit POI flow should not show confirm button")
        XCTAssertTrue(config.autoConfirmSelection, "Edit POI flow should auto-confirm selection")
        XCTAssertFalse(config.allowContinuousSwipe, "Edit POI flow should not allow continuous swiping")
        XCTAssertEqual(config.onAbortBehavior, .keepSelections, "Edit POI flow should keep selections on abort")
        XCTAssertEqual(config.excludedPOIs.count, 1, "Edit POI flow should exclude provided POIs")
        XCTAssertEqual(config.excludedPOIs.first?.id, excludedPOI.id, "Edit POI flow should exclude the correct POI")
    }
    
    // MARK: - Flow Identification Tests
    
    func testFlowIdentification() {
        // Given
        let manualConfig = SwipeFlowConfiguration.manual
        let addConfig = SwipeFlowConfiguration.addPOI
        let editConfig = SwipeFlowConfiguration.editPOI(excludedPOIs: [])
        
        // Then
        XCTAssertTrue(manualConfig.isManualFlow, "Manual config should be identified as manual flow")
        XCTAssertFalse(manualConfig.isEditFlow, "Manual config should not be identified as edit flow")
        
        XCTAssertTrue(addConfig.isManualFlow, "Add POI config should be identified as manual flow")
        XCTAssertFalse(addConfig.isEditFlow, "Add POI config should not be identified as edit flow")
        
        XCTAssertFalse(editConfig.isManualFlow, "Edit config should not be identified as manual flow")
        XCTAssertTrue(editConfig.isEditFlow, "Edit config should be identified as edit flow")
    }
    
    // MARK: - POI Filtering Tests
    
    func testPOIFiltering() {
        // Given
        let poi1 = createSamplePOI(name: "POI 1")
        let poi2 = createSamplePOI(name: "POI 2")
        let poi3 = createSamplePOI(name: "POI 3")
        let allPOIs = [poi1, poi2, poi3]
        
        let editConfig = SwipeFlowConfiguration.editPOI(excludedPOIs: [poi2])
        
        // When
        let filteredPOIs = editConfig.filterPOIs(allPOIs)
        
        // Then
        XCTAssertEqual(filteredPOIs.count, 2, "Should filter out excluded POI")
        XCTAssertTrue(filteredPOIs.contains(where: { $0.id == poi1.id }), "Should include non-excluded POI 1")
        XCTAssertFalse(filteredPOIs.contains(where: { $0.id == poi2.id }), "Should exclude specified POI 2")
        XCTAssertTrue(filteredPOIs.contains(where: { $0.id == poi3.id }), "Should include non-excluded POI 3")
    }
    
    func testPOIFilteringWithEmptyExclusions() {
        // Given
        let poi1 = createSamplePOI(name: "POI 1")
        let poi2 = createSamplePOI(name: "POI 2")
        let allPOIs = [poi1, poi2]
        
        let manualConfig = SwipeFlowConfiguration.manual
        
        // When
        let filteredPOIs = manualConfig.filterPOIs(allPOIs)
        
        // Then
        XCTAssertEqual(filteredPOIs.count, 2, "Should not filter any POIs when no exclusions")
        XCTAssertEqual(filteredPOIs, allPOIs, "Should return all POIs unchanged")
    }
    
    // MARK: - Configuration Customization Tests
    
    func testEditPOIConfigurationWithMultipleExclusions() {
        // Given
        let poi1 = createSamplePOI(name: "POI 1")
        let poi2 = createSamplePOI(name: "POI 2")
        let excludedPOIs = [poi1, poi2]
        
        // When
        let config = SwipeFlowConfiguration.editPOI(excludedPOIs: excludedPOIs)
        
        // Then
        XCTAssertEqual(config.excludedPOIs.count, 2, "Should handle multiple excluded POIs")
        XCTAssertTrue(config.excludedPOIs.contains(where: { $0.id == poi1.id }), "Should exclude POI 1")
        XCTAssertTrue(config.excludedPOIs.contains(where: { $0.id == poi2.id }), "Should exclude POI 2")
    }
    
    // MARK: - Helper Methods
    
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
