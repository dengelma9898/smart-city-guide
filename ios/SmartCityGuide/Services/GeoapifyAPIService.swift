import Foundation
import CoreLocation

// MARK: - Geoapify API Service

@MainActor
class GeoapifyAPIService: ObservableObject {
    static let shared = GeoapifyAPIService()
    
    // Secure Logging - lazy init to avoid main actor issues
    private lazy var secureLogger = SecureLogger.shared
    
    // Network Security with Certificate Pinning
    private let networkSecurity = NetworkSecurityManager.shared
    
    // Secure API Key loading from APIKeys.plist
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEOAPIFY_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("GEOAPIFY_API_KEY not found in APIKeys.plist. Please add the APIKeys.plist file to your Xcode project with your Geoapify API Key.")
        }
        return key
    }
    private let baseURL = "https://api.geoapify.com/v2"
    private let geocodeURL = "https://api.geoapify.com/v1/geocode"
    private let urlSession: URLSession
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(urlSession: URLSession? = nil) {
        // Use secure session with certificate pinning by default
        self.urlSession = urlSession ?? NetworkSecurityManager.shared.secureSession
        secureLogger.logInfo("🔐 GeoapifyAPIService initialized with certificate pinning", category: .security)
    }
    
    // MARK: - Public API
    
    /// Fetches POIs for a given city name with caching and rate limit handling
    func fetchPOIs(for cityName: String, categories: [PlaceCategory] = PlaceCategory.geoapifyEssentialCategories, retryCount: Int = 0) async throws -> [POI] {
        // Check cache first
        if let cachedPOIs = POICacheService.shared.getCachedPOIs(for: cityName) {
            // Cache hit - no logging needed
            return cachedPOIs
        }
        
        // Cache miss - fetch from API
        secureLogger.logInfo("🌐 Fetching POIs for '\(cityName)' from Geoapify (attempt \(retryCount + 1))", category: .data)
        
        do {
            // Step 1: Geocode the city to get coordinates
            let cityLocation = try await geocodeCity(cityName)
            
            // Step 2: Search for POIs around the city with 5km radius
            let pois = try await searchPOIs(near: cityLocation, categories: categories, cityName: cityName, radius: 5000) // 5km tourism radius
            
            // Cache the results
            POICacheService.shared.cachePOIs(pois, for: cityName)
            
            return pois
            
        } catch GeoapifyError.rateLimitExceeded {
            if retryCount < 1 { // Allow 1 retry for the main method
                secureLogger.logWarning("🌐 Geoapify API rate limit exceeded, retrying...", category: .general)
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 second delay
                return try await fetchPOIs(for: cityName, categories: categories, retryCount: retryCount + 1)
            } else {
                throw GeoapifyError.rateLimitExceeded
            }
        }
    }
    
    /// Direct POI search with coordinates (eliminates geocoding entirely!).
    /// radiusMeters: override the default tourism radius (default 5000m). Used e.g. for Quick-Planning (2000m).
    func fetchPOIs(
        at coordinates: CLLocationCoordinate2D,
        cityName: String,
        categories: [PlaceCategory] = PlaceCategory.geoapifyEssentialCategories,
        radiusMeters: Double = 5000
    ) async throws -> [POI] {
        secureLogger.logCoordinates(coordinates, context: "Direct POI search for '\(cityName)' via Geoapify")
        
        // Check cache first
        if let cachedPOIs = POICacheService.shared.getCachedPOIs(for: cityName) {
            // Cache hit - no logging needed
            return cachedPOIs
        }
        
        let pois = try await searchPOIs(near: coordinates, categories: categories, cityName: cityName, radius: radiusMeters)
        POICacheService.shared.cachePOIs(pois, for: cityName)
        return pois
    }
    
    // MARK: - Private Implementation
    
    private func geocodeCity(_ cityName: String) async throws -> CLLocationCoordinate2D {
        // Extract city name from full address if needed  
        let cleanCityName = extractCityFromInput(cityName)
        
        secureLogger.logInfo("🗺️ Using Geoapify Geocoding API for '\(cleanCityName)'", category: .data)
        
        let encodedCity = cleanCityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanCityName
        let urlString = "\(geocodeURL)/search?text=\(encodedCity)&lang=de&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GeoapifyError.invalidURL
        }
        
        do {
            // Minimal delay for geocoding
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeoapifyError.invalidResponse(statusCode: -1)
            }
            
            // Handle rate limiting specifically
            if httpResponse.statusCode == 429 {
                // Extract more details from rate limiting response
                if String(data: data, encoding: .utf8) != nil {
                    secureLogger.logWarning("🌐 Geoapify Geocoding rate limit hit", category: .general)
                }
                throw GeoapifyError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                // Extract error details from geocoding API response
                if String(data: data, encoding: .utf8) != nil {
                    secureLogger.logError("🌐 Geoapify Geocoding API Error \(httpResponse.statusCode)", category: .general)
                }
                throw GeoapifyError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            let geocodeResponse = try JSONDecoder().decode(GeoapifyGeocodeResponse.self, from: data)
            
            guard let feature = geocodeResponse.features.first,
                  case let coordinates = feature.geometry.coordinates,
                  coordinates.count >= 2 else {
                throw GeoapifyError.cityNotFound(cleanCityName)
            }
            
            // Geoapify returns [longitude, latitude]
            let coordinate = CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
            secureLogger.logCoordinates(coordinate, context: "Geocoded '\(cleanCityName)' via Geoapify")
            
            return coordinate
            
        } catch let error as GeoapifyError {
            throw error
        } catch {
            throw GeoapifyError.geocodingFailed(error.localizedDescription)
        }
    }
    
    private func extractCityFromInput(_ input: String) -> String {
        // 🔒 SECURITY: Validate and sanitize input to prevent injection attacks
        do {
            let validatedInput = try InputValidator.validateCityName(input)
            return extractCityFromValidatedInput(validatedInput)
        } catch {
            secureLogger.logError("🚨 SECURITY: Invalid city input rejected: \(error.localizedDescription)", category: .security)
            // Return sanitized fallback - just the basic trimmed input without special chars
            let fallback = input.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .punctuationCharacters).joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return String(fallback.prefix(50)) // Limit to 50 chars as fallback
        }
    }
    
    private func extractCityFromValidatedInput(_ input: String) -> String {
        // If input looks like a full address, try to extract city name
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it contains postal code pattern (5 digits)
        let postalCodePattern = #"\b\d{5}\b"#
        if let regex = try? NSRegularExpression(pattern: postalCodePattern),
           let match = regex.firstMatch(in: trimmedInput, range: NSRange(trimmedInput.startIndex..., in: trimmedInput)) {
            
            // Extract city name after postal code
            let matchRange = Range(match.range, in: trimmedInput)!
            let afterPostalCode = String(trimmedInput[matchRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !afterPostalCode.isEmpty {
                return afterPostalCode
            }
        }
        
        // If no postal code found, check for comma-separated format
        let components = trimmedInput.components(separatedBy: ",")
        if components.count > 1 {
            // Take the last non-empty component as potential city
            for component in components.reversed() {
                let cleanComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanComponent.isEmpty && !cleanComponent.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
                    return cleanComponent
                }
            }
        }
        
        // Handle "City Street Number" format (e.g., "Feucht Bienenweg 4")
        let words = trimmedInput.components(separatedBy: " ")
        if words.count >= 2 {
            // If the last word is a number, assume first word is the city
            if let lastWord = words.last, lastWord.allSatisfy(\.isNumber) {
                return words.first!
            }
            
            // If last 2 words contain numbers/street info, take first word as city
            let lastTwoWords = Array(words.suffix(2)).joined(separator: " ")
            if lastTwoWords.contains(where: \.isNumber) || 
               lastTwoWords.lowercased().contains("str") || 
               lastTwoWords.lowercased().contains("weg") ||
               lastTwoWords.lowercased().contains("platz") {
                return words.first!
            }
        }
        
        // Return original input if no extraction needed
        return trimmedInput
    }
    
    private func searchPOIs(near location: CLLocationCoordinate2D, categories: [PlaceCategory], cityName: String, radius: Double, allowFallback: Bool = true) async throws -> [POI] {
        await MainActor.run {
            isLoading = true
        }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // 🚀 GEOAPIFY PLACES API: Category-based search for precise POI filtering
        // Filter to leaf categories only (strings containing a dot), since top-level buckets like
        // "tourism" or "natural" are not valid for /places and can cause HTTP 400.
        let allCategories = categories
            .flatMap { $0.geoapifyCategories }
            .filter { $0.contains(".") }
        let categoryParams = allCategories.joined(separator: ",")
        
        // DEBUG: Log the actual categories being sent
        secureLogger.logInfo("🌍 Geoapify Categories: \(allCategories)", category: .geoapify)
        secureLogger.logInfo("🗺️ Search Location: \(location.latitude), \(location.longitude) with radius \(radius)m", category: .geoapify)
        
        // URL encode the category parameters properly
        guard !categoryParams.isEmpty,
              let encodedCategories = categoryParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw GeoapifyError.invalidURL
        }
        
        // Geoapify Places API with categories filter and German language:
        // GET /places?categories=tourism.attraction&filter=circle:lng,lat,5000&limit=50&lang=de&apiKey=key
        let urlString = "\(baseURL)/places?categories=\(encodedCategories)&filter=circle:\(location.longitude),\(location.latitude),\(Int(radius))&limit=50&lang=de&apiKey=\(apiKey)"
        
        secureLogger.logAPIRequest(url: urlString, category: .geoapify)
        
        guard let url = URL(string: urlString) else {
            secureLogger.logError("🌐 Invalid Geoapify URL: \(urlString)", category: .general)
            throw GeoapifyError.invalidURL
        }
        
        do {
            // Minimal delay since we only make one API call
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeoapifyError.invalidResponse(statusCode: -1)
            }
            
            if httpResponse.statusCode == 429 {
                // Extract more details from rate limiting response (no unused vars)
                if String(data: data, encoding: .utf8) != nil {
                    secureLogger.logWarning("🌐 Geoapify API rate limit hit", category: .general)
                }
                throw GeoapifyError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                // Extract error details from API response (no unused vars)
                if String(data: data, encoding: .utf8) != nil {
                    secureLogger.logError("🌐 Geoapify API Error \(httpResponse.statusCode)", category: .general)
                }
                // Fallback: On 400, retry with a minimal, known-good category set
                if httpResponse.statusCode == 400 && allowFallback {
                    secureLogger.logWarning("🌐 Falling back to minimal categories due to 400 - retrying with ['tourism.attraction']", category: .geoapify)
                    return try await searchPOIs(near: location, categories: [.attraction], cityName: cityName, radius: radius, allowFallback: false)
                }
                throw GeoapifyError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            // Debug: Print actual API response to understand format
            if let responseString = String(data: data, encoding: .utf8) {
                secureLogger.logAPIResponseData(String(responseString.prefix(500)), category: .geoapify)
            }
            
            let searchResponse = try JSONDecoder().decode(GeoapifySearchResponse.self, from: data)
            
            // Convert to POIs and categorize them intelligently
            let allPOIs = searchResponse.features.compactMap { feature -> POI? in
                let detectedCategory = detectCategory(for: feature)
                return POI(from: feature, category: detectedCategory, requestedCity: cityName)
            }
            
            // Filter: Ignore POIs ohne verlässlichen Namen (z.B. "Unbekannter Ort")
            let filteredPOIs = allPOIs.filter { poi in
                let name = poi.name.trimmingCharacters(in: .whitespacesAndNewlines)
                // Verwerfe leere Namen, Platzhalter oder sehr generische Labels
                guard !name.isEmpty else { return false }
                let lower = name.lowercased()
                if lower == "unbekannter ort" || lower == "unknown" || lower == "unnamed place" { return false }
                return true
            }
            
            // Remove duplicates manually since POI doesn't conform to Hashable
            var uniquePOIs: [POI] = []
            for poi in filteredPOIs {
                let isDuplicate = uniquePOIs.contains { existingPOI in
                    existingPOI.name == poi.name && 
                    abs(existingPOI.coordinate.latitude - poi.coordinate.latitude) < 0.0001 &&
                    abs(existingPOI.coordinate.longitude - poi.coordinate.longitude) < 0.0001
                }
                if !isDuplicate {
                    uniquePOIs.append(poi)
                }
            }
            
            secureLogger.logPOISearch(cityName: cityName, poiCount: uniquePOIs.count)
            return uniquePOIs
            
        } catch GeoapifyError.rateLimitExceeded {
            throw GeoapifyError.rateLimitExceeded
        } catch {
            secureLogger.logAPIError(error, category: .geoapify)
            throw GeoapifyError.searchFailed("Failed to search POIs: \(error.localizedDescription)")
        }
    }
    
    /// Intelligently detects the category of a POI based on its properties
    private func detectCategory(for feature: GeoapifyFeature) -> PlaceCategory {
        let name = feature.properties.name?.lowercased() ?? ""
        let categories = feature.properties.categories ?? []
        
        // Check Geoapify categories first (most specific)
        for category in categories {
            if category.contains("museum") { return .museum }
            if category.contains("heritage.monument") { return .monument }  
            if category.contains("heritage.castle") { return .castle }
            if category.contains("heritage") { return .monument }
            if category.contains("park") || category.contains("leisure.park") { return .park }
            if category.contains("tourism.gallery") { return .gallery }
            if category.contains("tourism.attraction") { return .attraction }
        }
        
        // Fallback to name-based detection
        if name.contains("museum") { return .museum }
        if name.contains("galerie") || name.contains("gallery") { return .gallery }
        if name.contains("burg") || name.contains("schloss") || name.contains("castle") { return .castle }
        if name.contains("denkmal") || name.contains("monument") { return .monument }
        if name.contains("park") || name.contains("garten") { return .park }
        
        // Default to attraction for everything else
        return .attraction
    }
}

