import Foundation
import CoreLocation

// MARK: - Supporting Types
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
    let wheelchair: String?
    let wheelchairDescription: String?
}

struct POIPricing: Codable {
    let fee: String?
    let feeAmount: String?
    let feeDescription: String?
}

// MARK: - POI Model
struct POI: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: PlaceCategory
    let description: String?
    let tags: [String: String]
    let sourceType: String
    let sourceId: Int64
    let address: POIAddress?
    let contact: POIContact?
    let accessibility: POIAccessibility?
    let pricing: POIPricing?
    let operatingHours: String?
    let website: String?
    let geoapifyWikiData: GeoapifyWikiAndMedia? // NEW: Wikipedia data from Geoapify
    
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
    
    /// Returns true if the POI is located in the given city (simple case-insensitive check).
    func isInCity(_ cityName: String) -> Bool {
        if let city = address?.city {
            return city.lowercased().contains(cityName.lowercased()) ||
                   cityName.lowercased().contains(city.lowercased())
        }
        return true
    }
}

// MARK: - POI Extension for Geoapify

extension POI {
    init?(from feature: GeoapifyFeature, category: PlaceCategory, requestedCity: String) {
        let props = feature.properties
        let coords = feature.geometry.coordinates
        
        // Basic Properties: Prefer stable Geoapify place_id as primary identifier
        if let rawPlaceId = props.place_id?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawPlaceId.isEmpty {
            self.id = "geo_\(rawPlaceId)"
        } else {
            // Stable fallback based on name + coordinates (no random hash)
            let namePart = (props.name ?? "").replacingOccurrences(of: " ", with: "_")
            let lat = String(format: "%.6f", (feature.geometry.coordinates.count >= 2 ? feature.geometry.coordinates[1] : 0))
            let lon = String(format: "%.6f", (feature.geometry.coordinates.count >= 2 ? feature.geometry.coordinates[0] : 0))
            self.id = "geo_fallback_\(namePart)_\(lat)_\(lon)"
        }
        self.name = props.name ?? "Unbekannter Ort"
        
        // Geoapify returns [longitude, latitude]
        guard coords.count >= 2 else { return nil }
        self.longitude = coords[0]
        self.latitude = coords[1]
        
        self.category = category
        self.sourceType = "geoapify_poi"
        self.sourceId = Int64(feature.hashValue)
        
        // Address Information
        self.address = POIAddress(
            street: props.address_line1,
            houseNumber: nil, // Geoapify doesn't separate house number
            city: props.city,
            postcode: props.postcode,
            country: props.country
        )
        
        // Contact Information - Geoapify doesn't provide contact details directly
        self.contact = nil
        
        // Do NOT surface technical Geoapify details/categories as user-facing description.
        // Leave description empty; UI will show enriched data or a friendly fallback.
        self.description = nil
        
        // Tags from Geoapify data
        var tags: [String: String] = [:]
        if let categories = props.categories {
            tags["geoapify:categories"] = categories.joined(separator: ",")
        }
        if let datasource = props.datasource?.sourcename {
            tags["source"] = datasource
        }
        if let placeId = props.place_id {
            tags["geoapify:place_id"] = placeId
        }
        self.tags = tags
        
        // Initialize other fields (Geoapify doesn't provide these directly)
        self.accessibility = nil
        self.pricing = nil
        self.operatingHours = nil
        self.website = nil
        
        // NEW: Store Geoapify Wikipedia data for optimized enrichment
        self.geoapifyWikiData = props.wiki_and_media
    }
}

// MARK: - Geoapify Feature Protocol Conformances

extension GeoapifyFeature: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(properties.place_id ?? properties.name ?? "")
        hasher.combine(geometry.coordinates)
    }
    
    static func == (lhs: GeoapifyFeature, rhs: GeoapifyFeature) -> Bool {
        return lhs.properties.place_id == rhs.properties.place_id &&
               lhs.geometry.coordinates == rhs.geometry.coordinates
    }
}