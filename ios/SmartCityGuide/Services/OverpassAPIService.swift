import Foundation
import CoreLocation

@MainActor
class OverpassAPIService: ObservableObject {
    private let baseURL = "https://overpass-api.de/api/interpreter"
    private let urlSession: URLSession
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - Public API
    
    /// Fetches POIs for a given city name with caching
    func fetchPOIs(for cityName: String, categories: [PlaceCategory] = PlaceCategory.defaultCategories) async throws -> [POI] {
        // Check cache first
        if let cachedPOIs = POICacheService.shared.getCachedPOIs(for: cityName) {
            print("OverpassAPIService: Using cached POIs for '\(cityName)'")
            return cachedPOIs
        }
        
        // Cache miss - fetch from API
        print("OverpassAPIService: Fetching POIs from API for '\(cityName)'")
        
        // First, get bounding box for the city
        let boundingBox = try await getBoundingBox(for: cityName)
        
        // Then fetch POIs within that bounding box
        let pois = try await fetchPOIs(in: boundingBox, categories: categories, cityName: cityName)
        
        // Cache the results
        POICacheService.shared.cachePOIs(pois, for: cityName)
        
        return pois
    }
    
    /// Fetches POIs within a specific bounding box
    func fetchPOIs(in boundingBox: BoundingBox, categories: [PlaceCategory] = PlaceCategory.defaultCategories, cityName: String? = nil) async throws -> [POI] {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let query = buildOverpassQuery(boundingBox: boundingBox, categories: categories, cityName: cityName)
            let response = try await executeQuery(query)
            let pois = parseResponse(response, cityName: cityName)
            
            print("OverpassAPIService: Found \(pois.count) POIs in bounding box")
            return pois
        } catch {
            let errorMsg = "Failed to fetch POIs: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("OverpassAPIService Error: \(errorMsg)")
            throw error
        }
    }
    
    // MARK: - Private Implementation
    
    private func getBoundingBox(for cityName: String) async throws -> BoundingBox {
        // Use CLGeocoder to get city coordinates and create a bounding box
        let geocoder = CLGeocoder()
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(cityName) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: OverpassError.geocodingFailed(error.localizedDescription))
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    continuation.resume(throwing: OverpassError.cityNotFound(cityName))
                    return
                }
                
                // Create a bounding box around the city (approximately 20km radius)
                let coordinate = location.coordinate
                let radius: Double = 0.18 // Approximately 20km in degrees
                
                let boundingBox = BoundingBox(
                    south: coordinate.latitude - radius,
                    west: coordinate.longitude - radius,
                    north: coordinate.latitude + radius,
                    east: coordinate.longitude + radius
                )
                
                continuation.resume(returning: boundingBox)
            }
        }
    }
    
    private func buildOverpassQuery(boundingBox: BoundingBox, categories: [PlaceCategory], cityName: String? = nil) -> String {
        var query = "[out:json][timeout:60];\n"
        var queryParts: [String] = []
        
        // Use area-based filtering if city name is provided (more accurate!)
        if let cityName = cityName {
            query += "{{geocodeArea:\(cityName)}}->.searchArea;\n"
            
            // Add queries for each category using area constraint
            for category in categories {
                for (key, value) in category.overpassTags {
                    queryParts.append("  node[\"\(key)\"=\"\(value)\"](area.searchArea);")
                    queryParts.append("  way[\"\(key)\"=\"\(value)\"](area.searchArea);")
                    queryParts.append("  relation[\"\(key)\"=\"\(value)\"](area.searchArea);")
                }
            }
            
            query += "(\n"
            query += queryParts.joined(separator: "\n")
            query += "\n);\n"
        } else {
            // Fallback to bounding box if no city name
            let bbox = "\(boundingBox.south),\(boundingBox.west),\(boundingBox.north),\(boundingBox.east)"
            
            for category in categories {
                for (key, value) in category.overpassTags {
                    queryParts.append("  node[\"\(key)\"=\"\(value)\"](\(bbox));")
                    queryParts.append("  way[\"\(key)\"=\"\(value)\"](\(bbox));")
                }
            }
            
            query += "(\n"
            query += queryParts.joined(separator: "\n")
            query += "\n);\n"
        }
        
        query += "out center meta;"
        
        print("OverpassAPIService Query: \(query)")
        return query
    }
    
    private func executeQuery(_ query: String) async throws -> OverpassResponse {
        guard let url = URL(string: baseURL) else {
            throw OverpassError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query)".data(using: .utf8)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OverpassError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw OverpassError.httpError(httpResponse.statusCode)
        }
        
        // Print raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("OverpassAPIService Raw Response: \(responseString.prefix(500))...")
        }
        
        do {
            let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
            return overpassResponse
        } catch {
            print("OverpassAPIService JSON Decode Error: \(error)")
            throw OverpassError.decodingFailed(error.localizedDescription)
        }
    }
    
    private func parseResponse(_ response: OverpassResponse, cityName: String? = nil) -> [POI] {
        var pois: [POI] = []
        
        for element in response.elements {
            // Skip elements without tags or coordinates
            guard let tags = element.tags,
                  !tags.isEmpty,
                  (element.lat != nil && element.lon != nil) || element.center != nil else {
                continue
            }
            
            // Determine category from tags
            let category = PlaceCategory.from(overpassTags: tags)
            
            // Create POI
            let poi = POI(from: element, category: category)
            
            // Skip POIs without names (optional filter)
            guard !poi.name.isEmpty && poi.name != category.rawValue else {
                continue
            }
            
            // No manual city filtering needed - Overpass API with geocodeArea already filters by city boundaries!
            pois.append(poi)
        }
        
        print("OverpassAPIService: Parsed \(pois.count) valid POIs from \(response.elements.count) elements (city-filtered by Overpass API)")
        return pois
    }
}

// MARK: - Supporting Types

struct BoundingBox {
    let south: Double
    let west: Double
    let north: Double
    let east: Double
}

enum OverpassError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingFailed(String)
    case geocodingFailed(String)
    case cityNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Overpass API URL"
        case .invalidResponse:
            return "Invalid response from Overpass API"
        case .httpError(let code):
            return "HTTP error \(code) from Overpass API"
        case .decodingFailed(let reason):
            return "Failed to decode response: \(reason)"
        case .geocodingFailed(let reason):
            return "Failed to geocode city: \(reason)"
        case .cityNotFound(let cityName):
            return "City '\(cityName)' not found"
        }
    }
}

// MARK: - PlaceCategory Extensions

extension PlaceCategory {
    static let defaultCategories: [PlaceCategory] = [
        .attraction, .museum, .gallery, .artwork, .viewpoint,
        .monument, .memorial, .castle, .ruins, .archaeologicalSite,
        .park, .garden, .artsCenter, .townhall, .placeOfWorship,
        .cathedral, .chapel, .monastery, .shrine, .spring,
        .waterfall, .lake, .nationalPark
    ]
}