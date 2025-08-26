//
//  RouteServiceTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-26
//  Unit tests for RouteService - Central route generation logic
//

import XCTest
import CoreLocation
import MapKit
@testable import SmartCityGuide

@MainActor
class RouteServiceTests: XCTestCase {
    
    var routeService: RouteService!
    
    override func setUp() {
        super.setUp()
        
        // Initialize RouteService with default dependencies
        routeService = RouteService()
    }
    
    override func tearDown() {
        routeService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testRouteServiceInitialization() {
        // Then
        XCTAssertNotNil(routeService, "RouteService should initialize successfully")
        XCTAssertFalse(routeService.isGenerating, "Should not be generating initially")
        XCTAssertNil(routeService.generatedRoute, "Should have no generated route initially")
        XCTAssertNil(routeService.errorMessage, "Should have no error message initially")
    }
    
    func testRouteServiceWithCustomDependencies() {
        // Given
        let mockRouteGeneration = RouteGenerationService()
        let mockMapKitService = MapKitRouteService()
        let mockLocationResolver = LocationResolverService()
        let mockPOIDiscovery = POIDiscoveryService()
        let mockRouteOptimization = RouteOptimizationService()
        let mockRouteValidation = RouteValidationService()
        
        // When
        let customRouteService = RouteService(
            routeGenerationService: mockRouteGeneration,
            mapKitService: mockMapKitService,
            locationResolver: mockLocationResolver,
            poiDiscoveryService: mockPOIDiscovery,
            routeOptimizationService: mockRouteOptimization,
            routeValidationService: mockRouteValidation
        )
        
        // Then
        XCTAssertNotNil(customRouteService, "RouteService should initialize with custom dependencies")
        XCTAssertFalse(customRouteService.isGenerating, "Should not be generating initially")
    }
    
    // MARK: - State Management Tests
    
    func testInitialState() {
        // Then
        XCTAssertFalse(routeService.isGenerating, "Should not be generating on initialization")
        XCTAssertNil(routeService.generatedRoute, "Should have no route on initialization")
        XCTAssertNil(routeService.errorMessage, "Should have no error on initialization")
    }
    
    func testHistoryManagerSetting() {
        // Given
        let mockHistoryManager = RouteHistoryManager()
        
        // When
        routeService.setHistoryManager(mockHistoryManager)
        
        // Then - just verify it doesn't crash
        XCTAssertNotNil(routeService, "Setting history manager should not affect service")
    }
}
