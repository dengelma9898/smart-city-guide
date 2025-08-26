//
//  GeoapifyAPIServiceTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-26
//  Unit tests for GeoapifyAPIService - POI discovery and API integration
//

import XCTest
import CoreLocation
@testable import SmartCityGuide

@MainActor
class GeoapifyAPIServiceTests: XCTestCase {
    
    var apiService: GeoapifyAPIService!
    
    override func setUp() {
        super.setUp()
        
        // Initialize API service with shared instance
        apiService = GeoapifyAPIService.shared
    }
    
    override func tearDown() {
        apiService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testGeoapifyAPIServiceInitialization() {
        // Then
        XCTAssertNotNil(apiService, "GeoapifyAPIService should initialize successfully")
        XCTAssertFalse(apiService.isLoading, "Should not be loading initially")
        XCTAssertNil(apiService.errorMessage, "Should not have error message initially")
    }
    
    // MARK: - Basic Configuration Tests
    
    func testAPIServiceConfiguration() {
        // Test that the service is properly configured
        XCTAssertNotNil(apiService, "API service should be configured")
        
        // Test initial state
        XCTAssertFalse(apiService.isLoading, "Should not be loading on init")
        XCTAssertNil(apiService.errorMessage, "Error message should be nil on init")
    }
    
    // MARK: - Category Mapping Tests
    
    func testPlaceCategoryToGeoapifyMapping() {
        // Test that essential place categories are defined
        let essentialCategories = PlaceCategory.geoapifyEssentialCategories
        
        XCTAssertFalse(essentialCategories.isEmpty, "Should have essential categories")
        XCTAssertTrue(essentialCategories.contains(.attraction), "Should include attractions")
        XCTAssertTrue(essentialCategories.contains(.museum), "Should include museums")
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateManagement() {
        // Initially not loading
        XCTAssertFalse(apiService.isLoading, "Should not be loading initially")
        
        // Test that we can change loading state (for manual testing)
        apiService.isLoading = true
        XCTAssertTrue(apiService.isLoading, "Loading state should be changeable")
        
        apiService.isLoading = false
        XCTAssertFalse(apiService.isLoading, "Loading state should be resetable")
    }
}
