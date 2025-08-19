import Foundation
import MapKit
import CoreLocation
import os.log

/// Service for resolving locations and handling geocoding operations
@MainActor
class LocationResolverService: ObservableObject {
  
  // MARK: - Properties
  
  private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "LocationResolver")
  
  // MARK: - Public Interface
  
  /// Find a location based on a natural language query
  /// - Parameter query: The search query (e.g., "Berlin", "Alexanderplatz")
  /// - Returns: A RoutePoint representing the found location
  /// - Throws: Error if location cannot be found
  func findLocation(query: String) async throws -> RoutePoint {
    return try await withCheckedThrowingContinuation { continuation in
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = query
      request.resultTypes = [.address, .pointOfInterest]
      
      let search = MKLocalSearch(request: request)
      search.start { response, error in
        if let error = error {
          self.logger.error("Location search failed for '\(query, privacy: .public)': \(error.localizedDescription)")
          continuation.resume(throwing: error)
        } else if let firstResult = response?.mapItems.first {
          let routePoint = RoutePoint(from: firstResult)
          self.logger.info("✅ Location found for '\(query, privacy: .public)': \(routePoint.name)")
          continuation.resume(returning: routePoint)
        } else {
          let error = NSError(
            domain: "LocationResolverService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Ort nicht gefunden: \(query)"]
          )
          self.logger.warning("❌ No location found for query: '\(query, privacy: .public)'")
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Create a RoutePoint from the user's current location using reverse geocoding
  /// - Parameter location: The current CLLocation
  /// - Returns: A RoutePoint with resolved address information
  /// - Throws: Error if reverse geocoding fails (with fallback handling)
  func createRoutePointFromCurrentLocation(_ location: CLLocation) async throws -> RoutePoint {
    return try await withCheckedThrowingContinuation { continuation in
      let geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error = error {
          self.logger.warning("Reverse geocoding failed: \(error.localizedDescription)")
          // Fallback: Create RoutePoint without reverse geocoding
          let routePoint = RoutePoint(
            name: "Mein Standort",
            coordinate: location.coordinate,
            address: "Aktuelle Position",
            category: .attraction // Default category for current location
          )
          continuation.resume(returning: routePoint)
        } else if let placemark = placemarks?.first {
          // Create RoutePoint with resolved location name
          let locationName = self.formatLocationName(from: placemark)
          let addressString = self.formatAddress(from: placemark)
          let routePoint = RoutePoint(
            name: locationName,
            coordinate: location.coordinate,
            address: addressString,
            category: .attraction
          )
          self.logger.info("✅ Current location resolved: \(locationName)")
          continuation.resume(returning: routePoint)
        } else {
          // Fallback: Create RoutePoint without resolved name
          let routePoint = RoutePoint(
            name: "Mein Standort",
            coordinate: location.coordinate,
            address: "Aktuelle Position",
            category: .attraction
          )
          self.logger.info("📍 Using fallback for current location")
          continuation.resume(returning: routePoint)
        }
      }
    }
  }
  
  /// Resolve coordinates to a human-readable location name
  /// - Parameter coordinate: The coordinate to resolve
  /// - Returns: A human-readable location name
  func resolveLocationName(for coordinate: CLLocationCoordinate2D) async throws -> String {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    
    return try await withCheckedThrowingContinuation { continuation in
      let geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error = error {
          self.logger.warning("Location name resolution failed: \(error.localizedDescription)")
          continuation.resume(throwing: error)
        } else if let placemark = placemarks?.first {
          let locationName = self.formatLocationName(from: placemark)
          continuation.resume(returning: locationName)
        } else {
          let error = NSError(
            domain: "LocationResolverService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Could not resolve location name"]
          )
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  // MARK: - Private Helper Methods
  
  /// Format a location name from a placemark for display purposes
  /// - Parameter placemark: The CLPlacemark to format
  /// - Returns: A formatted location name string
  private func formatLocationName(from placemark: CLPlacemark) -> String {
    var components: [String] = []
    
    if let locality = placemark.locality {
      components.append(locality)
    }
    if let subLocality = placemark.subLocality {
      components.append(subLocality)
    }
    if let thoroughfare = placemark.thoroughfare {
      components.append(thoroughfare)
    }
    
    if components.isEmpty {
      return "Mein Standort"
    } else {
      return "Mein Standort (\(components.joined(separator: ", ")))"
    }
  }
  
  /// Format a complete address from a placemark
  /// - Parameter placemark: The CLPlacemark to format
  /// - Returns: A formatted address string
  private func formatAddress(from placemark: CLPlacemark) -> String {
    var addressComponents: [String] = []
    
    if let thoroughfare = placemark.thoroughfare {
      if let subThoroughfare = placemark.subThoroughfare {
        addressComponents.append("\(thoroughfare) \(subThoroughfare)")
      } else {
        addressComponents.append(thoroughfare)
      }
    }
    
    if let locality = placemark.locality {
      addressComponents.append(locality)
    }
    
    if let postalCode = placemark.postalCode {
      addressComponents.append(postalCode)
    }
    
    if let country = placemark.country {
      addressComponents.append(country)
    }
    
    return addressComponents.isEmpty ? "Aktuelle Position" : addressComponents.joined(separator: ", ")
  }
  
  /// Check if a coordinate is valid
  /// - Parameter coordinate: The coordinate to validate
  /// - Returns: True if the coordinate is valid
  func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return CLLocationCoordinate2DIsValid(coordinate) &&
           coordinate.latitude != 0.0 &&
           coordinate.longitude != 0.0
  }
  
  /// Calculate distance between two coordinates
  /// - Parameters:
  ///   - from: Starting coordinate
  ///   - to: Destination coordinate
  /// - Returns: Distance in meters
  func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
}
