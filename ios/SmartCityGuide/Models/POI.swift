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