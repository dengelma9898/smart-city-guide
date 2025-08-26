//
//  RouteEnumsTests.swift
//  SmartCityGuideUnitTests
//
//  Created on 2025-08-26
//  Unit tests for route-related enums
//

import XCTest
@testable import SmartCityGuide

@MainActor
class RouteEnumsTests: XCTestCase {
    
    // MARK: - RouteLength Tests
    
    func testRouteLengthValues() {
        // Test basic enum values
        XCTAssertEqual(RouteLength.short.rawValue, "Kurz")
        XCTAssertEqual(RouteLength.medium.rawValue, "Mittel")
        XCTAssertEqual(RouteLength.long.rawValue, "Lang")
    }
    
    func testRouteLengthDistances() {
        // Test distance calculations
        XCTAssertEqual(RouteLength.short.maxTotalDistanceMeters, 5000)
        XCTAssertEqual(RouteLength.medium.maxTotalDistanceMeters, 15000)
        XCTAssertEqual(RouteLength.long.maxTotalDistanceMeters, 50000)
    }
    
    func testRouteLengthSearchRadius() {
        // Test search radius
        XCTAssertEqual(RouteLength.short.searchRadiusMeters, 3000)
        XCTAssertEqual(RouteLength.medium.searchRadiusMeters, 8000)
        XCTAssertEqual(RouteLength.long.searchRadiusMeters, 15000)
    }
    
    func testRouteLengthDescriptions() {
        // Test descriptions are not empty
        XCTAssertFalse(RouteLength.short.description.isEmpty)
        XCTAssertFalse(RouteLength.medium.description.isEmpty)
        XCTAssertFalse(RouteLength.long.description.isEmpty)
        
        // Test specific descriptions
        XCTAssertTrue(RouteLength.short.description.contains("5km"))
        XCTAssertTrue(RouteLength.medium.description.contains("15km"))
    }
    
    // MARK: - MaximumStops Tests
    
    func testMaximumStopsValues() {
        // Test enum values
        XCTAssertEqual(MaximumStops.three.rawValue, "3")
        XCTAssertEqual(MaximumStops.five.rawValue, "5")
        XCTAssertEqual(MaximumStops.eight.rawValue, "8")
    }
    
    func testMaximumStopsIntValues() {
        // Test conversion to integers
        XCTAssertEqual(MaximumStops.three.intValue, 3)
        XCTAssertEqual(MaximumStops.five.intValue, 5)
        XCTAssertEqual(MaximumStops.eight.intValue, 8)
    }
    
    func testMaximumStopsAllCases() {
        // Test that all cases are present
        XCTAssertEqual(MaximumStops.allCases.count, 3)
        XCTAssertTrue(MaximumStops.allCases.contains(.three))
        XCTAssertTrue(MaximumStops.allCases.contains(.five))
        XCTAssertTrue(MaximumStops.allCases.contains(.eight))
    }
    
    // MARK: - MaximumWalkingTime Tests
    
    func testMaximumWalkingTimeMinutes() {
        // Test time conversion
        XCTAssertEqual(MaximumWalkingTime.thirtyMin.minutes, 30)
        XCTAssertEqual(MaximumWalkingTime.fortyFiveMin.minutes, 45)
        XCTAssertEqual(MaximumWalkingTime.sixtyMin.minutes, 60)
        XCTAssertEqual(MaximumWalkingTime.ninetyMin.minutes, 90)
        XCTAssertEqual(MaximumWalkingTime.twoHours.minutes, 120)
        XCTAssertEqual(MaximumWalkingTime.threeHours.minutes, 180)
        XCTAssertNil(MaximumWalkingTime.openEnd.minutes)
    }
    
    func testMaximumWalkingTimeDescriptions() {
        // Test descriptions exist and are German
        for walkingTime in MaximumWalkingTime.allCases {
            XCTAssertFalse(walkingTime.description.isEmpty, "Walking time \(walkingTime) should have description")
        }
        
        // Test specific German descriptions
        XCTAssertTrue(MaximumWalkingTime.thirtyMin.description.contains("Kurze"))
        XCTAssertTrue(MaximumWalkingTime.openEnd.description.contains("Ohne"))
    }
    
    // MARK: - MinimumPOIDistance Tests
    
    func testMinimumPOIDistanceMeters() {
        // Test distance conversion
        XCTAssertEqual(MinimumPOIDistance.oneHundred.meters, 100)
        XCTAssertEqual(MinimumPOIDistance.twoFifty.meters, 250)
        XCTAssertEqual(MinimumPOIDistance.fiveHundred.meters, 500)
        XCTAssertEqual(MinimumPOIDistance.sevenFifty.meters, 750)
        XCTAssertEqual(MinimumPOIDistance.oneKm.meters, 1000)
        XCTAssertNil(MinimumPOIDistance.noMinimum.meters)
    }
    
    func testMinimumPOIDistanceRawValues() {
        // Test raw values are meaningful
        XCTAssertEqual(MinimumPOIDistance.oneHundred.rawValue, "100m")
        XCTAssertEqual(MinimumPOIDistance.oneKm.rawValue, "1km")
        XCTAssertEqual(MinimumPOIDistance.noMinimum.rawValue, "Kein Minimum")
    }
    
    // MARK: - EndpointOption Tests
    
    func testEndpointOptionValues() {
        // Test enum cases exist
        let allCases = EndpointOption.allCases
        XCTAssertTrue(allCases.contains(.roundtrip))
        XCTAssertTrue(allCases.contains(.lastPlace))
        XCTAssertTrue(allCases.contains(.custom))
    }
    
    func testEndpointOptionDescriptions() {
        // Test descriptions are in German
        for option in EndpointOption.allCases {
            let description = option.description
            XCTAssertFalse(description.isEmpty, "Endpoint option \(option) should have description")
        }
        
        // Test specific German text
        XCTAssertTrue(EndpointOption.roundtrip.description.contains("Startpunkt"))
        XCTAssertTrue(EndpointOption.custom.description.contains("Eigenen"))
    }
    
    // MARK: - Enum Completeness Tests
    
    func testAllEnumsHaveValidCases() {
        // Test that enums have reasonable number of cases
        XCTAssertGreaterThan(RouteLength.allCases.count, 2)
        XCTAssertGreaterThan(MaximumWalkingTime.allCases.count, 5)
        XCTAssertGreaterThan(MinimumPOIDistance.allCases.count, 4)
        XCTAssertGreaterThan(EndpointOption.allCases.count, 2)
    }
    
    func testAllEnumsAreCodable() {
        // Test that enums can be encoded/decoded
        let routeLength = RouteLength.medium
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test RouteLength codability
        XCTAssertNoThrow(try encoder.encode(routeLength))
        
        if let data = try? encoder.encode(routeLength) {
            XCTAssertNoThrow(try decoder.decode(RouteLength.self, from: data))
        }
        
        // Test MaximumStops codability
        let maxStops = MaximumStops.five
        XCTAssertNoThrow(try encoder.encode(maxStops))
        
        if let data = try? encoder.encode(maxStops) {
            XCTAssertNoThrow(try decoder.decode(MaximumStops.self, from: data))
        }
    }
}
