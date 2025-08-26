//
//  PlaceCategorySimpleTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-24
//  Simple unit tests for PlaceCategory enum
//

import XCTest
@testable import SmartCityGuide

@MainActor
class PlaceCategorySimpleTests: XCTestCase {
    
    func testPlaceCategoryBasicValues() {
        // Test basic category values
        XCTAssertEqual(PlaceCategory.attraction.rawValue, "Sehenswürdigkeit")
        XCTAssertEqual(PlaceCategory.museum.rawValue, "Museum")
        XCTAssertEqual(PlaceCategory.park.rawValue, "Park")
    }
    
    func testPlaceCategoryCount() {
        // Ensure we have multiple categories
        XCTAssertGreaterThan(PlaceCategory.allCases.count, 5, "Should have multiple place categories")
    }
}
