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

// MARK: - POI Supporting Types
struct POIAddress: Codable {
    let street: String?
    let houseNumber: String?
    let city: String?
    let postcode: String?
    let country: String?
    
    var fullAddress: String {
        var components: [String] = []
        
        if let street = street, let houseNumber = houseNumber {
            components.append("\(street) \(houseNumber)")
        } else if let street = street {
            components.append(street)
        }
        
        if let city = city {
            if let postcode = postcode {
                components.append("\(postcode) \(city)")
            } else {
                components.append(city)
            }
        }
        
        if let country = country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

struct POIContact: Codable {
    let phone: String?
    let email: String?
    let website: String?
}

struct POIAccessibility: Codable {
    let wheelchair: String? // "yes", "no", "limited"
    let wheelchairDescription: String?
}

struct POIPricing: Codable {
    let fee: String? // "yes", "no"
    let feeAmount: String?
    let feeDescription: String?
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
    
    // Extended information
    let address: POIAddress?
    let contact: POIContact?
    let accessibility: POIAccessibility?
    let pricing: POIPricing?
    let operatingHours: String?
    let website: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var fullAddress: String {
        address?.fullAddress ?? ""
    }
    
    var displayDescription: String {
        if let desc = description, !desc.isEmpty, desc != category.rawValue {
            return desc
        }
        return category.rawValue
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
                          element.tags?["description:de"] ?? 
                          element.tags?["short_name"] ??
                          element.tags?["alt_name"]
        
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
        
        // Extract address information
        let street = element.tags?["addr:street"]
        let houseNumber = element.tags?["addr:housenumber"]
        let city = element.tags?["addr:city"]
        let postcode = element.tags?["addr:postcode"]
        let country = element.tags?["addr:country"]
        
        if street != nil || houseNumber != nil || city != nil || postcode != nil || country != nil {
            self.address = POIAddress(
                street: street,
                houseNumber: houseNumber,
                city: city,
                postcode: postcode,
                country: country
            )
        } else {
            self.address = nil
        }
        
        // Extract contact information
        let phone = element.tags?["phone"] ?? element.tags?["contact:phone"]
        let email = element.tags?["email"] ?? element.tags?["contact:email"]
        let website = element.tags?["website"] ?? element.tags?["contact:website"] ?? element.tags?["url"]
        
        if phone != nil || email != nil || website != nil {
            self.contact = POIContact(phone: phone, email: email, website: website)
        } else {
            self.contact = nil
        }
        
        // Extract accessibility information
        let wheelchair = element.tags?["wheelchair"]
        let wheelchairDesc = element.tags?["wheelchair:description"]
        
        if wheelchair != nil || wheelchairDesc != nil {
            self.accessibility = POIAccessibility(
                wheelchair: wheelchair,
                wheelchairDescription: wheelchairDesc
            )
        } else {
            self.accessibility = nil
        }
        
        // Extract pricing information
        let fee = element.tags?["fee"]
        let feeAmount = element.tags?["fee:amount"] ?? element.tags?["charge"]
        let feeDesc = element.tags?["fee:description"]
        
        if fee != nil || feeAmount != nil || feeDesc != nil {
            self.pricing = POIPricing(
                fee: fee,
                feeAmount: feeAmount,
                feeDescription: feeDesc
            )
        } else {
            self.pricing = nil
        }
        
        // Extract operating hours
        self.operatingHours = element.tags?["opening_hours"]
        
        // Extract website (if not already in contact)
        self.website = element.tags?["website"] ?? element.tags?["url"]
    }
    
    // City filtering
    func isInCity(_ cityName: String) -> Bool {
        // Check if POI has address with matching city
        if let city = address?.city {
            return city.lowercased().contains(cityName.lowercased()) || 
                   cityName.lowercased().contains(city.lowercased())
        }
        
        // Fallback: If no address, we assume it's in the requested city
        // since it was found within the city's bounding box
        return true
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
        case .landmarkAttraction:
            return [("tourism", "attraction")]
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