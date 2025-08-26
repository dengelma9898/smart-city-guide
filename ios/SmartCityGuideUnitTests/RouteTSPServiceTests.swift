//
//  RouteTSPServiceTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-26
//  Unit tests for RouteTSPService - TSP algorithm optimization
//

import XCTest
import CoreLocation
@testable import SmartCityGuide

@MainActor
class RouteTSPServiceTests: XCTestCase {
    
    var tspService: RouteTSPService!
    
    override func setUp() {
        super.setUp()
        tspService = RouteTSPService()
    }
    
    override func tearDown() {
        tspService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testTSPServiceInitialization() {
        // Then
        XCTAssertNotNil(tspService, "RouteTSPService should initialize successfully")
    }
    
    // MARK: - Basic TSP Algorithm Tests
    
    func testOptimizeWaypointOrderWithMinimumPoints() {
        // Given - 2 route points (minimum for TSP)
        let routePoints = createTestRoutePoints(count: 2)
        
        // When
        let optimizedRoute = tspService.optimizeWaypointOrder(routePoints)
        
        // Then
        XCTAssertEqual(optimizedRoute.count, 2, "Should return all route points")
        XCTAssertNotNil(optimizedRoute.first, "Should have first point")
        XCTAssertNotNil(optimizedRoute.last, "Should have last point")
    }
    
    func testOptimizeWaypointOrderWithMultiplePoints() {
        // Given - 5 route points
        let routePoints = createTestRoutePoints(count: 5)
        
        // When
        let optimizedRoute = tspService.optimizeWaypointOrder(routePoints)
        
        // Then
        XCTAssertEqual(optimizedRoute.count, 5, "Should return all route points")
        
        // Test that all original points are present
        for originalPoint in routePoints {
            XCTAssertTrue(optimizedRoute.contains { $0.name == originalPoint.name }, 
                         "Should contain original point: \(originalPoint.name)")
        }
    }
    
    func testOptimizeEmptyWaypointOrder() {
        // Given - empty route
        let routePoints: [RoutePoint] = []
        
        // When
        let optimizedRoute = tspService.optimizeWaypointOrder(routePoints)
        
        // Then
        XCTAssertTrue(optimizedRoute.isEmpty, "Should return empty array for empty input")
    }
    
    func testOptimizeSingleWaypoint() {
        // Given - single route point
        let routePoints = createTestRoutePoints(count: 1)
        
        // When
        let optimizedRoute = tspService.optimizeWaypointOrder(routePoints)
        
        // Then
        XCTAssertEqual(optimizedRoute.count, 1, "Should return single point")
        XCTAssertEqual(optimizedRoute.first?.name, routePoints.first?.name, "Should be same point")
    }
    
    // MARK: - Helper Methods
    
    private func createTestRoutePoints(count: Int) -> [RoutePoint] {
        guard count > 0 else { return [] }
        
        var points: [RoutePoint] = []
        
        // Create points around Nürnberg area
        let baseLatitude = 49.4521
        let baseLongitude = 11.0767
        
        for i in 0..<count {
            let coordinate = CLLocationCoordinate2D(
                latitude: baseLatitude + Double(i) * 0.01, // Spread points by ~1km
                longitude: baseLongitude + Double(i) * 0.01
            )
            
            let routePoint = RoutePoint(
                name: "Test Point \(i + 1)",
                coordinate: coordinate,
                address: "Test Address \(i + 1)",
                category: .attraction,
                phoneNumber: nil,
                url: nil,
                operatingHours: nil,
                emailAddress: nil,
                poiId: "test-poi-\(i + 1)"
            )
            
            points.append(routePoint)
        }
        
        return points
    }
}
