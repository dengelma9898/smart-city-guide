import SwiftUI
import MapKit

// MARK: - Place Categories
enum PlaceCategory: String, CaseIterable, Codable {
  case attraction = "Sehenswürdigkeit"
  case museum = "Museum"
  case park = "Park"
  case nationalPark = "Nationalpark"
  
  var icon: String {
    switch self {
    case .attraction: return "star.fill"
    case .museum: return "building.columns.fill"
    case .park: return "tree.fill"
    case .nationalPark: return "mountain.2.fill"
    }
  }
  
  var color: Color {
    switch self {
    case .attraction: return .orange
    case .museum: return .purple
    case .park: return .green
    case .nationalPark: return .blue
    }
  }
  
  var searchTerms: [String] {
    switch self {
    case .attraction:
      return ["sehenswürdigkeiten", "tourist attractions", "landmarks", "monument", "historic sites"]
    case .museum:
      return ["museen", "galleries", "ausstellungen", "art gallery", "history museum"] 
    case .park:
      return ["parks", "gärten", "grünflächen", "green spaces", "botanical garden"]
    case .nationalPark:
      return ["nationalpark", "national park", "nature reserve", "wildlife park", "forest park"]
    }
  }
  
  static func classify(_ mapItem: MKMapItem) -> PlaceCategory {
    let name = mapItem.name?.lowercased() ?? ""
    let category = mapItem.pointOfInterestCategory
    
    // First check MKPointOfInterestCategory
    if let category = category {
      switch category {
      case .museum:
        return .museum
      case .nationalPark:
        return .nationalPark
      case .park:
        return .park
      default:
        break
      }
    }
    
    // Fallback to name-based classification
    if name.contains("museum") || name.contains("galerie") {
      return .museum  
    } else if name.contains("nationalpark") || name.contains("national park") {
      return .nationalPark
    } else if name.contains("park") || name.contains("garten") {
      return .park
    }
    
    return .attraction // Default fallback
  }
}

struct CategoryDistribution {
  static let target: [PlaceCategory: Double] = [
    .attraction: 0.4,      // 40%
    .museum: 0.3,          // 30%
    .park: 0.2,            // 20%
    .nationalPark: 0.1     // 10%
  ]
}

struct CategoryStat {
  let category: PlaceCategory
  let count: Int
}