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
    
    // MARK: - Basic POI Model Test
    
    func testPOIBasicInitialization() {
        // Given
        let address = POIAddress(
            street: "Hauptstraße",
            houseNumber: "123",
            city: "Nürnberg",
            postcode: "90402",
            country: "Deutschland"
        )
        
        // When
        let poi = POI(
            id: "test-poi",
            name: "Test POI",
            latitude: 49.4521,
            longitude: 11.0767,
            category: .attraction,
            description: "Ein Test POI",
            tags: ["test": "value"],
            sourceType: "test",
            sourceId: 123,
            address: address,
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: "9:00-17:00",
            website: "https://example.com",
            geoapifyWikiData: nil
        )
        
        // Then
        XCTAssertEqual(poi.id, "test-poi")
        XCTAssertEqual(poi.name, "Test POI")
        XCTAssertEqual(poi.coordinate.latitude, 49.4521, accuracy: 0.000001)
        XCTAssertEqual(poi.coordinate.longitude, 11.0767, accuracy: 0.000001)
        XCTAssertEqual(poi.category, .attraction)
        XCTAssertEqual(poi.fullAddress, "Hauptstraße 123, 90402 Nürnberg, Deutschland")
        XCTAssertEqual(poi.description, "Ein Test POI")
        XCTAssertEqual(poi.operatingHours, "9:00-17:00")
        XCTAssertEqual(poi.website, "https://example.com")
    }
    
    // MARK: - UserProfile Model Tests
    
    func testUserProfileInitialization() {
        // Given/When
        let profile = UserProfile(name: "Test User", email: "test@example.com")
        
        // Then
        XCTAssertEqual(profile.name, "Test User")
        XCTAssertEqual(profile.email, "test@example.com")
        XCTAssertNil(profile.profileImagePath)
        XCTAssertNotNil(profile.createdAt)
        XCTAssertNotNil(profile.lastActiveAt)
    }
    
    func testUserProfileDefaultValues() {
        // Given/When
        let profile = UserProfile()
        
        // Then
        XCTAssertEqual(profile.name, "Max Mustermann")
        XCTAssertEqual(profile.email, "max.mustermann@email.de")
        XCTAssertNil(profile.profileImagePath)
    }
    
    func testUserProfileUpdateLastActive() {
        // Given
        var profile = UserProfile()
        let originalTimestamp = profile.lastActiveAt
        
        // Wait a tiny bit to ensure timestamp difference
        let expectation = expectation(description: "Wait for timestamp difference")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When
        profile.updateLastActive()
        
        // Then
        XCTAssertGreaterThan(profile.lastActiveAt, originalTimestamp)
    }
}