// MARK: - Geoapify API Response Models

struct GeoapifyGeocodeResponse: Codable {
    let type: String
    let features: [GeoapifyGeocodeFeature]
}

struct GeoapifyGeocodeFeature: Codable {
    let type: String
    let properties: GeoapifyGeocodeProperties
    let geometry: GeoapifyGeometry
}

struct GeoapifyGeocodeProperties: Codable {
    let formatted: String?
    let city: String?
    let country: String?
}

struct GeoapifySearchResponse: Codable {
    let type: String
    let features: [GeoapifyFeature]
}

struct GeoapifyFeature: Codable {
    let type: String
    let properties: GeoapifyProperties
    let geometry: GeoapifyGeometry
}

struct GeoapifyProperties: Codable {
    let name: String?
    let formatted: String?
    let categories: [String]?
    let details: [String]?
    let datasource: GeoapifyDatasource?
    let address_line1: String?
    let address_line2: String?
    let city: String?
    let postcode: String?
    let country: String?
    let country_code: String?
    let lon: Double?
    let lat: Double?
    let place_id: String?
    let wiki_and_media: GeoapifyWikiAndMedia? // NEW: Wikipedia/Wikidata info
}

struct GeoapifyGeometry: Codable {
    let type: String
    let coordinates: [Double] // [lng, lat] for Geoapify
}

