//
//  RoutePointSimpleTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-24
//  Simple unit tests for RoutePoint model
//

import XCTest
import CoreLocation
@testable import SmartCityGuide

@MainActor
class RoutePointSimpleTests: XCTestCase {
    
    func testRoutePointInitialization() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767)
        let routePoint = RoutePoint(
            name: "Test Location",
            coordinate: coordinate,
            address: "Test Street 123",
            category: .attraction,
            phoneNumber: "+49123456789",
            url: URL(string: "https://example.com"),
            operatingHours: "9:00-17:00",
            emailAddress: "test@example.com",
            poiId: "test-poi-id"
        )
        
        // Then
        XCTAssertEqual(routePoint.name, "Test Location")
        XCTAssertEqual(routePoint.coordinate.latitude, 49.4521, accuracy: 0.0001)
        XCTAssertEqual(routePoint.coordinate.longitude, 11.0767, accuracy: 0.0001)
        XCTAssertEqual(routePoint.address, "Test Street 123")
        XCTAssertEqual(routePoint.category, .attraction)
        XCTAssertEqual(routePoint.phoneNumber, "+49123456789")
        XCTAssertEqual(routePoint.url?.absoluteString, "https://example.com")
        XCTAssertEqual(routePoint.operatingHours, "9:00-17:00")
        XCTAssertEqual(routePoint.emailAddress, "test@example.com")
        XCTAssertEqual(routePoint.poiId, "test-poi-id")
    }
    
    func testRoutePointWithMinimalData() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 50.0, longitude: 8.0)
        let routePoint = RoutePoint(
            name: "Minimal Location",
            coordinate: coordinate,
            address: "Basic Address",
            category: .museum
        )
        
        // Then
        XCTAssertEqual(routePoint.name, "Minimal Location")
        XCTAssertEqual(routePoint.category, .museum)
        XCTAssertNil(routePoint.phoneNumber)
        XCTAssertNil(routePoint.url)
        XCTAssertNil(routePoint.operatingHours)
        XCTAssertNil(routePoint.emailAddress)
        XCTAssertNil(routePoint.poiId)
    }
}
