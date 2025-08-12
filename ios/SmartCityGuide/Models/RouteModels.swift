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
  let operatingHours: String?
  let emailAddress: String?
  
  init(from mapItem: MKMapItem) {
    self.name = mapItem.name ?? "Unbekannter Ort"
    self.coordinate = mapItem.placemark.coordinate
    self.address = mapItem.placemark.title ?? ""
    self.category = PlaceCategory.classify(mapItem)
    self.phoneNumber = mapItem.phoneNumber
    self.url = mapItem.url
    self.pointOfInterestCategory = mapItem.pointOfInterestCategory
    self.operatingHours = nil // MKMapItem doesn't provide this
    self.emailAddress = nil    // MKMapItem doesn't provide this
  }
  
  init(name: String, coordinate: CLLocationCoordinate2D, address: String, category: PlaceCategory = .attraction, phoneNumber: String? = nil, url: URL? = nil, operatingHours: String? = nil, emailAddress: String? = nil) {
    self.name = name
    self.coordinate = coordinate
    self.address = address
    self.category = category
    self.phoneNumber = phoneNumber
    self.url = url
    self.pointOfInterestCategory = nil
    self.operatingHours = operatingHours
    self.emailAddress = emailAddress
  }
  
  /// Erstelle RoutePoint aus POI mit Kontakt- und Öffnungszeiten-Informationen
  init(from poi: POI) {
    self.name = poi.name
    self.coordinate = poi.coordinate
    self.address = poi.fullAddress
    self.category = poi.category
    
    // Kontakt-Informationen aus POI extrahieren
    self.phoneNumber = poi.contact?.phone
    self.emailAddress = poi.contact?.email
    
    if let websiteString = poi.contact?.website ?? poi.website {
      self.url = URL(string: websiteString)
    } else {
      self.url = nil
    }
    
    // Öffnungszeiten aus POI extrahieren
    self.operatingHours = poi.operatingHours
    
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
  case lastPlace = "Stopp"
  case custom = "Custom"
  
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

// MARK: - Legacy Route Length (for backwards compatibility)
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

// MARK: - New Filter Models

enum MaximumStops: String, CaseIterable, Codable {
    case three = "3"
    case five = "5" 
    case eight = "8"

    var intValue: Int {
        return Int(rawValue) ?? 5
    }
}

enum MaximumWalkingTime: String, CaseIterable, Codable {
    case thirtyMin = "30min"
    case fortyFiveMin = "45min"
    case sixtyMin = "60min"
    case ninetyMin = "90min"
    case twoHours = "2h"
    case threeHours = "3h"
    case openEnd = "Open End"
    
    var minutes: Int? {
        switch self {
        case .thirtyMin: return 30
        case .fortyFiveMin: return 45
        case .sixtyMin: return 60
        case .ninetyMin: return 90
        case .twoHours: return 120
        case .threeHours: return 180
        case .openEnd: return nil
        }
    }
    
    var description: String {
        switch self {
        case .thirtyMin: return "Kurze Spaziergänge"
        case .fortyFiveMin: return "Entspannte Touren"
        case .sixtyMin: return "Solide Entdeckungstouren"
        case .ninetyMin: return "Ausgiebige Erkundungen"
        case .twoHours: return "Intensive City-Touren"
        case .threeHours: return "Ganztages-Abenteuer"
        case .openEnd: return "Ohne Zeitlimit"
        }
    }
}

enum MinimumPOIDistance: String, CaseIterable, Codable {
    case oneHundred = "100m"
    case twoFifty = "250m"
    case fiveHundred = "500m"
    case sevenFifty = "750m"
    case oneKm = "1km"
    case noMinimum = "Kein Minimum"
    
    var meters: Double? {
        switch self {
        case .oneHundred: return 100
        case .twoFifty: return 250
        case .fiveHundred: return 500
        case .sevenFifty: return 750
        case .oneKm: return 1000
        case .noMinimum: return nil
        }
    }
}