struct GeoapifyDatasource: Codable {
    let sourcename: String?
    let attribution: String?
    let license: String?
    let url: String?
}

/// Geoapify Wikipedia/Wikidata integration data
struct GeoapifyWikiAndMedia: Codable {
    let wikidata: String? // e.g. "Q972490" 
    let wikipedia: String? // e.g. "de:Narrenschiffbrunnen (Nürnberg)"
    
    /// Extrahiert den deutschen Wikipedia-Titel (ohne "de:" Prefix)
    var germanWikipediaTitle: String? {
        guard let wikipedia = wikipedia,
              wikipedia.hasPrefix("de:") else {
            return nil
        }
        return String(wikipedia.dropFirst(3)) // Remove "de:" prefix
    }
    
    /// Prüft ob Wikipedia-Daten verfügbar sind
    var hasWikipediaData: Bool {
        return germanWikipediaTitle != nil || wikidata != nil
    }
}

// MARK: - Geoapify API Errors

enum GeoapifyError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case cityNotFound(String)
    case geocodingFailed(String)
    case searchFailed(String)
    case rateLimitExceeded
    case apiKeyInvalid
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die Karten-API URL ist ungültig."
        case .invalidResponse(let statusCode):
            return "Ungültige Antwort vom Kartenserver. Statuscode: \(statusCode)"
        case .cityNotFound(let city):
            return "Die Stadt '\(city)' konnte nicht gefunden werden. Bitte überprüfen Sie die Schreibweise."
        case .geocodingFailed(let description):
            return "Adressauflösung fehlgeschlagen: \(description)"
        case .searchFailed(let description):
            return "POI-Suche fehlgeschlagen: \(description)"
        case .rateLimitExceeded:
            return "Zu viele Anfragen an unseren Kartendienst. Bitte warten Sie einen Moment und versuchen Sie es erneut."
        case .apiKeyInvalid:
            return "Kartendienst-Authentifizierung fehlgeschlagen. Bitte kontaktieren Sie den Support."
        case .quotaExceeded:
            return "Kartendienst-Kontingent überschritten. Bitte versuchen Sie es später erneut."
        }
    }
}