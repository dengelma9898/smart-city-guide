//
//  POIModelTests.swift
//  SmartCityGuideUnitTests
//
//  Created on 2025-08-26
//  Unit tests for POI model and supporting types
//

import XCTest
import CoreLocation
@testable import SmartCityGuide

@MainActor
class POIModelTests: XCTestCase {
    
    // MARK: - POIAddress Tests
    
    func testPOIAddressFullAddressWithAllComponents() {
        // Given
        let address = POIAddress(
            street: "Hauptstraße",
            houseNumber: "123",
            city: "Nürnberg",
            postcode: "90402",
            country: "Deutschland"
        )
        
        // When
        let fullAddress = address.fullAddress
        
        // Then
        XCTAssertEqual(fullAddress, "Hauptstraße 123, 90402 Nürnberg, Deutschland")
    }
    
    func testPOIAddressWithMinimalComponents() {
        // Given
        let address = POIAddress(
            street: "Hauptstraße",
            houseNumber: nil,
            city: "Nürnberg",
            postcode: nil,
            country: nil
        )
        
        // When
        let fullAddress = address.fullAddress
        
        // Then
        XCTAssertEqual(fullAddress, "Hauptstraße, Nürnberg")
    }
    
    func testPOIAddressWithEmptyComponents() {
        // Given
        let address = POIAddress(
            street: nil,
            houseNumber: nil,
            city: nil,
            postcode: nil,
            country: nil
        )
        
        // When
        let fullAddress = address.fullAddress
        
        // Then
        XCTAssertEqual(fullAddress, "")
    }
    
    // MARK: - POIContact Tests
    
    func testPOIContactInitialization() {
        // Given/When
        let contact = POIContact(
            phone: "+49911123456",
            email: "info@example.com",
            website: "https://example.com"
        )
        
        // Then
        XCTAssertEqual(contact.phone, "+49911123456")
        XCTAssertEqual(contact.email, "info@example.com")
        XCTAssertEqual(contact.website, "https://example.com")
    }
    
    func testPOIContactWithNilValues() {
        // Given/When
        let contact = POIContact(phone: nil, email: nil, website: nil)
        
        // Then
        XCTAssertNil(contact.phone)
        XCTAssertNil(contact.email)
        XCTAssertNil(contact.website)
    }
    
    // MARK: - POIAccessibility Tests
    
    func testPOIAccessibilityInitialization() {
        // Given/When
        let accessibility = POIAccessibility(wheelchair: "yes")
        
        // Then
        XCTAssertEqual(accessibility.wheelchair, "yes")
    }
    
    // MARK: - POI Tests
    
    func testPOIInitializationWithAllData() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767)
        let address = POIAddress(
            street: "Hauptstraße",
            houseNumber: "123",
            city: "Nürnberg",
            postcode: "90402",
            country: "Deutschland"
        )
        let contact = POIContact(
            phone: "+49911123456",
            email: "info@example.com",
            website: "https://example.com"
        )
        let accessibility = POIAccessibility(wheelchair: "yes")
        
        // When
        let poi = POI(
            placeId: "test-123",
            name: "Test POI",
            coordinate: coordinate,
            address: address,
            contact: contact,
            category: .attraction,
            subcategory: "museum",
            openingHours: "9:00-17:00",
            accessibility: accessibility,
            rating: 4.5,
            priceLevel: 2,
            description: "Ein Test POI"
        )
        
        // Then
        XCTAssertEqual(poi.placeId, "test-123")
        XCTAssertEqual(poi.name, "Test POI")
        XCTAssertEqual(poi.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(poi.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(poi.address.fullAddress, "Hauptstraße 123, 90402 Nürnberg, Deutschland")
        XCTAssertEqual(poi.contact?.phone, "+49911123456")
        XCTAssertEqual(poi.category, .attraction)
        XCTAssertEqual(poi.subcategory, "museum")
        XCTAssertEqual(poi.openingHours, "9:00-17:00")
        XCTAssertEqual(poi.accessibility?.wheelchair, "yes")
        XCTAssertEqual(poi.rating, 4.5)
        XCTAssertEqual(poi.priceLevel, 2)
        XCTAssertEqual(poi.description, "Ein Test POI")
    }
    
    func testPOIWithMinimalData() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767)
        let address = POIAddress(
            street: nil,
            houseNumber: nil,
            city: "Nürnberg",
            postcode: nil,
            country: nil
        )
        
        // When
        let poi = POI(
            placeId: "minimal-poi",
            name: "Minimal POI",
            coordinate: coordinate,
            address: address,
            contact: nil,
            category: .park,
            subcategory: nil,
            openingHours: nil,
            accessibility: nil,
            rating: nil,
            priceLevel: nil,
            description: nil
        )
        
        // Then
        XCTAssertEqual(poi.placeId, "minimal-poi")
        XCTAssertEqual(poi.name, "Minimal POI")
        XCTAssertEqual(poi.category, .park)
        XCTAssertNil(poi.contact)
        XCTAssertNil(poi.subcategory)
        XCTAssertNil(poi.openingHours)
        XCTAssertNil(poi.accessibility)
        XCTAssertNil(poi.rating)
        XCTAssertNil(poi.priceLevel)
        XCTAssertNil(poi.description)
    }
    
    // MARK: - POI Codable Tests
    
    func testPOICodableRoundTrip() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767)
        let address = POIAddress(
            street: "Teststraße",
            houseNumber: "42",
            city: "Nürnberg",
            postcode: "90402",
            country: "Deutschland"
        )
        
        let originalPOI = POI(
            placeId: "codable-test",
            name: "Codable Test POI",
            coordinate: coordinate,
            address: address,
            contact: nil,
            category: .museum,
            subcategory: "history",
            openingHours: "10:00-18:00",
            accessibility: nil,
            rating: 4.2,
            priceLevel: 1,
            description: "Test für Codable"
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(originalPOI) else {
            XCTFail("Failed to encode POI")
            return
        }
        
        // When - Decode
        let decoder = JSONDecoder()
        guard let decodedPOI = try? decoder.decode(POI.self, from: data) else {
            XCTFail("Failed to decode POI")
            return
        }
        
        // Then
        XCTAssertEqual(decodedPOI.placeId, originalPOI.placeId)
        XCTAssertEqual(decodedPOI.name, originalPOI.name)
        XCTAssertEqual(decodedPOI.coordinate.latitude, originalPOI.coordinate.latitude, accuracy: 0.000001)
        XCTAssertEqual(decodedPOI.coordinate.longitude, originalPOI.coordinate.longitude, accuracy: 0.000001)
        XCTAssertEqual(decodedPOI.category, originalPOI.category)
        XCTAssertEqual(decodedPOI.rating, originalPOI.rating)
    }
}
