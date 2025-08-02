import Foundation
import MapKit
import CoreLocation

// MARK: - Route Models
struct RoutePoint {
  let name: String
  let coordinate: CLLocationCoordinate2D
  let address: String
  let category: PlaceCategory
  let phoneNumber: String?
  let url: URL?
  let pointOfInterestCategory: MKPointOfInterestCategory?
  
  init(from mapItem: MKMapItem) {
    self.name = mapItem.name ?? "Unbekannter Ort"
    self.coordinate = mapItem.placemark.coordinate
    self.address = mapItem.placemark.title ?? ""
    self.category = PlaceCategory.classify(mapItem)
    self.phoneNumber = mapItem.phoneNumber
    self.url = mapItem.url
    self.pointOfInterestCategory = mapItem.pointOfInterestCategory
  }
  
  init(name: String, coordinate: CLLocationCoordinate2D, address: String, category: PlaceCategory = .attraction, phoneNumber: String? = nil, url: URL? = nil) {
    self.name = name
    self.coordinate = coordinate
    self.address = address
    self.category = category
    self.phoneNumber = phoneNumber
    self.url = url
    self.pointOfInterestCategory = nil
  }
}

struct GeneratedRoute {
  let waypoints: [RoutePoint]
  let routes: [MKRoute]
  let totalDistance: CLLocationDistance  
  let totalTravelTime: TimeInterval
  let totalVisitTime: TimeInterval
  let totalExperienceTime: TimeInterval
  
  var numberOfStops: Int {
    // Exclude start and end points from stop count
    max(0, waypoints.count - 2)
  }
  
  var walkingTimes: [TimeInterval] {
    return routes.map { $0.expectedTravelTime }
  }
  
  var walkingDistances: [CLLocationDistance] {
    return routes.map { $0.distance }
  }
}

// MARK: - Endpoint Configuration Models
enum EndpointOption: String, CaseIterable, Codable {
  case roundtrip = "Rundreise"
  case lastPlace = "Letzter Ort"
  case custom = "Anderer Ort"
  
  var description: String {
    switch self {
    case .roundtrip:
      return "Zurück zum Startpunkt"
    case .lastPlace:
      return "Bei letztem besuchten Ort enden"
    case .custom:
      return "Eigenen Endpunkt wählen"
    }
  }
}

enum RouteLength: String, CaseIterable, Codable {
  case short = "Kurz"
  case medium = "Mittel"  
  case long = "Lang"
  
  var description: String {
    switch self {
    case .short:
      return "Bis zu 5km Gesamtstrecke"
    case .medium:
      return "Bis zu 15km Gesamtstrecke"
    case .long:
      return "Über 15km Gesamtstrecke"
    }
  }
  
  var maxTotalDistanceMeters: Double {
    switch self {
    case .short:
      return 5000   // 5km total route
    case .medium:
      return 15000  // 15km total route
    case .long:
      return 50000  // 50km total route
    }
  }
  
  var searchRadiusMeters: Double {
    switch self {
    case .short:
      return 3000   // Search within 3km for short routes
    case .medium:
      return 8000   // Search within 8km for medium routes
    case .long:
      return 15000  // Search within 15km for long routes
    }
  }
}