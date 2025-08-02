import Foundation
import CoreLocation

// MARK: - Overpass API Response Models
struct OverpassResponse: Codable {
    let version: Double
    let generator: String
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int64
    let lat: Double?
    let lon: Double?
    let tags: [String: String]?
    
    // For ways and relations
    let center: OverpassCenter?
    let nodes: [Int64]?
    let members: [OverpassMember]?
}

struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

struct OverpassMember: Codable {
    let type: String
    let ref: Int64
    let role: String?
}

// MARK: - POI Model for App
struct POI: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: PlaceCategory
    let description: String?
    let tags: [String: String]
    let overpassType: String // "node", "way", or "relation"
    let overpassId: Int64
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Initialize from Overpass API element
    init(from element: OverpassElement, category: PlaceCategory) {
        self.id = "\(element.type)_\(element.id)"
        self.overpassType = element.type
        self.overpassId = element.id
        self.category = category
        self.tags = element.tags ?? [:]
        
        // Extract name
        self.name = element.tags?["name"] ?? 
                   element.tags?["name:de"] ?? 
                   element.tags?["name:en"] ?? 
                   category.rawValue
        
        // Extract description
        self.description = element.tags?["description"] ?? 
                          element.tags?["tourism"] ?? 
                          element.tags?["amenity"] ?? 
                          element.tags?["leisure"]
        
        // Extract coordinates
        if let lat = element.lat, let lon = element.lon {
            // For nodes
            self.latitude = lat
            self.longitude = lon
        } else if let center = element.center {
            // For ways and relations
            self.latitude = center.lat
            self.longitude = center.lon
        } else {
            // Fallback
            self.latitude = 0.0
            self.longitude = 0.0
        }
    }
}

// MARK: - POI Category Mapping to Overpass Tags
extension PlaceCategory {
    var overpassTags: [(key: String, value: String)] {
        switch self {
        case .attraction:
            return [("tourism", "attraction")]
        case .museum:
            return [("tourism", "museum")]
        case .gallery:
            return [("tourism", "gallery")]
        case .artwork:
            return [("tourism", "artwork")]
        case .viewpoint:
            return [("tourism", "viewpoint")]
        case .monument:
            return [("tourism", "monument")]
        case .memorial:
            return [("tourism", "memorial")]
        case .castle:
            return [("tourism", "castle")]
        case .ruins:
            return [("tourism", "ruins")]
        case .archaeologicalSite:
            return [("tourism", "archaeological_site")]
        case .park:
            return [("leisure", "park")]
        case .garden:
            return [("leisure", "garden")]
        case .artsCenter:
            return [("amenity", "arts_centre")]
        case .townhall:
            return [("amenity", "townhall")]
        case .placeOfWorship:
            return [("amenity", "place_of_worship")]
        case .cathedral:
            return [("amenity", "cathedral")]
        case .chapel:
            return [("amenity", "chapel")]
        case .monastery:
            return [("amenity", "monastery")]
        case .shrine:
            return [("amenity", "shrine")]
        case .spring:
            return [("natural", "spring")]
        case .waterfall:
            return [("natural", "waterfall")]
        case .lake:
            return [("natural", "lake")]
        case .nationalPark:
            return [("leisure", "nature_reserve")]
        }
    }
    
    static func from(overpassTags tags: [String: String]) -> PlaceCategory {
        // Check tourism tags
        if let tourism = tags["tourism"] {
            switch tourism {
            case "attraction": return .attraction
            case "museum": return .museum
            case "gallery": return .gallery
            case "artwork": return .artwork
            case "viewpoint": return .viewpoint
            case "monument": return .monument
            case "memorial": return .memorial
            case "castle": return .castle
            case "ruins": return .ruins
            case "archaeological_site": return .archaeologicalSite
            default: break
            }
        }
        
        // Check leisure tags
        if let leisure = tags["leisure"] {
            switch leisure {
            case "park": return .park
            case "garden": return .garden
            case "nature_reserve": return .nationalPark
            default: break
            }
        }
        
        // Check amenity tags
        if let amenity = tags["amenity"] {
            switch amenity {
            case "arts_centre": return .artsCenter
            case "townhall": return .townhall
            case "place_of_worship": return .placeOfWorship
            case "cathedral": return .cathedral
            case "chapel": return .chapel
            case "monastery": return .monastery
            case "shrine": return .shrine
            default: break
            }
        }
        
        // Check natural tags
        if let natural = tags["natural"] {
            switch natural {
            case "spring": return .spring
            case "waterfall": return .waterfall
            case "lake": return .lake
            default: break
            }
        }
        
        return .attraction // Default fallback
    }
}