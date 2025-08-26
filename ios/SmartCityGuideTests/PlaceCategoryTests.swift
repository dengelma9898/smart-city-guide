//
//  PlaceCategoryTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-24
//  Unit tests for PlaceCategory enum
//

import XCTest
import MapKit
@testable import SmartCityGuide

@MainActor
class PlaceCategoryTests: XCTestCase {
    
    func testPlaceCategoryValues() {
        // Test basic category values
        XCTAssertEqual(PlaceCategory.attraction.rawValue, "Sehenswürdigkeit")
        XCTAssertEqual(PlaceCategory.museum.rawValue, "Museum")
        XCTAssertEqual(PlaceCategory.park.rawValue, "Park")
        XCTAssertEqual(PlaceCategory.gallery.rawValue, "Galerie")
    }
    
    func testPlaceCategoryIconNames() {
        // Test that categories have icon names
        XCTAssertFalse(PlaceCategory.attraction.iconName.isEmpty)
        XCTAssertFalse(PlaceCategory.museum.iconName.isEmpty)
        XCTAssertFalse(PlaceCategory.park.iconName.isEmpty)
        XCTAssertFalse(PlaceCategory.gallery.iconName.isEmpty)
    }
    
    func testPlaceCategoryColors() {
        // Test that categories have colors
        XCTAssertNotNil(PlaceCategory.attraction.color)
        XCTAssertNotNil(PlaceCategory.museum.color)
        XCTAssertNotNil(PlaceCategory.park.color)
        XCTAssertNotNil(PlaceCategory.gallery.color)
    }
    
    func testAllCategoriesHaveRequiredProperties() {
        // Test that all categories have required properties
        for category in PlaceCategory.allCases {
            XCTAssertFalse(category.rawValue.isEmpty, "Category \(category) should have a raw value")
            XCTAssertFalse(category.iconName.isEmpty, "Category \(category) should have an icon name")
            XCTAssertNotNil(category.color, "Category \(category) should have a color")
        }
    }
    
    func testCategoryCount() {
        // Ensure we have a reasonable number of categories
        XCTAssertGreaterThan(PlaceCategory.allCases.count, 10, "Should have multiple place categories")
    }
    
    func testCategoryUniqueness() {
        // Test that all categories have unique raw values
        let rawValues = PlaceCategory.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        XCTAssertEqual(rawValues.count, uniqueRawValues.count, "All categories should have unique raw values")
    }
}
