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
        let accessibility = POIAccessibility(wheelchair: "yes", wheelchairDescription: nil)
        
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
        let accessibility = POIAccessibility(wheelchair: "yes", wheelchairDescription: nil)
        
        // When
        let poi = POI(
            id: "test-123",
            name: "Test POI",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: .attraction,
            description: "Ein Test POI",
            tags: ["type": "museum"],
            sourceType: "test",
            sourceId: 123,
            address: address,
            contact: contact,
            accessibility: accessibility,
            pricing: nil,
            operatingHours: "9:00-17:00",
            website: "https://example.com",
            geoapifyWikiData: nil
        )
        
        // Then
        XCTAssertEqual(poi.id, "test-123")
        XCTAssertEqual(poi.name, "Test POI")
        XCTAssertEqual(poi.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(poi.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(poi.address?.fullAddress, "Hauptstraße 123, 90402 Nürnberg, Deutschland")
        XCTAssertEqual(poi.contact?.phone, "+49911123456")
        XCTAssertEqual(poi.category, .attraction)
        XCTAssertEqual(poi.tags["type"], "museum")
        XCTAssertEqual(poi.operatingHours, "9:00-17:00")
        XCTAssertEqual(poi.accessibility?.wheelchair, "yes")
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
            id: "minimal-poi",
            name: "Minimal POI",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: .park,
            description: nil,
            tags: [:],
            sourceType: "test",
            sourceId: 456,
            address: address,
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
        
        // Then
        XCTAssertEqual(poi.id, "minimal-poi")
        XCTAssertEqual(poi.name, "Minimal POI")
        XCTAssertEqual(poi.category, .park)
        XCTAssertNil(poi.contact)
        XCTAssertNil(poi.operatingHours)
        XCTAssertNil(poi.accessibility)

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
            id: "codable-test",
            name: "Codable Test POI",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: .museum,
            description: "Test für Codable",
            tags: ["type": "history"],
            sourceType: "test",
            sourceId: 789,
            address: address,
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: "10:00-18:00",
            website: nil,
            geoapifyWikiData: nil
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
        XCTAssertEqual(decodedPOI.id, originalPOI.id)
        XCTAssertEqual(decodedPOI.name, originalPOI.name)
        XCTAssertEqual(decodedPOI.coordinate.latitude, originalPOI.coordinate.latitude, accuracy: 0.000001)
        XCTAssertEqual(decodedPOI.coordinate.longitude, originalPOI.coordinate.longitude, accuracy: 0.000001)
        XCTAssertEqual(decodedPOI.category, originalPOI.category)
        XCTAssertEqual(decodedPOI.description, originalPOI.description)
    }
}
