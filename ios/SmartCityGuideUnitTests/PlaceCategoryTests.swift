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
    
    // MARK: - Route Enums Tests
    
    func testRouteLengthBasics() {
        // Test RouteLength enum values and calculations
        XCTAssertEqual(RouteLength.short.rawValue, "Kurz")
        XCTAssertEqual(RouteLength.medium.rawValue, "Mittel")
        XCTAssertEqual(RouteLength.long.rawValue, "Lang")
        
        // Test distance calculations
        XCTAssertEqual(RouteLength.short.maxTotalDistanceMeters, 5000)
        XCTAssertEqual(RouteLength.medium.maxTotalDistanceMeters, 15000)
        XCTAssertEqual(RouteLength.long.maxTotalDistanceMeters, 50000)
        
        // Test search radius
        XCTAssertEqual(RouteLength.short.searchRadiusMeters, 3000)
        XCTAssertEqual(RouteLength.medium.searchRadiusMeters, 8000)
        XCTAssertEqual(RouteLength.long.searchRadiusMeters, 15000)
    }
    
    func testMaximumStopsEnum() {
        // Test MaximumStops enum
        XCTAssertEqual(MaximumStops.three.intValue, 3)
        XCTAssertEqual(MaximumStops.five.intValue, 5)
        XCTAssertEqual(MaximumStops.eight.intValue, 8)
        XCTAssertEqual(MaximumStops.allCases.count, 3)
    }
    
    func testMaximumWalkingTimeEnum() {
        // Test MaximumWalkingTime enum
        XCTAssertEqual(MaximumWalkingTime.thirtyMin.minutes, 30)
        XCTAssertEqual(MaximumWalkingTime.sixtyMin.minutes, 60)
        XCTAssertEqual(MaximumWalkingTime.twoHours.minutes, 120)
        XCTAssertNil(MaximumWalkingTime.openEnd.minutes)
        
        // Test descriptions exist
        XCTAssertFalse(MaximumWalkingTime.thirtyMin.description.isEmpty)
        XCTAssertTrue(MaximumWalkingTime.openEnd.description.contains("Ohne"))
    }
    
    func testMinimumPOIDistanceEnum() {
        // Test MinimumPOIDistance enum
        XCTAssertEqual(MinimumPOIDistance.oneHundred.meters, 100)
        XCTAssertEqual(MinimumPOIDistance.fiveHundred.meters, 500)
        XCTAssertEqual(MinimumPOIDistance.oneKm.meters, 1000)
        XCTAssertNil(MinimumPOIDistance.noMinimum.meters)
        
        // Test raw values
        XCTAssertEqual(MinimumPOIDistance.oneHundred.rawValue, "100m")
        XCTAssertEqual(MinimumPOIDistance.noMinimum.rawValue, "Kein Minimum")
    }
    
    func testEndpointOptionEnum() {
        // Test EndpointOption enum
        let allCases = EndpointOption.allCases
        XCTAssertTrue(allCases.contains(.roundtrip))
        XCTAssertTrue(allCases.contains(.lastPlace))
        XCTAssertTrue(allCases.contains(.custom))
        
        // Test raw values
        XCTAssertEqual(EndpointOption.roundtrip.rawValue, "Rundreise")
        XCTAssertEqual(EndpointOption.lastPlace.rawValue, "Stopp")
        XCTAssertEqual(EndpointOption.custom.rawValue, "Custom")
        
        // Test descriptions in German
        XCTAssertTrue(EndpointOption.roundtrip.description.contains("Startpunkt"))
        XCTAssertTrue(EndpointOption.custom.description.contains("Eigenen"))
        XCTAssertTrue(EndpointOption.lastPlace.description.contains("letztem"))
    }
    
    // MARK: - SwipeDirection Tests
    
    func testSwipeDirectionBasics() {
        // Test enum cases
        let allCases = SwipeDirection.allCases
        XCTAssertTrue(allCases.contains(.left))
        XCTAssertTrue(allCases.contains(.right))
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertEqual(allCases.count, 3)
    }
    
    func testSwipeDirectionColors() {
        // Test indicator colors
        XCTAssertEqual(SwipeDirection.left.indicatorColor, .green)
        XCTAssertEqual(SwipeDirection.right.indicatorColor, .red)
        XCTAssertEqual(SwipeDirection.none.indicatorColor, .clear)
    }
    
    func testSwipeDirectionIcons() {
        // Test indicator icons
        XCTAssertEqual(SwipeDirection.left.indicatorIcon, "checkmark.circle.fill")
        XCTAssertEqual(SwipeDirection.right.indicatorIcon, "xmark.circle.fill")
        XCTAssertEqual(SwipeDirection.none.indicatorIcon, "")
    }
    
    func testSwipeDirectionActionText() {
        // Test German action text
        XCTAssertEqual(SwipeDirection.left.actionText, "Nehmen")
        XCTAssertEqual(SwipeDirection.right.actionText, "Überspringen")
        XCTAssertEqual(SwipeDirection.none.actionText, "")
    }
    
    func testSwipeDirectionLogic() {
        // Test logic properties
        XCTAssertTrue(SwipeDirection.left.isAccept)
        XCTAssertFalse(SwipeDirection.left.isReject)
        
        XCTAssertFalse(SwipeDirection.right.isAccept)
        XCTAssertTrue(SwipeDirection.right.isReject)
        
        XCTAssertFalse(SwipeDirection.none.isAccept)
        XCTAssertFalse(SwipeDirection.none.isReject)
    }
    
    // MARK: - Manual Route Models Tests
    
    func testRoutePlanningModeEnum() {
        // Test RoutePlanningMode enum
        XCTAssertEqual(RoutePlanningMode.automatic.rawValue, "Automatisch")
        XCTAssertEqual(RoutePlanningMode.manual.rawValue, "Manuell erstellen")
        XCTAssertEqual(RoutePlanningMode.allCases.count, 2)
    }
    
    func testManualRouteConfigInitialization() {
        // Test ManualRouteConfig initialization
        let coordinate = CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767)
        let config = ManualRouteConfig(
            startingCity: "Nürnberg",
            startingCoordinates: coordinate,
            usingCurrentLocation: false,
            endpointOption: .roundtrip,
            customEndpoint: "Test Endpoint",
            customEndpointCoordinates: coordinate
        )
        
        XCTAssertEqual(config.startingCity, "Nürnberg")
        XCTAssertNotNil(config.startingCoordinates)
        XCTAssertFalse(config.usingCurrentLocation)
        XCTAssertEqual(config.endpointOption, .roundtrip)
        XCTAssertEqual(config.customEndpoint, "Test Endpoint")
        XCTAssertNotNil(config.customEndpointCoordinates)
    }
    
    func testManualPOISelectionInitialState() {
        // Test ManualPOISelection initial state
        let selection = ManualPOISelection()
        
        XCTAssertTrue(selection.selectedPOIs.isEmpty)
        XCTAssertTrue(selection.rejectedPOIs.isEmpty)
        XCTAssertEqual(selection.currentCardIndex, 0)
        XCTAssertFalse(selection.hasSelections)
        XCTAssertFalse(selection.canUndo) // Initial history is empty
        XCTAssertFalse(selection.canGenerateRoute) // Need at least 1 POI
    }
    
    func testManualPOISelectionWithPOIs() {
        // Given
        let selection = ManualPOISelection()
        let poi = POI(
            id: "test-poi",
            name: "Test POI",
            latitude: 49.4521,
            longitude: 11.0767,
            category: .attraction,
            description: "Test",
            tags: [:],
            sourceType: "test",
            sourceId: 123,
            address: nil,
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
        
        // When - Add POI to selection
        selection.selectedPOIs.append(poi)
        
        // Then
        XCTAssertTrue(selection.hasSelections)
        XCTAssertEqual(selection.selectedPOIs.count, 1)
        XCTAssertEqual(selection.selectedPOIs.first?.id, "test-poi")
    }
}
